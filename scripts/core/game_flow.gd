class_name GameFlow
extends Node

signal run_started(run: RunState)
signal run_ended(victory: bool)
signal returned_to_hub
## Emitted when the last input device changes, so HUD prompts can follow it.
signal input_device_changed(using_gamepad: bool)
## Emitted after a keyboard or controller binding changes, so cached key
## labels in the HUD and world prompts can be rebuilt.
signal keybinds_changed

const DEFAULT_PROFILE_PATH := "user://changzi_profile.cfg"

var profile: Profile
var current_run: RunState
var profile_path: String = DEFAULT_PROFILE_PATH
## Mid-run checkpoint; tests point this at a temporary file.
var run_save_path: String = RunSave.DEFAULT_PATH
## Set by the title screen's "continue run" button and consumed by game.gd.
var resume_requested := false
var auto_save: bool = true
## Per-run variety: encounter variation (EncounterVariation) and the extra
## big-map platforms (RoomVariety). Acceptance suites that check the authored
## waves and layouts switch it off.
var encounter_variation: bool = true
## Dead Cells-style roaming encounters (0.15): ordinary fights spread their
## enemies through the region instead of locking an arena and spawning waves.
## Acceptance suites that walk the authored lock/wave flow switch it off.
var roaming_encounters: bool = true
var last_victory: bool = false
var last_reward: int = 0
var last_ending: Dictionary = {}
var title_shown_this_session: bool = false
var difficulty: int = 0
var shake_scale: float = 1.0
var flash_scale: float = 1.0
## Last device used. Menus and HUD read this through prompt_label().
var using_gamepad := false
## Set while the keybind page waits for the next button, so gameplay does not
## interpret the same press as an action.
var input_capture_active := false

const DEFAULT_KEYBINDS: Dictionary = {
	"move_left": KEY_A, "move_right": KEY_D, "move_up": KEY_W, "move_down": KEY_S,
	"jump": KEY_SPACE, "attack": KEY_J, "dodge": KEY_L, "interact": KEY_E,
	"cast_1": KEY_Q, "cast_2": KEY_F, "inventory": KEY_TAB,
	"codex": KEY_C, "settings": KEY_F10, "help": KEY_H,
	"npc_inspire": KEY_Y, "weapon_1": KEY_1, "weapon_2": KEY_2,
	"map": KEY_M, "pause": KEY_P, "restart": KEY_R,
}
## Extra keys that stay bound alongside the primary one (arrows and Esc).
const SECONDARY_KEYBINDS: Dictionary = {
	"move_left": [KEY_LEFT], "move_right": [KEY_RIGHT],
	"move_up": [KEY_UP], "move_down": [KEY_DOWN],
	"pause": [KEY_ESCAPE],
}
## Standard controller layout. Face buttons follow the Xbox positions, which
## matches the on-screen glyph names; every one can be rebound in Settings.
const DEFAULT_JOYPAD_BUTTONS: Dictionary = {
	"jump": JOY_BUTTON_A,
	"attack": JOY_BUTTON_X,
	"dodge": JOY_BUTTON_B,
	"interact": JOY_BUTTON_Y,
	"npc_inspire": JOY_BUTTON_Y,
	"weapon_1": JOY_BUTTON_LEFT_SHOULDER,
	"weapon_2": JOY_BUTTON_RIGHT_SHOULDER,
	"pause": JOY_BUTTON_START,
	"restart": JOY_BUTTON_START,
	"inventory": JOY_BUTTON_DPAD_DOWN,
	"codex": JOY_BUTTON_DPAD_UP,
	"map": JOY_BUTTON_DPAD_LEFT,
	"help": JOY_BUTTON_DPAD_RIGHT,
	"settings": JOY_BUTTON_BACK,
}
## Left stick moves; triggers cast. Cast triggers share the keyboard slots.
const JOYPAD_AXES: Dictionary = {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"cast_1": [JOY_AXIS_TRIGGER_LEFT, 1.0],
	"cast_2": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
}


