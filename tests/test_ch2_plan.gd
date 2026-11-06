extends RefCounted

## Chapter 2 big-map data layer: the authored region plan and the graph
## fixture. Nothing here is chapter content — the fixture has no room scenes,
## and game.gd does not load the plan until the real regions are built. The
## assertions pin the plan shape, per-node content ids, fall planes and the
## plan ↔ world-graph agreement.

const PLAN_PATH := "res://resources/chapters/chapter_2_demo.tres"
const GRAPH_PATH := "res://tests/fixtures/big_room/ch2_graph.mdsworld.json"
const CH1_PLAN_PATH := "res://resources/chapters/chapter_1_demo.tres"


func run(t: Callable) -> void:
	_test_plan_shape(t)
	_test_region_types(t)
	_test_sizes_and_fall_planes(t)
	_test_content_ids(t)
	_test_graph(t)
	_test_fixture_matches_plan(t)
	_test_fixture_geometry(t)
	_test_validation_catches_bad_plans(t)
	_test_chapter_one_unchanged(t)


func _test_plan_shape(t: Callable) -> void:
	var plan := _plan()
	t.call(plan != null, true, "ch2_plan_loads")
	if plan == null:
		return
	t.call(plan.chapter_id, &"breathing_ruins", "ch2_plan_chapter_id")
	t.call(plan.big_map, true, "ch2_plan_is_big_map")
	t.call(plan.start_region(), "ch2_entry", "ch2_plan_start_region")
	t.call(plan.rooms.size(), 9, "ch2_plan_has_nine_regions")
	t.call(plan.doors.size(), 11, "ch2_plan_has_eleven_doors")
	t.call(plan.room("missing_region").is_empty(), true, "ch2_plan_unknown_region_is_empty")
	t.call(plan.validate(), PackedStringArray(), "ch2_plan_validates_clean")
	# The plan owns the Chapter 2 boss scene (its unique breath/nail mechanics);
	# the authority pool carries the shared revive/rewrite base and conditional
	# entries come from ContentLibrary.
	t.call(plan.boss_scene != null, true, "ch2_plan_owns_boss_scene")
	if plan.boss_scene != null:
		t.call(plan.boss_scene.resource_path,
			"res://scenes/bosses/lung_bell_guardian.tscn",
			"ch2_plan_boss_scene_is_lung_guardian")
	t.call(plan.authority_pool.size(), 2, "ch2_plan_has_two_base_authorities")
	t.call(plan.authority_pool[0].id, &"revive", "ch2_plan_first_authority_is_revive")
	t.call(plan.authority_pool[1].id, &"rewrite", "ch2_plan_second_authority_is_rewrite")


func _test_region_types(t: Callable) -> void:
	var plan := _plan()
	if plan == null:
		return
	var expected := {
		"ch2_entry": "entrance",
		"ch2_branch_a": "branch",
		"ch2_branch_b": "branch",
		"ch2_hub": "hub",
		"ch2_well": "well",
		"ch2_vault": "vault",
		"ch2_event": "event",
		"ch2_elite": "elite",
		"ch2_boss": "boss",
	}
	for room_id in expected:
		t.call(plan.room(room_id).get("type", ""), expected[room_id], "ch2_region_type_%s" % room_id)
	t.call(plan.regions_of_type("entrance").size(), 1, "ch2_one_entrance")
	t.call(plan.regions_of_type("hub").size(), 1, "ch2_one_hub")
	t.call(plan.regions_of_type("boss").size(), 1, "ch2_one_boss")
	t.call(plan.regions_of_type("branch").size(), 2, "ch2_two_branches")
	t.call(plan.regions_of_type("well").size(), 1, "ch2_one_well")

	var hub := plan.room("ch2_hub")
	t.call(bool(hub.get("rest", false)), true, "ch2_hub_has_rest")
	t.call(String(hub.get("shop", "")), "ch2_hub_shop", "ch2_hub_shop_id")
	t.call(_strings(hub.get("steles", [])), PackedStringArray(["ch2_hub/Stele1"]),
		"ch2_hub_has_stele")
	t.call(_strings(hub.get("shortcuts", [])), PackedStringArray(["hub_shortcut_entry"]),
		"ch2_hub_unlocks_shortcut")

	var vault := plan.room("ch2_vault")
	t.call(bool(vault.get("hidden", false)), true, "ch2_vault_is_hidden")
	t.call(_strings(vault.get("chests", [])).size(), 2, "ch2_vault_has_two_chests")
	t.call(_strings(vault.get("steles", [])).size(), 2, "ch2_vault_has_two_steles")
	t.call(plan.region_size("ch2_vault"), Vector2i(2560, 1440), "ch2_vault_size")

	t.call(bool(plan.room("ch2_well").get("vertical", false)), true, "ch2_well_is_vertical")
	var hidden := 0
	for entry in plan.rooms:
		if bool(entry.get("hidden", false)):
			hidden += 1
	t.call(hidden, 1, "ch2_one_hidden_region")


