extends RefCounted


func run(t: Callable) -> void:
	var damageable := Damageable.new()
	t.call(damageable.health, 10, "damageable_init")
	var health_values: Array = []
	damageable.health_changed.connect(func(value, _maximum): health_values.append(value))
	damageable.take_damage(3)
	t.call(damageable.health, 7, "damageable_take")
	damageable.heal(5)
	t.call(damageable.health, 10, "damageable_heal_cap")

	var died_count := [0]
	damageable.died.connect(func(): died_count[0] += 1)
	damageable.take_damage(20)
	t.call(damageable.health, 0, "damageable_death")
	t.call(died_count[0], 1, "damageable_died_once")
	damageable.take_damage(5)
	t.call(died_count[0], 1, "damageable_no_double_death")

	var player := Player.new()
	t.call(player.health, 100, "player_health")
	player.start_dodge()
	t.call(player.is_dodging, true, "player_dodging")
	t.call(player.is_invulnerable(), true, "player_iframes")
	player.take_damage(10)
	t.call(player.health, 100, "player_dodge_blocks")

	var player2 := Player.new()
	player2.take_damage(10)
	t.call(player2.health, 90, "player_take_damage")
	player2.take_damage(10)
	t.call(player2.health, 90, "player_hit_iframes")
	player2.heal(100)
	t.call(player2.health, 100, "player_heal_cap")
	t.call(player2.disable_phrase_slot(0), true, "player_disable_slot")
	t.call(player2.disabled_phrase_slots[0], true, "player_slot_disabled")
	t.call(player2.disable_phrase_slot(2), false, "player_bad_slot")

	var starter := WeaponData.new()
	starter.kind = WeaponData.Kind.MELEE
	t.call(player2.equip_weapon(0, starter), true, "player_equip_weapon")
	t.call(player2.weapons[0] != null, true, "player_weapon_created")
	t.call(player2.switch_weapon(0), true, "player_switch_weapon")

	damageable.free()
	player.free()
	player2.free()
