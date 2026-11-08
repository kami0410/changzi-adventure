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
