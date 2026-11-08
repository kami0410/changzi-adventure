class_name PauseMenu
extends CanvasLayer

signal pause_requested
signal settings_requested
var managed := false
var _root: Control = null
var _resume_button: Button = null
var _settings_button: Button = null
var _restart_button: Button = null
var _quit_button: Button = null
var _footer: Label = null
var _nodes_ready: bool = false
var _confirm: ConfirmationDialog = null
## The handler currently armed on the shared confirmation dialog. Dismissing
## the dialog (Esc, Cancel, or closing it) must not leave that one-shot
## connection behind: the next confirmation would then run both handlers, so
## cancelling "退出" and confirming "重新开始" would also abandon the run.
var _confirm_action := Callable()


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


func _flow_node() -> GameFlow:
	var tree := _scene_tree()
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


func _ensure_nodes() -> void:
	if _nodes_ready:
		return
	_nodes_ready = true
	_root = find_child("Root", true, false) as Control
	_resume_button = find_child("ResumeButton", true, false) as Button
	_settings_button = find_child("SettingsButton", true, false) as Button
	_restart_button = find_child("RestartButton", true, false) as Button
	_quit_button = find_child("QuitButton", true, false) as Button
	_footer = find_child("Footer", true, false) as Label
	var flow := _flow_node()
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)
	if flow != null and not flow.keybinds_changed.is_connected(_refresh_footer):
		flow.keybinds_changed.connect(_refresh_footer)
	if _root != null:
		_root.process_mode = Node.PROCESS_MODE_ALWAYS
	if _resume_button != null and not _resume_button.pressed.is_connected(_on_resume_pressed):
		_resume_button.pressed.connect(_on_resume_pressed)
	if _settings_button != null and not _settings_button.pressed.is_connected(_on_settings_pressed):
		_settings_button.pressed.connect(_on_settings_pressed)
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
		_refresh_footer()


func _refresh_footer() -> void:
	if _footer == null:
		return
	var flow := _flow_node()
	_footer.text = "按 %s 继续" % (flow.prompt_label(&"pause") if flow != null else "P / Esc")


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_footer()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if managed:
			return
		toggle()
		if is_inside_tree() and get_viewport() != null:
			get_viewport().set_input_as_handled()
		return
	# Controller B is ui_cancel, not pause; let it back out of the page.
	if is_open() and event.is_action_pressed("ui_cancel"):
		if managed:
			pause_requested.emit()
		else:
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


func _on_settings_pressed() -> void:
	settings_requested.emit()


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
		_confirm.canceled.connect(_clear_confirm)
		_confirm.confirmed.connect(_run_confirm)
		# Hiding the dialog by any other route (programmatic close, window
		# dismissal) is a cancel too. `canceled` alone would leave the action
		# armed for the next confirmation.
		_confirm.visibility_changed.connect(_on_confirm_visibility_changed)
	_clear_confirm()
	_confirm.dialog_text = text
	_confirm_action = action
	# A unit test can build the pause menu before the root is in the tree; a
	# native Window cannot pop there. In game the menu is always inside it.
	if is_inside_tree():
		_confirm.popup_centered()


## Both signals go through one arming slot, so the dialog never holds two
## actions at once. Confirming runs the armed action exactly once.
func _run_confirm() -> void:
	var action := _confirm_action
	_clear_confirm()
	if action.is_valid():
		action.call()


func _clear_confirm() -> void:
	_confirm_action = Callable()


func _on_confirm_visibility_changed() -> void:
	if _confirm != null and not _confirm.visible:
		_clear_confirm()


func _do_restart() -> void:
	var tree := _scene_tree()
	if tree == null:
		return
	tree.paused = false
	if Flow != null and Flow.auto_save:
		# Restart is a fresh run, not a resume of the run being abandoned.
		RunSave.clear(Flow.run_save_path)
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
