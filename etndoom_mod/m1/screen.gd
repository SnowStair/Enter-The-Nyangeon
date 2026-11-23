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
var slot: SpinBox
var notice: Label
var last_event_seq := 0
var new_game_dialog: ConfirmationDialog
var skill_select: OptionButton
var episode_select: SpinBox
var map_select: SpinBox

func _ready() -> void:
	name = "ETNDOOM_M1"
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
	column.add_theme_constant_override("separation", 2)
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
	restart.text = "重开本图（F5）"
	restart.pressed.connect(_restart)
	tools.add_child(restart)
	var more := HBoxContainer.new()
	column.add_child(more)
	for spec in [["新游戏", _new_game], ["重生/确认（Enter）", _confirm], ["保存（F6）", _save], ["读取（F7）", _load]]:
		var button := Button.new()
		button.text = spec[0]
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(spec[1])
		more.add_child(button)
	slot = SpinBox.new()
	slot.min_value = 1
	slot.max_value = 8
	slot.value = 1
	slot.prefix = "槽"
	slot.custom_minimum_size.x = 66
	more.add_child(slot)
	for button in tools.get_children():
		button.add_theme_font_size_override("font_size", 12)
		button.focus_mode = Control.FOCUS_NONE
	for button in more.get_children():
		if button is Button:
			button.focus_mode = Control.FOCUS_NONE
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
	notice = Label.new()
	notice.add_theme_font_size_override("font_size", 12)
	notice.text = "M1 · " + entry.options.resource
	column.add_child(notice)
	var hint := Label.new()
	hint.text = "WASD 移动 · ←/→ 转向 · Ctrl/画面左键 开火 · E 使用 · 1–7 武器 · Space 跳跃"
	hint.add_theme_font_size_override("font_size", 12)
	column.add_child(hint)
	previous_usec = Time.get_ticks_usec()
	_draw_frame()
	_build_new_game_dialog()

func _input(event: InputEvent) -> void:
	if new_game_dialog != null and new_game_dialog.visible:
		return
	if event is InputEventKey:
		if get_viewport().gui_get_focus_owner() is LineEdit and event.physical_keycode not in [KEY_ESCAPE, KEY_F10]:
			return
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
			elif key == KEY_F6:
				_save()
			elif key == KEY_F7:
				_load()
			elif key == KEY_ENTER or key == KEY_KP_ENTER:
				_confirm()
			elif key >= KEY_1 and key <= KEY_7:
				requested_weapon = key - KEY_1
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		held["fire"] = event.pressed and picture.get_global_rect().has_point(event.position)
		if held["fire"] and get_viewport().gui_get_focus_owner() != null:
			get_viewport().gui_get_focus_owner().release_focus()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and bridge != null and bridge.running:
		_set_pause(true, "focus")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and bridge != null and bridge.running:
		_set_pause(false, "focus")

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
		if not _consume_events():
			return {"ok": false, "error": "事件消费失败"}
		return {"ok": true, "executed": 0, "backlog": 0}
	accumulator += seconds * TICS_PER_SECOND
	if accumulator > MAX_BACKLOG:
		backlog = int(accumulator)
		overload = true
		bridge.set_paused(true, "overload")
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
			if bridge.running:
				_set_pause(true)
			else:
				held.clear()
				requested_weapon = -1
				accumulator = 0.0
			status.text = "运行错误：" + str(result)
			return result
		accumulator -= 1.0
		executed_tics += 1
		if not _consume_events():
			return {"ok": false, "error": "事件消费失败"}
	backlog = int(accumulator)
	if not _consume_events():
		return {"ok": false, "error": "事件消费失败"}
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