func _ready() -> void:
	# Device tracking must keep working while a modal page pauses the game.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if profile == null:
		profile = Profile.new()
		add_child(profile)
	# load_profile itself falls back to the .bak file and defaults if missing.
	profile.load_profile(profile_path)
	shake_scale = profile.shake_scale
	flash_scale = profile.flash_scale
	apply_master_volume()
	apply_window_mode()
	ensure_actions()
	apply_keybinds(profile)
	# The window close button must first give the active run a chance to save.
	# Explicit quit() calls (pause menu, tests) still exit immediately.
	if get_tree() != null:
		get_tree().auto_accept_quit = false


func _input(event: InputEvent) -> void:
	# Observe only: never consume. This keeps menu prompts in sync with the
	# device the player actually touched.
	if event is InputEventKey:
		if (event as InputEventKey).pressed:
			_set_using_gamepad(false)
	elif event is InputEventMouseButton:
		if (event as InputEventMouseButton).pressed:
			_set_using_gamepad(false)
	elif event is InputEventJoypadButton:
		if (event as InputEventJoypadButton).pressed:
			_set_using_gamepad(true)
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > 0.5:
			_set_using_gamepad(true)


func _set_using_gamepad(value: bool) -> void:
	if using_gamepad == value:
		return
	using_gamepad = value
	input_device_changed.emit(value)


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST:
		return
	var tree := get_tree()
	if tree == null:
		return
	var scene := tree.current_scene
	if scene != null and scene.has_method("save_run_on_exit"):
		scene.call("save_run_on_exit")
	tree.quit()


func has_run_save() -> bool:
	return auto_save and RunSave.has_save(run_save_path)


## Godot's built-in UI actions ship with keyboard and D-pad/stick events but
## no face buttons, so menu confirm (A) and back (B) do nothing on a pad unless
## the project adds them. They are UI-level bindings: rebinding gameplay keys
## must not take them away.
const UI_JOYPAD_BUTTONS := {
	"ui_accept": [JOY_BUTTON_A],
	"ui_cancel": [JOY_BUTTON_B],
}


func ensure_actions() -> void:
	for action in DEFAULT_KEYBINDS.keys():
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		_apply_default_keyboard(StringName(action))
	_ensure_ui_joypad_buttons()


func _ensure_ui_joypad_buttons() -> void:
	for action in UI_JOYPAD_BUTTONS.keys():
		var action_name := StringName(action)
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		var present: Array[int] = []
		for event in InputMap.action_get_events(action_name):
			if event is InputEventJoypadButton:
				present.append((event as InputEventJoypadButton).button_index)
		for button in UI_JOYPAD_BUTTONS[action]:
			if present.has(int(button)):
				continue
			var event := InputEventJoypadButton.new()
			event.button_index = int(button)
			InputMap.action_add_event(action_name, event)


## Applies a profile's custom keyboards and controller buttons. Keyboard rebinds
## never erase controller events, and vice versa.
func apply_keybinds(source_profile: Profile) -> void:
	ensure_actions()
	if source_profile == null:
		return
	for action in source_profile.keybinds.keys():
		var keycode := int(source_profile.keybinds[action])
		if keycode <= 0 or not InputMap.has_action(action):
			continue
		_set_keyboard_events(StringName(action), keycode)
	apply_joybindings(source_profile)
	keybinds_changed.emit()


func apply_joybindings(source_profile: Profile) -> void:
	for action in DEFAULT_JOYPAD_BUTTONS.keys():
		var action_name := StringName(action)
		if not InputMap.has_action(action_name):
			continue
		var button := int(DEFAULT_JOYPAD_BUTTONS[action])
		if source_profile != null and source_profile.joybinds.has(action):
			button = int(source_profile.joybinds[action])
		_erase_joypad_buttons(action_name)
		_add_joypad_button(action_name, button)
	for action in JOYPAD_AXES.keys():
		var action_name := StringName(action)
		if not InputMap.has_action(action_name):
			continue
		var entry: Array = JOYPAD_AXES[action]
		_erase_joypad_motion(action_name)
		_add_joypad_axis(action_name, int(entry[0]), float(entry[1]))


