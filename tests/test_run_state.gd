extends RefCounted


func run(t: Callable) -> void:
	var run := RunState.new()
	run.reset_for_new_run(123)
	t.call(run.run_seed, 123, "run_seed")
	t.call(run.rng.seed, 123, "rng_seed")
	t.call(run.health, 100, "run_health")
	t.call(run.ink, 100, "run_ink")
	t.call(run.corruption, 0, "run_corruption")

	var corruption_values: Array = []
	run.corruption_changed.connect(func(value): corruption_values.append(value))
	run.add_corruption(25)
	t.call(corruption_values.size(), 1, "corruption_signal_once")
	t.call(corruption_values[0], 25, "corruption_signal_value")
	t.call(run.corruption_tier(), 1, "corruption_tier_25")
	run.add_corruption(25)
	t.call(run.corruption_tier(), 2, "corruption_tier_50")
	t.call(run.corruption_tier_name(), "侵蚀", "corruption_name_50")
	t.call(run.corruption_damage_taken_multiplier(), 1.30, "corruption_damage_50")
	t.call(run.corruption_ink_cost_multiplier(), 1.30, "corruption_ink_50")
	t.call(run.corruption_cooldown_multiplier(), 1.20, "corruption_cooldown_50")
	t.call(run.corruption_tier_warning().contains("敌人伤害 +30%"), true, "corruption_warning_50")
	run.add_corruption(25)
	t.call(run.corruption_tier_name(), "深渊", "corruption_name_75")
	t.call(run.corruption_damage_taken_multiplier(), 1.45, "corruption_damage_75")
	run.add_corruption(25)
	t.call(run.corruption_tier_name(), "失控", "corruption_name_100")
	t.call(run.corruption_cooldown_multiplier(), 1.50, "corruption_cooldown_100")
	run.corruption = 50
	run.corruption_changed.emit(50)

	t.call(run.spend_ink(120), false, "spend_ink_too_much")
	t.call(run.spend_ink(30), true, "spend_ink_ok")
	t.call(run.ink, 70, "ink_after_spend")
	run.restore_ink(100)
	t.call(run.ink, 100, "ink_cap")

	run.take_damage(30)
	t.call(run.health, 70, "health_after_damage")
	run.heal(100)
	t.call(run.health, 100, "health_cap")

	var weapon := WeaponData.new()
	t.call(run.inventory.equip_weapon(0, weapon), true, "equip_weapon")
	t.call(run.inventory.weapons[0], weapon, "weapon_slot")
	t.call(run.inventory.equip_weapon(2, weapon), false, "equip_bad_slot")

	var relic := RelicData.new()
	relic.corruption = 7
	t.call(run.inventory.add_relic(relic), true, "add_relic")
	var word := WordData.new()
	word.corruption = 3
	run.inventory.add_word(word)
	t.call(run.inventory.total_corruption(), 10, "total_corruption")

	run.reset_for_new_run(321)
	t.call(run.run_seed, 321, "reset_seed")
	t.call(run.corruption, 0, "reset_corruption")
	t.call(run.inventory.weapons[0], null, "reset_inventory")
