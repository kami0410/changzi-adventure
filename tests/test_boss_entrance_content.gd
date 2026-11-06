extends RefCounted

## Boss entrance flavour: every variant stays copy-only, the authored chapter
## pools rotate per run without consuming the run RNG, and chapters without
## authored copy keep the silent entrance (empty line).


func run(t: Callable) -> void:
	_test_variants(t)
	_test_selection(t)
	_test_rng_untouched(t)


func _test_variants(t: Callable) -> void:
	var lines := BossEntranceData.variants(0)
	t.call(lines.size() >= 8, true, "boss_entrance_has_multiple_lines")
	var unique: Dictionary = {}
	for line in lines:
		t.call(line.strip_edges() != "", true, "boss_entrance_line_non_empty")
		t.call(line.length() <= 24, true, "boss_entrance_line_fits_banner")
		t.call(not line.contains("%"), true, "boss_entrance_line_has_no_placeholder")
		unique[line] = true
	t.call(unique.size(), lines.size(), "boss_entrance_lines_unique")
	t.call(BossEntranceData.variants(3).size() >= 8, true,
		"boss_entrance_chapter_4_has_its_own_copy")
	t.call(BossEntranceData.variants(4).is_empty(), true,
		"boss_entrance_out_of_range_has_no_flavor")


func _test_selection(t: Callable) -> void:
	var lines := BossEntranceData.variants(0)
	var first := BossEntranceData.pick(4242, 0)
	t.call(first, BossEntranceData.pick(4242, 0), "boss_entrance_pick_stable")
	t.call(lines.has(first), true, "boss_entrance_pick_returns_authored_line")
	var seen: Dictionary = {}
	for seed in 40:
		var line := BossEntranceData.pick(seed, 0)
		t.call(lines.has(line), true, "boss_entrance_pick_known_%d" % seed)
		seen[line] = true
	t.call(seen.size() >= 3, true, "boss_entrance_pick_rotates")
	t.call(BossEntranceData.pick(4242, 4), "", "boss_entrance_out_of_range_pick_is_empty")


func _test_rng_untouched(t: Callable) -> void:
	var run := RunState.new()
	run.rng.seed = 123456
	var state_before: int = run.rng.state
	BossEntranceData.pick(4242, 0)
	BossEntranceData.pick(4243, 0)
	t.call(run.rng.state, state_before, "boss_entrance_pick_keeps_run_rng")