func set_keybind(action: StringName, keycode: int) -> bool:
	if not InputMap.has_action(action) or keycode <= 0:
		return false
	_set_keyboard_events(action, keycode)
	if profile != null:
		profile.keybinds[String(action)] = keycode
		save_profile()
	keybinds_changed.emit()
	return true


func set_joypad_bind(action: StringName, button: int) -> bool:
	if not InputMap.has_action(action) or button < 0:
		return false
	_erase_joypad_buttons(action)
	_add_joypad_button(action, button)
	if profile != null:
		profile.joybinds[String(action)] = button
		save_profile()
	keybinds_changed.emit()
	return true


func reset_keybinds() -> void:
	if profile == null:
		return
	profile.keybinds.clear()
	profile.joybinds.clear()
	for action in DEFAULT_KEYBINDS.keys():
		_apply_default_keyboard(StringName(action))
	apply_joybindings(profile)
	save_profile()
	keybinds_changed.emit()


func _apply_default_keyboard(action: StringName) -> void:
	if not InputMap.has_action(action):
		return
	_set_keyboard_events(action, int(DEFAULT_KEYBINDS[action]))


func _set_keyboard_events(action: StringName, keycode: int) -> void:
	if not InputMap.has_action(action) or keycode <= 0:
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	var primary := InputEventKey.new()
	primary.physical_keycode = keycode
	InputMap.action_add_event(action, primary)
	for secondary in SECONDARY_KEYBINDS.get(String(action), []):
		if int(secondary) == keycode:
			continue
		var extra := InputEventKey.new()
		extra.physical_keycode = int(secondary)
		InputMap.action_add_event(action, extra)


func _erase_joypad_buttons(action: StringName) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			InputMap.action_erase_event(action, event)


func _erase_joypad_motion(action: StringName) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			InputMap.action_erase_event(action, event)


func _add_joypad_button(action: StringName, button: int) -> void:
	if button < 0:
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button:
			return
	var joy := InputEventJoypadButton.new()
	joy.button_index = button
	InputMap.action_add_event(action, joy)


func _add_joypad_axis(action: StringName, axis: int, value: float) -> void:
	var motion := InputEventJoypadMotion.new()
	motion.axis = axis
	motion.axis_value = value
	InputMap.action_add_event(action, motion)


