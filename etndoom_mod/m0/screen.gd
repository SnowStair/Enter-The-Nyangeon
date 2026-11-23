extends Control

const TICS_PER_SECOND := 35.0
const MAX_TICS_PER_FRAME := 8
const BACKLOG_WARNING := 70
const MAX_BACKLOG := 350
var entry: Node
var bridge: RefCounted
var texture: ImageTexture
var picture: TextureRect
var status: Label
var paused_button: Button
var previous_usec := 0
var accumulator := 0.0
var backlog := 0
var held: Dictionary = {}
var requested_weapon := -1
var return_requested := false
var frame_count := 0
var executed_tics := 0
var test_input: Dictionary = {}
var overload := false

func _ready() -> void:
	name = "ETNDOOM_M0"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(column)
	var tools := HBoxContainer.new()
	column.add_child(tools)
	var back := Button.new()
	back.text = "返回 ETN（F10）"
	back.pressed.connect(_return)
	tools.add_child(back)
	paused_button = Button.new()
	paused_button.text = "暂停（Esc）"
	paused_button.pressed.connect(_toggle_pause)
	tools.add_child(paused_button)
	var restart := Button.new()
	restart.text = "重新开始（F5）"
	restart.pressed.connect(_restart)
	tools.add_child(restart)
	picture = TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(picture)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 12)
	column.add_child(status)
	var hint := Label.new()
	hint.text = "W/S 前后 · A/D 横移 · ←/→ 转向 · Ctrl/左键 开火 · E 开门 · 1–7 武器 · Space 跳跃（需开启）"
	hint.add_theme_font_size_override("font_size", 12)
	column.add_child(hint)
	previous_usec = Time.get_ticks_usec()
	_draw_frame()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.echo:
			get_viewport().set_input_as_handled()
			return
		var key: int = event.physical_keycode
		held[key] = event.pressed
		if event.pressed:
			if key == KEY_ESCAPE:
				_toggle_pause()
			elif key == KEY_F10:
				_return()
			elif key == KEY_F5:
				_restart()
			elif key >= KEY_1 and key <= KEY_7:
				requested_weapon = key - KEY_1
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		held["fire"] = event.pressed

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and bridge != null and bridge.running:
		_set_pause(true)

func _held(key) -> int:
	return 1 if held.get(key, false) else 0

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var seconds := float(now - previous_usec) / 1000000.0
	previous_usec = now
	advance_seconds(seconds)

func advance_seconds(seconds: float) -> Dictionary:
	if return_requested or not bridge.running:
		return {"ok": false, "error": "无活动会话"}
	if seconds < 0.0 or not is_finite(seconds):
		return {"ok": false, "error": "显示帧间隔无效"}
	if overload:
		return {"ok": false, "error": "积压超限；请重开或返回 ETN", "backlog": backlog}
	if bridge.paused:
		accumulator = 0.0
		backlog = 0
		return {"ok": true, "executed": 0, "backlog": 0}
	accumulator += seconds * TICS_PER_SECOND
	if accumulator > MAX_BACKLOG:
		backlog = int(accumulator)
		overload = true
		bridge.set_paused(true)
		held.clear()
		status.text = "模拟积压 %d tic 超过 %d；欠账已保留，请重新开始或返回 ETN。" % [backlog, MAX_BACKLOG]
		return {"ok": false, "error": "backlog_overflow", "backlog": backlog}
	var count := mini(int(accumulator + 0.000000001), MAX_TICS_PER_FRAME)
	for i in count:
		var speed := 50 if _held(KEY_SHIFT) else 25
		var buttons := 1 if _held(KEY_CTRL) or _held("fire") else 0
		if _held(KEY_E):
			buttons |= 2
		if requested_weapon >= 0:
			buttons |= 4 | (requested_weapon << 3)
			requested_weapon = -1
		var cmd := {"forward_move": (_held(KEY_W) - _held(KEY_S)) * speed, "side_move": (_held(KEY_D) - _held(KEY_A)) * speed, "angle_turn": (_held(KEY_LEFT) - _held(KEY_RIGHT)) * 640, "buttons": buttons, "arti": 128 if entry.options.jump and _held(KEY_SPACE) else 0}
		cmd.merge(test_input, true)
		var result: Dictionary = bridge.command(cmd)
		if not result.get("ok", false):
			_set_pause(true)
			status.text = "运行错误：" + str(result)
			return result
		accumulator -= 1.0
		executed_tics += 1
	backlog = int(accumulator)
	var event_result: Dictionary = bridge.read_events()
	bridge.acknowledge_events(int(event_result.latest_seq))
	if count > 0:
		_draw_frame()
	frame_count += 1
	status.text = "Crispy Doom 7.2 · tic %d · 待补 %d%s · %s" % [bridge.next_tic, backlog, "（性能不足，保留全部欠账）" if backlog >= BACKLOG_WARNING else "", "原生跳跃开启" if entry.options.jump else "原规则配置"]
	return {"ok": true, "executed": count, "backlog": backlog, "accumulator": accumulator}

func _draw_frame() -> void:
	var size: Dictionary = bridge.dimensions()
	var bytes: PackedByteArray = bridge.framebuffer()
	if bytes.size() != int(size.get("width", 0)) * int(size.get("height", 0)) * 4:
		status.text = "帧缓冲读取失败"
		return
	var image := Image.create_from_data(int(size.width), int(size.height), false, Image.FORMAT_RGBA8, bytes)
	if texture == null:
		texture = ImageTexture.create_from_image(image)
		picture.texture = texture
	else:
		texture.update(image)

func _set_pause(value: bool) -> void:
	if overload:
		return
	bridge.set_paused(value)
	accumulator = 0.0
	backlog = 0
	held.clear()
	requested_weapon = -1
	previous_usec = Time.get_ticks_usec()
	paused_button.text = "继续（Esc）" if bridge.paused else "暂停（Esc）"

func _toggle_pause() -> void:
	_set_pause(not bridge.paused)

func _restart() -> void:
	bridge.close()
	var result: Dictionary = bridge.create_session(entry.options.resource, entry.options.jump)
	if not result.get("ok", false):
		status.text = "重开失败：" + str(result)
		return
	overload = false
	_set_pause(false)
	_draw_frame()

func _return() -> void:
	return_requested = true
	entry.return_to_etn.call_deferred()
