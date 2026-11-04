extends SceneTree

## End-to-end controller pass: real joypad events must drive the mapped actions,
## move the player, jump, pause, and open the pause menu with keyboard focus.

var failures: int = 0
var assertions: int = 0

const PROFILE_PATH := "user://test_gamepad_profile.cfg"
const RUN_PATH := "user://test_gamepad_run.cfg"


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("GAMEPAD FAIL: " + label)


func _initialize() -> void:
	_run.call_deferred()


func _cleanup_files() -> void:
	RunSave.clear(RUN_PATH)
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = PROFILE_PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _focus_inside(page: Control, control: Control) -> bool:
	return control != null and page != null and page.is_ancestor_of(control)


func _press_button(button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame


func _release_button(button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _press_key(keycode: int) -> void:
	# A real keyboard event carries both keycode and physical_keycode; built-in
	# ui_accept/ui_cancel match on keycode, custom gameplay actions on physical.
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame


func _release_key(keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _move_axis(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)
	await process_frame


func _wait_mds(scene, timeout := 8.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._mds_world != null and not scene._mds_world.changing_room and not scene._mds_world.current_room.is_empty():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _test_action_mapping() -> void:
	# Give the Input singleton a frame to initialize before the first event.
	await process_frame
	# Every gameplay action must fire from the standard face button.
	var buttons := {
		"jump": JOY_BUTTON_A,
		"attack": JOY_BUTTON_X,
		"dodge": JOY_BUTTON_B,
		"interact": JOY_BUTTON_Y,
		"pause": JOY_BUTTON_START,
	}
	for action in buttons:
		var button := int(buttons[action])
		await _press_button(button)
		check(Input.is_action_pressed(action), "gamepad_action_%s" % action)
		await _release_button(button)
		check(not Input.is_action_pressed(action), "gamepad_action_%s_release" % action)

	await _press_button(JOY_BUTTON_LEFT_SHOULDER)
	check(Input.is_action_pressed("weapon_1"), "gamepad_weapon_1")
	await _release_button(JOY_BUTTON_LEFT_SHOULDER)
	await _press_button(JOY_BUTTON_RIGHT_SHOULDER)
	check(Input.is_action_pressed("weapon_2"), "gamepad_weapon_2")
	await _release_button(JOY_BUTTON_RIGHT_SHOULDER)

	var trigger := InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_LEFT
	trigger.axis_value = 1.0
	Input.parse_input_event(trigger)
	await process_frame
	check(Input.is_action_pressed("cast_1"), "gamepad_trigger_cast_1")
	trigger = InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_LEFT
	trigger.axis_value = 0.0
	Input.parse_input_event(trigger)
	await process_frame
	check(not Input.is_action_pressed("cast_1"), "gamepad_trigger_cast_1_release")

	# Built-in UI actions need face-button events; Godot ships only keyboard
	# and D-pad/stick for them, so A/B must be added by the project.
	await _press_button(JOY_BUTTON_A)
	check(Input.is_action_pressed("ui_accept"), "gamepad_a_is_ui_accept")
	await _release_button(JOY_BUTTON_A)
	await _press_button(JOY_BUTTON_B)
	check(Input.is_action_pressed("ui_cancel"), "gamepad_b_is_ui_cancel")
	await _release_button(JOY_BUTTON_B)


func _run() -> void:
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.profile_path = PROFILE_PATH
	flow.run_save_path = RUN_PATH
	flow.title_shown_this_session = true
	flow.resume_requested = false
	flow.difficulty = 0
	_cleanup_files()

	await _test_action_mapping()

	# Device tracking: the pad press must switch prompts, the key must switch back.
	flow.using_gamepad = false
	await _press_button(JOY_BUTTON_A)
	check(flow.using_gamepad, "gamepad_device_detected")
	check(flow.prompt_label(&"jump") == "A", "gamepad_prompt_after_pad")
	await _release_button(JOY_BUTTON_A)
	await _press_key(KEY_J)
	check(not flow.using_gamepad, "gamepad_keyboard_detected")
	check(flow.prompt_label(&"attack") == OS.get_keycode_string(KEY_J), "gamepad_prompt_after_key")
	await _release_key(KEY_J)

	# Real scene: stick movement, jump, pause focus, and the pause Settings page.
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.4).timeout
	if scene._story != null and scene._story.is_open():
		scene._story.close()
	check(await _wait_mds(scene), "gamepad_scene_loads")

	scene.player.global_position = scene._last_checkpoint
	scene.player.velocity = Vector2.ZERO
	await create_timer(0.35).timeout
	var start_x: float = scene.player.global_position.x
	await _move_axis(1.0)
	await create_timer(0.45).timeout
	await _move_axis(0.0)
	check(scene.player.global_position.x > start_x + 10.0, "gamepad_stick_moves_player")

	scene.player.global_position = scene._last_checkpoint
	scene.player.velocity = Vector2.ZERO
	await create_timer(0.3).timeout
	var start_y: float = scene.player.global_position.y
	await _press_button(JOY_BUTTON_A)
	await create_timer(0.12).timeout
	check(scene.player.velocity.y < 0.0 or scene.player.global_position.y < start_y - 4.0, "gamepad_a_jumps")
	await _release_button(JOY_BUTTON_A)
	await create_timer(0.4).timeout

	scene.pause_menu.open_pause()
	await process_frame
	check(paused, "gamepad_pause_pauses_tree")
	check(scene.pause_menu.is_open(), "gamepad_pause_menu_open")
	var resume := scene.pause_menu.find_child("ResumeButton", true, false) as Button
	check(root.gui_get_focus_owner() == resume, "gamepad_pause_focus_resume")
	var settings_button := scene.pause_menu.find_child("SettingsButton", true, false) as Button
	check(settings_button != null, "gamepad_pause_has_settings")
	if settings_button != null:
		await _press_button(JOY_BUTTON_DPAD_DOWN)
		await process_frame
		check(root.gui_get_focus_owner() == settings_button, "gamepad_pause_dpad_focus")
		await _release_button(JOY_BUTTON_DPAD_DOWN)
		# Real A opens Settings from the pause menu.
		await _press_button(JOY_BUTTON_A)
		await process_frame
		await _release_button(JOY_BUTTON_A)
		await process_frame
		check(scene.settings_menu.visible, "gamepad_pause_opens_settings")
		check(root.gui_get_focus_owner() != null, "gamepad_settings_focus")
		# B closes Settings back to the pause menu, still paused, with focus on
		# the item that opened it (not straight back into the game).
		await _press_button(JOY_BUTTON_B)
		await process_frame
		check(not scene.settings_menu.visible, "gamepad_b_closes_pause_settings")
		check(scene.pause_menu.is_open(), "gamepad_settings_close_returns_to_pause")
		check(paused, "gamepad_settings_close_keeps_pause")
		check(root.gui_get_focus_owner() == settings_button, "gamepad_settings_close_restores_focus")
		await _release_button(JOY_BUTTON_B)
		# Another B resumes from the pause menu.
		await _press_button(JOY_BUTTON_B)
		await process_frame
		await _release_button(JOY_BUTTON_B)
		await process_frame
		check(not paused, "gamepad_pause_b_after_settings_resumes")
		check(not scene.pause_menu.is_open(), "gamepad_pause_b_after_settings_hides")
		# Keyboard path: P pauses, Enter opens Settings from the focused item,
		# and Esc closes it back to the pause menu.
		await _press_key(KEY_P)
		await _release_key(KEY_P)
		await process_frame
		check(paused, "gamepad_key_pause_pauses")
		check(scene.pause_menu.is_open(), "gamepad_key_pause_menu_visible")
		settings_button.grab_focus()
		await process_frame
		await _press_key(KEY_ENTER)
		await _release_key(KEY_ENTER)
		await process_frame
		check(scene.settings_menu.visible, "gamepad_key_opens_settings")
		await _press_key(KEY_ESCAPE)
		await _release_key(KEY_ESCAPE)
		await process_frame
		check(scene.pause_menu.is_open(), "gamepad_key_esc_returns_to_pause")
		check(paused, "gamepad_key_esc_keeps_pause")
		check(root.gui_get_focus_owner() == settings_button, "gamepad_key_esc_restores_focus")
		# Mixed round trip: the pad opens Settings, Esc closes it.
		await _press_button(JOY_BUTTON_A)
		await process_frame
		await _release_button(JOY_BUTTON_A)
		await process_frame
		check(scene.settings_menu.visible, "gamepad_mixed_pad_opens_settings")
		await _press_key(KEY_ESCAPE)
		await _release_key(KEY_ESCAPE)
		await process_frame
		check(scene.pause_menu.is_open(), "gamepad_mixed_esc_returns_to_pause")
		check(paused, "gamepad_mixed_keeps_pause")
		check(root.gui_get_focus_owner() == settings_button, "gamepad_mixed_focus_restored")
		# Leave the pause menu so the subpage checks below start from gameplay.
		await _press_button(JOY_BUTTON_B)
		await process_frame
		await _release_button(JOY_BUTTON_B)
		await process_frame
		check(not paused, "gamepad_mixed_pause_b_resumes")

	# Settings subpages own the top of the stack: B closes the subpage first,
	# then the settings page, and the world stays paused in between.
	scene._toggle_overlay(scene.settings_menu)
	await process_frame
	var ai_button: Button = null
	for button in scene.settings_menu.find_children("*", "Button", true, false):
		if String(button.text).contains("AI"):
			ai_button = button
			break
	check(ai_button != null, "gamepad_settings_has_ai_button")
	if ai_button != null:
		# Real A press, not a synthetic pressed.emit(): this proves the new
		# ui_accept face-button binding drives focused menu buttons.
		ai_button.grab_focus()
		await process_frame
		await _press_button(JOY_BUTTON_A)
		await process_frame
		await _release_button(JOY_BUTTON_A)
		await process_frame
		var ai_page: AISettingsUI = scene.settings_menu._ai_page
		check(ai_page != null and ai_page.visible, "gamepad_ai_page_opens")
		check(scene.settings_menu.has_subpage(), "gamepad_settings_tracks_ai_page")
		check(paused, "gamepad_ai_page_keeps_pause")
		await _press_button(JOY_BUTTON_B)
		await process_frame
		check(ai_page == null or not ai_page.visible, "gamepad_b_closes_ai_page")
		check(scene.settings_menu.visible, "gamepad_b_keeps_settings")
		check(paused, "gamepad_b_keeps_pause")
		await _release_button(JOY_BUTTON_B)
		await _press_button(JOY_BUTTON_B)
		await process_frame
		check(not scene.settings_menu.visible, "gamepad_b_closes_settings")
		check(not paused, "gamepad_settings_b_unpauses")
		await _release_button(JOY_BUTTON_B)

	# Help opened from Settings is a Settings subpage too (previously it was
	# left visible and unpaused after the settings page closed underneath it).
	scene._toggle_overlay(scene.settings_menu)
	await process_frame
	var help_button: Button = null
	for button in scene.settings_menu.find_children("*", "Button", true, false):
		if String(button.text).contains("操作说明"):
			help_button = button
			break
	check(help_button != null, "gamepad_settings_has_help_button")
	if help_button != null:
		help_button.pressed.emit()
		await process_frame
		check(scene._help_ui.is_open(), "gamepad_settings_opens_help")
		check(scene.settings_menu.has_subpage(), "gamepad_settings_tracks_help")
		check(paused, "gamepad_help_keeps_pause")
		await _press_button(JOY_BUTTON_B)
		await process_frame
		check(not scene._help_ui.is_open(), "gamepad_b_closes_help")
		check(scene.settings_menu.visible, "gamepad_b_keeps_settings_after_help")
		await _release_button(JOY_BUTTON_B)
		await _press_button(JOY_BUTTON_B)
		await process_frame
		check(not paused, "gamepad_help_then_settings_unpauses")
		await _release_button(JOY_BUTTON_B)

	# Inventory/codex overlays: the pad must land on a pressable control. The
	# codex starts on the first word's 选择 button, so A builds a phrase
	# instead of immediately closing the page.
	scene._toggle_overlay(scene.inventory_ui)
	await process_frame
	var inventory_focus := root.gui_get_focus_owner() as Button
	check(inventory_focus != null and not inventory_focus.disabled, "gamepad_inventory_focus_pressable")
	check(inventory_focus != null and inventory_focus.is_visible_in_tree(), "gamepad_inventory_focus_visible")
	await _press_button(JOY_BUTTON_B)
	await process_frame
	await _release_button(JOY_BUTTON_B)
	check(scene._overlay == null, "gamepad_inventory_b_closes")

	scene._toggle_overlay(scene.codex_ui)
	await process_frame
	var codex_focus := root.gui_get_focus_owner() as Button
	check(codex_focus != null and not codex_focus.disabled, "gamepad_codex_focus_pressable")
	check(codex_focus != null and codex_focus.text == "选择", "gamepad_codex_focus_first_word")
	await _press_button(JOY_BUTTON_A)
	await process_frame
	await _release_button(JOY_BUTTON_A)
	check(scene._overlay == scene.codex_ui, "gamepad_codex_a_keeps_page")
	check(scene.codex_ui._selected_words.size() == 1, "gamepad_codex_a_selects_word")
	# Selecting a word rebuilds the grid; focus must stay on the same word's
	# now-"取消选择" button so a second A can deselect without a mouse.
	var codex_after_pick := root.gui_get_focus_owner() as Button
	check(codex_after_pick != null and codex_after_pick.is_visible_in_tree(),
		"gamepad_codex_focus_survives_word_rebuild")
	check(codex_after_pick != null and codex_after_pick.text == "取消选择",
		"gamepad_codex_focus_stays_on_picked_word")
	# An async AI reply clears the selection and rebuilds the word grid. The pad
	# must keep focus on the same word instead of dropping it on a freed button.
	var picked_id := StringName(codex_after_pick.get_meta("word_id", &"")) if codex_after_pick != null else &""
	scene.codex_ui._free_text.text = "让雷落在火里"
	scene.codex_ui._on_ai_intent("让雷落在火里", {
		"name": "AI 测试",
		"shape": "flame",
		"tags": ["flame"],
		"confidence": 0.9,
		"components": {"damage": 5},
	})
	await process_frame
	await process_frame
	var after_ai_focus := root.gui_get_focus_owner() as Button
	check(after_ai_focus != null and after_ai_focus.is_visible_in_tree(),
		"gamepad_codex_focus_survives_ai_rebuild")
	check(after_ai_focus != null and StringName(after_ai_focus.get_meta("word_id", &"")) == picked_id,
		"gamepad_codex_ai_focus_keeps_word")
	await _press_button(JOY_BUTTON_A)
	await process_frame
	await _release_button(JOY_BUTTON_A)
	check(scene.codex_ui._selected_words.size() == 1,
		"gamepad_codex_a_after_ai_reply_selects")
	await _press_button(JOY_BUTTON_B)
	await process_frame
	await _release_button(JOY_BUTTON_B)
	check(scene._overlay == null, "gamepad_codex_b_closes")
	var after_close_focus := root.gui_get_focus_owner()
	check(after_close_focus == null or after_close_focus.is_visible_in_tree(), "gamepad_overlay_close_no_stale_focus")

	# The generic entry picker skips disabled buttons (the codex itself has
	# disabled equip buttons, so a blind first-child grab can strand focus).
	var synthetic := Control.new()
	root.add_child(synthetic)
	var disabled_first := Button.new()
	disabled_first.text = "禁用"
	disabled_first.disabled = true
	synthetic.add_child(disabled_first)
	var enabled_second := Button.new()
	enabled_second.text = "可用"
	synthetic.add_child(enabled_second)
	check(GameFlow.first_pressable_button(synthetic) == enabled_second, "gamepad_first_pressable_skips_disabled")
	synthetic.free()

	# A wordless codex has no 选择 button: pad focus must fall back to 返回 so A
	# still leaves the page instead of dying on an empty grid.
	var empty_codex = load("res://scenes/ui/codex.tscn").instantiate()
	root.add_child(empty_codex)
	await process_frame
	empty_codex.bind(PhraseResolver.new(), RunState.new())
	empty_codex.focus_entry()
	await process_frame
	var empty_codex_focus := root.gui_get_focus_owner() as Button
	check(empty_codex_focus != null, "gamepad_empty_codex_focus_exists")
	check(empty_codex_focus != null and not empty_codex_focus.disabled, "gamepad_empty_codex_focus_pressable")
	check(empty_codex_focus != null and empty_codex_focus.is_visible_in_tree(), "gamepad_empty_codex_focus_visible")
	var empty_codex_closed: Array[bool] = [false]
	empty_codex.close_requested.connect(func(): empty_codex_closed[0] = true)
	await _press_button(JOY_BUTTON_A)
	await process_frame
	await _release_button(JOY_BUTTON_A)
	check(empty_codex_closed[0], "gamepad_empty_codex_a_closes")
	root.remove_child(empty_codex)
	empty_codex.free()
	await process_frame

	# Start resumes normally as well.
	await _press_button(JOY_BUTTON_START)
	await process_frame
	check(paused, "gamepad_start_opens_pause")
	await _release_button(JOY_BUTTON_START)
	await process_frame
	await _press_button(JOY_BUTTON_START)
	await process_frame
	check(not paused, "gamepad_start_resumes")
	await _release_button(JOY_BUTTON_START)

	# Pause confirmations: Start must not hide the pause menu and resume the
	# world underneath an open Restart/Quit dialog; Esc cancels back to Resume.
	await _press_button(JOY_BUTTON_START)
	await process_frame
	await _release_button(JOY_BUTTON_START)
	check(paused and scene.pause_menu.is_open(), "gamepad_confirm_pause_open")
	var restart_button := scene.pause_menu.find_child("RestartButton", true, false) as Button
	check(restart_button != null, "gamepad_confirm_restart_button")
	if restart_button != null:
		restart_button.pressed.emit()
		await process_frame
		var restart_confirm: ConfirmationDialog = scene.pause_menu._confirm
		check(restart_confirm != null and restart_confirm.visible,
			"gamepad_confirm_restart_opens")
		check(restart_confirm != null and restart_confirm.dialog_text.contains("重新开始"),
			"gamepad_confirm_restart_text")
		await _press_button(JOY_BUTTON_START)
		await process_frame
		await _release_button(JOY_BUTTON_START)
		check(restart_confirm != null and restart_confirm.visible,
			"gamepad_confirm_restart_ignores_start")
		check(paused and scene.pause_menu.is_open(),
			"gamepad_confirm_restart_keeps_pause")
		await _press_key(KEY_ESCAPE)
		await _release_key(KEY_ESCAPE)
		check(restart_confirm == null or not restart_confirm.visible,
			"gamepad_confirm_restart_escape_cancels")
		check(paused and scene.pause_menu.is_open(),
			"gamepad_confirm_restart_cancel_keeps_pause")
		var restart_cancel_focus := root.gui_get_focus_owner()
		check(restart_cancel_focus != null
			and String(restart_cancel_focus.name) == "ResumeButton",
			"gamepad_confirm_restart_cancel_focus")
	var quit_button := scene.pause_menu.find_child("QuitButton", true, false) as Button
	check(quit_button != null, "gamepad_confirm_quit_button")
	if quit_button != null:
		quit_button.pressed.emit()
		await process_frame
		var quit_confirm: ConfirmationDialog = scene.pause_menu._confirm
		check(quit_confirm != null and quit_confirm.visible, "gamepad_confirm_quit_opens")
		await _press_button(JOY_BUTTON_START)
		await process_frame
		await _release_button(JOY_BUTTON_START)
		check(quit_confirm != null and quit_confirm.visible,
			"gamepad_confirm_quit_ignores_start")
		check(paused and scene.pause_menu.is_open(), "gamepad_confirm_quit_keeps_pause")
		await _press_key(KEY_ESCAPE)
		await _release_key(KEY_ESCAPE)
		check(quit_confirm == null or not quit_confirm.visible,
			"gamepad_confirm_quit_escape_cancels")
		check(paused and scene.pause_menu.is_open(),
			"gamepad_confirm_quit_cancel_keeps_pause")
	await _press_button(JOY_BUTTON_START)
	await process_frame
	await _release_button(JOY_BUTTON_START)
	check(not paused, "gamepad_confirm_closes_pause")

	# Boss authority choice owns the pause state: a pause press must neither
	# resume the world underneath it nor stack the pause menu on top.
	var authority_options: Array = scene._chapter_plan.authority_pool
	scene._authority_choice.open(authority_options)
	await process_frame
	check(paused, "gamepad_authority_pauses")
	await _press_button(JOY_BUTTON_START)
	await process_frame
	check(paused, "gamepad_authority_start_ignored")
	check(scene._authority_choice.is_open(), "gamepad_authority_stays_open")
	check(not scene.pause_menu.is_open(), "gamepad_authority_no_pause_menu")
	await _release_button(JOY_BUTTON_START)
	await _press_key(KEY_P)
	check(paused, "gamepad_authority_p_ignored")
	check(scene._authority_choice.is_open(), "gamepad_authority_open_after_p")
	# Release the key: a held P would keep the pause action down for the rest of
	# the suite and hide polled "just pressed" transitions in later Hub checks.
	await _release_key(KEY_P)
	scene._authority_choice._choose(0)
	await process_frame
	check(not paused, "gamepad_authority_resumes_after_choice")

	var keybind := KeybindUI.new()
	root.add_child(keybind)
	await process_frame
	keybind.open()
	await process_frame
	check(root.gui_get_focus_owner() != null, "gamepad_keybind_focus")
	check(flow.input_capture_active, "gamepad_keybind_blocks_gameplay")
	var jump_button := keybind._buttons.get(&"jump") as Button
	check(jump_button != null, "gamepad_keybind_has_jump_row")
	if jump_button != null:
		jump_button.pressed.emit()
		await process_frame
		var capturing := keybind._buttons.get(&"jump") as Button
		check(root.gui_get_focus_owner() == capturing, "gamepad_keybind_focus_after_capture_start")
		await _press_key(KEY_K)
		var rebound := keybind._buttons.get(&"jump") as Button
		check(root.gui_get_focus_owner() == rebound, "gamepad_keybind_focus_after_rebind")
		check(GameFlow.key_label(&"jump") == OS.get_keycode_string(KEY_K), "gamepad_keybind_rebind_applied")
	keybind.close()
	await process_frame
	check(not flow.input_capture_active, "gamepad_keybind_releases_input")

	scene.queue_free()
	await process_frame
	await process_frame

	# Hub: Y is both interact and npc_inspire. One press during dialogue must
	# open the inspiration panel without re-opening the dialogue underneath.
	var hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await process_frame
	await process_frame
	var npcs: Array = hub.get_npcs()
	check(npcs.size() > 0, "gamepad_hub_has_npcs")
	var talkable = null
	for candidate in npcs:
		if candidate.npc_id != &"wenjin" and candidate.npc_id != &"baiyu":
			talkable = candidate
			break
	check(talkable != null, "gamepad_hub_has_talkable_npc")
	if talkable != null:
		var npc = talkable
		hub.player.global_position = npc.global_position
		hub.talk_to_npc(npc)
		await process_frame
		check(hub.dialogue_ui.is_open(), "gamepad_hub_dialogue_open")
		await _press_button(JOY_BUTTON_Y)
		await process_frame
		check(hub.npc_inspire_ui != null and hub.npc_inspire_ui.is_open(), "gamepad_hub_y_opens_inspiration")
		check(not hub.dialogue_ui.is_open(), "gamepad_hub_y_closes_dialogue")
		await _release_button(JOY_BUTTON_Y)
		var inspire_focus := root.gui_get_focus_owner() as Button
		check(inspire_focus != null, "gamepad_hub_inspire_focuses_service")
		var service_hits: Array[StringName] = []
		hub.npc_inspire_ui.function_requested.connect(
			func(_npc_id: StringName, function_id: StringName): service_hits.append(function_id))
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		check(service_hits.size() == 1, "gamepad_hub_inspire_a_runs_service")
		if hub.shop_ui != null and hub.shop_ui.is_open():
			hub.shop_ui.close()
		if hub.archive_ui != null and hub.archive_ui.is_open():
			hub.archive_ui.close()
		# While an AI reply is pending the submit button is disabled; focus must
		# survive the disable/re-enable instead of leaving the page dead.
		var inspire_ui = hub.npc_inspire_ui
		inspire_ui._submit.grab_focus()
		check(root.gui_get_focus_owner() == inspire_ui._submit,
			"gamepad_hub_inspire_submit_focus")
		inspire_ui.set_busy(true)
		var inspire_busy_focus := root.gui_get_focus_owner()
		check(inspire_busy_focus != null and inspire_busy_focus.is_visible_in_tree(),
			"gamepad_hub_inspire_busy_keeps_focus")
		inspire_ui.set_busy(false)
		var inspire_idle_focus := root.gui_get_focus_owner()
		check(inspire_idle_focus != null and inspire_idle_focus.is_visible_in_tree(),
			"gamepad_hub_inspire_idle_has_focus")
		await _press_button(JOY_BUTTON_B)
		await process_frame
		await _release_button(JOY_BUTTON_B)
		check(not hub.npc_inspire_ui.is_open(), "gamepad_hub_inspire_b_closes")
		var inspire_close_focus := root.gui_get_focus_owner()
		check(inspire_close_focus == null or inspire_close_focus.is_visible_in_tree(),
			"gamepad_hub_inspire_close_no_stale_focus")

	# D-pad up opens the Hub codex; focus must land on the first word so A
	# selects a word instead of doing nothing (or closing the page).
	await _press_button(JOY_BUTTON_DPAD_UP)
	await process_frame
	check(hub._tutorial_codex != null and hub._tutorial_codex.visible, "gamepad_hub_codex_opens")
	var hub_codex_focus := root.gui_get_focus_owner() as Button
	check(hub_codex_focus != null and not hub_codex_focus.disabled, "gamepad_hub_codex_focus_pressable")
	check(hub_codex_focus != null and hub_codex_focus.text == "选择", "gamepad_hub_codex_focus_first_word")
	await _release_button(JOY_BUTTON_DPAD_UP)
	await _press_button(JOY_BUTTON_A)
	await process_frame
	await _release_button(JOY_BUTTON_A)
	check(hub._tutorial_codex.visible, "gamepad_hub_codex_a_keeps_page")
	check(hub._tutorial_codex._selected_words.size() == 1, "gamepad_hub_codex_a_selects_word")
	var hub_codex_after_pick := root.gui_get_focus_owner() as Button
	check(hub_codex_after_pick != null and hub_codex_after_pick.is_visible_in_tree(),
		"gamepad_hub_codex_focus_survives_word_rebuild")
	check(hub_codex_after_pick != null and hub_codex_after_pick.text == "取消选择",
		"gamepad_hub_codex_focus_stays_on_picked_word")
	await _press_button(JOY_BUTTON_B)
	await process_frame
	await _release_button(JOY_BUTTON_B)
	check(not hub._tutorial_codex.visible, "gamepad_hub_codex_b_closes")
	# Closing must not leave focus on the hidden page: the pad has to keep
	# driving the Hub, and a return target is null or a visible control.
	var codex_b_close_focus := root.gui_get_focus_owner()
	check(codex_b_close_focus == null or codex_b_close_focus.is_visible_in_tree(),
		"gamepad_hub_codex_b_close_no_hidden_focus")
	check(not _focus_inside(hub._tutorial_codex, codex_b_close_focus),
		"gamepad_hub_codex_b_close_focus_outside_page")
	check(not paused, "gamepad_hub_codex_b_unpauses")
	check(hub.player.is_physics_processing(), "gamepad_hub_codex_b_unfreezes")

	# Start must back out of the Hub codex as well, matching every other Hub
	# modal page (settings/dialogue/shop/archive/help/inspiration).
	await _press_button(JOY_BUTTON_DPAD_UP)
	await process_frame
	await _release_button(JOY_BUTTON_DPAD_UP)
	check(hub._tutorial_codex.visible, "gamepad_hub_codex_reopens")
	await _press_button(JOY_BUTTON_START)
	# The Hub polls the pause action in _process, so hold it for one more frame
	# than the event-driven pages need.
	await process_frame
	await _release_button(JOY_BUTTON_START)
	check(not hub._tutorial_codex.visible, "gamepad_hub_codex_start_closes")
	check(not paused, "gamepad_hub_codex_start_unpauses")
	check(hub.player.is_physics_processing(), "gamepad_hub_codex_start_unfreezes")
	var codex_start_close_focus := root.gui_get_focus_owner()
	check(codex_start_close_focus == null or codex_start_close_focus.is_visible_in_tree(),
		"gamepad_hub_codex_start_close_no_hidden_focus")
	check(not _focus_inside(hub._tutorial_codex, codex_start_close_focus),
		"gamepad_hub_codex_start_close_focus_outside_page")

	# Reopen/close stability: keyboard Esc and the codex key itself must close
	# the page with the same focus/pause contract on every cycle.
	await _press_button(JOY_BUTTON_DPAD_UP)
	await _release_button(JOY_BUTTON_DPAD_UP)
	await process_frame
	check(hub._tutorial_codex.visible, "gamepad_hub_codex_reopens_for_esc")
	var esc_open_focus := root.gui_get_focus_owner()
	check(_focus_inside(hub._tutorial_codex, esc_open_focus),
		"gamepad_hub_codex_esc_open_focus_inside")
	await _press_key(KEY_ESCAPE)
	await _release_key(KEY_ESCAPE)
	await process_frame
	check(not hub._tutorial_codex.visible, "gamepad_hub_codex_esc_closes")
	check(not paused, "gamepad_hub_codex_esc_unpauses")
	check(hub.player.is_physics_processing(), "gamepad_hub_codex_esc_unfreezes")
	var esc_close_focus := root.gui_get_focus_owner()
	check(esc_close_focus == null or esc_close_focus.is_visible_in_tree(),
		"gamepad_hub_codex_esc_close_no_hidden_focus")
	check(not _focus_inside(hub._tutorial_codex, esc_close_focus),
		"gamepad_hub_codex_esc_close_focus_outside_page")

	await _press_button(JOY_BUTTON_DPAD_UP)
	await _release_button(JOY_BUTTON_DPAD_UP)
	await process_frame
	check(hub._tutorial_codex.visible, "gamepad_hub_codex_reopens_for_codex_key")
	await _press_key(KEY_C)
	await _release_key(KEY_C)
	await process_frame
	check(not hub._tutorial_codex.visible, "gamepad_hub_codex_key_closes")
	check(not paused, "gamepad_hub_codex_key_unpauses")
	check(hub.player.is_physics_processing(), "gamepad_hub_codex_key_unfreezes")
	var codex_key_close_focus := root.gui_get_focus_owner()
	check(not _focus_inside(hub._tutorial_codex, codex_key_close_focus),
		"gamepad_hub_codex_key_close_focus_outside_page")

	# If a Hub control owned focus before the codex opened, closing hands focus
	# back to it instead of leaving the page dead.
	var focus_anchor := Button.new()
	focus_anchor.name = "CodexFocusAnchor"
	focus_anchor.text = "anchor"
	focus_anchor.position = Vector2(8, 8)
	focus_anchor.size = Vector2(96, 24)
	hub.add_child(focus_anchor)
	await process_frame
	focus_anchor.grab_focus()
	check(root.gui_get_focus_owner() == focus_anchor, "gamepad_hub_codex_anchor_focused")
	await _press_button(JOY_BUTTON_DPAD_UP)
	await _release_button(JOY_BUTTON_DPAD_UP)
	await process_frame
	check(_focus_inside(hub._tutorial_codex, root.gui_get_focus_owner()),
		"gamepad_hub_codex_anchor_open_focus_inside")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	await process_frame
	check(root.gui_get_focus_owner() == focus_anchor,
		"gamepad_hub_codex_anchor_focus_restored")
	# A second cycle must not keep a stale return-focus pointer.
	await _press_button(JOY_BUTTON_DPAD_UP)
	await _release_button(JOY_BUTTON_DPAD_UP)
	await process_frame
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	await process_frame
	check(not hub._tutorial_codex.visible,
		"gamepad_hub_codex_anchor_second_close")
	check(root.gui_get_focus_owner() == focus_anchor,
		"gamepad_hub_codex_anchor_focus_restored_twice")
	hub.remove_child(focus_anchor)
	focus_anchor.free()

	# The Hub help page closes on Start as well.
	await _press_button(JOY_BUTTON_DPAD_RIGHT)
	await process_frame
	await _release_button(JOY_BUTTON_DPAD_RIGHT)
	check(hub.help_ui != null and hub.help_ui.is_open(), "gamepad_hub_help_opens")
	await _press_button(JOY_BUTTON_START)
	await process_frame
	await _release_button(JOY_BUTTON_START)
	check(not hub.help_ui.is_open(), "gamepad_hub_help_start_closes")
	check(hub.player.is_physics_processing(), "gamepad_hub_help_start_unfreezes")

	# Help closes on B as well, leaving no focus on the hidden page.
	await _press_button(JOY_BUTTON_DPAD_RIGHT)
	await process_frame
	await _release_button(JOY_BUTTON_DPAD_RIGHT)
	check(hub.help_ui.is_open(), "gamepad_hub_help_reopens")
	await _press_button(JOY_BUTTON_B)
	await process_frame
	await _release_button(JOY_BUTTON_B)
	check(not hub.help_ui.is_open(), "gamepad_hub_help_b_closes")
	check(hub.player.is_physics_processing(), "gamepad_hub_help_b_unfreezes")
	var help_close_focus := root.gui_get_focus_owner()
	check(help_close_focus == null or help_close_focus.is_visible_in_tree(),
		"gamepad_hub_help_close_no_stale_focus")

	# Hub dialogue closes on both Start and B. It restores a previous visible
	# focus owner when there is one, otherwise focus must not stay hidden.
	var hub_luchen = hub.get_npc(&"luchen")
	check(hub_luchen != null, "gamepad_hub_has_luchen")
	if hub_luchen != null:
		hub.talk_to_npc(hub_luchen)
		await process_frame
		check(hub.dialogue_ui.is_open(), "gamepad_hub_dialogue_start_case_opens")
		var dialogue_open_focus := root.gui_get_focus_owner()
		check(dialogue_open_focus != null and dialogue_open_focus.is_visible_in_tree(),
			"gamepad_hub_dialogue_open_focus_visible")
		await _press_button(JOY_BUTTON_START)
		await process_frame
		await _release_button(JOY_BUTTON_START)
		check(not hub.dialogue_ui.is_open(), "gamepad_hub_dialogue_start_closes")
		check(hub.player.is_physics_processing(), "gamepad_hub_dialogue_start_unfreezes")
		var dialogue_close_focus := root.gui_get_focus_owner()
		check(dialogue_close_focus == null or dialogue_close_focus.is_visible_in_tree(),
			"gamepad_hub_dialogue_close_no_stale_focus")
		hub.talk_to_npc(hub_luchen)
		await process_frame
		check(hub.dialogue_ui.is_open(), "gamepad_hub_dialogue_b_case_opens")
		await _press_button(JOY_BUTTON_B)
		await process_frame
		await _release_button(JOY_BUTTON_B)
		check(not hub.dialogue_ui.is_open(), "gamepad_hub_dialogue_b_closes")
		check(hub.player.is_physics_processing(), "gamepad_hub_dialogue_b_unfreezes")

	# Hub shop (opened as 咕噜's service) closes on Start and B without leaving
	# a hidden focus owner behind.
	hub.perform_npc_function(&"guru", &"shop")
	await process_frame
	check(hub.shop_ui.is_open(), "gamepad_hub_shop_start_case_opens")
	var shop_open_focus := root.gui_get_focus_owner()
	check(shop_open_focus != null and shop_open_focus.is_visible_in_tree(),
		"gamepad_hub_shop_open_focus_visible")
	await _press_button(JOY_BUTTON_START)
	await process_frame
	await _release_button(JOY_BUTTON_START)
	check(not hub.shop_ui.is_open(), "gamepad_hub_shop_start_closes")
	check(hub.player.is_physics_processing(), "gamepad_hub_shop_start_unfreezes")
	var shop_close_focus := root.gui_get_focus_owner()
	check(shop_close_focus == null or shop_close_focus.is_visible_in_tree(),
		"gamepad_hub_shop_close_no_stale_focus")
	hub.perform_npc_function(&"guru", &"shop")
	await process_frame
	check(hub.shop_ui.is_open(), "gamepad_hub_shop_b_case_opens")
	await _press_button(JOY_BUTTON_B)
	await process_frame
	await _release_button(JOY_BUTTON_B)
	check(not hub.shop_ui.is_open(), "gamepad_hub_shop_b_closes")
	check(hub.player.is_physics_processing(), "gamepad_hub_shop_b_unfreezes")

	# Hub archive (陆沉's service) closes on Start and B; both must unfreeze the
	# player and drop focus from the hidden page.
	hub.perform_npc_function(&"luchen", &"archive")
	await process_frame
	check(hub.archive_ui.is_open(), "gamepad_hub_archive_start_case_opens")
	var archive_open_focus := root.gui_get_focus_owner()
	check(archive_open_focus != null and archive_open_focus.is_visible_in_tree(),
		"gamepad_hub_archive_open_focus_visible")
	await _press_button(JOY_BUTTON_START)
	await process_frame
	await _release_button(JOY_BUTTON_START)
	check(not hub.archive_ui.is_open(), "gamepad_hub_archive_start_closes")
	check(hub.player.is_physics_processing(), "gamepad_hub_archive_start_unfreezes")
	var archive_close_focus := root.gui_get_focus_owner()
	check(archive_close_focus == null or archive_close_focus.is_visible_in_tree(),
		"gamepad_hub_archive_close_no_stale_focus")
	hub.perform_npc_function(&"luchen", &"archive")
	await process_frame
	check(hub.archive_ui.is_open(), "gamepad_hub_archive_b_case_opens")
	await _press_button(JOY_BUTTON_B)
	await process_frame
	await _release_button(JOY_BUTTON_B)
	check(not hub.archive_ui.is_open(), "gamepad_hub_archive_b_closes")
	check(hub.player.is_physics_processing(), "gamepad_hub_archive_b_unfreezes")

	# Hub inspiration closes on Start too (B is covered above).
	var hub_guru = hub.get_npc(&"guru")
	if hub_guru != null:
		hub.talk_to_npc(hub_guru)
		await process_frame
		await _press_button(JOY_BUTTON_Y)
		await process_frame
		await _release_button(JOY_BUTTON_Y)
		check(hub.npc_inspire_ui.is_open(), "gamepad_hub_inspire_start_case_opens")
		await _press_button(JOY_BUTTON_START)
		await process_frame
		await _release_button(JOY_BUTTON_START)
		check(not hub.npc_inspire_ui.is_open(), "gamepad_hub_inspire_start_closes")
		check(hub.player.is_physics_processing(), "gamepad_hub_inspire_start_unfreezes")
		var inspire_start_focus := root.gui_get_focus_owner()
		check(inspire_start_focus == null or inspire_start_focus.is_visible_in_tree(),
			"gamepad_hub_inspire_start_no_stale_focus")

	# Title → Settings must return focus to the title button when it closes.
	var title := TitleScreen.new()
	hub.add_child(title)
	await process_frame
	hub._connect_title_settings()
	var title_settings := title.find_child("SettingsButton", true, false) as Button
	check(title_settings != null, "gamepad_title_has_settings")
	if title_settings != null:
		title_settings.grab_focus()
		await process_frame
		title_settings.pressed.emit()
		await process_frame
		check(hub.settings_menu != null and hub.settings_menu.visible, "gamepad_title_settings_opens")
		check(root.gui_get_focus_owner() == hub.settings_menu.fullscreen_button, "gamepad_title_settings_focus")
		hub.settings_menu.close()
		await process_frame
		check(root.gui_get_focus_owner() == title_settings, "gamepad_title_focus_returns_after_settings")

	# "New game" swaps Flow.profile; the Hub must rebind before the old instance
	# is freed, including its shop page, word copies and tutorial codex.
	var old_profile_id: int = hub.profile.get_instance_id()
	flow.reset_profile()
	hub._on_new_game_requested()
	await process_frame
	check(hub.profile == flow.profile, "gamepad_hub_rebinds_profile_after_new_game")
	check(is_instance_valid(hub.profile), "gamepad_hub_profile_stays_valid")
	check(hub.shop_ui._profile == flow.profile, "gamepad_hub_shop_rebinds_profile")
	check(hub._tutorial_run != null, "gamepad_hub_tutorial_run_rebuilt")
	check(hub._tutorial_codex._run == hub._tutorial_run, "gamepad_hub_tutorial_codex_rebinds")
	check(hub.profile.get_instance_id() != old_profile_id, "gamepad_hub_profile_replaced")
	title.queue_free()
	paused = false
	await process_frame
	hub.queue_free()
	await process_frame
	await process_frame
	_cleanup_files()
	print("GAMEPAD INTEGRATION: %d checks, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
