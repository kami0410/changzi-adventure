class_name HelpUI
extends Control

signal closed

const THEME = preload("res://resources/ui/theme.tres")

var _panel: PanelContainer
var _explore_content: VBoxContainer
var _combat_content: VBoxContainer
var _close_button: Button
var _open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("help_ui")
	theme = THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()
	visibility_changed.connect(func():
		# The page doubles as a Settings subpage and as the help overlay: the
		# overlay path shows it with show(), so visibility is the source of
		# truth. Otherwise a page reopened that way had a dead close button.
		_open = visible
		if visible:
			_refresh_key_hints()
	)
	var flow := _flow_node()
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)
	_refresh_key_hints()
	_refresh_close_hint()


func open() -> void:
	_refresh_key_hints()
	_refresh_close_hint()
	visible = true
	_open = true
	var first := find_children("*", "Button", true, false)
	if not first.is_empty():
		(first[0] as Button).grab_focus()


func close() -> void:
	if not visible:
		return
	_open = false
	visible = false
	closed.emit()


func is_open() -> bool:
	return _open


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = UIPalette.SHADE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	# Width is fixed, height follows the content: a fixed 620 px page left a
	# third of the sheet blank under the two columns.
	_panel.custom_minimum_size = Vector2(960, 0)
	center.add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	_panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 18)
	margin.add_child(outer)
	var title := Label.new()
	title.text = "操作与言灵"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title)
	var hint := Label.new()
	hint.text = "所有键盘按键与手柄按键都能在「设置 → 键位设置」里改。菜单打开时游戏暂停。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", UIPalette.INK_FAINT)
	outer.add_child(hint)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 48)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(columns)
	var left := _make_column("探索")
	var right := _make_column("战斗与言灵")
	_explore_content = left.get_node("Content") as VBoxContainer
	_combat_content = right.get_node("Content") as VBoxContainer
	columns.add_child(left)
	columns.add_child(right)
	outer.add_child(HSeparator.new())
	outer.add_child(_make_close_row())


func _make_column(title_text: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", UIPalette.CINNABAR)
	column.add_child(title)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 10)
	column.add_child(content)
	return column


func _make_close_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_close_button = Button.new()
	_close_button.text = "继续冒险"
	_close_button.custom_minimum_size = Vector2(240, 44)
	_close_button.pressed.connect(close)
	row.add_child(_close_button)
	return row


func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


func _refresh_close_hint() -> void:
	if _close_button == null:
		return
	var flow := _flow_node()
	var key := flow.close_prompt() if flow != null else "Esc"
	_close_button.text = "继续冒险  [%s]" % key


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_close_hint()


func _refresh_key_hints() -> void:
	if _explore_content == null or _combat_content == null:
		return
	_clear(_explore_content)
	_clear(_combat_content)
	_add_line(_explore_content, "移动", "move_left / move_right")
	_add_line(_explore_content, "跳跃（空中再按＝二段跳）", "jump")
	_add_line(_explore_content, "翻滚（无敌帧）", "dodge")
	_add_line(_explore_content, "交互 / 开箱 / 呼叫电梯", "interact")
	_add_line(_explore_content, "背包", "inventory")
	_add_line(_explore_content, "造句台", "codex")
	_add_line(_explore_content, "设置", "settings")
	_add_line(_explore_content, "地图", "map")
	_add_line(_explore_content, "本说明", "help")
	_add_line(_combat_content, "轻攻击（连段 3 段）", "attack")
	_add_line(_combat_content, "切换武器", "weapon_1 / weapon_2")
	_add_line(_combat_content, "短语 1", "cast_1")
	_add_line(_combat_content, "短语 2", "cast_2")
	_add_line(_combat_content, "对 NPC 言灵", "npc_inspire")
	_add_line(_combat_content, "暂停", "pause")
	_add_hint(_combat_content, "提示：黄色预警＝攻击前摇；紫色＝深渊污染")
	_add_hint(_combat_content, "翻滚：可按方向向后滚；无敌帧内被击中＝完美闪避（回墨、重置冷却）；翻滚末尾出手必是重击")
	_add_hint(_combat_content, "平台可以从下方跳上去；按住下再跳可以落下")
	var flow := get_node_or_null("/root/Flow") as GameFlow
	if flow != null and flow.using_touch:
		_add_hint(_combat_content, "触屏：左半屏任意处按住即是摇杆；右侧按键可以滑动切换；按键大小与透明度在设置里调")


func _add_line(parent: VBoxContainer, label_text: String, action_text: String) -> void:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	var left_label := Label.new()
	left_label.text = label_text
	left_label.custom_minimum_size = Vector2(260, 0)
	left_label.add_theme_font_size_override("font_size", 24)
	line.add_child(left_label)
	var key_label := Label.new()
	var parts := action_text.split(" / ")
	var shown: Array[String] = []
	for part in parts:
		shown.append(GameFlow.input_label(StringName(part)))
	key_label.text = "  /  ".join(shown)
	key_label.add_theme_color_override("font_color", UIPalette.SEAL_GOLD)
	key_label.add_theme_font_size_override("font_size", 24)
	line.add_child(key_label)
	parent.add_child(line)


func _add_hint(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", UIPalette.INK_SOFT)
	parent.add_child(label)


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("help") or event.is_action_pressed("ui_cancel"):
		close()
		if is_inside_tree() and get_viewport() != null:
			get_viewport().set_input_as_handled()
