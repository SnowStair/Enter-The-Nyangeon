extends Node

const MOD_ID := "etndoom_m1"
const PREFIX := "res://mods/etndoom_m1/"
var bridge: RefCounted
var ready_ok := false
var failure: Dictionary = {}
var host_info: Dictionary = {}
var deployment: Dictionary = {}
var options: Dictionary = {}
var screen: Control
var previous_scene: Node
var previous_mouse := Input.MOUSE_MODE_VISIBLE
var bgm_states: Array[Dictionary] = []
var reenter: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	host_info = {"engine": Engine.get_version_info(), "architecture": Engine.get_architecture_name(), "debug": OS.is_debug_build(), "editor": Engine.is_editor_hint(), "user_dir": OS.get_user_data_dir(), "exe": OS.get_executable_path(), "mods": get_parent().list_mods()}
	options = parse_arguments(OS.get_cmdline_user_args())
	print("M1_ENTRY " + JSON.stringify({"host": host_info, "options": options}))
	if not options.error.is_empty():
		_fail("arguments", options.error)
	elif options.enabled:
		_bootstrap.call_deferred()

static func parse_arguments(args: PackedStringArray) -> Dictionary:
	var result := {"enabled": false, "probe": false, "resource": "fixture", "jump": false, "skill": 3, "episode": 1, "map": 1, "error": ""}
	var seen: Dictionary = {}
	for arg in args:
		var key := arg.get_slice("=", 0)
		if key not in ["--etndoom", "--m1-probe", "--m1-resource", "--m1-jump", "--m1-skill", "--m1-episode", "--m1-map"]:
			continue
		if seen.has(key):
			result.error = "参数重复：" + key
		seen[key] = true
		match key:
			"--etndoom":
				result.enabled = arg == "--etndoom=m1"
				if not result.enabled:
					result.error = "--etndoom 只接受 m1"
			"--m1-probe":
				result.probe = arg == "--m1-probe"
				if not result.probe:
					result.error = "--m1-probe 不接受值"
			"--m1-resource":
				result.resource = arg.trim_prefix("--m1-resource=")
				if result.resource not in ["fixture", "doom2", "doom", "dss"]:
					result.error = "--m1-resource 只接受 fixture / doom2 / doom / dss"
			"--m1-jump":
				result.jump = arg == "--m1-jump=on"
				if arg not in ["--m1-jump=on", "--m1-jump=off"]:
					result.error = "--m1-jump 只接受 on/off"
			_:
				var value := arg.get_slice("=", 1)
				var field := key.trim_prefix("--m1-")
				if not value.is_valid_int() or arg.count("=") != 1:
					result.error = "参数需要整数：" + key
				else:
					result[field] = int(value)
	if result.skill < 1 or result.skill > 5 or result.episode < 1 or result.episode > 4 or result.map < 1 or result.map > 32:
		result.error = "难度或起始地图超出范围"
	if not result.enabled and seen.size() > 0 and result.error.is_empty():
		result.error = "M1 参数需同时指定 --etndoom=m1"
	return result

func _fail(stage: String, message: String) -> void:
	failure = {"ok": false, "stage": stage, "error": message}
	print("M1_FAILURE " + JSON.stringify(failure))
	push_warning("[ETNDOOM M1] %s：%s" % [stage, message])
	if not options.get("probe", false):
		var dialog := AcceptDialog.new()
		dialog.title = "ETNDOOM M1 启动失败"
		dialog.dialog_text = "%s\n%s" % [stage, message]
		add_child(dialog)
		dialog.popup_centered(Vector2i(600, 240))

