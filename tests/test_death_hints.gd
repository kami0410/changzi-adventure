extends RefCounted

## Revive hints are copy-only: both paths keep their mechanical text, rotate
## per run without consuming run.rng, and never return another kind's line.

const KINDS: Array[StringName] = [&"authority", &"relic"]


func run(t: Callable) -> void:
	for kind in KINDS:
		var lines := DeathHintData.variants(kind)
		t.call(lines.size() >= 8, true, "death_hint_%s_count" % kind)
		var unique: Dictionary = {}
		for line in lines:
			t.call(String(line).strip_edges() != "", true, "death_hint_%s_non_empty" % kind)
			t.call(String(line).length() <= 24, true, "death_hint_%s_fits_banner" % kind)
			t.call(not String(line).contains("%"), true, "death_hint_%s_no_placeholder" % kind)
			unique[String(line)] = true
			if kind == &"authority":
				t.call(String(line).contains("续命生效"), true,
					"death_hint_authority_keeps_lead")
				t.call(String(line).contains("恢复 50 生命"), true,
					"death_hint_authority_keeps_mechanics")
			else:
				t.call(String(line).contains("不灭档案"), true,
					"death_hint_relic_keeps_relic")
				t.call(String(line).contains("翻回上一页"), true,
					"death_hint_relic_keeps_action")
		t.call(unique.size(), lines.size(), "death_hint_%s_unique" % kind)

		var first := DeathHintData.pick(4242, kind)
		t.call(first, DeathHintData.pick(4242, kind), "death_hint_%s_stable" % kind)
		t.call(lines.has(first), true, "death_hint_%s_returns_authored_line" % kind)
		var seen: Dictionary = {}
		for seed_value in 40:
			var line := DeathHintData.pick(seed_value, kind)
			t.call(lines.has(line), true, "death_hint_%s_known_%d" % [kind, seed_value])
			seen[line] = true
		t.call(seen.size() >= 3, true, "death_hint_%s_rotates" % kind)

	t.call(DeathHintData.variants(&"unknown").is_empty(), true,
		"death_hint_unknown_kind_empty")
	t.call(DeathHintData.pick(4242, &"unknown"), "", "death_hint_unknown_pick_empty")

	var run := RunState.new()
	run.reset_for_new_run(123)
	var state_before: int = run.rng.state
	DeathHintData.pick(run.run_seed, &"authority")
	DeathHintData.pick(run.run_seed + 1, &"relic")
	t.call(run.rng.state, state_before, "death_hint_pick_keeps_run_rng")
