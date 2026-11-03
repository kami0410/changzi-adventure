extends RefCounted

func run(t: Callable) -> void:
	var inventory := Inventory.new()
	var word := ContentLibrary.WORDS[0] as WordData
	inventory.add_word(word)
	inventory.add_word(word.duplicate())
	t.call(inventory.words.size(), 1, "collected_words_are_unique_by_id")
	var relic := ContentLibrary.RELICS[0] as RelicData
	inventory.add_relic(relic)
	t.call(inventory.add_relic(relic.duplicate()), false, "duplicate_relic_rejected")
	t.call(inventory.relics.size(), 1, "relic_bonus_cannot_stack_duplicates")
	var room := preload("res://scenes/levels/room.tscn").instantiate() as ArenaRoom
	t.call(room.has_method("contains_entry"), true, "room_has_safe_entry_boundary")
	if room.has_method("contains_entry"):
		t.call(room.call("contains_entry", Vector2(-700, 250)), false, "outside_door_does_not_lock")
		t.call(room.call("contains_entry", Vector2(-500, 250)), true, "inside_door_can_start_encounter")
	room.free()
	t.call(ContentLibrary.WORDS.size(), 95, "export_has_word_catalogue")
	t.call(ContentLibrary.RELICS.size(), 9, "export_has_relic_catalogue")
	_test_builds(t)
	_test_relics(t)

func _test_builds(t: Callable) -> void:
	var profile := Profile.new()
	var words := RunLoot.starting_words(profile)
	var decoded := 0
	for word in words:
		if word.decoded:
			decoded += 1
	t.call(decoded, 6, "starter_has_six_decoded_words")
	t.call(words.size(), 18, "starter_has_six_decoded_and_twelve_fragments")
	profile.unlock_word(&"fengbao")
	t.call(RunLoot.starting_words(profile).size(), 19, "profile_word_unlock_is_available")
	var base := preload("res://resources/weapons/broken_page_sword.tres")
	profile.weapon_base_levels[base.id] = 2
	var upgraded := RunLoot.weapon_for_run(base, profile, 1)
	t.call(upgraded.damage, base.damage + 6, "weapon_inherits_base_and_room_upgrade")
	t.call(upgraded != base, true, "weapon_upgrade_keeps_shared_resource_unchanged")
	var first := RunState.new()
	var second := RunState.new()
	first.reset_for_new_run(321)
	second.reset_for_new_run(321)
	var a := RunLoot.choices(first, 1, profile)
	var b := RunLoot.choices(second, 1, profile)
	t.call(a.size(), 3, "room_reward_three_choices")
	t.call(a[0]["title"], b[0]["title"], "reward_seed_reproduces_relic")
	t.call(a[1]["title"], b[1]["title"], "reward_seed_reproduces_word")
	for relic in ContentLibrary.RELICS:
		first.inventory.add_relic(relic)
	t.call(RunLoot.choices(first, 2, profile)[0]["kind"], &"vitality", "all_relics_owned_gives_useful_fallback")
	profile.free()

func _test_relics(t: Callable) -> void:
	var run := RunState.new()
	var player := Player.new()
	var effects := RelicEffects.new()
	effects.run = run
	effects.player = player
	for relic in ContentLibrary.RELICS:
		run.inventory.add_relic(relic)
	run.ink = 0
	run.corruption = 20
	for i in 5:
		effects.tick(1.0, [])
	t.call(run.ink, 25, "ink_heart_adds_passive_regen")
	t.call(run.corruption, 19, "purify_flow_cleanses")
	effects.on_room_cleared()
	t.call(run.corruption, 15, "purify_flow_room_clear")
	run.ink = 0
	effects.on_kill()
	t.call(run.ink, 11, "kill_restores_ink_with_tongue_bonus")
	player.health = 50
	effects.on_damage(20)
	t.call(player.health, 52, "blood_quill_restores_actual_damage_fraction")
	effects.on_room_cleared()
	t.call(player.health, 70, "lung_heals_after_clear")
	t.call(effects.cooldown_scale(), 0.75, "time_shard_reduces_cooldown")
	run.corruption = 25
	t.call(effects.damage_scale(), 1.4, "polluted_eye_uses_corruption_threshold")
	player.health = 0
	player.heal(20)
	t.call(player.health, 0, "ordinary_heal_does_not_revive")
	t.call(player.revive(40), true, "explicit_revive_restores_dead_player")
	t.call(player.health, 40, "revive_restores_requested_health")
	t.call(player.is_invulnerable(), true, "revive_protects_player")
	t.call(player.revive(40), false, "cannot_revive_living_player")
	player._invulnerable_left = 0
	player.grant_shield(8, 3.0)
	player.take_damage(10)
	t.call(player.health, 38, "shield_absorbs_damage_before_health")
	t.call(player.shield, 0, "shield_is_consumed")
	player.free()