func _test_sizes_and_fall_planes(t: Callable) -> void:
	var plan := _plan()
	if plan == null:
		return
	var expected_sizes := {
		"ch2_entry": Vector2i(2560, 1440),
		"ch2_branch_a": Vector2i(2560, 1440),
		"ch2_branch_b": Vector2i(2560, 1440),
		"ch2_hub": Vector2i(2560, 1440),
		"ch2_well": Vector2i(2560, 2160),
		"ch2_vault": Vector2i(2560, 1440),
		"ch2_event": Vector2i(2560, 1440),
		"ch2_elite": Vector2i(3840, 2160),
		"ch2_boss": Vector2i(3840, 2160),
	}
	for room_id in expected_sizes:
		var size := plan.region_size(room_id)
		t.call(size, expected_sizes[room_id], "ch2_region_size_%s" % room_id)
		t.call(size.x % ChapterPlanData.SCREEN_SIZE.x, 0, "ch2_region_width_screens_%s" % room_id)
		t.call(size.y % ChapterPlanData.SCREEN_SIZE.y, 0, "ch2_region_height_screens_%s" % room_id)
		var screens_x := size.x / ChapterPlanData.SCREEN_SIZE.x
		var screens_y := size.y / ChapterPlanData.SCREEN_SIZE.y
		t.call(screens_x >= 1 and screens_x <= ChapterPlanData.MAX_REGION_SCREENS, true,
			"ch2_region_width_in_range_%s" % room_id)
		t.call(screens_y >= 1 and screens_y <= ChapterPlanData.MAX_REGION_SCREENS, true,
			"ch2_region_height_in_range_%s" % room_id)
		# Every region authors a fall plane below its own union; lower layers
		# (the vertical well in particular) survive a drop inside the region.
		var entry := plan.room(room_id)
		t.call(entry.has("fall_y") or entry.has("fall_below_bounds"), true,
			"ch2_region_fall_configured_%s" % room_id)
		t.call(plan.region_fall_limit(room_id), float(size.y) + 240.0,
			"ch2_region_fall_limit_%s" % room_id)
		t.call(plan.region_fall_limit(room_id) > float(size.y), true,
			"ch2_region_fall_clears_lower_layers_%s" % room_id)
	t.call(plan.fall_limit("ch2_well", 2160.0), 2400.0, "ch2_fall_uses_room_height")


