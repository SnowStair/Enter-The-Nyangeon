extends Control

const TICS_PER_SECOND := 35.0
const MAX_TICS_PER_FRAME := 8
const BACKLOG_WARNING := 70
const MAX_BACKLOG := 350
const DOOM_RIGHT := 0xae
const DOOM_LEFT := 0xac
const DOOM_UP := 0xad
const DOOM_DOWN := 0xaf
const DOOM_ESCAPE := 27
const DOOM_ENTER := 13
const DOOM_BACKSPACE := 0x7f
const DOOM_PAUSE := 0xff
const DOOM_F1 := 0xbb
const DOOM_F2 := 0xbc
const DOOM_F3 := 0xbd
const DOOM_F4 := 0xbe
const DOOM_F5 := 0xbf
const DOOM_F6 := 0xc0
const DOOM_F7 := 0xc1
const DOOM_F8 := 0xc2
const DOOM_F9 := 0xc3
const DOOM_F10 := 0xc4
const DOOM_F11 := 0xd7
const DOOM_F12 := 0xd8
const DOOM_RSHIFT := 0xb6
const DOOM_RCTRL := 0x9d
const DOOM_RALT := 0xb8
const SMOOTH_PIXEL_SHADER := """
shader_type canvas_item;
render_mode unshaded;
uniform vec2 integer_scale = vec2(1.0);
void fragment() {
    // 等价于 Crispy 的 nearest 整数上采样，再以 linear 缩放到窗口。
    vec2 source = UV / TEXTURE_PIXEL_SIZE - vec2(0.5);
    vec2 blend = clamp((fract(source) - vec2(0.5)) * integer_scale + vec2(0.5), vec2(0.0), vec2(1.0));
    vec2 sample_uv = (floor(source) + blend + vec2(0.5)) * TEXTURE_PIXEL_SIZE;
    COLOR = texture(TEXTURE, sample_uv);
}
"""

var entry: Node
var bridge: RefCounted
var texture: ImageTexture
var picture: TextureRect
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
var slot := 0
var last_event_seq := 0
var interactive := true
var native_ui: Dictionary = {}
var _applied_window_settings: Dictionary = {}
var _display_size := Vector2i.ZERO
var error_dialog: AcceptDialog
var _smooth_material: ShaderMaterial
var _use_alias_down := false
var _space_down := false

func _ready() -> void:
	name = "ETNDOOM_M1"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	picture = TextureRect.new()
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	var shader := Shader.new()
	shader.code = SMOOTH_PIXEL_SHADER
	_smooth_material = ShaderMaterial.new()
	_smooth_material.shader = shader
	previous_usec = Time.get_ticks_usec()
	_apply_native_window_settings()
	_sync_native_ui()
	_draw_frame()

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var seconds := float(now - previous_usec) / 1000000.0
	previous_usec = now
	advance_seconds(seconds)

func _input(event: InputEvent) -> void:
	if return_requested or bridge == null or not bridge.running:
		return
	if is_instance_valid(error_dialog) and error_dialog.visible:
		return
	if event is InputEventKey:
		if event.echo and not native_ui.get("menu_active", false):
			get_viewport().set_input_as_handled()
			return
		var doom_key := _doom_key(event)
		if doom_key >= 0:
			interactive = true
			var gameplay_input: bool = not bridge.paused and not native_ui.get("menu_active", false) and not native_ui.get("native_paused", false)
			if event.physical_keycode == KEY_SPACE:
				_space_down = event.pressed
			# E 和 Space 同时按住时，任一个松开都不能提前释放使用键。
			if event.physical_keycode != KEY_SPACE or event.pressed or not _use_alias_down:
				_send_input(1 if event.pressed else 0, doom_key, event.unicode if event.unicode < 128 else 0, event.unicode if event.unicode < 128 else 0)
			_sync_native_ui()
			# 保留原始 E 给原生菜单/秘籍；仅游玩时额外按下默认使用键。
			if event.physical_keycode == KEY_E:
				if event.pressed and gameplay_input and not native_ui.get("menu_active", false):
					_use_alias_down = true
					if not _space_down:
						_send_input(1, 32, 32, 32)
				elif not event.pressed and _use_alias_down:
					_use_alias_down = false
					if not _space_down:
						_send_input(0, 32, 0, 0)
			if not event.pressed and event.physical_keycode == KEY_ESCAPE and native_ui.get("menu_active", false) == false:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		interactive = true
		_send_input(2, int(event.button_mask) & 7, clampi(int(round(event.screen_relative.x)), -32768, 32767), clampi(-int(round(event.screen_relative.y)), -32768, 32767))
		_sync_native_ui()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			interactive = true
			_send_input(2, int(event.button_mask), 0, 0)
			if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
				_send_input(2, int(event.button_mask) & 7, 0, 0)
			_sync_native_ui()
			get_viewport().set_input_as_handled()

