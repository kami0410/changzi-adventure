extends RefCounted

## Chapter 3 big-map data layer: the authored region plan and the graph fixture.
## The fixture has no room scenes; the real region world lives in
## scenes/mds/chapter_3_bigmap.mdsworld.json (see test_ch3_world.gd), and
## game.gd loads the plan from slot 2 (wired in pass 80). The assertions pin the
## plan shape, per-node content ids, fall planes, the wired wave table, the
## routing tables and the plan ↔ graph-fixture agreement, and keep Chapters 1–2
## untouched.

const PLAN_PATH := "res://resources/chapters/chapter_3_demo.tres"
const GRAPH_PATH := "res://tests/fixtures/big_room/ch3_graph.mdsworld.json"
const CH1_PLAN_PATH := "res://resources/chapters/chapter_1_demo.tres"
const CH2_PLAN_PATH := "res://resources/chapters/chapter_2_demo.tres"
const GAME_SCRIPT_PATH := "res://scripts/game.gd"
const BIGMAP_WORLD_PATH := "res://scenes/mds/chapter_3_bigmap.mdsworld.json"
const BIGMAP_SCENE_PATH := "res://scenes/mds/chapter_3_bigmap_world.tscn"
const OLD_CH3_WORLD_PATH := "res://scenes/mds/chapter_3.mdsworld.json"
const OLD_CH3_SCENE_PATH := "res://scenes/mds/chapter_3_world.tscn"
const REGION_DIR := "res://resources/rooms/ch3_bigmap"
const SCENE_DIR := "res://scenes/mds/ch3_bigmap"
const REGION_IDS: PackedStringArray = [
	"ch3_entry", "ch3_branch_a", "ch3_branch_b", "ch3_hub", "ch3_well",
	"ch3_vault", "ch3_event", "ch3_elite", "ch3_boss",
]
const COMBAT_ENCOUNTERS: Array[String] = [
	"ch3_branch_a/Arena", "ch3_branch_a/Arena2", "ch3_branch_b/Arena",
	"ch3_well/Arena", "ch3_well/Arena2", "ch3_elite/Arena",
]
const EVENT_ENCOUNTER := "ch3_event/event"


func run(t: Callable) -> void:
	_test_plan_shape(t)
	_test_region_types(t)
	_test_sizes_and_fall_planes(t)
	_test_content_ids(t)
	_test_wave_wiring(t)
	_test_graph(t)
	_test_fixture_matches_plan(t)
	_test_fixture_geometry(t)
	_test_old_world_unchanged(t)
	_test_other_chapters_unchanged(t)


func _test_plan_shape(t: Callable) -> void:
	var plan := _plan()
	t.call(plan != null, true, "ch3_plan_loads")
	if plan == null:
		return
	t.call(plan.chapter_id, &"lightless_sea", "ch3_plan_chapter_id")
	t.call(plan.big_map, true, "ch3_plan_is_big_map")
	t.call(plan.start_region(), "ch3_entry", "ch3_plan_start_region")
	t.call(plan.rooms.size(), 9, "ch3_plan_has_nine_regions")
	t.call(plan.doors.size(), 11, "ch3_plan_has_eleven_doors")
	t.call(_sorted(plan.room_ids()), _sorted(REGION_IDS), "ch3_plan_region_ids")
	t.call(plan.room("missing_region").is_empty(), true, "ch3_plan_unknown_region_is_empty")
	t.call(plan.validate(), PackedStringArray(), "ch3_plan_validates_clean")
	# Boss routing landed with the Boss 3 pass; the wave wiring landed with the
	# content layer's step 2, so the plan no longer defers its wave validation.
	t.call(plan.boss_scene != null, true, "ch3_plan_owns_boss_scene")
	if plan.boss_scene != null:
		t.call(plan.boss_scene.resource_path,
			"res://scenes/bosses/last_reader.tscn", "ch3_plan_boss_scene_path")
	t.call(plan.authority_pool.size(), 2, "ch3_plan_has_two_base_authorities")
	t.call(plan.authority_pool[0].id, &"revive", "ch3_plan_first_authority_is_revive")
	t.call(plan.authority_pool[1].id, &"rewrite", "ch3_plan_second_authority_is_rewrite")
	t.call(plan.content_pending, false, "ch3_plan_content_pending_cleared")


