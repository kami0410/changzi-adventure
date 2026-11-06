extends RefCounted

## Chapter 3 content layer: the event copy rotates deterministically per run +
## event node id, the plan authors the same revive/rewrite base pool plus the
## existing conditional additions, and the boss entrance/phase copy has its own
## chapter table instead of falling back to Chapters 1–2. Step 2 wires the six
## combat encounters to the existing chapter 3 waves (ROOM_WAVES[2]) by node id;
## the event node and boss region own no wave, and the plan no longer marks its
## wave content pending. Step 3 reuses the chapter-agnostic big-map event
## trigger: the event region opens the Chapter 3 page on entry and the settled
## node stays quiet across reloads. Nothing here makes Chapter 3 reachable:
## game.gd keeps plan slot 2 empty and the old linear world.

const EVENT_KEYS: Array[String] = [
	"eyebrow", "title", "body", "read_label", "take_label",
	"read_word_message", "read_pages_message", "take_message",
]
const CH3_PLAN_PATH := "res://resources/chapters/chapter_3_demo.tres"
const CH2_PLAN_PATH := "res://resources/chapters/chapter_2_demo.tres"
const CH1_PLAN_PATH := "res://resources/chapters/chapter_1_demo.tres"
const GAME_SCRIPT_PATH := "res://scripts/game.gd"
const OLD_CH3_WORLD_PATH := "res://scenes/mds/chapter_3.mdsworld.json"
const OLD_CH3_SCENE_PATH := "res://scenes/mds/chapter_3_world.tscn"
const CH3_BIGMAP_WORLD_PATH := "res://scenes/mds/chapter_3_bigmap.mdsworld.json"
const CH2_BIGMAP_WORLD_PATH := "res://scenes/mds/chapter_2_bigmap.mdsworld.json"
## Every enemy id used by ROOM_WAVES[2] (the existing chapter 3 waves).
const CH3_ENEMIES: Array[StringName] = [
	&"mirror_sniper", &"hanging_scribe", &"rust_whisperer", &"lung_moth",
	&"echo_enemy", &"collapse_husk", &"typo_beast", &"page_swarm",
]
const EXISTING_EFFECTS: Array[StringName] = [&"revive", &"rewrite", &"devour", &"archive"]
const COMBAT_ENCOUNTERS: Array[String] = [
	"ch3_branch_a/Arena", "ch3_branch_a/Arena2", "ch3_branch_b/Arena",
	"ch3_well/Arena", "ch3_well/Arena2", "ch3_elite/Arena",
]
const EVENT_ENCOUNTER := "ch3_event/event"


func run(t: Callable) -> void:
	_test_event_variants(t)
	_test_event_selection(t)
	_test_event_messages(t)
	_test_event_rng_untouched(t)
	_test_event_routing(t)
	_test_authority_pool(t)
	_test_boss_entrance(t)
	_test_boss_phase(t)
	_test_boss_data_unchanged(t)
	_test_encounters_match_waves(t)
	_test_runtime_wave_lookup(t)
	_test_event_trigger_inputs(t)
	_test_chapter_one_unchanged(t)
	_test_chapter_two_unchanged(t)
	_test_chapter_three_still_unwired(t)


func _test_event_variants(t: Callable) -> void:
	var variants := Ch3EventData.variants()
	t.call(variants.size() >= 7, true, "ch3_event_has_multiple_variants")
	var eyebrows: Dictionary = {}
	var other_eyebrows: Dictionary = {}
	for variant in Ch1EventData.variants():
		other_eyebrows[String(variant.get("eyebrow", ""))] = true
	for variant in Ch2EventData.variants():
		other_eyebrows[String(variant.get("eyebrow", ""))] = true
	for variant in variants:
		var label := String(variant.get("eyebrow", ""))
		t.call(label != "", true, "ch3_event_variant_has_eyebrow")
		t.call(not other_eyebrows.has(label), true, "ch3_event_eyebrow_not_chapters_1_2")
		eyebrows[label] = true
		for key in EVENT_KEYS:
			t.call(String(variant.get(key, "")) != "", true,
				"ch3_event_%s_%s" % [label, key])
		t.call(not String(variant.get("title", "")).contains("%"), true,
			"ch3_event_%s_title_has_no_placeholder" % label)
	t.call(eyebrows.size(), variants.size(), "ch3_event_variants_unique")
	t.call(Ch3EventData.CORRUPTION_COST > 0, true, "ch3_event_corruption_cost_positive")
	t.call(Ch3EventData.PAGES_REWARD > Ch3EventData.FALLBACK_PAGES, true,
		"ch3_event_taking_pays_more_than_fallback")
	# Same fixed pair the Chapter 1/2 pages use; no new numbers.
	t.call(Ch3EventData.CORRUPTION_COST, Ch2EventData.CORRUPTION_COST,
		"ch3_event_corruption_cost_matches_chapter_2")
	t.call(Ch3EventData.PAGES_REWARD, Ch2EventData.PAGES_REWARD,
		"ch3_event_pages_reward_matches_chapter_2")
	t.call(Ch3EventData.FALLBACK_PAGES, Ch2EventData.FALLBACK_PAGES,
		"ch3_event_fallback_pages_matches_chapter_2")


