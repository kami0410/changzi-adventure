extends RefCounted

## Chapter 2 wave wiring (data layer): `wave` is keyed by encounter node id,
## six combat encounters own exactly one wave each (matching ROOM_WAVES[1] in
## plan order), the event node and the boss region own none, and the plan
## validation catches missing/empty/misplaced wave tables. Enemy spawning from
## those keys is covered by tests/integration_playability.gd.

const PLAN_PATH := "res://resources/chapters/chapter_2_demo.tres"
const CH1_PLAN_PATH := "res://resources/chapters/chapter_1_demo.tres"
const COMBAT_ENCOUNTERS: Array[String] = [
	"ch2_branch_a/Arena", "ch2_branch_a/Arena2", "ch2_branch_b/Arena",
	"ch2_well/Arena", "ch2_well/Arena2", "ch2_elite/Arena",
]


func run(t: Callable) -> void:
	_test_plan_waves(t)
	_test_wave_for(t)
	_test_wave_validation(t)
	_test_chapter_one_unchanged(t)


func _test_plan_waves(t: Callable) -> void:
	var plan := load(PLAN_PATH) as ChapterPlanData
	t.call(plan != null, true, "ch2_waves_plan_loads")
	if plan == null:
		return
	t.call(plan.big_map, true, "ch2_waves_plan_is_big_map")
	t.call(plan.validate_waves(), PackedStringArray(), "ch2_waves_plan_valid")
	t.call(plan.clear_target(), 7, "ch2_waves_clear_target_stays_seven")

	var encounters := plan.encounter_ids()
	var combat: Array[String] = []
	for encounter_id in encounters:
		if encounter_id != "ch2_event/event":
			combat.append(encounter_id)
	t.call(combat, COMBAT_ENCOUNTERS, "ch2_waves_six_combat_encounters")

	var game_script := load("res://scripts/game.gd") as GDScript
	t.call(game_script != null, true, "ch2_waves_game_script_loads")
	if game_script == null:
		return
	var constants := game_script.get_script_constant_map()
	var waves: Array = constants.get("ROOM_WAVES", [])
	t.call(waves.size() >= 2, true, "ch2_waves_room_waves_present")
	if waves.size() < 2:
		return
	var chapter_waves: Array = waves[1]
	t.call(combat.size(), chapter_waves.size(), "ch2_waves_combat_matches_wave_count")
	for index in mini(combat.size(), chapter_waves.size()):
		var encounter_id := combat[index]
		var region := encounter_id.get_slice("/", 0)
		var wave := plan.wave_for(region, encounter_id)
		t.call(wave, chapter_waves[index], "ch2_wave_by_node_%s" % encounter_id)
		t.call(not wave.is_empty(), true, "ch2_wave_by_node_%s_not_empty" % encounter_id)

	# The event node owns no wave and the boss region authors none at all.
	t.call(plan.wave_for("ch2_event", "ch2_event/event").is_empty(), true,
		"ch2_waves_event_node_has_none")
	var event_wave: Variant = plan.room("ch2_event").get("wave", null)
	t.call(event_wave, null, "ch2_waves_event_region_has_no_table")
	t.call(plan.room("ch2_boss").has("wave"), false, "ch2_waves_boss_region_has_no_table")
	t.call(plan.wave_for("ch2_boss", "ch2_boss/Arena").is_empty(), true,
		"ch2_waves_boss_arena_has_none")

	# Keys are unique across the plan and anchored to their own region.
	var keys: Dictionary = {}
	for entry in plan.rooms:
		var room_id := String(entry.get("id", ""))
		var table: Variant = entry.get("wave", null)
		if not table is Dictionary:
			continue
		for key in table.keys():
			var key_text := String(key)
			t.call(key_text.begins_with(room_id + "/"), true,
				"ch2_wave_key_anchored_%s" % key_text)
			t.call(keys.has(key_text), false, "ch2_wave_key_unique_%s" % key_text)
			keys[key_text] = true
	t.call(keys.size(), COMBAT_ENCOUNTERS.size(), "ch2_waves_unique_key_count")
	for encounter_id in COMBAT_ENCOUNTERS:
		t.call(keys.has(encounter_id), true, "ch2_waves_key_present_%s" % encounter_id)


