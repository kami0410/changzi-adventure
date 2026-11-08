extends RefCounted

## 1.0 言灵权能: offline sentences and AI intents reach world powers (time
## stop, execute, charm, blink, invulnerability, ink steps, reveal, unlock,
## conjure), each takes real effect, and AI-voiced NPCs grant uncapped gifts.


func run(t: Callable) -> void:
	_test_offline_words(t)
	_test_ai_intent(t)
	_test_effects(t)
	_test_npc_authority(t)
	grimoire_roundtrip(t)


func _test_offline_words(t: Callable) -> void:
	var base := SpellSynthesizer.synthesize("火", [])
	var stop := SpellSynthesizer.synthesize("让时间停五秒", [])
	t.call(float(stop.components.get(&"time_stop", 0.0)), 5.0, "power_offline_time_stop_seconds")
	t.call(stop.ink_cost > base.ink_cost, true, "power_offline_time_stop_costs_ink")
	t.call(stop.corruption_gain > base.corruption_gain, true, "power_offline_time_stop_costs_corruption")
	var steps := SpellSynthesizer.synthesize("铺一条通天的墨阶", [])
	t.call(float(steps.components.get(&"terrain", 0.0)) >= 4.0, true, "power_offline_terrain")
	var charm := SpellSynthesizer.synthesize("让三个敌人为我而战", [])
	t.call(float(charm.components.get(&"charm", 0.0)), 3.0, "power_offline_charm_count")
	var execute := SpellSynthesizer.synthesize("把它们的名字一笔勾销", [])
	t.call(float(execute.components.get(&"execute", 0.0)) > 0.0, true, "power_offline_execute")
	var blink := SpellSynthesizer.synthesize("闪现到它身后", [])
	t.call(float(blink.components.get(&"blink", 0.0)) > 0.0, true, "power_offline_blink")
	var shield := SpellSynthesizer.synthesize("刀枪不入", [])
	t.call(float(shield.components.get(&"invulnerable", 0.0)) > 0.0, true, "power_offline_invulnerable")
	var reveal := SpellSynthesizer.synthesize("揭示这一章的真相", [])
	t.call(float(reveal.components.get(&"reveal", 0.0)) > 0.0, true, "power_offline_reveal")
	var unlock := SpellSynthesizer.synthesize("破门", [])
	t.call(float(unlock.components.get(&"unlock", 0.0)) > 0.0, true, "power_offline_unlock")
	var gold := SpellSynthesizer.synthesize("点石成金", [])
	t.call(float(gold.components.get(&"conjure", 0.0)) > 0.0, true, "power_offline_conjure")
	t.call(WorldPowers.has_any(base.components), false, "power_plain_spell_has_none")
	t.call(WorldPowers.has_any(stop.components), true, "power_detected")


func _test_ai_intent(t: Callable) -> void:
	var intent := {
		"name": "停摆的名册", "shape": "blade", "tags": ["time", "name"], "confidence": 0.9,
		"components": {"damage": 30, "time_stop": 10, "execute": 0.3, "charm": 4, "blink": 500,
			"invulnerable": 6, "terrain": 8, "reveal": 1, "unlock": 1, "conjure": 99, "purify": 40},
		"ink_cost": 40, "cooldown": 12, "corruption_gain": 18,
	}
	var phrase := SpellSynthesizer.compile_intent("让时间停十秒", intent, [])
	t.call(phrase != null, true, "power_ai_compiles")
	if phrase == null:
		return
	for key in ["time_stop", "execute", "charm", "blink", "invulnerable", "terrain", "reveal", "unlock", "conjure", "purify"]:
		t.call(float(phrase.components.get(StringName(key), -1.0)), float(intent["components"][key]), "power_ai_keeps_%s" % key)
	t.call(phrase.ink_cost, 40, "power_ai_sets_ink_cost")
	t.call(phrase.corruption_gain, 18, "power_ai_sets_corruption")
	var prompt := AIService.SYSTEM_PROMPT
	for key in WorldPowers.KEYS:
		t.call(prompt.contains(String(key)), true, "power_ai_prompt_lists_%s" % key)


func _test_effects(t: Callable) -> void:
	var ctx := SpellContext.new()
	ctx.direction = Vector2.RIGHT
	var weak := _enemy(100, 20)
	var healthy := _enemy(100, 90)
	var targets := SpellTargets.describe([weak, healthy])
	WorldPowers.execute(ctx, targets, 0.3)
	t.call(weak.dead, true, "power_execute_kills_below_line")
	t.call(healthy.dead, false, "power_execute_spares_above_line")
	WorldPowers.time_stop(ctx, SpellTargets.describe([healthy]), 4.0)
	t.call(healthy.is_stunned(), true, "power_time_stop_freezes")
	var ally := _enemy(60, 60)
	var done := WorldPowers.charm(ctx, SpellTargets.describe([ally]), 2, 5.0)
	t.call(done, 1, "power_charm_count")
	t.call(ally.is_charmed(), true, "power_charm_applies")
	t.call(ally.collision_layer, 0, "power_charmed_cannot_be_hit")
	t.call(ally.is_in_group("enemies"), false, "power_charmed_leaves_enemy_group")
	var player := Player.new()
	ctx.player = player
	var applied := WorldPowers.apply(ctx, {&"invulnerable": 3.0, &"blink": 200.0, &"conjure": 5.0}, [], func(_p, _a): pass)
	t.call(player.is_invulnerable(), true, "power_invulnerable")
	t.call(player.global_position.x, 200.0, "power_blink_moves_forward")
	t.call(applied.has(&"conjure"), true, "power_game_power_reported")
	var asked := []
	WorldPowers.apply(ctx, {&"reveal": 1.0, &"unlock": 1.0}, [], func(p, a): asked.append([p, a]))
	t.call(asked.size(), 2, "power_game_powers_emitted")
	for node in [weak, healthy, ally, player]:
		node.free()