func _bootstrap() -> void:
	var installed := ""
	for record in get_parent().list_mods():
		if record.id == MOD_ID and record.enabled and record.mounted:
			installed = ProjectSettings.globalize_path(record.dir)
	if installed.is_empty():
		_fail("install_root", "ModManager 未返回已挂载安装根")
		return
	var manifest_path := installed.path_join("native/manifest.json")
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path)) if FileAccess.file_exists(manifest_path) else null
	if not manifest is Dictionary or manifest.get("schema", 0) != 1 or not manifest.get("files") is Dictionary:
		_fail("native_manifest", "原生清单缺失或 schema 无效：" + manifest_path)
		return
	var files: Dictionary = manifest.files
	if manifest.get("bridge_abi", 0) != 2 or manifest.get("core_abi", 0) != 2:
		_fail("native_manifest", "M1 需要 ABI 2")
		return
	var packed_identity_path := PREFIX + "build_identity.json"
	var packed_identity = JSON.parse_string(FileAccess.get_file_as_string(packed_identity_path)) if FileAccess.file_exists(packed_identity_path) else null
	if not packed_identity is Dictionary:
		_fail("build_identity", "PCK 内嵌构建身份缺失或无效，请重新安装完整 Mod 包")
		return
	for field in ["schema", "bridge_abi", "core_abi", "build_id", "files"]:
		if not packed_identity.has(field) or not manifest.has(field) or packed_identity[field] != manifest[field]:
			_fail("build_identity", "PCK 与物理原生清单不属于同一构建：%s；请重新安装完整 Mod 包" % field)
			return
	for required in ["etndoom_m1_bridge.dll", "etndoom_crispy_core.dll", "SDL2.dll", "SDL2_mixer.dll"]:
		if not files.has(required):
			_fail("native_manifest", "缺少原生文件声明：" + required)
			return
	var manifest_hash := FileAccess.get_sha256(manifest_path)
	var cache := ProjectSettings.globalize_path("user://etndoom_m1/native/" + manifest_hash)
	DirAccess.make_dir_recursive_absolute(cache)
	for filename in files:
		if filename != str(filename).get_file() or not str(filename).ends_with(".dll"):
			_fail("native_manifest", "原生文件名不合法：" + str(filename))
			return
		var source := installed.path_join("native/" + filename)
		if not FileAccess.file_exists(source) or FileAccess.get_sha256(source) != files[filename]:
			_fail("native_integrity", "原生文件缺失或 SHA-256 不匹配：" + source)
			return
		var target := cache.path_join(filename)
		if FileAccess.file_exists(target) and FileAccess.get_sha256(target) != files[filename]:
			_fail("native_cache", "缓存文件内容损坏，请退出后移除该构建缓存：" + target)
			return
		if not FileAccess.file_exists(target):
			var error := DirAccess.copy_absolute(source, target)
			if error != OK or FileAccess.get_sha256(target) != files[filename]:
				_fail("native_copy", "原生缓存复制失败：%s（%s）" % [target, error_string(error)])
				return
	var extension_path := cache.path_join("etndoom_m1.gdextension")
	if not FileAccess.file_exists(extension_path):
		var file := FileAccess.open(extension_path, FileAccess.WRITE)
		if file == null:
			_fail("extension_file", "不能写入扩展描述：" + extension_path)
			return
		file.store_string('[configuration]\nentry_symbol = "etndoom_m1_init"\ncompatibility_minimum = "4.2"\nreloadable = false\n\n[libraries]\nwindows.x86_64 = "./etndoom_m1_bridge.dll"\n')
		file.close()
	var status := GDExtensionManager.load_extension(extension_path)
	if status not in [GDExtensionManager.LOAD_STATUS_OK, GDExtensionManager.LOAD_STATUS_ALREADY_LOADED] or not ClassDB.class_exists("CrispyDoomBridgeM1"):
		_fail("extension_load", "GDExtension 加载失败：%s；status=%s；Godot=%s" % [extension_path, status, Engine.get_version_info().string])
		return
	# 成功注册后才载入原生接口消费者，避免 preload 解析时序耦合。
	var script = load(PREFIX + "m1/session.gd")
	if script == null or not script.can_instantiate():
		_fail("session_script", "会话脚本加载失败，请检查 Mod 包与运行日志")
		return
	bridge = script.new()
	bridge.setup(cache.path_join("etndoom_crispy_core.dll"))
	var bridge_info: Dictionary = bridge.build_info()
	if int(bridge_info.get("bridge_abi", 0)) != 2 or str(bridge_info.get("bridge_build", "")) != str(manifest.get("build_id", "")):
		bridge.close()
		_fail("bridge_identity", "驻留桥接与当前安装构建不一致，请完整退出 ETN 后重新启动")
		return
	deployment = {"install_root": installed, "cache_root": cache, "manifest_sha256": manifest_hash, "build_id": manifest.get("build_id", ""), "files": files, "extension_status": status, "cache_cleanup": _clean_old_caches(manifest_hash)}
	ready_ok = true
	print("M1_ENTRY_READY " + JSON.stringify(deployment))
	if not options.probe:
		_create_reentry()
		start_session(options.resource, options.jump)

