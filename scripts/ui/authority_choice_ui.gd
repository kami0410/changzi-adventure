class_name AuthorityChoiceUI
extends Control

## Boss reward: choose one authority for the rest of the run. Pauses the game
## and returns the chosen index; AuthorityEffects/game own the actual effect.

signal chosen(index: int)

const THEME = preload("res://resources/ui/theme.tres")

var _buttons: Array[Button] = []
var _was_paused := false
var _open := false
var _title: Label
var _row: HBoxContainer


func _ready() -> void:
	_build()


func _build() -> void:
	if _row != null:
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var shade := ColorRect.new()
	shade.color = UIPalette.SHADE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(980, 420)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	var eyebrow := Label.new()
	eyebrow.text = "权柄 · 记住它，它会在这一局改变规则"
	eyebrow.add_theme_font_size_override("font_size", 12)
	eyebrow.add_theme_color_override("font_color", UIPalette.CINNABAR)
	column.add_child(eyebrow)
	_title = Label.new()
	_title.text = "选择一条权柄"
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_color_override("font_color", UIPalette.INK)
	column.add_child(_title)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 18)
	column.add_child(_row)


func open(options: Array[AuthorityData]) -> void:
	_build()
	for child in _row.get_children():
		_row.remove_child(child)
		child.free()
	_buttons.clear()
	for index in options.size():
		var authority := options[index]
		if authority == null:
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(440, 220)
		button.text = "%s\n\n%s" % [authority.display_name, authority.description]
		button.add_theme_font_size_override("font_size", 24)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_choose.bind(index))
		_row.add_child(button)
		_buttons.append(button)
	visible = true
	_open = true
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree != null:
		_was_paused = scene_tree.paused
		scene_tree.paused = true
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func get_button_count() -> int:
	return _buttons.size()


func _choose(index: int) -> void:
	if not _open:
		return
	_open = false
	visible = false
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree != null:
		scene_tree.paused = _was_paused
	chosen.emit(index)
