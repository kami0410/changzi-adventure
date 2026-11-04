extends RefCounted

## Spell v3: every AI/lexicon component must change what happens in the world.
## Runs outside the scene tree, so PhraseCaster resolves bolts, waves, meteors
## and fields immediately; the node classes are also stepped by hand.

class StubEnemy:
	extends Enemy
	var taken := 0
	var stunned_for := 0.0
	var knocked := Vector2.ZERO
	func take_damage(amount: int) -> void:
		taken += amount
		health = maxi(health - amount, 0)
		if health == 0:
			dead = true
	func apply_stun(duration: float) -> void:
		stunned_for = maxf(stunned_for, duration)
	func apply_knockback(impulse: Vector2, _duration: float = 0.2) -> void:
		knocked = impulse


func run(t: Callable) -> void:
	_test_projectiles_spawn(t)
	_test_uncapped_damage(t)
	_test_pulses_repeat(t)
	_test_statuses(t)
	_test_new_shapes(t)
	_test_bolt_node(t)
	_test_domain_lasts(t)
	_test_ai_intent(t)
	_test_freeform_words(t)
	_test_numbers(t)
	_test_claim_costs(t)


func _enemy(at: Vector2, health: int = 100000) -> StubEnemy:
	var enemy := StubEnemy.new()
	enemy.max_health = health
	enemy.health = health
	enemy.position = at
	return enemy


func _caster(enemies: Array[Enemy]) -> Array:
	var player := Player.new()
	player.max_health = 100
	player.health = 50
	var run := RunState.new()
	run.ink = 100
	var caster := PhraseCaster.new()
	caster.bind_run_state(run)
	caster.set_player(player)
	caster.set_enemies(enemies)
	caster.damage_scale = 1.0
	return [caster, player, run]


func _phrase(shape: StringName, components: Dictionary, tags: Array[StringName] = []) -> ResolvedPhrase:
	var phrase := ResolvedPhrase.new()
	phrase.display_name = "测试"
	phrase.components = components
	phrase.tags = tags
	phrase.spell = SpellStyle.decide(tags, components)
	phrase.spell[&"shape"] = shape
	var base := SpellStyle.base_for(shape)
	phrase.spell[&"range"] = float(base[&"range"])
	phrase.spell[&"pulses"] = int(components.get(&"pulses", 1))
	return phrase


func _free(items: Array) -> void:
	for item in items:
		if item is Object and is_instance_valid(item) and not item is RefCounted:
			item.free()


func _test_projectiles_spawn(t: Callable) -> void:
	var targets: Array[Enemy] = []
	for index in 6:
		targets.append(_enemy(Vector2(120 + index * 40, -12 + (index % 3 - 1) * 26)))
	var parts := _caster(targets)
	var caster: PhraseCaster = parts[0]
	caster.equip_phrase(0, _phrase(&"missile", {&"damage": 10.0, &"projectiles": 20.0, &"spread": 1.2, &"homing": 1.0}))
	t.call(caster.cast(0), true, "v3_missile_casts")
	var hit := 0
	for enemy in targets:
		if (enemy as StubEnemy).taken > 0:
			hit += 1
	t.call(hit >= 4, true, "v3_twenty_projectiles_spread_over_targets")
	t.call(caster.last_context.total_hits() >= 6, true, "v3_projectiles_really_hit_many_times")
	# A flame with projectiles also fires a volley layer.
	var lone: Array[Enemy] = [_enemy(Vector2(400, -28))]
	var flame_parts := _caster(lone)
	var flame_caster: PhraseCaster = flame_parts[0]
	flame_caster.equip_phrase(0, _phrase(&"flame", {&"damage": 5.0, &"projectiles": 8.0}, [&"flame"]))
	flame_caster.cast(0)
	t.call((lone[0] as StubEnemy).taken > 0, true, "v3_flame_projectile_layer_reaches_far_enemy")
	_free(parts + flame_parts + targets + lone)


func _test_uncapped_damage(t: Callable) -> void:
	var enemies: Array[Enemy] = [_enemy(Vector2(90, -28), 1000000)]
	var parts := _caster(enemies)
	var caster: PhraseCaster = parts[0]
	caster.equip_phrase(0, _phrase(&"beam", {&"damage": 999.0}, [&"eye"]))
	caster.cast(0)
	t.call((enemies[0] as StubEnemy).taken, 999, "v3_ai_damage_999_not_clamped")
	caster.equip_phrase(1, _phrase(&"beam", {&"damage": 1.0e15}, [&"eye"]))
	t.call(caster.cast(1), true, "v3_absurd_damage_does_not_crash")
	_free(parts + enemies)


