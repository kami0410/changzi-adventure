extends SceneTree

## Chapter 1 event wiring: "读禁文" must decode one owned fragment (the demo
## starts with all twelve owned but locked), persist it to the Profile, flip the
## run's copy and pay corruption instead of silently falling back to pages.

var failures: int = 0
var assertions: int = 0

const PROFILE_PATH := "user://test_ch1_event_profile.cfg"
const RUN_PATH := "user://test_ch1_event_run.cfg"


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("CH1 EVENT FAIL: " + label)


func _cleanup_files() -> void:
	RunSave.clear(RUN_PATH)
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = PROFILE_PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _initialize() -> void:
	_run.call_deferred()


func _wait_mds(scene, timeout := 8.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._mds_world != null and not scene._mds_world.changing_room and not scene._mds_world.current_room.is_empty():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _wait_story(scene, timeout := 3.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._story != null and scene._story.is_open():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _settle() -> void:
	await process_frame
	await process_frame


func _press_key(keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await _settle()


func _release_key(keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = false
	Input.parse_input_event(event)
	await _settle()


func _press_button(button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await _settle()


func _release_button(button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = false
	Input.parse_input_event(event)
	await _settle()


func _hold_key(keycode: int, seconds: float) -> void:
	await _press_key(keycode)
	await create_timer(seconds).timeout
	await _release_key(keycode)


func _focus_owner() -> Control:
	return root.gui_get_focus_owner()


func _focus_is_reasonable() -> bool:
	var owner := _focus_owner()
	return owner == null or (owner.is_visible_in_tree() and not owner.is_queued_for_deletion())


func _ui_word_meaning(grid, glyph: String) -> String:
	if grid == null:
		return "<no-grid>"
	for card in grid.get_children():
		if not card is PanelContainer:
			continue
		var labels: Array[Node] = card.find_children("*", "Label", true, false)
		if labels.size() >= 2 and (labels[0] as Label).text == glyph:
			return (labels[1] as Label).text
	return "<missing>"


func _run() -> void:
	var flow := root.get_node("Flow") as GameFlow
	_cleanup_files()
	flow.auto_save = true
	flow.profile_path = PROFILE_PATH
	flow.run_save_path = RUN_PATH
	flow.title_shown_this_session = true
	flow.resume_requested = false
	# Profile extends Node, so tests that replace the loaded profile must free
	# their own instance instead of leaving it to the refcount.
	var fresh_profile := Profile.new()
	flow.profile = fresh_profile

	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.4).timeout
	if scene._story.is_open():
		scene._story.close()
	check(await _wait_mds(scene), "event_test_boots")
	# A fixed non-zero seed makes the variant deterministic and exercises the
	# seed round-trip instead of relying on a random run seed.
	scene.run_state.run_seed = 20261104
	scene.run_state.rng.seed = scene.run_state.run_seed
	# Leaving the event room before its 0.8 s page timer fires must cancel the
	# page. Opening it during the next room's fade used to pause the transition
	# behind the black fade (the story layer sits under it), stalling the room.
	await scene._mds_world.load_room("ch1_05")
	await create_timer(0.15).timeout
	await scene._mds_world.load_room("ch1_04")
	await create_timer(1.2).timeout
	check(scene._mds_world.current_room == "ch1_04", "event_leave_keeps_next_room")
	check(not scene._mds_world.changing_room, "event_leave_transition_finishes")
	check(not scene._story.is_open(), "event_leave_cancels_page")
	check(not paused, "event_leave_does_not_pause")
	check(not scene._cleared_encounters.has("ch1_05/event"), "event_leave_does_not_clear_room")
	# Re-entering still schedules the page because the room is uncleared.
	if not scene._mds_world.current_room.is_empty():
		await scene._mds_world.load_room("ch1_05")
	check(await _wait_story(scene), "event_opens")
	# The choice page is a required modal: it pauses the world, focuses the
	# first option, and B/Esc/Start must not skip or stack a pause menu.
	await _settle()
	check(paused, "event_choice_pauses")
	var choice_focus := _focus_owner()
	check(choice_focus is Button and choice_focus.is_visible_in_tree(),
		"event_choice_focus_visible")
	check(choice_focus == scene._story._options.get_child(0), "event_choice_focus_first")
	var frozen_x: float = scene.player.global_position.x
	await _hold_key(KEY_D, 0.2)
	check(is_equal_approx(scene.player.global_position.x, frozen_x),
		"event_choice_player_frozen")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(scene._story.is_open(), "event_choice_b_ignored")
	check(paused and not scene.pause_menu.is_open(), "event_choice_b_keeps_pause")
	await _press_key(KEY_ESCAPE)
	await _release_key(KEY_ESCAPE)
	check(scene._story.is_open(), "event_choice_esc_ignored")
	check(paused and not scene.pause_menu.is_open(), "event_choice_esc_no_pause_menu")
	await _press_button(JOY_BUTTON_START)
	await _release_button(JOY_BUTTON_START)
	check(scene._story.is_open(), "event_choice_start_ignored")
	check(not scene.pause_menu.is_open(), "event_choice_start_no_pause_menu")
	await _press_button(JOY_BUTTON_DPAD_DOWN)
	await _release_button(JOY_BUTTON_DPAD_DOWN)
	check(_focus_owner() == scene._story._options.get_child(1),
		"event_choice_dpad_moves_focus")
	await _press_button(JOY_BUTTON_DPAD_UP)
	await _release_button(JOY_BUTTON_DPAD_UP)
	check(_focus_owner() == scene._story._options.get_child(0),
		"event_choice_dpad_up_moves_focus")
	var expected_event := Ch1EventData.pick(scene.run_state.run_seed, "ch1_05")
	check(not expected_event.is_empty(), "event_variant_resolves")
	check(scene._story._eyebrow.text == String(expected_event.get("eyebrow", "")),
		"event_variant_eyebrow")
	check(scene._story._title.text == String(expected_event.get("title", "")),
		"event_variant_title")
	check(scene._story._options.get_child_count() == 2, "event_variant_has_two_choices")
	if scene._story._options.get_child_count() == 2:
		var read_button := scene._story._options.get_child(0) as Button
		var take_button := scene._story._options.get_child(1) as Button
		check(read_button.text.begins_with(String(expected_event.get("read_label", ""))),
			"event_variant_read_label")
		check(take_button.text.begins_with(String(expected_event.get("take_label", ""))),
			"event_variant_take_label")
	check(flow.profile.decoded_words.size() == 6, "event_starts_with_six_decoded")
	check(scene.run_state.inventory.words.size() == 18, "event_run_owns_eighteen_fragments")

	# Saving inside the event room and resuming must re-open the same page:
	# the variant is picked from run_seed, which the checkpoint round-trips.
	var original_seed: int = scene.run_state.run_seed
	check(scene.save_run_now(), "event_resume_checkpoint")
	scene._story.close()
	scene.queue_free()
	await process_frame
	await process_frame

	flow.resume_requested = true
	var resumed = load("res://scenes/main.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	await create_timer(0.4).timeout
	check(await _wait_mds(resumed), "event_resume_loads")
	check(resumed.run_state.run_seed == original_seed, "event_resume_keeps_seed")
	check(resumed._mds_world.current_room == "ch1_05", "event_resume_keeps_room")
	check(await _wait_story(resumed), "event_resume_reopens_event")
	var resumed_event := Ch1EventData.pick(resumed.run_state.run_seed, "ch1_05")
	check(String(resumed_event.get("eyebrow", "")) == String(expected_event.get("eyebrow", "")),
		"event_resume_variant_eyebrow")
	check(String(resumed_event.get("title", "")) == String(expected_event.get("title", "")),
		"event_resume_variant_title")
	check(String(resumed_event.get("read_label", "")) == String(expected_event.get("read_label", "")),
		"event_resume_variant_read_label")
	check(String(resumed_event.get("take_label", "")) == String(expected_event.get("take_label", "")),
		"event_resume_variant_take_label")
	scene = resumed
	check(flow.profile.decoded_words.size() == 6, "event_resume_profile_untouched")
	check(scene.run_state.inventory.words.size() == 18, "event_resume_keeps_fragments")

	var decoded_before := flow.profile.decoded_words.duplicate()
	var pages_before: int = scene.run_state.pages
	var corruption_before: int = scene.run_state.corruption
	var multiplier: float = scene.run_state.corruption_gain_multiplier
	# Confirm the resumed page with a real joypad A: the pick closes the page,
	# releases the pause, leaves focus off hidden controls, and hands control
	# back to the player.
	check(_focus_owner() == scene._story._options.get_child(0),
		"event_resume_focus_first")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	await create_timer(0.5).timeout
	check(not scene._story.is_open(), "event_choice_a_picks")
	check(not paused, "event_choice_a_unpauses")
	check(not scene.pause_menu.is_open(), "event_choice_a_no_pause_menu")
	check(_focus_is_reasonable(), "event_choice_a_focus_not_hidden")
	var freed_x: float = scene.player.global_position.x
	await _hold_key(KEY_D, 0.35)
	check(scene.player.global_position.x > freed_x + 1.0, "event_choice_a_player_moves")
	var picked_save := RunSave.read(RUN_PATH)
	check(not picked_save.is_empty(), "event_choice_a_saves")
	var picked_cleared: Array = picked_save.get("progress", {}).get("cleared_encounters", [])
	check(picked_cleared.has("ch1_05/event"), "event_choice_a_save_marks_cleared")

	check(flow.profile.decoded_words.size() == decoded_before.size() + 1, "event_decodes_one_word")
	var decoded_id: StringName = &""
	for word_id in flow.profile.decoded_words:
		if not decoded_before.has(word_id):
			decoded_id = word_id
	check(decoded_id != &"", "event_reports_new_word_id")
	var persisted := Profile.new()
	check(persisted.load_profile(PROFILE_PATH), "event_profile_saved")
	check(persisted.is_word_decoded(decoded_id), "event_decode_persisted_across_quit")
	persisted.free()
	var run_copy_decoded := false
	var decoded_word: WordData = null
	for word in scene.run_state.inventory.words:
		if word != null and word.id == decoded_id:
			run_copy_decoded = word.decoded
			decoded_word = word
	check(run_copy_decoded, "event_unlocks_run_copy")
	check(decoded_word != null, "event_has_decoded_word")
	if decoded_word != null:
		# The Codex and Inventory grids were built before the event choice.
		# Decoding in place must refresh them instead of leaving the old
		# "未解码" card on screen when the player opens either page.
		check(_ui_word_meaning(scene.codex_ui._word_grid, decoded_word.glyph) == decoded_word.meaning,
			"event_codex_word_refreshes_after_decode")
		check(_ui_word_meaning(scene.inventory_ui._word_grid, decoded_word.glyph) == decoded_word.meaning,
			"event_inventory_word_refreshes_after_decode")
	check(scene.run_state.pages == pages_before, "event_does_not_pay_pages_when_word_available")
	var expected_corruption := mini(
		corruption_before + maxi(int(ceilf(8.0 * multiplier)), 1), 100)
	check(scene.run_state.corruption == expected_corruption, "event_pays_eight_corruption")
	check(scene._cleared_encounters.has("ch1_05/event"), "event_marks_room_cleared")

	# Falling back to pages happens only when every fragment is readable.
	var remaining := RunLoot.owned_undecoded_words(scene.run_state, flow.profile, 0)
	for word in remaining:
		RunLoot.decode_owned_word(scene.run_state, flow.profile, word)
	var pages_before_fallback: int = scene.run_state.pages
	check(scene._grant_event_word(Ch1EventData.FALLBACK_PAGES) == "",
		"event_fallback_reports_no_word")
	check(scene.run_state.pages == pages_before_fallback + 6, "event_fallback_pays_pages")

	# Pass 86: opening the map inside the 0.8 s event window must not stack the
	# required choice on top of it. The page waits behind the map; closing the
	# map lets it open normally instead of unpausing the run underneath it.
	scene._cleared_encounters.erase("ch1_05/event")
	scene._cleared_in_chapter = maxi(scene._cleared_in_chapter - 1, 0)
	scene._event_room_id = ""
	await scene._mds_world.load_room("ch1_05")
	await _wait_mds(scene)
	await _press_key(KEY_M)
	await _release_key(KEY_M)
	check(scene._map_overlay.is_open(), "event_map_opens_in_window")
	check(paused, "event_map_pauses")
	await create_timer(1.2).timeout
	check(not scene._story.is_open(), "event_page_waits_for_map")
	check(scene._map_overlay.is_open(), "event_map_stays_open")
	check(paused, "event_map_keeps_pause")
	await _press_key(KEY_ESCAPE)
	await _release_key(KEY_ESCAPE)
	check(not scene._map_overlay.is_open(), "event_map_closes")
	check(await _wait_story(scene), "event_page_opens_after_map")
	check(paused and not scene._map_overlay.is_open(), "event_page_pauses_alone")
	await _press_button(JOY_BUTTON_DPAD_DOWN)
	await _release_button(JOY_BUTTON_DPAD_DOWN)
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	await create_timer(0.5).timeout
	check(not scene._story.is_open(), "event_page_choice_resolves")
	check(not paused, "event_page_choice_unpauses")
	check(not scene.pause_menu.is_open(), "event_page_choice_no_pause_menu")

	# Pass 86: stepping through the door inside the 0.8 s beat is the third way
	# out. `current_room` only flips after the fade-out, so the page must read
	# the transition itself; otherwise it opens under the MDS fade (layer 100,
	# above the story layer), pauses the world and freezes on a black screen.
	scene._cleared_encounters.erase("ch1_05/event")
	scene._cleared_in_chapter = maxi(scene._cleared_in_chapter - 1, 0)
	scene._event_room_id = ""
	await scene._mds_world.load_room("ch1_05")
	await _wait_mds(scene)
	# `load_room` returns after the fade-in (0.175 s); 0.5 s more puts the page
	# timer (0.8 s after room_loaded) in the middle of the fade-out.
	await create_timer(0.5).timeout
	scene._mds_world.load_room("ch1_04")
	await create_timer(0.6).timeout
	check(not scene._story.is_open(), "event_page_cancelled_by_fade")
	check(not paused, "event_fade_leave_does_not_pause")
	check(await _wait_mds(scene) and scene._mds_world.current_room == "ch1_04",
		"event_fade_leave_finishes")

	scene.queue_free()
	await process_frame
	await process_frame
	flow.profile = null
	fresh_profile.free()
	_cleanup_files()
	await process_frame
	current_scene = null
	print("CH1 EVENT INTEGRATION: %d checks, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