func _consume_events() -> bool:
	var result: Dictionary = bridge.read_events(last_event_seq)
	if not result.get("ok", false):
		status.text = "事件读取失败：" + str(result.get("error", result))
		if bridge.running:
			bridge.close()
		return false
	for item in result.events:
		# 原生后端已消费音频；界面消费流程/请求结果，快照用于重建全部表现。
		if item.type == "world_changed":
			held.clear()
			requested_weapon = -1
		elif item.type == "request_failed":
			notice.text = "操作失败：" + str(item.payload.get("error", item.payload))
		elif item.type == "request_completed":
			notice.text = "操作已完成：" + str(item.payload.get("operation", item.payload.get("request_id", "")))
		elif item.type == "request_cancelled":
			notice.text = "待处理操作已取消：" + str(item.payload.get("request_id", ""))
		last_event_seq = int(item.event_seq)
	var acknowledged: Dictionary = bridge.acknowledge_events(last_event_seq)
	if not acknowledged.get("ok", false):
		status.text = "事件确认失败：" + str(acknowledged)
		bridge.close()
		return false
	return true

func _set_pause(value: bool, reason: String = "manual") -> void:
	if overload or not bridge.running:
		return
	if not _consume_events():
		return
	var response: Dictionary = bridge.set_paused(value, reason)
	if not response.get("ok", false):
		status.text = "暂停变更失败：" + str(response)
		return
	accumulator = 0.0
	backlog = 0
	held.clear()
	requested_weapon = -1
	previous_usec = Time.get_ticks_usec()
	paused_button.text = "继续（Esc）" if bridge.paused else "暂停（Esc）"

func _toggle_pause() -> void:
	_set_pause(not bridge.pause_reasons.has("manual"))

func _restart() -> void:
	_control("restart_level")

func _confirm() -> void:
	var current: Dictionary = bridge.snapshot()
	if current.get("world_valid", false) and int(current.get("player", {}).get("state", 0)) == 1:
		_control("reborn")
	else:
		_control("confirm")

func _save() -> void:
	_control("save", int(slot.value) - 1)

func _load() -> void:
	_control("load", int(slot.value) - 1)

func _control(action: String, a: int = 0, b: int = 0, c: int = 0) -> void:
	var response: Dictionary = bridge.request_flow_action(action, a, b, c)
	notice.text = (("已完成：" if response.get("completed", false) else "已接受：") if response.get("ok", false) else "操作失败：") + action + ("" if response.get("ok", false) else " · " + str(response.get("error", response)))
	if response.get("ok", false):
		if action in ["new_game", "restart_level", "reborn", "load"]:
			overload = false
			accumulator = 0.0
			backlog = 0
			bridge.set_paused(false, "overload")
		held.clear()
		requested_weapon = -1
		previous_usec = Time.get_ticks_usec()
		if bridge.running:
			_draw_frame()
	_consume_events()

func _build_new_game_dialog() -> void:
	new_game_dialog = ConfirmationDialog.new()
	new_game_dialog.title = "新游戏 · " + entry.options.resource
	new_game_dialog.ok_button_text = "开始"
	new_game_dialog.cancel_button_text = "取消"
	add_child(new_game_dialog)
	var form := VBoxContainer.new()
	new_game_dialog.add_child(form)
	skill_select = OptionButton.new()
	for value in ["1 · I'm too young to die", "2 · Hey, not too rough", "3 · Hurt me plenty", "4 · Ultra-Violence", "5 · Nightmare"]:
		skill_select.add_item(value)
	skill_select.select(entry.options.skill - 1)
	form.add_child(skill_select)
	episode_select = SpinBox.new()
	episode_select.prefix = "Episode"
	episode_select.min_value = 1
	episode_select.max_value = 4 if entry.options.resource in ["doom", "dss"] else 1
	episode_select.value = entry.options.episode
	form.add_child(episode_select)
	map_select = SpinBox.new()
	map_select.prefix = "Map"
	map_select.min_value = 1
	map_select.max_value = 9 if entry.options.resource in ["doom", "dss"] else (1 if entry.options.resource == "fixture" else 32)
	map_select.value = entry.options.map
	form.add_child(map_select)
	new_game_dialog.confirmed.connect(func():
		_control("new_game", skill_select.selected + 1, int(episode_select.value), int(map_select.value))
		_set_pause(false, "dialog"))
	new_game_dialog.canceled.connect(func(): _set_pause(false, "dialog"))

func _new_game() -> void:
	_set_pause(true, "dialog")
	if bridge.running and bridge.pause_reasons.has("dialog"):
		new_game_dialog.popup_centered(Vector2i(340, 180))

func _return() -> void:
	return_requested = true
	entry.return_to_etn.call_deferred()