func _test_wave_for(t: Callable) -> void:
	var big := ChapterPlanData.new()
	big.big_map = true
	big.rooms.append({
		"id": "r", "type": "branch",
		"encounters": ["r/Arena", "r/Arena2"],
		"wave": {"r/Arena": [&"ink_hound"], "r/Arena2": [&"scribe_bug", &"page_swarm"]},
	})
	t.call(big.wave_for("r", "r/Arena"), [&"ink_hound"], "ch2_wave_for_first_node")
	t.call(big.wave_for("r", "r/Arena2"), [&"scribe_bug", &"page_swarm"],
		"ch2_wave_for_second_node")
	t.call(big.wave_for("r", "r/Arena3").is_empty(), true, "ch2_wave_for_unknown_node")
	t.call(big.wave_for("missing", "missing/Arena").is_empty(), true, "ch2_wave_for_unknown_region")

	# Linear plans keep the room-level array and ignore the encounter id.
	var linear := ChapterPlanData.new()
	linear.rooms.append({"id": "x", "type": "combat", "wave": [&"ink_hound", &"scribe_bug"]})
	t.call(linear.wave_for("x", ""), [&"ink_hound", &"scribe_bug"], "ch1_wave_for_room_level")
	t.call(linear.wave_for("x", "x/Arena"), [&"ink_hound", &"scribe_bug"],
		"ch1_wave_for_ignores_encounter_id")


func _test_wave_validation(t: Callable) -> void:
	var valid := _wave_plan("branch", ["r/Arena"], {"r/Arena": [&"ink_hound"]})
	t.call(valid.validate_waves(), PackedStringArray(), "ch2_wave_validation_accepts_valid")

	var missing := _wave_plan("branch", ["r/Arena"], {})
	t.call(_joined(missing.validate_waves()).contains("encounter r/Arena needs a wave"), true,
		"ch2_wave_validation_flags_missing_wave")

	var unwired := _wave_plan("branch", ["r/Arena"], {})
	unwired.rooms[0].erase("wave")
	t.call(_joined(unwired.validate_waves()).contains("encounter r/Arena needs a wave"), true,
		"ch2_wave_validation_flags_missing_table")

	var unknown := _wave_plan("branch", ["r/Arena"], {"r/Other": [&"ink_hound"]})
	t.call(_joined(unknown.validate_waves()).contains("r/Other is not a listed encounter"), true,
		"ch2_wave_validation_flags_unknown_node")

	var wrong_type := _wave_plan("branch", ["r/Arena"], {})
	wrong_type.rooms[0]["wave"] = [&"ink_hound"]
	t.call(_joined(wrong_type.validate_waves()).contains("must map encounter node ids"), true,
		"ch2_wave_validation_flags_non_dictionary")

	var empty := _wave_plan("branch", ["r/Arena"], {"r/Arena": []})
	t.call(_joined(empty.validate_waves()).contains("wave r/Arena is empty"), true,
		"ch2_wave_validation_flags_empty_wave")

	var bad_enemy := _wave_plan("branch", ["r/Arena"], {"r/Arena": [""]})
	t.call(_joined(bad_enemy.validate_waves()).contains("empty enemy id"), true,
		"ch2_wave_validation_flags_empty_enemy")

	var non_string := _wave_plan("branch", ["r/Arena"], {"r/Arena": [5]})
	t.call(_joined(non_string.validate_waves()).contains("non-string enemy id"), true,
		"ch2_wave_validation_flags_non_string_enemy")

	var event := _wave_plan("event", ["r/event"], {"r/event": [&"ink_hound"]})
	t.call(_joined(event.validate_waves()).contains("must not own a wave"), true,
		"ch2_wave_validation_flags_event_wave")

	var boss := _wave_plan("boss", [], {"r/Arena": [&"ink_hound"]})
	t.call(_joined(boss.validate_waves()).contains("is not a listed encounter"), true,
		"ch2_wave_validation_flags_boss_wave")


func _test_chapter_one_unchanged(t: Callable) -> void:
	var plan := load(CH1_PLAN_PATH) as ChapterPlanData
	t.call(plan != null, true, "ch1_waves_plan_still_loads")
	if plan == null:
		return
	t.call(plan.big_map, false, "ch1_waves_plan_still_linear")
	t.call(plan.validate_waves(), PackedStringArray(), "ch1_waves_validation_is_noop")
	var authored: Variant = plan.room("ch1_01").get("wave", null)
	t.call(authored is Array, true, "ch1_waves_stay_room_level")
	t.call(plan.wave_for("ch1_01", ""), authored, "ch1_waves_room_level_roundtrip")
	t.call(plan.wave_for("ch1_01", "ch1_01/Arena"), authored,
		"ch1_waves_ignore_encounter_id")
	t.call(plan.clear_target(), 6, "ch1_waves_clear_target_unchanged")
	t.call(plan.encounter_ids().is_empty(), true, "ch1_waves_have_no_encounter_lists")


func _wave_plan(type: String, encounters: Array, wave: Dictionary) -> ChapterPlanData:
	var plan := ChapterPlanData.new()
	plan.big_map = true
	plan.rooms.append({
		"id": "r", "type": type,
		"encounters": encounters,
		"wave": wave,
	})
	return plan


func _joined(errors: PackedStringArray) -> String:
	return "\n".join(errors)
