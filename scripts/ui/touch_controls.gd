class_name TouchControls
extends Control

@onready var left_button: Button = $Left
@onready var right_button: Button = $Right
@onready var attack_button: Button = $Attack
@onready var jump_button: Button = $Jump
@onready var dodge_button: Button = $Dodge
@onready var interact_button: Button = $Interact
@onready var cast1_button: Button = $Cast1
@onready var cast2_button: Button = $Cast2


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	_bind(left_button, &"move_left")
	_bind(right_button, &"move_right")
	_bind(attack_button, &"attack")
	_bind(jump_button, &"jump")
	_bind(dodge_button, &"dodge")
	_bind(interact_button, &"interact")
	_bind(cast1_button, &"cast_1")
	_bind(cast2_button, &"cast_2")
	var menu_row := HBoxContainer.new()
	menu_row.position = Vector2(24, 190)
	menu_row.add_theme_constant_override("separation", 8)
	add_child(menu_row)
	for item in [["背包", KEY_TAB], ["造句", KEY_C], ["暂停", KEY_ESCAPE]]:
		var button := Button.new()
		button.text = item[0]
		button.custom_minimum_size = Vector2(72, 44)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_send_key.bind(item[1]))
		menu_row.add_child(button)
	var switch_button := Button.new()
	switch_button.text = "换武器"
	switch_button.position = Vector2(24, 248)
	switch_button.custom_minimum_size = Vector2(100, 44)
	switch_button.pressed.connect(func():
		var player := get_tree().get_first_node_in_group("player") as Player
		if player != null:
			player.switch_weapon(1 - player.active_weapon_slot)
	)
	add_child(switch_button)

func _send_key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventKey.new()
	release.physical_keycode = code
	Input.parse_input_event(release)


func _bind(button: Button, action: StringName) -> void:
	if button == null:
		return
	button.focus_mode = Control.FOCUS_NONE
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))


func _exit_tree() -> void:
	for action in [&"move_left", &"move_right", &"attack", &"jump", &"dodge", &"interact", &"cast_1", &"cast_2"]:
		Input.action_release(action)
