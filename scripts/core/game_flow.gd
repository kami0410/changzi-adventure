class_name GameFlow
extends Node

signal run_started(run: RunState)
signal run_ended(victory: bool)
signal returned_to_hub

const DEFAULT_PROFILE_PATH := "user://changzi_profile.cfg"

var profile: Profile
var current_run: RunState
var profile_path: String = DEFAULT_PROFILE_PATH
var auto_save: bool = true
var last_victory: bool = false
var last_reward: int = 0
var last_ending: Dictionary = {}
var title_shown_this_session: bool = false
var difficulty: int = 0
var shake_scale: float = 1.0
var flash_scale: float = 1.0

const DEFAULT_KEYBINDS: Dictionary = {
	"move_left": KEY_A, "move_right": KEY_D, "jump": KEY_SPACE,
	"attack": KEY_J, "dodge": KEY_L, "interact": KEY_E,
	"cast_1": KEY_Q, "cast_2": KEY_F, "inventory": KEY_TAB,
	"codex": KEY_C, "settings": KEY_F10, "help": KEY_H,
	"npc_inspire": KEY_Y, "weapon_1": KEY_1, "weapon_2": KEY_2,
	"pause": KEY_ESCAPE,
}


func _ready() -> void:
	if profile == null:
		profile = Profile.new()
		add_child(profile)
	# load_profile itself falls back to the .bak file and defaults if missing.
	profile.load_profile(profile_path)
	shake_scale = profile.shake_scale
	flash_scale = profile.flash_scale
	ensure_actions()
	apply_keybinds(profile)


func ensure_actions() -> void:
	for action in DEFAULT_KEYBINDS.keys():
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = int(DEFAULT_KEYBINDS[action])
		InputMap.action_add_event(action, event)


func apply_keybinds(source_profile: Profile) -> void:
	ensure_actions()
	if source_profile == null:
		return
	for action in source_profile.keybinds.keys():
		var keycode := int(source_profile.keybinds[action])
		if keycode <= 0 or not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)


func set_keybind(action: StringName, keycode: int) -> bool:
	if not InputMap.has_action(action) or keycode <= 0:
		return false
	InputMap.action_erase_events(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)
	if profile != null:
		profile.keybinds[String(action)] = keycode
		save_profile()
	return true


func reset_keybinds() -> void:
	if profile == null:
		return
	profile.keybinds.clear()
	for action in DEFAULT_KEYBINDS.keys():
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var event := InputEventKey.new()
		event.physical_keycode = int(DEFAULT_KEYBINDS[action])
		InputMap.action_add_event(action, event)
	save_profile()


static func key_label(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "未设置"
	var events := InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			return OS.get_keycode_string((event as InputEventKey).physical_keycode)
	return "未设置"


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


func return_to_hub() -> void:
	if auto_save:
		save_profile()
	returned_to_hub.emit()


func save_profile() -> void:
	if profile != null:
		profile.save_profile(profile_path)


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
		profile.keybinds = old.keybinds.duplicate()
		old.queue_free()
	title_shown_this_session = true
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = profile_path + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if auto_save:
		save_profile()
