extends RefCounted

# 模拟只由 Crispy 运行。这里管理宿主身份、命令与复制后的观察数据。
const IWAD := "E:/Enter-The-Nyangeon-ETNDoom/etndoom_mod/wad/Third Party WAD/DOOM2.WAD"
const PWAD := "E:/Enter-The-Nyangeon-ETNDoom/etndoom_mod/wad/MAP01.wad"
const DOOM := "E:/Enter-The-Nyangeon-ETNDoom/etndoom_mod/wad/Third Party WAD/doom.wad"
const DSS := "E:/Enter-The-Nyangeon-ETNDoom/etndoom_mod/wad/Third Party WAD/dss/DSS.wad"
const COMMAND_CAPACITY := 1024
const EVENT_CAPACITY := 256
static var _session_counter := 0
static var _world_counter := 0
var native: Object
var core_path := ""
var session_epoch := 0
var world_epoch := 0
var next_tic := 0
var snapshot_seq := 0
var last_sequence := -1
var paused := false
var running := false
var failed := false
var queue: Array[Dictionary] = []
var events: Array[Dictionary] = []
var event_seq := 0
var acknowledged_event := 0
var last_error: Dictionary = {}
var resource_id := ""
var jump_enabled := false
var _map_identity := ""
var _leveltime := -1
var _core_world := ""
var _flow_state := -1
var request_seq := 0
var pause_reasons: Dictionary = {}
var _native_event_seq := 0
var _native_ack_map: Dictionary = {}
var _resource_lengths: Dictionary = {}
var _pending_requests: Dictionary = {}
var interactive := false

func save_directory(resource: String, jump: bool) -> String:
	return ProjectSettings.globalize_path("user://etndoom_m1/saves/" + resource + ("_jump" if jump else "_original"))

# 浏览只读取封套头，真正加载仍由原生校验完整摘要与补充状态。
func save_slots(resource: String, jump: bool) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	if resource not in ["fixture", "doom2", "doom", "dss"]:
		return slots
	var iwad := DOOM if resource in ["doom", "dss"] else IWAD
	var pwad := PWAD if resource == "fixture" else (DSS if resource == "dss" else "")
	var identity := FileAccess.get_sha256(iwad) + (FileAccess.get_sha256(pwad) if not pwad.is_empty() else "0".repeat(64))
	var core_identity := FileAccess.get_sha256(core_path)
	for number in 64:
		var path := save_directory(resource, jump).path_join("m1-slot-%d.etns" % number)
		var item := {"slot": number, "file": path, "exists": FileAccess.file_exists(path), "description": "空存档", "episode": 0, "map": 0, "skill": 0, "modified": 0, "compatible": false, "error": ""}
		if item.exists:
			item.modified = FileAccess.get_modified_time(path)
			var file := FileAccess.open(path, FileAccess.READ)
			if file == null:
				item.error = "不能读取存档"
			else:
				var header := file.get_buffer(168)
				if header.size() != 168 or header.slice(0, 7).get_string_from_ascii() != "ETNM1SV" or header.decode_u32(8) != 1 or header.decode_u32(12) != 168 or int(file.get_length()) != 168 + header.decode_u32(16) + header.decode_u32(20):
					item.error = "存档封套无效"
				else:
					item.description = file.get_buffer(24).get_string_from_utf8().strip_edges()
					item.skill = header.decode_s32(156) + 1
					item.episode = header.decode_s32(160)
					item.map = header.decode_s32(164)
					item.rules = header.decode_s32(152)
					item.compatible = header.slice(24, 88).hex_encode() == identity and header.slice(88, 120).hex_encode() == core_identity
					if not item.compatible:
						item.error = "构建或资源身份不同；请使用原启动器"
				file.close()
		slots.append(item)
	return slots

func setup(path: String) -> void:
	core_path = path
	native = ClassDB.instantiate("CrispyDoomBridgeM1")

func _decode(value: String) -> Dictionary:
	var parsed = JSON.parse_string(value)
	if not parsed is Dictionary:
		return _error("core_json", "原生接口返回无效 JSON")
	if parsed.has("error") and not parsed.has("ok"):
		parsed["ok"] = false
	return parsed

func _error(stage: String, message: String) -> Dictionary:
	last_error = {"ok": false, "stage": stage, "error": message}
	return last_error.duplicate(true)

func _stop_failed_session(error: Dictionary) -> Dictionary:
	# 内核失败后不再等待 UI 再发一次已被拒绝的 pause；先撤回音频和 DLL。
	last_error = error.duplicate(true)
	last_error["recoverability"] = "close_required"
	failed = true
	running = false
	paused = true
	queue.clear()
	if native != null:
		last_error["cleanup"] = _decode(native.call("close_core"))
	return last_error.duplicate(true)

