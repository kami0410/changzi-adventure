class_name NPCInspireUI
extends CanvasLayer

## A small conversation window for speaking a free-form 言灵 to a hub NPC.
## The NPC answers in character, and the words can bend their actual services.

signal closed
signal inspiration_submitted(npc_id: StringName, text: String)
signal function_requested(npc_id: StringName, function_id: StringName)

const THEME = preload("res://resources/ui/theme.tres")
## Demo NPCs use 192x256 pixel cards cut from their existing portraits so the
## faces stay identical. Wenjin/Baiyu keep the full-resolution art until they
## get their own demo pass.
const PORTRAITS := {
	&"luchen": "res://assets/portraits/pixel/luchen.png",
	&"ayan": "res://assets/portraits/pixel/ayan.png",
	&"guru": "res://assets/portraits/pixel/guru.png",
	&"wenjin": "res://assets/portraits/wenjin.png",
	&"baiyu": "res://assets/portraits/baiyu.png",
}
const COLOR_BONE := UIPalette.INK
const COLOR_DIM := UIPalette.INK_FAINT
const COLOR_CYAN := UIPalette.CINNABAR

var _root: Control
var _panel: PanelContainer
var _portrait_frame: PanelContainer
var _portrait: TextureRect
var _name_label: Label
var _title_label: Label
var _story_label: Label
var _function_box: HBoxContainer
var _history: RichTextLabel
var _input: LineEdit
var _submit: Button
var _status: Label
var _busy_label: Label
var _close_button: Button
var _npc_id: StringName = &""
var _profile: Dictionary = {}
var _open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build()
	_root.visible = false
	_refresh_close_hint()
	var flow := get_node_or_null("/root/Flow")
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)


func open(npc: NPC) -> void:
	if npc == null:
		return
	_npc_id = npc.npc_id
	_profile = NPCProfiles.get_profile(_npc_id)
	if _profile.is_empty():
		return
	_name_label.text = String(_profile.get("name", npc.display_name))
	_title_label.text = String(_profile.get("title", ""))
	var story: Array = _profile.get("story", [])
	_story_label.text = "\n\n".join(story)
	var portrait_path := String(PORTRAITS.get(_npc_id, ""))
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		_portrait.texture = load(portrait_path)
		_portrait_frame.show()
	else:
		_portrait.texture = null
		_portrait_frame.hide()
	_history.clear()
	_history.append_text("[color=#4a4a45]%s[/color]\n\n" % String(_profile.get("greeting", "")))
	_rebuild_functions()
	_input.text = ""
	_status.text = "对 TA 说一句话。言灵会改变 TA 的态度，也可能改变 TA 的职能。"
	_busy_label.text = ""
	_refresh_close_hint()
	_root.visible = true
	_open = true
	# A pad cannot type into the LineEdit, so land on the first service button
	# instead; keyboard players keep the text field as the natural entry point.
	var flow := get_node_or_null("/root/Flow")
	if flow != null and flow.using_gamepad:
		_focus_first_function()
	else:
		_input.grab_focus()


func _focus_first_function() -> void:
	for card in _function_box.get_children():
		for node in card.find_children("*", "Button", true, false):
			var button := node as Button
			if button != null and not button.disabled and not button.is_queued_for_deletion():
				button.grab_focus()
				return
	_input.grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	closed.emit()


func is_open() -> bool:
	return _open


func _refresh_close_hint() -> void:
	if _close_button == null:
		return
	var flow := get_node_or_null("/root/Flow") as GameFlow
	var key := flow.close_prompt() if flow != null else "Esc"
	_close_button.text = "离开 [%s]" % key


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_close_hint()


func show_reply(text: String, mood: String = "neutral") -> void:
	var color := "#" + UIPalette.INK.to_html(false)
	if mood == "abyssal":
		color = "#" + UIPalette.ABYSS.to_html(false)
	elif mood == "warm":
		color = "#" + UIPalette.SEAL_GOLD.to_html(false)
	_history.append_text("[color=%s]%s[/color]\n\n" % [color, text])
	_scroll_to_end()


func show_status(text: String) -> void:
	_status.text = text


func set_busy(busy: bool) -> void:
	_submit.disabled = busy
	_input.editable = not busy
	_busy_label.text = "（正在聆听……）" if busy else ""


func focus_input() -> void:
	_input.grab_focus()


