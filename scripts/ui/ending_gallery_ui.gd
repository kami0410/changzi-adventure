class_name EndingGalleryUI
extends Control

## Read-only gallery of the five authored endings. Profile stores only ids, so
## an old save (or an id this build no longer ships) simply shows as locked;
## nothing is migrated and nothing new is written.

signal closed

const THEME = preload("res://resources/ui/ink_theme.tres")
const LOCKED_TITLE := "？？？"
const LOCKED_BODY := "尚未记录。走过不同的选择，这一页会自己出现。"

var _profile: Profile
var _open := false
var _return_focus: Control = null
var _close_button: Button
var _count_label: Label
var _rows: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()


func open(profile: Profile, return_focus: Control = null) -> void:
	if _close_button == null:
		_build()
	_profile = profile
	_refresh()
	var viewport := get_viewport() if is_inside_tree() else null
	_return_focus = return_focus if return_focus != null else (
		viewport.gui_get_focus_owner() if viewport != null else null)
	_open = true
	show()
	if _close_button.is_inside_tree():
		_close_button.grab_focus()


func is_open() -> bool:
	return _open


func get_entry_count() -> int:
	return _rows.size()


func get_entry_text(index: int) -> String:
	if index < 0 or index >= _rows.size():
		return ""
	var row: Dictionary = _rows[index]
	var title_label: Label = row["title"]
	var body_label: Label = row["body"]
	return title_label.text + "\n" + body_label.text


func is_unlocked(index: int) -> bool:
	if index < 0 or index >= _rows.size():
		return false
	return bool(_rows[index].get("unlocked", false))


func close() -> void:
	if not _open:
		return
	_open = false
	hide()
	var previous := _return_focus
	_return_focus = null
	if previous != null and is_instance_valid(previous) and previous.is_inside_tree() \
			and previous.is_visible_in_tree():
		previous.grab_focus()
	closed.emit()


func _refresh() -> void:
	var unlocked_count := 0
	for index in _rows.size():
		var entry := CampaignData.ending(index)
		var unlocked := _profile != null and _profile.endings.has(String(entry.get("id", "")))
		if unlocked:
			unlocked_count += 1
		var row: Dictionary = _rows[index]
		row["unlocked"] = unlocked
		var title_label: Label = row["title"]
		var body_label: Label = row["body"]
		title_label.text = String(entry.get("title", "")) if unlocked else LOCKED_TITLE
		title_label.add_theme_color_override("font_color",
			UIPalette.BONE if unlocked else UIPalette.INK_FAINT)
		body_label.text = String(entry.get("body", "")) if unlocked else LOCKED_BODY
		body_label.add_theme_color_override("font_color",
			UIPalette.BONE_DIM if unlocked else UIPalette.INK_FAINT)
	if _count_label != null:
		_count_label.text = "已记录 %d / %d" % [unlocked_count, _rows.size()]


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = UIPalette.SHADE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 640)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var title := Label.new()
	title.text = "结局画廊"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 12)
	_count_label.add_theme_color_override("font_color", UIPalette.BONE_DIM)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_count_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 440)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	for index in CampaignData.ending_count():
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(card)
		var card_margin := MarginContainer.new()
		for side in ["left", "top", "right", "bottom"]:
			card_margin.add_theme_constant_override("margin_" + side, 12)
		card.add_child(card_margin)
		var card_column := VBoxContainer.new()
		card_column.add_theme_constant_override("separation", 6)
		card_margin.add_child(card_column)
		var title_label := Label.new()
		title_label.add_theme_font_size_override("font_size", 24)
		card_column.add_child(title_label)
		var body_label := Label.new()
		body_label.add_theme_font_size_override("font_size", 12)
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_column.add_child(body_label)
		_rows.append({"title": title_label, "body": body_label, "unlocked": false})
	_close_button = Button.new()
	_close_button.name = "EndingGalleryClose"
	_close_button.text = "合上画廊"
	_close_button.custom_minimum_size = Vector2(240, 46)
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close_button.pressed.connect(close)
	column.add_child(_close_button)
	# Single-control modal: keep directional and tab focus on the close button
	# instead of letting it walk onto the title buttons behind the shade.
	for side in ["left", "top", "right", "bottom"]:
		_close_button.set("focus_neighbor_" + side, NodePath("."))
	_close_button.focus_next = NodePath(".")
	_close_button.focus_previous = NodePath(".")
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close()
		if is_inside_tree() and get_viewport() != null:
			get_viewport().set_input_as_handled()