func create_session(resource: String = "fixture", jump: bool = false, skill: int = 3, episode: int = 1, map: int = 1) -> Dictionary:
	if running:
		return _error("state", "已有活动会话")
	if resource not in ["fixture", "doom2", "doom", "dss"]:
		return _error("resource", "未知获准资源配置")
	if resource == "fixture" and (episode != 1 or map != 1):
		return _error("resource", "自制夹具仅允许 MAP01")
	if resource in ["doom", "dss"] and (episode < 1 or episode > 4 or map < 1 or map > 9):
		return _error("resource", "Doom 起始关卡范围为 E1–E4 / M1–M9")
	var save_dir := save_directory(resource, jump)
	DirAccess.make_dir_recursive_absolute(save_dir)
	var pwad := PWAD if resource == "fixture" else (DSS if resource == "dss" else "")
	var iwad := DOOM if resource in ["doom", "dss"] else IWAD
	var core_episode := episode if resource in ["doom", "dss"] else 0
	var result := _decode(native.call("open_core", core_path, iwad, pwad, save_dir, skill, core_episode, map, int(jump)))
	if not result.get("ok", false):
		last_error = result
		return result
	var info := build_info()
	if int(info.get("abi", -1)) != 2:
		native.call("close_core")
		return _error("abi", "核心 ABI 不匹配：预期 2，实际 %s" % info.get("abi", "缺失"))
	_session_counter += 1
	_world_counter += 1
	session_epoch = _session_counter
	world_epoch = _world_counter
	next_tic = 0
	snapshot_seq = 0
	last_sequence = -1
	queue.clear()
	events.clear()
	acknowledged_event = event_seq
	paused = false
	running = true
	failed = false
	last_error = {}
	resource_id = resource
	jump_enabled = jump
	_map_identity = ""
	_leveltime = -1
	_core_world = ""
	_flow_state = -1
	request_seq = 0
	pause_reasons.clear()
	_native_event_seq = 0
	_native_ack_map.clear()
	_resource_lengths.clear()
	_pending_requests.clear()
	interactive = false
	_event("session_started", {"resource": resource, "jump": jump})
	return {"ok": true, "session_epoch": session_epoch, "world_epoch": world_epoch, "snapshot": snapshot()}

func open(resource: String = "fixture", jump: bool = false) -> Dictionary:
	return create_session(resource, jump)

func close() -> Dictionary:
	queue.clear()
	events.clear()
	acknowledged_event = event_seq
	paused = false
	running = false
	failed = false
	pause_reasons.clear()
	return _decode(native.call("close_core")) if native != null else {"ok": true}

func _valid_command(cmd: Dictionary, target: int, sequence: int) -> String:
	for key in ["session_epoch", "world_epoch", "target_tic", "player_slot", "sequence", "forward_move", "side_move", "angle_turn", "buttons", "arti"]:
		if not cmd.has(key) or typeof(cmd[key]) != TYPE_INT:
			return "字段缺失或不是整数：" + key
	if cmd.session_epoch != session_epoch or cmd.world_epoch != world_epoch:
		return "旧会话或世界代次"
	if cmd.player_slot != 0:
		return "M1 只支持单人 player_slot=0"
	if cmd.target_tic != target:
		return "target_tic 必须连续：预期 %d，实际 %d" % [target, cmd.target_tic]
	if cmd.sequence <= sequence:
		return "sequence 重复或倒退"
	if abs(cmd.forward_move) > 50 or abs(cmd.side_move) > 50 or cmd.angle_turn < -32768 or cmd.angle_turn > 32767 or cmd.buttons < 0 or cmd.buttons > 127 or cmd.arti not in [0, 128]:
		return "ticcmd 字段超出 M1 范围"
	if cmd.arti != 0 and not jump_enabled:
		return "原规则配置未启用跳跃"
	return ""

func submit_commands(commands: Array) -> Dictionary:
	if not running or failed:
		return _error("state", "会话不可步进")
	if queue.size() + commands.size() > COMMAND_CAPACITY:
		return _error("command_capacity", "命令队列容量 1024，整批拒绝")
	var sequence := last_sequence
	for i in commands.size():
		if not commands[i] is Dictionary:
			return _error("command", "命令不是 Dictionary")
		var error := _valid_command(commands[i], next_tic + queue.size() + i, sequence)
		if not error.is_empty():
			return _error("command", error)
		sequence = commands[i].sequence
	for cmd in commands:
		queue.append(cmd.duplicate(true))
	last_sequence = sequence
	return {"ok": true, "accepted": commands.size(), "queued": queue.size()}