func _build() -> void:
	_root = Control.new()
	_root.theme = THEME
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = UIPalette.SHADE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(1120, 660)
	center.add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	_panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	margin.add_child(outer)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	outer.add_child(header)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 0)
	header.add_child(names)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 48)
	_name_label.add_theme_color_override("font_color", COLOR_BONE)
	names.add_child(_name_label)
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", COLOR_CYAN)
	names.add_child(_title_label)
	_close_button = Button.new()
	_close_button.text = "离开"
	_close_button.custom_minimum_size = Vector2(176, 44)
	_close_button.add_theme_font_size_override("font_size", 24)
	_close_button.pressed.connect(close)
	header.add_child(_close_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 22)
	outer.add_child(body)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(560, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	body.add_child(left)

	var dossier := HBoxContainer.new()
	dossier.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dossier.add_theme_constant_override("separation", 18)
	left.add_child(dossier)

	_portrait_frame = PanelContainer.new()
	_portrait_frame.custom_minimum_size = Vector2(192, 256)
	_portrait_frame.add_theme_stylebox_override("panel", _portrait_style())
	dossier.add_child(_portrait_frame)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.custom_minimum_size = Vector2(192, 256)
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(_portrait)

	var story_column := VBoxContainer.new()
	story_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_column.add_theme_constant_override("separation", 6)
	dossier.add_child(story_column)
	var story_title := Label.new()
	story_title.text = "TA 的来历"
	story_title.add_theme_font_size_override("font_size", 24)
	story_title.add_theme_color_override("font_color", COLOR_CYAN)
	story_column.add_child(story_title)
	var story_scroll := ScrollContainer.new()
	story_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	story_column.add_child(story_scroll)
	_story_label = Label.new()
	_story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_label.add_theme_font_size_override("font_size", 24)
	_story_label.add_theme_color_override("font_color", COLOR_BONE)
	_story_label.custom_minimum_size = Vector2(330, 0)
	story_scroll.add_child(_story_label)

	var function_title := Label.new()
	function_title.text = "职能"
	function_title.add_theme_font_size_override("font_size", 24)
	function_title.add_theme_color_override("font_color", COLOR_CYAN)
	left.add_child(function_title)
	_function_box = HBoxContainer.new()
	_function_box.add_theme_constant_override("separation", 16)
	left.add_child(_function_box)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	body.add_child(right)
	var talk_title := Label.new()
	talk_title.text = "对话"
	talk_title.add_theme_font_size_override("font_size", 24)
	talk_title.add_theme_color_override("font_color", COLOR_CYAN)
	right.add_child(talk_title)
	_history = RichTextLabel.new()
	_history.bbcode_enabled = true
	_history.scroll_following = true
	_history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_history.custom_minimum_size = Vector2(440, 260)
	_history.add_theme_font_size_override("normal_font_size", 24)
	right.add_child(_history)
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	right.add_child(input_row)
	_input = LineEdit.new()
	_input.placeholder_text = "例如：『以锻造之神真名，重燃此炉』"
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.add_theme_font_size_override("font_size", 24)
	_input.text_submitted.connect(func(_text: String): _submit_text())
	input_row.add_child(_input)
	_submit = Button.new()
	_submit.text = "言灵"
	_submit.custom_minimum_size = Vector2(110, 46)
	_submit.add_theme_font_size_override("font_size", 24)
	_submit.pressed.connect(_submit_text)
	input_row.add_child(_submit)
	_busy_label = Label.new()
	_busy_label.add_theme_font_size_override("font_size", 12)
	_busy_label.add_theme_color_override("font_color", COLOR_DIM)
	right.add_child(_busy_label)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", COLOR_DIM)
	right.add_child(_status)


func _portrait_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.05, 0.066, 0.92)
	style.border_color = Color(0.910, 0.882, 0.812, 0.28)
	style.set_border_width_all(2)
	style.set_content_margin_all(2)
	style.anti_aliasing = false
	return style

func _rebuild_functions() -> void:
	for child in _function_box.get_children():
		child.queue_free()
	var functions: Array = _profile.get("functions", [])
	for entry in functions:
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_constant_override("separation", 2)
		var button := Button.new()
		var cost := int(entry.get("cost", 0))
		button.text = "%s%s" % [String(entry.get("name", "职能")), "" if cost <= 0 else "（%d 碎片）" % cost]
		button.tooltip_text = String(entry.get("desc", ""))
		button.custom_minimum_size = Vector2(0, 44)
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(func(): function_requested.emit(_npc_id, StringName(entry.get("id", &""))))
		card.add_child(button)
		var description := Label.new()
		description.text = String(entry.get("desc", ""))
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 12)
		description.add_theme_color_override("font_color", COLOR_DIM)
		card.add_child(description)
		_function_box.add_child(card)

func _submit_text() -> void:
	if not _open:
		return
	var text := _input.text.strip_edges()
	if text.is_empty():
		show_status("先说一句话。")
		return
	_input.text = ""
	inspiration_submitted.emit(_npc_id, text)


func _scroll_to_end() -> void:
	if _history != null:
		_history.scroll_to_line(maxi(_history.get_line_count() - 1, 0))


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		if is_inside_tree() and get_viewport() != null:
			get_viewport().set_input_as_handled()