func _test_event_selection(t: Callable) -> void:
	var node_id := EVENT_ENCOUNTER
	var first := Ch3EventData.pick(4242, node_id)
	t.call(first, Ch3EventData.pick(4242, node_id), "ch3_event_pick_is_stable")
	var known: Dictionary = {}
	for variant in Ch3EventData.variants():
		known[String(variant.get("eyebrow", ""))] = true
	t.call(known.has(String(first.get("eyebrow", ""))), true,
		"ch3_event_pick_returns_authored_variant")
	var seen: Dictionary = {}
	for seed in 40:
		var event := Ch3EventData.pick(seed, node_id)
		t.call(known.has(String(event.get("eyebrow", ""))), true,
			"ch3_event_pick_known_%d" % seed)
		seen[String(event.get("eyebrow", ""))] = true
	t.call(seen.size() >= 2, true, "ch3_event_pick_rotates_across_runs")
	# The node id is part of the key, so a second event node could differ.
	var by_node: Dictionary = {}
	for index in 12:
		by_node[String(Ch3EventData.pick(4242, "ch3_event/node_%d" % index).get("eyebrow", ""))] = true
	t.call(by_node.size() >= 2, true, "ch3_event_pick_varies_by_node")


func _test_event_messages(t: Callable) -> void:
	for variant in Ch3EventData.variants():
		var decoded := String(variant["read_word_message"]) % ["词", Ch3EventData.CORRUPTION_COST]
		var fallback := String(variant["read_pages_message"]) % [
			Ch3EventData.FALLBACK_PAGES, Ch3EventData.CORRUPTION_COST]
		var take := String(variant["take_message"]) % Ch3EventData.PAGES_REWARD
		t.call(decoded.contains("词"), true, "ch3_event_word_message_formats")
		t.call(decoded.contains(str(Ch3EventData.CORRUPTION_COST)), true,
			"ch3_event_word_message_shows_corruption")
		t.call(fallback.contains(str(Ch3EventData.FALLBACK_PAGES)), true,
			"ch3_event_fallback_message_shows_pages")
		t.call(take.contains(str(Ch3EventData.PAGES_REWARD)), true,
			"ch3_event_take_message_shows_pages")
		t.call(not decoded.contains("%"), true, "ch3_event_word_message_fully_formatted")
		t.call(not fallback.contains("%"), true, "ch3_event_fallback_message_fully_formatted")
		t.call(not take.contains("%"), true, "ch3_event_take_message_fully_formatted")


func _test_event_rng_untouched(t: Callable) -> void:
	var run := RunState.new()
	run.rng.seed = 123456
	var state_before: int = run.rng.state
	Ch3EventData.pick(4242, EVENT_ENCOUNTER)
	Ch3EventData.pick(4243, "ch3_event/other")
	t.call(run.rng.state, state_before, "ch3_event_pick_keeps_run_rng")


## The chapter table is the only switch: the Chapter 1 key stays the room id,
## Chapters 2–4 key on the plan's event node id, and out-of-range chapters have
## no page. The game node is used outside the tree; `_event_data` only reads
## `run_state` and `_chapter`.
func _test_event_routing(t: Callable) -> void:
	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	t.call(game_script != null, true, "ch3_routing_game_script_loads")
	if game_script == null:
		return
	var game = game_script.new()
	var run := RunState.new()
	run.reset_for_new_run(4242)
	game.run_state = run
	game._chapter = 2
	var data: Dictionary = game._event_data("ch3_event")
	t.call(data.get("event"), Ch3EventData.pick(4242, EVENT_ENCOUNTER),
		"ch3_routing_chapter_3_uses_its_own_copy")
	t.call(data.get("corruption_cost"), Ch3EventData.CORRUPTION_COST,
		"ch3_routing_chapter_3_corruption_cost")
	t.call(data.get("pages_reward"), Ch3EventData.PAGES_REWARD,
		"ch3_routing_chapter_3_pages_reward")
	t.call(data.get("fallback_pages"), Ch3EventData.FALLBACK_PAGES,
		"ch3_routing_chapter_3_fallback_pages")
	game._chapter = 1
	t.call(game._event_data("ch2_event").get("event"),
		Ch2EventData.pick(4242, "ch2_event/event"),
		"ch3_routing_chapter_2_unchanged")
	game._chapter = 0
	t.call(game._event_data("ch1_05").get("event"),
		Ch1EventData.pick(4242, "ch1_05"), "ch3_routing_chapter_1_unchanged")
	game._chapter = 3
	t.call(game._event_data("ch4_event").get("event"),
		Ch4EventData.pick(4242, "ch4_event/event"),
		"ch3_routing_chapter_4_uses_its_own_copy")
	t.call(game._event_data("ch4_event").get("corruption_cost"),
		Ch4EventData.CORRUPTION_COST, "ch3_routing_chapter_4_corruption_cost")
	game._chapter = 4
	t.call(game._event_data("ch4_event"), {}, "ch3_routing_out_of_range_has_no_page")
	# game.gd creates its PhraseCaster (a Node) as a member initializer and only
	# parents it in _ready; freeing the standalone game node does not free a
	# Node held by a script variable, so release it explicitly.
	var caster: PhraseCaster = game.phrase_caster
	game.phrase_caster = null
	caster.free()
	game.free()


