class_name SpeakBar
extends Control

## 开口即言灵 (1.1): a single line at the bottom of the screen. The world holds
## its breath while the player types; Enter speaks the sentence and it takes
## effect at once, without visiting the codex or using a phrase slot.
##
## The bar only collects the sentence. The run scene decides who reads it (the
## AI when one is configured, the offline reading otherwise) and what it costs.

signal spoken(text: String)
signal cancelled

const THEME = preload("res://resources/ui/theme.tres")
const MAX_LENGTH := 60
const MAX_RECENT := 4
const INK := Color("0b1418")
const PAPER := Color("e8e1cf")
const TEAL := Color("8fe8dc")
const GOLD := Color("d8b56a")

var _panel: PanelContainer
var _line: LineEdit
var _status: Label
var _chips: HBoxContainer
var _send: Button
var _open := false
var _waiting := false
var _was_paused := false
var _recent: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(INK, 0.38)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, 0.94)
	style.border_color = TEAL
	style.set_border_width_all(1)
	style.border_width_top = 2
	style.set_corner_radius_all(2)
	style.set_content_margin_all(14.0)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	_panel.add_theme_stylebox_override("panel", style)
	# Upper third: clear of the phone keyboard and of the fight at the feet.
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = -330.0
	_panel.offset_right = 330.0
	_panel.offset_top = 96.0
	_panel.grow_vertical = Control.GROW_DIRECTION_END
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)

	var title := Label.new()
	title.text = "言出法随"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", TEAL)
	column.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	_line = LineEdit.new()
	_line.name = "Sentence"
	_line.placeholder_text = "说一句话，世界会照做…"
	_line.max_length = MAX_LENGTH
	_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line.custom_minimum_size = Vector2(0, 40)
	_line.add_theme_font_size_override("font_size", 16)
	# The bar sits on ink, not on a paper page: the theme's paper controls
	# (dark text on a clear button) would vanish here.
	_line.add_theme_color_override("font_color", PAPER)
	_line.add_theme_color_override("font_placeholder_color", Color(PAPER, 0.38))
	_line.add_theme_color_override("caret_color", TEAL)
	_line.add_theme_color_override("font_uneditable_color", Color(PAPER, 0.5))
	_line.add_theme_stylebox_override("normal", _field(Color(TEAL, 0.45)))
	_line.add_theme_stylebox_override("focus", _field(TEAL))
	_line.add_theme_stylebox_override("read_only", _field(Color(GOLD, 0.6)))
	_line.text_submitted.connect(_submit)
	row.add_child(_line)
	_send = Button.new()
	_send.name = "Send"
	_send.text = "说出"
	_send.custom_minimum_size = Vector2(76, 40)
	_send.pressed.connect(func() -> void: _submit(_line.text))
	_dress(_send, true)
	row.add_child(_send)

	_chips = HBoxContainer.new()
	_chips.name = "Recent"
	_chips.add_theme_constant_override("separation", 6)
	column.add_child(_chips)

	_status = Label.new()
	_status.name = "Status"
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", Color(PAPER, 0.72))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)


func is_open() -> bool:
	return _open


func is_waiting() -> bool:
	return _waiting


## Opens the line and pauses the world. [param hint] is the price reminder.
func open(hint: String = "") -> void:
	if _open:
		return
	_open = true
	_waiting = false
	_was_paused = get_tree().paused
	get_tree().paused = true
	visible = true
	_line.editable = true
	_send.disabled = false
	_line.text = ""
	_refresh_chips()
	set_status(hint if not hint.is_empty() else "回车说出 · Esc 收回 · 代价是墨与污染")
	_line.grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	_waiting = false
	visible = false
	_line.release_focus()
	get_tree().paused = _was_paused


## The sentence was sent to a reader that takes time (the AI): the line stays
## up, frozen, until [method close] or [method fail].
func wait(text: String) -> void:
	_waiting = true
	_line.editable = false
	_send.disabled = true
	set_status(text)


## The sentence could not be spoken (not enough ink, still echoing…): the line
## stays open with the reason so the player can change it or leave.
func fail(reason: String) -> void:
	_waiting = false
	_line.editable = true
	_send.disabled = false
	set_status(reason, true)
	_line.grab_focus()


func set_status(text: String, warning: bool = false) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", GOLD if warning else Color(PAPER, 0.72))


## Sentences offered as one-tap chips (the grimoire and what was just said).
func set_recent(sentences: Array[String]) -> void:
	_recent.clear()
	for sentence in sentences:
		remember(sentence)


func remember(sentence: String) -> void:
	var cleaned := sentence.strip_edges()
	if cleaned.is_empty():
		return
	_recent.erase(cleaned)
	_recent.push_front(cleaned)
	if _recent.size() > MAX_RECENT:
		_recent.resize(MAX_RECENT)


func _refresh_chips() -> void:
	for child in _chips.get_children():
		child.queue_free()
	_chips.visible = not _recent.is_empty()
	for sentence in _recent:
		var chip := Button.new()
		chip.text = sentence if sentence.length() <= 12 else sentence.substr(0, 11) + "…"
		chip.tooltip_text = sentence
		chip.add_theme_font_size_override("font_size", 12)
		chip.custom_minimum_size = Vector2(0, 30)
		chip.pressed.connect(_submit.bind(sentence))
		_dress(chip, false)
		_chips.add_child(chip)


## The sentence field: a well of darker ink with one bright line under it.
func _field(line: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.065, 0.96)
	style.border_color = line
	style.border_width_bottom = 2
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


## On-ink buttons. [param solid] is the one primary action (teal block, ink
## text); the rest are quiet outlined chips.
func _dress(button: Button, solid: bool) -> void:
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		var lit := state == "hover" or state == "focus"
		if solid:
			style.bg_color = TEAL if not lit else Color("c4fff6")
			if state == "pressed":
				style.bg_color = Color("5fbfb3")
			elif state == "disabled":
				style.bg_color = Color(TEAL, 0.22)
		else:
			style.bg_color = Color(TEAL, 0.2 if lit or state == "pressed" else 0.07)
			style.border_color = Color(TEAL, 0.9 if lit else 0.4)
			style.set_border_width_all(1)
		style.set_corner_radius_all(2)
		style.content_margin_left = 10.0
		style.content_margin_right = 10.0
		style.content_margin_top = 4.0
		style.content_margin_bottom = 4.0
		button.add_theme_stylebox_override(state, style)
	var text := INK if solid else PAPER
	for role: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(role, text)
	button.add_theme_color_override("font_disabled_color", Color(PAPER, 0.45))


func _submit(text: String) -> void:
	if not _open or _waiting:
		return
	var cleaned := text.strip_edges()
	if cleaned.is_empty():
		set_status("先说一句话。", true)
		return
	_line.text = cleaned
	spoken.emit(cleaned)


func _unhandled_key_input(event: InputEvent) -> void:
	_swallow(event)


func _input(event: InputEvent) -> void:
	if not _open:
		return
	# Only Esc / B: the pause key is a letter the player may be typing.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		# A sentence already on its way to the AI is still cancelled here: the
		# run scene ignores the late answer.
		close()
		cancelled.emit()
		return
	_swallow(event)


## While the line is open, typing must never reach gameplay (J attacks, T
## reopens, Space jumps).
func _swallow(event: InputEvent) -> void:
	if _open and event is InputEventKey and not _line.has_focus():
		get_viewport().set_input_as_handled()
