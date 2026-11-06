extends RefCounted

## Chapter 2 content layer (data only): the event copy rotates deterministically
## per run + event node id, the plan authors the same revive/rewrite base pool
## plus the existing conditional additions, and the boss entrance/phase copy has
## its own chapter table instead of falling back to Chapter 1. The encounter
## entries are checked against the existing chapter 2 waves; this file does not
## place any enemy content.

const EVENT_KEYS: Array[String] = [
	"eyebrow", "title", "body", "read_label", "take_label",
	"read_word_message", "read_pages_message", "take_message",
]
const PLAN_PATH := "res://resources/chapters/chapter_2_demo.tres"
const CH1_PLAN_PATH := "res://resources/chapters/chapter_1_demo.tres"
const CH2_ENEMIES: Array[StringName] = [
	&"breath_hound", &"lung_moth", &"rust_whisperer", &"choir_summoner", &"collapse_husk",
]
const EXISTING_EFFECTS: Array[StringName] = [&"revive", &"rewrite", &"devour", &"archive"]


func run(t: Callable) -> void:
	_test_event_variants(t)
	_test_event_selection(t)
	_test_event_messages(t)
	_test_event_rng_untouched(t)
	_test_authority_pool(t)
	_test_boss_entrance(t)
	_test_boss_phase(t)
	_test_boss_data_unchanged(t)
	_test_encounters_match_waves(t)


func _test_event_variants(t: Callable) -> void:
	var variants := Ch2EventData.variants()
	t.call(variants.size() >= 7, true, "ch2_event_has_multiple_variants")
	var eyebrows: Dictionary = {}
	var ch1_eyebrows: Dictionary = {}
	for variant in Ch1EventData.variants():
		ch1_eyebrows[String(variant.get("eyebrow", ""))] = true
	for variant in variants:
		var label := String(variant.get("eyebrow", ""))
		t.call(label != "", true, "ch2_event_variant_has_eyebrow")
		t.call(not ch1_eyebrows.has(label), true, "ch2_event_eyebrow_not_chapter_1")
		eyebrows[label] = true
		for key in EVENT_KEYS:
			t.call(String(variant.get(key, "")) != "", true,
				"ch2_event_%s_%s" % [label, key])
		t.call(not String(variant.get("title", "")).contains("%"), true,
			"ch2_event_%s_title_has_no_placeholder" % label)
	t.call(eyebrows.size(), variants.size(), "ch2_event_variants_unique")
	t.call(Ch2EventData.CORRUPTION_COST > 0, true, "ch2_event_corruption_cost_positive")
	t.call(Ch2EventData.PAGES_REWARD > Ch2EventData.FALLBACK_PAGES, true,
		"ch2_event_taking_pays_more_than_fallback")


func _test_event_selection(t: Callable) -> void:
	var node_id := "ch2_event/event"
	var first := Ch2EventData.pick(4242, node_id)
	t.call(first, Ch2EventData.pick(4242, node_id), "ch2_event_pick_is_stable")
	var known: Dictionary = {}
	for variant in Ch2EventData.variants():
		known[String(variant.get("eyebrow", ""))] = true
	t.call(known.has(String(first.get("eyebrow", ""))), true,
		"ch2_event_pick_returns_authored_variant")
	var seen: Dictionary = {}
	for seed in 40:
		var event := Ch2EventData.pick(seed, node_id)
		t.call(known.has(String(event.get("eyebrow", ""))), true,
			"ch2_event_pick_known_%d" % seed)
		seen[String(event.get("eyebrow", ""))] = true
	t.call(seen.size() >= 2, true, "ch2_event_pick_rotates_across_runs")
	# The node id is part of the key, so two event nodes in one run can differ.
	var by_node: Dictionary = {}
	for index in 12:
		by_node[String(Ch2EventData.pick(4242, "ch2_event/node_%d" % index).get("eyebrow", ""))] = true
	t.call(by_node.size() >= 2, true, "ch2_event_pick_varies_by_node")


