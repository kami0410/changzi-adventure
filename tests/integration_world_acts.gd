extends SceneTree

## 言灵世界改写 (1.1) in the real run scene: a sentence's acts reach the
## enemies, the caster and the room; rules fire from real game events; the
## run-wide modifiers reach the systems they govern; a checkpoint keeps what
## was written.
##   godot --headless --path . -s res://tests/integration_world_acts.gd

var failures := 0
var assertions := 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("INTEGRATION FAIL: " + label)


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame


func _alive_foes() -> int:
	var count := 0
	for node in get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and not enemy.dead and not enemy.has_meta(&"word_ally"):
			count += 1
	return count


func _run() -> void:
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.title_shown_this_session = true
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var left := 10.0
	while left > 0.0 and (scene._mds_world == null or scene._mds_world.changing_room \
			or scene._mds_world.current_room.is_empty()):
		await create_timer(0.05).timeout
		left -= 0.05
	if scene._story.is_open():
		scene._story.close()
	var player: Player = scene.player
	player._invulnerable_left = 600.0
	await _frames(90)
	var acts: WorldActs = scene.world_acts
	check(acts != null and acts.is_inside_tree(), "world_acts_in_scene")
	check(acts.enemy_ids.has(&"ink_hound"), "world_acts_knows_the_roster")

	# --- summon: allies never hold a room, and their end is not a kill -------
	var kills_before: int = scene._kills
	var foes_before := _alive_foes()
	acts.apply(WorldActs.sanitize([{"do": "summon", "id": "ink_hound", "count": 2, "seconds": 1.0}])[0])
	await _frames(5)
	var allies: Array = []
	for child in scene._word_room.get_node("Enemies").get_children():
		if child is Enemy and child.has_meta(&"word_ally"):
			allies.append(child)
	check(allies.size() == 2, "summon_makes_two_allies (%d)" % allies.size())
	if not allies.is_empty():
		check((allies[0] as Enemy).is_charmed(), "summoned_ally_is_charmed")
		check((allies[0] as Enemy).sprite_visual != null, "summoned_ally_is_dressed")
	await create_timer(2.6).timeout
	# Allies may bite a real enemy to death meanwhile: those kills count, the
	# allies' own end does not.
	check(scene._kills - kills_before == foes_before - _alive_foes(), "ally_burning_out_is_not_a_kill")

	# --- hostile summon, then acts on enemies --------------------------------
	acts.apply(WorldActs.sanitize([{"do": "summon", "id": "scribe_bug", "count": 3, "seconds": 5, "hostile": 1}])[0])
	await _frames(5)
	var bugs: Array[Enemy] = []
	for node in get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and not enemy.dead and enemy.data != null and enemy.data.id == &"scribe_bug":
			bugs.append(enemy)
	check(bugs.size() >= 3, "hostile_summon_spawns (%d)" % bugs.size())
	acts.perform(WorldActs.sanitize([
		{"do": "shrink", "target": "all", "scale": 0.5, "seconds": 5},
		{"do": "disarm", "target": "all", "seconds": 5},
	]), [])
	if not bugs.is_empty():
		check(is_equal_approx(bugs[0].scale.x, 0.5), "shrink_reaches_enemies")
		check(bugs[0].is_disarmed() and bugs[0].get_attack_damage() == 0, "disarm_reaches_enemies")

	# --- transform keeps the body count and is not a kill ---------------------
	kills_before = scene._kills
	var before := get_nodes_in_group("enemies").size()
	acts.apply(WorldActs.sanitize([{"do": "transform", "into": "ink_hound", "target": "nearest", "count": 1}])[0])
	await _frames(4)
	check(get_nodes_in_group("enemies").size() == before, "transform_keeps_body_count")
	check(scene._kills == kills_before, "transform_is_not_a_kill")

	# --- rules fire from real kills -------------------------------------------
	scene.run_state.ink = 0
	scene.run_state.ink_changed.emit(0)
	acts.add_rule(WorldActs.sanitize_rules([{"when": "on_kill", "do": [{"do": "ink", "amount": 7}], "seconds": 0}])[0])
	var ink_before: int = scene.run_state.ink
	for node in get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and not enemy.dead and enemy.data != null and enemy.data.id == &"scribe_bug":
			enemy.take_damage(999999)
			break
	await _frames(3)
	check(scene.run_state.ink >= ink_before + 7, "on_kill_rule_fires_from_a_real_kill")
	check(scene._kills == kills_before + 1, "real_kill_counts")
	acts.apply(WorldActs.sanitize([{"do": "kill", "target": "all", "count": 0}])[0])
	await _frames(3)

	# --- run-wide modifiers reach what they govern ----------------------------
	var taken_before: float = player.damage_taken_multiplier
	acts.perform(WorldActs.sanitize([
		{"do": "mutator", "key": "damage_taken", "amount": 2.0, "seconds": 0},
		{"do": "power", "amount": 3.0, "seconds": 30},
		{"do": "free_cast", "seconds": 30},
		{"do": "gravity", "amount": 0.4, "seconds": 30},
		{"do": "mutator", "key": "enemy_speed", "amount": 0.5, "seconds": 30},
		{"do": "mutator", "key": "player_speed", "amount": 1.5, "seconds": 30},
		{"do": "mutator", "key": "corruption_gain", "amount": 0.0, "seconds": 30},
	]), [])
	await process_frame
	await process_frame
	check(is_equal_approx(player.damage_taken_multiplier, taken_before * 2.0), "modifier_damage_taken")
	check(player.damage_dealt_multiplier >= 3.0 - 0.001, "modifier_damage_dealt")
	check(is_zero_approx(scene.phrase_caster.ink_cost_scale), "modifier_free_cast")
	check(is_equal_approx(player.word_gravity_scale, 0.4) and is_equal_approx(Enemy.world_gravity_scale, 0.4), "modifier_gravity")
	check(is_equal_approx(Enemy.world_speed_scale, 0.5), "modifier_enemy_speed")
	check(is_equal_approx(player.word_speed_scale, 1.5), "modifier_player_speed")
	var corruption: int = scene.run_state.corruption
	scene.run_state.add_corruption(20)
	check(scene.run_state.corruption == corruption, "modifier_corruption_gain_zero")
	check(scene.hud._world_rules_label != null and scene.hud._world_rules_label.visible, "hud_lists_world_rules")

	# --- the caster and the room ----------------------------------------------
	var start := player.global_position
	acts.apply(WorldActs.sanitize([{"do": "teleport", "to": "forward", "distance": 200}])[0])
	check(absf(player.global_position.x - start.x) > 60.0, "teleport_moves_the_caster")
	acts.apply(WorldActs.sanitize([{"do": "platforms", "count": 4, "pattern": "stairs", "seconds": 5}])[0])
	acts.apply(WorldActs.sanitize([{"do": "wall", "seconds": 5}])[0])
	await process_frame
	var steps := 0
	for child in scene.get_children():
		if String(child.name).begins_with("WordStep"):
			steps += 1
	check(steps == 4, "platforms_written (%d)" % steps)
	check(scene.get_node_or_null("WordWall") != null, "wall_written")
	acts.apply(WorldActs.sanitize([{"do": "time_scale", "amount": 0.5, "seconds": 0.3}])[0])
	check(is_equal_approx(Engine.time_scale, 0.5), "time_scale_applies")
	await create_timer(0.6, true, false, true).timeout
	check(is_equal_approx(Engine.time_scale, 1.0), "time_scale_restores")
	var jump: float = player.jump_velocity
	acts.apply(WorldActs.sanitize([{"do": "jump", "amount": 2.0, "seconds": 0.2}])[0])
	check(is_equal_approx(player.jump_velocity, jump * 2.0), "jump_override_applies")
	await create_timer(0.5).timeout
	check(is_equal_approx(player.jump_velocity, jump), "jump_override_restores")

	# --- things written into being survive a checkpoint ------------------------
	var relics_before: int = scene.run_state.inventory.relics.size()
	acts.apply(WorldActs.sanitize([{"do": "relic", "name": "墨心", "description": "它替你记得。", "mods": {"cooldown": 0.5}}])[0])
	check(scene.run_state.inventory.relics.size() == relics_before + 1, "relic_written_into_the_bag")
	acts.apply(WorldActs.sanitize([{"do": "weapon", "name": "斩月", "damage": 77, "kind": "melee"}])[0])
	await process_frame
	var dropped := false
	for child in scene.get_children():
		if child is Pickup and child.kind == &"weapon" and (child.resource as WeaponData).display_name == "斩月":
			dropped = (child.resource as WeaponData).damage == 77
	check(dropped, "weapon_written_at_the_feet_of_the_caster")
	var save: Dictionary = scene._build_run_save()
	var word: Dictionary = save["world"]["word"]
	check((word["relics"] as Array).size() == 1, "save_keeps_written_relic")
	check((word["rules"] as Array).size() == 1, "save_keeps_run_long_rule")
	for id in save["inventory"]["relics"]:
		check(not String(id).begins_with("word_relic"), "save_relic_ids_stay_shipped_ids")

	# --- a full sentence through the caster ------------------------------------
	var phrase := SpellSynthesizer.synthesize("让雷落在火里，立起一面墙", [])
	var heard: Array = []
	acts.acted.connect(func(act: Dictionary) -> void: heard.append(String(act["do"])))
	scene.run_state.inventory.phrases[0] = phrase
	scene.phrase_caster.equip_phrase(0, phrase)
	scene.run_state.ink = scene.run_state.max_ink
	scene._try_cast(0)
	await _frames(3)
	check(heard.has("wall"), "sentence_cast_performs_its_acts")
	check(scene.ai_situation().contains("生命"), "ai_situation_describes_the_fight")

	# --- 开口即言灵: one line, cast at once ---------------------------------------
	var ai := root.get_node("AI") as AIService
	ai.config["enabled"] = false
	check(InputMap.has_action(&"speak"), "speak_action_registered")
	scene._speak_cooldown = 0.0
	# Killing everything cleared the room: take the reward so the world runs.
	if scene._reward_ui.visible:
		scene._on_reward_chosen(0)
	await _frames(2)
	paused = false
	# The free-cast rule from above would make every sentence free.
	acts._mods.clear()
	await process_frame
	await process_frame
	scene._open_speak_bar()
	var bar: SpeakBar = scene._speak_bar
	check(bar.is_open() and paused, "speak_bar_pauses_the_world")
	scene.run_state.ink = 0
	bar.spoken.emit("立起一面墙")
	check(bar.is_open(), "speak_without_ink_keeps_the_line_open")
	scene.run_state.ink = scene.run_state.max_ink
	heard.clear()
	var ink_full: int = scene.run_state.ink
	bar.spoken.emit("立起一面墙")
	await _frames(2)
	check(not bar.is_open() and not paused, "speak_closes_and_resumes")
	check(heard.has("wall"), "spoken_sentence_takes_effect")
	check(scene.run_state.ink < ink_full, "spoken_sentence_costs_ink")
	check(scene._speak_cooldown >= scene.SPEAK_MIN_COOLDOWN, "spoken_sentence_echoes")
	scene._open_speak_bar()
	check(not bar.is_open(), "speak_waits_for_the_echo")
	# The AI path: the line waits, and a late or failed answer falls back.
	ai.config["enabled"] = true
	if ai.is_configured():
		scene._speak_cooldown = 0.0
		scene._open_speak_bar()
		scene._speak_pending = "所有敌人缩小"
		bar.wait("世界在听这句话…")
		heard.clear()
		ai.intent_ready.emit("所有敌人缩小", AIService.validate_intent({
			"name": "渺小之名", "shape": "ward", "tags": ["name"], "confidence": 0.9, "components": {"shield": 5},
			"actions": [{"do": "shrink", "scale": 0.4, "seconds": 5}], "ink_cost": 5, "cooldown": 2, "corruption_gain": 1}))
		await _frames(2)
		check(heard.has("shrink") and not bar.is_open(), "ai_spoken_intent_takes_effect")
		scene._speak_cooldown = 0.0
		scene._open_speak_bar()
		scene._speak_pending = "天黑"
		heard.clear()
		ai.intent_failed.emit("天黑", "offline")
		await _frames(2)
		check(heard.has("darkness"), "ai_failure_falls_back_to_offline_reading")
	ai.config["enabled"] = false

	# --- NPC 临行赠言 lands on the run ---------------------------------------------
	var profile: Profile = flow.profile
	check(profile.add_word_blessing("阿砚", {"name": "淬火", "actions": [{"do": "power", "amount": 1.5, "seconds": 0.0},
		{"do": "nonsense"}], "rules": []}), "blessing_kept_on_profile")
	check(not profile.add_word_blessing("阿砚", {"actions": [{"do": "nonsense"}]}), "empty_blessing_refused")
	var dealt_before: float = acts.modifier(&"damage_dealt")
	scene._apply_word_blessings()
	check(is_equal_approx(acts.modifier(&"damage_dealt"), dealt_before * 1.5), "blessing_performed_at_run_start")
	check(profile.word_blessings.is_empty(), "blessing_spent")
	profile.remember_npc_talk(&"ayan", "你还记得我吗", "记得。你的刀还钝着。")
	for i in 12:
		profile.remember_npc_talk(&"ayan", "第 %d 句" % i, "嗯。")
	check(profile.npc_memory_lines(&"ayan").size() == Profile.NPC_MEMORY_LINES, "npc_memory_is_bounded")
	var npc_prompt := AIService._npc_system_prompt({"story": ["你是阿砚。"], "memory": profile.npc_memory_lines(&"ayan")})
	check(npc_prompt.contains("你们之前谈过") and npc_prompt.contains("blessing"), "npc_prompt_carries_memory_and_blessing")
	var parsed := AIService.parse_npc_response("ollama", JSON.stringify({"message": {"content": JSON.stringify({
		"reply": "拿去。", "mood": "warm", "effect": {},
		"blessing": {"name": "<淬火>", "actions": [{"do": "relic", "name": "砚心", "mods": {"cooldown": 0.8}}, {"do": "rm"}]}})}}))
	check((parsed["blessing"]["actions"] as Array).size() == 1 and parsed["blessing"]["name"] == "淬火", "npc_blessing_validated")
	profile.npc_memory.erase("ayan")

	Engine.time_scale = 1.0
	print("INTEGRATION world acts: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
