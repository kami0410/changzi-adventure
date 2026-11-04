extends RefCounted

## Hub shop failure lines are copy-only: each kind keeps its mechanical prefix
## (and both numbers for insufficient fragments), rotates by a fixed kind+item
## id without consuming randomness, and never mixes the three kinds.

const KINDS: Array[StringName] = [&"owned", &"insufficient", &"missing"]


func run(t: Callable) -> void:
	var all_lines: Dictionary = {}
	var counts := {&"owned": 8, &"insufficient": 8, &"missing": 4}
	for kind in KINDS:
		var lines := ShopFailData.variants(kind)
		var label := String(kind)
		t.call(lines.size() >= int(counts[kind]), true,
			"shop_fail_%s_count" % label)
		var unique: Dictionary = {}
		for line in lines:
			var text := String(line).strip_edges()
			t.call(text != "", true, "shop_fail_%s_non_empty" % label)
			t.call(text.length() <= 48, true, "shop_fail_%s_fits_message" % label)
			unique[text] = true
			all_lines[text] = true
		t.call(unique.size(), lines.size(), "shop_fail_%s_unique" % label)

	for line in ShopFailData.variants(&"owned"):
		t.call(String(line).begins_with("这件货已经在你的手里了。"), true,
			"shop_fail_owned_keeps_prefix")
		t.call(String(line).contains("{"), false,
			"shop_fail_owned_no_placeholder")
	for line in ShopFailData.variants(&"missing"):
		t.call(String(line).begins_with("没有这件货。"), true,
			"shop_fail_missing_keeps_prefix")
		t.call(String(line).contains("{"), false,
			"shop_fail_missing_no_placeholder")
	for line in ShopFailData.variants(&"insufficient"):
		var text := String(line)
		t.call(text.begins_with("记忆碎片不足"), true,
			"shop_fail_insufficient_keeps_prefix")
		t.call(text.count("{cost}"), 1, "shop_fail_insufficient_one_cost")
		t.call(text.count("{have}"), 1, "shop_fail_insufficient_one_have")
		t.call(text.replace("{cost}", "").replace("{have}", "").contains("{"), false,
			"shop_fail_insufficient_no_other_placeholder")
		var formatted := ShopFailData.format(text, 42, 7)
		t.call(formatted.contains("42"), true,
			"shop_fail_insufficient_formats_cost")
		t.call(formatted.contains("7"), true,
			"shop_fail_insufficient_formats_have")
		t.call(formatted.contains("{"), false,
			"shop_fail_insufficient_formatted_no_placeholder")

	t.call(ShopFailData.format("没有这件货。", 42, 7), "没有这件货。",
		"shop_fail_format_passthrough")
	t.call(ShopFailData.format("需要 {cost}，你只有 {have}。", 12, 3),
		"需要 12，你只有 3。", "shop_fail_format_both")

	for kind in KINDS:
		var label := String(kind)
		var first := ShopFailData.pick(kind, &"jilu")
		t.call(first, ShopFailData.pick(kind, &"jilu"),
			"shop_fail_%s_stable" % label)
		t.call(ShopFailData.variants(kind).has(first), true,
			"shop_fail_%s_returns_authored_line" % label)
		var seen: Dictionary = {}
		for index in 40:
			var item_id := StringName("item_%d" % index)
			var line := ShopFailData.pick(kind, item_id)
			t.call(ShopFailData.variants(kind).has(line), true,
				"shop_fail_%s_known_%d" % [label, index])
			seen[line] = true
		t.call(seen.size() >= 3, true, "shop_fail_%s_rotates" % label)

	t.call(ShopFailData.variants(&"unknown").is_empty(), true,
		"shop_fail_unknown_kind_empty")
	t.call(ShopFailData.pick(&"unknown", &"jilu"), "",
		"shop_fail_unknown_kind_blank")
	t.call(all_lines.size(),
		ShopFailData.variants(&"owned").size()
		+ ShopFailData.variants(&"insufficient").size()
		+ ShopFailData.variants(&"missing").size(),
		"shop_fail_kinds_disjoint")

	var run := RunState.new()
	run.reset_for_new_run(2024)
	var state_before: int = run.rng.state
	for kind in KINDS:
		for index in 20:
			ShopFailData.pick(kind, StringName("id_%d" % index))
			ShopFailData.format(ShopFailData.pick(kind, &"jilu"), index, index)
	t.call(run.rng.state, state_before, "shop_fail_pick_keeps_run_rng")