func _test_event_messages(t: Callable) -> void:
	for variant in Ch2EventData.variants():
		var decoded := String(variant["read_word_message"]) % ["词", Ch2EventData.CORRUPTION_COST]
		var fallback := String(variant["read_pages_message"]) % [
			Ch2EventData.FALLBACK_PAGES, Ch2EventData.CORRUPTION_COST]
		var take := String(variant["take_message"]) % Ch2EventData.PAGES_REWARD
		t.call(decoded.contains("词"), true, "ch2_event_word_message_formats")
		t.call(decoded.contains(str(Ch2EventData.CORRUPTION_COST)), true,
			"ch2_event_word_message_shows_corruption")
		t.call(fallback.contains(str(Ch2EventData.FALLBACK_PAGES)), true,
			"ch2_event_fallback_message_shows_pages")
		t.call(take.contains(str(Ch2EventData.PAGES_REWARD)), true,
			"ch2_event_take_message_shows_pages")
		t.call(not decoded.contains("%"), true, "ch2_event_word_message_fully_formatted")
		t.call(not fallback.contains("%"), true, "ch2_event_fallback_message_fully_formatted")
		t.call(not take.contains("%"), true, "ch2_event_take_message_fully_formatted")


func _test_event_rng_untouched(t: Callable) -> void:
	var run := RunState.new()
	run.rng.seed = 123456
	var state_before: int = run.rng.state
	Ch2EventData.pick(4242, "ch2_event/event")
	Ch2EventData.pick(4243, "ch2_event/other")
	t.call(run.rng.state, state_before, "ch2_event_pick_keeps_run_rng")


func _test_authority_pool(t: Callable) -> void:
	var plan := load(PLAN_PATH) as ChapterPlanData
	t.call(plan != null, true, "ch2_plan_loads")
	if plan == null:
		return
	var pool_ids: Array[StringName] = []
	for authority in plan.authority_pool:
		pool_ids.append(authority.id)
		t.call(EXISTING_EFFECTS.has(authority.effect_id if authority.effect_id != &"" else authority.id),
			true, "ch2_authority_%s_uses_existing_effect" % authority.id)
	t.call(pool_ids, _names(["revive", "rewrite"]),
		"ch2_authority_base_pool_is_revive_rewrite")

	var profile := Profile.new()
	var run := RunState.new()
	run.reset_for_new_run(4242)
	run.corruption = 0
	var base := AuthorityController.build_pool(plan.authority_pool, run, profile, 0)
	t.call(_ids(base), _names(["revive", "rewrite"]),
		"ch2_authority_no_conditions_keeps_base")

	run.corruption = 39
	t.call(_ids(AuthorityController.build_pool(plan.authority_pool, run, profile, 0)),
		_names(["revive", "rewrite"]), "ch2_devour_below_threshold")
	run.corruption = 40
	t.call(_ids(AuthorityController.build_pool(plan.authority_pool, run, profile, 0)),
		_names(["revive", "rewrite", "devour"]),
		"ch2_devour_unlocks_at_corruption_40")

	run.corruption = 0
	t.call(_ids(AuthorityController.build_pool(plan.authority_pool, run, profile, 1)),
		_names(["revive", "rewrite"]), "ch2_archive_below_threshold")
	t.call(_ids(AuthorityController.build_pool(plan.authority_pool, run, profile, 2)),
		_names(["revive", "rewrite", "archive"]),
		"ch2_archive_unlocks_at_two_records")

	run.corruption = 60
	var all_ids := _ids(AuthorityController.build_pool(plan.authority_pool, run, profile, 3))
	t.call(all_ids, _names(["revive", "rewrite", "archive", "devour"]),
		"ch2_both_conditions_follow_content_library_order")
	var unique: Dictionary = {}
	for id in all_ids:
		unique[id] = true
	t.call(unique.size(), all_ids.size(), "ch2_authority_pool_has_no_duplicates")
	profile.free()

	var ch1_plan := load(CH1_PLAN_PATH) as ChapterPlanData
	t.call(ch1_plan != null, true, "ch1_plan_still_loads")
	if ch1_plan != null:
		t.call(_ids(ch1_plan.authority_pool), _names(["revive", "rewrite"]),
			"ch1_authority_pool_unchanged")