func _test_authority_pool(t: Callable) -> void:
	var plan := load(CH3_PLAN_PATH) as ChapterPlanData
	t.call(plan != null, true, "ch3_plan_loads")
	if plan == null:
		return
	var pool_ids: Array[StringName] = []
	for authority in plan.authority_pool:
		pool_ids.append(authority.id)
		t.call(EXISTING_EFFECTS.has(authority.effect_id if authority.effect_id != &"" else authority.id),
			true, "ch3_authority_%s_uses_existing_effect" % authority.id)
	t.call(pool_ids, _names(["revive", "rewrite"]),
		"ch3_authority_base_pool_is_revive_rewrite")

	var profile := Profile.new()
	var run := RunState.new()
	run.reset_for_new_run(4242)
	run.corruption = 0
	var base := AuthorityController.build_pool(plan.authority_pool, run, profile, 0)
	t.call(_ids(base), _names(["revive", "rewrite"]),
		"ch3_authority_no_conditions_keeps_base")

	run.corruption = 39
	t.call(_ids(AuthorityController.build_pool(plan.authority_pool, run, profile, 0)),
		_names(["revive", "rewrite"]), "ch3_devour_below_threshold")
	run.corruption = 40
	t.call(_ids(AuthorityController.build_pool(plan.authority_pool, run, profile, 0)),
		_names(["revive", "rewrite", "devour"]),
		"ch3_devour_unlocks_at_corruption_40")

	run.corruption = 0
	t.call(_ids(AuthorityController.build_pool(plan.authority_pool, run, profile, 1)),
		_names(["revive", "rewrite"]), "ch3_archive_below_threshold")
	t.call(_ids(AuthorityController.build_pool(plan.authority_pool, run, profile, 2)),
		_names(["revive", "rewrite", "archive"]),
		"ch3_archive_unlocks_at_two_records")

	run.corruption = 60
	var all_ids := _ids(AuthorityController.build_pool(plan.authority_pool, run, profile, 3))
	t.call(all_ids, _names(["revive", "rewrite", "archive", "devour"]),
		"ch3_both_conditions_follow_content_library_order")
	var unique: Dictionary = {}
	for id in all_ids:
		unique[id] = true
	t.call(unique.size(), all_ids.size(), "ch3_authority_pool_has_no_duplicates")
	profile.free()


func _test_boss_entrance(t: Callable) -> void:
	var lines := BossEntranceData.variants(2)
	t.call(lines.size() >= 8, true, "ch3_boss_entrance_has_multiple_lines")
	var earlier: Dictionary = {}
	for line in BossEntranceData.variants(0):
		earlier[line] = true
	for line in BossEntranceData.variants(1):
		earlier[line] = true
	var unique: Dictionary = {}
	for line in lines:
		t.call(line.strip_edges() != "", true, "ch3_boss_entrance_line_non_empty")
		t.call(line.length() <= 24, true, "ch3_boss_entrance_line_fits_banner")
		t.call(not line.contains("%"), true, "ch3_boss_entrance_line_has_no_placeholder")
		t.call(not earlier.has(line), true, "ch3_boss_entrance_line_not_chapters_1_2")
		unique[line] = true
	t.call(unique.size(), lines.size(), "ch3_boss_entrance_lines_unique")
	t.call(BossEntranceData.variants(3).size() >= 8, true,
		"ch3_boss_entrance_chapter_4_has_its_own_copy")
	t.call(BossEntranceData.variants(4).is_empty(), true,
		"boss_entrance_out_of_range_still_silent")

	var first := BossEntranceData.pick(4242, 2)
	t.call(first, BossEntranceData.pick(4242, 2), "ch3_boss_entrance_pick_stable")
	t.call(lines.has(first), true, "ch3_boss_entrance_pick_returns_authored_line")
	var seen: Dictionary = {}
	for seed in 40:
		var line := BossEntranceData.pick(seed, 2)
		t.call(lines.has(line), true, "ch3_boss_entrance_pick_known_%d" % seed)
		seen[line] = true
	t.call(seen.size() >= 3, true, "ch3_boss_entrance_pick_rotates")
	# Chapter 1 and Chapter 2 keep their exact legacy selection keys.
	var ch1_table := BossEntranceData.variants(0)
	var ch1_legacy := ch1_table[posmod(hash("%d:%d" % [4242, 0]), ch1_table.size())]
	t.call(BossEntranceData.pick(4242, 0), ch1_legacy, "ch1_boss_entrance_selection_unchanged")
	var ch2_table := BossEntranceData.variants(1)
	var ch2_legacy := ch2_table[posmod(hash("%d:%d" % [4242, 1]), ch2_table.size())]
	t.call(BossEntranceData.pick(4242, 1), ch2_legacy, "ch2_boss_entrance_selection_unchanged")