# 完整快照默认保留供观察消费者；framebuffer 画面显式选择轻量状态。
func step(count: int = 1, capture_snapshot: bool = true) -> Dictionary:
	if not running or failed:
		return _error("state", "会话不可步进")
	if count < 0 or count > COMMAND_CAPACITY:
		return _error("count", "step 数量超界")
	if paused:
		return {"ok": true, "executed": 0, "paused": true, "next_tic": next_tic}
	if count > queue.size():
		return _error("command_missing", "缺少显式 tic 命令；不自动补输入")
	if events.size() >= EVENT_CAPACITY - 4:
		return _error("event_capacity", "事件尚未确认，停止步进")
	var result: Dictionary = {}
	var executed := 0
	for i in count:
		if queue.is_empty() or events.size() >= EVENT_CAPACITY - 4:
			break
		var cmd: Dictionary = queue.pop_front()
		result = _decode(native.call("step_core" if capture_snapshot else "step_status_core", cmd.forward_move, cmd.side_move, cmd.angle_turn, cmd.buttons, cmd.arti))
		if result.has("ok") and not result.ok:
			var current := _decode(native.call("status_json"))
			if not current.get("ok", true) or current.get("observer_failed", false):
				return _stop_failed_session(result)
			# 原生参数拒绝不推进 tic，也不销毁可恢复的世界。
			queue.clear()
			result["recoverability"] = "retry"
			last_error = result.duplicate(true)
			return result
		next_tic += 1
		executed += 1
		snapshot_seq += 1
		var changed := _check_world(result)
		_collect_native_events()
		if failed:
			return _stop_failed_session(last_error)
		if changed:
			break
	var response := {"ok": true, "executed": executed, "next_tic": next_tic}
	if capture_snapshot:
		response["snapshot"] = _decorate(result) if executed > 0 else snapshot()
	else:
		response["status"] = _decorate(result if executed > 0 else _decode(native.call("status_json")))
	return response

func command(values: Dictionary = {}, capture_snapshot: bool = true) -> Dictionary:
	var cmd := {"session_epoch": session_epoch, "world_epoch": world_epoch, "target_tic": next_tic + queue.size(), "player_slot": 0, "sequence": last_sequence + 1, "forward_move": 0, "side_move": 0, "angle_turn": 0, "buttons": 0, "arti": 0}
	cmd.merge(values, true)
	var accepted := submit_commands([cmd])
	return step(1, capture_snapshot) if accepted.get("ok", false) else accepted

func ui_status() -> Dictionary:
	return _decode(native.call("ui_status_json")) if running else _error("state", "无活动会话")

func input_event(kind: int, a: int = 0, b: int = 0, c: int = 0) -> Dictionary:
	if not running or failed:
		return _error("state", "会话不可接受输入")
	if paused and kind != 3:
		return {"ok": true, "ignored": true}
	var result := _decode(native.call("input_json", kind, a, b, c))
	if not result.get("ok", true):
		return result
	interactive = true
	_check_world(_decode(native.call("status_json")))
	_collect_native_events()
	return _stop_failed_session(last_error) if failed else result

func play_tick() -> Dictionary:
	if not running or failed:
		return _error("state", "会话不可步进")
	if paused:
		return {"ok": true, "executed": 0, "paused": true}
	if not queue.is_empty():
		return _error("command_pending", "交互输入前须消费显式命令队列")
	if events.size() >= EVENT_CAPACITY - 4:
		return _error("event_capacity", "请先消费待处理事件")
	var state := _decode(native.call("play_tick_json"))
	if not state.get("ok", true):
		return _stop_failed_session(state)
	interactive = true
	var ui := ui_status()
	var executed := int(ui.get("executed", 1))
	next_tic += executed
	snapshot_seq += 1
	_check_world(state)
	_collect_native_events()
	if failed:
		return _stop_failed_session(last_error)
	return {"ok": true, "executed": executed, "next_tic": next_tic, "status": _decorate(state), "ui": ui}