func _test_content_ids(t: Callable) -> void:
	var plan := _plan()
	if plan == null:
		return
	var encounters := plan.encounter_ids()
	t.call(encounters.size(), 7, "ch2_plan_encounter_count")
	t.call(plan.clear_target(), 7, "ch2_plan_clear_target_from_encounters")
	t.call(plan.clear_target() == plan.encounter_ids().size(), true,
		"ch2_plan_clear_target_matches_encounter_ids")
	t.call(plan.clear_target() != 6, true, "ch2_plan_clear_target_not_legacy_six")
	t.call(plan.clear_target_override, 0, "ch2_plan_has_no_target_override")
	var derived := 0
	for entry in plan.rooms:
		var list: Variant = entry.get("encounters", [])
		if list is Array:
			derived += list.size()
	t.call(plan.clear_target(), derived, "ch2_plan_clear_target_derived_from_regions")

	var branch_a := _strings(plan.room("ch2_branch_a").get("encounters", []))
	t.call(branch_a, PackedStringArray(["ch2_branch_a/Arena", "ch2_branch_a/Arena2"]),
		"ch2_branch_a_has_two_encounters")
	t.call(_strings(plan.room("ch2_well").get("encounters", [])).size(), 2,
		"ch2_well_has_two_encounters")
	t.call(_strings(plan.room("ch2_event").get("encounters", [])),
		PackedStringArray(["ch2_event/event"]), "ch2_event_uses_event_encounter_id")
	t.call(plan.room("ch2_entry").get("encounters", []).is_empty(), true,
		"ch2_entry_has_no_encounter")
	t.call(plan.room("ch2_boss").get("encounters", []).is_empty(), true,
		"ch2_boss_counts_separately")

	var chests := plan.chest_ids()
	var steles := plan.stele_ids()
	t.call(chests.size(), 5, "ch2_plan_chest_count")
	t.call(steles.size(), 5, "ch2_plan_stele_count")
	_assert_unique(t, chests, "ch2_chest_ids_unique")
	_assert_unique(t, steles, "ch2_stele_ids_unique")
	_assert_unique(t, encounters, "ch2_encounter_ids_unique")
	for id in encounters:
		t.call(_anchored(id, plan), true, "ch2_encounter_id_is_node_id_%s" % id)
	for id in chests:
		t.call(_anchored(id, plan), true, "ch2_chest_id_is_node_id_%s" % id)
	for id in steles:
		t.call(_anchored(id, plan), true, "ch2_stele_id_is_node_id_%s" % id)
	# The runtime id helper and the plan agree on the node-id shape; the plan
	# never falls back to one-content-per-room.
	t.call(RoomProgress.encounter_id("ch2_branch_a", "Arena2", ""), "ch2_branch_a/Arena2",
		"ch2_plan_matches_room_progress_encounter_shape")
	t.call(RoomProgress.content_id("ch2_vault", "Chest2", ""), "ch2_vault/Chest2",
		"ch2_plan_matches_room_progress_content_shape")
	t.call(encounters.has("ch2_branch_a/Arena2"), true, "ch2_plan_keeps_second_arena_id")
	t.call(chests.has("ch2_vault/Chest2"), true, "ch2_plan_keeps_second_vault_chest")
	t.call(steles.has("ch2_vault/Stele2"), true, "ch2_plan_keeps_second_vault_stele")


func _test_graph(t: Callable) -> void:
	var plan := _plan()
	if plan == null:
		return
	var reached := plan.reachable_from("ch2_entry")
	t.call(reached.size(), 9, "ch2_graph_entry_reaches_every_region")
	for room_id in plan.room_ids():
		t.call(reached.has(room_id), true, "ch2_graph_reaches_%s" % room_id)
	t.call(reached.has("ch2_hub"), true, "ch2_graph_entry_reaches_hub")
	t.call(reached.has("ch2_vault"), true, "ch2_graph_entry_reaches_hidden_vault")
	t.call(reached.has("ch2_boss"), true, "ch2_graph_entry_reaches_boss")
	t.call(plan.reachable_from().size(), 9, "ch2_graph_default_start_is_entrance")
	t.call(plan.reachable_from("ch2_boss").size(), 1, "ch2_graph_boss_is_one_way_in")
	t.call(plan.reachable_from("ch2_vault", false).size(), 9,
		"ch2_graph_undirected_from_leaf_reaches_all")

	t.call(plan.pairs_count(), 11, "ch2_graph_has_eleven_region_pairs")
	t.call(plan.pairs_count() >= plan.rooms.size(), true, "ch2_graph_has_a_loop")
	var one_way := plan.one_way_doors()
	t.call(one_way.size(), 2, "ch2_graph_two_one_way_doors")
	var one_way_ids := PackedStringArray()
	for entry in one_way:
		one_way_ids.append(String(entry.get("id", "")))
	one_way_ids.sort()
	t.call(one_way_ids, PackedStringArray(["elite_boss", "hub_shortcut_entry"]),
		"ch2_graph_one_way_door_ids")
	var shortcut: Dictionary = plan.door("hub_shortcut_entry")
	t.call(String(shortcut.get("from", "")), "ch2_hub", "ch2_shortcut_starts_at_hub")
	t.call(_strings(shortcut.get("requires", [])), PackedStringArray(["ch2_shortcut"]),
		"ch2_shortcut_requires_flag")
	t.call(_strings(plan.door("elite_boss").get("requires", [])).is_empty(), true,
		"ch2_boss_door_needs_no_ability")
	t.call(plan.door_targets("ch2_boss").is_empty(), true, "ch2_boss_has_no_outgoing_door")
	t.call(plan.door_targets("ch2_hub").has("ch2_entry"), true,
		"ch2_shortcut_returns_to_entry")
	t.call(plan.validate_graph(), PackedStringArray(), "ch2_graph_validates_clean")


