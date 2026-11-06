extends RefCounted

## Big-map decoupling: per-node content/encounter ids, plan-driven clear
## targets and per-room fall planes. Chapter 1 must keep its old numbers.


func run(t: Callable) -> void:
	_test_content_ids(t)
	_test_unique_ids(t)
	_test_recorded_fallback(t)
	_test_event_encounter(t)
	_test_ch1_target(t)
	_test_derived_target(t)
	_test_target_override(t)
	_test_fall_default(t)
	_test_fall_overrides(t)


func _test_content_ids(t: Callable) -> void:
	t.call(RoomProgress.content_id("ch1_03", "Chest"), "ch1_03/Chest", "content_id_room_and_name")
	t.call(RoomProgress.content_id("ch1_03", "Chest", "authored_chest"), "authored_chest",
		"content_id_authored_wins")
	t.call(RoomProgress.content_id("ch1_03", ""), "ch1_03", "content_id_empty_name_falls_back")
	t.call(RoomProgress.content_id("", "Chest"), "Chest", "content_id_empty_room_keeps_name")
	t.call(RoomProgress.encounter_id("ch2_04", "Arena", ""), "ch2_04/Arena",
		"encounter_id_room_and_name")
	t.call(RoomProgress.encounter_id("ch2_04", "Arena", "lung_gate"), "lung_gate",
		"encounter_id_authored_wins")


func _test_unique_ids(t: Callable) -> void:
	var used: Dictionary = {}
	t.call(RoomProgress.unique_id("ch2_01/Chest", used), "ch2_01/Chest", "unique_id_first")
	t.call(RoomProgress.unique_id("ch2_01/Chest", used), "ch2_01/Chest#2", "unique_id_second")
	t.call(RoomProgress.unique_id("ch2_01/Chest", used), "ch2_01/Chest#3", "unique_id_third")
	t.call(RoomProgress.unique_id("ch2_01/Stele", used), "ch2_01/Stele", "unique_id_other_kept")
	t.call(used.size(), 4, "unique_id_records_all")


func _test_recorded_fallback(t: Callable) -> void:
	var ids := {"ch2_01/Chest": true}
	var legacy := {"ch1_03": true}
	t.call(RoomProgress.is_recorded(ids, legacy, "ch2_01/Chest", "ch2_01"), true,
		"recorded_by_id")
	t.call(RoomProgress.is_recorded(ids, legacy, "ch1_03/Chest", "ch1_03"), true,
		"recorded_by_legacy_room")
	t.call(RoomProgress.is_recorded(ids, legacy, "ch2_02/Chest", "ch2_02"), false,
		"recorded_neither")
	t.call(RoomProgress.is_recorded({}, {}, "x", "y"), false, "recorded_empty")


func _test_event_encounter(t: Callable) -> void:
	t.call(RoomProgress.event_encounter_id("ch1_05"), "ch1_05/event", "event_id_shape")


func _test_ch1_target(t: Callable) -> void:
	var plan := load("res://resources/chapters/chapter_1_demo.tres") as ChapterPlanData
	t.call(plan != null, true, "ch1_plan_loads_for_target")
	if plan == null:
		return
	t.call(plan.clear_target(), 6, "ch1_plan_clear_target_six")
	t.call(plan.clear_target_override, 0, "ch1_plan_has_no_target_override")
	for entry in plan.rooms:
		t.call(plan.fall_limit(String(entry.get("id", ""))), ChapterPlanData.DEFAULT_FALL_Y,
			"ch1_fall_default_%s" % String(entry.get("id", "")))


func _test_derived_target(t: Callable) -> void:
	var plan := ChapterPlanData.new()
	plan.rooms.append({"id": "a", "type": "combat"})
	plan.rooms.append({"id": "b", "type": "elite"})
	plan.rooms.append({"id": "c", "type": "event"})
	plan.rooms.append({"id": "rest", "type": "rest"})
	plan.rooms.append({"id": "boss", "type": "boss"})
	plan.rooms.append({"id": "vault", "type": "vault"})
	plan.rooms.append({"id": "unknown"})
	t.call(plan.clear_target(), 3, "plan_target_counts_clearable_types")
	t.call(ChapterPlanData.new().clear_target(), 0, "empty_plan_target_zero")


func _test_target_override(t: Callable) -> void:
	var plan := ChapterPlanData.new()
	plan.rooms.append({"id": "a", "type": "combat"})
	plan.clear_target_override = 4
	t.call(plan.clear_target(), 4, "plan_target_override_wins")
	plan.clear_target_override = -2
	t.call(plan.clear_target(), 1, "plan_target_negative_override_ignored")


func _test_fall_default(t: Callable) -> void:
	var plan := ChapterPlanData.new()
	plan.rooms.append({"id": "room", "type": "combat"})
	t.call(plan.fall_limit("room"), ChapterPlanData.DEFAULT_FALL_Y, "fall_plan_default")
	t.call(ChapterPlanData.DEFAULT_FALL_Y, 850.0, "fall_default_is_850")
	t.call(plan.fall_limit("missing"), ChapterPlanData.DEFAULT_FALL_Y, "fall_missing_room_default")


func _test_fall_overrides(t: Callable) -> void:
	var plan := ChapterPlanData.new()
	plan.rooms.append({"id": "tall", "type": "combat", "fall_y": 2400.0})
	plan.rooms.append({"id": "below", "type": "combat", "fall_below_bounds": 300.0})
	plan.rooms.append({"id": "both", "type": "combat", "fall_y": 1900.0, "fall_below_bounds": 300.0})
	plan.rooms.append({"id": "bad", "type": "combat", "fall_y": "deep"})
	t.call(plan.fall_limit("tall"), 2400.0, "fall_y_read")
	t.call(plan.fall_limit("below", 1440.0), 1740.0, "fall_below_bounds_read")
	t.call(plan.fall_limit("both", 1440.0), 1900.0, "fall_y_wins_over_below")
	t.call(plan.fall_limit("bad"), ChapterPlanData.DEFAULT_FALL_Y, "fall_bad_value_ignored")
	t.call(ChapterPlanData.fall_limit_from_entry({"fall_y": 900}, 720.0, NAN), 900.0,
		"fall_entry_helper_reads_y")
	t.call(is_nan(ChapterPlanData.fall_limit_from_entry({}, 720.0, NAN)), true,
		"fall_entry_helper_reports_unset")