func _check_world(state: Dictionary) -> bool:
	var identity := str(state.get("world_epoch", ""))
	var changed := not _core_world.is_empty() and identity != _core_world
	if changed:
		_world_counter += 1
		world_epoch = _world_counter
		queue.clear()
		var retired := event_seq
		events.clear()
		_native_ack_map.clear()
		acknowledged_event = event_seq
		_event("world_changed", {"core_world_epoch": identity, "retired_through": str(retired)})
	_core_world = identity
	var control = state.get("control")
	if control is Dictionary and control.get("completed", false):
		var request_id := str(control.get("request_id", ""))
		if _pending_requests.has(request_id):
			_event("request_completed", control)
			_pending_requests.erase(request_id)
	var flow := int(state.get("gamestate", -1))
	if _flow_state >= 0 and flow != _flow_state:
		_event("flow_changed", {"from": _flow_state, "to": flow})
	_flow_state = flow
	return changed

func _decorate(state: Dictionary) -> Dictionary:
	var copy := state.duplicate(true)
	copy["core_world_epoch"] = state.get("world_epoch", "")
	copy["session_epoch"] = str(session_epoch)
	copy["world_epoch"] = str(world_epoch)
	copy["next_tic"] = next_tic
	copy["snapshot_seq"] = snapshot_seq
	copy["pause_reasons"] = pause_reasons.keys()
	return copy

func snapshot() -> Dictionary:
	if not running:
		return _error("state", "无活动会话")
	var state := _decode(native.call("snapshot_json"))
	_check_world(state)
	return _decorate(state)

func map_data() -> Dictionary:
	var result := _decode(native.call("map_json"))
	# 只附当前宿主身份；读取地图不触发快照检查、世界变更或序号推进。
	result["core_world_epoch"] = result.get("world_epoch", _core_world)
	result["session_epoch"] = str(session_epoch)
	result["world_epoch"] = str(world_epoch)
	return result

func build_info() -> Dictionary:
	return _decode(native.call("build_info_json"))

func dimensions() -> Dictionary:
	return _decode(native.call("dimensions_json"))

func framebuffer() -> PackedByteArray:
	if not running:
		return PackedByteArray()
	return native.call("framebuffer")

func set_paused(value: bool, reason: String = "manual") -> Dictionary:
	if not running:
		return _error("state", "无活动会话")
	var proposed := pause_reasons.duplicate()
	if value:
		proposed[reason] = true
	else:
		proposed.erase(reason)
	var effective := not proposed.is_empty()
	if paused == effective:
		if proposed != pause_reasons:
			if events.size() >= EVENT_CAPACITY:
				return _error("event_capacity", "事件尚未确认，拒绝暂停原因变更")
			_event("pause_reasons_changed", {"paused": paused, "reasons": proposed.keys()})
		pause_reasons = proposed
		return {"ok": true, "paused": paused}
	if events.size() >= EVENT_CAPACITY:
		return _error("event_capacity", "事件尚未确认，拒绝暂停变更")
	var response := _request_flow_action("pause", int(effective))
	if not response.get("ok", false):
		return response
	paused = effective
	pause_reasons = proposed
	queue.clear()
	_event("paused" if effective else "resumed", {"reasons": pause_reasons.keys()})
	response["paused"] = paused
	return response

func request_flow_action(action: String, arg0: int = 0, arg1: int = 0, arg2: int = 0) -> Dictionary:
	if action == "pause":
		if arg0 not in [0, 1] or arg1 != 0 or arg2 != 0:
			return _error("control", "pause 只接受 0/1")
		return set_paused(bool(arg0), "manual")
	return _request_flow_action(action, arg0, arg1, arg2)

func _request_flow_action(action: String, arg0: int = 0, arg1: int = 0, arg2: int = 0) -> Dictionary:
	if not running or failed:
		return _error("state", "会话不可接受流程请求")
	if events.size() >= EVENT_CAPACITY - 4:
		return _error("event_capacity", "请先消费待处理事件")
	if action == "new_game" and resource_id == "fixture" and (arg1 not in [0, 1] or arg2 != 1):
		return _error("resource", "自制夹具的新游戏入口仅允许 MAP01")
	if action == "confirm" and not _pending_requests.is_empty():
		return _error("request_pending", "前一次确认尚未由流程消费")
	request_seq += 1
	var response := _decode(native.call("control_json", action, arg0, arg1, arg2, request_seq))
	response["operation"] = action
	response["session_epoch"] = str(session_epoch)
	response["stage"] = "control"
	if not response.get("ok", false):
		response["error"] = response.get("code", "CONTROL_FAILED")
		if response.get("active", true) == false:
			return _stop_failed_session(response)
		response["recoverability"] = "close_required" if failed else "retry"
	if response.get("ok", false):
		queue.clear()
		snapshot_seq += 1
		_check_world(_decode(native.call("status_json")))
		# 换世界先撤销旧世界事件，再发布取消结果，避免它被重建清队列吞掉。
		var cancelled := str(response.get("cancelled_request_id", "0"))
		if _pending_requests.has(cancelled):
			_event("request_cancelled", {"request_id": cancelled, "by": action})
			_pending_requests.erase(cancelled)
		# 内核保留 host_paused；重建不再额外发未检查的 pause 请求，
		# 否则会覆盖本次请求的完成状态/标识。
	if response.get("ok", false) and not response.get("completed", false):
		_pending_requests[str(response.request_id)] = action
		_event("request_accepted", response)
	else:
		_event("request_completed" if response.get("ok", false) else "request_failed", response)
	_collect_native_events()
	if failed:
		return _stop_failed_session(last_error)
	return response