func _test_pulses_repeat(t: Callable) -> void:
	var enemies: Array[Enemy] = [_enemy(Vector2(80, -28))]
	var parts := _caster(enemies)
	var caster: PhraseCaster = parts[0]
	caster.equip_phrase(0, _phrase(&"flame", {&"damage": 10.0, &"pulses": 4.0}, [&"flame"]))
	caster.cast(0)
	t.call((enemies[0] as StubEnemy).taken, 40, "v3_pulses_repeat_hits")
	_free(parts + enemies)


func _test_statuses(t: Callable) -> void:
	var near := _enemy(Vector2(70, -28))
	var enemies: Array[Enemy] = [near]
	var parts := _caster(enemies)
	var caster: PhraseCaster = parts[0]
	var player: Player = parts[1]
	caster.equip_phrase(0, _phrase(&"blade", {&"damage": 10.0, &"stun": 1.5, &"knockback": 3.0, &"burn": 7.0, &"slow": 0.5, &"duration": 4.0}))
	caster.cast(0)
	t.call(near.stunned_for >= 1.5, true, "v3_stun_applied")
	t.call(near.knocked.x > 0.0, true, "v3_knockback_pushes_away")
	var burn := near.get_node_or_null("BurnStatus") as BurnStatus
	t.call(burn != null and burn.damage == 7, true, "v3_ai_burn_value_used")
	t.call(burn != null and burn.ticks >= 7, true, "v3_duration_extends_burn")
	t.call(near.is_slowed(), true, "v3_slow_on_hit")
	near.tick_status_effects(5.5)
	t.call(near.is_slowed(), true, "v3_duration_extends_slow")
	var before := player.health
	caster.equip_phrase(1, _phrase(&"blade", {&"damage": 20.0, &"lifesteal": 0.5}))
	caster.cast(1)
	t.call(player.health > before, true, "v3_lifesteal_heals")
	_free(parts + enemies)


func _test_new_shapes(t: Callable) -> void:
	var ahead := _enemy(Vector2(240, -28))
	var behind := _enemy(Vector2(-240, -28))
	var enemies: Array[Enemy] = [ahead, behind]
	var parts := _caster(enemies)
	var caster: PhraseCaster = parts[0]
	caster.equip_phrase(0, _phrase(&"quake", {&"damage": 12.0}, [&"earth"]))
	caster.cast(0)
	t.call(ahead.taken > 0, true, "v3_quake_hits_ahead")
	t.call(behind.taken, 0, "v3_quake_runs_one_way")
	t.call(ahead.knocked.y < 0.0, true, "v3_quake_throws_upward")
	ahead.taken = 0
	caster.equip_phrase(1, _phrase(&"meteor", {&"damage": 15.0, &"projectiles": 2.0}, [&"star"]))
	caster.cast(1)
	t.call(ahead.taken >= 15, true, "v3_meteor_lands_on_enemy")
	ahead.taken = 0
	caster._cooldowns = [0.0, 0.0]
	caster.equip_phrase(0, _phrase(&"beam", {&"damage": 9.0, &"pulses": 3.0}, [&"eye"]))
	caster.cast(0)
	t.call(ahead.taken, 27, "v3_beam_pulses_hit_again")
	t.call(behind.taken, 0, "v3_beam_is_directional")
	ahead.taken = 0
	caster.equip_phrase(1, _phrase(&"domain", {&"damage": 10.0}, [&"crown"]))
	var far := _enemy(Vector2(120, -28))
	caster.set_enemies([far] as Array[Enemy])
	caster.cast(1)
	t.call(far.taken > 0, true, "v3_domain_ticks_inside")
	caster.equip_phrase(0, _phrase(&"chain", {&"damage": 10.0, &"chain": 6.0}, [&"thunder"]))
	var links: Array[Enemy] = []
	for index in 6:
		links.append(_enemy(Vector2(100 + index * 120, -28)))
	caster.set_enemies(links)
	caster.cast(0)
	var linked := 0
	for enemy in links:
		if (enemy as StubEnemy).taken > 0:
			linked += 1
	t.call(linked, 6, "v3_chain_count_jumps_six_targets")
	_free(parts + enemies + [far] + links)


