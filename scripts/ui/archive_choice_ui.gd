class_name ArchiveChoiceUI
extends Control

## 归档 authority: on a final death, preserve exactly one carried item for the
## next run. Pauses the game and returns the chosen option index; the caller
## stores it on the Profile. Index -1 means the player explicitly skipped.

signal chosen(index: int)

const THEME = preload("res://resources/ui/theme.tres")

var _buttons: Array[Button] = []
var _skip_button: Button
var _was_paused := false
var _open := false
var _options: Array[Dictionary] = []
var _grid: GridContainer


func _ready() -> void:
	_build()


func _build() -> void:
	if _grid != null:
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
	panel.custom_minimum_size = Vector2(1000, 640)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var eyebrow := Label.new()
	eyebrow.text = "权柄 · 归档 · 死亡前最后一页"
	eyebrow.add_theme_font_size_override("font_size", 12)
	eyebrow.add_theme_color_override("font_color", UIPalette.CINNABAR)
	column.add_child(eyebrow)
	var title := Label.new()
	title.text = "选择一件物品带到下一局"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", UIPalette.INK)
	column.add_child(title)
	var hint := Label.new()
	hint.text = "只能带走一件。武器会替换下一局的起始武器；遗物会直接放进背包。"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", UIPalette.INK_FAINT)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 12)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)
	_skip_button = Button.new()
	_skip_button.name = "ArchiveSkipButton"
	_skip_button.text = "不带走任何东西"
	_skip_button.custom_minimum_size = Vector2(320, 44)
	_skip_button.add_theme_font_size_override("font_size", 24)
	_skip_button.pressed.connect(_choose.bind(-1))
	var skip_row := HBoxContainer.new()
	skip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(skip_row)
	skip_row.add_child(_skip_button)


func open(options: Array[Dictionary]) -> void:
	_build()
	_options = options.duplicate()
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.free()
	_buttons.clear()
	for index in _options.size():
		var entry: Dictionary = _options[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(460, 96)
		button.add_theme_font_size_override("font_size", 24)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_choose.bind(index))
		# Text is assigned after add_child so layout happens once against the
		# real theme (same pattern as the codex/shop card fix).
		_grid.add_child(button)
		button.text = "%s\n%s" % [String(entry.get("name", "物品")), String(entry.get("desc", ""))]
		_buttons.append(button)
	visible = true
	_open = true
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree != null:
		_was_paused = scene_tree.paused
		scene_tree.paused = true
	if not _buttons.is_empty() and _buttons[0].is_inside_tree():
		_buttons[0].grab_focus()
	elif _skip_button.is_inside_tree():
		_skip_button.grab_focus()


func is_open() -> bool:
	return _open


func get_option_count() -> int:
	return _buttons.size()


func get_option_text(index: int) -> String:
	if index < 0 or index >= _buttons.size():
		return ""
	return _buttons[index].text


func _choose(index: int) -> void:
	if not _open:
		return
	_open = false
	visible = false
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree != null:
		scene_tree.paused = _was_paused
	chosen.emit(index)
