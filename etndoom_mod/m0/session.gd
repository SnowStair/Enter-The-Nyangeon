extends RefCounted

# 模拟只由 Crispy 运行。这里管理宿主身份、命令与复制后的观察数据。
const IWAD := "E:/Enter-The-Nyangeon-ETNDoom/etndoom_mod/wad/DOOM2.WAD"
const PWAD := "E:/Enter-The-Nyangeon-ETNDoom/etndoom_mod/wad/MAP01.wad"
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
var _map_identity := ""
var _leveltime := -1

func setup(path: String) -> void:
	core_path = path
	native = ClassDB.instantiate("CrispyDoomBridge")

func _decode(value: String) -> Dictionary:
	var parsed = JSON.parse_string(value)
	if not parsed is Dictionary:
		return _error("core_json", "原生接口返回无效 JSON")
	return parsed

func _error(stage: String, message: String) -> Dictionary:
	last_error = {"ok": false, "stage": stage, "error": message}
	return last_error.duplicate(true)

func create_session(resource: String = "fixture", jump: bool = false) -> Dictionary:
	if running:
		return _error("state", "已有活动会话")
	if resource not in ["fixture", "doom2"]:
		return _error("resource", "仅允许 fixture 或 doom2")
	var save_dir := ProjectSettings.globalize_path("user://etndoom_m0/saves")
	DirAccess.make_dir_recursive_absolute(save_dir)
	var pwad := PWAD if resource == "fixture" else ""
	var result := _decode(native.call("open_core", core_path, IWAD, pwad, save_dir, 3, 1, int(jump)))
	if not result.get("ok", false):
		last_error = result
		return result
	var info := build_info()
	if int(info.get("abi", -1)) != 1:
		native.call("close_core")
		return _error("abi", "核心 ABI 不匹配：预期 1，实际 %s" % info.get("abi", "缺失"))
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
	_map_identity = ""
	_leveltime = -1
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
	return _decode(native.call("close_core")) if native != null else {"ok": true}

func _valid_command(cmd: Dictionary, target: int, sequence: int) -> String:
	for key in ["session_epoch", "world_epoch", "target_tic", "player_slot", "sequence", "forward_move", "side_move", "angle_turn", "buttons", "arti"]:
		if not cmd.has(key) or typeof(cmd[key]) != TYPE_INT:
			return "字段缺失或不是整数：" + key
	if cmd.session_epoch != session_epoch or cmd.world_epoch != world_epoch:
		return "旧会话或世界代次"
	if cmd.player_slot != 0:
		return "M0 只支持单人 player_slot=0"
	if cmd.target_tic != target:
		return "target_tic 必须连续：预期 %d，实际 %d" % [target, cmd.target_tic]
	if cmd.sequence <= sequence:
		return "sequence 重复或倒退"
	if abs(cmd.forward_move) > 50 or abs(cmd.side_move) > 50 or cmd.angle_turn < -32768 or cmd.angle_turn > 32767 or cmd.buttons < 0 or cmd.buttons > 127 or cmd.arti not in [0, 128]:
		return "ticcmd 字段超出 M0 范围"
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

func step(count: int = 1) -> Dictionary:
	if not running or failed:
		return _error("state", "会话不可步进")
	if count < 0 or count > COMMAND_CAPACITY:
		return _error("count", "step 数量超界")
	if paused:
		return {"ok": true, "executed": 0, "paused": true, "next_tic": next_tic}
	if count > queue.size():
		return _error("command_missing", "缺少显式 tic 命令；不自动补输入")
	if events.size() >= EVENT_CAPACITY:
		return _error("event_capacity", "事件尚未确认，停止步进")
	var result: Dictionary = {}
	var executed := 0
	for i in count:
		if queue.is_empty() or events.size() >= EVENT_CAPACITY:
			break
		var cmd: Dictionary = queue.pop_front()
		result = _decode(native.call("step_core", cmd.forward_move, cmd.side_move, cmd.angle_turn, cmd.buttons, cmd.arti))
		if result.has("ok") and not result.ok:
			failed = true
			return result
		next_tic += 1
		executed += 1
		snapshot_seq += 1
		_check_world(result)
	return {"ok": true, "executed": executed, "next_tic": next_tic, "snapshot": _decorate(result) if executed > 0 else snapshot()}

func command(values: Dictionary = {}) -> Dictionary:
	var cmd := {"session_epoch": session_epoch, "world_epoch": world_epoch, "target_tic": next_tic + queue.size(), "player_slot": 0, "sequence": last_sequence + 1, "forward_move": 0, "side_move": 0, "angle_turn": 0, "buttons": 0, "arti": 0}
	cmd.merge(values, true)
	var accepted := submit_commands([cmd])
	return step(1) if accepted.get("ok", false) else accepted

func _check_world(state: Dictionary) -> void:
	var identity := str(state.get("gamemap", state.get("map", "")))
	var leveltime := int(state.get("leveltime", -1))
	if not _map_identity.is_empty() and (identity != _map_identity or (leveltime >= 0 and _leveltime > leveltime)):
		_world_counter += 1
		world_epoch = _world_counter
		queue.clear()
		_event("world_changed", {"map": identity})
	_map_identity = identity
	_leveltime = leveltime

func _decorate(state: Dictionary) -> Dictionary:
	var copy := state.duplicate(true)
	copy["session_epoch"] = session_epoch
	copy["world_epoch"] = world_epoch
	copy["next_tic"] = next_tic
	copy["snapshot_seq"] = snapshot_seq
	return copy

func snapshot() -> Dictionary:
	if not running:
		return _error("state", "无活动会话")
	var state := _decode(native.call("snapshot_json"))
	_check_world(state)
	return _decorate(state)

func map_data() -> Dictionary:
	return _decode(native.call("map_json"))

func build_info() -> Dictionary:
	return _decode(native.call("build_info_json"))

func dimensions() -> Dictionary:
	return _decode(native.call("dimensions_json"))

func framebuffer() -> PackedByteArray:
	if not running:
		return PackedByteArray()
	return native.call("framebuffer")

func set_paused(value: bool) -> Dictionary:
	if not running:
		return _error("state", "无活动会话")
	if paused == value:
		return {"ok": true, "paused": paused}
	if events.size() >= EVENT_CAPACITY:
		return _error("event_capacity", "事件尚未确认，拒绝暂停变更")
	paused = value
	queue.clear()
	_event("paused" if value else "resumed", {})
	return {"ok": true, "paused": paused}

func _event(kind: String, payload: Dictionary) -> void:
	event_seq += 1
	events.append({"event_seq": event_seq, "session_epoch": session_epoch, "world_epoch": world_epoch, "tic": next_tic, "type": kind, "payload": payload})

func read_events(after_seq: int = 0) -> Dictionary:
	var result: Array[Dictionary] = []
	for event in events:
		if event.event_seq > after_seq:
			result.append(event.duplicate(true))
	return {"ok": true, "events": result, "latest_seq": event_seq, "acknowledged": acknowledged_event, "capacity": EVENT_CAPACITY}

func acknowledge_events(sequence: int) -> Dictionary:
	if sequence < acknowledged_event or sequence > event_seq:
		return _error("event_ack", "确认序号超界")
	acknowledged_event = sequence
	while not events.is_empty() and int(events[0].event_seq) <= sequence:
		events.pop_front()
	return {"ok": true}
