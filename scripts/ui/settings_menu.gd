class_name SettingsMenu
extends Control

signal closed

@onready var fullscreen_button: Button = $Center/Panel/Margin/VBox/Fullscreen
@onready var volume_slider: HSlider = $Center/Panel/Margin/VBox/Volume
@onready var close_button: Button = $Center/Panel/Margin/VBox/Close
@onready var hint_label: Label = $Center/Panel/Margin/VBox/Hint

var _accessibility_built := false
## Pages opened from this menu (AI settings, keybinds, help). They live on the
## shared ModalLayer so they cover the HUD, but this menu still owns their
## lifetime: B/Esc closes the top page first, then the settings page itself.
var _subpages: Array[Node] = []
var _subpage_focus: Dictionary = {}
var _return_focus: Control = null
var _ai_page: AISettingsUI = null


func _ready() -> void:
	# Settings must work from the title screen and Hub while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	volume_slider.value_changed.connect(_on_volume_changed)
	close_button.pressed.connect(close)
	var flow := _flow_node()
	if flow != null and flow.profile != null:
		volume_slider.set_value_no_signal(clampf(flow.profile.master_volume, 0.0, 1.0))
	else:
		volume_slider.value = clampf(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.0, 1.0)
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)
	if flow != null and not flow.keybinds_changed.is_connected(_refresh_close_hint):
		flow.keybinds_changed.connect(_refresh_close_hint)
	_refresh_close_hint()
	_add_accessibility_options()


func open() -> void:
	_refresh_close_hint()
	_add_accessibility_options()
	# Remember where focus came from (title/Hub button) so closing the page
	# does not leave keyboard and controller players with no focus at all.
	var viewport := get_viewport()
	_return_focus = viewport.gui_get_focus_owner() if viewport != null else null
	visible = true
	if fullscreen_button != null:
		fullscreen_button.grab_focus.call_deferred()


func close() -> void:
	_close_subpages()
	visible = false
	var previous := _return_focus
	_return_focus = null
	closed.emit()
	if previous != null and is_instance_valid(previous) and previous.is_inside_tree() and previous.is_visible_in_tree():
		previous.grab_focus()


## True while one of the pages launched from Settings is still open.
func has_subpage() -> bool:
	_prune_subpages()
	return not _subpages.is_empty()


## Closes the topmost page launched from Settings. Returns false when there is
## nothing left to close, so the caller can close Settings itself.
func close_subpage() -> bool:
	_prune_subpages()
	if _subpages.is_empty():
		return false
	var page: Node = _subpages.back()
	_subpages.pop_back()
	if is_instance_valid(page):
		if page.has_method("close"):
			page.call("close")
		elif page.has_method("close_page"):
			# AISettingsUI names its close method close_page(); it still emits
			# closed, which restores the opener's focus and drops the one-shot.
			page.call("close_page")
		elif page is CanvasItem:
			(page as CanvasItem).visible = false
	return true


## Closes every page launched from Settings without closing Settings itself.
func close_subpages() -> void:
	_close_subpages()


func _open_subpage(page: Node, opener: Control) -> void:
	if page == null:
		return
	_prune_subpages()
	if _subpages.has(page):
		return
	_subpages.append(page)
	_subpage_focus[page] = opener
	if page.has_signal("closed"):
		page.connect("closed", _on_subpage_closed.bind(page), CONNECT_ONE_SHOT)
	if not page.tree_exited.is_connected(_forget_subpage.bind(page)):
		page.tree_exited.connect(_forget_subpage.bind(page), CONNECT_ONE_SHOT)
	if page.has_method("open"):
		page.call("open")
	elif page is CanvasItem:
		(page as CanvasItem).visible = true


func _on_subpage_closed(page: Node) -> void:
	var opener: Control = _subpage_focus.get(page)
	_forget_subpage(page)
	if opener != null and is_instance_valid(opener) and opener.is_inside_tree() and opener.is_visible_in_tree():
		opener.grab_focus()


func _forget_subpage(page: Node) -> void:
	_subpages.erase(page)
	_subpage_focus.erase(page)


func _prune_subpages() -> void:
	for index in range(_subpages.size() - 1, -1, -1):
		var page: Node = _subpages[index]
		if not is_instance_valid(page) or not page.is_inside_tree():
			_forget_subpage(page)


func _close_subpages() -> void:
	while close_subpage():
		pass


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var flow := _flow_node()
	# The keybind page owns every press (including B) while it waits for a key.
	if flow != null and flow.input_capture_active:
		return
	# Controller B and keyboard Esc both leave the top page. A subpage closes
	# first so one press never drops the player back into the game unexpectedly.
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if not close_subpage():
			close()
		get_viewport().set_input_as_handled()


func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


func _refresh_close_hint() -> void:
	if hint_label == null:
		return
	var flow := _flow_node()
	var settings_key := flow.prompt_label(&"settings") if flow != null else "F10"
	var close_key := flow.close_prompt() if flow != null else "Esc"
	hint_label.text = "按 %s 或 %s 关闭 · 全屏与主音量" % [settings_key, close_key]


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_close_hint()