func _test_boss_entrance(t: Callable) -> void:
	var lines := BossEntranceData.variants(1)
	t.call(lines.size() >= 8, true, "ch2_boss_entrance_has_multiple_lines")
	var ch1_lines := BossEntranceData.variants(0)
	var ch1_set: Dictionary = {}
	for line in ch1_lines:
		ch1_set[line] = true
	var unique: Dictionary = {}
	for line in lines:
		t.call(line.strip_edges() != "", true, "ch2_boss_entrance_line_non_empty")
		t.call(line.length() <= 24, true, "ch2_boss_entrance_line_fits_banner")
		t.call(not line.contains("%"), true, "ch2_boss_entrance_line_has_no_placeholder")
		t.call(not ch1_set.has(line), true, "ch2_boss_entrance_line_not_chapter_1")
		unique[line] = true
	t.call(unique.size(), lines.size(), "ch2_boss_entrance_lines_unique")
	t.call(BossEntranceData.variants(2).size() >= 8, true,
		"ch2_boss_entrance_chapter_3_has_its_own_copy")
	t.call(BossEntranceData.variants(3).size() >= 8, true,
		"ch2_boss_entrance_chapter_4_has_its_own_copy")
	t.call(BossEntranceData.variants(4).is_empty(), true,
		"boss_entrance_out_of_range_still_silent")

	var first := BossEntranceData.pick(4242, 1)
	t.call(first, BossEntranceData.pick(4242, 1), "ch2_boss_entrance_pick_stable")
	t.call(lines.has(first), true, "ch2_boss_entrance_pick_returns_authored_line")
	var seen: Dictionary = {}
	for seed in 40:
		var line := BossEntranceData.pick(seed, 1)
		t.call(lines.has(line), true, "ch2_boss_entrance_pick_known_%d" % seed)
		seen[line] = true
	t.call(seen.size() >= 3, true, "ch2_boss_entrance_pick_rotates")
	# Chapter 1 keeps its exact legacy selection key.
	var legacy := ch1_lines[posmod(hash("%d:%d" % [4242, 0]), ch1_lines.size())]
	t.call(BossEntranceData.pick(4242, 0), legacy, "ch1_boss_entrance_selection_unchanged")


