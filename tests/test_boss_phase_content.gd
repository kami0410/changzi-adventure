extends RefCounted

## Boss phase flavor: every variant stays copy-only, the phase 2/3 pools rotate
## per run without consuming the run RNG, and unknown phases keep the plain
## mechanical banner (empty flavor).


func run(t: Callable) -> void:
	_test_variants(t)
	_test_selection(t)
	_test_rng_untouched(t)


func _test_variants(t: Callable) -> void:
	var all_lines: Dictionary = {}
	for phase in [2, 3]:
		var lines := BossPhaseData.variants(phase)
		t.call(lines.size() >= 8, true, "boss_phase_%d_has_multiple_lines" % phase)
		var unique: Dictionary = {}
		for line in lines:
			t.call(line.strip_edges() != "", true, "boss_phase_%d_line_non_empty" % phase)
			t.call(line.length() <= 24, true, "boss_phase_%d_line_fits_banner" % phase)
			t.call(not line.contains("%"), true, "boss_phase_%d_line_has_no_placeholder" % phase)
			unique[line] = true
			t.call(not all_lines.has(line), true, "boss_phase_%d_line_unique_across_phases" % phase)
			all_lines[line] = true
		t.call(unique.size(), lines.size(), "boss_phase_%d_lines_unique" % phase)
	t.call(BossPhaseData.variants(1).is_empty(), true, "boss_phase_1_has_no_flavor")
	t.call(BossPhaseData.variants(4).is_empty(), true, "boss_phase_4_has_no_flavor")


func _test_selection(t: Callable) -> void:
	for phase in [2, 3]:
		var lines := BossPhaseData.variants(phase)
		var first := BossPhaseData.pick(4242, phase)
		t.call(first, BossPhaseData.pick(4242, phase), "boss_phase_%d_pick_stable" % phase)
		t.call(lines.has(first), true, "boss_phase_%d_pick_returns_authored_line" % phase)
		var seen: Dictionary = {}
		for seed in 40:
			var line := BossPhaseData.pick(seed, phase)
			t.call(lines.has(line), true, "boss_phase_%d_pick_known_%d" % [phase, seed])
			seen[line] = true
		t.call(seen.size() >= 3, true, "boss_phase_%d_pick_rotates" % phase)
	t.call(BossPhaseData.pick(4242, 1), "", "boss_phase_1_pick_is_empty")
	t.call(BossPhaseData.pick(4242, 4), "", "boss_phase_4_pick_is_empty")


func _test_rng_untouched(t: Callable) -> void:
	var run := RunState.new()
	run.rng.seed = 123456
	var state_before: int = run.rng.state
	BossPhaseData.pick(4242, 2)
	BossPhaseData.pick(4243, 3)
	t.call(run.rng.state, state_before, "boss_phase_pick_keeps_run_rng")
