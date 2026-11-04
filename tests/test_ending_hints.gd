extends RefCounted

## Ending return hints are copy-only: every line keeps the key prompt and the
## "回到最后的档案馆" destination, rotates per run + outcome without consuming
## run.rng, and never mixes victory/defeat copy.

const OUTCOMES: Array[bool] = [true, false]


func run(t: Callable) -> void:
	var all_lines: Dictionary = {}
	for won in OUTCOMES:
		var label := "win" if won else "lose"
		var lines := EndingHintData.variants(won)
		t.call(lines.size() >= 8, true, "ending_hint_%s_count" % label)
		var unique: Dictionary = {}
		for line in lines:
			t.call(String(line).strip_edges() != "", true,
				"ending_hint_%s_non_empty" % label)
			t.call(String(line).length() <= 24, true,
				"ending_hint_%s_fits_banner" % label)
			t.call(String(line).contains("按 %s"), true,
				"ending_hint_%s_keeps_key_prompt" % label)
			t.call(String(line).contains("回到最后的档案馆"), true,
				"ending_hint_%s_keeps_destination" % label)
			t.call(String(line).count("%s"), 1,
				"ending_hint_%s_one_placeholder" % label)
			t.call(String(line).replace("%s", "").contains("%"), false,
				"ending_hint_%s_no_other_placeholder" % label)
			unique[String(line)] = true
			all_lines[String(line)] = true
		t.call(unique.size(), lines.size(), "ending_hint_%s_unique" % label)

		var formatted := EndingHintData.format_hint(lines[0], "R")
		t.call(formatted.contains("按 R"), true,
			"ending_hint_%s_formats_key" % label)
		t.call(formatted.contains("回到最后的档案馆"), true,
			"ending_hint_%s_formatted_destination" % label)
		t.call(formatted.contains("%s"), false,
			"ending_hint_%s_formatted_no_placeholder" % label)

		var first := EndingHintData.pick(4242, won)
		t.call(first, EndingHintData.pick(4242, won),
			"ending_hint_%s_stable" % label)
		t.call(lines.has(first), true,
			"ending_hint_%s_returns_authored_line" % label)
		var seen: Dictionary = {}
		for seed_value in 40:
			var line := EndingHintData.pick(seed_value, won)
			t.call(lines.has(line), true,
				"ending_hint_%s_known_%d" % [label, seed_value])
			seen[line] = true
		t.call(seen.size() >= 3, true, "ending_hint_%s_rotates" % label)

	t.call(all_lines.size(), EndingHintData.variants(true).size()
		+ EndingHintData.variants(false).size(),
		"ending_hint_outcomes_disjoint")
	t.call(EndingHintData.format_hint("", "R"), "",
		"ending_hint_empty_template")
	t.call(EndingHintData.format_hint("按 %s 回到最后的档案馆", "Start"),
		"按 Start 回到最后的档案馆", "ending_hint_formats_pad_key")

	var run := RunState.new()
	run.reset_for_new_run(123)
	var state_before: int = run.rng.state
	EndingHintData.pick(run.run_seed, true)
	EndingHintData.pick(run.run_seed + 1, false)
	t.call(run.rng.state, state_before, "ending_hint_pick_keeps_run_rng")
