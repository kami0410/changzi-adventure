class_name KeybindUI
extends CanvasLayer

signal closed

const ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"jump", &"attack", &"dodge", &"interact",
	&"weapon_1", &"weapon_2", &"cast_1", &"cast_2", &"inventory", &"codex",
	&"settings", &"help", &"npc_inspire", &"pause",
]
const LABELS := {
	"move_left": "向左移动", "move_right": "向右移动", "jump": "跳跃",
	"attack": "攻击", "dodge": "翻滚", "interact": "交互",
	"weapon_1": "武器 1", "weapon_2": "武器 2", "cast_1": "短语 1", "cast_2": "短语 2",
	"inventory": "背包", "codex": "造句台", "settings": "设置", "help": "操作说明",
	"npc_inspire": "对 NPC 言灵", "pause": "暂停",
}

var _root: Control
var _rows: VBoxContainer
var _waiting: StringName = &""
var _buttons: Dictionary = {}
var _open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_build()
	_refresh()
	visible = false


func open() -> void:
	visible = true
	_open = true
	_refresh()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	closed.emit()
	queue_free()


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
	var hint := Label.new()
	hint.text = "点击一个动作，然后按下新键。Esc 取消当前修改。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", UIPalette.INK_FAINT)
	outer.add_child(hint)
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
		var flow := get_node_or_null("/root/Flow") as GameFlow
		if flow != null:
			flow.reset_keybinds()
			_refresh()
	)
	row.add_child(reset)
	var close_button := Button.new()
	close_button.text = "返回  [Esc]"
	close_button.pressed.connect(close)
	row.add_child(close_button)


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
		button.text = "按新键…" if _waiting == action else GameFlow.key_label(action)
		button.pressed.connect(_begin_capture.bind(action))
		line.add_child(button)
		_rows.add_child(line)
		_buttons[action] = button


func _begin_capture(action: StringName) -> void:
	_waiting = action
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not _open or _waiting == &"":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.physical_keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
			return
		if key.physical_keycode == KEY_ESCAPE:
			_waiting = &""
			_refresh()
			get_viewport().set_input_as_handled()
			return
		var flow := get_node_or_null("/root/Flow") as GameFlow
		if flow != null:
			flow.set_keybind(_waiting, key.physical_keycode)
		_waiting = &""
		_refresh()
		get_viewport().set_input_as_handled()
