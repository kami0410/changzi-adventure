extends SceneTree

## Real checkpoint round-trip: enter a room, change stats/items, quit, launch a
## new Main with resume_requested, and continue in the same room with the same
## state. Also covers corrupt files and cleanup on death.

var failures: int = 0
var assertions: int = 0

const RUN_PATH := "user://test_run_save_integration.cfg"
const PROFILE_PATH := "user://test_run_save_profile.cfg"


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("RUN SAVE FAIL: " + label)


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


func _close_story(scene) -> void:
	if scene._story != null and scene._story.is_open():
		scene._story.close()


func _wait_room(scene, room_id: String, timeout := 4.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if not scene._mds_world.changing_room and scene._mds_world.current_room == room_id:
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _cleanup_files() -> void:
	RunSave.clear(RUN_PATH)
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = PROFILE_PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _free_scene(scene) -> void:
	# A real quit ends the process; in-process resumes must not inherit the
	# paused state of the page that was open when the save was written.
	paused = false
	scene.queue_free()
	await process_frame
	await process_frame


func _press_button(button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame


func _release_button(button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	await process_frame


func _wait_vulnerable(scene, timeout := 3.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if not scene.player.is_invulnerable():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _run() -> void:
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = true
	flow.profile_path = PROFILE_PATH
	flow.run_save_path = RUN_PATH
	flow.title_shown_this_session = true
	flow.resume_requested = false
	_cleanup_files()

	# --- First launch: play into ch1_03, then checkpoint. ---
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.4).timeout
	_close_story(scene)
	check(await _wait_mds(scene), "run_save_first_room_loads")
	check(scene._mds_world.current_room == "ch1_01", "run_save_first_room_id")
	check(FileAccess.file_exists(RUN_PATH), "run_save_written_on_room_entry")

	# A pending reward must not be checkpointed as already taken: the room is
	# marked cleared before the choice, so writing now loses the reward.
	var test_rewards: Array[Dictionary] = [
		{"kind": &"rest", "title": "测试奖励", "description": "仅用于存档边界测试。"},
	]
	scene._reward_ui.open_choices(test_rewards)
	check(scene._reward_ui.visible, "run_save_reward_opens")
	check(not scene.save_run_now(), "run_save_waits_for_pending_reward")
	scene._reward_ui.hide()
	check(scene.save_run_now(), "run_save_resumes_after_reward")

	# Quitting during a run must persist Profile progress (mastery/decodes),
	# not only the run checkpoint.
	var mastery_before := flow.profile.word_mastery_xp(&"xue")
	flow.profile.add_word_mastery(&"xue", 7)
	scene.save_run_on_exit()
	var saved_profile := Profile.new()
	check(saved_profile.load_profile(PROFILE_PATH), "run_exit_saves_profile")
	var mastery_after := saved_profile.word_mastery_xp(&"xue")
	check(mastery_after == mastery_before + 7, "run_exit_profile_keeps_mastery")
	saved_profile.free()

	await scene._mds_world.load_room("ch1_03")
	await create_timer(0.3).timeout
	_close_story(scene)
	check(scene._mds_world.current_room == "ch1_03", "run_save_moved_to_ch1_03")

	var word := ContentLibrary.word_by_id(&"xue")
	check(word != null, "run_save_word_exists")
	if word != null:
		scene._acquire_word(word)
	var relic := ContentLibrary.relic_by_id(&"time_shard")
	check(relic != null, "run_save_relic_exists")
	if relic != null:
		scene.run_state.inventory.add_relic(relic)
	scene._cleared_encounters["ch1_01/Arena"] = true
	if not scene._chests.is_empty():
		scene._open_chest(scene._chests[0])
	check(scene._opened_chests.has("ch1_03/Chest"), "run_save_chest_marked")
	scene.player.max_health = 135
	scene.player.health = 84
	scene.run_state.pages = 27
	scene.run_state.set_corruption(41)
	# Stand on known ground: some Chapter 1 rooms have pits at fixed x values.
	var safe: Vector2 = scene._last_checkpoint
	scene.player.global_position = safe + Vector2(40, 0)
	scene.player.velocity = Vector2.ZERO
	await create_timer(0.3).timeout
	var saved_position: Vector2 = scene.player.global_position
	check(scene.save_run_now(), "run_save_explicit_write")
	var saved := RunSave.read(RUN_PATH)
	check(String(saved.get("run", {}).get("room", "")) == "ch1_03", "run_save_file_has_room")

	await _free_scene(scene)

	# --- Second launch: the title asked to continue. ---
	flow.resume_requested = true
	var resumed = load("res://scenes/main.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	await create_timer(0.4).timeout
	_close_story(resumed)
	check(await _wait_mds(resumed), "run_save_resume_loads")
	check(resumed._mds_world.current_room == "ch1_03", "run_save_resume_room")
	check(resumed.player.max_health == 135, "run_save_resume_max_health")
	check(resumed.player.health == 84, "run_save_resume_health")
	check(resumed.run_state.pages == 27, "run_save_resume_pages")
	check(resumed.run_state.corruption == 41, "run_save_resume_corruption")
	check(resumed.run_state.inventory.has_word(&"xue"), "run_save_resume_words")
	check(resumed.run_state.inventory.has_relic(&"time_shard"), "run_save_resume_relics")
	check(resumed._cleared_encounters.has("ch1_01/Arena"), "run_save_resume_cleared_rooms")
	# Falling continues where the checkpoint left off; horizontal placement is
	# exact and the vertical drift is only gravity settling.
	var restored_position: Vector2 = resumed.player.global_position
	check(absf(restored_position.x - saved_position.x) < 8.0, "run_save_resume_x")
	check(absf(restored_position.y - saved_position.y) < 40.0, "run_save_resume_position")
	check(not resumed._story.is_open(), "run_save_resume_skips_intro")
	var chest_open := false
	for chest in resumed._chests:
		if chest.is_open:
			chest_open = true
	check(chest_open, "run_save_resume_chest_stays_open")

	# --- Longer play: three more rooms and a much fuller inventory. ---
	for room_id in ["ch1_04", "ch1_06", "ch1_rest"]:
		await resumed._mds_world.load_room(room_id)
		await create_timer(0.3).timeout
		_close_story(resumed)
		check(resumed._mds_world.current_room == room_id, "run_save_long_room_" + room_id)
	resumed.player.max_health = 160
	resumed.player.health = 66
	resumed.run_state.max_ink = 120
	resumed.run_state.ink = 44
	resumed.run_state.pages = 58
	resumed.run_state.set_corruption(63)
	var long_word := ContentLibrary.word_by_id(&"dongjie")
	check(long_word != null, "run_save_long_word_exists")
	if long_word != null:
		resumed._acquire_word(long_word)
	var long_relic := ContentLibrary.relic_by_id(&"blood_quill")
	check(long_relic != null, "run_save_long_relic_exists")
	if long_relic != null:
		resumed.run_state.inventory.add_relic(long_relic)
	var long_weapon := ContentLibrary.weapon_by_id(&"ink_axe")
	check(long_weapon != null, "run_save_long_weapon_exists")
	if long_weapon != null:
		resumed._acquire_weapon(long_weapon)
	resumed._cleared_encounters["ch1_04/Arena"] = true
	resumed._cleared_encounters["ch1_06/Arena"] = true
	var saved_phrase := ""
	if not resumed.run_state.inventory.phrases.is_empty():
		saved_phrase = resumed.run_state.inventory.phrases[0].signature
	resumed.player.global_position = resumed._last_checkpoint + Vector2(30, 0)
	resumed.player.velocity = Vector2.ZERO
	await create_timer(0.2).timeout
	# Repeated pause → settings → back-to-pause cycles must leave the pending
	# checkpoint untouched. Closing Settings returns to the pause menu; closing
	# that menu resumes the game between cycles.
	for cycle in 3:
		resumed.pause_menu.open_pause()
		check(paused, "run_save_pause_cycle_%d_paused" % cycle)
		resumed._on_pause_settings()
		check(resumed.settings_menu.visible, "run_save_pause_cycle_%d_settings" % cycle)
		check(not resumed.pause_menu.is_open(), "run_save_pause_cycle_%d_pause_hidden" % cycle)
		resumed.settings_menu.close()
		await process_frame
		check(paused, "run_save_pause_cycle_%d_back_to_pause" % cycle)
		check(resumed.pause_menu.is_open(), "run_save_pause_cycle_%d_pause_back" % cycle)
		resumed.pause_menu.toggle()
		await process_frame
		check(not paused, "run_save_pause_cycle_%d_resumed" % cycle)
	check(resumed.player.health == 66 and resumed.run_state.pages == 58
		and resumed._mds_world.current_room == "ch1_rest",
		"run_save_pause_cycles_keep_state")
	var long_position: Vector2 = resumed.player.global_position
	check(resumed.save_run_now(), "run_save_long_write")
	# The atomic writer keeps the previous checkpoint in .bak; write the same
	# long-run state twice so the backup matches what a loss of the main file
	# must restore.
	check(resumed.save_run_now(), "run_save_long_write_again")
	check(FileAccess.file_exists(RUN_PATH + ".bak"), "run_save_long_backup_exists")
	await _free_scene(resumed)

	# --- Normal resume from the main checkpoint after the pause → settings →
	# pause → resume round trip: every long-run value must match. ---
	flow.resume_requested = true
	var after_cycles = load("res://scenes/main.tscn").instantiate()
	root.add_child(after_cycles)
	current_scene = after_cycles
	await create_timer(0.4).timeout
	_close_story(after_cycles)
	check(await _wait_mds(after_cycles), "run_save_round_trip_boots")
	check(after_cycles._mds_world.current_room == "ch1_rest", "run_save_round_trip_room")
	check(after_cycles.player.max_health == 160, "run_save_round_trip_max_health")
	check(after_cycles.player.health == 66, "run_save_round_trip_health")
	check(after_cycles.run_state.max_ink == 120, "run_save_round_trip_max_ink")
	check(after_cycles.run_state.ink == 44, "run_save_round_trip_ink")
	check(after_cycles.run_state.pages == 58, "run_save_round_trip_pages")
	check(after_cycles.run_state.corruption == 63, "run_save_round_trip_corruption")
	check(after_cycles.run_state.inventory.has_word(&"xue")
		and after_cycles.run_state.inventory.has_word(&"dongjie"),
		"run_save_round_trip_words")
	check(after_cycles.run_state.inventory.has_relic(&"time_shard")
		and after_cycles.run_state.inventory.has_relic(&"blood_quill"),
		"run_save_round_trip_relics")
	var round_trip_weapon := false
	for weapon in after_cycles.run_state.inventory.weapons:
		if weapon != null and weapon.id == &"ink_axe":
			round_trip_weapon = true
	check(round_trip_weapon, "run_save_round_trip_weapon")
	check(not after_cycles.run_state.inventory.phrases.is_empty()
		and after_cycles.run_state.inventory.phrases[0].signature == saved_phrase,
		"run_save_round_trip_phrase")
	check(after_cycles._cleared_encounters.has("ch1_01/Arena")
		and after_cycles._cleared_encounters.has("ch1_04/Arena")
		and after_cycles._cleared_encounters.has("ch1_06/Arena"),
		"run_save_round_trip_cleared_rooms")
	check(absf(after_cycles.player.global_position.x - long_position.x) < 8.0,
		"run_save_round_trip_position_x")
	check(absf(after_cycles.player.global_position.y - long_position.y) < 40.0,
		"run_save_round_trip_position_y")

	# Quitting while the pause menu is open resumes from the save taken by the
	# pause action; the pause page itself must not come back.
	after_cycles._toggle_pause()
	check(paused, "run_save_pause_save_paused")
	check(after_cycles.pause_menu.is_open(), "run_save_pause_save_menu")
	var paused_position: Vector2 = after_cycles.player.global_position
	await _free_scene(after_cycles)
	# A real relaunch starts with an unpaused tree even though the save was
	# written while paused.
	paused = false
	flow.resume_requested = true
	var from_pause = load("res://scenes/main.tscn").instantiate()
	root.add_child(from_pause)
	current_scene = from_pause
	await create_timer(0.4).timeout
	_close_story(from_pause)
	check(await _wait_mds(from_pause), "run_save_pause_resume_boots")
	check(from_pause._mds_world.current_room == "ch1_rest", "run_save_pause_resume_room")
	check(from_pause.player.health == 66 and from_pause.run_state.pages == 58,
		"run_save_pause_resume_stats")
	check(not paused, "run_save_pause_resume_unpaused")
	check(not from_pause.pause_menu.is_open(), "run_save_pause_resume_no_pause_menu")
	check(absf(from_pause.player.global_position.x - paused_position.x) < 8.0,
		"run_save_pause_resume_position_x")
	check(absf(from_pause.player.global_position.y - paused_position.y) < 40.0,
		"run_save_pause_resume_position_y")
	await _free_scene(from_pause)

	# --- Main checkpoint missing, backup present: resume from the backup and
	# promote it back to the main file. ---
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN_PATH)) == OK,
		"run_save_backup_main_removed")
	check(not FileAccess.file_exists(RUN_PATH), "run_save_backup_main_gone")
	flow.resume_requested = true
	var from_backup = load("res://scenes/main.tscn").instantiate()
	root.add_child(from_backup)
	current_scene = from_backup
	await create_timer(0.4).timeout
	_close_story(from_backup)
	check(await _wait_mds(from_backup), "run_save_backup_still_boots")
	check(from_backup._mds_world.current_room == "ch1_rest", "run_save_backup_resume_room")
	check(from_backup.player.max_health == 160, "run_save_backup_resume_max_health")
	check(from_backup.player.health == 66, "run_save_backup_resume_health")
	check(from_backup.run_state.max_ink == 120, "run_save_backup_resume_max_ink")
	check(from_backup.run_state.ink == 44, "run_save_backup_resume_ink")
	check(from_backup.run_state.pages == 58, "run_save_backup_resume_pages")
	check(from_backup.run_state.corruption == 63, "run_save_backup_resume_corruption")
	check(from_backup.run_state.inventory.has_word(&"dongjie"), "run_save_backup_resume_long_word")
	check(from_backup.run_state.inventory.has_relic(&"blood_quill"), "run_save_backup_resume_long_relic")
	var restored_weapon := false
	for weapon in from_backup.run_state.inventory.weapons:
		if weapon != null and weapon.id == &"ink_axe":
			restored_weapon = true
	check(restored_weapon, "run_save_backup_resume_long_weapon")
	check(from_backup._cleared_encounters.has("ch1_04/Arena"), "run_save_backup_resume_cleared_ch1_04")
	check(from_backup._cleared_encounters.has("ch1_06/Arena"), "run_save_backup_resume_cleared_ch1_06")
	check(not from_backup.run_state.inventory.phrases.is_empty()
		and from_backup.run_state.inventory.phrases[0].signature == saved_phrase,
		"run_save_backup_resume_phrase")
	check(absf(from_backup.player.global_position.x - long_position.x) < 8.0,
		"run_save_backup_resume_position")
	check(FileAccess.file_exists(RUN_PATH), "run_save_backup_promoted_main")
	check(not RunSave.read(RUN_PATH).is_empty(), "run_save_backup_promoted_readable")

	# --- Main checkpoint corrupt, backup present: same recovery path, without
	# telling the player the run was discarded. ---
	await _free_scene(from_backup)
	var file := FileAccess.open(RUN_PATH, FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	check(FileAccess.file_exists(RUN_PATH + ".bak"), "run_save_corrupt_backup_exists")
	flow.resume_requested = true
	var from_corrupt_backup = load("res://scenes/main.tscn").instantiate()
	root.add_child(from_corrupt_backup)
	current_scene = from_corrupt_backup
	await create_timer(0.4).timeout
	# Check before closing the intro: the chapter objective toast replaces it.
	check(not from_corrupt_backup.hud.get_message_text().contains("损坏"),
		"run_save_corrupt_backup_no_discard_message")
	_close_story(from_corrupt_backup)
	check(await _wait_mds(from_corrupt_backup), "run_save_corrupt_backup_still_boots")
	check(from_corrupt_backup._mds_world.current_room == "ch1_rest",
		"run_save_corrupt_backup_resume_room")
	check(from_corrupt_backup.player.max_health == 160, "run_save_corrupt_backup_max_health")
	check(from_corrupt_backup.run_state.inventory.has_word(&"dongjie"),
		"run_save_corrupt_backup_word")
	check(not RunSave.read(RUN_PATH).is_empty(), "run_save_corrupt_backup_promoted")

	# --- Second-generation resume after backup recovery: spend pages at the
	# rest-room stall, checkpoint, quit and resume again. The sold row and the
	# remaining pages must come back from the save, not be re-rolled or re-sold.
	check(not from_corrupt_backup._shops.is_empty(), "run_save_shop_stall_present")
	var shop_id := &""
	var shop_offer_cost := 0
	var shop_pages_saved := 0
	if not from_corrupt_backup._shops.is_empty():
		var stall: MemoryShop = from_corrupt_backup._shops[0]
		shop_id = stall.shop_id
		from_corrupt_backup._open_shop(stall)
		var offers: Array = from_corrupt_backup._shop_cache.get(shop_id, [])
		check(not offers.is_empty(), "run_save_shop_has_offers")
		if not offers.is_empty():
			shop_offer_cost = int(offers[0].get("cost", 0))
			from_corrupt_backup.run_state.add_pages(shop_offer_cost + 20)
			var pages_before: int = from_corrupt_backup.run_state.pages
			from_corrupt_backup._on_shop_buy(0)
			check(from_corrupt_backup.run_state.pages == pages_before - shop_offer_cost,
				"run_save_shop_buy_spends_pages")
			check(bool(from_corrupt_backup._shop_cache[shop_id][0].get("bought", false)),
				"run_save_shop_buy_cached")
		from_corrupt_backup._shop_ui.close_shop()
		await process_frame
		shop_pages_saved = from_corrupt_backup.run_state.pages
	check(from_corrupt_backup.save_run_now(), "run_save_shop_write")
	await _free_scene(from_corrupt_backup)

	flow.resume_requested = true
	var second_gen = load("res://scenes/main.tscn").instantiate()
	root.add_child(second_gen)
	current_scene = second_gen
	await create_timer(0.4).timeout
	_close_story(second_gen)
	check(await _wait_mds(second_gen), "run_save_second_resume_boots")
	check(second_gen._mds_world.current_room == "ch1_rest", "run_save_second_resume_room")
	check(second_gen.run_state.pages == shop_pages_saved, "run_save_second_resume_pages")
	check(second_gen._shop_cache.has(shop_id), "run_save_second_resume_shop_cache")
	var resumed_stall: MemoryShop = null
	for candidate in second_gen._shops:
		if candidate.shop_id == shop_id:
			resumed_stall = candidate
	check(resumed_stall != null, "run_save_second_resume_stall")
	if second_gen._shop_cache.has(shop_id) and resumed_stall != null:
		var cached: Array = second_gen._shop_cache[shop_id]
		check(not cached.is_empty() and bool(cached[0].get("bought", false)),
			"run_save_second_resume_sold_row")
		second_gen._open_shop(resumed_stall)
		check(second_gen._shop_ui._buttons[0].disabled,
			"run_save_second_resume_sold_button_disabled")
		var pages_before_rebuy: int = second_gen.run_state.pages
		second_gen._on_shop_buy(0)
		check(second_gen.run_state.pages == pages_before_rebuy,
			"run_save_second_resume_no_double_spend")
		second_gen._shop_ui.close_shop()
		await process_frame

	# --- Death clears the checkpoint, including any backup. ---
	second_gen._finish(false)
	await create_timer(1.0).timeout
	check(not FileAccess.file_exists(RUN_PATH), "run_save_cleared_on_death")
	check(not FileAccess.file_exists(RUN_PATH + ".bak"), "run_save_cleared_backup_on_death")
	await _free_scene(second_gen)

	# --- Corrupt checkpoint with no backup is discarded and a fresh run starts
	# with an explicit message. ---
	var file2 := FileAccess.open(RUN_PATH, FileAccess.WRITE)
	file2.store_string("broken")
	file2.close()
	flow.resume_requested = true
	var fresh = load("res://scenes/main.tscn").instantiate()
	root.add_child(fresh)
	current_scene = fresh
	await create_timer(0.4).timeout
	# The discard notice is shown before the intro is dismissed; closing the
	# intro immediately replaces it with the chapter objective toast.
	check(fresh.hud.get_message_text().contains("局内存档损坏"),
		"run_save_corrupt_player_message")
	_close_story(fresh)
	check(await _wait_mds(fresh), "run_save_corrupt_still_boots")
	check(fresh._mds_world.current_room == "ch1_01", "run_save_corrupt_starts_new_run")
	# Entering the first room immediately writes a fresh valid checkpoint over
	# the discarded file; it must no longer be the garbage payload.
	var rewritten := RunSave.read(RUN_PATH)
	check(not rewritten.is_empty(), "run_save_corrupt_replaced_by_valid")
	check(String(rewritten.get("run", {}).get("room", "")) == "ch1_01", "run_save_corrupt_new_room")
	await _free_scene(fresh)

	# --- A parseable save with corrupt sub-containers is rejected, not applied
	# halfway through scene setup. ---
	_cleanup_files()
	RunSave.write({
		"version": RunSave.SAVE_VERSION,
		"run": {"room": "ch1_03", "health": []},
		"inventory": {"words": [], "weapons": [], "relics": [], "phrases": []},
		"progress": "garbage",
		"world": 5,
	}, RUN_PATH)
	flow.resume_requested = true
	var malformed = load("res://scenes/main.tscn").instantiate()
	root.add_child(malformed)
	current_scene = malformed
	await create_timer(0.4).timeout
	check(malformed.hud.get_message_text().contains("局内存档损坏"),
		"run_save_malformed_player_message")
	_close_story(malformed)
	check(await _wait_mds(malformed), "run_save_malformed_still_boots")
	check(malformed._mds_world.current_room == "ch1_01", "run_save_malformed_starts_new_run")
	check(malformed._resume_data.is_empty(), "run_save_malformed_not_applied")
	await _free_scene(malformed)

	# --- Boundary checkpoint: resume directly into the live boss room. The
	# boss is not saved, so a fresh one must spawn and the run must stay valid.
	var base_save := RunSave.read(RUN_PATH)
	check(not base_save.is_empty(), "run_save_boss_base_save")
	var boss_save: Dictionary = base_save.duplicate(true)
	boss_save["run"]["room"] = "ch1_boss"
	boss_save["mds"]["room"] = "ch1_boss"
	boss_save["world"]["boss_defeated"] = false
	check(RunSave.write(boss_save, RUN_PATH), "run_save_boss_save_written")
	flow.resume_requested = true
	var boss_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(boss_resume)
	current_scene = boss_resume
	await create_timer(0.4).timeout
	check(await _wait_mds(boss_resume), "run_save_boss_boots")
	check(boss_resume._mds_world.current_room == "ch1_boss", "run_save_boss_room")
	check(boss_resume._boss != null, "run_save_boss_spawned")
	check(not boss_resume._boss_defeated, "run_save_boss_alive_flag")
	check(boss_resume._mds_boss_arena != null, "run_save_boss_arena_tracked")
	await _free_scene(boss_resume)

	# --- Boundary checkpoint: the save already says the boss died (quit during
	# the authority/outro sequence). Booting must finish that sequence, not spawn
	# a second boss or pay the kill reward twice.
	var won_save: Dictionary = base_save.duplicate(true)
	won_save["run"]["room"] = "ch1_boss"
	won_save["mds"]["room"] = "ch1_boss"
	won_save["world"]["boss_defeated"] = true
	won_save["authority"] = {}
	# A real boss-death checkpoint is written while the player still stands in
	# the arena (that is where the killing blow landed), so the saved position
	# must be inside it. `ch1_boss` sits at world origin x=8960 and its Arena at
	# room-local (640, 280), so this lands 210 px below the arena centre — inside
	# its entry band. A checkpoint synthesised with the player elsewhere hides
	# the lock pass re-arming a room whose boss is already down.
	won_save["mds"]["position"] = [9600.0, 490.0]
	check(RunSave.write(won_save, RUN_PATH), "run_save_aftermath_save_written")
	flow.resume_requested = true
	var won_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(won_resume)
	current_scene = won_resume
	await create_timer(0.4).timeout
	check(await _wait_mds(won_resume), "run_save_aftermath_boots")
	check(won_resume._mds_world.current_room == "ch1_boss", "run_save_aftermath_room")
	check(won_resume._boss == null, "run_save_aftermath_no_second_boss")
	check(won_resume._boss_defeated, "run_save_aftermath_flag")
	var ch1_objective := won_resume.hud.find_child("Objective", true, false) as Label
	check(ch1_objective != null and ch1_objective.text == "墨骸史官已经倒下",
		"run_save_aftermath_objective_uses_ch1_boss")
	# Pass 97 regression: the restored player stands inside the dead boss's
	# arena, and re-locking it would replay the entrance sting and replace the
	# "已经倒下" objective with a fresh kill order.
	var aftermath_arena: ArenaRoom = won_resume._mds_boss_arena
	check(aftermath_arena != null and not aftermath_arena.is_locked(),
		"run_save_aftermath_dead_boss_room_stays_open")
	check(not won_resume._boss_entrance_started,
		"run_save_aftermath_no_entrance_replay")
	await create_timer(1.6).timeout
	check(won_resume._authority_choice != null and won_resume._authority_choice.is_open(),
		"run_save_aftermath_authority_opens")
	if won_resume._authority_choice != null and won_resume._authority_choice.is_open():
		won_resume._authority_choice._choose(0)
	await create_timer(0.4).timeout
	check(won_resume._story.is_open(), "run_save_aftermath_outro_opens")
	if won_resume._story.is_open():
		won_resume._story.close()
	await create_timer(0.5).timeout
	check(won_resume._story.is_open() and won_resume._story._choice_mode,
		"run_save_aftermath_choice_opens")
	if won_resume._story.is_open() and won_resume._story._choice_mode:
		won_resume._story.choose(0)
	await create_timer(1.2).timeout
	# Chapter 1 now hands off into Chapter 2 instead of ending the campaign.
	check(won_resume._chapter == 1, "run_save_aftermath_enters_chapter_2")
	check(not won_resume._finished, "run_save_aftermath_does_not_finish")
	check(won_resume._story.is_open() and not won_resume._story._choice_mode,
		"run_save_aftermath_opens_chapter_2_intro")
	check(not flow.last_victory, "run_save_aftermath_no_victory_recorded")
	check(flow.profile != null and flow.profile.demo_cleared,
		"run_save_aftermath_demo_cleared")
	# The last safe checkpoint is still the Chapter 1 boss room: quitting during
	# the Chapter 2 intro must replay the completion page, not skip content.
	check(FileAccess.file_exists(RUN_PATH), "run_save_aftermath_keeps_checkpoint")
	var aftermath_saved := RunSave.read(RUN_PATH)
	check(int(aftermath_saved.get("run", {}).get("chapter", -1)) == 0,
		"run_save_aftermath_checkpoint_still_chapter_1")
	await _free_scene(won_resume)

	# --- Boundary checkpoint: quit after the authority was already picked but
	# before the outro finished. Booting must keep that pick, must not reopen the
	# authority choice, and must not spawn another boss.
	var chosen_save: Dictionary = base_save.duplicate(true)
	chosen_save["run"]["room"] = "ch1_boss"
	chosen_save["mds"]["room"] = "ch1_boss"
	chosen_save["world"]["boss_defeated"] = true
	chosen_save["authority"] = {"id": "revive", "revive_used": false, "rewrite_used": false}
	check(RunSave.write(chosen_save, RUN_PATH), "run_save_chosen_authority_save_written")
	flow.resume_requested = true
	var chosen_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(chosen_resume)
	current_scene = chosen_resume
	await create_timer(0.4).timeout
	check(await _wait_mds(chosen_resume), "run_save_chosen_authority_boots")
	check(chosen_resume._mds_world.current_room == "ch1_boss", "run_save_chosen_authority_room")
	check(chosen_resume._boss == null, "run_save_chosen_authority_no_second_boss")
	check(chosen_resume.run_state.authority != null
		and chosen_resume.run_state.authority.id == &"revive",
		"run_save_chosen_authority_restored")
	await create_timer(0.4).timeout
	check(not chosen_resume._authority_choice.is_open(),
		"run_save_chosen_authority_not_reopened")
	check(chosen_resume._story.is_open(), "run_save_chosen_authority_outro_opens")
	if chosen_resume._story.is_open():
		chosen_resume._story.close()
	await create_timer(0.5).timeout
	check(chosen_resume._story.is_open() and chosen_resume._story._choice_mode,
		"run_save_chosen_authority_choice_opens")
	if chosen_resume._story.is_open() and chosen_resume._story._choice_mode:
		chosen_resume._story.choose(0)
	await create_timer(1.2).timeout
	check(chosen_resume._chapter == 1, "run_save_chosen_authority_enters_chapter_2")
	check(not chosen_resume._finished, "run_save_chosen_authority_does_not_finish")
	check(chosen_resume._story.is_open() and not chosen_resume._story._choice_mode,
		"run_save_chosen_authority_opens_chapter_2_intro")
	check(FileAccess.file_exists(RUN_PATH),
		"run_save_chosen_authority_keeps_checkpoint")
	await _free_scene(chosen_resume)

	# --- Main and backup both corrupt: discard the run once, say so, and start
	# the fresh run cleanly instead of looping on the broken pair.
	RunSave.clear(RUN_PATH)
	var bad_main := FileAccess.open(RUN_PATH, FileAccess.WRITE)
	bad_main.store_string("broken")
	bad_main.close()
	var bad_backup := FileAccess.open(RUN_PATH + ".bak", FileAccess.WRITE)
	bad_backup.store_string("also broken")
	bad_backup.close()
	flow.resume_requested = true
	var both_bad = load("res://scenes/main.tscn").instantiate()
	root.add_child(both_bad)
	current_scene = both_bad
	await create_timer(0.4).timeout
	check(both_bad.hud.get_message_text().contains("局内存档损坏"),
		"run_save_both_corrupt_player_message")
	_close_story(both_bad)
	check(await _wait_mds(both_bad), "run_save_both_corrupt_still_boots")
	check(both_bad._mds_world.current_room == "ch1_01", "run_save_both_corrupt_starts_new_run")
	check(both_bad._resume_data.is_empty(), "run_save_both_corrupt_not_applied")
	check(not FileAccess.file_exists(RUN_PATH + ".bak"),
		"run_save_both_corrupt_backup_cleared")
	await _free_scene(both_bad)

	# --- A future-version main file must not poison a valid backup: recovery
	# uses the backup and promotes it instead of discarding the run.
	check(RunSave.write(base_save, RUN_PATH), "run_save_future_backup_seed_main")
	var future_main: Dictionary = base_save.duplicate(true)
	future_main["version"] = RunSave.SAVE_VERSION + 1
	check(RunSave.write(future_main, RUN_PATH), "run_save_future_backup_main_written")
	check(FileAccess.file_exists(RUN_PATH + ".bak"), "run_save_future_backup_present")
	flow.resume_requested = true
	var future_backup = load("res://scenes/main.tscn").instantiate()
	root.add_child(future_backup)
	current_scene = future_backup
	await create_timer(0.4).timeout
	check(not future_backup.hud.get_message_text().contains("损坏"),
		"run_save_future_backup_no_discard_message")
	_close_story(future_backup)
	check(await _wait_mds(future_backup), "run_save_future_backup_still_boots")
	check(not future_backup._resume_data.is_empty(),
		"run_save_future_backup_resume_applied")
	check(future_backup._mds_world.current_room == "ch1_01",
		"run_save_future_backup_room")
	check(int(RunSave.read(RUN_PATH).get("version", 0)) == RunSave.SAVE_VERSION,
		"run_save_future_backup_main_valid_after_boot")
	await _free_scene(future_backup)

	# --- A future version number with no recoverable backup is discarded like
	# any other unusable save.
	RunSave.clear(RUN_PATH)
	var future_save: Dictionary = base_save.duplicate(true)
	future_save["version"] = RunSave.SAVE_VERSION + 1
	check(RunSave.write(future_save, RUN_PATH), "run_save_future_version_written")
	flow.resume_requested = true
	var future = load("res://scenes/main.tscn").instantiate()
	root.add_child(future)
	current_scene = future
	await create_timer(0.4).timeout
	check(future.hud.get_message_text().contains("局内存档损坏"),
		"run_save_future_version_player_message")
	_close_story(future)
	check(await _wait_mds(future), "run_save_future_version_still_boots")
	check(future._mds_world.current_room == "ch1_01", "run_save_future_version_starts_new_run")
	check(future._resume_data.is_empty(), "run_save_future_version_not_applied")
	await _free_scene(future)

	# --- Checkpoint inside the hidden vault: one room below the main path in
	# world space. Resuming must land on the exact spot, keep the one-shot chest
	# and stele states, and never trigger the fall guard (which once pinned the
	# player to the door and drained health).
	flow.resume_requested = false
	var vault_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(vault_run)
	current_scene = vault_run
	await create_timer(0.4).timeout
	_close_story(vault_run)
	check(await _wait_mds(vault_run), "run_save_vault_boots")
	await vault_run._mds_world.load_room("ch1_03")
	await create_timer(0.3).timeout
	var vault_door := MDSGate.find_gate(vault_run._mds_world.room_node, "door1")
	check(vault_door != null, "run_save_vault_door_present")
	if vault_door != null:
		vault_door.use()
		check(await _wait_room(vault_run, "ch1_vault"), "run_save_vault_entered")
		await create_timer(0.2).timeout
		for chest in vault_run._chests:
			vault_run._open_chest(chest)
		if not vault_run._steles.is_empty():
			vault_run.player.global_position = vault_run._steles[0].global_position
			vault_run.player.velocity = Vector2.ZERO
			await create_timer(0.15).timeout
			vault_run._claim_nearest_stele()
			await process_frame
		check(vault_run._opened_chests.has("ch1_vault/Chest"), "run_save_vault_chest_marked")
		check(vault_run._claimed_steles.has("ch1_vault/Stele"), "run_save_vault_stele_marked")
		vault_run.player.max_health = 140
		vault_run.player.health = 77
		vault_run.run_state.max_ink = 110
		vault_run.run_state.ink = 52
		vault_run.run_state.pages = 31
		vault_run.run_state.set_corruption(29)
		await create_timer(0.2).timeout
		var vault_saved_position: Vector2 = vault_run.player.global_position
		check(vault_run.save_run_now(), "run_save_vault_write")
		var vault_file := RunSave.read(RUN_PATH)
		check(String(vault_file.get("run", {}).get("room", "")) == "ch1_vault",
			"run_save_vault_file_room")
		var vault_found: Array = vault_file.get("progress", {}).get("vaults", [])
		var vault_chests: Array = vault_file.get("world", {}).get("opened_chest_ids", [])
		var vault_steles: Array = vault_file.get("world", {}).get("claimed_stele_ids", [])
		check(vault_found.has("ch1_vault"), "run_save_vault_file_discovery")
		check(vault_chests.has("ch1_vault/Chest"), "run_save_vault_file_chest")
		check(vault_steles.has("ch1_vault/Stele"), "run_save_vault_file_stele")
		await _free_scene(vault_run)

		flow.resume_requested = true
		var vault_resume = load("res://scenes/main.tscn").instantiate()
		root.add_child(vault_resume)
		current_scene = vault_resume
		await create_timer(0.4).timeout
		_close_story(vault_resume)
		check(await _wait_mds(vault_resume), "run_save_vault_resume_boots")
		check(vault_resume._mds_world.current_room == "ch1_vault",
			"run_save_vault_resume_room")
		check(vault_resume.player.max_health == 140, "run_save_vault_resume_max_health")
		check(vault_resume.player.health == 77, "run_save_vault_resume_health")
		check(vault_resume.run_state.max_ink == 110, "run_save_vault_resume_max_ink")
		check(vault_resume.run_state.ink == 52, "run_save_vault_resume_ink")
		check(vault_resume.run_state.pages == 31, "run_save_vault_resume_pages")
		check(vault_resume.run_state.corruption == 29, "run_save_vault_resume_corruption")
		check(absf(vault_resume.player.global_position.x - vault_saved_position.x) < 8.0,
			"run_save_vault_resume_x")
		check(absf(vault_resume.player.global_position.y - vault_saved_position.y) < 40.0,
			"run_save_vault_resume_position")
		check(vault_resume._discovered_vaults.has("ch1_vault"),
			"run_save_vault_resume_discovery")
		var resumed_vault_chest := false
		for chest in vault_resume._chests:
			if chest.is_open:
				resumed_vault_chest = true
		check(resumed_vault_chest, "run_save_vault_resume_chest_open")
		check(vault_resume._steles.is_empty(), "run_save_vault_resume_stele_claimed")
		# A full invulnerability window in the vault must not cost health.
		var vault_hp: int = vault_resume.player.health
		await create_timer(0.8).timeout
		check(vault_resume.player.health == vault_hp, "run_save_vault_resume_no_fall_damage")
		var vault_x: float = vault_resume.player.global_position.x
		Input.action_press("move_right")
		await create_timer(0.4).timeout
		Input.action_release("move_right")
		await create_timer(0.1).timeout
		check(vault_resume.player.global_position.x > vault_x + 10.0,
			"run_save_vault_resume_can_move")
		var vault_exit := MDSGate.find_gate(vault_resume._mds_world.room_node, "door1")
		check(vault_exit != null, "run_save_vault_resume_exit_present")
		if vault_exit != null:
			vault_exit.use()
			check(await _wait_room(vault_resume, "ch1_03"),
				"run_save_vault_resume_returns_to_path")
		await _free_scene(vault_resume)

	# --- Legacy checkpoint compatibility: a save written before per-node ids
	# only carries room keys. It must still load (not be treated as corrupt),
	# keep suppressing its one-shot content, and carry the old keys forward.
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var legacy_seed = load("res://scenes/main.tscn").instantiate()
	root.add_child(legacy_seed)
	current_scene = legacy_seed
	await create_timer(0.4).timeout
	_close_story(legacy_seed)
	check(await _wait_mds(legacy_seed), "run_save_legacy_boots")
	await legacy_seed._mds_world.load_room("ch1_03")
	await create_timer(0.3).timeout
	check(legacy_seed._mds_world.current_room == "ch1_03", "run_save_legacy_seeded_room")
	legacy_seed.player.global_position = legacy_seed._last_checkpoint + Vector2(40, 0)
	legacy_seed.player.velocity = Vector2.ZERO
	await create_timer(0.2).timeout
	check(legacy_seed.save_run_now(), "run_save_legacy_seed_write")
	var old_save := RunSave.read(RUN_PATH)
	check(not old_save.is_empty(), "run_save_legacy_seed_reads")
	old_save["progress"].erase("cleared_encounters")
	old_save["progress"]["cleared_rooms"] = ["ch1_01"]
	old_save["progress"]["cleared_in_chapter"] = 1
	old_save["world"].erase("claimed_stele_ids")
	old_save["world"].erase("opened_chest_ids")
	old_save["world"]["opened_chests"] = ["ch1_03"]
	old_save["world"]["claimed_steles"] = ["ch1_rest"]
	check(RunSave.write(old_save, RUN_PATH), "run_save_legacy_rewritten")
	await _free_scene(legacy_seed)

	flow.resume_requested = true
	var legacy_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(legacy_resume)
	current_scene = legacy_resume
	await create_timer(0.4).timeout
	_close_story(legacy_resume)
	check(await _wait_mds(legacy_resume), "run_save_legacy_resume_boots")
	check(legacy_resume._mds_world.current_room == "ch1_03",
		"run_save_legacy_resume_room")
	check(legacy_resume._legacy_cleared_rooms.has("ch1_01"),
		"run_save_legacy_cleared_record_read")
	check(legacy_resume._cleared_encounters.is_empty(),
		"run_save_legacy_has_no_new_encounter_keys")
	check(legacy_resume._legacy_opened_chests.has("ch1_03"),
		"run_save_legacy_chest_record_read")
	check(legacy_resume._legacy_claimed_steles.has("ch1_rest"),
		"run_save_legacy_stele_record_read")
	var legacy_chest_open := false
	for chest in legacy_resume._chests:
		if chest.is_open:
			legacy_chest_open = true
	check(legacy_chest_open, "run_save_legacy_chest_stays_open")
	await legacy_resume._mds_world.load_room("ch1_01")
	await create_timer(0.2).timeout
	check(legacy_resume._rooms.is_empty(), "run_save_legacy_room_not_respawned")
	await legacy_resume._mds_world.load_room("ch1_rest")
	await create_timer(0.2).timeout
	check(legacy_resume._steles.is_empty(), "run_save_legacy_stele_suppressed")
	check(legacy_resume.save_run_now(), "run_save_legacy_carry_write")
	var carried := RunSave.read(RUN_PATH)
	check(not carried.is_empty(), "run_save_legacy_carry_reads")
	check((carried.get("progress", {}).get("cleared_rooms", []) as Array).has("ch1_01"),
		"run_save_legacy_cleared_carried")
	check((carried.get("world", {}).get("opened_chests", []) as Array).has("ch1_03"),
		"run_save_legacy_chest_carried")
	check((carried.get("world", {}).get("claimed_steles", []) as Array).has("ch1_rest"),
		"run_save_legacy_stele_carried")
	check(not (carried.get("progress", {}).get("cleared_encounters", []) as Array).has("ch1_01/Arena"),
		"run_save_legacy_no_fabricated_ids")
	await _free_scene(legacy_resume)

	# --- Quit while a modal page is open. The window-close path calls
	# save_run_on_exit(), not a manual checkpoint; resuming must drop the page,
	# keep the pre-page state, and never skip content that was not yet claimed.
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var modal_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(modal_run)
	current_scene = modal_run
	await create_timer(0.4).timeout
	_close_story(modal_run)
	check(await _wait_mds(modal_run), "run_save_modal_event_boots")
	await modal_run._mds_world.load_room("ch1_05")
	check(await _wait_room(modal_run, "ch1_05"), "run_save_modal_event_room")
	await create_timer(1.2).timeout
	check(modal_run._story.is_open() and modal_run._story._choice_mode,
		"run_save_modal_event_open")
	check(not modal_run._cleared_encounters.has("ch1_05/event"),
		"run_save_modal_event_not_cleared")
	var modal_pages: int = modal_run.run_state.pages
	modal_run.save_run_on_exit()
	var modal_file := RunSave.read(RUN_PATH)
	check(String(modal_file.get("run", {}).get("room", "")) == "ch1_05",
		"run_save_modal_event_file_room")
	check(not (modal_file.get("progress", {}).get("cleared_encounters", []) as Array).has("ch1_05/event"),
		"run_save_modal_event_file_not_cleared")
	await _free_scene(modal_run)

	flow.resume_requested = true
	var modal_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(modal_resume)
	current_scene = modal_resume
	await create_timer(0.4).timeout
	_close_story(modal_resume)
	check(await _wait_mds(modal_resume), "run_save_modal_event_resume_boots")
	check(modal_resume._mds_world.current_room == "ch1_05",
		"run_save_modal_event_resume_room")
	await create_timer(1.2).timeout
	check(modal_resume._story.is_open() and modal_resume._story._choice_mode,
		"run_save_modal_event_reopens")
	if modal_resume._story.is_open():
		modal_resume._story.choose(1)
	await create_timer(0.2).timeout
	check(modal_resume._cleared_encounters.has("ch1_05/event"),
		"run_save_modal_event_clears_after_choice")
	check(modal_resume.run_state.pages > modal_pages,
		"run_save_modal_event_pays_pages")
	await _free_scene(modal_resume)

	# Shop page: the purchase and remaining pages survive the close-the-window
	# path, while the page itself is not restored over the resumed room.
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var shop_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(shop_run)
	current_scene = shop_run
	await create_timer(0.4).timeout
	_close_story(shop_run)
	check(await _wait_mds(shop_run), "run_save_modal_shop_boots")
	await shop_run._mds_world.load_room("ch1_rest")
	check(await _wait_room(shop_run, "ch1_rest"), "run_save_modal_shop_room")
	check(not shop_run._shops.is_empty(), "run_save_modal_shop_present")
	var modal_shop_id: StringName = &""
	var modal_shop_pages := 0
	if not shop_run._shops.is_empty():
		var stall: MemoryShop = shop_run._shops[0]
		modal_shop_id = stall.shop_id
		shop_run.run_state.add_pages(60)
		shop_run._open_shop(stall)
		var shop_offers: Array = shop_run._shop_cache.get(modal_shop_id, [])
		check(not shop_offers.is_empty(), "run_save_modal_shop_offers")
		if not shop_offers.is_empty():
			shop_run._on_shop_buy(0)
		modal_shop_pages = shop_run.run_state.pages
		check(shop_run._shop_ui.visible, "run_save_modal_shop_open")
		shop_run.save_run_on_exit()
		var shop_file := RunSave.read(RUN_PATH)
		var saved_shops: Dictionary = shop_file.get("world", {}).get("shops", {})
		check(saved_shops.has(String(modal_shop_id)), "run_save_modal_shop_file_cache")
		await _free_scene(shop_run)

		flow.resume_requested = true
		var shop_resume = load("res://scenes/main.tscn").instantiate()
		root.add_child(shop_resume)
		current_scene = shop_resume
		await create_timer(0.4).timeout
		_close_story(shop_resume)
		check(await _wait_mds(shop_resume), "run_save_modal_shop_resume_boots")
		check(shop_resume._mds_world.current_room == "ch1_rest",
			"run_save_modal_shop_resume_room")
		check(shop_resume.run_state.pages == modal_shop_pages,
			"run_save_modal_shop_resume_pages")
		check(not shop_resume._shop_ui.visible and not paused,
			"run_save_modal_shop_resume_closed")
		var modal_resumed_stall: MemoryShop = null
		for candidate in shop_resume._shops:
			if candidate.shop_id == modal_shop_id:
				modal_resumed_stall = candidate
		check(modal_resumed_stall != null, "run_save_modal_shop_resume_stall")
		if modal_resumed_stall != null:
			shop_resume._open_shop(modal_resumed_stall)
			var cached: Array = shop_resume._shop_cache.get(modal_shop_id, [])
			check(not cached.is_empty() and bool(cached[0].get("bought", false)),
				"run_save_modal_shop_resume_bought")
			check(shop_resume._shop_ui._buttons[0].disabled,
				"run_save_modal_shop_resume_row_disabled")
			shop_resume._shop_ui.close_shop()
			await process_frame
		await _free_scene(shop_resume)

	# Reward page: the room was marked cleared just before the choice, so this
	# path must keep the pre-clear checkpoint and replay the fight.
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var reward_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(reward_run)
	current_scene = reward_run
	await create_timer(0.4).timeout
	_close_story(reward_run)
	check(await _wait_mds(reward_run), "run_save_modal_reward_boots")
	await reward_run._mds_world.load_room("ch1_02")
	check(await _wait_room(reward_run, "ch1_02"), "run_save_modal_reward_room")
	check(RunSave.has_save(RUN_PATH), "run_save_modal_reward_entry_checkpoint")
	var modal_arena := reward_run._mds_world.room_node.get_node_or_null("Arena") as ArenaRoom
	check(modal_arena != null, "run_save_modal_reward_arena")
	# An enemy corpse is freed by a 0.35 s scene timer that keeps running while
	# the tree is paused, so a page open inside that window can still be up when
	# the room clears and the deferred reward arrives. The required reward must
	# wait for gameplay instead of covering the page (closing the page would then
	# unpause the world with an unpicked reward on screen), and the checkpoint
	# must stay silent while it waits or the resume loses the unchosen reward.
	if modal_arena != null:
		reward_run._map_overlay.open()
		reward_run._on_room_cleared(modal_arena, reward_run._chapter)
		check(reward_run._reward_pending, "run_save_modal_reward_pending")
		check(reward_run._cleared_encounters.has("ch1_02/Arena"),
			"run_save_modal_reward_room_cleared")
		await create_timer(0.2).timeout
		check(not reward_run._reward_ui.visible,
			"run_save_modal_reward_waits_for_map")
		check(reward_run._map_overlay.is_open(), "run_save_modal_reward_map_kept")
		check(not reward_run.save_run_now(), "run_save_modal_reward_pending_blocked")
		reward_run._map_overlay.close()
		var reward_wait := 0.0
		while reward_wait < 2.0 and not reward_run._reward_ui.visible:
			await create_timer(0.05).timeout
			reward_wait += 0.05
	check(reward_run._reward_ui.visible and paused, "run_save_modal_reward_open")
	# The reward is still owed until it is picked, so the hold stays on.
	check(reward_run._reward_pending, "run_save_modal_reward_pending_after_open")
	check(not reward_run.save_run_now(), "run_save_modal_reward_blocked")
	reward_run.save_run_on_exit()
	var reward_file := RunSave.read(RUN_PATH)
	check(not (reward_file.get("progress", {}).get("cleared_encounters", []) as Array).has("ch1_02/Arena"),
		"run_save_modal_reward_file_not_cleared")
	await _free_scene(reward_run)

	flow.resume_requested = true
	var reward_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(reward_resume)
	current_scene = reward_resume
	await create_timer(0.4).timeout
	_close_story(reward_resume)
	check(await _wait_mds(reward_resume), "run_save_modal_reward_resume_boots")
	check(reward_resume._mds_world.current_room == "ch1_02",
		"run_save_modal_reward_resume_room")
	check(not reward_resume._cleared_encounters.has("ch1_02/Arena"),
		"run_save_modal_reward_replays")
	check(not reward_resume._reward_ui.visible, "run_save_modal_reward_resume_closed")
	await _free_scene(reward_resume)

	# Map and inventory own no save fields: resuming must not restore either
	# page or leave the tree paused.
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var page_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(page_run)
	current_scene = page_run
	await create_timer(0.4).timeout
	_close_story(page_run)
	check(await _wait_mds(page_run), "run_save_modal_page_boots")
	await page_run._mds_world.load_room("ch1_01")
	check(await _wait_room(page_run, "ch1_01"), "run_save_modal_page_room")
	page_run._map_overlay.open()
	await process_frame
	page_run.save_run_on_exit()
	await _free_scene(page_run)

	flow.resume_requested = true
	var page_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(page_resume)
	current_scene = page_resume
	await create_timer(0.4).timeout
	_close_story(page_resume)
	check(await _wait_mds(page_resume), "run_save_modal_map_resume_boots")
	check(page_resume._mds_world.current_room == "ch1_01",
		"run_save_modal_map_resume_room")
	check(not page_resume._map_overlay.is_open() and not paused,
		"run_save_modal_map_resume_closed")
	page_resume._toggle_overlay(page_resume.inventory_ui)
	await process_frame
	page_resume.save_run_on_exit()
	await _free_scene(page_resume)

	flow.resume_requested = true
	var inventory_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(inventory_resume)
	current_scene = inventory_resume
	await create_timer(0.4).timeout
	_close_story(inventory_resume)
	check(await _wait_mds(inventory_resume), "run_save_modal_inventory_resume_boots")
	check(inventory_resume._mds_world.current_room == "ch1_01",
		"run_save_modal_inventory_resume_room")
	check(inventory_resume._overlay == null and not paused,
		"run_save_modal_inventory_resume_closed")
	await _free_scene(inventory_resume)

	# --- Quitting while the keybind page is capturing: the checkpoint is still
	# written, and the capture flag dies with the scene so the resumed run is
	# not stuck ignoring input. ---
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var capture_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(capture_run)
	current_scene = capture_run
	await create_timer(0.4).timeout
	_close_story(capture_run)
	check(await _wait_mds(capture_run), "run_save_capture_exit_boots")
	await capture_run._mds_world.load_room("ch1_03")
	check(await _wait_room(capture_run, "ch1_03"), "run_save_capture_exit_room")
	capture_run.player.health = 77
	capture_run.run_state.pages = 33
	check(capture_run.save_run_now(), "run_save_capture_exit_checkpoint")
	capture_run.pause_menu.open_pause()
	capture_run._on_pause_settings()
	await process_frame
	check(capture_run.settings_menu.visible, "run_save_capture_exit_settings")
	var keybind_button: Button = null
	for button in capture_run.settings_menu.find_children("*", "Button", true, false):
		if String(button.text).contains("键位设置"):
			keybind_button = button
			break
	check(keybind_button != null, "run_save_capture_exit_keybind_entry")
	if keybind_button != null:
		keybind_button.pressed.emit()
		await process_frame
		var keybind_ui = capture_run.settings_menu._subpages.back() \
			if not capture_run.settings_menu._subpages.is_empty() else null
		check(keybind_ui != null and keybind_ui.is_open(), "run_save_capture_exit_keybind_open")
		check(flow.input_capture_active, "run_save_capture_exit_capture_active")
		if keybind_ui != null:
			keybind_ui._begin_capture(keybind_ui.ACTIONS[0])
			await process_frame
		capture_run.save_run_on_exit()
		var capture_saved := RunSave.read(RUN_PATH)
		check(String(capture_saved.get("run", {}).get("room", "")) == "ch1_03",
			"run_save_capture_exit_saved_room")
		check(int(capture_saved.get("run", {}).get("pages", 0)) == 33,
			"run_save_capture_exit_saved_pages")
		await _free_scene(capture_run)
		check(not flow.input_capture_active, "run_save_capture_exit_flag_released")

	flow.resume_requested = true
	var capture_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(capture_resume)
	current_scene = capture_resume
	check(await _wait_mds(capture_resume), "run_save_capture_exit_resume_boots")
	check(capture_resume._mds_world.current_room == "ch1_03",
		"run_save_capture_exit_resume_room")
	check(capture_resume.player.health == 77, "run_save_capture_exit_resume_health")
	check(capture_resume.run_state.pages == 33, "run_save_capture_exit_resume_pages")
	check(not flow.input_capture_active, "run_save_capture_exit_resume_flag_clean")
	check(not paused and capture_resume.player.is_physics_processing(),
		"run_save_capture_exit_resume_playable")
	await _free_scene(capture_resume)

	# --- Quitting while the required boss authority pick is open: the boss stays
	# defeated, the authority is still ungranted, and the pick is presented again
	# on resume instead of being skipped. ---
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var authority_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(authority_run)
	current_scene = authority_run
	await create_timer(0.4).timeout
	_close_story(authority_run)
	check(await _wait_mds(authority_run), "run_save_authority_exit_boots")
	await authority_run._mds_world.load_room("ch1_boss")
	check(await _wait_room(authority_run, "ch1_boss"), "run_save_authority_exit_room")
	authority_run._boss_defeated = true
	authority_run.run_state.authority = null
	check(authority_run._chapter_plan.authority_pool.size() >= 2,
		"run_save_authority_exit_pool")
	authority_run._grant_chapter_authority.call_deferred()
	await create_timer(1.6).timeout
	check(authority_run._authority_choice.is_open(), "run_save_authority_exit_choice_open")
	check(paused, "run_save_authority_exit_paused")
	authority_run.save_run_on_exit()
	var authority_saved := RunSave.read(RUN_PATH)
	check(String(authority_saved.get("run", {}).get("room", "")) == "ch1_boss",
		"run_save_authority_exit_saved_room")
	check(bool(authority_saved.get("world", {}).get("boss_defeated", false)),
		"run_save_authority_exit_boss_defeated_saved")
	check(String(authority_saved.get("authority", {}).get("id", "")) == "",
		"run_save_authority_exit_not_granted")
	await _free_scene(authority_run)

	flow.resume_requested = true
	var authority_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(authority_resume)
	current_scene = authority_resume
	check(await _wait_mds(authority_resume), "run_save_authority_exit_resume_boots")
	check(authority_resume._mds_world.current_room == "ch1_boss",
		"run_save_authority_exit_resume_room")
	check(authority_resume._boss_defeated, "run_save_authority_exit_resume_boss_defeated")
	check(authority_resume._boss == null or not is_instance_valid(authority_resume._boss),
		"run_save_authority_exit_resume_no_second_boss")
	await create_timer(1.6).timeout
	check(authority_resume._authority_choice.is_open(),
		"run_save_authority_exit_resume_choice_reopens")
	check(authority_resume.run_state.authority == null,
		"run_save_authority_exit_resume_still_ungranted")
	if authority_resume._authority_choice.is_open():
		authority_resume._authority_choice._choose(0)
	await create_timer(0.3).timeout
	check(authority_resume.run_state.authority != null,
		"run_save_authority_exit_pick_applies")
	check(not authority_resume._authority_choice.is_open(),
		"run_save_authority_exit_pick_closes")
	await _free_scene(authority_resume)

	# --- Quitting with the ending screen open writes no run checkpoint (the run
	# is over) and still saves the profile; a stale resume then starts clean. ---
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var ending_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(ending_run)
	current_scene = ending_run
	await create_timer(0.4).timeout
	_close_story(ending_run)
	check(await _wait_mds(ending_run), "run_save_ending_exit_boots")
	await ending_run._mds_world.load_room("ch1_03")
	check(await _wait_room(ending_run, "ch1_03"), "run_save_ending_exit_room")
	check(ending_run.save_run_now(), "run_save_ending_exit_checkpoint")
	check(RunSave.has_save(RUN_PATH), "run_save_ending_exit_save_exists")
	ending_run._finish(true)
	await create_timer(1.2).timeout
	check(ending_run.ending_screen.visible, "run_save_ending_exit_page_visible")
	check(paused, "run_save_ending_exit_paused")
	var victory_hint := EndingHintData.format_hint(
		EndingHintData.pick(ending_run.run_state.run_seed, true),
		flow.prompt_label(&"restart"))
	check(ending_run.ending_screen._hint != null
		and ending_run.ending_screen._hint.text == victory_hint,
		"run_save_ending_hint_matches_run_seed")
	check(ending_run.ending_screen._hint.text.contains("回到最后的档案馆"),
		"run_save_ending_hint_keeps_destination")
	check(not RunSave.has_save(RUN_PATH), "run_save_ending_exit_clears_checkpoint")
	ending_run.save_run_on_exit()
	check(not RunSave.has_save(RUN_PATH), "run_save_ending_exit_writes_no_checkpoint")
	check(FileAccess.file_exists(PROFILE_PATH), "run_save_ending_exit_saves_profile")
	await _free_scene(ending_run)

	flow.resume_requested = true
	var ending_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(ending_resume)
	current_scene = ending_resume
	await create_timer(0.4).timeout
	_close_story(ending_resume)
	check(await _wait_mds(ending_resume), "run_save_ending_exit_resume_boots")
	check(ending_resume._mds_world.current_room == "ch1_01",
		"run_save_ending_exit_resume_starts_new_run")
	check(not paused, "run_save_ending_exit_resume_unpaused")
	await _free_scene(ending_resume)

	# --- A `.bak`-only recovery followed immediately by modal pages: the
	# promoted checkpoint stays readable and the next write does not lose it. ---
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var backup_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(backup_run)
	current_scene = backup_run
	await create_timer(0.4).timeout
	_close_story(backup_run)
	check(await _wait_mds(backup_run), "run_save_backup_modal_boots")
	await backup_run._mds_world.load_room("ch1_03")
	check(await _wait_room(backup_run, "ch1_03"), "run_save_backup_modal_room")
	backup_run.run_state.pages = 21
	check(backup_run.save_run_now(), "run_save_backup_modal_first_write")
	backup_run.run_state.pages = 42
	check(backup_run.save_run_now(), "run_save_backup_modal_second_write")
	check(FileAccess.file_exists(RUN_PATH + ".bak"), "run_save_backup_modal_backup_exists")
	var corrupt := FileAccess.open(RUN_PATH, FileAccess.WRITE)
	check(corrupt != null, "run_save_backup_modal_corrupt_open")
	if corrupt != null:
		corrupt.store_string("not a config file")
		corrupt.close()
	await _free_scene(backup_run)

	flow.resume_requested = true
	var backup_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(backup_resume)
	current_scene = backup_resume
	check(await _wait_mds(backup_resume), "run_save_backup_modal_resume_boots")
	check(backup_resume._mds_world.current_room == "ch1_03",
		"run_save_backup_modal_resume_room")
	check(backup_resume.run_state.pages == 21, "run_save_backup_modal_uses_backup")
	backup_resume.pause_menu.open_pause()
	await process_frame
	check(backup_resume.pause_menu.is_open(), "run_save_backup_modal_pause_opens")
	backup_resume._on_pause_settings()
	await process_frame
	check(backup_resume.settings_menu.visible, "run_save_backup_modal_settings_opens")
	backup_resume.settings_menu.close()
	await process_frame
	check(backup_resume.pause_menu.is_open(), "run_save_backup_modal_pause_returns")
	backup_resume.pause_menu.toggle()
	await process_frame
	check(not paused, "run_save_backup_modal_resumed")
	check(backup_resume.save_run_now(), "run_save_backup_modal_writes_after_recovery")
	var repaired := RunSave.read(RUN_PATH)
	check(not repaired.is_empty(), "run_save_backup_modal_main_readable")
	check(int(repaired.get("run", {}).get("pages", 0)) == 21,
		"run_save_backup_modal_pages_kept")
	await _free_scene(backup_resume)

	# --- Quitting with the death result page open (won=false). The run is over,
	# so no checkpoint may be written; the death reward on the Profile must
	# survive the exit, and a stale resume request starts a clean run. ---
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var death_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(death_run)
	current_scene = death_run
	await create_timer(0.4).timeout
	_close_story(death_run)
	check(await _wait_mds(death_run), "run_save_death_exit_boots")
	check(RunSave.has_save(RUN_PATH), "run_save_death_exit_checkpoint")
	var death_fragments: int = flow.profile.memory_fragments
	death_run.player.take_damage(9999)
	await create_timer(1.0).timeout
	check(death_run.ending_screen.visible, "run_save_death_exit_page_visible")
	check(paused, "run_save_death_exit_paused")
	var death_title := death_run.ending_screen.get_node_or_null(
		"Center/Panel/Margin/VBox/Title") as Label
	check(death_title != null and death_title.text == "记录中断",
		"run_save_death_exit_is_interrupted")
	check(not RunSave.has_save(RUN_PATH), "run_save_death_exit_clears_checkpoint")
	death_run.save_run_on_exit()
	check(not RunSave.has_save(RUN_PATH), "run_save_death_exit_writes_no_checkpoint")
	check(FileAccess.file_exists(PROFILE_PATH), "run_save_death_exit_saves_profile")
	var death_disk := Profile.new()
	check(death_disk.load_profile(PROFILE_PATH), "run_save_death_exit_profile_readable")
	check(death_disk.memory_fragments >= death_fragments + 10,
		"run_save_death_exit_keeps_reward")
	death_disk.free()
	await _free_scene(death_run)

	flow.resume_requested = true
	var death_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(death_resume)
	current_scene = death_resume
	await create_timer(0.4).timeout
	_close_story(death_resume)
	check(await _wait_mds(death_resume), "run_save_death_exit_resume_boots")
	check(death_resume._resume_data.is_empty(),
		"run_save_death_exit_resume_has_no_data")
	check(not death_resume._resume_restored,
		"run_save_death_exit_resume_starts_fresh")
	check(death_resume._mds_world.current_room == "ch1_01",
		"run_save_death_exit_resume_first_room")
	check(not paused, "run_save_death_exit_resume_unpaused")
	check(not death_resume.ending_screen.visible,
		"run_save_death_exit_resume_no_ending_page")
	await _free_scene(death_resume)
	flow.resume_requested = false

	# --- Quitting while the boss entrance flavour is playing. The checkpoint
	# stays in the boss room with the boss alive; resuming must not duplicate
	# the boss, strand the letterbox or skip the entrance. ---
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var entrance_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(entrance_run)
	current_scene = entrance_run
	await create_timer(0.4).timeout
	_close_story(entrance_run)
	check(await _wait_mds(entrance_run), "run_save_boss_entrance_exit_boots")
	await entrance_run._mds_world.load_room("ch1_boss")
	check(await _wait_room(entrance_run, "ch1_boss"), "run_save_boss_entrance_exit_room")
	check(entrance_run._boss != null, "run_save_boss_entrance_exit_boss_spawned")
	if not entrance_run._boss_entrance_started:
		for room in entrance_run._rooms:
			if entrance_run._is_boss_room(room):
				entrance_run.player.global_position = room.global_position + Vector2(0, -80)
		await process_frame
		await process_frame
	check(entrance_run._boss_entrance_started,
		"run_save_boss_entrance_exit_started")
	var entrance_text: String = entrance_run.hud.get_message_text()
	check(entrance_text != "", "run_save_boss_entrance_exit_text")
	check(entrance_text == BossEntranceData.pick(entrance_run.run_state.run_seed, 0),
		"run_save_boss_entrance_exit_text_matches_seed")
	entrance_run.save_run_on_exit()
	check(RunSave.has_save(RUN_PATH), "run_save_boss_entrance_exit_writes_checkpoint")
	var entrance_save := RunSave.read(RUN_PATH)
	check(String(entrance_save.get("run", {}).get("room", "")) == "ch1_boss",
		"run_save_boss_entrance_exit_save_room")
	check(not bool(entrance_save.get("world", {}).get("boss_defeated", true)),
		"run_save_boss_entrance_exit_save_boss_alive")
	await _free_scene(entrance_run)

	flow.resume_requested = true
	var entrance_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(entrance_resume)
	current_scene = entrance_resume
	await create_timer(0.4).timeout
	_close_story(entrance_resume)
	check(await _wait_mds(entrance_resume), "run_save_boss_entrance_resume_boots")
	check(entrance_resume._resume_restored, "run_save_boss_entrance_resume_restored")
	check(entrance_resume._mds_world.current_room == "ch1_boss",
		"run_save_boss_entrance_resume_room")
	check(entrance_resume._boss != null and not entrance_resume._boss.dead,
		"run_save_boss_entrance_resume_boss_alive")
	check(not entrance_resume._boss_defeated, "run_save_boss_entrance_resume_flag")
	check(not paused, "run_save_boss_entrance_resume_unpaused")
	var live_bosses := 0
	if entrance_resume._mds_boss_arena != null:
		var enemies_root: Node = entrance_resume._mds_boss_arena.get_node_or_null("Enemies")
		if enemies_root != null:
			for child in enemies_root.get_children():
				if child is InkArchivist and not child.dead:
					live_bosses += 1
	check(live_bosses == 1, "run_save_boss_entrance_resume_single_boss")
	if not entrance_resume._boss_entrance_started:
		for room in entrance_resume._rooms:
			if entrance_resume._is_boss_room(room):
				entrance_resume.player.global_position = room.global_position + Vector2(0, -80)
		await process_frame
		await process_frame
	check(entrance_resume._boss_entrance_started,
		"run_save_boss_entrance_resume_replays")
	# The intro waits 1.25 s before the 0.5 s letterbox-out tween, so wait past
	# the full 1.75 s entrance beat before asserting the bars are gone.
	await create_timer(2.0).timeout
	check(is_equal_approx(entrance_resume._screen_fx._top.offset_bottom, 0.0),
		"run_save_boss_entrance_resume_letterbox_clears")
	check(entrance_resume._boss != null and not entrance_resume._boss.dead,
		"run_save_boss_entrance_resume_boss_still_alive")
	await _free_scene(entrance_resume)
	flow.resume_requested = false

	# --- Quitting inside the 0.65 s death settlement delay. Death is final the
	# moment it is committed, so the pre-death checkpoint must be gone before
	# the result page opens; otherwise a window close during the animation
	# would leave "继续本局" pointing at a live player. ---
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var delay_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(delay_run)
	current_scene = delay_run
	await create_timer(0.4).timeout
	_close_story(delay_run)
	check(await _wait_mds(delay_run), "run_save_death_delay_boots")
	check(RunSave.has_save(RUN_PATH), "run_save_death_delay_checkpoint_before")
	check(await _wait_vulnerable(delay_run), "run_save_death_delay_vulnerable")
	var delay_room: String = delay_run._mds_world.current_room
	var delay_before := RunSave.read(RUN_PATH)
	check(int(delay_before.get("run", {}).get("health", 0)) > 0,
		"run_save_death_delay_checkpoint_has_health")
	delay_run.player.take_damage(999999)
	check(delay_run.player.health == 0, "run_save_death_delay_player_dead")
	check(delay_run._ending_pending, "run_save_death_delay_settlement_pending")
	check(not delay_run._finished, "run_save_death_delay_not_finished")
	delay_run.save_run_on_exit()
	check(not RunSave.has_save(RUN_PATH),
		"run_save_death_delay_clears_checkpoint")
	check(FileAccess.file_exists(PROFILE_PATH),
		"run_save_death_delay_saves_profile")
	# Free before the timer resumes the coroutine, exactly like a real quit.
	await _free_scene(delay_run)

	flow.resume_requested = true
	var delay_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(delay_resume)
	current_scene = delay_resume
	await create_timer(0.4).timeout
	_close_story(delay_resume)
	check(await _wait_mds(delay_resume), "run_save_death_delay_resume_boots")
	check(delay_resume._resume_data.is_empty(),
		"run_save_death_delay_resume_has_no_data")
	check(not delay_resume._resume_restored,
		"run_save_death_delay_resume_starts_fresh")
	check(delay_resume._mds_world.current_room == "ch1_01",
		"run_save_death_delay_resume_first_room")
	check(delay_resume._mds_world.current_room != delay_room or delay_room == "ch1_01",
		"run_save_death_delay_resume_not_old_room")
	check(delay_resume.player.health > 0,
		"run_save_death_delay_resume_player_alive")
	check(not delay_resume.ending_screen.visible,
		"run_save_death_delay_resume_no_ending_page")
	await _free_scene(delay_resume)
	flow.resume_requested = false

	# --- Quitting during the corruption frenzy. The checkpoint must carry the
	# frenzy countdown, the capped health pool and the pre-frenzy maximum so the
	# resumed run can finish the frenzy and recover normally. ---
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var frenzy_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(frenzy_run)
	current_scene = frenzy_run
	await create_timer(0.4).timeout
	_close_story(frenzy_run)
	check(await _wait_mds(frenzy_run), "run_save_frenzy_boots")
	var frenzy_base_max: int = frenzy_run.player.max_health
	frenzy_run.run_state.corruption = 99
	frenzy_run.run_state.add_corruption(1)
	await process_frame
	check(frenzy_run._frenzy_active, "run_save_frenzy_starts")
	check(frenzy_run.player.max_health < frenzy_base_max,
		"run_save_frenzy_caps_health")
	var frenzy_max: int = frenzy_run.player.max_health
	var frenzy_health: int = frenzy_run.player.health
	var frenzy_room: String = frenzy_run._mds_world.current_room
	var frenzy_left: float = frenzy_run._frenzy_left
	frenzy_run.save_run_on_exit()
	var frenzy_save := RunSave.read(RUN_PATH)
	check(not frenzy_save.is_empty(), "run_save_frenzy_exit_writes_save")
	var frenzy_world: Dictionary = frenzy_save.get("world", {})
	var frenzy_data: Dictionary = frenzy_world.get("frenzy", {})
	check(bool(frenzy_data.get("active", false)),
		"run_save_frenzy_exit_marks_active")
	check(float(frenzy_data.get("left", 0.0)) > 0.0,
		"run_save_frenzy_exit_keeps_remaining")
	check(int(frenzy_data.get("saved_max_health", 0)) == frenzy_base_max,
		"run_save_frenzy_exit_keeps_pre_frenzy_max")
	check(int(frenzy_save.get("run", {}).get("max_health", 0)) == frenzy_max,
		"run_save_frenzy_exit_keeps_capped_max")
	check(int(frenzy_save.get("run", {}).get("corruption", 0)) == 100,
		"run_save_frenzy_exit_keeps_corruption")
	await _free_scene(frenzy_run)

	flow.resume_requested = true
	var frenzy_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(frenzy_resume)
	current_scene = frenzy_resume
	await create_timer(0.4).timeout
	_close_story(frenzy_resume)
	check(await _wait_mds(frenzy_resume), "run_save_frenzy_resume_boots")
	check(frenzy_resume._frenzy_active, "run_save_frenzy_resume_active")
	check(frenzy_resume._frenzy_left > 0.0
		and frenzy_resume._frenzy_left <= frenzy_left + 1.0,
		"run_save_frenzy_resume_remaining")
	check(frenzy_resume._frenzy_saved_max_health == frenzy_base_max,
		"run_save_frenzy_resume_saved_max")
	check(frenzy_resume.player.max_health == frenzy_max,
		"run_save_frenzy_resume_capped_health")
	check(frenzy_resume.player.health == frenzy_health,
		"run_save_frenzy_resume_health_value")
	check(frenzy_resume._mds_world.current_room == frenzy_room,
		"run_save_frenzy_resume_room")
	frenzy_resume._frenzy_left = 0.01
	frenzy_resume._update_corruption_frenzy(0.02)
	check(not frenzy_resume._frenzy_active,
		"run_save_frenzy_resume_can_end")
	check(frenzy_resume.player.max_health == frenzy_base_max,
		"run_save_frenzy_resume_restores_max")
	check(frenzy_resume.run_state.corruption < 100,
		"run_save_frenzy_resume_drops_corruption")
	await _free_scene(frenzy_resume)
	flow.resume_requested = false

	# --- Quitting while the first Hub tutorial page (and its Codex) is open.
	# The Hub has no run checkpoint to write; the tutorial must stay incomplete
	# and replay on the next launch instead of being marked done. ---
	RunSave.clear(RUN_PATH)
	flow.reset_profile()
	check(flow.profile != null and not flow.profile.tutorial_done,
		"run_save_tutorial_exit_profile_fresh")
	paused = false
	var tutorial_hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(tutorial_hub)
	current_scene = tutorial_hub
	await create_timer(0.4).timeout
	check(tutorial_hub.tutorial_flow != null and tutorial_hub.tutorial_flow.is_active(),
		"run_save_tutorial_exit_starts")
	tutorial_hub._open_tutorial_codex()
	await process_frame
	await process_frame
	check(tutorial_hub._tutorial_codex != null and tutorial_hub._tutorial_codex.visible,
		"run_save_tutorial_exit_codex_open")
	check(not tutorial_hub.has_method("save_run_on_exit"),
		"run_save_tutorial_exit_hub_has_no_save")
	check(not RunSave.has_save(RUN_PATH), "run_save_tutorial_exit_no_checkpoint")
	var tutorial_disk := Profile.new()
	check(tutorial_disk.load_profile(PROFILE_PATH),
		"run_save_tutorial_exit_profile_readable")
	check(not tutorial_disk.tutorial_done,
		"run_save_tutorial_exit_not_marked_done")
	tutorial_disk.free()
	await _free_scene(tutorial_hub)
	check(not paused, "run_save_tutorial_exit_unpaused")

	paused = false
	tutorial_hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(tutorial_hub)
	current_scene = tutorial_hub
	await create_timer(0.4).timeout
	check(tutorial_hub.tutorial_flow != null and tutorial_hub.tutorial_flow.is_active(),
		"run_save_tutorial_replays_after_exit")
	check(tutorial_hub._tutorial_codex != null
		and not tutorial_hub._tutorial_codex.visible,
		"run_save_tutorial_codex_not_restored")
	check(tutorial_hub.player != null and tutorial_hub.player.is_physics_processing(),
		"run_save_tutorial_hub_player_free")
	check(flow.profile != null and not flow.profile.tutorial_done,
		"run_save_tutorial_still_incomplete")
	await _free_scene(tutorial_hub)

	# --- Quitting with the pause menu open keeps the current-room checkpoint
	# and resumes playable, with no pause menu inherited from the old process.
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var pause_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(pause_run)
	current_scene = pause_run
	await create_timer(0.4).timeout
	_close_story(pause_run)
	check(await _wait_mds(pause_run), "run_save_pause_exit_boots")
	await pause_run._mds_world.load_room("ch1_02")
	check(await _wait_room(pause_run, "ch1_02"), "run_save_pause_exit_room")
	var pause_health: int = pause_run.player.health
	pause_run.pause_menu.open_pause()
	await process_frame
	check(paused and pause_run.pause_menu.is_open(), "run_save_pause_exit_menu_open")
	pause_run.save_run_on_exit()
	var pause_saved := RunSave.read(RUN_PATH)
	check(not pause_saved.is_empty(), "run_save_pause_exit_saves")
	check(String(pause_saved.get("run", {}).get("room", "")) == "ch1_02",
		"run_save_pause_exit_saved_room")
	check(int(pause_saved.get("run", {}).get("health", -1)) == pause_health,
		"run_save_pause_exit_saved_health")
	await _free_scene(pause_run)

	flow.resume_requested = true
	var pause_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(pause_resume)
	current_scene = pause_resume
	check(await _wait_mds(pause_resume), "run_save_pause_exit_resume_boots")
	check(pause_resume._mds_world.current_room == "ch1_02",
		"run_save_pause_exit_resume_room")
	check(not paused, "run_save_pause_exit_resume_unpaused")
	check(not pause_resume.pause_menu.is_open(), "run_save_pause_exit_resume_no_menu")
	check(pause_resume.player.is_physics_processing(),
		"run_save_pause_exit_resume_playable")
	check(pause_resume.player.health == pause_health,
		"run_save_pause_exit_resume_health")
	await _free_scene(pause_resume)

	# --- Quitting while the chapter-completion page is open after the authority
	# pick: the last checkpoint still holds the granted authority and
	# boss_defeated, so resume replays the completion and can finish the demo.
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var complete_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(complete_run)
	current_scene = complete_run
	await create_timer(0.4).timeout
	_close_story(complete_run)
	check(await _wait_mds(complete_run), "run_save_complete_exit_boots")
	await complete_run._mds_world.load_room("ch1_boss")
	check(await _wait_room(complete_run, "ch1_boss"), "run_save_complete_exit_room")
	complete_run._boss_defeated = true
	if complete_run._boss != null and is_instance_valid(complete_run._boss):
		complete_run._boss.queue_free()
		complete_run._boss = null
	complete_run.run_state.authority = null
	complete_run._grant_chapter_authority.call_deferred()
	await create_timer(1.6).timeout
	check(complete_run._authority_choice.is_open(),
		"run_save_complete_exit_authority_open")
	complete_run._authority_choice._choose(0)
	await create_timer(0.3).timeout
	check(complete_run.run_state.authority != null,
		"run_save_complete_exit_authority_granted")
	check(complete_run.save_run_now(), "run_save_complete_exit_checkpoint")
	var granted_id: StringName = complete_run.run_state.authority.id
	complete_run._complete_chapter.call_deferred()
	await create_timer(0.5).timeout
	check(complete_run._story.is_open(), "run_save_complete_exit_page_open")
	check(paused, "run_save_complete_exit_page_paused")
	check(complete_run._ending_pending, "run_save_complete_exit_pending")
	complete_run.save_run_on_exit()
	var complete_saved := RunSave.read(RUN_PATH)
	check(not complete_saved.is_empty(), "run_save_complete_exit_save_survives")
	check(String(complete_saved.get("run", {}).get("room", "")) == "ch1_boss",
		"run_save_complete_exit_save_room")
	check(bool(complete_saved.get("world", {}).get("boss_defeated", false)),
		"run_save_complete_exit_save_boss")
	check(String(complete_saved.get("authority", {}).get("id", "")) == String(granted_id),
		"run_save_complete_exit_save_authority")
	check(not flow.profile.demo_cleared, "run_save_complete_exit_profile_not_cleared")
	await _free_scene(complete_run)

	flow.resume_requested = true
	var complete_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(complete_resume)
	current_scene = complete_resume
	check(await _wait_mds(complete_resume), "run_save_complete_exit_resume_boots")
	check(complete_resume._mds_world.current_room == "ch1_boss",
		"run_save_complete_exit_resume_room")
	check(complete_resume._boss == null or not is_instance_valid(complete_resume._boss),
		"run_save_complete_exit_resume_no_second_boss")
	await create_timer(1.0).timeout
	check(complete_resume.run_state.authority != null
		and complete_resume.run_state.authority.id == granted_id,
		"run_save_complete_exit_resume_keeps_authority")
	check(complete_resume._story.is_open(), "run_save_complete_exit_resume_page")
	check(paused, "run_save_complete_exit_resume_page_paused")
	complete_resume._story.close()
	await create_timer(0.4).timeout
	check(complete_resume._story.is_open() and complete_resume._story._choice_mode,
		"run_save_complete_exit_resume_choice")
	complete_resume._story.choose(0)
	await create_timer(1.2).timeout
	check(complete_resume._chapter == 1, "run_save_complete_exit_resume_enters_chapter_2")
	check(not complete_resume._finished, "run_save_complete_exit_resume_not_finished")
	check(complete_resume._story.is_open() and not complete_resume._story._choice_mode,
		"run_save_complete_exit_resume_opens_chapter_2_intro")
	# Closing the Chapter 2 intro loads the big-map entry and moves the
	# checkpoint into the new chapter.
	complete_resume._story.close()
	await create_timer(1.0).timeout
	check(await _wait_mds(complete_resume), "run_save_complete_exit_resume_chapter_2_boots")
	check(complete_resume._mds_world.current_room == "ch2_entry",
		"run_save_complete_exit_resume_chapter_2_room")
	var chapter_2_saved := RunSave.read(RUN_PATH)
	check(int(chapter_2_saved.get("run", {}).get("chapter", -1)) == 1,
		"run_save_complete_exit_resume_checkpoint_chapter_2")
	check(String(chapter_2_saved.get("run", {}).get("room", "")) == "ch2_entry",
		"run_save_complete_exit_resume_checkpoint_entry")
	await _free_scene(complete_resume)

	# --- Hub dialogue open when the game is closed: no run checkpoint is
	# written (the Hub has no save hook), the profile stays readable, and a
	# fresh Hub boots with no inherited dialogue or frozen player.
	RunSave.clear(RUN_PATH)
	flow.profile.memory_fragments = 500
	flow.save_profile()
	check(FileAccess.file_exists(PROFILE_PATH), "run_save_hub_dialogue_profile")
	var hub_dialogue = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub_dialogue)
	current_scene = hub_dialogue
	await create_timer(0.4).timeout
	var talkable = null
	for candidate in hub_dialogue.get_npcs():
		if candidate.npc_id != &"wenjin" and candidate.npc_id != &"baiyu":
			talkable = candidate
			break
	check(talkable != null, "run_save_hub_dialogue_npc")
	if talkable != null:
		hub_dialogue.talk_to_npc(talkable)
		await process_frame
		await process_frame
		check(hub_dialogue.dialogue_ui.is_open(), "run_save_hub_dialogue_open")
		check(not hub_dialogue.player.is_physics_processing(),
			"run_save_hub_dialogue_freezes_player")
		check(not paused, "run_save_hub_dialogue_no_tree_pause")
	check(not hub_dialogue.has_method("save_run_on_exit"),
		"run_save_hub_dialogue_no_run_hook")
	check(not RunSave.has_save(RUN_PATH), "run_save_hub_dialogue_no_checkpoint")
	await _free_scene(hub_dialogue)
	var hub_dialogue_disk := Profile.new()
	check(hub_dialogue_disk.load_profile(PROFILE_PATH),
		"run_save_hub_dialogue_profile_readable")
	check(hub_dialogue_disk.memory_fragments == 500,
		"run_save_hub_dialogue_profile_fragments")
	hub_dialogue_disk.free()
	var hub_dialogue_reboot = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub_dialogue_reboot)
	current_scene = hub_dialogue_reboot
	await create_timer(0.3).timeout
	check(not hub_dialogue_reboot.dialogue_ui.is_open(),
		"run_save_hub_dialogue_reboot_closed")
	check(hub_dialogue_reboot.player.is_physics_processing(),
		"run_save_hub_dialogue_reboot_playable")
	check(not paused, "run_save_hub_dialogue_reboot_unpaused")
	await _free_scene(hub_dialogue_reboot)

	# --- Hub shop open when the game is closed: the purchase was already
	# persisted by the Hub, no run checkpoint exists, and the bought item is
	# still owned after reload.
	RunSave.clear(RUN_PATH)
	flow.profile.memory_fragments = 500
	flow.save_profile()
	var hub_shop = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub_shop)
	current_scene = hub_shop
	await create_timer(0.4).timeout
	check(hub_shop.shop_ui != null, "run_save_hub_shop_ui")
	var guru = null
	for candidate in hub_shop.get_npcs():
		if candidate.npc_id == &"guru":
			guru = candidate
			break
	check(guru != null, "run_save_hub_shop_guru")
	if guru != null:
		hub_shop.talk_to_npc(guru)
		await process_frame
		await process_frame
		var guard := 40
		while hub_shop.dialogue_ui.is_open() and guard > 0:
			hub_shop.dialogue_ui.advance()
			await process_frame
			guard -= 1
	await process_frame
	await process_frame
	check(hub_shop.shop_ui.is_open(), "run_save_hub_shop_open")
	check(not hub_shop.player.is_physics_processing(),
		"run_save_hub_shop_freezes_player")
	check(not paused, "run_save_hub_shop_no_tree_pause")
	var shop_ref: Shop = hub_shop.shop
	var item: Dictionary = {}
	for entry in shop_ref.stock:
		if not shop_ref.owned_by(entry, hub_shop.profile):
			item = entry
			break
	check(not item.is_empty(), "run_save_hub_shop_unowned_stock")
	var item_id := StringName(item.get("id", &""))
	var cost := shop_ref.price_for(item_id)
	var fragments_before: int = hub_shop.profile.memory_fragments
	check(hub_shop.shop_ui.buy(item_id), "run_save_hub_shop_buys")
	check(hub_shop.profile.memory_fragments == fragments_before - cost,
		"run_save_hub_shop_pays")
	check(not RunSave.has_save(RUN_PATH), "run_save_hub_shop_no_checkpoint")
	await _free_scene(hub_shop)
	var hub_shop_disk := Profile.new()
	check(hub_shop_disk.load_profile(PROFILE_PATH),
		"run_save_hub_shop_profile_readable")
	check(hub_shop_disk.memory_fragments == fragments_before - cost,
		"run_save_hub_shop_fragments_persist")
	check(shop_ref.owned_by(item, hub_shop_disk),
		"run_save_hub_shop_purchase_persists")
	hub_shop_disk.free()

	# --- Hub archive panel open when the game is closed: the upgrade purchase
	# is persisted immediately, the Hub writes no run checkpoint, and a fresh
	# Hub boots with the panel closed and the player free.
	RunSave.clear(RUN_PATH)
	flow.profile.tutorial_done = true
	flow.profile.memory_fragments = 500
	flow.save_profile()
	var archive_hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(archive_hub)
	current_scene = archive_hub
	await create_timer(0.4).timeout
	archive_hub.perform_npc_function(&"luchen", &"archive")
	await process_frame
	await process_frame
	check(archive_hub.archive_ui.is_open(), "run_save_archive_exit_panel_open")
	check(not archive_hub.player.is_physics_processing(),
		"run_save_archive_exit_freezes_player")
	var archive_track := StringName(ArchiveData.TRACKS[0].get(&"id", &""))
	var archive_cost := ArchiveData.cost(archive_track, 0)
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(flow.profile.archive_level(archive_track) == 1,
		"run_save_archive_exit_purchase_applied")
	check(flow.profile.memory_fragments == 500 - archive_cost,
		"run_save_archive_exit_purchase_paid")
	check(not archive_hub.has_method("save_run_on_exit"),
		"run_save_archive_exit_no_run_hook")
	check(not RunSave.has_save(RUN_PATH), "run_save_archive_exit_no_checkpoint")
	check(FileAccess.file_exists(PROFILE_PATH), "run_save_archive_exit_profile")
	await _free_scene(archive_hub)
	var archive_disk := Profile.new()
	check(archive_disk.load_profile(PROFILE_PATH),
		"run_save_archive_exit_profile_readable")
	check(archive_disk.archive_level(archive_track) == 1,
		"run_save_archive_exit_level_persisted")
	check(archive_disk.memory_fragments == 500 - archive_cost,
		"run_save_archive_exit_fragments_persisted")
	archive_disk.free()
	var archive_reboot = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(archive_reboot)
	current_scene = archive_reboot
	await create_timer(0.4).timeout
	check(not archive_reboot.archive_ui.is_open(),
		"run_save_archive_reboot_panel_closed")
	check(archive_reboot.player.is_physics_processing(),
		"run_save_archive_reboot_player_free")
	check(not paused, "run_save_archive_reboot_unpaused")
	await _free_scene(archive_reboot)

	# --- Hub training stele mid-tutorial when the game is closed: the
	# incomplete tutorial must replay from step 1, keep no stale phrase and no
	# damaged dummy, and must not be marked done.
	flow.reset_profile()
	flow.auto_save = true
	paused = false
	var stele_exit_hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(stele_exit_hub)
	current_scene = stele_exit_hub
	await create_timer(0.5).timeout
	check(stele_exit_hub.tutorial_flow != null
		and stele_exit_hub.tutorial_flow.is_active(),
		"run_save_stele_exit_tutorial_active")
	stele_exit_hub._open_tutorial_codex()
	await process_frame
	stele_exit_hub._close_tutorial_codex()
	await process_frame
	await process_frame
	var stele_words: Array[WordData] = []
	for stele_word in stele_exit_hub._tutorial_run.inventory.words:
		if stele_words.size() < 2 and stele_word != null:
			stele_words.append(stele_word)
	var stele_phrase: ResolvedPhrase = PhraseResolver.new().resolve(stele_words)
	check(stele_phrase != null, "run_save_stele_exit_phrase_resolves")
	stele_exit_hub._on_tutorial_phrase_equipped(0, stele_phrase)
	await process_frame
	await process_frame
	check(stele_exit_hub.tutorial_flow.get_hint().contains("训练碑"),
		"run_save_stele_exit_at_step3")
	check(not stele_exit_hub.has_method("save_run_on_exit"),
		"run_save_stele_exit_no_run_hook")
	check(not RunSave.has_save(RUN_PATH), "run_save_stele_exit_no_checkpoint")
	await _free_scene(stele_exit_hub)
	var stele_disk := Profile.new()
	check(stele_disk.load_profile(PROFILE_PATH),
		"run_save_stele_exit_profile_readable")
	check(not stele_disk.tutorial_done, "run_save_stele_exit_not_done")
	stele_disk.free()
	var stele_reboot = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(stele_reboot)
	current_scene = stele_reboot
	await create_timer(0.5).timeout
	check(stele_reboot.tutorial_flow.is_active(),
		"run_save_stele_reboot_tutorial_replays")
	check(stele_reboot.tutorial_flow.get_hint().contains("第 1 步"),
		"run_save_stele_reboot_step1")
	check(stele_reboot._tutorial_phrase == null,
		"run_save_stele_reboot_no_stale_phrase")
	check(stele_reboot.training_dummy.health == stele_reboot.training_dummy.max_health,
		"run_save_stele_reboot_dummy_full")
	check(stele_reboot.player.is_physics_processing(),
		"run_save_stele_reboot_player_free")
	check(not paused, "run_save_stele_reboot_unpaused")
	# Finishing the stele hit persists tutorial_done; a later quit must not
	# replay the banner.
	stele_reboot._open_tutorial_codex()
	await process_frame
	stele_reboot._close_tutorial_codex()
	await process_frame
	await process_frame
	var reboot_words: Array[WordData] = []
	for reboot_word in stele_reboot._tutorial_run.inventory.words:
		if reboot_words.size() < 2 and reboot_word != null:
			reboot_words.append(reboot_word)
	var reboot_phrase: ResolvedPhrase = PhraseResolver.new().resolve(reboot_words)
	check(reboot_phrase != null, "run_save_stele_done_phrase_resolves")
	stele_reboot._on_tutorial_phrase_equipped(0, reboot_phrase)
	await process_frame
	stele_reboot.interact_with(stele_reboot.training_dummy)
	await process_frame
	await process_frame
	check(flow.profile.tutorial_done, "run_save_stele_done_marks_profile")
	check(not stele_reboot.tutorial_flow.is_active(),
		"run_save_stele_done_banner_closed")
	check(not RunSave.has_save(RUN_PATH), "run_save_stele_done_no_checkpoint")
	await _free_scene(stele_reboot)
	var stele_done_reboot = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(stele_done_reboot)
	current_scene = stele_done_reboot
	await create_timer(0.4).timeout
	check(not stele_done_reboot.tutorial_flow.is_active(),
		"run_save_stele_done_reboot_no_tutorial")
	check(not stele_done_reboot.tutorial_flow.visible,
		"run_save_stele_done_reboot_banner_hidden")
	check(stele_done_reboot.player.is_physics_processing(),
		"run_save_stele_done_reboot_player_free")
	check(not paused, "run_save_stele_done_reboot_unpaused")
	var stele_done_disk := Profile.new()
	check(stele_done_disk.load_profile(PROFILE_PATH),
		"run_save_stele_done_profile_readable")
	check(stele_done_disk.tutorial_done, "run_save_stele_done_persisted")
	stele_done_disk.free()
	await _free_scene(stele_done_reboot)

	# --- Title settings open (with its AI subpage) when the game is closed:
	# no run checkpoint, the Profile stays readable and unchanged, and a fresh
	# Hub boots with no settings page, no capture and a free player.
	var title_fragments: int = int(flow.profile.memory_fragments)
	paused = false
	var title_hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(title_hub)
	current_scene = title_hub
	await create_timer(0.4).timeout
	var title := TitleScreen.new()
	title_hub.add_child(title)
	await process_frame
	await process_frame
	title_hub._connect_title_settings()
	var title_settings_button := title.find_child("SettingsButton", true, false) as Button
	check(title_settings_button != null, "run_save_title_exit_settings_button")
	if title_settings_button != null:
		title_settings_button.grab_focus()
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		check(title_hub.settings_menu != null and title_hub.settings_menu.visible,
			"run_save_title_exit_settings_open")
		var title_ai_button: Button = null
		for candidate in title_hub.settings_menu.find_children("*", "Button", true, false):
			if String(candidate.text).contains("AI"):
				title_ai_button = candidate
				break
		if title_ai_button != null:
			title_ai_button.grab_focus()
			await _press_button(JOY_BUTTON_A)
			await _release_button(JOY_BUTTON_A)
			check(title_hub.settings_menu.has_subpage(),
				"run_save_title_exit_subpage_open")
		check(not title_hub.has_method("save_run_on_exit"),
			"run_save_title_exit_no_run_hook")
		check(not RunSave.has_save(RUN_PATH), "run_save_title_exit_no_checkpoint")
		var title_disk := Profile.new()
		check(title_disk.load_profile(PROFILE_PATH),
			"run_save_title_exit_profile_readable")
		check(title_disk.memory_fragments == title_fragments,
			"run_save_title_exit_fragments_intact")
		check(title_disk.tutorial_done, "run_save_title_exit_tutorial_intact")
		title_disk.free()
		await _free_scene(title_hub)
		paused = false
		var title_reboot = load("res://scenes/hub/hub.tscn").instantiate()
		root.add_child(title_reboot)
		current_scene = title_reboot
		await create_timer(0.4).timeout
		check(title_reboot.settings_menu == null
			or not title_reboot.settings_menu.visible,
			"run_save_title_reboot_settings_closed")
		check(title_reboot.player.is_physics_processing(),
			"run_save_title_reboot_player_free")
		check(not paused, "run_save_title_reboot_unpaused")
		check(not flow.input_capture_active,
			"run_save_title_reboot_no_capture")
		check(not RunSave.has_save(RUN_PATH),
			"run_save_title_reboot_no_checkpoint")
		await _free_scene(title_reboot)

	# --- 归档 authority: a final death pauses for one item pick, clears the
	# checkpoint before the pick (closing the window cannot revive the run), and
	# the chosen item reaches the next fresh run exactly once. ---
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	flow.profile.archived_item.clear()
	flow.profile.stored_relics.clear()
	flow.profile.pending_run_bonuses.clear()
	var archive_pick := load("res://resources/authorities/archive.tres") as AuthorityData
	var devour_pick := load("res://resources/authorities/devour.tres") as AuthorityData
	check(archive_pick != null and devour_pick != null, "run_save_archive_resources")

	var archive_first = load("res://scenes/main.tscn").instantiate()
	root.add_child(archive_first)
	current_scene = archive_first
	await create_timer(0.4).timeout
	_close_story(archive_first)
	check(await _wait_mds(archive_first), "run_save_archive_death_boots")
	check(await _wait_vulnerable(archive_first), "run_save_archive_death_vulnerable")
	check(RunSave.has_save(RUN_PATH), "run_save_archive_death_checkpoint_before")
	var archive_relic := ContentLibrary.relic_by_id(&"ink_heart")
	var archive_axe := ContentLibrary.weapon_by_id(&"ink_axe")
	check(archive_relic != null and archive_axe != null, "run_save_archive_items_exist")
	if archive_relic != null:
		archive_first.run_state.inventory.add_relic(archive_relic)
	if archive_axe != null:
		archive_first._equip_weapon(0, RunLoot.weapon_for_run(archive_axe, flow.profile))
	archive_first._authority.apply(archive_pick, archive_first.run_state)
	check(archive_first._authority.can_archive(), "run_save_archive_authority_ready")
	var archive_offers: Array[Dictionary] = archive_first._archive_offers()
	check(archive_offers.size() == 2, "run_save_archive_offers_carried_items")
	var starter_names := false
	for entry in archive_offers:
		if String(entry.get("name", "")) == "断页剑" \
				or String(entry.get("name", "")) == "墨弹枪":
			starter_names = true
	check(not starter_names, "run_save_archive_skips_starter_weapons")

	# The last enemy's corpse timer keeps running while the tree is paused, so
	# killing the room's last wave and dying inside its 0.35 s delay clears the
	# room behind the death archive pick. The deferred reward page must not
	# stack on the required pick (taking it would unpause the world underneath).
	# Hold the player still so stray contact damage cannot kill them before the
	# scripted last-enemy-then-death sequence; take_damage still works.
	archive_first.player.set_physics_process(false)
	var death_arena: ArenaRoom = null
	for room in archive_first._rooms:
		if room is ArenaRoom:
			death_arena = room
			break
	check(death_arena != null, "run_save_archive_room_arena")
	if death_arena != null:
		if not death_arena.is_locked():
			death_arena.lock_until_cleared()
		var race_rounds := 0
		while race_rounds < 400:
			race_rounds += 1
			var alive: Array = []
			for node in get_nodes_in_group("enemies"):
				if is_instance_valid(node) and not node.dead:
					alive.append(node)
			if alive.is_empty():
				await process_frame
				continue
			for enemy in alive:
				enemy.take_damage(999999)
			if death_arena._wave_queue.is_empty():
				break
			await process_frame
		check(not death_arena.is_cleared(), "run_save_archive_room_delay_running")

	archive_first.player.take_damage(999999)
	check(archive_first._archive_choice.is_open(), "run_save_archive_pick_opens")
	check(paused, "run_save_archive_pick_pauses")
	check(not archive_first._ending_pending, "run_save_archive_defers_ending")
	check(not RunSave.has_save(RUN_PATH),
		"run_save_archive_clears_checkpoint_before_pick")
	check(archive_first._death_committed, "run_save_archive_death_committed")
	# Let the corpses finish freeing while the pick waits for input: the room
	# clears, but death is final so the reward is dropped instead of covering
	# the page.
	if death_arena != null:
		await create_timer(0.8).timeout
		check(death_arena.is_cleared(), "run_save_archive_room_clears_behind_pick")
		check(archive_first._archive_choice.is_open(),
			"run_save_archive_pick_survives_room_clear")
		check(not archive_first._reward_ui.visible,
			"run_save_archive_no_reward_over_pick")
		check(paused, "run_save_archive_room_clear_keeps_pause")
		check(not archive_first.hud.visible,
			"run_save_archive_room_clear_hides_hud")
	await process_frame
	check(not archive_first.hud.visible, "run_save_archive_hides_hud")
	check(archive_first._archive_choice.get_option_count() == 2,
		"run_save_archive_pick_options")
	var archive_focus: Control = archive_first.get_viewport().gui_get_focus_owner()
	check(archive_focus == archive_first._archive_choice._buttons[0],
		"run_save_archive_pick_focus")
	# Start/B must not close the pick or open the pause page underneath it.
	await _press_button(JOY_BUTTON_START)
	await _release_button(JOY_BUTTON_START)
	check(archive_first._archive_choice.is_open(), "run_save_archive_start_ignored")
	check(not archive_first.pause_menu.is_open(), "run_save_archive_no_pause_page")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(archive_first._archive_choice.is_open(), "run_save_archive_b_ignored")
	check(paused, "run_save_archive_still_paused")
	archive_first.save_run_on_exit()
	check(not RunSave.has_save(RUN_PATH),
		"run_save_archive_exit_during_pick_no_checkpoint")
	archive_first._archive_choice._choose(0)
	check(not paused, "run_save_archive_pick_unpauses")
	check(String(flow.profile.archived_item.get("kind", "")) == "weapon",
		"run_save_archive_stores_weapon_kind")
	check(String(flow.profile.archived_item.get("id", "")) == "ink_axe",
		"run_save_archive_stores_weapon_id")
	check(archive_first._authority.can_archive() == false,
		"run_save_archive_spent")
	await create_timer(1.0).timeout
	check(archive_first.ending_screen.visible, "run_save_archive_ending_page")
	check(not RunSave.has_save(RUN_PATH), "run_save_archive_ending_no_checkpoint")
	var archive_pick_disk := Profile.new()
	check(archive_pick_disk.load_profile(PROFILE_PATH), "run_save_archive_profile_readable")
	check(String(archive_pick_disk.archived_item.get("id", "")) == "ink_axe",
		"run_save_archive_profile_persisted")
	archive_pick_disk.free()
	await _free_scene(archive_first)

	# Fresh launch: the archived weapon replaces the starting blade and leaves
	# the Profile slot empty.
	flow.resume_requested = false
	var archive_second = load("res://scenes/main.tscn").instantiate()
	root.add_child(archive_second)
	current_scene = archive_second
	await create_timer(0.4).timeout
	_close_story(archive_second)
	check(await _wait_mds(archive_second), "run_save_archive_receive_boots")
	check(archive_second.run_state.inventory.weapons[0] != null
		and archive_second.run_state.inventory.weapons[0].id == &"ink_axe",
		"run_save_archive_weapon_replaces_starter")
	check(archive_second.player.weapons[0] != null
		and archive_second.player.weapons[0].data.id == &"ink_axe",
		"run_save_archive_weapon_equipped")
	check(archive_second.inventory_ui.get_weapon_slot_text(0).contains("墨斧"),
		"run_save_archive_weapon_in_inventory_ui")
	check(flow.profile.archived_item.is_empty(), "run_save_archive_slot_consumed")

	# Second cycle: archive the carried relic instead. The next run receives it
	# in the inventory (and its corruption), not as a weapon. The carried axe is
	# itself a legitimate offer now, so the list holds both; pick the relic.
	archive_second.run_state.inventory.add_relic(archive_relic)
	archive_second._authority.apply(archive_pick, archive_second.run_state)
	var relic_offer_index := -1
	var second_offers: Array[Dictionary] = archive_second._archive_offers()
	for offer_index in second_offers.size():
		if StringName(second_offers[offer_index].get("kind", &"")) == &"relic" \
				and StringName(second_offers[offer_index].get("id", &"")) == &"ink_heart":
			relic_offer_index = offer_index
	check(second_offers.size() == 2 and relic_offer_index == 1,
		"run_save_archive_relic_offer")
	check(await _wait_vulnerable(archive_second), "run_save_archive_relic_vulnerable")
	archive_second.player.take_damage(999999)
	check(archive_second._archive_choice.is_open(), "run_save_archive_relic_pick_opens")
	archive_second._archive_choice._choose(relic_offer_index)
	check(String(flow.profile.archived_item.get("kind", "")) == "relic",
		"run_save_archive_stores_relic_kind")
	check(String(flow.profile.archived_item.get("id", "")) == "ink_heart",
		"run_save_archive_stores_relic_id")
	await create_timer(1.0).timeout
	check(archive_second.ending_screen.visible, "run_save_archive_relic_ending_page")
	await _free_scene(archive_second)

	# Trust tiers feed the next fresh run's pages; all five at 托付 would grant
	# 30, so the same cap of 20 must hold. No new save key is involved.
	for trust_npc in NPCProfiles.all_ids():
		flow.profile.add_npc_trust(trust_npc, 12.0)
	flow.resume_requested = false
	var archive_third = load("res://scenes/main.tscn").instantiate()
	root.add_child(archive_third)
	current_scene = archive_third
	await create_timer(0.4).timeout
	_close_story(archive_third)
	check(await _wait_mds(archive_third), "run_save_archive_relic_boots")
	check(archive_third.run_state.pages == TrustData.START_PAGES_CAP,
		"run_save_trust_start_pages")
	check(archive_third.run_state.inventory.has_relic(&"ink_heart"),
		"run_save_archive_relic_received")
	check(archive_third.inventory_ui.get_relics_text().contains("墨心"),
		"run_save_archive_relic_in_inventory_ui")
	check(archive_third.run_state.corruption >= archive_relic.corruption,
		"run_save_archive_relic_corruption")
	check(archive_third.run_state.inventory.weapons[0].id == &"broken_page_sword",
		"run_save_archive_weapon_not_reapplied")
	check(flow.profile.archived_item.is_empty(), "run_save_archive_relic_consumed")
	await _free_scene(archive_third)
	flow.profile.archived_item.clear()

	# --- Chapter 2 step 3: bench checkpoint and collapsing platform through the
	# real game scene (fall guard, run save, resume). The props are injected
	# into a Chapter 1 room at test time; no demo scene or save key changes.
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var props = load("res://scenes/main.tscn").instantiate()
	root.add_child(props)
	current_scene = props
	await create_timer(0.4).timeout
	_close_story(props)
	check(await _wait_mds(props), "run_save_bench_boots")
	check(props._mds_world.current_room == "ch1_01", "run_save_bench_room")
	check(get_nodes_in_group(BenchCheckpoint.GROUP).is_empty(),
		"run_save_ch1_has_no_benches")
	check(props._fall_limit_local == ChapterPlanData.DEFAULT_FALL_Y,
		"run_save_bench_default_fall_plane")
	# Keep the room's enemies alive but inert: queue_free would count as a
	# clear and open the reward page under the test.
	for enemy in get_nodes_in_group(&"enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	for hazard in get_nodes_in_group(&"hostile_hazards"):
		hazard.queue_free()
	props.player.health = props.player.max_health
	props.player._invulnerable_left = 0.0
	# Chapter 1 ground is tile collision and must keep treating down+jump as a
	# plain jump; only one-way platforms may swallow it.
	var ground_feet: float = props.player.global_position.y + Player.FOOT_Y
	Input.action_press("move_down")
	Input.action_press("jump")
	var ground_peak := ground_feet
	for _frame in 24:
		await physics_frame
		ground_peak = minf(ground_peak, props.player.global_position.y + Player.FOOT_Y)
	Input.action_release("jump")
	Input.action_release("move_down")
	check(ground_peak < ground_feet - 8.0, "run_save_ch1_down_jump_unchanged")
	for _frame in 120:
		await physics_frame
		if props.player.is_on_floor() \
				and absf(props.player.global_position.y + Player.FOOT_Y - ground_feet) <= 2.0:
			break
	var room_node: Node2D = props._mds_world.room_node
	check(room_node != null, "run_save_bench_room_node")
	var bench := BenchCheckpoint.new()
	bench.name = "TestBench"
	room_node.add_child(bench)
	# Bench anchors sit on the floor line; the respawn offset puts the player's
	# feet back on the same floor.
	var player_local := room_node.to_local(props.player.global_position)
	bench.global_position = room_node.to_global(
		Vector2(player_local.x + 40.0, MDSChapterRoom.FLOOR_Y))
	await physics_frame
	check(bench.is_in_group(BenchCheckpoint.GROUP), "run_save_bench_group")
	var bench_respawn := bench.respawn_position()
	Input.action_press("interact")
	await process_frame
	await process_frame
	Input.action_release("interact")
	check(bench.use_count == 1, "run_save_bench_interact_uses")
	check(props._last_checkpoint.distance_to(bench_respawn) < 1.0,
		"run_save_bench_updates_checkpoint")
	check(FileAccess.file_exists(RUN_PATH), "run_save_bench_writes_run_save")
	var bench_saved := RunSave.read(RUN_PATH)
	check(int(bench_saved.get("version", 0)) == RunSave.SAVE_VERSION,
		"run_save_bench_keeps_version")
	check(String(bench_saved.get("run", {}).get("room", "")) == "ch1_01",
		"run_save_bench_saved_room")
	var bench_saved_pos: Array = bench_saved.get("mds", {}).get("position", [])
	check(bench_saved_pos.size() == 2, "run_save_bench_saved_position")
	if bench_saved_pos.size() == 2:
		check(absf(float(bench_saved_pos[0]) - props.player.global_position.x) < 8.0,
			"run_save_bench_saved_player_x")
	check(props._fall_limit_local == ChapterPlanData.DEFAULT_FALL_Y,
		"run_save_bench_fall_plane_unchanged")

	# Collapsing platform: warning, fall to the floor and a restore, all without
	# the fall guard or the fall-plane resolver firing.
	# Left of the arena entry band: stepping into it would (correctly) refresh
	# the combat checkpoint and defeat the point of this bench test.
	var collapse := CollapsingPlatform.new()
	collapse.name = "TestCollapse"
	collapse.position = Vector2(16, 480)
	collapse.size = Vector2(80, 16)
	collapse.warn_time = 0.2
	collapse.fall_time = 0.2
	collapse.respawn_time = 5.0
	room_node.add_child(collapse)
	await physics_frame
	var collapse_hp: int = props.player.health
	props.player.global_position = room_node.to_global(Vector2(56, 480 - Player.FOOT_Y))
	props.player.velocity = Vector2.ZERO
	await physics_frame
	var collapse_fell := false
	for _frame in 180:
		await physics_frame
		if collapse.has_collapsed():
			collapse_fell = true
			break
	check(collapse_fell, "run_save_collapse_falls")
	check(not collapse.is_solid(), "run_save_collapse_collision_off")
	var floor_y := room_node.to_global(Vector2(0, 560))
	var landed := false
	for _frame in 180:
		await physics_frame
		if props.player.is_on_floor() \
				and absf(props.player.global_position.y + Player.FOOT_Y - floor_y.y) <= 2.0:
			landed = true
			break
	check(landed, "run_save_collapse_player_lands_on_floor")
	check(props.player.health == collapse_hp, "run_save_collapse_no_fall_guard_damage")
	check(props._fall_limit_local == ChapterPlanData.DEFAULT_FALL_Y,
		"run_save_collapse_fall_plane_unchanged")

	# Force a real fall while the platform is gone: the guard returns the player
	# to the bench and restores every collapsing platform first.
	props.player.global_position = room_node.to_global(Vector2(600, 900))
	props.player.velocity = Vector2.ZERO
	await process_frame
	await process_frame
	check(props.player.global_position.distance_to(bench_respawn) < 12.0,
		"run_save_bench_fall_returns_to_bench")
	check(collapse.is_solid() and collapse.state == CollapsingPlatform.State.IDLE,
		"run_save_fall_resets_collapsing_platforms")
	check(props.player.health == collapse_hp - 15, "run_save_bench_fall_damage")
	await _free_scene(props)

	# Resume: the bench's checkpoint brings the player back to the same room and
	# spot, with the normal save format.
	flow.resume_requested = true
	var bench_resumed = load("res://scenes/main.tscn").instantiate()
	root.add_child(bench_resumed)
	current_scene = bench_resumed
	await create_timer(0.4).timeout
	_close_story(bench_resumed)
	check(await _wait_mds(bench_resumed), "run_save_bench_resume_boots")
	check(bench_resumed._mds_world.current_room == "ch1_01", "run_save_bench_resume_room")
	check(bench_resumed.player.global_position.distance_to(bench_respawn) < 64.0,
		"run_save_bench_resume_position")
	check(bench_resumed._last_checkpoint.distance_to(bench_respawn) < 64.0,
		"run_save_bench_resume_checkpoint")
	await _free_scene(bench_resumed)

	# --- Chapter 2 boundary (test-only start). The checkpoint holds boss_defeated
	# and the granted authority. Resuming must not spawn a second boss or pay the
	# kill reward again, and (since pass 80) the chapter end hands off into the
	# Chapter 3 intro instead of stopping.
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var ch2_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(ch2_run)
	current_scene = ch2_run
	await create_timer(0.4).timeout
	_close_story(ch2_run)
	check(await _wait_mds(ch2_run), "run_save_ch2_boots")
	ch2_run._finished = false
	ch2_run._ending_pending = false
	ch2_run.ending_screen.visible = false
	paused = false
	ch2_run._start_chapter(1)
	await create_timer(0.3).timeout
	check(ch2_run._story.is_open(), "run_save_ch2_intro")
	_close_story(ch2_run)
	await process_frame
	check(await _wait_mds(ch2_run), "run_save_ch2_region_world")
	await ch2_run._mds_world.load_room("ch2_boss")
	check(await _wait_room(ch2_run, "ch2_boss"), "run_save_ch2_boss_room")
	check(ch2_run._boss is LungBellGuardian, "run_save_ch2_boss_scene")
	ch2_run._boss_defeated = true
	if ch2_run._boss != null and is_instance_valid(ch2_run._boss):
		ch2_run._boss.queue_free()
		ch2_run._boss = null
	ch2_run.run_state.authority = null
	ch2_run._grant_chapter_authority.call_deferred()
	await create_timer(1.6).timeout
	check(ch2_run._authority_choice.is_open(), "run_save_ch2_authority_opens")
	check(not ch2_run.hud.visible, "run_save_ch2_authority_hides_hud")
	if ch2_run._authority_choice.is_open():
		ch2_run._authority_choice._choose(0)
	await create_timer(0.3).timeout
	check(ch2_run.run_state.authority != null, "run_save_ch2_authority_granted")
	var ch2_authority: StringName = ch2_run.run_state.authority.id
	var ch2_pool_ids: Array[StringName] = []
	for entry in ch2_run._chapter_plan.authority_pool:
		ch2_pool_ids.append(entry.id)
	check(ch2_pool_ids.has(ch2_authority), "run_save_ch2_authority_from_plan_pool")
	var ch2_pages: int = ch2_run.run_state.pages
	var ch2_kills: int = ch2_run._kills
	check(ch2_run.save_run_now(), "run_save_ch2_checkpoint")
	var ch2_saved := RunSave.read(RUN_PATH)
	check(int(ch2_saved.get("run", {}).get("chapter", -1)) == 1,
		"run_save_ch2_saved_chapter")
	check(bool(ch2_saved.get("world", {}).get("boss_defeated", false)),
		"run_save_ch2_saved_boss")
	check(String(ch2_saved.get("authority", {}).get("id", "")) == String(ch2_authority),
		"run_save_ch2_saved_authority")
	check(int(ch2_saved.get("authority", {}).get("chapter", -1)) == 1,
		"run_save_ch2_saved_authority_chapter")
	await _free_scene(ch2_run)

	flow.resume_requested = true
	var ch2_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(ch2_resume)
	current_scene = ch2_resume
	check(await _wait_mds(ch2_resume), "run_save_ch2_resume_boots")
	check(ch2_resume._chapter == 1, "run_save_ch2_resume_chapter")
	check(ch2_resume._mds_world.current_room == "ch2_boss",
		"run_save_ch2_resume_room")
	check(ch2_resume._boss == null, "run_save_ch2_resume_no_second_boss")
	check(ch2_resume._boss_defeated, "run_save_ch2_resume_boss_flag")
	var ch2_objective := ch2_resume.hud.find_child("Objective", true, false) as Label
	check(ch2_objective != null and ch2_objective.text == "肺钟守卫已经倒下",
		"run_save_ch2_resume_objective_uses_ch2_boss")
	check(ch2_resume.run_state.authority != null
		and ch2_resume.run_state.authority.id == ch2_authority,
		"run_save_ch2_resume_authority")
	check(ch2_resume.run_state.pages == ch2_pages,
		"run_save_ch2_resume_pages_no_duplicate")
	check(ch2_resume._kills == ch2_kills, "run_save_ch2_resume_kills_no_duplicate")
	await create_timer(0.6).timeout
	check(not ch2_resume._authority_choice.is_open(),
		"run_save_ch2_resume_authority_not_reopened")
	check(ch2_resume._story.is_open(), "run_save_ch2_resume_outro")
	_close_story(ch2_resume)
	await create_timer(0.5).timeout
	check(ch2_resume._story.is_open() and ch2_resume._story._choice_mode,
		"run_save_ch2_resume_choice")
	if ch2_resume._story.is_open() and ch2_resume._story._choice_mode:
		ch2_resume._story.choose(0)
	await create_timer(1.2).timeout
	# Pass 80: the Chapter 2 choice hands off into Chapter 3 instead of ending
	# the campaign. The last safe checkpoint stays the Chapter 2 boss room until
	# the Chapter 3 entrance loads and writes the new one.
	check(ch2_resume._chapter == 2, "run_save_ch2_resume_enters_chapter_3")
	check(not ch2_resume._finished, "run_save_ch2_resume_does_not_finish")
	check(ch2_resume._story.is_open() and not ch2_resume._story._choice_mode,
		"run_save_ch2_resume_opens_chapter_3_intro")
	check(not ch2_resume.ending_screen.visible, "run_save_ch2_resume_no_end_screen")
	check(FileAccess.file_exists(RUN_PATH), "run_save_ch2_resume_keeps_checkpoint")
	var boundary_save := RunSave.read(RUN_PATH)
	check(int(boundary_save.get("run", {}).get("chapter", -1)) == 1,
		"run_save_ch2_resume_checkpoint_still_chapter_2")
	# Closing the Chapter 3 intro loads the big-map entry and moves the
	# checkpoint into the new chapter.
	_close_story(ch2_resume)
	await create_timer(1.0).timeout
	check(await _wait_mds(ch2_resume), "run_save_ch2_resume_chapter_3_boots")
	check(ch2_resume._mds_world.current_room == "ch3_entry",
		"run_save_ch2_resume_chapter_3_room")
	var chapter_3_saved := RunSave.read(RUN_PATH)
	check(int(chapter_3_saved.get("run", {}).get("chapter", -1)) == 2,
		"run_save_ch2_resume_checkpoint_chapter_3")
	check(String(chapter_3_saved.get("run", {}).get("room", "")) == "ch3_entry",
		"run_save_ch2_resume_checkpoint_entry")
	await _free_scene(ch2_resume)

	# --- Chapter 2 boss checkpoint written before its authority pick, with the
	# Chapter 1 authority still in hand (the real-play case: every chapter boss
	# hands out a pick). The boss-death save is written first, so resuming must
	# offer this chapter's pick again instead of mistaking the carried-over
	# authority for an already-spent one. ---
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	var ch2_owed = load("res://scenes/main.tscn").instantiate()
	root.add_child(ch2_owed)
	current_scene = ch2_owed
	await create_timer(0.4).timeout
	_close_story(ch2_owed)
	check(await _wait_mds(ch2_owed), "run_save_ch2_owed_boots")
	ch2_owed._finished = false
	ch2_owed._ending_pending = false
	ch2_owed.ending_screen.visible = false
	paused = false
	ch2_owed._start_chapter(1)
	await create_timer(0.3).timeout
	_close_story(ch2_owed)
	await process_frame
	check(await _wait_mds(ch2_owed), "run_save_ch2_owed_region_world")
	await ch2_owed._mds_world.load_room("ch2_boss")
	check(await _wait_room(ch2_owed, "ch2_boss"), "run_save_ch2_owed_boss_room")
	var ch1_authority := ContentLibrary.authority_by_id(&"revive")
	check(ch1_authority != null, "run_save_ch2_owed_authority_resource")
	ch2_owed._authority.apply(ch1_authority, ch2_owed.run_state)
	ch2_owed._authority_granted_chapter = 0
	ch2_owed._boss_defeated = true
	check(ch2_owed.save_run_now(), "run_save_ch2_owed_checkpoint")
	var owed_saved := RunSave.read(RUN_PATH)
	check(int(owed_saved.get("run", {}).get("chapter", -1)) == 1,
		"run_save_ch2_owed_saved_chapter")
	check(bool(owed_saved.get("world", {}).get("boss_defeated", false)),
		"run_save_ch2_owed_saved_boss")
	check(String(owed_saved.get("authority", {}).get("id", "")) == "revive",
		"run_save_ch2_owed_saved_authority")
	check(int(owed_saved.get("authority", {}).get("chapter", -1)) == 0,
		"run_save_ch2_owed_saved_authority_chapter")
	await _free_scene(ch2_owed)

	flow.resume_requested = true
	var ch2_owed_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(ch2_owed_resume)
	current_scene = ch2_owed_resume
	check(await _wait_mds(ch2_owed_resume), "run_save_ch2_owed_resume_boots")
	check(ch2_owed_resume._chapter == 1, "run_save_ch2_owed_resume_chapter")
	check(ch2_owed_resume._mds_world.current_room == "ch2_boss",
		"run_save_ch2_owed_resume_room")
	check(ch2_owed_resume._boss == null, "run_save_ch2_owed_resume_no_second_boss")
	await create_timer(2.0).timeout
	check(ch2_owed_resume._authority_choice.is_open(),
		"run_save_ch2_owed_authority_reoffered")
	check(not ch2_owed_resume._story.is_open(),
		"run_save_ch2_owed_outro_waits_for_pick")
	if ch2_owed_resume._authority_choice.is_open():
		ch2_owed_resume._authority_choice._choose(0)
	await create_timer(0.4).timeout
	check(ch2_owed_resume.run_state.authority != null,
		"run_save_ch2_owed_authority_granted")
	check(ch2_owed_resume._story.is_open(), "run_save_ch2_owed_outro_opens")
	await _free_scene(ch2_owed_resume)

	# --- Pre-pass-83 checkpoints carry no `authority.chapter` key. A Chapter 2
	# boss checkpoint that already holds a picked authority must keep it and go
	# straight to the outro. The legacy default is the chapter saved in the file
	# (restore runs before `_start_chapter` applies it to `_chapter`). ---
	var legacy_ch2_save: Dictionary = owed_saved.duplicate(true)
	legacy_ch2_save["authority"]["id"] = "revive"
	legacy_ch2_save["authority"].erase("chapter")
	check(RunSave.write(legacy_ch2_save, RUN_PATH), "run_save_legacy_ch2_save_written")
	flow.resume_requested = true
	var legacy_ch2_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(legacy_ch2_resume)
	current_scene = legacy_ch2_resume
	check(await _wait_mds(legacy_ch2_resume), "run_save_legacy_ch2_boots")
	check(legacy_ch2_resume._chapter == 1, "run_save_legacy_ch2_chapter")
	check(legacy_ch2_resume._mds_world.current_room == "ch2_boss", "run_save_legacy_ch2_room")
	check(legacy_ch2_resume.run_state.authority != null
		and legacy_ch2_resume.run_state.authority.id == &"revive",
		"run_save_legacy_ch2_authority")
	await create_timer(2.0).timeout
	check(not legacy_ch2_resume._authority_choice.is_open(),
		"run_save_legacy_ch2_authority_not_reopened")
	check(legacy_ch2_resume._story.is_open(), "run_save_legacy_ch2_outro_opens")
	await _free_scene(legacy_ch2_resume)

	# --- 不朽档案's revive is once per run, not once per session. Spending it
	# and then checkpointing used to boot the resume with the relic re-armed
	# (`revive_used` lived only on RelicEffects), so a second death in the same
	# run was saved again for free. ---
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	flow.profile.archived_item.clear()
	flow.profile.stored_relics.clear()
	flow.profile.pending_run_bonuses.clear()
	var revive_first = load("res://scenes/main.tscn").instantiate()
	root.add_child(revive_first)
	current_scene = revive_first
	await create_timer(0.4).timeout
	_close_story(revive_first)
	check(await _wait_mds(revive_first), "run_save_revive_boots")
	var revive_relic := ContentLibrary.relic_by_id(&"immortal_archive")
	check(revive_relic != null, "run_save_revive_relic_exists")
	if revive_relic != null:
		revive_first.run_state.inventory.add_relic(revive_relic)
	revive_first.relic_effects.revive_used = false
	check(await _wait_vulnerable(revive_first), "run_save_revive_vulnerable_before_first_death")
	revive_first.player.health = 1
	revive_first.player.take_damage(5)
	check(revive_first.player.health == 40, "run_save_revive_first_heals_40")
	check(revive_first.relic_effects.revive_used, "run_save_revive_first_marks_used")
	check(await _wait_vulnerable(revive_first), "run_save_revive_vulnerable_after_first")
	check(revive_first.save_run_now(), "run_save_revive_checkpoint")
	var revive_saved := RunSave.read(RUN_PATH)
	check(bool(revive_saved.get("world", {}).get("relic_revive_used", false)),
		"run_save_revive_checkpoint_carries_flag")
	var revive_health: int = revive_first.player.health
	await _free_scene(revive_first)

	flow.resume_requested = true
	var revive_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(revive_resume)
	current_scene = revive_resume
	await create_timer(0.4).timeout
	_close_story(revive_resume)
	check(await _wait_mds(revive_resume), "run_save_revive_resume_boots")
	check(revive_resume.player.health == revive_health, "run_save_revive_resume_health")
	check(revive_resume.relic_effects.revive_used, "run_save_revive_resume_flag_restored")
	check(await _wait_vulnerable(revive_resume), "run_save_revive_vulnerable_before_second")
	revive_resume.player.health = 1
	revive_resume.player.take_damage(5)
	check(revive_resume.player.health == 0, "run_save_revive_second_death_is_final")
	await _free_scene(revive_resume)

	# A checkpoint written before the key existed carries no flag and must keep
	# loading; the in-memory default is unspent, which is the old behaviour.
	flow.resume_requested = false
	var legacy_revive = load("res://scenes/main.tscn").instantiate()
	root.add_child(legacy_revive)
	current_scene = legacy_revive
	await create_timer(0.4).timeout
	_close_story(legacy_revive)
	check(await _wait_mds(legacy_revive), "run_save_legacy_revive_boots")
	legacy_revive.run_state.inventory.add_relic(revive_relic)
	check(legacy_revive.save_run_now(), "run_save_legacy_revive_checkpoint")
	var legacy_revive_save := RunSave.read(RUN_PATH)
	legacy_revive_save["world"].erase("relic_revive_used")
	check(RunSave.write(legacy_revive_save, RUN_PATH), "run_save_legacy_revive_written")
	await _free_scene(legacy_revive)
	flow.resume_requested = true
	var legacy_revive_resume = load("res://scenes/main.tscn").instantiate()
	root.add_child(legacy_revive_resume)
	current_scene = legacy_revive_resume
	await create_timer(0.4).timeout
	_close_story(legacy_revive_resume)
	check(await _wait_mds(legacy_revive_resume), "run_save_legacy_revive_resume_boots")
	check(not legacy_revive_resume.relic_effects.revive_used,
		"run_save_legacy_revive_defaults_unspent")
	await _free_scene(legacy_revive_resume)

	_cleanup_files()
	print("RUN SAVE INTEGRATION: %d checks, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
