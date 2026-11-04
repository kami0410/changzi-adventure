extends RefCounted

## Copy-only coverage for the corruption tier warnings: enough variants per
## tier, unique text, exact mechanics kept, stable per run + tier, rotating
## across runs, and no run RNG consumed.

const TIERS: Array[int] = [1, 2, 3, 4]
const MECHANICS := {
	1: ["敌人伤害 +15%", "短语墨耗 +15%"],
	2: ["敌人伤害 +30%", "短语墨耗 +30%", "冷却 +20%"],
	3: ["敌人伤害 +45%", "短语墨耗 +45%", "冷却 +35%"],
}


func run(t: Callable) -> void:
	for tier in TIERS:
		var variants := CorruptionWarningData.variants(tier)
		t.call(variants.size(), 4, "corruption_warning_%d_variant_count" % tier)
		var unique: Dictionary = {}
		for line in variants:
			t.call(String(line) != "", true, "corruption_warning_%d_non_empty" % tier)
			unique[String(line)] = true
			if tier < 4:
				for fragment in MECHANICS[tier]:
					t.call(String(line).contains(fragment), true,
						"corruption_warning_%d_keeps_%s" % [tier, fragment])
			else:
				t.call(String(line).begins_with("污染失控"), true,
					"corruption_warning_4_frenzy")
		t.call(unique.size(), variants.size(), "corruption_warning_%d_unique" % tier)
	t.call(CorruptionWarningData.variants(0).is_empty(), true, "corruption_warning_tier0_empty")
	t.call(CorruptionWarningData.pick(1, 0), "", "corruption_warning_pick_tier0_empty")

	for tier in TIERS:
		var first := CorruptionWarningData.pick(4242, tier)
		t.call(CorruptionWarningData.pick(4242, tier), first,
			"corruption_warning_%d_stable" % tier)
		var seen: Dictionary = {}
		for seed_value in 40:
			seen[CorruptionWarningData.pick(seed_value, tier)] = true
		t.call(seen.size() >= 3, true, "corruption_warning_%d_rotates" % tier)

	var run := RunState.new()
	run.reset_for_new_run(123)
	var state_before: int = run.rng.state
	t.call(run.corruption_tier_warning(), "", "corruption_warning_quiet_run")
	run.add_corruption(25)
	t.call(run.corruption_tier_warning(), CorruptionWarningData.pick(123, 1),
		"corruption_warning_run_tier_1")
	run.add_corruption(25)
	t.call(run.corruption_tier_warning(), CorruptionWarningData.pick(123, 2),
		"corruption_warning_run_tier_2")
	run.add_corruption(25)
	t.call(run.corruption_tier_warning(), CorruptionWarningData.pick(123, 3),
		"corruption_warning_run_tier_3")
	run.add_corruption(25)
	t.call(run.corruption_tier_warning(), CorruptionWarningData.pick(123, 4),
		"corruption_warning_run_tier_4")
	t.call(run.rng.state, state_before, "corruption_warning_keeps_rng")