func _test_boss_phase(t: Callable) -> void:
	var earlier: Dictionary = {}
	for phase in [2, 3]:
		for line in BossPhaseData.variants(phase, 0):
			earlier[line] = true
		for line in BossPhaseData.variants(phase, 1):
			earlier[line] = true
	for phase in [2, 3]:
		var lines := BossPhaseData.variants(phase, 2)
		t.call(lines.size() >= 8, true, "ch3_boss_phase_%d_has_multiple_lines" % phase)
		var unique: Dictionary = {}
		for line in lines:
			t.call(line.strip_edges() != "", true, "ch3_boss_phase_%d_line_non_empty" % phase)
			t.call(line.length() <= 24, true, "ch3_boss_phase_%d_line_fits_banner" % phase)
			t.call(not line.contains("%"), true, "ch3_boss_phase_%d_line_has_no_placeholder" % phase)
			t.call(not earlier.has(line), true,
				"ch3_boss_phase_%d_line_not_chapters_1_2" % phase)
			unique[line] = true
		t.call(unique.size(), lines.size(), "ch3_boss_phase_%d_lines_unique" % phase)
		var first := BossPhaseData.pick(4242, phase, 2)
		t.call(first, BossPhaseData.pick(4242, phase, 2),
			"ch3_boss_phase_%d_pick_stable" % phase)
		t.call(lines.has(first), true,
			"ch3_boss_phase_%d_pick_returns_authored_line" % phase)
		var seen: Dictionary = {}
		for seed in 40:
			var line := BossPhaseData.pick(seed, phase, 2)
			t.call(lines.has(line), true, "ch3_boss_phase_%d_pick_known_%d" % [phase, seed])
			seen[line] = true
		t.call(seen.size() >= 3, true, "ch3_boss_phase_%d_pick_rotates" % phase)
		t.call(BossPhaseData.variants(phase, 2) != BossPhaseData.variants(phase, 0), true,
			"ch3_boss_phase_%d_uses_its_own_table" % phase)
		t.call(BossPhaseData.variants(phase, 2) != BossPhaseData.variants(phase, 1), true,
			"ch3_boss_phase_%d_differs_from_chapter_2" % phase)
	t.call(BossPhaseData.variants(1, 2).is_empty(), true, "ch3_boss_phase_1_has_no_flavor")
	t.call(BossPhaseData.variants(4, 2).is_empty(), true, "ch3_boss_phase_4_has_no_flavor")
	t.call(BossPhaseData.variants(2, 3).size() >= 8, true,
		"ch3_boss_phase_chapter_4_has_its_own_copy")
	t.call(BossPhaseData.variants(2, 4).is_empty(), true,
		"boss_phase_out_of_range_still_silent")
	t.call(BossPhaseData.pick(4242, 2, 4), "", "boss_phase_out_of_range_pick_is_empty")
	# Chapters 1–2 keep their exact legacy selection keys.
	var ch1_table := BossPhaseData.variants(2, 0)
	var ch1_legacy := ch1_table[posmod(hash("%d:%d" % [4242, 2]), ch1_table.size())]
	t.call(BossPhaseData.pick(4242, 2, 0), ch1_legacy, "ch1_boss_phase_selection_unchanged")
	var ch2_table := BossPhaseData.variants(2, 1)
	var ch2_legacy := ch2_table[posmod(hash("%d:%d:%d" % [4242, 1, 2]), ch2_table.size())]
	t.call(BossPhaseData.pick(4242, 2, 1), ch2_legacy, "ch2_boss_phase_selection_unchanged")


