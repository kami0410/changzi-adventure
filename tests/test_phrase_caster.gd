extends RefCounted


func run(t: Callable) -> void:
	_test_equip_and_validation(t)
	_test_damage_and_area(t)
	_test_heal_and_lifesteal(t)
	_test_ink_and_corruption(t)
	_test_cooldown_and_disabled(t)
	_test_slow(t)
	_test_projectile_and_summon(t)
	_test_enemy_root_and_group(t)


func _make_run(seed_value: int = 1) -> RunState:
	var run := RunState.new()
	run.reset_for_new_run(seed_value)
	return run


func _make_player(health: int = 100) -> Player:
	var player := Player.new()
	player.max_health = 100
	player.health = health
	return player


func _make_enemy(position: Vector2, health: int = 50) -> Enemy:
	var enemy := Enemy.new()
	enemy.max_health = health
	enemy.health = health
	enemy.position = position
	return enemy


func _make_phrase(components: Dictionary, ink_cost: int = 0, cooldown: float = 0.0, corruption_gain: int = 0) -> ResolvedPhrase:
	var phrase := ResolvedPhrase.new()
	phrase.display_name = "测试短语"
	phrase.components = components
	phrase.ink_cost = ink_cost
	phrase.cooldown = cooldown
	phrase.corruption_gain = corruption_gain
	return phrase


func _make_caster(run: RunState, player: Player, enemies: Array[Enemy]) -> PhraseCaster:
	var caster := PhraseCaster.new()
	caster.bind_run_state(run)
	caster.set_player(player)
	caster.set_enemies(enemies)
	return caster


func _test_equip_and_validation(t: Callable) -> void:
	var run := _make_run()
	var player := _make_player()
	var caster := PhraseCaster.new()
	var phrase := _make_phrase({})
	t.call(caster.equip_phrase(0, phrase), true, "equip_valid_slot")
	t.call(caster.equip_phrase(1, phrase), true, "equip_second_slot")
	t.call(caster.equip_phrase(-1, phrase), false, "equip_negative_slot")
	t.call(caster.equip_phrase(2, phrase), false, "equip_out_of_range_slot")
	t.call(caster.equip_phrase(0, null), false, "equip_null_phrase")
	t.call(caster.cast(0), false, "cast_without_bindings")
	caster.bind_run_state(run)
	caster.set_player(player)
	t.call(caster.is_ready(0), true, "ready_after_bind")
	t.call(caster.cast(0), true, "cast_empty_phrase")
	t.call(caster.cast(2), false, "cast_out_of_range_slot")
	caster.free()
	player.free()


func _test_damage_and_area(t: Callable) -> void:
	var run := _make_run()
	var player := _make_player()
	var near := _make_enemy(Vector2(40.0, 0.0), 50)
	var far := _make_enemy(Vector2(500.0, 0.0), 50)
	var enemies: Array[Enemy] = [near, far]
	var caster := _make_caster(run, player, enemies)
	t.call(caster.equip_phrase(0, _make_phrase({&"damage": 12.0})), true, "damage_equip")
	t.call(caster.cast(0), true, "damage_cast")
	t.call(near.health, 38, "damage_hits_enemy_in_range")
	t.call(far.health, 50, "damage_skips_enemy_out_of_range")

	caster.equip_phrase(1, _make_phrase({&"damage": 5.0, &"area": 2.0}))
	t.call(caster.cast(1), true, "area_cast")
	t.call(far.health, 45, "area_expands_radius")
	t.call(near.health, 33, "area_still_hits_near")
	caster.free()
	player.free()
	near.free()
	far.free()


func _test_heal_and_lifesteal(t: Callable) -> void:
	var run := _make_run()
	var player := _make_player(50)
	var enemy := _make_enemy(Vector2(20.0, 0.0), 50)
	var enemies: Array[Enemy] = [enemy]
	var caster := _make_caster(run, player, enemies)
	caster.equip_phrase(0, _make_phrase({&"heal": 8.0}))
	t.call(caster.cast(0), true, "heal_cast")
	t.call(player.health, 58, "heal_component_heals_player")

	caster.equip_phrase(1, _make_phrase({&"damage": 10.0, &"lifesteal": 0.5}))
	t.call(caster.cast(1), true, "lifesteal_cast")
	t.call(enemy.health, 40, "lifesteal_damages_enemy")
	t.call(player.health, 63, "lifesteal_heals_by_damage")
	caster.free()
	player.free()
	enemy.free()


func _test_ink_and_corruption(t: Callable) -> void:
	var run := _make_run()
	run.ink = 30
	var player := _make_player()
	var no_enemies: Array[Enemy] = []
	var caster := _make_caster(run, player, no_enemies)
	caster.equip_phrase(0, _make_phrase({&"ink_gain": 15.0, &"corruption_gain": 6.0}, 10))
	t.call(caster.cast(0), true, "ink_cost_cast")
	t.call(run.ink, 35, "ink_cost_and_gain")
	t.call(run.corruption, 6, "corruption_gain_component")

	caster.equip_phrase(1, _make_phrase({}, 0, 0.0, 4))
	t.call(caster.cast(1), true, "phrase_corruption_cast")
	t.call(run.corruption, 10, "phrase_corruption_fallback")

	run.corruption = 50
	run.ink = 30
	caster.equip_phrase(0, _make_phrase({}, 10, 2.0))
	t.call(caster.effective_ink_cost(0), 13, "corruption_raises_ink_cost")
	t.call(caster.cast(0), true, "corruption_cast_spends_more")
	t.call(run.ink, 17, "corruption_ink_spent")
	t.call(is_equal_approx(caster.get_cooldown_left(0), 2.4), true, "corruption_extends_cooldown")

	run.corruption = 20
	caster.equip_phrase(1, _make_phrase({&"purify": 5.0}, 0))
	t.call(caster.cast(1), true, "purify_cast")
	t.call(run.corruption, 15, "purify_reduces_corruption")

	run.corruption = 10
	run.ink = 0
	caster.equip_phrase(0, _make_phrase({&"corruption_gain": 5.0}, 1))
	t.call(caster.is_ready(0), false, "not_ready_without_ink")
	t.call(caster.cast(0), false, "cast_fails_without_ink")
	t.call(run.corruption, 10, "failed_cast_no_corruption")
	caster.free()
	player.free()