func _doom_key(event: InputEventKey) -> int:
	var key := int(event.physical_keycode)
	match key:
		KEY_ESCAPE: return DOOM_ESCAPE
		KEY_ENTER, KEY_KP_ENTER: return DOOM_ENTER
		KEY_BACKSPACE: return DOOM_BACKSPACE
		KEY_TAB: return 9
		KEY_PAUSE: return DOOM_PAUSE
		KEY_UP: return DOOM_UP
		KEY_DOWN: return DOOM_DOWN
		KEY_LEFT: return DOOM_LEFT
		KEY_RIGHT: return DOOM_RIGHT
		KEY_F1: return DOOM_F1
		KEY_F2: return DOOM_F2
		KEY_F3: return DOOM_F3
		KEY_F4: return DOOM_F4
		KEY_F5: return DOOM_F5
		KEY_F6: return DOOM_F6
		KEY_F7: return DOOM_F7
		KEY_F8: return DOOM_F8
		KEY_F9: return DOOM_F9
		KEY_F10: return DOOM_F10
		KEY_F11: return DOOM_F11
		KEY_F12: return DOOM_F12
		KEY_SHIFT: return DOOM_RSHIFT
		KEY_CTRL: return DOOM_RCTRL
		KEY_ALT: return DOOM_RALT
		KEY_DELETE: return 0xd3
		KEY_HOME: return 0xc7
		KEY_END: return 0xcf
		KEY_PAGEUP: return 0xc9
		KEY_PAGEDOWN: return 0xd1
		KEY_INSERT: return 0xd2
		KEY_CAPSLOCK: return 0xba
		KEY_NUMLOCK: return 0xc5
		KEY_SCROLLLOCK: return 0xc6
		KEY_KP_ADD: return 43
		KEY_KP_SUBTRACT: return 45
		KEY_KP_MULTIPLY: return 42
		KEY_KP_DIVIDE: return 47
		KEY_EQUAL: return 0x3d
		KEY_MINUS: return 0x2d
		KEY_SPACE: return 32
		_:
			if key >= KEY_A and key <= KEY_Z:
				return key + 32
			if key >= 32 and key <= 126:
				return key
	return -1

func _send_input(kind: int, a: int, b: int, c: int) -> void:
	var result: Dictionary = bridge.input_event(kind, a, b, c)
	if not result.get("ok", false):
		_show_error("Crispy Doom 输入失败：%s" % result)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and bridge != null and bridge.running:
		_set_pause(true, "focus")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and bridge != null and bridge.running:
		_set_pause(false, "focus")

func _process_legacy_tick() -> Dictionary:
	var speed := 50 if _held(KEY_SHIFT) else 25
	var buttons := 1 if _held(KEY_CTRL) else 0
	if _held(KEY_E):
		buttons |= 2
	if requested_weapon >= 0:
		buttons |= 4 | (requested_weapon << 3)
		requested_weapon = -1
	var cmd := {"forward_move": (_held(KEY_W) - _held(KEY_S)) * speed, "side_move": (_held(KEY_D) - _held(KEY_A)) * speed, "angle_turn": (_held(KEY_LEFT) - _held(KEY_RIGHT)) * 640, "buttons": buttons, "arti": 128 if entry.options.jump and _held(KEY_SPACE) else 0}
	cmd.merge(test_input, true)
	return bridge.command(cmd, false)

func _held(key) -> int:
	return 1 if held.get(key, false) else 0

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
		_show_error("模拟积压 %d tic；请返回测试入口后重新开始。" % backlog)
		return {"ok": false, "error": "backlog_overflow", "backlog": backlog}
	var count := mini(int(accumulator + 0.000000001), MAX_TICS_PER_FRAME)
	var executed := 0
	if interactive and test_input.is_empty():
		_sync_display_size()
	for _i in count:
		var result: Dictionary = bridge.play_tick() if interactive and test_input.is_empty() else _process_legacy_tick()
		if not result.get("ok", false):
			if bridge.running:
				_set_pause(true)
			else:
				held.clear()
				requested_weapon = -1
				accumulator = 0.0
			_show_error("Crispy Doom 运行失败：%s" % result)
			return result
		accumulator -= 1.0
		executed += int(result.get("executed", 0))
		executed_tics += int(result.get("executed", 0))
		if not _consume_events():
			return {"ok": false, "error": "事件消费失败"}
	backlog = int(accumulator)
	_sync_native_ui()
	if bridge.interactive and native_ui.get("uncapped", false):
		bridge.input_event(5, int(clampf(accumulator, 0.0, 1.0) * 65536.0))
	_draw_frame()
	frame_count += 1
	return {"ok": true, "executed": executed, "backlog": backlog, "accumulator": accumulator}

func _sync_native_ui() -> void:
	if bridge == null or not bridge.running:
		return
	native_ui = bridge.ui_status()
	if native_ui.get("quit_requested", false):
		return_requested = true
		entry.return_to_launcher.call_deferred()
		return
	if bridge.paused or native_ui.get("menu_active", false) or native_ui.get("native_paused", false) or (is_instance_valid(error_dialog) and error_dialog.visible):
		_use_alias_down = false
		_space_down = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_native_window_settings()