func _test_boss_data_unchanged(t: Callable) -> void:
	var chapter := CampaignData.chapter(2)
	t.call(String(chapter.get("id", "")), "lightless_sea", "ch3_campaign_id")
	t.call(String(chapter.get("boss_name", "")), "最后的读者", "ch3_boss_name")
	t.call(int(chapter.get("boss_hp", 0)), 380, "ch3_boss_hp_unchanged")
	t.call(int(chapter.get("boss_damage", 0)), 15, "ch3_boss_damage_unchanged")
	t.call(float(chapter.get("boss_speed", 0.0)), 78.0, "ch3_boss_speed_unchanged")
	t.call(String(chapter.get("boss_voice", "")) == "reader", true, "ch3_boss_voice")
	var texture := String(chapter.get("boss_texture", ""))
	t.call(ResourceLoader.exists(texture), true, "ch3_boss_texture_exists")
	t.call(texture, "res://assets/sprites/bosses/last_reader.png",
		"ch3_boss_texture_unchanged")
	# Boss 3 keeps its own script branch as the legacy fallback; the Boss 3 pass
	# routes the scene through the plan instead (see test_ch3_boss).
	t.call(String(chapter.get("boss_script", "")) == "reader", true,
		"ch3_boss_script_unchanged")


func _test_encounters_match_waves(t: Callable) -> void:
	var plan := load(CH3_PLAN_PATH) as ChapterPlanData
	t.call(plan != null, true, "ch3_plan_loads_for_encounters")
	if plan == null:
		return
	t.call(plan.validate_regions(), PackedStringArray(), "ch3_plan_regions_valid")
	t.call(plan.validate_graph(), PackedStringArray(), "ch3_plan_graph_valid")
	var encounters := plan.encounter_ids()
	t.call(encounters.size(), 7, "ch3_plan_has_seven_encounters")
	t.call(plan.clear_target(), 7, "ch3_plan_clear_target_seven")
	var unique: Dictionary = {}
	var event_encounters := 0
	for encounter_id in encounters:
		unique[encounter_id] = true
		var region := encounter_id.get_slice("/", 0)
		t.call(plan.room(region).size() > 0, true, "ch3_encounter_%s_anchored" % encounter_id)
		if encounter_id == EVENT_ENCOUNTER:
			event_encounters += 1
	t.call(unique.size(), encounters.size(), "ch3_encounter_ids_unique")
	t.call(event_encounters, 1, "ch3_event_encounter_anchored_once")
	# The region-level entry trigger and the one-shot settlement record share
	# one key: the RoomProgress event id must equal the plan's authored node.
	t.call(RoomProgress.event_encounter_id("ch3_event"), EVENT_ENCOUNTER,
		"ch3_event_trigger_key_matches_plan")
	var event_nodes: Array = plan.room("ch3_event").get("encounters", [])
	t.call(event_nodes.has(EVENT_ENCOUNTER), true, "ch3_event_plan_authors_trigger_key")
	# The six combat entries keep their plan order; the event node is skipped.
	var combat: Array[String] = []
	for encounter_id in encounters:
		if encounter_id != EVENT_ENCOUNTER:
			combat.append(encounter_id)
	t.call(combat, COMBAT_ENCOUNTERS, "ch3_six_combat_encounters_in_plan_order")

	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	t.call(game_script != null, true, "ch3_game_script_loads")
	if game_script == null:
		return
	var constants := game_script.get_script_constant_map()
	var waves: Array = constants.get("ROOM_WAVES", [])
	var enemy_scenes: Dictionary = constants.get("ENEMY_SCENES", {})
	t.call(waves.size(), 4, "room_waves_cover_four_chapters")
	if waves.size() < 3:
		return
	var chapter3_waves: Array = waves[2]
	t.call(chapter3_waves.size(), combat.size(),
		"ch3_waves_match_combat_encounters_in_order")
	for index in mini(combat.size(), chapter3_waves.size()):
		var wave: Array = chapter3_waves[index]
		t.call(wave.size() >= 1, true, "ch3_wave_%d_not_empty" % index)
		for enemy_id in wave:
			t.call(enemy_scenes.has(enemy_id), true,
				"ch3_wave_%d_enemy_%s_has_scene" % [index, enemy_id])
			var scene: PackedScene = enemy_scenes.get(enemy_id, null)
			if scene != null:
				t.call(ResourceLoader.exists(scene.resource_path), true,
					"ch3_wave_%d_enemy_%s_scene_exists" % [index, enemy_id])
	var appeared: Dictionary = {}
	for wave in chapter3_waves:
		for enemy_id in wave:
			appeared[enemy_id] = true
	for enemy_id in CH3_ENEMIES:
		t.call(appeared.has(enemy_id), true, "ch3_wave_uses_%s" % enemy_id)

	# Wave wiring: every combat encounter owns the plan-order ROOM_WAVES[2] wave,
	# keyed by its own node id. The event node and the boss region own none, and
	# the plan validates its wave table normally (content_pending cleared).
	for index in COMBAT_ENCOUNTERS.size():
		var encounter_id := COMBAT_ENCOUNTERS[index]
		var region := encounter_id.get_slice("/", 0)
		var planned_wave := plan.wave_for(region, encounter_id)
		t.call(planned_wave, chapter3_waves[index],
			"ch3_wave_by_node_%s" % encounter_id)
		t.call(not planned_wave.is_empty(), true,
			"ch3_wave_by_node_%s_not_empty" % encounter_id)
	t.call(plan.wave_for("ch3_event", EVENT_ENCOUNTER).is_empty(), true,
		"ch3_event_encounter_has_no_wave")
	t.call(plan.room("ch3_event").get("wave", null), null,
		"ch3_event_region_has_no_wave_table")
	t.call(plan.room("ch3_boss").has("wave"), false,
		"ch3_boss_region_has_no_wave_table")
	t.call(plan.wave_for("ch3_boss", "ch3_boss/Arena").is_empty(), true,
		"ch3_boss_arena_has_no_wave")
	var wave_keys: Dictionary = {}
	for entry in plan.rooms:
		var room_id := String(entry.get("id", ""))
		var table: Variant = entry.get("wave", null)
		if not table is Dictionary:
			continue
		for key in table.keys():
			var key_text := String(key)
			t.call(key_text.begins_with(room_id + "/"), true,
				"ch3_wave_key_anchored_%s" % key_text)
			t.call(wave_keys.has(key_text), false, "ch3_wave_key_unique_%s" % key_text)
			wave_keys[key_text] = true
	t.call(wave_keys.size(), COMBAT_ENCOUNTERS.size(), "ch3_wave_key_count")
	for encounter_id in COMBAT_ENCOUNTERS:
		t.call(wave_keys.has(encounter_id), true, "ch3_wave_key_present_%s" % encounter_id)
	t.call(plan.validate_waves(), PackedStringArray(), "ch3_plan_waves_validate_clean")
	t.call(plan.content_pending, false, "ch3_plan_waves_are_no_longer_pending")