func _test_bolt_node(t: Callable) -> void:
	var enemy := _enemy(Vector2(300, 0))
	var ctx := SpellContext.new()
	var list: Array[Enemy] = [enemy]
	ctx.target_provider = func() -> Array[Dictionary]: return SpellTargets.describe(list)
	ctx.pierce = 1
	var bolt := SpellBolt.new()
	bolt.ctx = ctx
	bolt.direction = Vector2.RIGHT
	bolt.damage = 12.0
	bolt.speed = 600.0
	bolt.pierce = 1
	bolt.global_position = Vector2(0, -28)
	for index in 40:
		bolt.step(1.0 / 60.0)
	t.call(enemy.taken, 12, "v3_bolt_node_hits_once")
	var homing_target := _enemy(Vector2(200, 160))
	var homing_list: Array[Enemy] = [homing_target]
	var homing_ctx := SpellContext.new()
	homing_ctx.target_provider = func() -> Array[Dictionary]: return SpellTargets.describe(homing_list)
	var seeker := SpellBolt.new()
	seeker.ctx = homing_ctx
	seeker.direction = Vector2.RIGHT
	seeker.damage = 5.0
	seeker.speed = 420.0
	seeker.homing = 1.5
	seeker.lifetime = 3.0
	seeker.global_position = Vector2(0, -28)
	for index in 180:
		if seeker.is_done():
			break
		seeker.step(1.0 / 60.0)
	t.call(homing_target.taken, 5, "v3_homing_bolt_turns_to_target")
	bolt.free()
	seeker.free()
	enemy.free()
	homing_target.free()


func _test_domain_lasts(t: Callable) -> void:
	var enemy := _enemy(Vector2(60, 0))
	var list: Array[Enemy] = [enemy]
	var ctx := SpellContext.new()
	ctx.target_provider = func() -> Array[Dictionary]: return SpellTargets.describe(list)
	var field := SpellDomain.new()
	field.ctx = ctx
	field.radius = 150.0
	field.lifetime = 4.0
	field.tick = 0.5
	field.damage = 3.0
	field.global_position = Vector2.ZERO
	for index in 200:
		if field.is_queued_for_deletion():
			break
		field.step(0.02)
	t.call(field.ticks_done() >= 7, true, "v3_domain_duration_really_persists")
	t.call(enemy.taken >= 21, true, "v3_domain_ticks_accumulate")
	field.free()
	enemy.free()


func _test_ai_intent(t: Callable) -> void:
	var intent := {
		"name": "百焰追星", "description": "一百颗火星追着敌人。", "shape": "missile",
		"tags": [&"flame", &"star"], "confidence": 0.9,
		"components": {"damage": 999.0, "projectiles": 100.0, "homing": 1.2, "burn": 3.0, "spread": 1.4, "duration": 5.0},
		"vfx": {"secondary": "#ffe0a0", "size": 1.6, "trail": 12},
		"feel": {"screen_shake": 1.5, "hit_stop": 0.06},
	}
	var phrase := SpellSynthesizer.compile_intent("一百颗追着敌人的火星", intent, [])
	t.call(phrase != null, true, "v3_ai_intent_compiles")
	t.call(phrase.spell.get(&"shape", &""), &"missile", "v3_ai_shape_missile_kept")
	t.call(phrase.components.get(&"damage", 0.0), 999.0, "v3_ai_damage_kept_uncapped")
	t.call(phrase.components.get(&"projectiles", 0.0), 100.0, "v3_ai_projectiles_kept")
	t.call(phrase.components.get(&"homing", 0.0), 1.2, "v3_ai_homing_kept")
	t.call(phrase.spell.get(&"vfx", {}).get(&"size", 0.0), 1.6, "v3_ai_vfx_recipe_kept")
	t.call(phrase.spell.get(&"feel", {}).get(&"hit_stop", 0.0), 0.06, "v3_ai_feel_recipe_kept")
	var weird := {"name": "坏数", "shape": "beam", "tags": [&"eye"], "components": {"damage": INF, "pierce": -3.0}, "vfx": {"size": NAN}}
	var safe := SpellSynthesizer.compile_intent("坏数", weird, [])
	t.call(safe != null, true, "v3_non_finite_ai_numbers_survive")
	t.call(is_finite(float(safe.components.get(&"damage", 0.0))), true, "v3_infinite_damage_dropped")
	t.call(float(safe.components.get(&"pierce", 0.0)) >= 0.0, true, "v3_negative_pierce_dropped")
	var abyss := SpellSynthesizer.compile_intent("咕噜咕噜", {"name": "未知", "shape": "void", "tags": [&"abyss"], "confidence": 0.1, "components": {"damage": 4.0}}, [])
	t.call(bool(abyss.synthesis.get(&"abyssal", false)), true, "v3_low_confidence_becomes_abyss")
	t.call(float(abyss.components.get(&"damage", 0.0)) >= 18.0, true, "v3_abyss_is_still_strong")
	t.call(abyss.corruption_gain >= 20, true, "v3_abyss_corrupts_heavily")
	var validated := AIService.validate_intent({"name": "测", "shape": "meteor", "tags": ["star"], "components": {"explosion": 3, "stun": 2, "pull": 1}, "vfx": {"rings": 5}})
	t.call(validated.get("shape", &""), &"meteor", "v3_validator_accepts_new_shapes")
	t.call(validated.get("components", {}).get(&"explosion", 0.0), 3.0, "v3_validator_keeps_explosion")
	t.call(validated.has("vfx"), true, "v3_validator_passes_vfx")
	var target := _enemy(Vector2(150, -28))
	var parts := _caster([target] as Array[Enemy])
	var caster: PhraseCaster = parts[0]
	caster.equip_phrase(0, phrase)
	caster.cast(0)
	t.call(caster.last_context.vfx_scale, 1.6, "v3_vfx_size_reaches_cast")
	t.call(caster.last_context.burn, 3, "v3_ai_burn_reaches_cast")
	_free(parts + [target])


