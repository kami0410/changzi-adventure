class_name DialogueUI
extends CanvasLayer

signal finished
signal closed
signal inspiration_requested

## Demo NPCs use 192x256 pixel cards cut from their existing portraits; the
## faces stay identical to the previous art. Wenjin/Baiyu keep the old cards
## until the full-version pass.
const PORTRAITS := {
	"陆沉": "res://assets/portraits/pixel/luchen.png",
	"阿砚": "res://assets/portraits/pixel/ayan.png",
	"咕噜": "res://assets/portraits/pixel/guru.png",
	"闻烬": "res://assets/portraits/wenjin.png",
	"白榆": "res://assets/portraits/baiyu.png",
}

var _root: Control = null
var _dim: ColorRect = null
var _portrait: TextureRect = null
var _speaker_label: Label = null
var _line_label: Label = null
var _progress_label: Label = null
var _continue_button: Button = null
var _close_button: Button = null
var _inspire_button: Button = null
var _inspiration_enabled := false
var _nodes_ready := false

var _speaker := ""
var _lines: Array[String] = []
var _index := 0
var _open := false
var _return_focus: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_nodes()
	PaperGrain.apply(get_node_or_null("Root/Panel") as Control)
	if _root != null:
		_root.visible = false
	var flow := _flow_node()
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)


func open_dialogue(speaker: String, lines: Array) -> void:
	_ensure_nodes()
	_speaker = speaker
	_lines.clear()
	for line in lines:
		_lines.append(String(line))
	if _lines.is_empty():
		_lines.append("……")
	_index = 0
	_open = true
	var viewport := get_viewport() if is_inside_tree() else null
	_return_focus = viewport.gui_get_focus_owner() if viewport != null else null
	if _root != null:
		_root.visible = true
	if _inspire_button != null:
		_inspire_button.visible = _inspiration_enabled
	_refresh()
	# Focus the continue button so a controller's A advances the page the same
	# way Y does; otherwise the whole dialogue is unreachable without a mouse.
	if _continue_button != null and _continue_button.is_inside_tree():
		_continue_button.grab_focus()
	_maybe_guru_laugh(0.45)


func advance() -> void:
	if not _open:
		return
	if _index + 1 < _lines.size():
		_index += 1
		_refresh()
		_maybe_guru_laugh(0.3)
		return
	finished.emit()
	close()


func close() -> void:
	if not _open:
		return
	_open = false
	if _root != null:
		_root.visible = false
	if _inspire_button != null:
		_inspire_button.visible = false
	var previous := _return_focus
	_return_focus = null
	closed.emit()
	if previous != null and is_instance_valid(previous) and previous.is_inside_tree() and previous.is_visible_in_tree():
		previous.grab_focus()


func is_open() -> bool:
	return _open


func set_inspiration_enabled(enabled: bool) -> void:
	_inspiration_enabled = enabled
	_ensure_nodes()
	if _inspire_button != null:
		_inspire_button.visible = enabled and _open


func get_speaker_text() -> String:
	_ensure_nodes()
	return _speaker_label.text if _speaker_label != null else ""


func get_line_text() -> String:
	_ensure_nodes()
	return _line_label.text if _line_label != null else ""


func get_progress_text() -> String:
	_ensure_nodes()
	return _progress_label.text if _progress_label != null else ""


func _ensure_nodes() -> void:
	if _nodes_ready:
		return
	_nodes_ready = true
	_root = find_child("Root", true, false) as Control
	_dim = find_child("Dim", true, false) as ColorRect
	_portrait = find_child("Portrait", true, false) as TextureRect
	if _portrait != null:
		_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_speaker_label = find_child("Speaker", true, false) as Label
	_line_label = find_child("Line", true, false) as Label
	_progress_label = find_child("Progress", true, false) as Label
	_continue_button = find_child("ContinueButton", true, false) as Button
	_close_button = find_child("CloseButton", true, false) as Button
	_inspire_button = find_child("InspireButton", true, false) as Button
	if _dim != null and not _dim.gui_input.is_connected(_on_dim_gui_input):
		_dim.gui_input.connect(_on_dim_gui_input)
	if _continue_button != null and not _continue_button.pressed.is_connected(advance):
		_continue_button.pressed.connect(advance)
	if _close_button != null and not _close_button.pressed.is_connected(close):
		_close_button.pressed.connect(close)
	if _inspire_button != null and not _inspire_button.pressed.is_connected(_on_inspire_pressed):
		_inspire_button.pressed.connect(_on_inspire_pressed)


func _refresh() -> void:
	if _speaker_label != null:
		_speaker_label.text = _speaker
	_refresh_portrait()
	if _line_label != null:
		_line_label.text = _lines[_index] if _index >= 0 and _index < _lines.size() else ""
	if _progress_label != null:
		_progress_label.text = "%d / %d" % [_index + 1, _lines.size()]
	# On a touch screen the on-screen controls hide behind this page, so the
	# buttons are tapped directly: no key hint.
	var flow := _flow_node()
	var touch := flow != null and flow.using_touch
	if _continue_button != null:
		var key := _prompt(&"interact")
		var verb := "结束" if _index + 1 >= _lines.size() else "继续"
		_continue_button.text = verb if touch else "%s  [%s]" % [verb, key]
	if _inspire_button != null:
		_inspire_button.text = "言灵对话" if touch else "言灵对话  [%s]" % _prompt(&"npc_inspire")


func _on_input_device_changed(_using_gamepad: bool) -> void:
	if _open:
		_refresh()


func _prompt(action: StringName) -> String:
	var flow := _flow_node()
	return flow.prompt_label(action) if flow != null else GameFlow.key_label(action)


func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


func _refresh_portrait() -> void:
	if _portrait == null:
		return
	var frame := _portrait.get_parent() as Control
	var path := String(PORTRAITS.get(_speaker, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		_portrait.texture = null
		if frame != null:
			frame.visible = false
		return
	var next := load(path) as Texture2D
	if next == null:
		_portrait.texture = null
		if frame != null:
			frame.visible = false
		return
	if frame != null:
		frame.visible = true
	if _portrait.texture == next:
		return
	_portrait.texture = next
	_portrait.modulate.a = 0.0
	if is_inside_tree():
		create_tween().tween_property(_portrait, "modulate:a", 1.0, 0.18)
	else:
		_portrait.modulate.a = 1.0


func _on_inspire_pressed() -> void:
	inspiration_requested.emit()


## B / Esc leaves the conversation. Keyboard players also have the close
## button; Y (interact) still advances, as the button label says.
func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close()
		if is_inside_tree() and get_viewport() != null:
			get_viewport().set_input_as_handled()


## 咕噜's laughter is a gag that should surprise, never loop: it fires on some
## lines only, and only for that speaker.
func _maybe_guru_laugh(chance: float) -> void:
	if _speaker != "咕噜" or DisplayServer.get_name() == "headless":
		return
	if randf() > chance:
		return
	var audio := get_node_or_null("/root/Audio")
	if audio != null and audio.has_method("play_voice"):
		audio.call("play_voice", "guru_laugh")


func _on_dim_gui_input(event: InputEvent) -> void:
	if not _open:
		return
	if not event is InputEventMouseButton:
		return
	var mouse := event as InputEventMouseButton
	if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		advance()
		if is_inside_tree() and get_viewport() != null:
			get_viewport().set_input_as_handled()