## game.gd's big-map branch reads a wave through `_plan_wave` →
## ChapterPlanData.wave_for by encounter node id. Attaching the Chapter 3 plan
## to a standalone game node proves that branch reads the wired table correctly
## without routing the plan into the chapter slots.
func _test_runtime_wave_lookup(t: Callable) -> void:
	var plan := load(CH3_PLAN_PATH) as ChapterPlanData
	t.call(plan != null, true, "ch3_runtime_wave_plan_loads")
	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	t.call(game_script != null, true, "ch3_runtime_wave_game_script_loads")
	if plan == null or game_script == null:
		return
	var waves: Array = game_script.get_script_constant_map().get("ROOM_WAVES", [])
	t.call(waves.size() >= 3, true, "ch3_runtime_wave_room_waves_present")
	if waves.size() < 3:
		return
	var chapter3_waves: Array = waves[2]
	var game = game_script.new()
	game._chapter_plan = plan
	for index in mini(COMBAT_ENCOUNTERS.size(), chapter3_waves.size()):
		var encounter_id := COMBAT_ENCOUNTERS[index]
		var region := encounter_id.get_slice("/", 0)
		t.call(game._plan_wave(region, encounter_id), chapter3_waves[index],
			"ch3_runtime_wave_read_by_node_%s" % encounter_id)
	t.call(game._plan_wave("ch3_event", EVENT_ENCOUNTER).is_empty(), true,
		"ch3_runtime_wave_event_has_none")
	t.call(game._plan_wave("ch3_boss", "ch3_boss/Arena").is_empty(), true,
		"ch3_runtime_wave_boss_has_none")
	t.call(game._plan_wave("ch3_branch_a", "ch3_branch_a/Missing").is_empty(), true,
		"ch3_runtime_wave_unknown_node_has_none")
	# See _test_event_routing: the standalone game node owns a PhraseCaster Node
	# that only gets parented in _ready, so release it explicitly.
	var caster: PhraseCaster = game.phrase_caster
	game.phrase_caster = null
	caster.free()
	game.free()