func _apply_native_window_settings() -> void:
	if native_ui.is_empty():
		return
	var window := get_window()
	if window == null:
		return
	var vsync := int(native_ui.get("vsync", 0))
	var fps := int(native_ui.get("fps_limit", 0)) if native_ui.get("uncapped", false) else 35
	var settings := {"vsync": vsync, "fps": fps}
	if settings != _applied_window_settings:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync != 0 else DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = fps
		_applied_window_settings = settings
	var smooth := bool(native_ui.get("smooth_scaling", false))
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if smooth else CanvasItem.TEXTURE_FILTER_NEAREST
	picture.material = _smooth_material if smooth else null

func _sync_display_size() -> void:
	var display := DisplayServer.window_get_size()
	if display != _display_size and display.x > 0 and display.y > 0:
		bridge.input_event(4, display.x, display.y)
		_display_size = display

func _draw_frame() -> void:
	if bridge == null or not bridge.running:
		return
	var size: Dictionary = bridge.dimensions()
	var width := int(size.get("width", 0))
	var height := int(size.get("height", 0))
	var bytes: PackedByteArray = bridge.framebuffer()
	if width <= 0 or height <= 0 or bytes.size() != width * height * 4:
		push_error("Crispy Doom 帧缓冲读取失败")
		return
	var image := Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, bytes)
	if texture == null or texture.get_width() != width or texture.get_height() != height:
		texture = ImageTexture.create_from_image(image)
		picture.texture = texture
	else:
		texture.update(image)
	var target_aspect := float(width) / (float(height) * (1.2 if native_ui.get("aspect_ratio_correct", true) else 1.0))
	var frame_size := self.size
	if frame_size.x / maxf(frame_size.y, 1.0) > target_aspect:
		frame_size.x = frame_size.y * target_aspect
	else:
		frame_size.y = frame_size.x / target_aspect
	picture.set_anchors_preset(Control.PRESET_TOP_LEFT)
	picture.position = (self.size - frame_size) * 0.5
	picture.size = frame_size
	var output_size := frame_size * Vector2(DisplayServer.window_get_size()) / self.size.max(Vector2.ONE)
	var integer_scale := Vector2(maxf(1.0, ceilf(floorf(output_size.x + 0.001) / float(width))), maxf(1.0, ceilf(floorf(output_size.y + 0.001) / float(height))))
	_smooth_material.set_shader_parameter("integer_scale", integer_scale)

func _consume_events() -> bool:
	var result: Dictionary = bridge.read_events(last_event_seq)
	if not result.get("ok", false):
		push_error("M1 事件读取失败：%s" % result.get("error", result))
		if bridge.running:
			bridge.close()
		return false
	for item in result.events:
		if item.type == "world_changed":
			held.clear()
			requested_weapon = -1
		elif item.type in ["request_failed", "request_cancelled"]:
			push_warning("M1 请求未完成：%s" % item.payload)
		last_event_seq = int(item.event_seq)
	var acknowledged: Dictionary = bridge.acknowledge_events(last_event_seq)
	if not acknowledged.get("ok", false):
		push_error("M1 事件确认失败：%s" % acknowledged)
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
		push_error("暂停变更失败：%s" % response)
		return
	accumulator = 0.0
	backlog = 0
	held.clear()
	requested_weapon = -1
	if bridge.interactive:
		bridge.input_event(3)
	previous_usec = Time.get_ticks_usec()
	_sync_native_ui()

func _toggle_pause() -> void:
	if interactive:
		bridge.input_event(1, DOOM_ESCAPE, DOOM_ESCAPE, DOOM_ESCAPE)
		_sync_native_ui()
		_draw_frame()
	else:
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
	_control("save", slot)

func _load() -> void:
	_control("load", slot)

func _control(action: String, a: int = 0, b: int = 0, c: int = 0) -> void:
	var response: Dictionary = bridge.request_flow_action(action, a, b, c)
	if not response.get("ok", false):
		push_warning("Crispy Doom 操作失败：%s" % response)
	if response.get("ok", false) and action in ["new_game", "restart_level", "reborn", "load"]:
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

func _new_game() -> void:
	_toggle_pause()

func _show_error(message: String) -> void:
	push_error(message)
	if not is_instance_valid(error_dialog):
		error_dialog = AcceptDialog.new()
		error_dialog.title = "Crispy Doom"
		error_dialog.ok_button_text = "返回测试入口"
		error_dialog.confirmed.connect(func(): entry.return_to_launcher())
		error_dialog.canceled.connect(func(): entry.return_to_launcher())
		add_child(error_dialog)
	error_dialog.dialog_text = message
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	error_dialog.popup_centered(Vector2i(520, 180))

func _return() -> void:
	return_requested = true
	entry.return_to_etn.call_deferred()
