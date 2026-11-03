extends RefCounted

class StubEnemy:
	extends Enemy
	var taken := 0
	func take_damage(amount: int) -> void:
		taken += amount
		health = maxi(health - amount, 0)

func _phrase(words: Array, tags: Array[StringName], components: Dictionary) -> ResolvedPhrase:
	var phrase := ResolvedPhrase.new()
	phrase.components = components
	phrase.tags = tags
	phrase.spell = SpellStyle.decide(tags, components)
	phrase.ink_cost = 0
	phrase.cooldown = 0.0
	return phrase

func run(t: Callable) -> void:
	var player := Player.new()
	player.health = 100
	var run := RunState.new()
	run.ink = 100
	var caster := PhraseCaster.new()
	caster.bind_run_state(run)
	caster.set_player(player)
	caster.damage_scale = 1.0
	var near := StubEnemy.new()
	near.position = Vector2(90, 0)
	near.health = 1000
	var far := StubEnemy.new()
	far.position = Vector2(260, 0)
	far.health = 1000
	var behind := StubEnemy.new()
	behind.position = Vector2(-120, 0)
	behind.health = 1000
	var enemies: Array[Enemy] = [near, far, behind]
	caster.set_enemies(enemies)
	caster.equip_phrase(0, _phrase([], [&"flame"], {&"damage": 10.0}))
	t.call(caster.cast(0), true, "flame_casts")
	t.call(near.taken, 10, "flame_hits_enemy_in_front")
	t.call(far.taken, 0, "flame_respects_cone_range")
	t.call(behind.taken, 0, "flame_does_not_hit_behind")
	t.call(near.get_node_or_null("BurnStatus") != null, true, "flame_applies_burn")
	caster.equip_phrase(0, _phrase([], [&"thunder"], {&"damage": 10.0}))
	t.call(caster.cast(0), true, "chain_casts")
	t.call(near.taken > 10, true, "chain_adds_damage")
	t.call(far.taken > 0, true, "chain_reaches_second_enemy")
	caster.equip_phrase(0, _phrase([], [&"summon"], {&"damage": 10.0}))
	t.call(caster.cast(0), true, "sentinel_casts")
	t.call(player.health, 100, "summon_does_not_damage_caster")
	caster.equip_phrase(0, _phrase([], [&"time"], {&"damage": 10.0}))
	t.call(caster.cast(0), true, "vortex_casts")
	caster.equip_phrase(0, _phrase([], [&"shield"], {&"damage": 10.0, &"shield": 9.0}))
	t.call(caster.cast(0), true, "ward_casts")
	t.call(player.shield >= 9, true, "ward_grants_shield")
	player.free()
	near.free()
	far.free()
	behind.free()
	caster.free()
