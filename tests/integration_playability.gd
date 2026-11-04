extends SceneTree
var failures: int = 0
var assertions: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("INTEGRATION FAIL: " + label)

func _wait_room_id(mds, room_id: String, timeout := 5.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if not mds.changing_room and mds.current_room == room_id:
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _wait_mds(scene, timeout := 8.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._mds_world != null and not scene._mds_world.changing_room and not scene._mds_world.current_room.is_empty():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _test_mds_chapter(scene, chapter_index: int) -> void:
	var mds = scene._mds_world
	var prefix := "ch%d" % (chapter_index + 1)
	check(mds.current_room == "%s_01" % prefix, "chapter_%d_mds_starts" % (chapter_index + 1))
	if chapter_index == 3:
		# Chapter 4 art audit: the MDS rooms must keep using the dedicated
		# painting, with TheaterBackdrop only adding its light overlay.
		var art := mds.room_node.get_node_or_null("BackgroundArt") as Sprite2D
		check(art != null and art.texture != null
			and art.texture.resource_path.ends_with("smiling_theater.png"),
			"chapter_4_background_uses_painting")
		var theater := mds.room_node.get_node_or_null("TheaterBackdrop") as TheaterBackdrop
		check(theater != null and theater.generated_art, "chapter_4_theater_overlay_is_lightweight")
	scene._map_overlay.open()
	check(scene._map_overlay.is_open(), "chapter_%d_map_opens" % (chapter_index + 1))
	check(scene._map_overlay.map_view.is_room_revealed("%s_01" % prefix), "chapter_%d_map_reveals_start" % (chapter_index + 1))
	scene._map_overlay.close()
	for room_index in 6:
		var expected := "%s_%02d" % [prefix, room_index + 1]
		if room_index > 0 and mds.current_room != expected:
			await mds.load_room(expected)
		check(mds.current_room == expected, "chapter_%d_room_%d_loaded" % [chapter_index, room_index])
		var arena := mds.room_node.get_node_or_null("Arena") as ArenaRoom
		check(arena != null, "chapter_%d_room_%d_has_arena" % [chapter_index, room_index])
		if arena == null:
			continue
		if chapter_index == 0 and room_index == 4:
			# Chapter 1 demo event room: no fight, a two-way choice instead.
			await create_timer(1.0).timeout
			check(scene._story.is_open(), "chapter_1_event_choice_opens")
			scene._story.choose(0)
			await create_timer(0.3).timeout
			check(scene._mds_cleared_rooms.has(expected), "chapter_1_event_marks_cleared")
			continue
		scene.player.global_position = arena.global_position
		scene._update_room_locks()
		check(arena.is_locked(), "chapter_%d_room_%d_locks" % [chapter_index, room_index])
		for attempt in 4:
			for enemy in arena.get_node("Enemies").get_children():
				if enemy is Enemy and not enemy.dead:
					enemy.take_damage(100000)
			await create_timer(0.4).timeout
			if arena.is_cleared():
				break
		check(arena.is_cleared(), "chapter_%d_room_%d_clears" % [chapter_index, room_index])
		check(scene._reward_ui.visible, "chapter_%d_room_%d_reward" % [chapter_index, room_index])
		scene._reward_ui._choose(0)
		await process_frame
		if room_index == 0:
			# Exercise a real MDS gate, not only programmatic room loads.
			var gate := MDSGate.find_gate(mds.room_node, "right1")
			check(gate != null, "chapter_%d_right_gate_present" % (chapter_index + 1))
			if gate != null:
				gate.use()
				check(await _wait_room_id(mds, "%s_02" % prefix), "chapter_%d_gate_transition" % (chapter_index + 1))
		if room_index == 2:
			# The hidden vault is optional: enter, see two rewards, come back.
			var vault_gate := MDSGate.find_gate(mds.room_node, "door1")
			check(vault_gate != null, "chapter_%d_vault_door_present" % (chapter_index + 1))
			if vault_gate != null:
				await create_timer(0.4).timeout
				vault_gate.use()
				check(await _wait_room_id(mds, "%s_vault" % prefix), "chapter_%d_vault_reached" % (chapter_index + 1))
				check(scene._chests.size() >= 1, "chapter_%d_vault_has_chest" % (chapter_index + 1))
				check(scene._steles.size() >= 1, "chapter_%d_vault_has_stele" % (chapter_index + 1))
				var vault_back := MDSGate.find_gate(mds.room_node, "door1")
				check(vault_back != null, "chapter_%d_vault_return_present" % (chapter_index + 1))
				if vault_back != null:
					await create_timer(0.4).timeout
					vault_back.use()
					check(await _wait_room_id(mds, expected), "chapter_%d_vault_return" % (chapter_index + 1))
	check(scene._cleared_in_chapter == 6, "chapter_%d_six_rooms_cleared" % (chapter_index + 1))
	await mds.load_room("%s_rest" % prefix)
	check(mds.current_room == "%s_rest" % prefix, "chapter_%d_rest_room_reached" % (chapter_index + 1))
	check(scene._shops.size() == 1, "chapter_%d_rest_room_has_shop" % (chapter_index + 1))
	check(scene._steles.size() == 1, "chapter_%d_rest_room_has_stele" % (chapter_index + 1))
	var shortcut := MDSGate.find_gate(mds.room_node, "door2")
	check(shortcut != null, "chapter_%d_shortcut_present" % (chapter_index + 1))
	if shortcut != null:
		await create_timer(0.4).timeout
		shortcut.use()
		check(await _wait_room_id(mds, "%s_02" % prefix), "chapter_%d_shortcut_reached" % (chapter_index + 1))
		await mds.load_room("%s_rest" % prefix)
		check(mds.current_room == "%s_rest" % prefix, "chapter_%d_shortcut_back_to_rest" % (chapter_index + 1))
	if not scene._shops.is_empty():
		check(scene._shops[0].shop_id == StringName("ch%d_rest_shop" % (chapter_index + 1)), "chapter_%d_shop_id" % (chapter_index + 1))
	await mds.load_room("%s_boss" % prefix)
	check(mds.current_room == "%s_boss" % prefix, "chapter_%d_boss_room_reached" % (chapter_index + 1))
	var boss_arena := mds.room_node.get_node_or_null("Arena") as ArenaRoom
	check(boss_arena != null, "chapter_%d_boss_arena_present" % (chapter_index + 1))
	check(is_instance_valid(scene._boss) and not scene._boss.dead, "chapter_%d_boss_spawned" % (chapter_index + 1))
	if boss_arena != null:
		scene.player.global_position = boss_arena.global_position
		scene._update_room_locks()
		check(boss_arena.is_locked(), "chapter_%d_boss_room_locks" % (chapter_index + 1))
		scene.player._invulnerable_left = 100
		scene._boss.take_damage(100000)
		await process_frame
		if chapter_index == 0:
			await create_timer(1.5).timeout
			check(scene._authority_choice.visible, "chapter_1_authority_choice_opens")
			scene._authority_choice._choose(0)
			await create_timer(0.4).timeout
			check(scene.run_state.authority != null, "chapter_1_authority_applied")
	check(scene._story.is_open(), "chapter_%d_outro" % (chapter_index + 1))
	scene._story.close()
	await process_frame
	check(scene._story.is_open(), "chapter_%d_choice" % (chapter_index + 1))
	scene._story.choose(0)
	await create_timer(0.35).timeout
	if chapter_index == 0:
		await create_timer(0.8).timeout
		check(scene._finished, "chapter_1_demo_ends")
		check(scene.ending_screen.visible, "chapter_1_demo_end_screen")
	elif chapter_index + 1 < CampaignData.chapter_count():
		check(scene._chapter == chapter_index + 1, "chapter_%d_transitions" % (chapter_index + 1))

func _run() -> void:
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.difficulty = 2
	flow.profile.archive_levels = {"vitality": 2, "ink": 1, "damage": 1, "ward": 1}
	if OS.get_cmdline_user_args().has("--expect-packed"):
		check(not FileAccess.file_exists("res://tests/run_tests.gd"), "tests excluded from mounted export package")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await physics_frame
	check(scene._chapters.size() == 4, "campaign_has_four_chapters")
	check(scene._story.is_open(), "chapter_intro_is_visible")
	var audio := root.get_node("Audio") as AudioManager
	print("AUDIO STATE current=", audio._current_music, " playing=", audio._music.playing if audio._music != null else "null")
	check(audio._music.playing, "chapter_music_plays")
	check(audio._voice.playing, "chapter_voice_plays")
	scene._story.close()
	await process_frame
	check(not scene._ending_pending, "first_chapter_becomes_playable")
	check(scene._mds_active, "chapter_1_uses_mds")
	check(await _wait_mds(scene), "mds_first_room_loads")
	check(scene._mds_world.current_room == "ch1_01", "mds_starts_in_first_room")
	check(scene._rooms.size() == 1, "mds_current_room_registered")
	check(scene.player.max_health >= 120, "archive_vitality_applies")
	check(scene.run_state.max_ink >= 105, "archive_ink_applies")
	check(is_equal_approx(scene._archive_damage_multiplier, 1.04), "archive_damage_applies")
	check(
		is_equal_approx(scene.run_state.corruption_gain_multiplier, Difficulty.corruption_multiplier(2) / 1.02),
		"archive_ward_applies"
	)
	check(scene.hud.region_label.text.contains("深渊"), "difficulty_shown")
	var first_arena: ArenaRoom = scene._mds_world.room_node.get_node("Arena")
	var scaled_enemy := false
	for enemy in first_arena.get_node("Enemies").get_children():
		if enemy is Enemy and enemy.data != null and enemy.data.max_health > 22:
			scaled_enemy = true
	check(scaled_enemy, "difficulty_scales_enemy_health")
	check(scene._chests.is_empty(), "mds_room_1_has_no_chest")
	check(scene.run_state.inventory.relics.is_empty(), "no_unearned_relics_at_spawn")
	check(not scene._rooms[0].is_locked(), "mds_spawn_does_not_lock_before_entry")

	var starter: WeaponData = scene.run_state.inventory.weapons[0]
	var candidate := preload("res://resources/weapons/miasma_bow.tres") as WeaponData
	scene._acquire_weapon(candidate)
	check(scene.run_state.inventory.weapons[0] == candidate, "weapon_reward_equips")
	check(scene.player.weapons[0].data == candidate, "weapon_reward_reaches_player")
	var dropped: Pickup = null
	for child in scene.get_children():
		if child is Pickup and child.kind == &"weapon" and child.resource == starter:
			dropped = child
	check(dropped != null, "previous_weapon_drops_instead_of_vanishing")
	scene.player.global_position = dropped.global_position
	dropped._on_body_entered(scene.player)
	check(scene._try_pickup_nearest(), "weapon_pickup_needs_interact")
	await process_frame
	check(scene.run_state.inventory.weapons[0] == starter, "dropped_weapon_can_be_picked_back")

	# Corruption 100 is a survivable 30-second frenzy, not an instant loss.
	var base_max: int = scene.player.max_health
	scene.run_state.corruption = 99
	scene.run_state.add_corruption(1)
	check(scene._frenzy_active, "corruption_100_starts_frenzy")
	check(scene.player.max_health < base_max, "frenzy_reduces_max_health")
	check(scene.player.health <= scene.player.max_health, "frenzy_health_clamped")
	scene._frenzy_left = 0.01
	scene._update_corruption_frenzy(0.02)
	check(not scene._frenzy_active, "frenzy_ends_after_duration")
	check(scene.player.max_health == base_max, "frenzy_restores_max_health")
	check(scene.run_state.corruption < 100, "frenzy_drops_corruption")
	scene.run_state.set_corruption(0)
	scene._apply_corruption_penalties()

	for chapter_index in CampaignData.chapter_count():
		if chapter_index > 0:
			# The demo stops after Chapter 1; start the remaining chapters
			# explicitly for structural coverage.
			scene._finished = false
			scene._ending_pending = false
			scene.ending_screen.visible = false
			scene.get_tree().paused = false
			scene._start_chapter(chapter_index)
			await create_timer(0.2).timeout
			check(scene._story.is_open(), "chapter_%d_intro" % (chapter_index + 1))
			scene._story.close()
			await process_frame
			check(await _wait_mds(scene), "chapter_%d_mds_loads" % (chapter_index + 1))
		check(scene._chapter == chapter_index, "chapter_index_%d" % chapter_index)
		await _test_mds_chapter(scene, chapter_index)
	await create_timer(1.0).timeout
	check(scene._finished, "campaign_reaches_ending")
	check(scene.ending_screen.visible, "ending_screen_visible")
	check(flow.last_ending.get("id", &"") == &"restored", "merciful_run_reaches_restored_ending")
	paused = false
	root.remove_child(scene)
	scene.free()
	if audio._music != null:
		audio._music.stop()
		audio._music.stream = null
	if audio._voice != null:
		audio._voice.stop()
		audio._voice.stream = null
	print("INTEGRATION: %d checks, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