func _test_boss_phase(t: Callable) -> void:
	var ch1_lines: Dictionary = {}
	for phase in [2, 3]:
		for line in BossPhaseData.variants(phase):
			ch1_lines[line] = true
	for phase in [2, 3]:
		var lines := BossPhaseData.variants(phase, 1)
		t.call(lines.size() >= 8, true, "ch2_boss_phase_%d_has_multiple_lines" % phase)
		var unique: Dictionary = {}
		for line in lines:
			t.call(line.strip_edges() != "", true, "ch2_boss_phase_%d_line_non_empty" % phase)
			t.call(line.length() <= 24, true, "ch2_boss_phase_%d_line_fits_banner" % phase)
			t.call(not line.contains("%"), true, "ch2_boss_phase_%d_line_has_no_placeholder" % phase)
			t.call(not ch1_lines.has(line), true, "ch2_boss_phase_%d_line_not_chapter_1" % phase)
			unique[line] = true
		t.call(unique.size(), lines.size(), "ch2_boss_phase_%d_lines_unique" % phase)
		var first := BossPhaseData.pick(4242, phase, 1)
		t.call(first, BossPhaseData.pick(4242, phase, 1),
			"ch2_boss_phase_%d_pick_stable" % phase)
		t.call(lines.has(first), true,
			"ch2_boss_phase_%d_pick_returns_authored_line" % phase)
		var seen: Dictionary = {}
		for seed in 40:
			var line := BossPhaseData.pick(seed, phase, 1)
			t.call(lines.has(line), true, "ch2_boss_phase_%d_pick_known_%d" % [phase, seed])
			seen[line] = true
		t.call(seen.size() >= 3, true, "ch2_boss_phase_%d_pick_rotates" % phase)
		t.call(BossPhaseData.variants(phase, 1) != BossPhaseData.variants(phase, 0), true,
			"ch2_boss_phase_%d_uses_its_own_table" % phase)
	t.call(BossPhaseData.variants(1, 1).is_empty(), true, "ch2_boss_phase_1_has_no_flavor")
	t.call(BossPhaseData.variants(4, 1).is_empty(), true, "ch2_boss_phase_4_has_no_flavor")
	t.call(BossPhaseData.variants(2, 2).size() >= 8, true,
		"ch2_boss_phase_chapter_3_has_its_own_copy")
	t.call(BossPhaseData.variants(2, 3).size() >= 8, true,
		"ch2_boss_phase_chapter_4_has_its_own_copy")
	t.call(BossPhaseData.variants(2, 4).is_empty(), true,
		"boss_phase_out_of_range_still_silent")
	# Chapter 1 keeps its exact legacy selection key.
	var ch1_table := BossPhaseData.variants(2, 0)
	var legacy := ch1_table[posmod(hash("%d:%d" % [4242, 2]), ch1_table.size())]
	t.call(BossPhaseData.pick(4242, 2, 0), legacy, "ch1_boss_phase_selection_unchanged")


func _test_boss_data_unchanged(t: Callable) -> void:
	var chapter := CampaignData.chapter(1)
	t.call(String(chapter.get("id", "")), "breathing_ruins", "ch2_campaign_id")
	t.call(String(chapter.get("boss_name", "")), "肺钟守卫", "ch2_boss_name")
	t.call(int(chapter.get("boss_hp", 0)), 360, "ch2_boss_hp_unchanged")
	t.call(int(chapter.get("boss_damage", 0)), 14, "ch2_boss_damage_unchanged")
	t.call(float(chapter.get("boss_speed", 0.0)), 75.0, "ch2_boss_speed_unchanged")
	t.call(String(chapter.get("boss_voice", "")) == "lung", true, "ch2_boss_voice")
	var texture := String(chapter.get("boss_texture", ""))
	t.call(ResourceLoader.exists(texture), true, "ch2_boss_texture_exists")
	t.call(String(chapter.get("boss_script", "")) == "ink", true, "ch2_boss_script_unchanged")