func _test_fixture_matches_plan(t: Callable) -> void:
	var plan := _plan()
	var graph := _graph()
	t.call(not graph.is_empty(), true, "ch2_graph_fixture_parses")
	if plan == null or graph.is_empty():
		return
	t.call(bool(graph.get("fixture", false)), true, "ch2_graph_fixture_is_marked_test_asset")
	t.call(String(graph.get("format", "")), "mds_world", "ch2_graph_fixture_world_format")
	t.call(String(graph.get("start_room", "")), plan.start_region(), "ch2_graph_fixture_start_room")
	var rooms: Dictionary = graph.get("rooms", {})
	t.call(rooms.size(), plan.rooms.size(), "ch2_graph_fixture_region_count")
	var graph_encounters := 0
	for room_id in plan.room_ids():
		t.call(rooms.has(room_id), true, "ch2_graph_fixture_has_%s" % room_id)
		if not rooms.has(room_id):
			continue
		var fixture_room: Dictionary = rooms[room_id]
		var plan_room := plan.room(room_id)
		t.call(String(fixture_room.get("type", "")), plan_room.get("type", ""),
			"ch2_graph_fixture_type_%s" % room_id)
		t.call(_strings(fixture_room.get("encounters", [])),
			_strings(plan_room.get("encounters", [])),
			"ch2_graph_fixture_encounters_%s" % room_id)
		t.call(_strings(fixture_room.get("chests", [])), _strings(plan_room.get("chests", [])),
			"ch2_graph_fixture_chests_%s" % room_id)
		t.call(_strings(fixture_room.get("steles", [])), _strings(plan_room.get("steles", [])),
			"ch2_graph_fixture_steles_%s" % room_id)
		t.call(_strings(fixture_room.get("shortcuts", [])),
			_strings(plan_room.get("shortcuts", [])),
			"ch2_graph_fixture_shortcuts_%s" % room_id)
		t.call(bool(fixture_room.get("hidden", false)), bool(plan_room.get("hidden", false)),
			"ch2_graph_fixture_hidden_%s" % room_id)
		var encounters: Variant = fixture_room.get("encounters", [])
		if encounters is Array:
			graph_encounters += encounters.size()
	# The clear target is derived from the graph's clearing encounters, not the
	# legacy six-room rule and not one-per-room.
	t.call(graph_encounters, 7, "ch2_graph_declares_seven_encounters")
	t.call(plan.clear_target(), graph_encounters, "ch2_plan_clear_target_matches_graph_encounters")

	var gates := _gates(graph)
	var outgoing := 0
	for key in gates:
		var gate: Dictionary = gates[key]
		var room_id := String(key).get_slice("/", 0)
		var gate_name := String(key).get_slice("/", 1)
		if gate.has("to"):
			outgoing += 1
			var door := _door_for_fixture_gate(plan, room_id, gate_name)
			t.call(not door.is_empty(), true, "ch2_graph_fixture_gate_declared_%s" % key)
			if door.is_empty():
				continue
			var forward := String(door.get("from", "")) == room_id \
				and String(door.get("from_gate", "")) == gate_name
			if forward:
				t.call(String(door.get("to", "")), String(gate.get("to", "")),
					"ch2_graph_fixture_gate_target_%s" % key)
				t.call(String(door.get("to_gate", "")), String(gate.get("to_gate", "")),
					"ch2_graph_fixture_gate_arrival_%s" % key)
				t.call(bool(door.get("one_way", false)), bool(gate.get("one_way", false)),
					"ch2_graph_fixture_gate_one_way_%s" % key)
			else:
				# The reverse side of a two-way door is derived, not authored as
				# a second plan entry.
				t.call(String(door.get("from", "")), String(gate.get("to", "")),
					"ch2_graph_fixture_gate_reverse_target_%s" % key)
				t.call(String(door.get("from_gate", "")), String(gate.get("to_gate", "")),
					"ch2_graph_fixture_gate_reverse_arrival_%s" % key)
				t.call(bool(door.get("one_way", false)), false,
					"ch2_graph_fixture_reverse_is_two_way_%s" % key)
			t.call(_strings(door.get("requires", [])),
				_strings(gate.get("requires", [])), "ch2_graph_fixture_gate_requires_%s" % key)
		else:
			var arrival := _door_by_arrival(plan, room_id, gate_name)
			t.call(not arrival.is_empty(), true, "ch2_graph_fixture_dead_end_declared_%s" % key)
	t.call(outgoing, 20, "ch2_graph_fixture_outgoing_gate_count")

	for entry in plan.doors:
		var door_id := String(entry.get("id", ""))
		var from := String(entry.get("from", ""))
		var to := String(entry.get("to", ""))
		var from_key := "%s/%s" % [from, String(entry.get("from_gate", ""))]
		var to_key := "%s/%s" % [to, String(entry.get("to_gate", ""))]
		t.call(gates.has(from_key), true, "ch2_door_%s_has_from_gate" % door_id)
		t.call(gates.has(to_key), true, "ch2_door_%s_has_arrival_gate" % door_id)
		if not gates.has(from_key) or not gates.has(to_key):
			continue
		var from_gate: Dictionary = gates[from_key]
		var to_gate: Dictionary = gates[to_key]
		t.call(String(from_gate.get("to", "")), to, "ch2_door_%s_target" % door_id)
		t.call(String(from_gate.get("to_gate", "")), String(entry.get("to_gate", "")),
			"ch2_door_%s_arrival_name" % door_id)
		if bool(entry.get("one_way", false)):
			t.call(to_gate.has("to"), false, "ch2_door_%s_one_way_has_no_return" % door_id)
		else:
			t.call(String(to_gate.get("to", "")), from, "ch2_door_%s_returns" % door_id)
			t.call(String(to_gate.get("to_gate", "")), String(entry.get("from_gate", "")),
				"ch2_door_%s_returns_to_gate" % door_id)
		t.call(_strings(from_gate.get("requires", [])), _strings(entry.get("requires", [])),
			"ch2_door_%s_requires" % door_id)

	var fixture_reached := _fixture_reachable(graph, plan.start_region())
	t.call(fixture_reached.size(), rooms.size(), "ch2_graph_fixture_all_regions_reachable")
	for room_id in rooms:
		t.call(fixture_reached.has(String(room_id)), true,
			"ch2_graph_fixture_reaches_%s" % room_id)


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
			"ch2_graph_fixture_bounds_%s" % id)
		var origin: Array = room.get("origin", [])
		t.call(origin.size(), 2, "ch2_graph_fixture_origin_%s" % id)
		if origin.size() == 2:
			t.call(int(origin[0]) % 32, 0, "ch2_graph_fixture_origin_x_grid_%s" % id)
			t.call(int(origin[1]) % 32, 0, "ch2_graph_fixture_origin_y_grid_%s" % id)
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a := _room_world_rect(graph, String(ids[i]))
			var b := _room_world_rect(graph, String(ids[j]))
			t.call(a.intersects(b, false), false,
				"ch2_graph_fixture_no_overlap_%s_%s" % [String(ids[i]), String(ids[j])])

	for entry in plan.doors:
		var door_id := String(entry.get("id", ""))
		var from := _room_world_rect(graph, String(entry.get("from", "")))
		var to := _room_world_rect(graph, String(entry.get("to", "")))
		var shortcut := bool(entry.get("one_way", false)) \
			and not _strings(entry.get("requires", [])).is_empty()
		if shortcut:
			# A shortcut door is a deliberate teleport link between non-touching
			# regions; it still arrives through a named gate.
			t.call(_touching(from, to), false, "ch2_door_%s_shortcut_is_not_adjacent" % door_id)
		else:
			t.call(_touching(from, to), true, "ch2_door_%s_regions_touch" % door_id)

	var gates := _gates(graph)
	for key in gates:
		var id := String(key)
		var room_id := id.get_slice("/", 0)
		var gate: Dictionary = gates[key]
		var local := _room_local_rect(graph, room_id)
		var pos_value: Array = gate.get("pos", [])
		t.call(pos_value.size(), 2, "ch2_graph_fixture_gate_pos_%s" % id)
		if pos_value.size() != 2:
			continue
		var pos := Vector2(float(pos_value[0]), float(pos_value[1]))
		var side := String(gate.get("side", ""))
		t.call(MDSWorld.SIDES.has(side), true, "ch2_graph_fixture_gate_side_%s" % id)
		t.call(pos.x >= 0.0 and pos.x <= local.size.x and pos.y >= 0.0 and pos.y <= local.size.y,
			true, "ch2_graph_fixture_gate_inside_%s" % id)
		match side:
			"left":
				t.call(pos.x <= 16.0, true, "ch2_graph_fixture_gate_on_left_%s" % id)
			"right":
				t.call(pos.x >= local.size.x - 16.0, true, "ch2_graph_fixture_gate_on_right_%s" % id)
			"top":
				t.call(pos.y <= 16.0, true, "ch2_graph_fixture_gate_on_top_%s" % id)
			"bot":
				t.call(pos.y >= local.size.y - 16.0, true, "ch2_graph_fixture_gate_on_bot_%s" % id)
			"door":
				t.call(pos.x >= 8.0 and pos.x <= local.size.x - 8.0
					and pos.y >= 8.0 and pos.y <= local.size.y - 8.0, true,
					"ch2_graph_fixture_door_inside_%s" % id)
		t.call(plan.fall_limit(room_id, local.size.y) > local.size.y, true,
			"ch2_graph_fixture_fall_covers_%s" % room_id)