func _test_region_types(t: Callable) -> void:
	var plan := _plan()
	if plan == null:
		return
	var expected := {
		"ch3_entry": "entrance",
		"ch3_branch_a": "branch",
		"ch3_branch_b": "branch",
		"ch3_hub": "hub",
		"ch3_well": "well",
		"ch3_vault": "vault",
		"ch3_event": "event",
		"ch3_elite": "elite",
		"ch3_boss": "boss",
	}
	for room_id in expected:
		t.call(plan.room(room_id).get("type", ""), expected[room_id],
			"ch3_region_type_%s" % room_id)
	t.call(plan.regions_of_type("entrance").size(), 1, "ch3_one_entrance")
	t.call(plan.regions_of_type("hub").size(), 1, "ch3_one_hub")
	t.call(plan.regions_of_type("boss").size(), 1, "ch3_one_boss")
	t.call(plan.regions_of_type("branch").size(), 2, "ch3_two_branches")
	t.call(plan.regions_of_type("well").size(), 1, "ch3_one_well")
	t.call(plan.regions_of_type("elite").size(), 1, "ch3_one_elite")
	t.call(plan.regions_of_type("event").size(), 1, "ch3_one_event")
	t.call(plan.regions_of_type("vault").size(), 1, "ch3_one_vault")

	var hub := plan.room("ch3_hub")
	t.call(bool(hub.get("rest", false)), true, "ch3_hub_has_rest")
	t.call(String(hub.get("shop", "")), "ch3_hub_shop", "ch3_hub_shop_id")
	t.call(_strings(hub.get("steles", [])), PackedStringArray(["ch3_hub/Stele1"]),
		"ch3_hub_has_stele")
	t.call(_strings(hub.get("shortcuts", [])), PackedStringArray(["hub_shortcut_entry"]),
		"ch3_hub_unlocks_shortcut")

	var vault := plan.room("ch3_vault")
	t.call(bool(vault.get("hidden", false)), true, "ch3_vault_is_hidden")
	t.call(_strings(vault.get("chests", [])).size(), 1, "ch3_vault_has_one_chest")
	t.call(_strings(vault.get("steles", [])).size(), 1, "ch3_vault_has_one_stele")
	t.call(plan.region_size("ch3_vault"), Vector2i(2560, 1440), "ch3_vault_size")

	t.call(bool(plan.room("ch3_well").get("vertical", false)), true, "ch3_well_is_vertical")
	var hidden := 0
	for entry in plan.rooms:
		if bool(entry.get("hidden", false)):
			hidden += 1
	t.call(hidden, 1, "ch3_one_hidden_region")

	# Pending-content markers live on the authored dictionaries themselves so a
	# later content pass can find them without guessing.
	t.call(String(plan.room("ch3_entry").get("note", "")).contains("#14"), true,
		"ch3_entry_notes_vision_compression_pending")
	t.call(String(plan.room("ch3_entry").get("note", "")).contains("#15"), true,
		"ch3_entry_notes_sea_motif_pending")
	t.call(String(plan.room("ch3_event").get("note", "")).contains("Ch3EventData"), true,
		"ch3_event_placeholders_marked")
	t.call(String(plan.room("ch3_boss").get("note", "")).contains("boss_scene"), true,
		"ch3_boss_route_placeholder_marked")


func _test_sizes_and_fall_planes(t: Callable) -> void:
	var plan := _plan()
	if plan == null:
		return
	var expected_sizes := {
		"ch3_entry": Vector2i(2560, 1440),
		"ch3_branch_a": Vector2i(2560, 1440),
		"ch3_branch_b": Vector2i(2560, 1440),
		"ch3_hub": Vector2i(2560, 1440),
		"ch3_well": Vector2i(2560, 2160),
		"ch3_vault": Vector2i(2560, 1440),
		"ch3_event": Vector2i(2560, 1440),
		"ch3_elite": Vector2i(3840, 2160),
		"ch3_boss": Vector2i(3840, 2160),
	}
	for room_id in expected_sizes:
		var size := plan.region_size(room_id)
		t.call(size, expected_sizes[room_id], "ch3_region_size_%s" % room_id)
		t.call(size.x % ChapterPlanData.SCREEN_SIZE.x, 0,
			"ch3_region_width_screens_%s" % room_id)
		t.call(size.y % ChapterPlanData.SCREEN_SIZE.y, 0,
			"ch3_region_height_screens_%s" % room_id)
		var screens_x := size.x / ChapterPlanData.SCREEN_SIZE.x
		var screens_y := size.y / ChapterPlanData.SCREEN_SIZE.y
		t.call(screens_x >= 1 and screens_x <= ChapterPlanData.MAX_REGION_SCREENS, true,
			"ch3_region_width_in_range_%s" % room_id)
		t.call(screens_y >= 1 and screens_y <= ChapterPlanData.MAX_REGION_SCREENS, true,
			"ch3_region_height_in_range_%s" % room_id)
		var entry := plan.room(room_id)
		t.call(entry.has("fall_y") or entry.has("fall_below_bounds"), true,
			"ch3_region_fall_configured_%s" % room_id)
		t.call(plan.region_fall_limit(room_id), float(size.y) + 240.0,
			"ch3_region_fall_limit_%s" % room_id)
		t.call(plan.region_fall_limit(room_id) > float(size.y), true,
			"ch3_region_fall_clears_lower_layers_%s" % room_id)
	t.call(plan.fall_limit("ch3_well", 2160.0), 2400.0, "ch3_fall_uses_room_height")