func _test_freeform_words(t: Callable) -> void:
	var homing := SpellSynthesizer.synthesize("追踪的火焰弹幕", [])
	t.call(homing.spell.get(&"shape", &""), &"missile", "v3_text_homing_volley")
	t.call(float(homing.components.get(&"homing", 0.0)) > 0.0, true, "v3_text_adds_homing")
	t.call(homing.spell.get(&"color", Color.WHITE), SpellStyle.ELEMENT_COLORS[0][1], "v3_fire_volley_keeps_fire_colour")
	var quake := SpellSynthesizer.synthesize("让大地裂开", [])
	t.call(quake.spell.get(&"shape", &""), &"quake", "v3_text_quake")
	var star := SpellSynthesizer.synthesize("星辰坠落", [])
	t.call(star.spell.get(&"shape", &""), &"meteor", "v3_text_meteor")
	var domain := SpellSynthesizer.synthesize("展开王的领域", [])
	t.call(domain.spell.get(&"shape", &""), &"domain", "v3_text_domain")
	var beam := SpellSynthesizer.synthesize("一道贯穿的光束", [])
	t.call(beam.spell.get(&"shape", &""), &"beam", "v3_text_beam")
	t.call(float(beam.components.get(&"pierce", 0.0)) > 0.0, true, "v3_text_pierce")
	var boom := SpellSynthesizer.synthesize("爆炸吧", [])
	t.call(float(boom.components.get(&"explosion", 0.0)) > 0.0, true, "v3_text_explosion")


func _test_numbers(t: Callable) -> void:
	t.call(SpellSynthesizer.parse_number("一百"), 100, "v3_number_yibai")
	t.call(SpellSynthesizer.parse_number("一百二十"), 120, "v3_number_120")
	t.call(SpellSynthesizer.parse_number("十"), 10, "v3_number_shi")
	t.call(SpellSynthesizer.parse_number("两千"), 2000, "v3_number_liangqian")
	t.call(SpellSynthesizer.parse_number("三万五"), 30005, "v3_number_wan")
	t.call(SpellSynthesizer.parse_number("48"), 48, "v3_number_digits")
	var volley := SpellSynthesizer.synthesize("一百颗追踪的火星", [])
	t.call(float(volley.components.get(&"projectiles", 0.0)), 100.0, "v3_text_count_sets_projectiles")
	var combo := SpellSynthesizer.synthesize("三连斩", [])
	t.call(int(combo.spell.get(&"pulses", 0)) >= 3, true, "v3_text_repeat_sets_pulses")
	var plain := SpellSynthesizer.synthesize("火焰", [])
	t.call(float(plain.components.get(&"projectiles", 0.0)), 0.0, "v3_no_number_no_volley")


func _test_claim_costs(t: Callable) -> void:
	var small := SpellSynthesizer.synthesize("火焰追踪", [])
	var huge := SpellSynthesizer.synthesize("一百颗火焰追踪", [])
	t.call(huge.ink_cost > small.ink_cost, true, "v3_big_claim_costs_more_ink")
	t.call(huge.corruption_gain > small.corruption_gain, true, "v3_big_claim_corrupts")
	t.call(huge.cooldown > small.cooldown, true, "v3_big_claim_cools_longer")
	var ctx := SpellContext.new()
	ctx.damage = 30.0
	t.call(ctx.share(1), 30.0, "v3_single_bolt_full_damage")
	t.call(ctx.share(96) < ctx.share(6), true, "v3_huge_volley_spreads_damage")
	t.call(ctx.share(96) * 96.0 > ctx.share(6) * 6.0, true, "v3_huge_volley_still_more_total")
	ctx.per_hit = true
	t.call(ctx.share(96), 30.0, "v3_ai_per_hit_damage_not_divided")
	var ai := SpellSynthesizer.compile_intent("百焰", {"name": "百焰", "shape": "missile", "tags": [&"flame"], "components": {"damage": 50.0, "projectiles": 40.0}}, [])
	t.call(bool(ai.spell.get(&"per_hit", false)), true, "v3_ai_intent_marks_per_hit")
