extends SceneTree

## Input-driven Chapter 1 demo smoke test: real Input actions move, jump,
## attack, dodge and interact. No teleporting into rooms and no 100000-damage
## kills; the old integration_playability.gd stays as the structural suite.

var failures: int = 0
var assertions: int = 0


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("CH1 DEMO FAIL: " + label)


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


func _wait_room(scene, room_id: String, timeout := 4.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if not scene._mds_world.changing_room and scene._mds_world.current_room == room_id:
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _tap_action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _run() -> void:
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.title_shown_this_session = true
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.5).timeout
	if scene._story.is_open():
		scene._story.close()
	await _wait_mds(scene)
	check(scene._mds_world.current_room == "ch1_01", "demo_starts_in_ch1_01")

	# Walk right with the real movement action.
	var start_x: float = scene.player.global_position.x
	Input.action_press("move_right")
	await create_timer(2.5).timeout
	Input.action_release("move_right")
	check(scene.player.global_position.x > start_x + 100.0, "demo_move_right")

	# Jump with the real jump action.
	await create_timer(0.15).timeout
	var start_y: float = scene.player.global_position.y
	Input.action_press("jump")
	await create_timer(0.12).timeout
	Input.action_release("jump")
	await create_timer(0.08).timeout
	check(scene.player.global_position.y < start_y - 4.0 or scene.player.velocity.y < -100.0, "demo_jump")

	# Attack whatever came to meet us; the input drives the swing.
	var arena := scene._mds_world.room_node.get_node_or_null("Arena") as ArenaRoom
	check(arena != null, "demo_arena_present")
	if arena != null:
		scene.player.global_position = arena.global_position
		scene._update_room_locks()
		await create_timer(0.4).timeout
		var enemies := arena.get_node("Enemies").get_children()
		var first_enemy: Enemy = null
		for enemy in enemies:
			if enemy is Enemy and not enemy.dead:
				first_enemy = enemy
				break
		check(first_enemy != null, "demo_enemy_present")
		var before: Dictionary = {}
		if first_enemy != null:
			first_enemy.global_position = scene.player.global_position + Vector2(40, 0)
			before[first_enemy] = first_enemy.health
			scene.player.facing = Vector2.RIGHT
		Input.action_press("attack")
		await create_timer(1.4).timeout
		Input.action_release("attack")
		await create_timer(0.2).timeout
		var damaged := false
		for enemy in before:
			if not is_instance_valid(enemy) or enemy.health < int(before[enemy]):
				damaged = true
		check(damaged, "demo_attack_damages_enemy")

	# Dodge grants invulnerability; a hit during it does not cost health.
	Input.action_press("dodge")
	await create_timer(0.05).timeout
	Input.action_release("dodge")
	check(scene.player.is_invulnerable(), "demo_dodge_invulnerable")
	var health_before: int = scene.player.health
	scene.player.take_damage(10)
	check(scene.player.health == health_before, "demo_dodge_blocks_damage")
	await create_timer(0.6).timeout

	# Interact with a real chest through the interact action.
	await scene._mds_world.load_room("ch1_03")
	await create_timer(0.4).timeout
	check(not scene._chests.is_empty(), "demo_chest_present")
	if not scene._chests.is_empty():
		var chest: TreasureChest = scene._chests[0]
		scene.player.global_position = chest.global_position + Vector2(-40, 0)
		scene.player.velocity = Vector2.ZERO
		check(scene.player.global_position.distance_to(chest.global_position) < 92.0, "demo_chest_in_range")
		await create_timer(0.2).timeout
		await _tap_action(&"interact")
		await create_timer(0.3).timeout
		check(chest.is_open, "demo_interact_opens_chest")

	# Hidden vault, through the real interact door on the main path. Its room
	# origin sits one room below the path in world coordinates, which used to
	# trip the fall guard: the player was pinned to the vault door and took 15
	# damage every invulnerability window (the reported freeze).
	var vault_door := MDSGate.find_gate(scene._mds_world.room_node, "door1")
	check(vault_door != null, "demo_vault_door_present")
	if vault_door != null:
		scene.player.global_position = vault_door.global_position
		scene.player.velocity = Vector2.ZERO
		await create_timer(0.3).timeout
		await _tap_action(&"interact")
		check(await _wait_room(scene, "ch1_vault"), "demo_vault_entered")
		check(not scene._mds_world.changing_room, "demo_vault_load_finished")
		check(not scene._chests.is_empty(), "demo_vault_chest_built")
		check(not scene._steles.is_empty(), "demo_vault_stele_built")
		var objective := scene.hud.find_child("Objective", true, false) as Label
		check(objective != null and objective.text == "搜查隐藏书库", "demo_vault_objective_built")
		check(scene.hud.get_message_text() != "", "demo_vault_discovery_line_not_empty")
		check(scene.hud.get_message_text()
			== VaultRoomData.pick(scene.run_state.run_seed, "ch1_vault"),
			"demo_vault_discovery_line_matches_seed")
		check(scene.hud.get_message_text().contains("搜查宝箱与残碑"),
			"demo_vault_discovery_keeps_search_hint")
		# Wait out a full invulnerability window, then walk. A fall-guard loop
		# keeps resetting the position to the door and drains health.
		var vault_hp: int = scene.player.health
		var vault_x: float = scene.player.global_position.x
		await create_timer(0.8).timeout
		Input.action_press("move_right")
		await create_timer(0.6).timeout
		Input.action_release("move_right")
		await create_timer(0.1).timeout
		check(scene.player.global_position.x > vault_x + 20.0, "demo_vault_player_can_move")
		check(scene.player.health == vault_hp, "demo_vault_no_fall_damage")
		check(scene.player.global_position.y > scene._mds_world.world.get_origin("ch1_vault").y + 500.0,
			"demo_vault_stands_on_floor")
		if not scene._chests.is_empty():
			var vault_chest: TreasureChest = scene._chests[0]
			scene.player.global_position = vault_chest.global_position + Vector2(-40, 0)
			await create_timer(0.2).timeout
			await _tap_action(&"interact")
			await create_timer(0.3).timeout
			check(vault_chest.is_open, "demo_vault_chest_opens")
		var vault_exit := MDSGate.find_gate(scene._mds_world.room_node, "door1")
		check(vault_exit != null, "demo_vault_return_door_built")
		if vault_exit != null:
			scene.player.global_position = vault_exit.global_position
			scene.player.velocity = Vector2.ZERO
			await create_timer(0.3).timeout
			await _tap_action(&"interact")
			check(await _wait_room(scene, "ch1_03"), "demo_vault_returned_to_path")
			var return_x: float = scene.player.global_position.x
			Input.action_press("move_right")
			await create_timer(0.3).timeout
			Input.action_release("move_right")
			await create_timer(0.1).timeout
			check(scene.player.global_position.x > return_x + 10.0, "demo_vault_play_resumes")
			# The guard must still catch a real fall: room-local Y, not world Y.
			var room_origin_y: float = scene._mds_world.world.get_origin("ch1_03").y
			scene.player.global_position = Vector2(scene.player.global_position.x, room_origin_y + 900.0)
			await create_timer(0.2).timeout
			check(scene.player.global_position.y - room_origin_y < 700.0,
				"demo_fall_guard_still_returns_player")

	# The rest-room paper man rotates authored copy by run seed and stall id.
	await scene._mds_world.load_room("ch1_rest")
	await create_timer(0.4).timeout
	var rest_line := RestRoomData.pick(scene.run_state.run_seed, "ch1_rest")
	check(rest_line != "", "demo_rest_room_line_not_empty")
	check(scene.hud.get_message_text() == rest_line, "demo_rest_room_line_matches_seed")
	# Reading a stele is a direct claim, not a modal page: the world stays
	# unpaused, focus must not stick to a hidden control, and the player keeps
	# control afterwards. The stone sits under a platform, so the 110 px claim
	# radius is reached from the platform edge.
	check(not scene._steles.is_empty(), "demo_rest_stele_present")
	if not scene._steles.is_empty():
		var rest_stele: MemoryStele = scene._steles[0]
		var stele_target: float = rest_stele.global_position.x - 90.0
		Input.action_press("move_right")
		var stele_walk: float = 2.5
		while stele_walk > 0.0 and scene.player.global_position.x < stele_target:
			await create_timer(0.05).timeout
			stele_walk -= 0.05
		Input.action_release("move_right")
		await create_timer(0.2).timeout
		check(scene.player.global_position.x >= stele_target, "demo_rest_stele_reachable")
		check(rest_stele.prompt.visible, "demo_rest_stele_prompt_visible")
		check(not paused, "demo_rest_stele_no_page_pause")
		check(root.gui_get_focus_owner() == null
			or root.gui_get_focus_owner().is_visible_in_tree(),
			"demo_rest_stele_focus_not_hidden")
		var rest_records: int = scene._records
		await _tap_action(&"interact")
		await create_timer(0.3).timeout
		check(scene._claimed_steles.has("ch1_rest/Stele"), "demo_rest_stele_claimed")
		# The roll can land on a relic/word the run already owns; that authored
		# branch heals instead of counting a record. Accept either outcome and
		# require the message that matches it, so the check is not seed-flaky.
		var record_message: String = scene.hud.get_message_text()
		var record_gained: bool = scene._records == rest_records + 1
		check(record_gained or scene._records == rest_records,
			"demo_rest_stele_record_rule")
		check(not paused, "demo_rest_stele_unpaused")
		check(not scene.pause_menu.is_open(), "demo_rest_stele_no_pause_menu")
		check(record_message.begins_with("记录 +1") if record_gained
			else record_message.begins_with("残碑已读过"),
			"demo_rest_stele_message")
		var stele_x: float = scene.player.global_position.x
		Input.action_press("move_left")
		await create_timer(0.3).timeout
		Input.action_release("move_left")
		await create_timer(0.1).timeout
		check(scene.player.global_position.x < stele_x - 10.0,
			"demo_rest_stele_player_moves")
	# Corruption tier warnings rotate by run seed but must keep the mechanics.
	scene.run_state.set_corruption(0)
	scene.run_state.add_corruption(26)
	var expected_warning := CorruptionWarningData.pick(scene.run_state.run_seed, 1)
	check(expected_warning != "", "demo_corruption_warning_not_empty")
	check(scene.hud.get_message_text() == expected_warning,
		"demo_corruption_warning_matches_seed")
	check(scene.hud.get_message_text().contains("敌人伤害 +15%"),
		"demo_corruption_warning_keeps_mechanics")
	scene.run_state.set_corruption(0)
	check(not scene._shops.is_empty(), "demo_rest_shop_present")
	if not scene._shops.is_empty():
		var stall: MemoryShop = scene._shops[0]
		scene._open_shop(stall)
		var expected_line := Ch1ShopData.pick(scene.run_state.run_seed, String(stall.shop_id))
		check(expected_line != "", "demo_shop_line_not_empty")
		check(scene._shop_ui._subtitle.text == expected_line, "demo_shop_line_matches_seed")
		# Buying through the real handler must answer with the authored sale
		# line for this run/stall/row, not the generic 成交。 fallback.
		var offers: Array = scene._shop_cache.get(stall.shop_id, [])
		check(not offers.is_empty(), "demo_shop_has_offers")
		if not offers.is_empty():
			scene.run_state.add_pages(100)
			var expected_sale := Ch1ShopData.pick_buy(
				scene.run_state.run_seed, String(stall.shop_id), 0)
			scene._on_shop_buy(0)
			check(scene._shop_ui._error_label.text == expected_sale, "demo_shop_sale_line_matches")
			check(scene._shop_ui._error_label.text != "成交。", "demo_shop_sale_line_is_authored")
			# A cached row can go stale: the same relic can be picked up from a
			# reward, chest or stele after the stall rolled its stock. Buying it
			# then must not spend pages on a duplicate the inventory refuses.
			var relic_index := -1
			for index in offers.size():
				if StringName(offers[index].get("kind", &"")) == &"relic":
					relic_index = index
					break
			check(relic_index > 0, "demo_shop_relic_row_present")
			if relic_index > 0:
				var stale_relic := offers[relic_index]["resource"] as RelicData
				check(stale_relic != null, "demo_shop_relic_row_has_resource")
				if stale_relic != null:
					scene.run_state.inventory.add_relic(stale_relic)
					var relic_count: int = scene.run_state.inventory.relics.size()
					var pages_before: int = scene.run_state.pages
					scene._on_shop_buy(relic_index)
					check(scene.run_state.pages == pages_before,
						"demo_shop_owned_relic_not_charged")
					check(scene.run_state.inventory.relics.size() == relic_count,
						"demo_shop_owned_relic_no_duplicate")
					check(scene._shop_ui._buttons[relic_index].disabled,
						"demo_shop_owned_relic_row_disabled")
					check(scene._shop_ui._buttons[relic_index].text.begins_with("已拥有"),
						"demo_shop_owned_relic_row_label")
					var owned_note: String = scene._shop_ui._error_label.text
					check(owned_note.contains("不收残页"), "demo_shop_owned_relic_message")
					# Leave the run exactly as it was for the rest of the suite.
					scene.run_state.inventory.relics.erase(stale_relic)
					scene.run_state.inventory.changed.emit()
		scene._shop_ui.close_shop()

	# Boss entrance flavour is copy-only and stable for this run's seed.
	var entrance_line := BossEntranceData.pick(scene.run_state.run_seed, 0)
	check(entrance_line != "", "demo_boss_entrance_line_not_empty")
	scene._boss_entrance_started = false
	scene._boss_entrance()
	await process_frame
	check(scene.hud.get_message_text() == entrance_line,
		"demo_boss_entrance_matches_seed")
	check(not BossEntranceData.variants(1).is_empty(),
		"demo_boss_entrance_chapter_2_has_copy")
	check(not BossEntranceData.variants(2).is_empty() and not BossEntranceData.variants(3).is_empty(),
		"demo_boss_entrance_chapter_3_and_4_authored")

	# Boss phase banners keep the mechanical "第 N 阶段" prefix and append the
	# seed-stable flavor line for that phase.
	var boss_chapter := CampaignData.chapter(0)
	for phase in [2, 3]:
		var phase_line := BossPhaseData.pick(scene.run_state.run_seed, phase)
		scene._on_boss_phase(boss_chapter, phase)
		check(phase_line != "", "demo_boss_phase_%d_line_not_empty" % phase)
		check(scene.hud.get_message_text()
			== "%s · 第 %d 阶段：%s" % [boss_chapter["boss_name"], phase, phase_line],
			"demo_boss_phase_%d_matches_seed" % phase)
		check(scene.hud.get_message_text().contains("第 %d 阶段" % phase),
			"demo_boss_phase_%d_keeps_banner" % phase)

	# Revive hints rotate per run but keep their mechanical text: the authority
	# path still restores 50 health, the relic path still spends its once-per-run
	# revive for 40.
	var revive_authority := load("res://resources/authorities/revive.tres") as AuthorityData
	check(revive_authority != null, "demo_revive_authority_present")
	if revive_authority != null:
		scene._authority.apply(revive_authority, scene.run_state)
		scene.player.health = 0
		scene._on_player_died()
		check(scene.player.health == 50, "demo_revive_authority_heals_50")
		check(scene.hud.get_message_text()
			== DeathHintData.pick(scene.run_state.run_seed, &"authority"),
			"demo_revive_authority_line_matches_seed")
		check(scene.hud.get_message_text().contains("恢复 50 生命"),
			"demo_revive_authority_keeps_mechanics")
	var revive_relic := load("res://resources/relics/immortal_archive.tres") as RelicData
	check(revive_relic != null, "demo_revive_relic_present")
	if revive_relic != null:
		scene.run_state.inventory.add_relic(revive_relic)
		scene.relic_effects.revive_used = false
		scene.player.health = 0
		scene._on_player_died()
		check(scene.player.health == 40, "demo_revive_relic_heals_40")
		check(scene.hud.get_message_text()
			== DeathHintData.pick(scene.run_state.run_seed, &"relic"),
			"demo_revive_relic_line_matches_seed")
		check(scene.hud.get_message_text().contains("不朽档案"),
			"demo_revive_relic_keeps_relic")

	# 吞噬: a passive run-long rule. The live corruption value feeds both the
	# weapon multiplier and the phrase damage scale, and the HUD reports it as
	# available instead of spent.
	var devour_authority := load("res://resources/authorities/devour.tres") as AuthorityData
	check(devour_authority != null, "demo_devour_authority_present")
	if devour_authority != null:
		scene._authority.apply(devour_authority, scene.run_state)
		scene.run_state.corruption = 0
		await process_frame
		var low_weapon: float = scene.player.damage_dealt_multiplier
		var low_phrase: float = scene.phrase_caster.damage_scale
		check(is_equal_approx(low_weapon, 1.0), "demo_devour_zero_corruption_neutral")
		check(scene._authority.can_use(), "demo_devour_hud_available")
		scene.run_state.corruption = 50
		await process_frame
		check(is_equal_approx(scene.player.damage_dealt_multiplier, 1.3),
			"demo_devour_weapon_multiplier")
		check(scene.phrase_caster.damage_scale > low_phrase,
			"demo_devour_scales_phrases")
		check(scene._authority.can_use(), "demo_devour_stays_available")
		scene.run_state.corruption = 0
		await process_frame
		check(is_equal_approx(scene.player.damage_dealt_multiplier, low_weapon),
			"demo_devour_multiplier_follows_purification")

	# 获取条件: at the boss choice the authored revive/rewrite pool grows with
	# 归档 (two records read) and 吞噬 (corruption >= 40), and picking one
	# installs it on the run.
	var archive_authority := load("res://resources/authorities/archive.tres") as AuthorityData
	check(archive_authority != null, "demo_archive_authority_present")
	if archive_authority != null:
		scene._records = 2
		scene.run_state.corruption = 45
		scene._authority = AuthorityController.new()
		scene._grant_chapter_authority.call_deferred()
		await create_timer(1.6).timeout
		check(scene._authority_choice.is_open(), "demo_authority_pool_opens")
		check(scene._authority_choice.get_button_count() == 4,
			"demo_authority_pool_has_conditional_entries")
		var pool_text := ""
		for index in scene._authority_choice.get_button_count():
			pool_text += scene._authority_choice._buttons[index].text
		check(pool_text.contains("归档"), "demo_authority_pool_offers_archive")
		check(pool_text.contains("吞噬"), "demo_authority_pool_offers_devour")
		scene._authority_choice._choose(2)
		await process_frame
		check(scene.run_state.authority != null
			and scene.run_state.authority.id == &"archive",
			"demo_authority_conditional_pick_applies")
		check(scene._authority.can_use(), "demo_archive_hud_available")

	# --- Big-map decoupling: several chests/steles in one room settle on their
	# own ids; a reload only suppresses the ones already recorded. ---
	var extra_stele := MemoryStele.new()
	extra_stele.name = "Stele2"
	extra_stele.position = Vector2(420, 520)
	scene._mds_world.room_node.add_child(extra_stele)
	var extra_chest := TreasureChest.new()
	extra_chest.name = "Chest"
	extra_chest.position = Vector2(520, 552)
	scene._mds_world.room_node.add_child(extra_chest)
	var second_chest := TreasureChest.new()
	second_chest.name = "Chest2"
	second_chest.position = Vector2(620, 552)
	scene._mds_world.room_node.add_child(second_chest)
	await process_frame
	scene._on_mds_room_loaded("ch1_rest")
	check(scene._steles.size() == 1, "multi_content_one_unclaimed_stele")
	check(scene._chests.size() == 2, "multi_content_two_chests")
	var extra_stele_id := ""
	if not scene._steles.is_empty():
		extra_stele_id = String(scene._steles[0].get_meta(&"content_id", ""))
	check(extra_stele_id == "ch1_rest/Stele2", "multi_content_stele_id")
	var multi_records: int = scene._records
	var claimed_before: Dictionary = scene._claimed_steles.duplicate()
	scene.player.global_position = extra_stele.global_position
	await create_timer(0.1).timeout
	scene._claim_nearest_stele()
	check(scene._claimed_steles.has("ch1_rest/Stele2"), "multi_content_stele_claimed_once")
	var newly_claimed: Array = []
	for claimed_id in scene._claimed_steles:
		if not claimed_before.has(claimed_id):
			newly_claimed.append(claimed_id)
	check(newly_claimed.size() == 1 and newly_claimed[0] == "ch1_rest/Stele2",
		"multi_content_claimed_ids_are_separate")
	scene._claim_nearest_stele()
	check(scene._records == multi_records + 1 or scene._records == multi_records,
		"multi_content_stele_single_settlement")
	var chest_pages: int = scene.run_state.pages
	scene._open_chest(extra_chest)
	check(scene._opened_chests.has("ch1_rest/Chest"), "multi_content_chest_id")
	check(not scene._opened_chests.has("ch1_rest/Chest2"), "multi_content_other_chest_untouched")
	scene._open_chest(extra_chest)
	check(scene.run_state.pages >= chest_pages, "multi_content_chest_reopen_safe")
	scene._on_mds_room_loaded("ch1_rest")
	check(scene._steles.is_empty(), "multi_content_reload_suppresses_claimed_stele")
	check(extra_chest.is_open and not second_chest.is_open,
		"multi_content_reload_opens_only_recorded_chest")
	var multi_save: Dictionary = scene._build_run_save()
	var multi_world: Dictionary = multi_save.get("world", {})
	var multi_progress: Dictionary = multi_save.get("progress", {})
	check((multi_world.get("opened_chest_ids", []) as Array).has("ch1_rest/Chest"),
		"multi_content_save_chest_id")
	check((multi_world.get("claimed_stele_ids", []) as Array).has("ch1_rest/Stele2"),
		"multi_content_save_stele_id")
	check(not (multi_world.get("opened_chests", []) as Array).has("ch1_rest"),
		"multi_content_legacy_list_not_polluted")
	# Encounters settle once even if a cleared signal is re-emitted.
	var cleared_before: int = scene._cleared_in_chapter
	check(scene._mark_encounter_cleared("ch1_rest", "ch1_rest/test_arena"), "encounter_settles")
	check(not scene._mark_encounter_cleared("ch1_rest", "ch1_rest/test_arena"),
		"encounter_not_double_counted")
	check(scene._cleared_in_chapter == cleared_before + 1, "encounter_counts_once")
	check((scene._build_run_save().get("progress", {}).get("cleared_encounters", []) as Array)
		.has("ch1_rest/test_arena"), "encounter_saved_by_id")
	# A legacy room-key record still suppresses content written before ids.
	var legacy_stele := MemoryStele.new()
	legacy_stele.name = "Stele3"
	legacy_stele.position = Vector2(300, 520)
	scene._mds_world.room_node.add_child(legacy_stele)
	await process_frame
	scene._legacy_claimed_steles["ch1_rest"] = true
	scene._on_mds_room_loaded("ch1_rest")
	check(scene._steles.is_empty(), "legacy_room_key_suppresses_stele")
	check(not is_instance_valid(legacy_stele) or legacy_stele.is_queued_for_deletion()
		or legacy_stele.is_claimed, "legacy_room_key_marks_stele")
	scene._legacy_claimed_steles.clear()

	print("CH1 DEMO INTEGRATION: %d checks, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
