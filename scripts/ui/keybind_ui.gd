class_name KeybindUI
extends CanvasLayer

signal closed

const ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down", &"jump", &"attack",
	&"dodge", &"interact", &"weapon_1", &"weapon_2", &"cast_1", &"cast_2",
	&"inventory", &"codex", &"map", &"settings", &"help", &"npc_inspire", &"pause",
]
const LABELS := {
	"move_left": "向左移动", "move_right": "向右移动", "move_up": "向上移动", "move_down": "向下移动",
	"jump": "跳跃", "attack": "攻击", "dodge": "翻滚", "interact": "交互",
	"weapon_1": "武器 1", "weapon_2": "武器 2", "cast_1": "短语 1", "cast_2": "短语 2",
	"inventory": "背包", "codex": "造句台", "map": "地图", "settings": "设置",
	"help": "操作说明", "npc_inspire": "对 NPC 言灵", "pause": "暂停",
}

var _root: Control
var _rows: VBoxContainer
var _waiting: StringName = &""
var _buttons: Dictionary = {}
var _hint: Label
var _close_button: Button
var _open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_build()
	_refresh()
	_refresh_device_hints()
	var flow := _flow_node()
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)
	visible = false


func open() -> void:
	visible = true
	_open = true
	_set_capture_active(true)
	_refresh()
	_focus_action(ACTIONS[0])


func close() -> void:
	if not _open:
		return
	_release_capture()
	_set_capture_active(false)
	_open = false
	visible = false
	closed.emit()
	queue_free()


func _exit_tree() -> void:
	_release_capture()
	_set_capture_active(false)


func is_open() -> bool:
	return _open


func _build() -> void:
	_root = Control.new()
	_root.theme = preload("res://resources/ui/theme.tres")
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = UIPalette.SHADE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 620)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)
	var title := Label.new()
	title.text = "键位设置"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_color", UIPalette.INK_FAINT)
	outer.add_child(_hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 5)
	scroll.add_child(_rows)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	outer.add_child(row)
	var reset := Button.new()
	reset.text = "恢复默认"
	reset.pressed.connect(func():
		var flow := _flow_node()
		if flow != null:
			flow.reset_keybinds()
			_refresh()
	)
	row.add_child(reset)
	_close_button = Button.new()
	_close_button.pressed.connect(close)
	row.add_child(_close_button)


func _refresh() -> void:
	if _rows == null:
		return
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_buttons.clear()
	for action in ACTIONS:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		var label := Label.new()
		label.text = String(LABELS.get(String(action), action))
		label.custom_minimum_size = Vector2(210, 0)
		label.add_theme_font_size_override("font_size", 12)
		line.add_child(label)
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 32)
		button.text = "按新键或手柄键…" if _waiting == action else GameFlow.input_label(action)
		button.pressed.connect(_begin_capture.bind(action))
		line.add_child(button)
		_rows.add_child(line)
		_buttons[action] = button


func _begin_capture(action: StringName) -> void:
	_waiting = action
	_refresh()
	# _refresh rebuilds every row button, including the one that was focused.
	# Without this the page loses keyboard/controller focus on the first press.
	_focus_action(action)


func _focus_action(action: StringName) -> void:
	var button := _buttons.get(action) as Button
	if button != null:
		button.grab_focus.call_deferred()


func _release_capture() -> void:
	_waiting = &""


func _set_capture_active(active: bool) -> void:
	var flow := _flow_node()
	if flow != null:
		flow.input_capture_active = active


func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


func _refresh_device_hints() -> void:
	var flow := _flow_node()
	var key := flow.close_prompt() if flow != null else "Esc"
	if _close_button != null:
		_close_button.text = "返回  [%s]" % key
	if _hint != null:
		if flow != null and flow.using_gamepad:
			_hint.text = "点击一个动作，然后按新键或手柄按键。按 B 或 Back 取消当前修改。"
		else:
			_hint.text = "点击一个动作，然后按新键或手柄按键。按 Esc 取消当前修改。"


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_device_hints()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if _waiting == &"":
		# ui_cancel is controller B; keyboard players use Esc / the close button.
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("settings") or event.is_action_pressed("pause"):
			close()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadButton and event.pressed:
		var joy := event as InputEventJoypadButton
		var action := _waiting
		if joy.button_index == JOY_BUTTON_BACK:
			_release_capture()
			_refresh()
			_focus_action(action)
			get_viewport().set_input_as_handled()
			return
		var flow := _flow_node()
		if flow != null:
			flow.set_joypad_bind(action, joy.button_index)
		_release_capture()
		_refresh()
		_focus_action(action)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.physical_keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
			return
		var action := _waiting
		if key.physical_keycode == KEY_ESCAPE:
			_release_capture()
			_refresh()
			_focus_action(action)
			get_viewport().set_input_as_handled()
			return
		var flow := _flow_node()
		if flow != null:
			flow.set_keybind(action, key.physical_keycode)
		_release_capture()
		_refresh()
		_focus_action(action)
		get_viewport().set_input_as_handled()
