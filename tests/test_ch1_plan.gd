extends RefCounted

## Chapter 1 must be a data-driven demo plan: nine rooms, an elite room, an
## event room, a boss scene and a separate reward pool from the legacy waves.

const PLAN_PATH := "res://resources/chapters/chapter_1_demo.tres"


func run(t: Callable) -> void:
	_test_plan_shape(t)
	_test_room_types(t)
	_test_elite_reward(t)


func _test_plan_shape(t: Callable) -> void:
	var plan := load(PLAN_PATH) as ChapterPlanData
	t.call(plan != null, true, "ch1_plan_loads")
	if plan == null:
		return
	t.call(plan.chapter_id, &"ink_archive", "ch1_plan_chapter_id")
	t.call(plan.rooms.size(), 9, "ch1_plan_has_nine_rooms")
	t.call(plan.boss_scene != null, true, "ch1_plan_has_boss_scene")
	t.call(plan.authority_pool.size() >= 2, true, "ch1_plan_has_two_authorities")
	t.call(plan.room("missing_room").is_empty(), true, "ch1_plan_unknown_room_is_empty")


func _test_room_types(t: Callable) -> void:
	var plan := load(PLAN_PATH) as ChapterPlanData
	if plan == null:
		return
	var expected := {
		"ch1_01": "combat",
		"ch1_04": "elite",
		"ch1_05": "event",
		"ch1_rest": "rest",
		"ch1_boss": "boss",
		"ch1_vault": "vault",
	}
	for room_id in expected:
		t.call(plan.room(room_id).get("type", ""), expected[room_id], "ch1_%s_type" % room_id)
	var elite_wave: Array = plan.room("ch1_04").get("wave", [])
	t.call(elite_wave.has(&"typo_beast"), true, "ch1_elite_has_typo_beast")
	var plan_wave: Array = plan.room("ch1_01").get("wave", [])
	var legacy_wave: Array = CampaignData.chapter(0)["rooms"][0]
	var expected_wave: Array = [&"ink_hound", &"scribe_bug"]
	t.call(plan_wave, expected_wave, "ch1_first_wave_comes_from_plan")
	t.call(plan_wave == legacy_wave, false, "ch1_wave_differs_from_legacy_room_waves")


func _test_elite_reward(t: Callable) -> void:
	var run := RunState.new()
	var profile := Profile.new()
	var options := RunLoot.elite_choices(run, 4, profile)
	t.call(options.size() >= 3, true, "elite_reward_has_three_choices")
	var kinds: Array = []
	for option in options:
		kinds.append(option.get("kind", &""))
	t.call(kinds.has(&"relic") or kinds.has(&"vitality"), true, "elite_reward_guarantees_relic")