func _test_encounters_match_waves(t: Callable) -> void:
	var plan := load(PLAN_PATH) as ChapterPlanData
	t.call(plan != null, true, "ch2_plan_loads_for_encounters")
	if plan == null:
		return
	t.call(plan.validate_regions(), PackedStringArray(), "ch2_plan_regions_valid")
	t.call(plan.validate_graph(), PackedStringArray(), "ch2_plan_graph_valid")
	var encounters := plan.encounter_ids()
	t.call(encounters.size(), 7, "ch2_plan_has_seven_encounters")
	t.call(plan.clear_target(), 7, "ch2_plan_clear_target_seven")
	var unique: Dictionary = {}
	var event_encounters := 0
	for encounter_id in encounters:
		unique[encounter_id] = true
		var region := encounter_id.get_slice("/", 0)
		t.call(plan.room(region).size() > 0, true, "ch2_encounter_%s_anchored" % encounter_id)
		if encounter_id == "ch2_event/event":
			event_encounters += 1
	t.call(unique.size(), encounters.size(), "ch2_encounter_ids_unique")
	t.call(event_encounters, 1, "ch2_event_encounter_anchored_once")
	# The region-level entry trigger and the one-shot settlement record share
	# one key: the RoomProgress event id must equal the plan's authored node.
	t.call(RoomProgress.event_encounter_id("ch2_event"), "ch2_event/event",
		"ch2_event_trigger_key_matches_plan")
	var event_nodes: Array = plan.room("ch2_event").get("encounters", [])
	t.call(event_nodes.has("ch2_event/event"), true,
		"ch2_event_plan_authors_trigger_key")

	var game_script := load("res://scripts/game.gd") as GDScript
	t.call(game_script != null, true, "ch2_game_script_loads")
	if game_script == null:
		return
	var constants := game_script.get_script_constant_map()
	var waves: Array = constants.get("ROOM_WAVES", [])
	var enemy_scenes: Dictionary = constants.get("ENEMY_SCENES", {})
	t.call(waves.size(), 4, "room_waves_cover_four_chapters")
	if waves.size() < 2:
		return
	var chapter2_waves: Array = waves[1]
	# The event encounter is the only non-combat entry, so the existing six
	# chapter 2 waves line up with the six combat encounters in plan order.
	t.call(chapter2_waves.size(), encounters.size() - 1, "ch2_waves_match_combat_encounters")
	for index in chapter2_waves.size():
		var wave: Array = chapter2_waves[index]
		t.call(wave.size() >= 1, true, "ch2_wave_%d_not_empty" % index)
		for enemy_id in wave:
			t.call(enemy_scenes.has(enemy_id), true,
				"ch2_wave_%d_enemy_%s_has_scene" % [index, enemy_id])
			t.call(ResourceLoader.exists("res://resources/enemies/%s.tres" % enemy_id), true,
				"ch2_wave_%d_enemy_%s_has_data" % [index, enemy_id])
	var appeared: Dictionary = {}
	for wave in chapter2_waves:
		for enemy_id in wave:
			appeared[enemy_id] = true
	for enemy_id in CH2_ENEMIES:
		t.call(appeared.has(enemy_id), true, "ch2_wave_uses_%s" % enemy_id)

	# The plan owns the wave wiring: one wave key per combat encounter node id,
	# in plan order, each equal to the existing chapter 2 wave it replaces. The
	# event node and the boss region own no ordinary wave.
	t.call(plan.validate_waves(), PackedStringArray(), "ch2_plan_waves_valid")
	var combat_index := 0
	var wave_keys: Dictionary = {}
	for entry in plan.rooms:
		var region_wave: Variant = entry.get("wave", null)
		if region_wave is Dictionary:
			for key in region_wave.keys():
				wave_keys[String(key)] = true
	t.call(wave_keys.size(), chapter2_waves.size(), "ch2_plan_wave_key_count")
	for encounter_id in encounters:
		var region := encounter_id.get_slice("/", 0)
		var plan_wave := plan.wave_for(region, encounter_id)
		if encounter_id == "ch2_event/event":
			t.call(plan_wave.is_empty(), true, "ch2_event_encounter_has_no_wave")
			continue
		t.call(wave_keys.has(encounter_id), true,
			"ch2_combat_encounter_has_wave_%s" % encounter_id)
		t.call(plan_wave, chapter2_waves[combat_index],
			"ch2_combat_encounter_wave_%s" % encounter_id)
		combat_index += 1
	t.call(combat_index, chapter2_waves.size(), "ch2_every_wave_key_is_a_combat_encounter")
	t.call(plan.wave_for("ch2_boss", "ch2_boss/Arena").is_empty(), true,
		"ch2_boss_region_has_no_ordinary_wave")
	t.call(plan.room("ch2_boss").has("wave"), false, "ch2_boss_region_authors_no_wave")
	t.call(plan.wave_for("ch2_entry", "ch2_entry/Arena").is_empty(), true,
		"ch2_entry_region_has_no_wave")


func _ids(pool: Array[AuthorityData]) -> Array[StringName]:
	var out: Array[StringName] = []
	for authority in pool:
		out.append(authority.id)
	return out


func _names(values: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for value in values:
		out.append(StringName(value))
	return out
