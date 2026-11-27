extends Control

const SCENARIOS := [
	{"name": "自制 MAP01 夹具", "resource": "fixture", "episode": 1},
	{"name": "Doom II", "resource": "doom2", "episode": 1},
	{"name": "The Ultimate Doom", "resource": "doom", "episode": 1},
	{"name": "DSS · Episode 2", "resource": "dss", "episode": 2},
	{"name": "DSS · Episode 4", "resource": "dss", "episode": 4},
]

var entry: Node
var scenario: OptionButton
var skill: OptionButton
var episode: SpinBox
var map: SpinBox
var jump: CheckBox
var start_mode: OptionButton
var slots: OptionButton
var fullscreen: CheckBox
var details: Label
var message: Label
var start_button: Button
var slot_records: Array[Dictionary] = []
var changing := false

func _ready() -> void:
	name = "M1_TestLauncher"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.02, 0.03, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	var inset := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		inset.add_theme_constant_override("margin_" + side, 10)
	panel.add_child(inset)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	inset.add_child(column)
	var title := Label.new()
	title.text = "ETNDOOM · M1 人工回归"
	title.add_theme_font_size_override("font_size", 18)
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 5)
	form.add_theme_font_size_override("font_size", 12)
	scroll.add_child(form)
	scenario = OptionButton.new()
	for item in SCENARIOS:
		scenario.add_item(item.name)
	_row(form, "测试方案", scenario)
	skill = OptionButton.new()
	for item in ["1 · I'm too young to die", "2 · Hey, not too rough", "3 · Hurt me plenty", "4 · Ultra-Violence", "5 · Nightmare"]:
		skill.add_item(item)
	_row(form, "难度", skill)
	var location := HBoxContainer.new()
	episode = SpinBox.new()
	episode.prefix = "Episode "
	episode.min_value = 1
	episode.max_value = 4
	episode.custom_minimum_size.x = 135
	location.add_child(episode)
	map = SpinBox.new()
	map.prefix = "Map "
	map.min_value = 1
	map.custom_minimum_size.x = 120
	location.add_child(map)
	jump = CheckBox.new()
	jump.text = "启用跳跃"
	location.add_child(jump)
	_row(form, "新游戏参数", location)
	start_mode = OptionButton.new()
	start_mode.add_item("开始新游戏")
	start_mode.add_item("读取本地存档")
	_row(form, "启动方式", start_mode)
	var save_row := HBoxContainer.new()
	slots = OptionButton.new()
	slots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	save_row.add_child(slots)
	var refresh := Button.new()
	refresh.text = "刷新"
	refresh.pressed.connect(_refresh_slots)
	save_row.add_child(refresh)
	_row(form, "存档选择", save_row)
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 12)
	form.add_child(details)
	fullscreen = CheckBox.new()
	fullscreen.text = "全屏游玩（退出后恢复 ETN 窗口）"
	fullscreen.button_pressed = true
	form.add_child(fullscreen)
	var persistence := Label.new()
	persistence.text = "存档按资源与跳跃规则分别保存在本地，重复启动可继续游玩。旧构建存档会保留，并显示兼容性。"
	persistence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	persistence.add_theme_font_size_override("font_size", 12)
	form.add_child(persistence)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 12)
	column.add_child(message)
	var actions := HBoxContainer.new()
	var back := Button.new()
	back.text = "返回 ETN"
	back.pressed.connect(entry.close_launcher)
	actions.add_child(back)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	start_button = Button.new()
	start_button.text = "开始"
	start_button.custom_minimum_size.x = 110
	start_button.pressed.connect(_launch)
	actions.add_child(start_button)
	column.add_child(actions)
	for row in form.get_children():
		if row is HBoxContainer:
			row.add_theme_constant_override("separation", 8)
	changing = true
	var initial_resource := str(entry.options.get("resource", "fixture"))
	var initial_episode := int(entry.options.get("episode", 1))
	var initial_index := 0
	for index in SCENARIOS.size():
		if SCENARIOS[index].resource == initial_resource:
			initial_index = index
			if initial_resource != "dss" or int(SCENARIOS[index].episode) == initial_episode:
				break
	scenario.select(initial_index)
	_configure_bounds()
	skill.select(clampi(int(entry.options.get("skill", 3)) - 1, 0, 4))
	episode.value = initial_episode
	map.value = int(entry.options.get("map", 1))
	jump.button_pressed = bool(entry.options.get("jump", false))
	changing = false
	scenario.item_selected.connect(_scenario_changed)
	episode.value_changed.connect(func(_value: float): _update_start())
	map.value_changed.connect(func(_value: float): _update_start())
	jump.toggled.connect(func(_value: bool): _refresh_slots())
	start_mode.item_selected.connect(func(_index: int): _update_start())
	slots.item_selected.connect(func(_index: int): _update_start())
	_refresh_slots()
	var initial_slot := int(entry.options.get("load_slot", -1))
	if initial_slot >= 0:
		start_mode.select(1)
		for index in slot_records.size():
			if int(slot_records[index].slot) == initial_slot:
				slots.select(index)
				break
		_update_start()
	start_button.grab_focus()

