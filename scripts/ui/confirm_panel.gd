class_name ConfirmPanel
extends Control

## In-scene confirmation page for title/menu actions. Unlike a native
## ConfirmationDialog this one lives in the regular Control tree, so controller
## A/B, focus capture and focus return work the same way as every other page.

signal confirmed
signal canceled

const THEME = preload("res://resources/ui/theme.tres")

var _message: Label
var _ok: Button
var _cancel: Button
var _hint: Label
var _open := false
var _return_focus: Control = null


func _ready() -> void:
	# The title screen pauses the tree; this page must still take input.
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()
	var flow := _flow_node()
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)


func open(message: String, confirm_text := "确认", cancel_text := "取消", return_focus: Control = null) -> void:
	if _ok == null:
		_build()
	_message.text = message
	_ok.text = confirm_text
	_cancel.text = cancel_text
	_refresh_hint()
	var viewport := get_viewport() if is_inside_tree() else null
	_return_focus = return_focus if return_focus != null else (viewport.gui_get_focus_owner() if viewport != null else null)
	_open = true
	show()
	if _ok.is_inside_tree():
		_ok.grab_focus()


func is_open() -> bool:
	return _open


func confirm() -> void:
	if not _open:
		return
	_finish()
	confirmed.emit()


func cancel() -> void:
	if not _open:
		return
	_finish()
	canceled.emit()


func _finish() -> void:
	_open = false
	hide()
	var previous := _return_focus
	_return_focus = null
	if previous != null and is_instance_valid(previous) and previous.is_inside_tree() and previous.is_visible_in_tree():
		previous.grab_focus()


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
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 24)
	column.add_child(_message)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	column.add_child(buttons)
	_ok = Button.new()
	_ok.custom_minimum_size = Vector2(160, 46)
	_ok.add_theme_font_size_override("font_size", 24)
	_ok.pressed.connect(confirm)
	buttons.add_child(_ok)
	_cancel = Button.new()
	_cancel.custom_minimum_size = Vector2(160, 46)
	_cancel.add_theme_font_size_override("font_size", 24)
	_cancel.pressed.connect(cancel)
	buttons.add_child(_cancel)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_color", UIPalette.INK_FAINT)
	_hint.add_theme_font_size_override("font_size", 12)
	column.add_child(_hint)
	_refresh_hint()


func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


func _refresh_hint() -> void:
	if _hint == null:
		return
	var flow := _flow_node()
	var confirm_key := flow.prompt_label(&"ui_accept") if flow != null else GameFlow.key_label(&"ui_accept")
	var cancel_key := flow.close_prompt() if flow != null else "Esc"
	_hint.text = "%s 确认 · %s 取消" % [confirm_key, cancel_key]


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_hint()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		cancel()
		if is_inside_tree() and get_viewport() != null:
			get_viewport().set_input_as_handled()
