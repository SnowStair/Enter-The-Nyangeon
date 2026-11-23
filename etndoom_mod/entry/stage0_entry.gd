extends Node

const SCENE := "res://mods/etndoom_stage0/stage0/stage0.tscn"
const VIEW_SCENE := "res://mods/etndoom_stage0/stage03/stage03.tscn"
var stage := ""
var argument_error := ""
var scene_error := ""
var view_options: Dictionary = {}

func _ready() -> void:
	var parsed := parse_arguments(OS.get_cmdline_user_args())
	stage = parsed.stage
	argument_error = parsed.error
	view_options = parsed.options
	print("STAGE0_ENTRY " + JSON.stringify(parsed))
	if not argument_error.is_empty():
		push_warning("[Stage0] " + argument_error)
	if not stage.is_empty():
		_start.call_deferred()

static func parse_arguments(args: PackedStringArray) -> Dictionary:
	var requests: Array[String] = []
	var options: Dictionary = {}
	var error := ""
	var selected := ""
	for arg in args:
		if arg == "--stage0" or arg.begins_with("--stage0="):
			requests.append(arg)
		for key in ["collision", "map", "size", "view"]:
			var prefix: String = "--stage0-" + key
			if arg == prefix or arg.begins_with(prefix + "="):
				if options.has(key) or arg == prefix or arg.get_slice("=", 1).is_empty():
					error = "重复或无值的 " + prefix
				options[key] = arg.trim_prefix(prefix + "=")
	if requests.size() > 1:
		error = "重复的 --stage0 参数（同值重复也不允许）"
	elif requests.size() == 1:
		if requests[0] in ["--stage0=0.1", "--stage0=0.2", "--stage0=0.3"]:
			selected = requests[0].get_slice("=", 1)
		else:
			error = "无效的 --stage0 参数：只接受 0.1、0.2 或 0.3"
	if not options.is_empty() and selected != "0.3":
		error = "--stage0-collision/map/size/view 仅允许与 --stage0=0.3 一起使用"
	if not options.get("collision", "on") in ["on", "off"]:
		error = "--stage0-collision 只接受 on/off"
	if not options.get("map", "MAP01.wad") in ["MAP01.wad", "MAP01_BackWall.wad", "MAP01_FrontWall.wad", "MAP01_Texture.wad", "MAP01_HTest.wad"]:
		error = "--stage0-map 必须为五张固定 WAD 之一"
	if not options.get("view", "follow") in ["follow", "overview"]:
		error = "--stage0-view 只接受 follow/overview"
	var size_text: String = options.get("size", "960")
	if not size_text.is_valid_int() or int(size_text) < 640 or int(size_text) > 1600 or int(size_text) % 10 != 0:
		error = "--stage0-size 必须为 640..1600 内的 10mu 整数步长"
	return {"stage": selected if error.is_empty() else "", "error": error, "requests": requests, "options": options}

func _start() -> void:
	# 只走 SceneTree；不广播原版玩家生成、首回合、场景门控信号。
	var selected_scene := VIEW_SCENE if stage == "0.3" else SCENE
	var packed = load(selected_scene) as PackedScene
	if packed == null:
		scene_error = "无法加载 " + selected_scene
	else:
		# 阶段在场景入树前显式传入；不依赖可变全局选角状态。
		var instance = packed.instantiate()
		instance.stage = stage
		if stage == "0.3":
			instance.collision_enabled = view_options.get("collision", "on") == "on"
			instance.map_name = view_options.get("map", "MAP01.wad")
			instance.game_size = float(view_options.get("size", "960"))
			instance.overview = view_options.get("view", "follow") == "overview"
		var prepared := PackedScene.new()
		var err := prepared.pack(instance)
		instance.free()
		if err == OK:
			err = get_tree().change_scene_to_packed(prepared)
		if err != OK:
			scene_error = "场景切换失败：%s" % error_string(err)
	if not scene_error.is_empty():
		push_error("[Stage0] " + scene_error)