## The region-level entry trigger added with the Chapter 2 step is
## chapter-agnostic: a big-map plan whose region type is `event` and whose
## chapter has authored event data. Attaching the Chapter 3 plan to a standalone
## game node proves every input of that predicate holds, that the trigger key is
## the plan's event node id, and that the event node contributes to the clear
## target while owning no wave. The chapter route is untouched: `_chapter` is set
## on the standalone node, never through `CHAPTER_PLAN_PATHS`.
func _test_event_trigger_inputs(t: Callable) -> void:
	var plan := load(CH3_PLAN_PATH) as ChapterPlanData
	t.call(plan != null, true, "ch3_trigger_plan_loads")
	if plan == null:
		return
	t.call(plan.big_map, true, "ch3_trigger_plan_is_big_map")
	var event_room := plan.room("ch3_event")
	t.call(String(event_room.get("type", "")), "event", "ch3_trigger_region_type_event")
	var event_nodes: Array = event_room.get("encounters", [])
	t.call(event_nodes.size(), 1, "ch3_trigger_region_authors_one_node")
	if event_nodes.size() == 1:
		t.call(String(event_nodes[0]), EVENT_ENCOUNTER,
			"ch3_trigger_region_authors_the_event_node")
	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	t.call(game_script != null, true, "ch3_trigger_game_script_loads")
	if game_script == null:
		return
	var game = game_script.new()
	var run := RunState.new()
	run.reset_for_new_run(4242)
	game.run_state = run
	game._chapter = 2
	game._chapter_plan = plan
	t.call(String(game._plan_room("ch3_event").get("type", "")), "event",
		"ch3_trigger_plan_room_visible_to_game")
	t.call(game._event_data("ch3_event").is_empty(), false,
		"ch3_trigger_event_data_present")
	t.call(game._plan_wave("ch3_event", EVENT_ENCOUNTER).is_empty(), true,
		"ch3_trigger_event_node_has_no_wave")
	# The plan's clear target counts the event node, and the HUD denominator adds
	# the boss room on top of it (7 + 1).
	t.call(game._chapter_clear_target(), 7, "ch3_trigger_clear_target_includes_event")
	t.call(game._chapter_progress_total(), 8, "ch3_trigger_progress_includes_boss")
	# Settlement reads and writes the same key the trigger reads, so a settled
	# node can never reopen or pay twice.
	t.call(RoomProgress.is_recorded({}, {}, EVENT_ENCOUNTER, "ch3_event"), false,
		"ch3_trigger_starts_unsettled")
	t.call(RoomProgress.is_recorded(
			{EVENT_ENCOUNTER: true}, {}, EVENT_ENCOUNTER, "ch3_event"), true,
		"ch3_trigger_settles_under_the_plan_key")
	# See _test_event_routing: the standalone game node owns a PhraseCaster Node
	# that only gets parented in _ready, so release it explicitly.
	var caster: PhraseCaster = game.phrase_caster
	game.phrase_caster = null
	caster.free()
	game.free()


func _test_chapter_one_unchanged(t: Callable) -> void:
	var ch1 := load(CH1_PLAN_PATH) as ChapterPlanData
	t.call(ch1 != null, true, "ch3_ch1_plan_still_loads")
	if ch1 != null:
		t.call(ch1.rooms.size(), 9, "ch3_ch1_plan_still_nine_rooms")
		t.call(ch1.clear_target(), 6, "ch3_ch1_clear_target_still_six")
		t.call(_ids(ch1.authority_pool), _names(["revive", "rewrite"]),
			"ch3_ch1_authority_pool_unchanged")
	t.call(Ch1EventData.variants().size(), 7, "ch3_ch1_event_variants_unchanged")
	t.call(String(Ch1EventData.variants()[0].get("eyebrow", "")), "事件 · 禁文",
		"ch3_ch1_first_event_copy_unchanged")
	t.call(Ch1EventData.CORRUPTION_COST, 8, "ch3_ch1_event_corruption_unchanged")
	t.call(Ch1EventData.PAGES_REWARD, 12, "ch3_ch1_event_pages_unchanged")
	t.call(Ch1EventData.FALLBACK_PAGES, 6, "ch3_ch1_event_fallback_unchanged")
	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	if game_script != null:
		var constants := game_script.get_script_constant_map()
		var waves: Array = constants.get("ROOM_WAVES", [])
		if waves.size() >= 1:
			t.call((waves[0] as Array).size(), 6, "ch3_ch1_six_waves_unchanged")
		var plan_paths: Array = constants.get("CHAPTER_PLAN_PATHS", [])
		if plan_paths.size() == 4:
			t.call(plan_paths[0], CH1_PLAN_PATH, "ch3_ch1_plan_slot_unchanged")
	# CampaignData still authors the six Chapter 1 combat waves.
	var chapter := CampaignData.chapter(0)
	t.call((chapter.get("rooms", []) as Array).size(), 6, "ch3_ch1_campaign_waves_unchanged")