func _test_cooldown_and_disabled(t: Callable) -> void:
	var run := _make_run()
	run.ink = 100
	var player := _make_player()
	var enemy := _make_enemy(Vector2(20.0, 0.0), 100)
	var enemies: Array[Enemy] = [enemy]
	var caster := _make_caster(run, player, enemies)
	caster.equip_phrase(0, _make_phrase({&"damage": 3.0}, 5, 2.0))
	t.call(caster.is_ready(0), true, "cooldown_initially_ready")
	t.call(caster.cast(0), true, "cooldown_first_cast")
	t.call(caster.is_ready(0), false, "cooldown_blocks_ready")
	t.call(caster.cast(0), false, "cooldown_blocks_cast")
	t.call(caster.get_cooldown_left(0), 2.0, "cooldown_left_full")
	caster.equip_phrase(0, _make_phrase({&"damage": 5.0}, 10, 2.0))
	t.call(caster.get_cooldown_left(0), 2.0, "changing_phrase_preserves_slot_cooldown")
	caster.tick(1.0)
	t.call(caster.is_ready(0), false, "cooldown_partial")
	caster.tick(1.0)
	t.call(caster.is_ready(0), true, "cooldown_finished")
	t.call(caster.cast(0), true, "cooldown_cast_again")

	player.disabled_phrase_slots[0] = true
	caster.tick(10.0)
	var ink_before := run.ink
	t.call(caster.is_ready(0), false, "disabled_slot_not_ready")
	t.call(caster.cast(0), false, "disabled_slot_blocks_cast")
	t.call(run.ink, ink_before, "disabled_cast_no_ink_spent")
	player.disabled_phrase_slots[0] = false
	t.call(caster.is_ready(0), true, "enabled_slot_ready_again")
	caster.free()
	player.free()
	enemy.free()


func _test_slow(t: Callable) -> void:
	var run := _make_run()
	var player := _make_player()
	var enemy := _make_enemy(Vector2(20.0, 0.0), 100)
	var enemies: Array[Enemy] = [enemy]
	var caster := _make_caster(run, player, enemies)
	caster.slow_duration = 1.0
	caster.equip_phrase(0, _make_phrase({&"slow": 0.5}))
	t.call(caster.cast(0), true, "slow_cast")
	t.call(enemy.is_slowed(), true, "slow_applied")
	t.call(enemy.get_move_speed(), 40.0, "slow_halves_speed")
	enemy.tick_status_effects(0.5)
	t.call(enemy.get_move_speed(), 40.0, "slow_lasts_duration")
	enemy.tick_status_effects(0.6)
	t.call(enemy.is_slowed(), false, "slow_expires")
	t.call(enemy.get_move_speed(), 80.0, "slow_speed_restored")

	caster.slow_duration = 0.5
	caster.equip_phrase(1, _make_phrase({&"slow": 0.25, &"duration": 1.0}))
	t.call(caster.cast(1), true, "slow_duration_component_cast")
	t.call(enemy.get_move_speed(), 60.0, "slow_quarter_reduction")
	enemy.tick_status_effects(1.4)
	t.call(enemy.get_move_speed(), 60.0, "slow_duration_component_active")
	enemy.tick_status_effects(0.2)
	t.call(enemy.get_move_speed(), 80.0, "slow_duration_component_expires")
	caster.free()
	player.free()
	enemy.free()


func _test_projectile_and_summon(t: Callable) -> void:
	var run := _make_run()
	var player := _make_player()
	player.facing = Vector2.LEFT
	var no_enemies: Array[Enemy] = []
	var caster := _make_caster(run, player, no_enemies)
	caster.equip_phrase(0, _make_phrase({&"projectile": 1.0, &"damage": 9.0, &"summon": 1.0}))
	t.call(caster.cast(0), true, "projectile_cast")
	var projectile := caster.get_child(0) as Projectile
	t.call(projectile != null, true, "projectile_spawned")
	if projectile != null:
		t.call(projectile.damage, 9, "projectile_damage")
		t.call(projectile.direction, Vector2.LEFT, "projectile_direction")
		t.call(projectile.position, Vector2(-20.0, -24.0), "projectile_spawns_at_hand_height")
	caster.free()
	player.free()


func _test_enemy_root_and_group(t: Callable) -> void:
	var run := _make_run()
	var player := _make_player()
	var root := Node2D.new()
	var root_enemy := _make_enemy(Vector2(30.0, 0.0), 50)
	root.add_child(root_enemy)
	var caster := PhraseCaster.new()
	caster.bind_run_state(run)
	caster.set_player(player)
	caster.set_enemy_root(root)
	caster.equip_phrase(0, _make_phrase({&"damage": 10.0}))
	t.call(caster.cast(0), true, "enemy_root_cast")
	t.call(root_enemy.health, 40, "enemy_root_damages_child")
	caster.free()
	player.free()
	root.free()
	# enemies 组的回退路径需要真实树帧（run_tests 在 _initialize 中同步执行，
	# 此时 root 尚未入树），因此这里只验证 set_enemy_root 的同步收集。
