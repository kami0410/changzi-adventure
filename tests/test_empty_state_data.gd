extends RefCounted

## Empty-state copy: the Codex and Inventory keep their state meaning while the
## wording rotates by run seed + surface id. Picking must never consume run RNG.

const IDS: Array[StringName] = [
	&"codex_words", &"codex_combos", &"inventory_words", &"inventory_relics",
]


func run(t: Callable) -> void:
	var all_lines: Array[String] = []
	for state_id in IDS:
		var lines := EmptyStateData.variants(state_id)
		t.call(lines.size(), 8, "empty_%s_count" % state_id)
		var unique: Dictionary = {}
		for line in lines:
			t.call(line.strip_edges() != "", true, "empty_%s_non_empty" % state_id)
			t.call(line.length() <= 48, true, "empty_%s_length" % state_id)
			t.call(line.contains("{"), false, "empty_%s_no_placeholder" % state_id)
			unique[line] = true
			all_lines.append(line)
		t.call(unique.size(), lines.size(), "empty_%s_unique" % state_id)
	t.call(EmptyStateData.variants(&"__missing__").is_empty(), true,
		"empty_unknown_variants")

	for line in EmptyStateData.variants(&"codex_words"):
		t.call(line.contains("尚未收集任何词"), true, "empty_codex_words_meaning")
	for line in EmptyStateData.variants(&"inventory_words"):
		t.call(line.contains("尚未收集任何词"), true, "empty_inventory_words_meaning")
	for line in EmptyStateData.variants(&"inventory_relics"):
		t.call(line.contains("尚未获得遗物"), true, "empty_inventory_relics_meaning")
	for line in EmptyStateData.variants(&"codex_combos"):
		t.call(line.contains("尚未发现组合"), true, "empty_combos_meaning")
		t.call(line.contains("在造句台"), true, "empty_combos_forge_hint")
		t.call(line.contains("2–3 个词"), true, "empty_combos_word_count_hint")
		t.call(line.contains("配方会记录在这里"), true, "empty_combos_record_hint")

	t.call(EmptyStateData.pick(&"__missing__"), "", "empty_unknown_pick_empty")
	for state_id in IDS:
		var lines := EmptyStateData.variants(state_id)
		var picked := EmptyStateData.pick(state_id, 424242)
		t.call(lines.has(picked), true, "empty_%s_pick_from_variants" % state_id)
		var stable := true
		for index in 100:
			if EmptyStateData.pick(state_id, 424242) != picked:
				stable = false
		t.call(stable, true, "empty_%s_stable" % state_id)
		var seen: Dictionary = {}
		for seed_value in 40:
			seen[EmptyStateData.pick(state_id, seed_value)] = true
		t.call(seen.size() >= 3, true, "empty_%s_rotates" % state_id)
	t.call(EmptyStateData.pick(&"codex_words", 7)
		== EmptyStateData.pick(&"codex_words", 7), true, "empty_same_seed_id_stable")

	# Selection is copy-only: it must not read or advance the run's RNG stream.
	var run_state := RunState.new()
	run_state.reset_for_new_run(90210)
	var before := run_state.rng.state
	for index in 200:
		for state_id in IDS:
			EmptyStateData.pick(state_id, run_state.run_seed)
	t.call(run_state.rng.state, before, "empty_does_not_advance_run_rng")
	t.call(run_state.run_seed, 90210, "empty_keeps_run_seed")

	# A seed change must be able to change the wording (not a constant string).
	var changed := false
	for seed_value in 40:
		var candidate := EmptyStateData.pick(&"codex_words", seed_value)
		if candidate != EmptyStateData.pick(&"codex_words", 0):
			changed = true
			break
	t.call(changed, true, "empty_seed_changes_copy")
