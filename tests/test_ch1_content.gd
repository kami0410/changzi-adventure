extends RefCounted

## Chapter 1 flavor fill: the event room rotates between authored pages, and a
## stele's epitaph is stable per stone. Both are copy-only; the mechanics stay
## in Ch1EventData constants / MemoryStele's existing reward roll.

const EVENT_KEYS: Array[String] = [
	"eyebrow", "title", "body", "read_label", "take_label",
	"read_word_message", "read_pages_message", "take_message",
]


func run(t: Callable) -> void:
	_test_event_variants(t)
	_test_event_selection(t)
	_test_event_messages(t)
	_test_stele_epitaphs(t)
	_test_shop_lines(t)
	_test_shop_buy_lines(t)
	_test_rest_offers(t)
	_test_rest_room_lines(t)
	_test_vault_room_lines(t)


func _test_event_variants(t: Callable) -> void:
	var variants := Ch1EventData.variants()
	t.call(variants.size() >= 7, true, "ch1_event_has_multiple_variants")
	var eyebrows: Dictionary = {}
	for variant in variants:
		var label := String(variant.get("eyebrow", ""))
		t.call(label != "", true, "ch1_event_variant_has_eyebrow")
		eyebrows[label] = true
		for key in EVENT_KEYS:
			t.call(String(variant.get(key, "")) != "", true,
				"ch1_event_%s_%s" % [label, key])
	t.call(eyebrows.size(), variants.size(), "ch1_event_variants_unique")
	t.call(Ch1EventData.CORRUPTION_COST > 0, true, "ch1_event_corruption_cost_positive")
	t.call(Ch1EventData.PAGES_REWARD > Ch1EventData.FALLBACK_PAGES, true,
		"ch1_event_taking_pays_more_than_fallback")


func _test_event_selection(t: Callable) -> void:
	var first := Ch1EventData.pick(4242, "ch1_05")
	var second := Ch1EventData.pick(4242, "ch1_05")
	t.call(first, second, "ch1_event_pick_is_stable_per_run")
	var known: Dictionary = {}
	for variant in Ch1EventData.variants():
		known[String(variant.get("eyebrow", ""))] = true
	var seen: Dictionary = {}
	for seed in 40:
		var event := Ch1EventData.pick(seed, "ch1_05")
		t.call(known.has(String(event.get("eyebrow", ""))), true,
			"ch1_event_pick_returns_authored_variant_%d" % seed)
		seen[String(event.get("eyebrow", ""))] = true
	t.call(seen.size() >= 2, true, "ch1_event_pick_rotates_across_runs")


func _test_event_messages(t: Callable) -> void:
	for variant in Ch1EventData.variants():
		var decoded := String(variant["read_word_message"]) % ["词", Ch1EventData.CORRUPTION_COST]
		var fallback := String(variant["read_pages_message"]) % [
			Ch1EventData.FALLBACK_PAGES, Ch1EventData.CORRUPTION_COST]
		var take := String(variant["take_message"]) % Ch1EventData.PAGES_REWARD
		t.call(decoded.contains("词"), true, "ch1_event_word_message_formats")
		t.call(decoded.contains(str(Ch1EventData.CORRUPTION_COST)), true,
			"ch1_event_word_message_shows_corruption")
		t.call(fallback.contains(str(Ch1EventData.FALLBACK_PAGES)), true,
			"ch1_event_fallback_message_shows_pages")
		t.call(take.contains(str(Ch1EventData.PAGES_REWARD)), true,
			"ch1_event_take_message_shows_pages")


func _test_stele_epitaphs(t: Callable) -> void:
	t.call(MemoryStele.EPITAPHS.size() >= 8, true, "stele_has_multiple_epitaphs")
	var seen: Dictionary = {}
	for index in 12:
		var id := StringName("stele_%d" % index)
		var epitaph := MemoryStele.epitaph_for(id)
		t.call(epitaph != "", true, "stele_epitaph_not_empty_%d" % index)
		seen[epitaph] = true
	t.call(seen.size() >= 2, true, "stele_epitaphs_vary_by_id")
	var fixed := MemoryStele.epitaph_for(&"ch1_vault_stele")
	t.call(MemoryStele.epitaph_for(&"ch1_vault_stele"), fixed, "stele_epitaph_is_stable")
	t.call(MemoryStele.EPITAPHS.has(fixed), true, "stele_epitaph_is_authored")
	var stele := MemoryStele.new()
	stele.stele_id = &"ch1_vault_stele"
	var reward := stele._roll_reward()
	t.call(reward.get("description", ""), fixed, "stele_reward_uses_epitaph")
	stele.free()