## Touch controls (1.0.1): when to show them, button size and opacity.
func _add_touch_options(box: Node, flow: GameFlow) -> void:
	if flow.profile == null:
		return
	var mode := OptionButton.new()
	mode.name = "TouchModeOption"
	for label in ["触屏按键：自动", "触屏按键：始终显示", "触屏按键：隐藏"]:
		mode.add_item(label)
	mode.selected = clampi(flow.profile.touch_mode, 0, 2)
	mode.item_selected.connect(func(index: int):
		flow.profile.touch_mode = index
		flow.apply_touch_settings()
		_persist_setting(flow))
	box.add_child(mode)
	var row := HBoxContainer.new()
	row.name = "TouchSizeRow"
	row.add_theme_constant_override("separation", 8)
	var sizes := [0.85, 1.0, 1.2]
	var size_option := OptionButton.new()
	size_option.name = "TouchSizeOption"
	for label in ["按键 小", "按键 中", "按键 大"]:
		size_option.add_item(label)
	size_option.selected = 0 if flow.profile.touch_scale < 0.93 else (2 if flow.profile.touch_scale > 1.1 else 1)
	size_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_option.item_selected.connect(func(index: int):
		flow.profile.touch_scale = float(sizes[index])
		flow.apply_touch_settings()
		_persist_setting(flow))
	row.add_child(size_option)
	var alphas := [0.4, 0.6, 0.8]
	var alpha_option := OptionButton.new()
	alpha_option.name = "TouchOpacityOption"
	for label in ["透明度 淡", "透明度 中", "透明度 浓"]:
		alpha_option.add_item(label)
	alpha_option.selected = 0 if flow.profile.touch_opacity < 0.5 else (2 if flow.profile.touch_opacity > 0.7 else 1)
	alpha_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alpha_option.item_selected.connect(func(index: int):
		flow.profile.touch_opacity = float(alphas[index])
		flow.apply_touch_settings()
		_persist_setting(flow))
	row.add_child(alpha_option)
	box.add_child(row)


func _add_accessibility_options() -> void:
	if _accessibility_built:
		return
	var flow := _flow_node()
	if flow == null:
		return
	var fullscreen := fullscreen_button
	if fullscreen == null:
		fullscreen = find_child("Fullscreen", true, false) as Button
	if fullscreen == null or fullscreen.get_parent() == null:
		return
	_accessibility_built = true
	var box := fullscreen.get_parent()
	var shake := CheckButton.new()
	shake.text = "减弱屏幕震动"
	shake.button_pressed = float(flow.shake_scale) < 0.7
	shake.toggled.connect(func(on: bool):
		flow.shake_scale = 0.35 if on else 1.0
		if flow.profile != null:
			flow.profile.shake_scale = flow.shake_scale
			_persist_setting(flow)
	)
	box.add_child(shake)
	var flash := CheckButton.new()
	flash.text = "减弱闪屏"
	flash.button_pressed = float(flow.flash_scale) < 0.7
	flash.toggled.connect(func(on: bool):
		flow.flash_scale = 0.35 if on else 1.0
		if flow.profile != null:
			flow.profile.flash_scale = flow.flash_scale
			_persist_setting(flow)
	)
	box.add_child(flash)
	var text_option := OptionButton.new()
	text_option.name = "TextScaleOption"
	var sizes := [12, 16, 20]
	for size in sizes:
		text_option.add_item("文字大小 %d px" % size)
	var current_size := flow.profile.text_scale if flow.profile != null else 16
	text_option.selected = maxi(sizes.find(current_size), 0)
	text_option.item_selected.connect(func(index: int): _set_text_scale(int(sizes[index])))
	box.add_child(text_option)
	_add_touch_options(box, flow)
	var ai_button := Button.new()
	ai_button.text = "AI 言灵设置"
	ai_button.pressed.connect(func():
		if _ai_page == null:
			_ai_page = AISettingsUI.new()
			ModalLayer.host(self).add_child(_ai_page)
		_open_subpage(_ai_page, ai_button)
	)
	box.add_child(ai_button)
	var keybind_button := Button.new()
	keybind_button.text = "键位设置"
	keybind_button.pressed.connect(func():
		var ui := KeybindUI.new()
		ModalLayer.host(self).add_child(ui)
		ui.layer = ModalLayer.LAYER + 1
		_open_subpage(ui, keybind_button)
	)
	box.add_child(keybind_button)
	var help_button := Button.new()
	help_button.text = "操作说明"
	help_button.pressed.connect(func():
		var help := get_tree().get_first_node_in_group("help_ui") as HelpUI
		if help == null:
			help = HelpUI.new()
			get_parent().add_child(help)
		_open_subpage(help, help_button)
	)
	box.add_child(help_button)


func _set_text_scale(size: int) -> void:
	var clamped := clampi(size, 12, 20)
	var flow := _flow_node()
	if flow != null:
		if flow.profile != null:
			flow.profile.text_scale = clamped
			if flow.auto_save:
				flow.save_profile()
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		var hud := tree.get_first_node_in_group(&"hud") as HUD
		if hud == null:
			for node in tree.root.find_children("*", "HUD", true, false):
				hud = node as HUD
				if hud != null:
					break
		if hud != null:
			hud.apply_text_scale(clamped)


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	var full := not (mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED)
	var flow := _flow_node()
	if flow != null and flow.profile != null:
		flow.profile.fullscreen = full
		if flow.auto_save:
			flow.save_profile()


func _on_volume_changed(value: float) -> void:
	var volume := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001)))
	var flow := _flow_node()
	if flow != null and flow.profile != null:
		flow.profile.master_volume = volume
		_persist_setting(flow)


## Tests and tools turn auto_save off; UI changes must not touch the real
## profile file in that mode.
func _persist_setting(flow: GameFlow) -> void:
	if flow != null and flow.auto_save:
		flow.save_profile()