static func key_label(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "未设置"
	var events := InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			var key := event as InputEventKey
			# Built-in UI actions (ui_accept/ui_cancel) carry a keycode but no
			# physical_keycode; gameplay rebinds write physical codes.
			var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
			return OS.get_keycode_string(code)
	return "未设置"


## Controller label for the first joypad binding, or "" when there is none.
static func joypad_label(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			return joypad_button_name((event as InputEventJoypadButton).button_index)
		if event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			match motion.axis:
				JOY_AXIS_LEFT_X:
					return "左摇杆←" if motion.axis_value < 0.0 else "左摇杆→"
				JOY_AXIS_LEFT_Y:
					return "左摇杆↑" if motion.axis_value < 0.0 else "左摇杆↓"
				JOY_AXIS_TRIGGER_LEFT:
					return "LT"
				JOY_AXIS_TRIGGER_RIGHT:
					return "RT"
	return ""


static func joypad_button_name(button: int) -> String:
	match button:
		JOY_BUTTON_A: return "A"
		JOY_BUTTON_B: return "B"
		JOY_BUTTON_X: return "X"
		JOY_BUTTON_Y: return "Y"
		JOY_BUTTON_LEFT_SHOULDER: return "LB"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB"
		JOY_BUTTON_BACK: return "Back"
		JOY_BUTTON_START: return "Start"
		JOY_BUTTON_LEFT_STICK: return "L3"
		JOY_BUTTON_RIGHT_STICK: return "R3"
		JOY_BUTTON_DPAD_UP: return "十字键↑"
		JOY_BUTTON_DPAD_DOWN: return "十字键↓"
		JOY_BUTTON_DPAD_LEFT: return "十字键←"
		JOY_BUTTON_DPAD_RIGHT: return "十字键→"
	return "手柄键 %d" % button


## Both bindings at once, for pages that explain the controls.
static func input_label(action: StringName) -> String:
	var keyboard := key_label(action)
	var pad := joypad_label(action)
	if pad.is_empty() or pad == keyboard:
		return keyboard
	return "%s / %s" % [keyboard, pad]


## The single prompt for the device currently in the player's hands.
func prompt_label(action: StringName) -> String:
	if using_gamepad:
		var pad := joypad_label(action)
		if not pad.is_empty():
			return pad
	return key_label(action)


## Prompt for leaving a modal page. Controller B is ui_cancel; keyboard pages
## may offer their own shortcuts (C, Tab, M...) plus Esc.
func close_prompt(keyboard_alts: String = "Esc") -> String:
	if using_gamepad:
		var pad := joypad_label(&"ui_cancel")
		if not pad.is_empty():
			return pad
		return "B"
	return keyboard_alts


## First button a player can actually press. Disabled buttons cannot take
## focus, so pages must not hand them the initial focus.
static func first_pressable_button(root: Node) -> Button:
	if root == null:
		return null
	for node in root.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and not button.disabled and button.is_visible_in_tree():
			return button
	return null


func start_run(seed_value: int = 0) -> RunState:
	last_victory = false
	last_reward = 0
	current_run = RunState.new()
	current_run.reset_for_new_run(seed_value)
	run_started.emit(current_run)
	return current_run


func end_run(victory: bool) -> void:
	if current_run == null:
		return
	var reward := int(round((10 + current_run.corruption_tier() * 5) * Difficulty.reward_multiplier(difficulty)))
	last_victory = victory
	last_reward = reward
	if profile != null:
		profile.add_memory_fragments(reward)
	run_ended.emit(victory)
	current_run = null
	if auto_save:
		save_profile()
		RunSave.clear(run_save_path)


func return_to_hub() -> void:
	if auto_save:
		save_profile()
		# Returning to the Hub abandons the active run.
		RunSave.clear(run_save_path)
	returned_to_hub.emit()


func save_profile() -> void:
	if profile != null:
		profile.save_profile(profile_path)


## Applies the persisted master volume at startup and after the settings page
## changes it. A stored 0 maps to the mixer's -60 dB floor instead of -inf.
## Restores the saved window mode; headless runs (tests, export checks) skip it.
func apply_window_mode() -> void:
	if profile == null or DisplayServer.get_name() == "headless":
		return
	var full := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	if profile.fullscreen != full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if profile.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


func apply_master_volume() -> void:
	var volume := clampf(profile.master_volume if profile != null else 1.0, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001)))


## Title "new game": discard progress and start from the default profile.
func reset_profile() -> void:
	var old := profile
	profile = Profile.new()
	profile.name = "Profile"
	add_child(profile)
	if old != null:
		# "Clear progress" must not erase accessibility settings or keybinds.
		profile.shake_scale = old.shake_scale
		profile.flash_scale = old.flash_scale
		profile.text_scale = old.text_scale
		profile.master_volume = old.master_volume
		profile.fullscreen = old.fullscreen
		profile.grimoire = old.grimoire.duplicate(true)
		profile.keybinds = old.keybinds.duplicate()
		profile.joybinds = old.joybinds.duplicate()
		old.queue_free()
	title_shown_this_session = true
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = profile_path + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if auto_save:
		RunSave.clear(run_save_path)
		save_profile()