func _test_content_ids(t: Callable) -> void:
	var plan := _plan()
	if plan == null:
		return
	var encounters := plan.encounter_ids()
	t.call(encounters.size(), 7, "ch3_plan_encounter_count")
	t.call(plan.clear_target(), 7, "ch3_plan_clear_target_from_encounters")
	t.call(plan.clear_target() == plan.encounter_ids().size(), true,
		"ch3_plan_clear_target_matches_encounter_ids")
	t.call(plan.clear_target() != 6, true, "ch3_plan_clear_target_not_legacy_six")
	t.call(plan.clear_target_override, 0, "ch3_plan_has_no_target_override")
	var derived := 0
	for entry in plan.rooms:
		var list: Variant = entry.get("encounters", [])
		if list is Array:
			derived += list.size()
	t.call(plan.clear_target(), derived, "ch3_plan_clear_target_derived_from_regions")

	var combat: Array[String] = []
	for encounter_id in encounters:
		if encounter_id != EVENT_ENCOUNTER:
			combat.append(encounter_id)
	t.call(combat, COMBAT_ENCOUNTERS, "ch3_plan_six_combat_encounters")
	t.call(combat.size(), 6, "ch3_plan_combat_encounter_count")
	t.call(_strings(plan.room("ch3_branch_a").get("encounters", [])),
		PackedStringArray(["ch3_branch_a/Arena", "ch3_branch_a/Arena2"]),
		"ch3_branch_a_has_two_encounters")
	t.call(_strings(plan.room("ch3_branch_b").get("encounters", [])),
		PackedStringArray(["ch3_branch_b/Arena"]), "ch3_branch_b_has_one_encounter")
	t.call(_strings(plan.room("ch3_well").get("encounters", [])).size(), 2,
		"ch3_well_has_two_encounters")
	t.call(_strings(plan.room("ch3_elite").get("encounters", [])).size(), 1,
		"ch3_elite_has_one_encounter")
	t.call(_strings(plan.room("ch3_event").get("encounters", [])),
		PackedStringArray([EVENT_ENCOUNTER]), "ch3_event_uses_event_encounter_id")
	t.call(plan.room("ch3_entry").get("encounters", []).is_empty(), true,
		"ch3_entry_has_no_encounter")
	t.call(plan.room("ch3_boss").get("encounters", []).is_empty(), true,
		"ch3_boss_counts_separately")

	var chests := plan.chest_ids()
	var steles := plan.stele_ids()
	t.call(chests.size(), 3, "ch3_plan_chest_count")
	t.call(steles.size(), 2, "ch3_plan_stele_count")
	t.call(_sorted(chests), _sorted(PackedStringArray([
		"ch3_branch_a/Chest1", "ch3_well/Chest1", "ch3_vault/Chest1",
	])), "ch3_plan_chest_ids")
	t.call(_sorted(steles), _sorted(PackedStringArray([
		"ch3_hub/Stele1", "ch3_vault/Stele1",
	])), "ch3_plan_stele_ids")
	_assert_unique(t, chests, "ch3_chest_ids_unique")
	_assert_unique(t, steles, "ch3_stele_ids_unique")
	_assert_unique(t, encounters, "ch3_encounter_ids_unique")
	for id in encounters:
		t.call(_anchored(id, plan), true, "ch3_encounter_id_is_node_id_%s" % id)
	for id in chests:
		t.call(_anchored(id, plan), true, "ch3_chest_id_is_node_id_%s" % id)
	for id in steles:
		t.call(_anchored(id, plan), true, "ch3_stele_id_is_node_id_%s" % id)
	t.call(RoomProgress.encounter_id("ch3_branch_a", "Arena2", ""),
		"ch3_branch_a/Arena2", "ch3_plan_matches_room_progress_encounter_shape")
	t.call(RoomProgress.content_id("ch3_vault", "Chest1", ""),
		"ch3_vault/Chest1", "ch3_plan_matches_room_progress_content_shape")

	# The old chapter authors six waves; this step stops short of wiring them, but
	# the six combat encounters are ready to take them one-for-one later.
	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	t.call(game_script != null, true, "ch3_plan_game_script_loads")
	if game_script != null:
		var waves: Array = game_script.get_script_constant_map().get("ROOM_WAVES", [])
		t.call(waves.size() >= 3, true, "ch3_plan_room_waves_present")
		if waves.size() >= 3:
			t.call((waves[2] as Array).size(), 6, "ch3_old_six_waves_present")
			t.call((waves[2] as Array).size(), combat.size(),
				"ch3_combat_encounters_match_old_wave_count")