func resources() -> Dictionary:
	var result := _decode(native.call("resources_json"))
	result["session_epoch"] = str(session_epoch)
	_resource_lengths.clear()
	for lump in result.get("lumps", []):
		_resource_lengths[int(lump.id)] = int(lump.length)
	return result

func resource_handle(index: int) -> Dictionary:
	if not _resource_lengths.has(index):
		return _error("resource_index", "请从当前资源目录选择有效 lump")
	return {"session_epoch": str(session_epoch), "index": index, "length": _resource_lengths[index]}

func read_resource(handle: Dictionary, offset: int, limit: int) -> Dictionary:
	if not running or str(handle.get("session_epoch", "")) != str(session_epoch):
		return _error("resource_identity", "资源句柄属于旧会话")
	var length := int(handle.get("length", -1))
	var index := int(handle.get("index", -1))
	if not _resource_lengths.has(index) or _resource_lengths[index] != length:
		return _error("resource_identity", "资源索引或长度与当前目录不符")
	if offset < 0 or offset > length or limit < 1 or limit > 1048576:
		return _error("resource_range", "资源读取范围无效")
	var data: PackedByteArray = native.call("resource_read", 0, int(handle.get("index", -1)), offset, limit)
	if data.size() != mini(limit, length - offset):
		return _error("resource_read", "资源读取失败或长度不符")
	return {"ok": true, "data": data, "length": length, "offset": offset}

func audio_status() -> Dictionary:
	return _decode(native.call("audio_status_json"))

func set_audio_volume(sfx: int, music: int) -> Dictionary:
	return _decode(native.call("audio_volume_json", sfx, music))

func _collect_native_events() -> void:
	var batch := _decode(native.call("events_json"))
	if not batch.get("ok", true) or batch.get("failed", false):
		failed = true
		last_error = batch
		return
	for item in batch.get("events", []):
		var seq := int(item.get("sequence", "0"))
		if seq <= _native_event_seq:
			continue
		if events.size() >= EVENT_CAPACITY:
			# 原生队列保留未复制项；消费后再次读取，不覆盖或提前 ack。
			break
		_event(str(item.get("type", "native")), item)
		_native_event_seq = seq
		_native_ack_map[event_seq] = seq

func _event(kind: String, payload: Dictionary) -> void:
	if events.size() >= EVENT_CAPACITY:
		failed = true
		_error("event_capacity", "单次操作事件超出容量，会话停止")
		return
	event_seq += 1
	events.append({"event_seq": event_seq, "session_epoch": session_epoch, "world_epoch": world_epoch, "tic": next_tic, "type": kind, "payload": payload})

func read_events(after_seq: int = 0) -> Dictionary:
	if running:
		_collect_native_events()
	var result: Array[Dictionary] = []
	for event in events:
		if event.event_seq > after_seq:
			result.append(event.duplicate(true))
	return {"ok": not failed, "events": result, "latest_seq": event_seq, "acknowledged": acknowledged_event, "capacity": EVENT_CAPACITY, "error": last_error if failed else {}}

func acknowledge_events(sequence: int) -> Dictionary:
	if sequence < acknowledged_event or sequence > event_seq:
		return _error("event_ack", "确认序号超界")
	var core_ack := 0
	for key in _native_ack_map.keys():
		if int(key) <= sequence:
			core_ack = maxi(core_ack, int(_native_ack_map[key]))
	if core_ack > 0:
		var response := _decode(native.call("ack_events_json", core_ack))
		if not response.get("ok", false):
			return response
	# 只有 native 成功后才提交宿主确认，失败可按原映射重试。
	acknowledged_event = sequence
	for key in _native_ack_map.keys():
		if int(key) <= sequence:
			_native_ack_map.erase(key)
	while not events.is_empty() and int(events[0].event_seq) <= sequence:
		events.pop_front()
	return {"ok": true}
