class_name SettingsMenu
extends Control

signal closed

@onready var fullscreen_button: Button = $Center/Panel/Margin/VBox/Fullscreen
@onready var volume_slider: HSlider = $Center/Panel/Margin/VBox/Volume
@onready var close_button: Button = $Center/Panel/Margin/VBox/Close

var _accessibility_built := false


func _ready() -> void:
	# Settings must work from the title screen and Hub while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	volume_slider.value_changed.connect(_on_volume_changed)
	close_button.pressed.connect(close)
	volume_slider.value = clampf(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.0, 1.0)
	_add_accessibility_options()


func open() -> void:
	_add_accessibility_options()
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


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
			flow.save_profile()
	)
	box.add_child(shake)
	var flash := CheckButton.new()
	flash.text = "减弱闪屏"
	flash.button_pressed = float(flow.flash_scale) < 0.7
	flash.toggled.connect(func(on: bool):
		flow.flash_scale = 0.35 if on else 1.0
		if flow.profile != null:
			flow.profile.flash_scale = flow.flash_scale
			flow.save_profile()
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
	var ai_button := Button.new()
	ai_button.text = "AI 言灵设置"
	ai_button.pressed.connect(func():
		var ui := AISettingsUI.new()
		ModalLayer.host(self).add_child(ui)
		ui.open()
	)
	box.add_child(ai_button)
	var keybind_button := Button.new()
	keybind_button.text = "键位设置"
	keybind_button.pressed.connect(func():
		var ui := KeybindUI.new()
		ModalLayer.host(self).add_child(ui)
		ui.layer = ModalLayer.LAYER + 1
		ui.open()
	)
	box.add_child(keybind_button)
	var help_button := Button.new()
	help_button.text = "操作说明"
	help_button.pressed.connect(func():
		var help := get_tree().get_first_node_in_group("help_ui") as HelpUI
		if help == null:
			help = HelpUI.new()
			get_parent().add_child(help)
		help.open()
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
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.001)))
