extends RefCounted

## 1.0 章节异象: one mutator per chapter per run, deterministic from the seed,
## every mutator has a name, a hint and at least one real hook.


func run(t: Callable) -> void:
	t.call(RunMutators.ALL.size(), 8, "mutator_count")
	for mutator in RunMutators.ALL:
		t.call(RunMutators.display_name(mutator).is_empty(), false, "mutator_name_%s" % mutator)
		t.call(RunMutators.hint(mutator).begins_with("本章异象 · "), true, "mutator_hint_%s" % mutator)
		var hooked := false
		for table in [RunMutators.ENEMY_HEALTH, RunMutators.ENEMY_SPEED, RunMutators.KILL_INK,
				RunMutators.KILL_PAGES_BONUS, RunMutators.KILL_PAGES_SCALE, RunMutators.ELITE_PAGES_SCALE,
				RunMutators.ELITE_EXTRA_CHANCE, RunMutators.EXTRA_ENEMIES, RunMutators.PHRASE_COOLDOWN,
				RunMutators.DAMAGE_TAKEN, RunMutators.DAMAGE_DEALT, RunMutators.CORRUPTION_GAIN,
				RunMutators.AGGRO_BONUS, RunMutators.WEAPON_DROP_SCALE]:
			if table.has(mutator):
				hooked = true
		t.call(hooked, true, "mutator_has_hook_%s" % mutator)
	t.call(RunMutators.hint(RunMutators.NONE), "", "mutator_none_silent")
	t.call(RunMutators.value(RunMutators.ENEMY_HEALTH, RunMutators.NONE), 1.0, "mutator_none_neutral")
	# Same seed + chapter -> same mutator; across seeds every mutator turns up,
	# and a run's chapters do not all share one.
	t.call(RunMutators.for_chapter(1234, 2), RunMutators.for_chapter(1234, 2), "mutator_deterministic")
	var seen := {}
	var varied := 0
	for seed in range(1, 200):
		var chapters := {}
		for chapter in 4:
			var m := RunMutators.for_chapter(seed, chapter)
			seen[m] = true
			chapters[m] = true
		if chapters.size() > 1:
			varied += 1
	t.call(seen.size(), RunMutators.ALL.size(), "mutator_all_reachable")
	t.call(varied > 180, true, "mutator_chapters_differ")
	var run := RunState.new()
	run.mutator_corruption_scale = RunMutators.value(RunMutators.CORRUPTION_GAIN, RunMutators.FOG)
	run.add_corruption(10)
	t.call(run.corruption, 6, "mutator_fog_slows_corruption")
	daily_seed(t)


## 每日挑战: one seed per calendar day, stable within the day.
static func daily_seed(t: Callable) -> void:
	var day := {"year": 2026, "month": 11, "day": 8}
	var next := {"year": 2026, "month": 11, "day": 9}
	t.call(GameFlow.daily_seed(day), GameFlow.daily_seed(day.duplicate()), "daily_seed_stable")
	t.call(GameFlow.daily_seed(day) != GameFlow.daily_seed(next), true, "daily_seed_changes_daily")
	t.call(GameFlow.daily_seed(day) > 0, true, "daily_seed_nonzero")
	t.call(GameFlow.daily_label(day), "每日挑战 · 11月8日", "daily_label")
	var run := RunState.new()
	run.reset_for_new_run(GameFlow.daily_seed(day))
	t.call(run.run_seed, GameFlow.daily_seed(day), "daily_seed_reaches_run")
	t.call(RunMutators.for_chapter(run.run_seed, 0), RunMutators.for_chapter(GameFlow.daily_seed(day), 0), "daily_same_mutators")
	var bad := {"run": {"room": "ch1_01", "daily": "yes"}, "inventory": {}}
	t.call(RunSave._has_valid_shape(bad), false, "daily_flag_must_be_bool")
