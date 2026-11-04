extends RefCounted

## Controller support: default buttons/axes, device-aware labels, and rebinds
## that never erase the other device's binding.

const PATH := "user://test_gamepad_profile.cfg"
const ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down", &"jump",
	&"attack", &"dodge", &"interact", &"cast_1", &"cast_2",
	&"weapon_1", &"weapon_2", &"inventory", &"codex", &"map",
	&"settings", &"help", &"npc_inspire", &"pause", &"restart",
]

var _saved_events: Dictionary = {}


func run(t: Callable) -> void:
	_cleanup()
	_snapshot_actions()
	_test_default_bindings(t)
	_test_labels(t)
	_test_rebind_keeps_other_device(t)
	_test_profile_roundtrip(t)
	_test_reset(t)
	_restore_actions()
	_cleanup()


func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _snapshot_actions() -> void:
	_saved_events.clear()
	for action in ACTIONS:
		if InputMap.has_action(action):
			_saved_events[action] = InputMap.action_get_events(action)


func _restore_actions() -> void:
	for action in _saved_events:
		InputMap.action_erase_events(action)
		for event in _saved_events[action]:
			InputMap.action_add_event(action, event)


func _has_joy_button(action: StringName, button: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button:
			return true
	return false


func _has_joy_axis(action: StringName, axis: int, value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			if motion.axis == axis and is_equal_approx(motion.axis_value, value):
				return true
	return false


func _test_default_bindings(t: Callable) -> void:
	var flow := GameFlow.new()
	var profile := Profile.new()
	flow.ensure_actions()
	flow.apply_joybindings(profile)
	for action in GameFlow.DEFAULT_JOYPAD_BUTTONS:
		var button := int(GameFlow.DEFAULT_JOYPAD_BUTTONS[action])
		t.call(_has_joy_button(StringName(action), button), true, "gamepad_button_%s" % action)
	t.call(_has_joy_axis(&"move_left", JOY_AXIS_LEFT_X, -1.0), true, "gamepad_axis_move_left")
	t.call(_has_joy_axis(&"move_right", JOY_AXIS_LEFT_X, 1.0), true, "gamepad_axis_move_right")
	t.call(_has_joy_axis(&"move_up", JOY_AXIS_LEFT_Y, -1.0), true, "gamepad_axis_move_up")
	t.call(_has_joy_axis(&"move_down", JOY_AXIS_LEFT_Y, 1.0), true, "gamepad_axis_move_down")
	t.call(_has_joy_axis(&"cast_1", JOY_AXIS_TRIGGER_LEFT, 1.0), true, "gamepad_axis_cast_1")
	t.call(_has_joy_axis(&"cast_2", JOY_AXIS_TRIGGER_RIGHT, 1.0), true, "gamepad_axis_cast_2")
	profile.free()
	flow.free()


func _test_labels(t: Callable) -> void:
	var flow := GameFlow.new()
	var profile := Profile.new()
	flow.ensure_actions()
	flow.apply_joybindings(profile)
	t.call(GameFlow.joypad_label(&"jump"), "A", "gamepad_label_jump")
	t.call(GameFlow.joypad_label(&"attack"), "X", "gamepad_label_attack")
	t.call(GameFlow.joypad_label(&"cast_1"), "LT", "gamepad_label_cast_1")
	t.call(GameFlow.joypad_label(&"move_right"), "左摇杆→", "gamepad_label_move_right")
	t.call(GameFlow.joypad_label(&"settings"), "Back", "gamepad_label_settings")
	t.call(GameFlow.input_label(&"jump").contains(" / A"), true, "gamepad_input_label_both")
	flow.using_gamepad = true
	t.call(flow.prompt_label(&"jump"), "A", "gamepad_prompt_uses_pad")
	flow.using_gamepad = false
	t.call(flow.prompt_label(&"jump"), GameFlow.key_label(&"jump"), "gamepad_prompt_uses_keyboard")
	profile.free()
	flow.free()


func _test_rebind_keeps_other_device(t: Callable) -> void:
	var flow := GameFlow.new()
	flow.profile = Profile.new()
	flow.profile_path = PATH
	flow.auto_save = false
	flow.apply_joybindings(flow.profile)

	t.call(flow.set_keybind(&"jump", KEY_K), true, "gamepad_key_rebind")
	t.call(_has_joy_button(&"jump", JOY_BUTTON_A), true, "gamepad_key_rebind_keeps_pad")
	t.call(GameFlow.key_label(&"jump"), OS.get_keycode_string(KEY_K), "gamepad_key_rebind_label")

	t.call(flow.set_joypad_bind(&"jump", JOY_BUTTON_RIGHT_SHOULDER), true, "gamepad_pad_rebind")
	t.call(_has_joy_button(&"jump", JOY_BUTTON_RIGHT_SHOULDER), true, "gamepad_pad_rebind_applied")
	t.call(_has_joy_button(&"jump", JOY_BUTTON_A), false, "gamepad_pad_rebind_replaces")
	t.call(GameFlow.key_label(&"jump"), OS.get_keycode_string(KEY_K), "gamepad_pad_rebind_keeps_key")
	flow.profile.free()
	flow.free()


func _test_profile_roundtrip(t: Callable) -> void:
	var profile := Profile.new()
	profile.keybinds["jump"] = KEY_K
	profile.joybinds["jump"] = JOY_BUTTON_RIGHT_SHOULDER
	profile.save_profile(PATH)
	var loaded := Profile.new()
	t.call(loaded.load_profile(PATH), true, "gamepad_profile_loads")
	t.call(int(loaded.keybinds.get("jump", 0)), KEY_K, "gamepad_profile_key_persists")
	t.call(int(loaded.joybinds.get("jump", -1)), JOY_BUTTON_RIGHT_SHOULDER, "gamepad_profile_pad_persists")
	profile.free()
	loaded.free()


func _test_reset(t: Callable) -> void:
	var flow := GameFlow.new()
	flow.profile = Profile.new()
	flow.profile_path = PATH
	flow.auto_save = false
	flow.set_keybind(&"jump", KEY_K)
	flow.set_joypad_bind(&"jump", JOY_BUTTON_RIGHT_SHOULDER)
	flow.reset_keybinds()
	t.call(flow.profile.keybinds.is_empty(), true, "gamepad_reset_clears_keys")
	t.call(flow.profile.joybinds.is_empty(), true, "gamepad_reset_clears_pads")
	t.call(_has_joy_button(&"jump", JOY_BUTTON_A), true, "gamepad_reset_restores_button")
	t.call(GameFlow.key_label(&"jump"), OS.get_keycode_string(KEY_SPACE), "gamepad_reset_restores_key")
	t.call(_has_joy_axis(&"move_left", JOY_AXIS_LEFT_X, -1.0), true, "gamepad_reset_keeps_axes")
	flow.profile.free()
	flow.free()