func _test_validation_catches_bad_plans(t: Callable) -> void:
	# An isolated region must fail reachability.
	var orphan := ChapterPlanData.new()
	orphan.big_map = true
	orphan.start_room = "a"
	orphan.rooms.append(_region("a", "entrance"))
	orphan.rooms.append(_region("b", "branch", ["b/Arena"]))
	t.call(_joined(orphan.validate_graph()).contains("unreachable from a"), true,
		"ch2_validation_flags_orphan_region")

	# Bad size and a missing fall plane are caught per region.
	var bad_size := ChapterPlanData.new()
	bad_size.big_map = true
	var bad_room := _region("a", "entrance")
	bad_room["size"] = [6400, 1440]
	bad_room.erase("fall_below_bounds")
	bad_size.rooms.append(bad_room)
	var size_errors := _joined(bad_size.validate_regions())
	t.call(size_errors.contains("screens"), true, "ch2_validation_flags_bad_size")
	t.call(size_errors.contains("fall_y or fall_below_bounds"), true,
		"ch2_validation_flags_missing_fall_plane")

	var shallow := ChapterPlanData.new()
	shallow.big_map = true
	var shallow_room := _region("a", "entrance")
	shallow_room.erase("fall_below_bounds")
	shallow_room["fall_y"] = 100
	shallow.rooms.append(shallow_room)
	t.call(_joined(shallow.validate_regions()).contains("does not clear"), true,
		"ch2_validation_flags_shallow_fall_plane")

	# Big-map regions must declare their clearing encounters, even when empty;
	# otherwise the derived clear target silently falls back to room types.
	var no_list := ChapterPlanData.new()
	no_list.big_map = true
	var no_list_room := _region("a", "entrance")
	no_list_room.erase("encounters")
	no_list.rooms.append(no_list_room)
	t.call(_joined(no_list.validate_regions()).contains("needs an encounters list"), true,
		"ch2_validation_flags_missing_encounter_list")

	# Content ids must stay unique and anchored to their region (node-id rule,
	# not one settlement per room).
	var dup := ChapterPlanData.new()
	dup.big_map = true
	var first := _region("a", "entrance")
	first["chests"] = ["a/Chest1"]
	dup.rooms.append(first)
	var second := _region("b", "branch")
	second["chests"] = ["a/Chest1", "loose_chest"]
	dup.rooms.append(second)
	var dup_errors := _joined(dup.validate_regions())
	t.call(dup_errors.contains("duplicate chest id a/Chest1"), true,
		"ch2_validation_flags_duplicate_chest_id")
	t.call(dup_errors.contains("must be a node id"), true,
		"ch2_validation_flags_unanchored_content_id")

	# Dangling doors, reused gates and duplicate pairs are graph errors.
	var bad_graph := ChapterPlanData.new()
	bad_graph.big_map = true
	bad_graph.start_room = "a"
	bad_graph.rooms.append(_region("a", "entrance"))
	bad_graph.rooms.append(_region("b", "branch"))
	bad_graph.doors.append(_door("d1", "a", "missing", "right1", "left1"))
	bad_graph.doors.append(_door("d2", "a", "b", "right1", "left1"))
	bad_graph.doors.append(_door("d3", "a", "b", "right1", "left1"))
	var graph_errors := _joined(bad_graph.validate_graph())
	t.call(graph_errors.contains("unknown region missing"), true,
		"ch2_validation_flags_unknown_region")
	t.call(graph_errors.contains("used by doors"), true,
		"ch2_validation_flags_reused_gate")
	t.call(graph_errors.contains("more than one door between"), true,
		"ch2_validation_flags_duplicate_pair")

	var bad_shortcut := ChapterPlanData.new()
	bad_shortcut.big_map = true
	bad_shortcut.start_room = "a"
	var hub_room := _region("a", "entrance")
	hub_room["shortcuts"] = ["d1"]
	bad_shortcut.rooms.append(hub_room)
	bad_shortcut.rooms.append(_region("b", "branch"))
	bad_shortcut.doors.append(_door("d1", "a", "b", "right1", "left1"))
	t.call(_joined(bad_shortcut.validate_graph()).contains("shortcut d1 needs a requires entry"),
		true, "ch2_validation_flags_shortcut_without_requirement")