func _test_wave_wiring(t: Callable) -> void:
	var plan := _plan()
	if plan == null:
		return
	# Wave wiring landed with the content layer's step 2: every combat encounter
	# owns one keyed wave, the event node and boss region own none, and the plan
	# validates its wave table normally. Boss routing is still a later pass.
	var wave_keys := 0
	for entry in plan.rooms:
		var table: Variant = entry.get("wave", null)
		if table is Dictionary:
			wave_keys += (table as Dictionary).size()
	t.call(wave_keys, COMBAT_ENCOUNTERS.size(), "ch3_wave_keys_match_combat_encounters")
	for encounter_id in COMBAT_ENCOUNTERS:
		var region := encounter_id.get_slice("/", 0)
		t.call(plan.wave_for(region, encounter_id).is_empty(), false,
			"ch3_wave_authored_%s" % encounter_id)
	t.call(plan.wave_for("ch3_event", EVENT_ENCOUNTER).is_empty(), true,
		"ch3_event_wave_not_authored")
	t.call(plan.room("ch3_boss").has("wave"), false, "ch3_boss_wave_not_authored")
	t.call(plan.authority_pool.size(), 2, "ch3_authority_pool_has_two_base_entries")
	t.call(plan.authority_pool[0].id, &"revive", "ch3_authority_pool_first_is_revive")
	t.call(plan.authority_pool[1].id, &"rewrite", "ch3_authority_pool_second_is_rewrite")
	t.call(plan.boss_scene != null, true, "ch3_boss_scene_routed")
	if plan.boss_scene != null:
		t.call(plan.boss_scene.resource_path,
			"res://scenes/bosses/last_reader.tscn", "ch3_boss_scene_routed_path")
	t.call(plan.content_pending, false, "ch3_plan_waves_validate_normally")
	t.call(plan.validate_waves(), PackedStringArray(), "ch3_wave_table_validates_clean")

	# content_pending still defers only the wave table: a copy that drops the
	# wired waves validates with the flag on, and reports six missing waves with
	# the flag off.
	var pending := ChapterPlanData.new()
	pending.big_map = true
	pending.start_room = plan.start_room
	for entry in plan.rooms:
		var copy: Dictionary = entry.duplicate(true)
		copy.erase("wave")
		pending.rooms.append(copy)
	for entry in plan.doors:
		var door_copy: Dictionary = entry.duplicate(true)
		pending.doors.append(door_copy)
	pending.content_pending = true
	t.call(pending.validate(), PackedStringArray(), "ch3_content_pending_still_defers_waves")
	pending.content_pending = false
	var strict_errors := pending.validate()
	t.call(strict_errors.size(), 6, "ch3_finished_plan_must_wire_waves")
	t.call(_joined(strict_errors).contains("needs a wave"), true,
		"ch3_finished_plan_reports_missing_waves")

	# The shortcut has no in-game granting source yet: the plan keeps the barrier
	# closed (requires ch3_shortcut) and game.gd never mentions the ability.
	var shortcut: Dictionary = plan.door("hub_shortcut_entry")
	t.call(_strings(shortcut.get("requires", [])), PackedStringArray(["ch3_shortcut"]),
		"ch3_shortcut_requires_flag")
	t.call(bool(shortcut.get("one_way", false)), true, "ch3_shortcut_is_one_way")
	t.call(String(shortcut.get("note", "")).contains("#16"), true,
		"ch3_shortcut_source_pending_marked")
	var game_source := FileAccess.get_file_as_string(GAME_SCRIPT_PATH)
	t.call(game_source.is_empty(), false, "ch3_game_source_readable")
	t.call(game_source.contains("ch3_shortcut"), false,
		"ch3_game_grants_no_shortcut_yet")

	# Pass 80 routes the plan and the real region world into the campaign while
	# the old linear Chapter 3 world stays on disk.
	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	t.call(game_script != null, true, "ch3_pending_game_script_loads")
	if game_script != null:
		var game_constants := game_script.get_script_constant_map()
		var plan_paths: Array = game_constants.get("CHAPTER_PLAN_PATHS", [])
		t.call(plan_paths.size(), 4, "ch3_game_has_four_plan_slots")
		if plan_paths.size() == 4:
			t.call(plan_paths[2], PLAN_PATH, "ch3_game_plan_slot_wired")
		var world_files: Array = game_constants.get("MDS_WORLD_FILES", [])
		t.call(world_files.size(), 4, "ch3_game_has_four_world_files")
		if world_files.size() == 4:
			t.call(world_files[2], BIGMAP_WORLD_PATH,
				"ch3_game_uses_the_big_map_world")
		var chapter_scenes: Array = game_constants.get("MDS_CHAPTER_SCENES", [])
		t.call(chapter_scenes.size(), 4, "ch3_game_has_four_world_scenes")
		if chapter_scenes.size() == 4:
			t.call((chapter_scenes[2] as PackedScene).resource_path, BIGMAP_SCENE_PATH,
				"ch3_game_uses_the_big_map_world_scene")
	# Step 2 landed the real region world; pass 80 wired it into the campaign.
	t.call(DirAccess.dir_exists_absolute(REGION_DIR), true,
		"ch3_region_data_dir_exists")
	if DirAccess.dir_exists_absolute(REGION_DIR):
		t.call(DirAccess.get_files_at(REGION_DIR).size(), 9,
			"ch3_region_data_dir_has_nine_regions")
	t.call(DirAccess.dir_exists_absolute(SCENE_DIR), true,
		"ch3_region_scene_dir_exists")
	if DirAccess.dir_exists_absolute(SCENE_DIR):
		t.call(DirAccess.get_files_at(SCENE_DIR).size(), 9,
			"ch3_region_scene_dir_has_nine_scenes")
	t.call(FileAccess.file_exists(OLD_CH3_WORLD_PATH), true,
		"ch3_old_world_still_present")
	t.call(ResourceLoader.exists(OLD_CH3_SCENE_PATH), true,
		"ch3_old_world_scene_still_present")