func _enemy(max_hp: int, hp: int) -> Enemy:
	var enemy := Enemy.new()
	var data := EnemyData.new()
	data.max_health = max_hp
	data.speed = 80.0
	data.contact_damage = 5
	enemy.data = data
	enemy.health = hp
	enemy.max_health = max_hp
	return enemy


func _test_npc_authority(t: Callable) -> void:
	var offline := Profile.new()
	var applied := NPCProfiles.apply_effect(offline, &"guru", {"fragments": 200.0, "start_health": 50.0})
	t.call(float(applied.get("fragments", 0.0)), 12.0, "power_npc_offline_capped")
	t.call(applied.has("start_health"), false, "power_npc_offline_no_new_gifts")
	var ai := Profile.new()
	var ai_applied := NPCProfiles.apply_effect(ai, &"guru", {"fragments": 200.0, "start_health": 50.0,
		"start_ink": 40.0, "start_relics": 2.0, "weapon_damage": 5.0, "map_pages": 60.0}, true)
	t.call(float(ai_applied.get("fragments", 0.0)), 200.0, "power_npc_ai_uncapped")
	t.call(ai.memory_fragments >= 200, true, "power_npc_ai_fragments_land")
	t.call(float(ai.pending_run_bonuses.get("ai_start_health", 0.0)), 50.0, "power_npc_ai_start_health")
	t.call(float(ai.pending_run_bonuses.get("ai_start_ink", 0.0)), 40.0, "power_npc_ai_start_ink")
	t.call(float(ai.pending_run_bonuses.get("ai_start_relics", 0.0)), 2.0, "power_npc_ai_start_relics")
	t.call(float(ai.pending_run_bonuses.get("ai_start_pages", 0.0)), 60.0, "power_npc_ai_start_pages")
	t.call(ai.npc_blessing(&"guru", "damage", 0.0), 5.0, "power_npc_ai_weapon_damage")
	var weapon := WeaponData.new()
	weapon.damage = 10
	t.call(RunLoot.weapon_for_run(weapon, ai).damage, 15, "power_npc_ai_damage_reaches_weapons")
	var prompt := AIService._npc_system_prompt({"story": ["测试"], "keywords": {}, "ai_actions": []})
	for key in ["start_health", "start_ink", "start_relics", "weapon_damage"]:
		t.call(prompt.contains(key), true, "power_npc_prompt_lists_%s" % key)


## 言灵法典: kept sentences survive a save/load and keep the AI reading.
static func grimoire_roundtrip(t: Callable) -> void:
	var path := "user://test_grimoire_profile.cfg"
	var profile := Profile.new()
	t.call(profile.add_grimoire("  ", "空"), false, "grimoire_rejects_empty")
	t.call(profile.add_grimoire("让时间停五秒", "停摆", {"shape": "blade", "components": {"time_stop": 5}}), true, "grimoire_adds")
	profile.add_grimoire("铺一条墨阶", "墨阶")
	profile.add_grimoire("让时间停五秒", "停摆二", {"shape": "blade", "components": {"time_stop": 6}})
	t.call(profile.grimoire.size(), 2, "grimoire_dedupes_text")
	t.call(String(profile.grimoire[1]["name"]), "停摆二", "grimoire_update_moves_to_end")
	for i in Profile.GRIMOIRE_MAX + 3:
		profile.add_grimoire("句子%d" % i, "句%d" % i)
	t.call(profile.grimoire.size(), Profile.GRIMOIRE_MAX, "grimoire_capped")
	profile.add_grimoire("让时间停五秒", "停摆", {"shape": "blade", "tags": ["time"], "components": {"time_stop": 5}})
	profile.save_profile(path)
	var loaded := Profile.new()
	loaded.load_profile(path)
	t.call(loaded.grimoire.size(), Profile.GRIMOIRE_MAX, "grimoire_saved_size")
	var last: Dictionary = loaded.grimoire.back()
	t.call(String(last["text"]), "让时间停五秒", "grimoire_saved_text")
	t.call(int((last["intent"] as Dictionary)["components"]["time_stop"]), 5, "grimoire_saved_intent")
	loaded.remove_grimoire(0)
	t.call(loaded.grimoire.size(), Profile.GRIMOIRE_MAX - 1, "grimoire_remove")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
