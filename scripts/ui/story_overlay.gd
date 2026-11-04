class_name StoryOverlay
extends CanvasLayer

signal story_finished
signal choice_made(index: int)

var _root: Control
var _eyebrow: Label
var _title: Label
var _body: Label
var _options: VBoxContainer
var _continue: Button
var _hint: Label
var _was_paused := false
var _open := false
var _choice_mode := false
var _voice_id := ""

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	var flow := _flow_node()
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)

func is_open() -> bool:
	return _open


func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


func _prompt(action: StringName) -> String:
	var flow := _flow_node()
	return flow.prompt_label(action) if flow != null else GameFlow.key_label(action)

func open_story(eyebrow: String, title: String, lines: Array, voice_id: String = "") -> void:
	_prepare(eyebrow, title)
	_voice_id = voice_id
	_choice_mode = false
	_body.text = "\n".join(lines)
	_options.hide()
	_continue.show()
	_refresh_device_prompts()
	_show_common()
	_play_voice()
	if is_inside_tree():
		_continue.grab_focus()

func open_choice(eyebrow: String, title: String, body: String, options: Array) -> void:
	_prepare(eyebrow, title)
	_choice_mode = true
	_body.text = body
	_continue.hide()
	_options.show()
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	for index in options.size():
		var option: Dictionary = options[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(360, 78)
		button.pressed.connect(_choose.bind(index))
		# Enter the tree before assigning text: a Button added with text is
		# shaped during ENTER_TREE (~14 ms per option measured headless), while
		# adding it empty and filling it afterwards is under a millisecond.
		_options.add_child(button)
		button.text = "%s\n%s" % [option.get("label", "选择"), option.get("note", "")]
	# A resumed run skips the chapter intro story page, so this can be the first
	# page the overlay shows after boot; refresh the key copy instead of leaving
	# the build-time keyboard default on screen.
	_refresh_device_prompts()
	_show_common()
	if _options.get_child_count() > 0 and is_inside_tree():
		(_options.get_child(0) as Button).grab_focus()

func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	_stop_voice()
	var tree := _tree()
	if tree != null:
		tree.paused = _was_paused
	story_finished.emit()

func choose(index: int) -> void:
	_choose(index)


func _choose(index: int) -> void:
	if not _open or not _choice_mode:
		return
	_open = false
	visible = false
	_stop_voice()
	var tree := _tree()
	if tree != null:
		tree.paused = _was_paused
	choice_made.emit(index)

func _prepare(eyebrow: String, title: String) -> void:
	if _root == null:
		_build()
	_eyebrow.text = eyebrow
	_title.text = title
	_open = true
	var tree := _tree()
	if tree != null:
		_was_paused = tree.paused
		tree.paused = true
	visible = true

func _play_voice() -> void:
	if _voice_id == "" or not is_inside_tree():
		return
	var audio := get_node_or_null("/root/Audio")
	if audio != null and audio.has_method("play_voice"):
		audio.call("play_voice", _voice_id)


func _stop_voice() -> void:
	if not is_inside_tree():
		return
	var audio := get_node_or_null("/root/Audio")
	if audio != null and audio.has_method("stop_voice"):
		audio.call("stop_voice")


func _tree() -> SceneTree:
	if is_inside_tree():
		return get_tree()
	return Engine.get_main_loop() as SceneTree

func _show_common() -> void:
	_root.modulate.a = 0.0
	if is_inside_tree():
		create_tween().tween_property(_root, "modulate:a", 1.0, 0.22)


func _refresh_device_prompts() -> void:
	if _hint != null:
		_hint.text = "方向键选择，%s 确认" % _prompt(&"ui_accept")
	if _continue != null:
		_continue.text = "继续  [%s]" % _prompt(&"interact")


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_device_prompts()

func _unhandled_input(event: InputEvent) -> void:
	# A choice page is a required pick: B must not skip it. The plain story page
	# is just reading, so all three "leave" actions close it.
	if not _open or _choice_mode:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("pause") \
			or event.is_action_pressed("ui_cancel"):
		close()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.theme = preload("res://resources/ui/theme.tres")
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = UIPalette.SHADE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	_eyebrow = Label.new()
	_eyebrow.add_theme_color_override("font_color", UIPalette.CINNABAR)
	_eyebrow.add_theme_font_size_override("font_size", 12)
	column.add_child(_eyebrow)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_title)
	var rule := HSeparator.new()
	column.add_child(rule)
	_body = Label.new()
	_body.custom_minimum_size = Vector2(700, 0)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 24)
	column.add_child(_body)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 12)
	column.add_child(_options)
	_continue = Button.new()
	_continue.custom_minimum_size = Vector2(220, 46)
	_continue.size_flags_horizontal = Control.SIZE_SHRINK_END
	_continue.pressed.connect(close)
	column.add_child(_continue)
	_hint = Label.new()
	_hint.text = "方向键选择，Enter 确认"
	_hint.add_theme_color_override("font_color", UIPalette.INK_FAINT)
	_hint.add_theme_font_size_override("font_size", 12)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_hint)