func _row(parent: VBoxContainer, label_text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 88
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.add_theme_font_size_override("font_size", 12)
	row.add_child(control)
	parent.add_child(row)

func _resource() -> String:
	return str(SCENARIOS[scenario.selected].resource)

func _configure_bounds() -> void:
	var resource := _resource()
	episode.max_value = 4 if resource in ["doom", "dss"] else 1
	map.max_value = 9 if resource in ["doom", "dss"] else (1 if resource == "fixture" else 32)

func _scenario_changed(_index: int) -> void:
	changing = true
	_configure_bounds()
	episode.value = int(SCENARIOS[scenario.selected].episode)
	map.value = 1
	changing = false
	_refresh_slots()

func _refresh_slots() -> void:
	if changing:
		return
	var old_slot := int(slot_records[slots.selected].slot) if slots.selected >= 0 and slots.selected < slot_records.size() else -1
	slots.clear()
	slot_records.clear()
	var records: Array = entry.bridge.save_slots(_resource(), jump.button_pressed)
	for record in records:
		if not record.get("exists", false):
			continue
		slot_records.append(record)
		var label := "槽 %02d · %s" % [int(record.slot) + 1, str(record.get("description", "未命名存档"))]
		if not record.get("compatible", false):
			label += " · 不兼容"
		slots.add_item(label)
		if int(record.slot) == old_slot:
			slots.select(slots.item_count - 1)
	if slots.item_count > 0 and slots.selected < 0:
		slots.select(0)
	if slot_records.is_empty():
		slots.add_item("此资源与跳跃规则下没有存档")
	_update_start()

func _modified_text(value: Variant) -> String:
	if value is int or value is float:
		return Time.get_datetime_string_from_unix_time(int(value), true) + " UTC" if int(value) > 0 else "未知时间"
	return str(value) if not str(value).is_empty() else "未知时间"

func _update_start() -> void:
	if changing or start_button == null:
		return
	var loading := start_mode.selected == 1
	skill.disabled = loading
	episode.editable = not loading
	map.editable = not loading
	slots.disabled = not loading or slot_records.is_empty()
	start_button.disabled = false
	start_button.text = "读取并开始" if loading else "开始新游戏"
	message.text = ""
	if slot_records.is_empty():
		details.text = "当前方案尚无本地存档。"
		start_button.disabled = loading
		return
	var record: Dictionary = slot_records[maxi(0, slots.selected)]
	var location := "E%dM%d" % [int(record.get("episode", 1)), int(record.get("map", 1))] if _resource() in ["doom", "dss"] else "MAP%02d" % int(record.get("map", 1))
	var compatibility := "兼容当前构建" if record.get("compatible", false) else "不兼容：" + str(record.get("error", "构建或资源身份不一致"))
	details.text = "%s · 难度 %d · %s\n%s" % [location, int(record.get("skill", 3)), _modified_text(record.get("modified", "")), compatibility]
	if loading and not record.get("compatible", false):
		start_button.disabled = true

func _launch() -> void:
	var selected_slot := -1
	if start_mode.selected == 1:
		if slot_records.is_empty() or slots.selected < 0:
			return
		var record: Dictionary = slot_records[slots.selected]
		if not record.get("compatible", false):
			return
		selected_slot = int(record.slot)
	start_button.disabled = true
	message.text = "正在启动…"
	var result: Dictionary = entry.launch_test({"resource": _resource(), "jump": jump.button_pressed, "skill": skill.selected + 1, "episode": int(episode.value), "map": int(map.value), "load_slot": selected_slot, "fullscreen": fullscreen.button_pressed})
	if not result.get("ok", false):
		message.text = "启动失败：" + str(result.get("error", result))
		start_button.disabled = false