func _test_shop_lines(t: Callable) -> void:
	t.call(Ch1ShopData.LINES.size() >= 3, true, "ch1_shop_has_multiple_lines")
	var seen: Dictionary = {}
	for line in Ch1ShopData.LINES:
		t.call(line.strip_edges() != "", true, "ch1_shop_line_not_empty")
		seen[line] = true
	t.call(seen.size(), Ch1ShopData.LINES.size(), "ch1_shop_lines_unique")
	var fixed := Ch1ShopData.pick(4242, "ch1_rest_shop")
	t.call(Ch1ShopData.pick(4242, "ch1_rest_shop"), fixed, "ch1_shop_line_stable")
	t.call(Ch1ShopData.LINES.has(fixed), true, "ch1_shop_pick_is_authored")
	var rotated: Dictionary = {}
	for seed in 40:
		var line := Ch1ShopData.pick(seed, "ch1_rest_shop")
		t.call(Ch1ShopData.LINES.has(line), true, "ch1_shop_pick_authored_%d" % seed)
		rotated[line] = true
	t.call(rotated.size() >= 2, true, "ch1_shop_lines_rotate_across_runs")
	t.call(Ch1ShopData.pick(7, "another_shop") != "", true, "ch1_shop_line_per_stall")


func _test_shop_buy_lines(t: Callable) -> void:
	t.call(Ch1ShopData.BUY_LINES.size() >= 5, true, "ch1_shop_has_multiple_buy_lines")
	var seen: Dictionary = {}
	for line in Ch1ShopData.BUY_LINES:
		t.call(line.strip_edges() != "", true, "ch1_shop_buy_line_not_empty")
		seen[line] = true
	t.call(seen.size(), Ch1ShopData.BUY_LINES.size(), "ch1_shop_buy_lines_unique")
	var fixed := Ch1ShopData.pick_buy(4242, "ch1_rest_shop", 1)
	t.call(Ch1ShopData.pick_buy(4242, "ch1_rest_shop", 1), fixed, "ch1_shop_buy_line_stable")
	t.call(Ch1ShopData.BUY_LINES.has(fixed), true, "ch1_shop_buy_pick_is_authored")
	var rotated: Dictionary = {}
	for seed in 40:
		var line := Ch1ShopData.pick_buy(seed, "ch1_rest_shop", 0)
		t.call(Ch1ShopData.BUY_LINES.has(line), true, "ch1_shop_buy_pick_authored_%d" % seed)
		rotated[line] = true
	t.call(rotated.size() >= 2, true, "ch1_shop_buy_lines_rotate_across_runs")
	var by_row: Dictionary = {}
	for row in 8:
		by_row[Ch1ShopData.pick_buy(4242, "ch1_rest_shop", row)] = true
	t.call(by_row.size() >= 2, true, "ch1_shop_buy_lines_vary_by_row")
	t.call(Ch1ShopData.pick_buy(7, "another_shop", 0) != "", true, "ch1_shop_buy_line_per_stall")


func _test_rest_offers(t: Callable) -> void:
	var variants := RestOfferData.variants()
	t.call(variants.size() >= 8, true, "rest_offer_has_multiple_variants")
	var titles: Dictionary = {}
	for variant in variants:
		var title := String(variant.get("title", ""))
		var description := String(variant.get("description", ""))
		t.call(title != "", true, "rest_offer_title_not_empty")
		t.call(description.contains("35") and description.contains("45")
			and description.contains("12"), true, "rest_offer_keeps_effect_numbers")
		t.call(description.contains("生命") and description.contains("墨量")
			and description.contains("污染"), true, "rest_offer_names_effect_stats")
		t.call(not description.contains("%s") and not description.contains("%d")
			and not description.contains("{"), true, "rest_offer_has_no_placeholders")
		titles[title] = true
	t.call(titles.size(), variants.size(), "rest_offer_titles_unique")

	var fixed := RestOfferData.pick(4242, 1)
	t.call(RestOfferData.pick(4242, 1), fixed, "rest_offer_pick_stable")
	t.call(titles.has(String(fixed.get("title", ""))), true, "rest_offer_pick_is_authored")
	var rotated: Dictionary = {}
	for seed in 40:
		var offer := RestOfferData.pick(seed, 1)
		t.call(titles.has(String(offer.get("title", ""))), true,
			"rest_offer_pick_authored_%d" % seed)
		rotated[String(offer.get("title", ""))] = true
	t.call(rotated.size() >= 2, true, "rest_offers_rotate_across_runs")

	var run := RunState.new()
	run.reset_for_new_run(4242)
	var profile := Profile.new()
	var rng_state := run.rng.state
	var picked := RestOfferData.pick(run.run_seed, 1)
	t.call(run.rng.state, rng_state, "rest_offer_pick_does_not_consume_run_rng")
	var rest: Dictionary = {}
	for option in RunLoot.choices(run, 1, profile, 0):
		if option.get("kind", &"") == &"rest":
			rest = option
	t.call(rest.get("title", ""), picked["title"], "rest_reward_uses_rotating_title")
	t.call(rest.get("description", ""), picked["description"], "rest_reward_uses_rotating_description")
	profile.free()