func _test_chapter_one_unchanged(t: Callable) -> void:
	var plan := load(CH1_PLAN_PATH) as ChapterPlanData
	t.call(plan != null, true, "ch1_plan_still_loads_alongside_ch2")
	if plan == null:
		return
	t.call(plan.big_map, false, "ch1_plan_still_linear")
	t.call(plan.rooms.size(), 9, "ch1_plan_still_nine_rooms")
	t.call(plan.clear_target(), 6, "ch1_plan_clear_target_still_six")
	t.call(plan.doors.is_empty(), true, "ch1_plan_has_no_graph")
	t.call(plan.start_region(), "", "ch1_plan_has_no_start_region")
	t.call(plan.validate(), PackedStringArray(), "ch1_plan_validates_clean")
	t.call(plan.region_size("ch1_01"), Vector2i.ZERO, "ch1_plan_has_no_region_sizes")
	t.call(plan.encounter_ids().is_empty(), true, "ch1_plan_has_no_encounter_lists")


func _plan() -> ChapterPlanData:
	return load(PLAN_PATH) as ChapterPlanData


func _graph() -> Dictionary:
	var text := FileAccess.get_file_as_string(GRAPH_PATH)
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


func _region(room_id: String, type: String, encounters: Array = []) -> Dictionary:
	return {
		"id": room_id,
		"type": type,
		"size": [2560, 1440],
		"encounters": encounters,
		"chests": [],
		"steles": [],
		"shortcuts": [],
		"fall_below_bounds": 240,
	}


func _door(door_id: String, from: String, to: String, from_gate: String, to_gate: String) -> Dictionary:
	return {
		"id": door_id,
		"from": from,
		"to": to,
		"from_gate": from_gate,
		"to_gate": to_gate,
		"one_way": false,
	}


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


func _joined(errors: PackedStringArray) -> String:
	return "\n".join(errors)