func _test_graph(t: Callable) -> void:
	var plan := _plan()
	if plan == null:
		return
	var reached := plan.reachable_from("ch3_entry")
	t.call(reached.size(), 9, "ch3_graph_entry_reaches_every_region")
	for room_id in plan.room_ids():
		t.call(reached.has(room_id), true, "ch3_graph_reaches_%s" % room_id)
	t.call(reached.has("ch3_hub"), true, "ch3_graph_entry_reaches_hub")
	t.call(reached.has("ch3_vault"), true, "ch3_graph_entry_reaches_hidden_vault")
	t.call(reached.has("ch3_boss"), true, "ch3_graph_entry_reaches_boss")
	t.call(plan.reachable_from().size(), 9, "ch3_graph_default_start_is_entrance")
	t.call(plan.reachable_from("ch3_boss").size(), 1, "ch3_graph_boss_is_one_way_in")
	t.call(plan.reachable_from("ch3_vault", false).size(), 9,
		"ch3_graph_undirected_from_leaf_reaches_all")

	t.call(plan.pairs_count(), 11, "ch3_graph_has_eleven_region_pairs")
	t.call(plan.pairs_count() >= plan.rooms.size(), true, "ch3_graph_has_a_loop")
	var one_way := plan.one_way_doors()
	t.call(one_way.size(), 2, "ch3_graph_two_one_way_doors")
	var one_way_ids := PackedStringArray()
	for entry in one_way:
		one_way_ids.append(String(entry.get("id", "")))
	one_way_ids.sort()
	t.call(one_way_ids, PackedStringArray(["elite_boss", "hub_shortcut_entry"]),
		"ch3_graph_one_way_door_ids")
	var shortcut: Dictionary = plan.door("hub_shortcut_entry")
	t.call(String(shortcut.get("from", "")), "ch3_hub", "ch3_shortcut_starts_at_hub")
	t.call(String(shortcut.get("to", "")), "ch3_entry", "ch3_shortcut_returns_to_entry")
	t.call(String(shortcut.get("from_gate", "")), "shortcut", "ch3_shortcut_from_gate")
	t.call(String(shortcut.get("to_gate", "")), "shortcut_arrival",
		"ch3_shortcut_arrival_gate")
	t.call(_strings(plan.door("elite_boss").get("requires", [])).is_empty(), true,
		"ch3_boss_door_needs_no_ability")
	t.call(plan.door_targets("ch3_boss").is_empty(), true, "ch3_boss_has_no_outgoing_door")
	t.call(plan.door_targets("ch3_hub").has("ch3_entry"), true,
		"ch3_shortcut_returns_to_entry")
	t.call(plan.validate_graph(), PackedStringArray(), "ch3_graph_validates_clean")


