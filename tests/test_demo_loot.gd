extends RefCounted

## The Chapter 1 demo exposes exactly six weapons and six relics. Each one has
## a distinct, testable behaviour instead of a stat-swapped clone.

class DummyTarget extends Node2D:
	var damage_taken := 0
	var knockback := Vector2.ZERO
	var stun_left := 0.0
	var slow_left := 0.0
	var marked := false

	func take_damage(amount: int, _from := Vector2.ZERO) -> void:
		damage_taken += amount

	func apply_knockback(impulse: Vector2, _duration := 0.2) -> void:
		knockback = impulse

	func apply_stun(duration: float) -> void:
		stun_left = duration

	func apply_slow(_multiplier: float, duration: float) -> void:
		slow_left = duration

	func mark() -> void:
		marked = true


func run(t: Callable) -> void:
	_test_pool_sizes(t)
	_test_unique_identities(t)
	_test_special_behaviours(t)
	_test_demo_drops(t)
	_test_projectile_pierce(t)


func _test_pool_sizes(t: Callable) -> void:
	t.call(ContentLibrary.DEMO_WEAPONS.size(), 6, "demo_has_six_weapons")
	t.call(ContentLibrary.DEMO_RELICS.size(), 6, "demo_has_six_relics")


func _test_unique_identities(t: Callable) -> void:
	var specials: Dictionary = {}
	for resource in ContentLibrary.DEMO_WEAPONS:
		var weapon := resource as WeaponData
		t.call(weapon != null, true, "demo_weapon_is_data")
		if weapon == null:
			continue
		t.call(weapon.special_id != &"", true, "demo_weapon_special_%s" % weapon.id)
		t.call(specials.has(weapon.special_id), false, "demo_weapon_special_unique_%s" % weapon.id)
		specials[weapon.special_id] = true
	var effects: Dictionary = {}
	for resource in ContentLibrary.DEMO_RELICS:
		var relic := resource as RelicData
		t.call(relic != null, true, "demo_relic_is_data")
		if relic == null:
			continue
		t.call(effects.has(relic.effect_id), false, "demo_relic_effect_unique_%s" % relic.id)
		effects[relic.effect_id] = true


func _test_special_behaviours(t: Callable) -> void:
	t.call(WeaponSpecial.damage_multiplier(&"page_ripple", 3), 1.5, "page_sword_third_hit_bonus")
	t.call(WeaponSpecial.damage_multiplier(&"page_ripple", 1), 1.0, "page_sword_first_hit_normal")
	t.call(WeaponSpecial.projectile_count(&"echo_shot"), 3, "echo_flute_fires_three")
	t.call(WeaponSpecial.projectile_pierce(&"ink_pierce"), 3, "bolt_gun_pierces_three")

	var attacker := Node2D.new()
	attacker.global_position = Vector2.ZERO
	var target := DummyTarget.new()
	target.global_position = Vector2(100, 0)

	WeaponSpecial.on_hit(&"chain_pull", attacker, target)
	t.call(target.knockback.length() > 0.0, true, "chain_blade_pulls_target")
	WeaponSpecial.on_hit(&"ink_break", attacker, target)
	t.call(target.stun_left > 0.0, true, "ink_axe_stuns_target")
	WeaponSpecial.on_hit(&"talisman_mark", attacker, target)
	t.call(target.slow_left > 0.0, true, "talisman_gun_slows_target")
	t.call(target.has_meta(&"talisman_mark"), true, "talisman_gun_marks_target")

	var axe := MeleeWeapon.new()
	axe.data = load("res://resources/weapons/ink_axe.tres") as WeaponData
	var dummy := DummyTarget.new()
	axe.apply_hit(dummy)
	t.call(dummy.stun_left > 0.0, true, "melee_apply_hit_runs_special")
	axe.free()
	dummy.free()
	attacker.free()
	target.free()


func _test_demo_drops(t: Callable) -> void:
	var run := RunState.new()
	run.reset_for_new_run(99)
	var profile := Profile.new()
	var demo_weapons: Dictionary = {}
	for resource in ContentLibrary.DEMO_WEAPONS:
		demo_weapons[(resource as WeaponData).id] = true
	var demo_relics: Dictionary = {}
	for resource in ContentLibrary.DEMO_RELICS:
		demo_relics[(resource as RelicData).id] = true
	for attempt in 20:
		var options := RunLoot.choices(run, attempt + 1, profile, 0)
		for option in options:
			if option.get("kind", &"") == &"relic":
				t.call(demo_relics.has((option["resource"] as RelicData).id), true, "demo_relic_pool_only")
			elif option.get("kind", &"") == &"weapon":
				t.call(demo_weapons.has((option["resource"] as WeaponData).id), true, "demo_weapon_pool_only")
	for attempt in 20:
		var loot := RunLoot.chest_loot(run, profile, 0)
		if loot.get("kind", &"") == &"relic":
			t.call(demo_relics.has((loot["resource"] as RelicData).id), true, "demo_chest_relic_pool_only")
		elif loot.get("kind", &"") == &"weapon":
			t.call(demo_weapons.has((loot["resource"] as WeaponData).id), true, "demo_chest_weapon_pool_only")


func _test_projectile_pierce(t: Callable) -> void:
	var projectile := Projectile.new()
	projectile.pierce = 2
	var first := DummyTarget.new()
	var second := DummyTarget.new()
	projectile.hit_target(first)
	t.call(projectile.is_spent(), false, "piercing_projectile_survives_first_hit")
	t.call(first.damage_taken, projectile.damage, "piercing_projectile_damages_first")
	projectile.hit_target(second)
	t.call(projectile.is_spent(), true, "piercing_projectile_spends_last")
	projectile.free()
	first.free()
	second.free()