func _create_reentry() -> void:
	reenter = CanvasLayer.new()
	reenter.layer = 95
	add_child(reenter)
	var button := Button.new()
	button.text = "进入 ETNDOOM M1（F9）"
	button.position = Vector2(12, 12)
	button.pressed.connect(func(): start_session(options.resource, options.jump))
	reenter.add_child(button)
	reenter.hide()

func _unhandled_key_input(event: InputEvent) -> void:
	if options.get("enabled", false) and not options.get("probe", false) and ready_ok and screen == null and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F9:
		start_session(options.resource, options.jump)
		get_viewport().set_input_as_handled()

func _clean_old_caches(current_hash: String) -> Dictionary:
	# 仅删除本模组缓存根下、以完整 SHA-256 命名的旧构建；不进入链接或其它目录。
	var root := ProjectSettings.globalize_path("user://etndoom_m1/native").simplify_path()
	var directory := DirAccess.open(root)
	var result := {"removed": [], "retained": [], "policy": "每次成功加载新构建后清理旧缓存；占用文件下次重试；卸载后显式清理"}
	if directory == null:
		return result
	for name in directory.get_directories():
		if name == current_hash or name.length() != 64 or not name.is_valid_hex_number(false) or directory.is_link(name):
			continue
		var target := root.path_join(name).simplify_path()
		if _remove_cache_tree(target, root):
			result.removed.append(name)
		else:
			result.retained.append(name)
	return result

func _remove_cache_tree(path: String, allowed_root: String) -> bool:
	if not path.begins_with(allowed_root + "/"):
		return false
	var directory := DirAccess.open(path)
	if directory == null:
		return false
	var success := true
	for name in directory.get_files():
		if DirAccess.remove_absolute(path.path_join(name)) != OK:
			success = false
	for name in directory.get_directories():
		if directory.is_link(name) or not _remove_cache_tree(path.path_join(name), allowed_root):
			success = false
	return DirAccess.remove_absolute(path) == OK if success else false

func start_session(resource: String = "fixture", jump: bool = false) -> Dictionary:
	if not ready_ok:
		return {"ok": false, "stage": "entry", "error": "原生入口尚未就绪"}
	var screen_script: Script
	if not options.probe:
		screen_script = load(PREFIX + "m1/screen.gd")
		if screen_script == null or not screen_script.can_instantiate():
			_fail("screen_script", "显示脚本加载失败，ETN 场景保持可用")
			return failure.duplicate(true)
	var result: Dictionary = bridge.create_session(resource, jump, options.skill, options.episode, options.map)
	if not result.get("ok", false):
		_fail(str(result.get("stage", "create")), str(result.get("error", "会话创建失败")))
		if reenter != null:
			reenter.show()
		return result
	if options.probe:
		return result
	if reenter != null:
		reenter.hide()
	previous_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	previous_scene = get_tree().current_scene
	if previous_scene != null:
		get_tree().root.remove_child(previous_scene)
	bgm_states.clear()
	var sound := get_tree().root.get_node_or_null("SoundManager")
	if sound != null:
		for player in sound.find_children("*", "AudioStreamPlayer", true, false):
			bgm_states.append({"player": player, "paused": player.stream_paused})
			player.stream_paused = true
	screen = screen_script.new()
	screen.entry = self
	screen.bridge = bridge
	get_tree().root.add_child(screen)
	get_tree().current_scene = screen
	print("M1_SESSION_READY " + JSON.stringify({"resource": resource, "snapshot": bridge.snapshot()}))
	return result

func stop_session() -> Dictionary:
	return return_to_etn()

func return_to_etn() -> Dictionary:
	var result: Dictionary = {"ok": true}
	if bridge != null:
		result = bridge.close()
	if is_instance_valid(screen):
		screen.queue_free()
		screen = null
	if is_instance_valid(previous_scene):
		get_tree().root.add_child(previous_scene)
		get_tree().current_scene = previous_scene
		previous_scene = null
	Input.mouse_mode = previous_mouse
	for state in bgm_states:
		if is_instance_valid(state.player) and state.player.stream_paused:
			state.player.stream_paused = state.paused
	bgm_states.clear()
	if reenter != null:
		reenter.show()
	print("M1_RETURNED_TO_ETN")
	return result

func _exit_tree() -> void:
	if bridge != null:
		bridge.close()
	if is_instance_valid(previous_scene) and not previous_scene.is_inside_tree():
		previous_scene.free()
