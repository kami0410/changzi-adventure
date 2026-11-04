class_name TutorialFlow
extends CanvasLayer

## First-visit Hub tutorial: C opens the Codex, select two words, preview,
## equip, then try the phrase on the training stele. Completion is persisted
## on Profile.tutorial_done.

const THEME = preload("res://resources/ui/theme.tres")

var _panel: PanelContainer
var _label: Label
var _active := false
var _built := false
var _step := 0


func _ready() -> void:
	_build()
	var flow := _flow_node()
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)
	if flow != null and not flow.keybinds_changed.is_connected(_refresh_hint):
		flow.keybinds_changed.connect(_refresh_hint)


func _build() -> void:
	if _built:
		return
	_built = true
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.theme = THEME
	_panel.position = Vector2(360, 24)
	_panel.custom_minimum_size = Vector2(560, 52)
	add_child(_panel)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", UIPalette.BONE)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_label)
	_panel.visible = false
	visible = false


func start_if_needed() -> void:
	_build()
	var profile := _profile()
	if profile == null or profile.tutorial_done:
		return
	_active = true
	visible = true
	_panel.visible = true
	_step = 1
	_refresh_hint()


func on_codex_opened() -> void:
	if _active:
		_step = 2
		_refresh_hint()


func on_phrase_equipped() -> void:
	if _active:
		_step = 3
		_refresh_hint()


func on_training_hit() -> void:
	if not _active:
		return
	_active = false
	_step = 0
	visible = false
	if _panel != null:
		_panel.visible = false
	var profile := _profile()
	if profile != null:
		profile.tutorial_done = true
		var flow := _flow_node()
		if flow != null and flow.auto_save:
			flow.save_profile()


func is_active() -> bool:
	return _active


func get_hint() -> String:
	return _label.text if _label != null else ""


## Rebuild the current step's copy so a device switch mid-tutorial replaces
## the stale C / E hints with the pad buttons the player now holds.
func _refresh_hint() -> void:
	if not _active or _label == null:
		return
	match _step:
		1:
			_label.text = "第 1 步 · 按 %s 打开语言图鉴。" % _prompt(&"codex")
		2:
			_label.text = "第 2 步 · 选 2 个词，预览法术，然后装备到 [%s]。" % _prompt(&"cast_1")
		3:
			_label.text = "第 3 步 · 走到训练碑前按 %s 试放短语。" % _prompt(&"interact")


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_hint()


func _prompt(action: StringName) -> String:
	var flow := _flow_node()
	return flow.prompt_label(action) if flow != null else GameFlow.key_label(action)


func _profile() -> Profile:
	var flow := _flow_node()
	return flow.profile if flow != null else null


func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null
