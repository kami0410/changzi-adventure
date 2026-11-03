class_name PauseMenu
extends CanvasLayer

signal pause_requested
var managed := false
var _root: Control = null
var _resume_button: Button = null
var _restart_button: Button = null
var _quit_button: Button = null
var _nodes_ready: bool = false
var _confirm: ConfirmationDialog = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_nodes()
	_sync_visibility()


func toggle() -> void:
	var tree := _scene_tree()
	if tree == null:
		return
	tree.paused = not tree.paused
	_sync_visibility()


func open_pause() -> void:
	var tree := _scene_tree()
	if tree == null:
		return
	tree.paused = true
	_sync_visibility()


func is_open() -> bool:
	_ensure_nodes()
	return _root != null and _root.visible


func _scene_tree() -> SceneTree:
	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	return tree


func _ensure_nodes() -> void:
	if _nodes_ready:
		return
	_nodes_ready = true
	_root = find_child("Root", true, false) as Control
	_resume_button = find_child("ResumeButton", true, false) as Button
	_restart_button = find_child("RestartButton", true, false) as Button
	_quit_button = find_child("QuitButton", true, false) as Button
	if _root != null:
		_root.process_mode = Node.PROCESS_MODE_ALWAYS
	if _resume_button != null and not _resume_button.pressed.is_connected(_on_resume_pressed):
		_resume_button.pressed.connect(_on_resume_pressed)
	if _restart_button != null and not _restart_button.pressed.is_connected(_on_restart_pressed):
		_restart_button.pressed.connect(_on_restart_pressed)
	if _quit_button != null and managed:
		_quit_button.text = "返回档案馆"
	if _quit_button != null and not _quit_button.pressed.is_connected(_on_quit_pressed):
		_quit_button.pressed.connect(_on_quit_pressed)


func _sync_visibility() -> void:
	var tree := _scene_tree()
	_ensure_nodes()
	if _root != null:
		_root.visible = tree != null and tree.paused
		if _root.visible and _resume_button != null and _resume_button.is_inside_tree():
			_resume_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if managed:
			return
		toggle()
		if is_inside_tree() and get_viewport() != null:
			get_viewport().set_input_as_handled()


func _on_resume_pressed() -> void:
	var tree := _scene_tree()
	if tree != null and tree.paused:
		if managed:
			pause_requested.emit()
		else:
			toggle()


func _on_restart_pressed() -> void:
	_ask_confirm("重新开始本局？当前进度会丢失。", _do_restart)


func _on_quit_pressed() -> void:
	var text := "放弃本局并返回档案馆？" if managed else "退出游戏？"
	_ask_confirm(text, _do_quit)


func _ask_confirm(text: String, action: Callable) -> void:
	if _confirm == null:
		_confirm = ConfirmationDialog.new()
		_confirm.name = "ConfirmDialog"
		_confirm.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_confirm)
	_confirm.dialog_text = text
	if _confirm.confirmed.is_connected(action):
		_confirm.confirmed.disconnect(action)
	_confirm.confirmed.connect(action, CONNECT_ONE_SHOT)
	_confirm.popup_centered()


func _do_restart() -> void:
	var tree := _scene_tree()
	if tree == null:
		return
	tree.paused = false
	tree.reload_current_scene()


func _do_quit() -> void:
	var tree := _scene_tree()
	if tree == null:
		return
	tree.paused = false
	if managed:
		Flow.return_to_hub()
		tree.change_scene_to_file("res://scenes/hub/hub.tscn")
	else:
		tree.quit()