func _test_fixture_matches_plan(t: Callable) -> void:
	var plan := _plan()
	var graph := _graph()
	t.call(not graph.is_empty(), true, "ch3_graph_fixture_parses")
	if plan == null or graph.is_empty():
		return
	t.call(bool(graph.get("fixture", false)), true, "ch3_graph_fixture_is_marked_test_asset")
	t.call(bool(graph.get("content_pending", false)), true,
		"ch3_graph_fixture_marks_pending_content")
	t.call(String(graph.get("format", "")), "mds_world", "ch3_graph_fixture_world_format")
	t.call(String(graph.get("name", "")), "Chapter 3 Big-Map Graph Fixture",
		"ch3_graph_fixture_name")
	var fixture_note := String(graph.get("note", ""))
	t.call(fixture_note.contains("TEST FIXTURE ONLY"), true, "ch3_graph_fixture_note")
	t.call(fixture_note.contains("#14"), true, "ch3_graph_fixture_notes_vision_pending")
	t.call(fixture_note.contains("#15"), true, "ch3_graph_fixture_notes_sea_pending")
	t.call(fixture_note.contains("#16"), true, "ch3_graph_fixture_notes_shortcut_pending")
	t.call(String(graph.get("start_room", "")), plan.start_region(),
		"ch3_graph_fixture_start_room")
	var game_source := FileAccess.get_file_as_string(GAME_SCRIPT_PATH)
	t.call(game_source.contains("ch3_graph.mdsworld.json"), false,
		"ch3_graph_fixture_is_never_referenced_by_the_game")
	var rooms: Dictionary = graph.get("rooms", {})
	t.call(rooms.size(), plan.rooms.size(), "ch3_graph_fixture_region_count")
	var graph_encounters := 0
	for room_id in plan.room_ids():
		t.call(rooms.has(room_id), true, "ch3_graph_fixture_has_%s" % room_id)
		if not rooms.has(room_id):
			continue
		var fixture_room: Dictionary = rooms[room_id]
		var plan_room := plan.room(room_id)
		t.call(fixture_room.has("scene_path"), false,
			"ch3_graph_fixture_room_has_no_scene_%s" % room_id)
		t.call(String(fixture_room.get("type", "")), plan_room.get("type", ""),
			"ch3_graph_fixture_type_%s" % room_id)
		t.call(_strings(fixture_room.get("encounters", [])),
			_strings(plan_room.get("encounters", [])),
			"ch3_graph_fixture_encounters_%s" % room_id)
		t.call(_strings(fixture_room.get("chests", [])), _strings(plan_room.get("chests", [])),
			"ch3_graph_fixture_chests_%s" % room_id)
		t.call(_strings(fixture_room.get("steles", [])), _strings(plan_room.get("steles", [])),
			"ch3_graph_fixture_steles_%s" % room_id)
		t.call(_strings(fixture_room.get("shortcuts", [])),
			_strings(plan_room.get("shortcuts", [])),
			"ch3_graph_fixture_shortcuts_%s" % room_id)
		t.call(bool(fixture_room.get("hidden", false)), bool(plan_room.get("hidden", false)),
			"ch3_graph_fixture_hidden_%s" % room_id)
		var encounters: Variant = fixture_room.get("encounters", [])
		if encounters is Array:
			graph_encounters += encounters.size()
	t.call(graph_encounters, 7, "ch3_graph_declares_seven_encounters")
	t.call(plan.clear_target(), graph_encounters, "ch3_plan_clear_target_matches_graph_encounters")

	var areas: Dictionary = graph.get("areas", {})
	t.call(areas.has("Lightless Sea"), true, "ch3_graph_fixture_lightless_sea_area")
	if areas.has("Lightless Sea"):
		var area: Dictionary = areas["Lightless Sea"]
		t.call(String(area.get("weather", "")).contains("fog"), true,
			"ch3_graph_fixture_area_fog")
		t.call(String(area.get("weather", "")).contains("rain"), true,
			"ch3_graph_fixture_area_rain")
		t.call(String(area.get("boss_background", "")), "deep_water",
			"ch3_graph_fixture_boss_background")
		t.call(String(area.get("background", "")), "", "ch3_graph_fixture_area_background")
		# The sea motif (status #15) is not modelled here; the fixture mirrors the
		# old world area, which authors no backdrop image.
		t.call(area.has("backdrop_image"), false, "ch3_graph_fixture_no_backdrop_decision")

	var gates := _gates(graph)
	var outgoing := 0
	var arrivals := 0
	for key in gates:
		var gate: Dictionary = gates[key]
		var room_id := String(key).get_slice("/", 0)
		var gate_name := String(key).get_slice("/", 1)
		if gate.has("to"):
			outgoing += 1
			var door := _door_for_fixture_gate(plan, room_id, gate_name)
			t.call(not door.is_empty(), true, "ch3_graph_fixture_gate_declared_%s" % key)
			if door.is_empty():
				continue
			var forward := String(door.get("from", "")) == room_id \
				and String(door.get("from_gate", "")) == gate_name
			if forward:
				t.call(String(door.get("to", "")), String(gate.get("to", "")),
					"ch3_graph_fixture_gate_target_%s" % key)
				t.call(String(door.get("to_gate", "")), String(gate.get("to_gate", "")),
					"ch3_graph_fixture_gate_arrival_%s" % key)
				t.call(bool(door.get("one_way", false)), bool(gate.get("one_way", false)),
					"ch3_graph_fixture_gate_one_way_%s" % key)
			else:
				# The reverse side of a two-way door is derived, not authored as
				# a second plan entry.
				t.call(String(door.get("from", "")), String(gate.get("to", "")),
					"ch3_graph_fixture_gate_reverse_target_%s" % key)
				t.call(String(door.get("from_gate", "")), String(gate.get("to_gate", "")),
					"ch3_graph_fixture_gate_reverse_arrival_%s" % key)
				t.call(bool(door.get("one_way", false)), false,
					"ch3_graph_fixture_reverse_is_two_way_%s" % key)
			t.call(_strings(door.get("requires", [])),
				_strings(gate.get("requires", [])), "ch3_graph_fixture_gate_requires_%s" % key)
		else:
			arrivals += 1
			var arrival := _door_by_arrival(plan, room_id, gate_name)
			t.call(not arrival.is_empty(), true, "ch3_graph_fixture_dead_end_declared_%s" % key)
	t.call(outgoing, 20, "ch3_graph_fixture_outgoing_gate_count")
	t.call(arrivals, 2, "ch3_graph_fixture_arrival_only_gate_count")

	for entry in plan.doors:
		var door_id := String(entry.get("id", ""))
		var from := String(entry.get("from", ""))
		var to := String(entry.get("to", ""))
		var from_key := "%s/%s" % [from, String(entry.get("from_gate", ""))]
		var to_key := "%s/%s" % [to, String(entry.get("to_gate", ""))]
		t.call(gates.has(from_key), true, "ch3_door_%s_has_from_gate" % door_id)
		t.call(gates.has(to_key), true, "ch3_door_%s_has_arrival_gate" % door_id)
		if not gates.has(from_key) or not gates.has(to_key):
			continue
		var from_gate: Dictionary = gates[from_key]
		var to_gate: Dictionary = gates[to_key]
		t.call(String(from_gate.get("to", "")), to, "ch3_door_%s_target" % door_id)
		t.call(String(from_gate.get("to_gate", "")), String(entry.get("to_gate", "")),
			"ch3_door_%s_arrival_name" % door_id)
		if bool(entry.get("one_way", false)):
			t.call(to_gate.has("to"), false, "ch3_door_%s_one_way_has_no_return" % door_id)
		else:
			t.call(String(to_gate.get("to", "")), from, "ch3_door_%s_returns" % door_id)
			t.call(String(to_gate.get("to_gate", "")), String(entry.get("from_gate", "")),
				"ch3_door_%s_returns_to_gate" % door_id)
		t.call(_strings(from_gate.get("requires", [])), _strings(entry.get("requires", [])),
			"ch3_door_%s_requires" % door_id)

	var fixture_reached := _fixture_reachable(graph, plan.start_region())
	t.call(fixture_reached.size(), rooms.size(), "ch3_graph_fixture_all_regions_reachable")
	for room_id in rooms:
		t.call(fixture_reached.has(String(room_id)), true,
			"ch3_graph_fixture_reaches_%s" % room_id)


