class_name MapOverlay
extends Control

## Archive map for the MDS chapter pilot. MDSWorldMapView draws the world file;
## MDSWorldGame feeds it visited rooms and the player's position.

signal closed

const THEME = preload("res://resources/ui/theme.tres")
const WORLD_FILE := "res://scenes/mds/chapter_1.mdsworld.json"

var map_view: MDSWorldMapView
var _root: Control
var _open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = UIPalette.SHADE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1060, 660)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	margin.add_child(outer)
	var title := Label.new()
	title.text = "档案馆地图"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title)
	var hint := Label.new()
	hint.text = "已探索的房间会亮起。按 M 或 Esc 关闭。"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", UIPalette.INK_FAINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(hint)
	var frame := PanelContainer.new()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.05, 0.066, 0.96)
	style.border_color = Color(0.910, 0.882, 0.812, 0.28)
	style.set_border_width_all(2)
	frame.add_theme_stylebox_override("panel", style)
	outer.add_child(frame)
	map_view = MDSWorldMapView.new()
	map_view.name = "MapView"
	map_view.world_file = WORLD_FILE
	map_view.show_room_names = true
	map_view.show_area_names = false
	map_view.show_objective = false
	map_view.background = Color(0.035, 0.05, 0.066, 0.96)
	map_view.padding = 18.0
	map_view.theme = THEME
	frame.add_child(map_view)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(buttons)
	var close_button := Button.new()
	close_button.text = "继续探索  [M]"
	close_button.custom_minimum_size = Vector2(240, 44)
	close_button.add_theme_font_size_override("font_size", 24)
	close_button.pressed.connect(close)
	buttons.add_child(close_button)


func set_world(path: String) -> void:
	if path.is_empty():
		return
	if map_view.world_file != path:
		map_view.world_file = path
	map_view.set_save_data({})


func open() -> void:
	if _open:
		return
	_open = true
	visible = true
	map_view.queue_redraw()
	if is_inside_tree():
		get_tree().paused = true


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	if is_inside_tree():
		get_tree().paused = false
	closed.emit()


func is_open() -> bool:
	return _open


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("map") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		if is_inside_tree() and get_viewport() != null:
			get_viewport().set_input_as_handled()