func _test_rest_room_lines(t: Callable) -> void:
	var lines := RestRoomData.variants()
	t.call(lines.size() >= 8, true, "rest_room_has_multiple_lines")
	var authored: Dictionary = {}
	for line in lines:
		t.call(line != "", true, "rest_room_line_not_empty")
		t.call(not line.contains("%s") and not line.contains("%d")
			and not line.contains("{"), true, "rest_room_line_has_no_placeholders")
		authored[line] = true
	t.call(authored.size(), lines.size(), "rest_room_lines_unique")

	var fixed := RestRoomData.pick(4242, "ch1_rest")
	t.call(RestRoomData.pick(4242, "ch1_rest"), fixed, "rest_room_pick_stable")
	t.call(authored.has(fixed), true, "rest_room_pick_is_authored")
	var rotated: Dictionary = {}
	for seed in 40:
		var line := RestRoomData.pick(seed, "ch1_rest")
		t.call(authored.has(line), true, "rest_room_pick_authored_%d" % seed)
		rotated[line] = true
	t.call(rotated.size() >= 2, true, "rest_room_lines_rotate_across_runs")
	var by_room: Dictionary = {}
	for index in 12:
		by_room[RestRoomData.pick(4242, "ch1_rest_%d" % index)] = true
	t.call(by_room.size() >= 2, true, "rest_room_lines_vary_by_room")

	var run := RunState.new()
	run.reset_for_new_run(4242)
	var rng_state := run.rng.state
	RestRoomData.pick(run.run_seed, "ch1_rest")
	t.call(run.rng.state, rng_state, "rest_room_pick_does_not_consume_run_rng")


func _test_vault_room_lines(t: Callable) -> void:
	var lines := VaultRoomData.variants()
	t.call(lines.size() >= 8, true, "vault_room_has_multiple_lines")
	var authored: Dictionary = {}
	for line in lines:
		t.call(line != "", true, "vault_room_line_not_empty")
		t.call(line.begins_with("发现隐藏书库"), true, "vault_room_line_announces_discovery")
		t.call(line.contains("搜查宝箱与残碑"), true, "vault_room_line_keeps_search_hint")
		t.call(not line.contains("%s") and not line.contains("%d")
			and not line.contains("{"), true, "vault_room_line_has_no_placeholders")
		authored[line] = true
	t.call(authored.size(), lines.size(), "vault_room_lines_unique")

	var fixed := VaultRoomData.pick(4242, "ch1_vault")
	t.call(VaultRoomData.pick(4242, "ch1_vault"), fixed, "vault_room_pick_stable")
	t.call(authored.has(fixed), true, "vault_room_pick_is_authored")
	var rotated: Dictionary = {}
	for seed in 40:
		var line := VaultRoomData.pick(seed, "ch1_vault")
		t.call(authored.has(line), true, "vault_room_pick_authored_%d" % seed)
		rotated[line] = true
	t.call(rotated.size() >= 2, true, "vault_room_lines_rotate_across_runs")
	var by_room: Dictionary = {}
	for index in 12:
		by_room[VaultRoomData.pick(4242, "ch1_vault_%d" % index)] = true
	t.call(by_room.size() >= 2, true, "vault_room_lines_vary_by_room")

	var run := RunState.new()
	run.reset_for_new_run(4242)
	var rng_state := run.rng.state
	VaultRoomData.pick(run.run_seed, "ch1_vault")
	t.call(run.rng.state, rng_state, "vault_room_pick_does_not_consume_run_rng")