func _test_fixture_geometry(t: Callable) -> void:
	var plan := _plan()
	var graph := _graph()
	if plan == null or graph.is_empty():
		return
	var rooms: Dictionary = graph.get("rooms", {})
	var ids: Array = rooms.keys()
	for room_id in ids:
		var id := String(room_id)
		var room: Dictionary = rooms[room_id]
		var bounds := _room_world_rect(graph, id)
		var size := plan.region_size(id)
		t.call(bounds.size, Vector2(float(size.x), float(size.y)),
			"ch3_graph_fixture_bounds_%s" % id)
		var origin: Array = room.get("origin", [])
		t.call(origin.size(), 2, "ch3_graph_fixture_origin_%s" % id)
		if origin.size() == 2:
			t.call(int(origin[0]) % 32, 0, "ch3_graph_fixture_origin_x_grid_%s" % id)
			t.call(int(origin[1]) % 32, 0, "ch3_graph_fixture_origin_y_grid_%s" % id)
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a := _room_world_rect(graph, String(ids[i]))
			var b := _room_world_rect(graph, String(ids[j]))
			t.call(a.intersects(b, false), false,
				"ch3_graph_fixture_no_overlap_%s_%s" % [String(ids[i]), String(ids[j])])

	for entry in plan.doors:
		var door_id := String(entry.get("id", ""))
		var from := _room_world_rect(graph, String(entry.get("from", "")))
		var to := _room_world_rect(graph, String(entry.get("to", "")))
		var shortcut := bool(entry.get("one_way", false)) \
			and not _strings(entry.get("requires", [])).is_empty()
		if shortcut:
			# A shortcut door is a deliberate teleport link between non-touching
			# regions; it still arrives through a named gate.
			t.call(_touching(from, to), false, "ch3_door_%s_shortcut_is_not_adjacent" % door_id)
		else:
			t.call(_touching(from, to), true, "ch3_door_%s_regions_touch" % door_id)

	var gates := _gates(graph)
	for key in gates:
		var id := String(key)
		var room_id := id.get_slice("/", 0)
		var gate: Dictionary = gates[key]
		var local := _room_local_rect(graph, room_id)
		var pos_value: Array = gate.get("pos", [])
		t.call(pos_value.size(), 2, "ch3_graph_fixture_gate_pos_%s" % id)
		if pos_value.size() != 2:
			continue
		var pos := Vector2(float(pos_value[0]), float(pos_value[1]))
		var side := String(gate.get("side", ""))
		t.call(MDSWorld.SIDES.has(side), true, "ch3_graph_fixture_gate_side_%s" % id)
		t.call(pos.x >= 0.0 and pos.x <= local.size.x and pos.y >= 0.0 and pos.y <= local.size.y,
			true, "ch3_graph_fixture_gate_inside_%s" % id)
		match side:
			"left":
				t.call(pos.x <= 16.0, true, "ch3_graph_fixture_gate_on_left_%s" % id)
			"right":
				t.call(pos.x >= local.size.x - 16.0, true,
					"ch3_graph_fixture_gate_on_right_%s" % id)
			"top":
				t.call(pos.y <= 16.0, true, "ch3_graph_fixture_gate_on_top_%s" % id)
			"bot":
				t.call(pos.y >= local.size.y - 16.0, true,
					"ch3_graph_fixture_gate_on_bot_%s" % id)
			"door":
				t.call(pos.x >= 8.0 and pos.x <= local.size.x - 8.0
					and pos.y >= 8.0 and pos.y <= local.size.y - 8.0, true,
					"ch3_graph_fixture_door_inside_%s" % id)
		t.call(plan.fall_limit(room_id, local.size.y) > local.size.y, true,
			"ch3_graph_fixture_fall_covers_%s" % room_id)


func _test_old_world_unchanged(t: Callable) -> void:
	# Step 1 leaves the linear world exactly as it is: 9 rooms, 17 outgoing
	# gates, start at ch3_01, and the world scene still points at that JSON.
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
		var sides := {"right": 0, "left": 0, "door": 0}
		for room_id in rooms:
			var gates: Dictionary = rooms[room_id].get("gates", {})
			for gate_name in gates:
				var gate: Dictionary = gates[gate_name]
				if gate.has("to"):
					outgoing += 1
				var side := String(gate.get("side", ""))
				if sides.has(side):
					sides[side] = int(sides[side]) + 1
		t.call(outgoing, 17, "ch3_old_world_still_seventeen_gates")
		t.call(sides["right"], 7, "ch3_old_world_seven_right_gates")
		t.call(sides["left"], 7, "ch3_old_world_seven_left_gates")
		t.call(sides["door"], 3, "ch3_old_world_three_door_gates")
	var scene_source := FileAccess.get_file_as_string(OLD_CH3_SCENE_PATH)
	t.call(scene_source.contains("chapter_3.mdsworld.json"), true,
		"ch3_old_world_scene_still_points_at_its_world")