func _test_chapter_two_unchanged(t: Callable) -> void:
	var ch2 := load(CH2_PLAN_PATH) as ChapterPlanData
	t.call(ch2 != null, true, "ch3_ch2_plan_still_loads")
	if ch2 != null:
		t.call(ch2.validate(), PackedStringArray(), "ch3_ch2_plan_still_validates")
		t.call(ch2.clear_target(), 7, "ch3_ch2_clear_target_still_seven")
		t.call(ch2.encounter_ids().size(), 7, "ch3_ch2_still_seven_encounters")
		t.call(_ids(ch2.authority_pool), _names(["revive", "rewrite"]),
			"ch3_ch2_authority_pool_unchanged")
	t.call(Ch2EventData.variants().size(), 7, "ch3_ch2_event_variants_unchanged")
	t.call(String(Ch2EventData.variants()[0].get("eyebrow", "")), "事件 · 呼气",
		"ch3_ch2_first_event_copy_unchanged")
	t.call(Ch2EventData.CORRUPTION_COST, 8, "ch3_ch2_event_corruption_unchanged")
	t.call(Ch2EventData.PAGES_REWARD, 12, "ch3_ch2_event_pages_unchanged")
	t.call(Ch2EventData.FALLBACK_PAGES, 6, "ch3_ch2_event_fallback_unchanged")
	t.call(BossEntranceData.variants(1).size(), 8, "ch3_ch2_boss_entrance_unchanged")
	t.call(String(BossEntranceData.variants(1)[0]), "肺钟守卫从雾里抬起钟摆",
		"ch3_ch2_first_boss_entrance_line_unchanged")
	t.call(BossPhaseData.variants(2, 1).size(), 8, "ch3_ch2_phase_2_lines_unchanged")
	t.call(String(BossPhaseData.variants(2, 1)[0]), "钟摆开始倒转，雾往肺里灌",
		"ch3_ch2_first_phase_2_line_unchanged")
	t.call(BossPhaseData.variants(3, 1).size(), 8, "ch3_ch2_phase_3_lines_unchanged")
	t.call(FileAccess.file_exists(CH2_BIGMAP_WORLD_PATH), true,
		"ch3_ch2_bigmap_world_still_present")
	var chapter := CampaignData.chapter(1)
	t.call(int(chapter.get("boss_hp", 0)), 360, "ch3_ch2_boss_hp_unchanged")


func _test_chapter_three_still_unwired(t: Callable) -> void:
	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	t.call(game_script != null, true, "ch3_unwired_game_script_loads")
	if game_script != null:
		var constants := game_script.get_script_constant_map()
		var plan_paths: Array = constants.get("CHAPTER_PLAN_PATHS", [])
		t.call(plan_paths.size(), 4, "ch3_game_has_four_plan_slots")
		if plan_paths.size() == 4:
			t.call(plan_paths[2], "", "ch3_game_plan_slot_stays_empty")
			t.call(plan_paths[3], "", "ch4_game_plan_slot_stays_empty")
			# The Chapter 4 plan is authored (pass 51) but deliberately unrouted.
			t.call(ResourceLoader.exists("res://resources/chapters/chapter_4_demo.tres"), true,
				"ch4_game_plan_authored_but_not_routed")
			t.call(plan_paths[1], CH2_PLAN_PATH, "ch3_ch2_plan_slot_unchanged")
		var world_files: Array = constants.get("MDS_WORLD_FILES", [])
		if world_files.size() == 4:
			t.call(world_files[2], OLD_CH3_WORLD_PATH,
				"ch3_game_still_uses_the_old_world")
	var plan := load(CH3_PLAN_PATH) as ChapterPlanData
	if plan != null:
		t.call(plan.content_pending, false,
			"ch3_plan_waves_no_longer_marked_pending")
		t.call(plan.boss_scene != null, true, "ch3_plan_boss_scene_routed")
		if plan.boss_scene != null:
			t.call(plan.boss_scene.resource_path,
				"res://scenes/bosses/last_reader.tscn", "ch3_plan_boss_scene_path")
		t.call(plan.clear_target(), 7, "ch3_plan_clear_target_still_seven")
	# The old linear Chapter 3 world stays exactly as it was: 9 rooms, 17
	# outgoing gates, start at ch3_01.
	var text := FileAccess.get_file_as_string(OLD_CH3_WORLD_PATH)
	var parsed: Variant = JSON.parse_string(text)
	t.call(parsed is Dictionary, true, "ch3_old_world_still_parses")
	if parsed is Dictionary:
		var world: Dictionary = parsed
		var rooms: Dictionary = world.get("rooms", {})
		t.call(rooms.size(), 9, "ch3_old_world_still_nine_rooms")
		t.call(String(world.get("start_room", "")), "ch3_01",
			"ch3_old_world_start_room_unchanged")
		var outgoing := 0
		for room_id in rooms:
			var gates: Dictionary = rooms[room_id].get("gates", {})
			for gate_name in gates:
				if (gates[gate_name] as Dictionary).has("to"):
					outgoing += 1
		t.call(outgoing, 17, "ch3_old_world_still_seventeen_gates")
	var scene_source := FileAccess.get_file_as_string(OLD_CH3_SCENE_PATH)
	t.call(scene_source.contains("chapter_3.mdsworld.json"), true,
		"ch3_old_world_scene_still_points_at_its_world")
	# The step-2 region world from the previous pass stays in place too.
	t.call(FileAccess.file_exists(CH3_BIGMAP_WORLD_PATH), true,
		"ch3_bigmap_world_still_present")


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