func _test_other_chapters_unchanged(t: Callable) -> void:
	var ch1 := load(CH1_PLAN_PATH) as ChapterPlanData
	t.call(ch1 != null, true, "ch3_ch1_plan_still_loads")
	if ch1 != null:
		t.call(ch1.big_map, false, "ch3_ch1_plan_still_linear")
		t.call(ch1.rooms.size(), 9, "ch3_ch1_plan_still_nine_rooms")
		t.call(ch1.clear_target(), 6, "ch3_ch1_plan_clear_target_still_six")
		t.call(ch1.content_pending, false, "ch3_ch1_plan_has_no_pending_content")
		t.call(ch1.validate(), PackedStringArray(), "ch3_ch1_plan_validates_clean")

	var ch2 := load(CH2_PLAN_PATH) as ChapterPlanData
	t.call(ch2 != null, true, "ch3_ch2_plan_still_loads")
	if ch2 != null:
		t.call(ch2.big_map, true, "ch3_ch2_plan_still_big_map")
		t.call(ch2.rooms.size(), 9, "ch3_ch2_plan_still_nine_regions")
		t.call(ch2.doors.size(), 11, "ch3_ch2_plan_still_eleven_doors")
		t.call(ch2.clear_target(), 7, "ch3_ch2_plan_clear_target_still_seven")
		t.call(ch2.content_pending, false, "ch3_ch2_plan_has_no_pending_content")
		t.call(ch2.validate(), PackedStringArray(), "ch3_ch2_plan_validates_clean")


func _plan() -> ChapterPlanData:
	return load(PLAN_PATH) as ChapterPlanData


func _graph() -> Dictionary:
	var text := FileAccess.get_file_as_string(GRAPH_PATH)
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


func _gates(graph: Dictionary) -> Dictionary:
	var out := {}
	var rooms: Dictionary = graph.get("rooms", {})
	for room_id in rooms:
		var gates: Dictionary = rooms[room_id].get("gates", {})
		for gate_name in gates:
			out["%s/%s" % [String(room_id), String(gate_name)]] = gates[gate_name]
	return out


## The plan door a fixture gate belongs to: either its authored forward gate or
## the derived reverse gate of a two-way door.
func _door_for_fixture_gate(plan: ChapterPlanData, room_id: String, gate_name: String) -> Dictionary:
	for entry in plan.doors:
		if String(entry.get("from", "")) == room_id \
				and String(entry.get("from_gate", "")) == gate_name:
			return entry
		if not bool(entry.get("one_way", false)) \
				and String(entry.get("to", "")) == room_id \
				and String(entry.get("to_gate", "")) == gate_name:
			return entry
	return {}


func _door_by_arrival(plan: ChapterPlanData, room_id: String, gate_name: String) -> Dictionary:
	for entry in plan.doors:
		if String(entry.get("to", "")) == room_id \
				and String(entry.get("to_gate", "")) == gate_name:
			return entry
	return {}


func _fixture_reachable(graph: Dictionary, start: String) -> PackedStringArray:
	var out := PackedStringArray()
	var rooms: Dictionary = graph.get("rooms", {})
	if not rooms.has(start):
		return out
	var seen := {start: true}
	var queue: Array[String] = [start]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		out.append(current)
		var gates: Dictionary = rooms[current].get("gates", {})
		for gate_name in gates:
			var gate: Dictionary = gates[gate_name]
			var target := String(gate.get("to", ""))
			if target.is_empty() or not rooms.has(target) or seen.has(target):
				continue
			seen[target] = true
			queue.append(target)
	return out


func _room_local_rect(graph: Dictionary, room_id: String) -> Rect2:
	var rooms: Dictionary = graph.get("rooms", {})
	if not rooms.has(room_id):
		return Rect2()
	var room: Dictionary = rooms[room_id]
	var union := Rect2()
	var first := true
	for rect_value in room.get("rects", []):
		if not rect_value is Array or rect_value.size() < 4:
			continue
		var rect := Rect2(float(rect_value[0]), float(rect_value[1]),
			float(rect_value[2]), float(rect_value[3]))
		if first:
			union = rect
			first = false
		else:
			union = union.merge(rect)
	return union


func _room_world_rect(graph: Dictionary, room_id: String) -> Rect2:
	var local := _room_local_rect(graph, room_id)
	var rooms: Dictionary = graph.get("rooms", {})
	if not rooms.has(room_id):
		return local
	var origin_value: Array = rooms[room_id].get("origin", [])
	if origin_value.size() < 2:
		return local
	var origin := Vector2(float(origin_value[0]), float(origin_value[1]))
	return Rect2(origin + local.position, local.size)


func _touching(a: Rect2, b: Rect2) -> bool:
	var vertical_edge := is_equal_approx(a.end.x, b.position.x) \
		or is_equal_approx(b.end.x, a.position.x)
	var horizontal_edge := is_equal_approx(a.end.y, b.position.y) \
		or is_equal_approx(b.end.y, a.position.y)
	var y_overlap := minf(a.end.y, b.end.y) - maxf(a.position.y, b.position.y)
	var x_overlap := minf(a.end.x, b.end.x) - maxf(a.position.x, b.position.x)
	return (vertical_edge and y_overlap > 0.0) or (horizontal_edge and x_overlap > 0.0)


func _anchored(id: String, plan: ChapterPlanData) -> bool:
	for room_id in plan.room_ids():
		if id.begins_with(room_id + "/"):
			return true
	return false


func _assert_unique(t: Callable, ids: PackedStringArray, label: String) -> void:
	var seen := {}
	for id in ids:
		t.call(seen.has(id), false, "%s_no_duplicate_%s" % [label, id])
		seen[id] = true


func _strings(value: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	if value is Array:
		for item in value:
			if item is String:
				out.append(String(item))
	out.sort()
	return out


func _sorted(ids: PackedStringArray) -> PackedStringArray:
	var out := ids.duplicate()
	out.sort()
	return out


func _joined(errors: PackedStringArray) -> String:
	return "\n".join(errors)
