extends RefCounted

## Chapter 3 big-map world: the real nine-region world and its room scenes.
## Pass 80 points game.gd at this world together with the Chapter 3 plan, while
## the old linear Chapter 3 world stays on disk. The fixture under tests/fixtures
## is a test-only mirror and is never loaded. Vision compression (status #14),
## the big-map sea motif (status #15) and the ch3_shortcut grant (status #16)
## stay unauthored.

const WORLD_PATH := "res://scenes/mds/chapter_3_bigmap.mdsworld.json"
const WORLD_SCENE_PATH := "res://scenes/mds/chapter_3_bigmap_world.tscn"
const REGION_DIR := "res://scenes/mds/ch3_bigmap"
const ROOM_DATA_DIR := "res://resources/rooms/ch3_bigmap"
const FIXTURE_PATH := "res://tests/fixtures/big_room/ch3_graph.mdsworld.json"
const PLAN_PATH := "res://resources/chapters/chapter_3_demo.tres"
const CH1_PLAN_PATH := "res://resources/chapters/chapter_1_demo.tres"
const CH2_PLAN_PATH := "res://resources/chapters/chapter_2_demo.tres"
const CH2_WORLD_PATH := "res://scenes/mds/chapter_2_bigmap.mdsworld.json"
const OLD_CH3_WORLD_PATH := "res://scenes/mds/chapter_3.mdsworld.json"
const OLD_CH3_SCENE_PATH := "res://scenes/mds/chapter_3_world.tscn"
const GAME_SCRIPT_PATH := "res://scripts/game.gd"
const TILES_PATH := "res://resources/tiles/ch3_tiles.tres"
const BACKDROP_PATH := "res://assets/backgrounds/lightless_sea.png"
const FALL_MARGIN := 240.0
## MovingPlatform.speed default in scripts/levels/moving_platform.gd. Chapter 3
## authors no speed override, so the pipeline default (80 px/s) is the value.
const MOVING_PLATFORM_DEFAULT_SPEED := 80.0
const REGION_IDS: PackedStringArray = [
	"ch3_entry", "ch3_branch_a", "ch3_branch_b", "ch3_hub", "ch3_well",
	"ch3_vault", "ch3_event", "ch3_elite", "ch3_boss",
]


func run(t: Callable) -> void:
	_test_world_matches_plan(t)
	_test_world_geometry(t)
	_test_region_scenes(t)
	_test_region_content(t)
	_test_vertical_props(t)
	_test_fixture_mirror(t)
	_test_game_wiring(t)
	_test_old_worlds_kept(t)


func _test_world_matches_plan(t: Callable) -> void:
	var plan := _plan()
	var world := _world()
	t.call(not world.is_empty(), true, "ch3_world_parses")
	t.call(plan != null, true, "ch3_world_plan_loads")
	if plan == null or world.is_empty():
		return
	t.call(String(world.get("format", "")), "mds_world", "ch3_world_format")
	t.call(int(world.get("version", 0)), 1, "ch3_world_version")
	t.call(world.has("fixture"), false, "ch3_world_is_not_a_test_fixture")
	t.call(String(world.get("name", "")), "Changzi Chapter 3 Big Map", "ch3_world_name")
	t.call(String(world.get("start_room", "")), plan.start_region(), "ch3_world_start_room")
	t.call(String(world.get("start_room", "")), "ch3_entry", "ch3_world_start_is_entry")

	var rooms: Dictionary = world.get("rooms", {})
	t.call(rooms.size(), 9, "ch3_world_nine_regions")
	t.call(_room_keys(rooms), _sorted(plan.room_ids()), "ch3_world_region_ids_match_plan")
	var areas: Dictionary = world.get("areas", {})
	t.call(areas.has("Lightless Sea"), true, "ch3_world_lightless_sea_area")
	if areas.has("Lightless Sea"):
		var area: Dictionary = areas["Lightless Sea"]
		t.call(String(area.get("weather", "")).contains("fog"), true, "ch3_world_area_fog")
		t.call(String(area.get("weather", "")).contains("rain"), true, "ch3_world_area_rain")
		t.call(String(area.get("boss_background", "")), "deep_water",
			"ch3_world_boss_background")
		# Status #15: the sea motif lives only in the old LivingBackdrop rooms.
		# The big-map world uses the pipeline's tiled static backdrop + ambient,
		# so the area authors no backdrop_image and no sea layer.
		t.call(area.has("backdrop_image"), false, "ch3_world_area_has_no_backdrop_decision")
		t.call(area.has("sea"), false, "ch3_world_area_has_no_sea_layer")

	for room_id in REGION_IDS:
		t.call(rooms.has(room_id), true, "ch3_world_has_region_%s" % room_id)
		if not rooms.has(room_id):
			continue
		var room: Dictionary = rooms[room_id]
		var plan_room := plan.room(room_id)
		t.call(String(room.get("scene_path", "")), "%s/%s.tscn" % [REGION_DIR, room_id],
			"ch3_world_scene_path_%s" % room_id)
		t.call(ResourceLoader.exists(String(room.get("scene_path", ""))), true,
			"ch3_world_scene_exists_%s" % room_id)
		t.call(String(room.get("type", "")), String(plan_room.get("type", "")),
			"ch3_world_type_%s" % room_id)
		t.call(_sorted(_strings(room.get("encounters", []))),
			_sorted(_strings(plan_room.get("encounters", []))),
			"ch3_world_encounters_%s" % room_id)
		t.call(_sorted(_strings(room.get("chests", []))),
			_sorted(_strings(plan_room.get("chests", []))), "ch3_world_chests_%s" % room_id)
		t.call(_sorted(_strings(room.get("steles", []))),
			_sorted(_strings(plan_room.get("steles", []))), "ch3_world_steles_%s" % room_id)
		t.call(_sorted(_strings(room.get("shortcuts", []))),
			_sorted(_strings(plan_room.get("shortcuts", []))),
			"ch3_world_shortcuts_%s" % room_id)
		t.call(bool(room.get("hidden", false)), bool(plan_room.get("hidden", false)),
			"ch3_world_hidden_%s" % room_id)
		t.call(String(room.get("shop", "")), String(plan_room.get("shop", "")),
			"ch3_world_shop_%s" % room_id)
		t.call(bool(room.get("rest", false)), bool(plan_room.get("rest", false)),
			"ch3_world_rest_%s" % room_id)
		t.call(bool(room.get("vertical", false)), bool(plan_room.get("vertical", false)),
			"ch3_world_vertical_%s" % room_id)
		t.call(String(room.get("area", "")), "Lightless Sea", "ch3_world_area_%s" % room_id)

	# The authored encounters are exactly the plan's clear target (7), all of
	# them anchored as region/Node ids.
	var world_encounters := 0
	for room_id in REGION_IDS:
		var list: Variant = rooms[room_id].get("encounters", [])
		if list is Array:
			world_encounters += (list as Array).size()
	t.call(world_encounters, plan.clear_target(), "ch3_world_clear_target_matches_encounters")
	t.call(world_encounters, 7, "ch3_world_seven_encounters")

	# Every plan door is a real world gate; two-way doors are mirrored.
	var outgoing := 0
	var dead_ends := 0
	for room_id in REGION_IDS:
		var gates: Dictionary = rooms[room_id].get("gates", {})
		for gate_name in gates:
			var gate: Dictionary = gates[gate_name]
			if gate.has("to"):
				outgoing += 1
			else:
				dead_ends += 1
	t.call(outgoing, 20, "ch3_world_twenty_outgoing_gates")
	t.call(dead_ends, 2, "ch3_world_two_arrival_only_gates")
	for entry in plan.doors:
		var door_id := String(entry.get("id", ""))
		var from := String(entry.get("from", ""))
		var to := String(entry.get("to", ""))
		var from_gate_name := String(entry.get("from_gate", ""))
		var to_gate_name := String(entry.get("to_gate", ""))
		var from_gate := _gate(world, from, from_gate_name)
		var to_gate := _gate(world, to, to_gate_name)
		t.call(not from_gate.is_empty(), true, "ch3_world_door_%s_from_gate" % door_id)
		t.call(not to_gate.is_empty(), true, "ch3_world_door_%s_arrival_gate" % door_id)
		if from_gate.is_empty() or to_gate.is_empty():
			continue
		t.call(String(from_gate.get("to", "")), to, "ch3_world_door_%s_target" % door_id)
		t.call(String(from_gate.get("to_gate", "")), to_gate_name,
			"ch3_world_door_%s_arrival" % door_id)
		t.call(_sorted(_strings(from_gate.get("requires", []))),
			_sorted(_strings(entry.get("requires", []))), "ch3_world_door_%s_requires" % door_id)
		if bool(entry.get("one_way", false)):
			t.call(to_gate.has("to"), false, "ch3_world_one_way_%s_dead_end" % door_id)
		else:
			t.call(bool(from_gate.get("one_way", false)), false,
				"ch3_world_two_way_%s_not_flagged" % door_id)
			t.call(String(to_gate.get("to", "")), from, "ch3_world_door_%s_returns" % door_id)
			t.call(String(to_gate.get("to_gate", "")), from_gate_name,
				"ch3_world_door_%s_returns_to_gate" % door_id)

	# Status #16: the shortcut barrier stays closed; no authored grant exists.
	var shortcut_gate := _gate(world, "ch3_hub", "shortcut")
	t.call(_strings(shortcut_gate.get("requires", [])), PackedStringArray(["ch3_shortcut"]),
		"ch3_world_shortcut_requires_ability")
	t.call(bool(shortcut_gate.get("one_way", false)), true, "ch3_world_shortcut_is_one_way")
	t.call(String(shortcut_gate.get("side", "")), "door", "ch3_world_shortcut_is_a_door")

	# Reachability over the real world graph, not the fixture.
	var reached := _reachable(world, String(world.get("start_room", "")))
	t.call(reached.size(), 9, "ch3_world_graph_reaches_every_region")
	for room_id in REGION_IDS:
		t.call(reached.has(room_id), true, "ch3_world_graph_reaches_%s" % room_id)
	t.call(reached.has("ch3_hub"), true, "ch3_world_graph_reaches_hub")
	t.call(reached.has("ch3_vault"), true, "ch3_world_graph_reaches_hidden_vault")
	t.call(reached.has("ch3_boss"), true, "ch3_world_graph_reaches_boss")


func _test_world_geometry(t: Callable) -> void:
	var world := _world()
	if world.is_empty():
		return
	var rooms: Dictionary = world.get("rooms", {})
	for room_id in REGION_IDS:
		var room: Dictionary = rooms[room_id]
		var rects: Array = room.get("rects", [])
		t.call(rects.size(), 1, "ch3_world_single_rect_%s" % room_id)
		if rects.size() == 1:
			var rect: Array = rects[0]
			t.call(_rect(rect).position, Vector2.ZERO, "ch3_world_local_origin_%s" % room_id)
		var origin: Array = room.get("origin", [])
		t.call(origin.size(), 2, "ch3_world_origin_%s" % room_id)
		if origin.size() == 2:
			t.call(int(origin[0]) % 32, 0, "ch3_world_origin_grid_x_%s" % room_id)
			t.call(int(origin[1]) % 32, 0, "ch3_world_origin_grid_y_%s" % room_id)
		# Gates sit on their named edge (16 px tolerance) and inside the room.
		var bounds := _world_rect(world, room_id)
		var gates: Dictionary = room.get("gates", {})
		for gate_name in gates:
			var gate: Dictionary = gates[gate_name]
			var pos_value: Array = gate.get("pos", [])
			t.call(pos_value.size(), 2, "ch3_world_gate_pos_%s/%s" % [room_id, gate_name])
			if pos_value.size() != 2:
				continue
			var pos := Vector2(float(pos_value[0]), float(pos_value[1]))
			var local := pos
			t.call(local.x >= 0.0 and local.x <= bounds.size.x
				and local.y >= 0.0 and local.y <= bounds.size.y, true,
				"ch3_world_gate_inside_%s/%s" % [room_id, gate_name])
			var side := String(gate.get("side", ""))
			t.call(MDSWorld.SIDES.has(side), true,
				"ch3_world_gate_side_%s/%s" % [room_id, gate_name])
			match side:
				"left":
					t.call(local.x <= 16.0, true, "ch3_world_gate_left_%s" % gate_name)
				"right":
					t.call(local.x >= bounds.size.x - 16.0, true,
						"ch3_world_gate_right_%s" % gate_name)
				"top":
					t.call(local.y <= 16.0, true, "ch3_world_gate_top_%s" % gate_name)
				"bot":
					t.call(local.y >= bounds.size.y - 16.0, true,
						"ch3_world_gate_bot_%s" % gate_name)
				"door":
					t.call(local.x >= 8.0 and local.x <= bounds.size.x - 8.0
						and local.y >= 8.0 and local.y <= bounds.size.y - 8.0, true,
						"ch3_world_gate_door_inside_%s" % gate_name)

	for i in REGION_IDS.size():
		for j in range(i + 1, REGION_IDS.size()):
			var a := _world_rect(world, REGION_IDS[i])
			var b := _world_rect(world, REGION_IDS[j])
			t.call(a.intersects(b, false), false,
				"ch3_world_no_overlap_%s_%s" % [REGION_IDS[i], REGION_IDS[j]])

	var plan := _plan()
	if plan == null:
		return
	for entry in plan.doors:
		var door_id := String(entry.get("id", ""))
		var from := _world_rect(world, String(entry.get("from", "")))
		var to := _world_rect(world, String(entry.get("to", "")))
		var shortcut := bool(entry.get("one_way", false)) \
			and not _strings(entry.get("requires", [])).is_empty()
		if shortcut:
			# The hub shortcut is a deliberate teleport between non-touching
			# regions; it still arrives through a named gate.
			t.call(_touching(from, to), false, "ch3_world_shortcut_not_adjacent_%s" % door_id)
		else:
			t.call(_touching(from, to), true, "ch3_world_door_regions_touch_%s" % door_id)


func _test_region_scenes(t: Callable) -> void:
	var plan := _plan()
	var world := _world()
	if plan == null or world.is_empty():
		return
	for room_id in REGION_IDS:
		var scene_path := "%s/%s.tscn" % [REGION_DIR, room_id]
		var packed := load(scene_path) as PackedScene
		t.call(packed != null, true, "ch3_region_packs_%s" % room_id)
		if packed == null:
			continue
		var node := packed.instantiate()
		var big := node as MDSBigRoom
		t.call(big != null, true, "ch3_region_uses_big_room_pipeline_%s" % room_id)
		t.call(node is MDSChapterRoom, false, "ch3_region_is_not_legacy_room_%s" % room_id)
		if big == null:
			node.free()
			continue
		t.call(big.data != null, true, "ch3_region_has_room_data_%s" % room_id)
		if big.data != null:
			t.call(big.data.resource_path, "%s/%s.tres" % [ROOM_DATA_DIR, room_id],
				"ch3_region_data_path_%s" % room_id)
			t.call(big.data.size, plan.region_size(room_id), "ch3_region_data_size_%s" % room_id)
			var rect := Rect2(Vector2.ZERO,
				Vector2(float(plan.region_size(room_id).x), float(plan.region_size(room_id).y)))
			t.call(big.data.validate(rect), PackedStringArray(),
				"ch3_region_geometry_valid_%s" % room_id)
			t.call(big.data.tile_set != null and big.data.tile_set.resource_path == TILES_PATH,
				true, "ch3_region_tiles_%s" % room_id)
			t.call(big.data.backdrop_path, BACKDROP_PATH, "ch3_region_backdrop_%s" % room_id)
			t.call(big.data.backdrop_pixel_art, false, "ch3_region_backdrop_scaled_%s" % room_id)
			t.call(String(big.data.ambient_kind), "motes", "ch3_region_ambient_%s" % room_id)
			t.call(is_equal_approx(big.data.ambient_density, 0.5), true,
				"ch3_region_ambient_density_%s" % room_id)
			var grounded := false
			for ground in big.data.ground:
				if float(ground.get("y", 0.0)) + float(ground.get("height", 0.0)) \
						>= float(plan.region_size(room_id).y) - 8.0:
					grounded = true
			t.call(grounded, true, "ch3_region_has_bottom_ground_%s" % room_id)
		t.call(is_equal_approx(big.fall_margin, FALL_MARGIN), true,
			"ch3_region_fall_margin_%s" % room_id)
		node.free()


func _test_region_content(t: Callable) -> void:
	var plan := _plan()
	if plan == null:
		return
	for room_id in REGION_IDS:
		var node := _instantiate(room_id)
		if node == null:
			continue
		var plan_room := plan.room(room_id)
		var arenas: Array[ArenaRoom] = []
		for child in node.get_children():
			if child is ArenaRoom:
				arenas.append(child)
		var chests := 0
		var steles := 0
		for child in node.get_children():
			if child is TreasureChest:
				chests += 1
			elif child is MemoryStele:
				steles += 1
		var encounters := _strings(plan_room.get("encounters", []))
		var plan_chests := _strings(plan_room.get("chests", []))
		var plan_steles := _strings(plan_room.get("steles", []))
		# The boss region authors one structural Arena for the boss fight; it is
		# not an ordinary encounter and the plan lists none there.
		var expected_arenas := encounters.size() if room_id != "ch3_boss" else 1
		t.call(arenas.size(), expected_arenas, "ch3_region_arena_count_%s" % room_id)
		t.call(chests, plan_chests.size(), "ch3_region_chest_count_%s" % room_id)
		t.call(steles, plan_steles.size(), "ch3_region_stele_count_%s" % room_id)

		for encounter_id in encounters:
			var arena_name := String(encounter_id).get_slice("/", 1)
			var arena := node.get_node_or_null(NodePath(arena_name))
			if arena == null and not arena_name.is_empty():
				# Authored ids may be lower-case (`ch3_event/event`) while the
				# scene keeps the project's PascalCase node naming.
				arena_name = arena_name.substr(0, 1).to_upper() + arena_name.substr(1)
				arena = node.get_node_or_null(NodePath(arena_name))
			t.call(arena is ArenaRoom, true,
				"ch3_region_encounter_node_%s/%s" % [room_id, arena_name])
			if arena is ArenaRoom and room_id == "ch3_event":
				t.call(arena.encounter_id, &"ch3_event/event",
					"ch3_region_event_authors_encounter_id")
		for chest_id in plan_chests:
			var chest_name := String(chest_id).get_slice("/", 1)
			t.call(node.get_node_or_null(NodePath(chest_name)) is TreasureChest, true,
				"ch3_region_chest_node_%s/%s" % [room_id, chest_name])
		for stele_id in plan_steles:
			var stele_name := String(stele_id).get_slice("/", 1)
			t.call(node.get_node_or_null(NodePath(stele_name)) is MemoryStele, true,
				"ch3_region_stele_node_%s/%s" % [room_id, stele_name])
		if room_id == "ch3_hub":
			var shop := node.get_node_or_null("Shop") as MemoryShop
			t.call(shop != null, true, "ch3_region_hub_shop")
			if shop != null:
				t.call(shop.shop_id, &"ch3_hub_shop", "ch3_region_hub_shop_id")
			t.call(node.get_node_or_null("Bench") is BenchCheckpoint, true,
				"ch3_region_hub_bench")
		if room_id == "ch3_boss":
			t.call(node.get_node_or_null("Arena") is ArenaRoom, true,
				"ch3_region_boss_has_structural_arena")
		if room_id == "ch3_entry":
			var arrival := MDSGate.find_gate(node, "shortcut_arrival")
			t.call(arrival != null, true, "ch3_region_entry_authored_arrival_gate")
			if arrival != null:
				t.call(arrival.mode, MDSGate.Mode.TOUCH,
					"ch3_region_entry_arrival_is_inert")
			# A fresh Chapter 3 run starts on the first step, not at the room
			# label anchor (the centre of the largest rect, which is mid-air).
			var entry := node as MDSBigRoom
			var spawn := node.get_node_or_null("SpawnPoint") as Marker2D
			t.call(spawn != null, true, "ch3_region_entry_spawn_point")
			if spawn != null:
				t.call(spawn.is_in_group(&"save_point"), true,
					"ch3_region_entry_spawn_is_save_point")
				if entry != null and entry.data != null \
						and not entry.data.platforms.is_empty():
					var step_y := float(entry.data.platforms[0].get("y", 0.0)) - Player.FOOT_Y
					t.call(is_equal_approx(spawn.position.y, step_y), true,
						"ch3_region_entry_spawn_stands_on_step")
		node.free()


func _test_vertical_props(t: Callable) -> void:
	var world := _world()
	if world.is_empty():
		return
	for room_id in REGION_IDS:
		var node := _instantiate(room_id)
		if node == null:
			continue
		var big := node as MDSBigRoom
		var lifts: Array = []
		var one_ways := 0
		for child in node.get_children():
			if child is MovingPlatform:
				lifts.append(child)
			elif child is OneWayPlatform:
				one_ways += 1
		if room_id == "ch3_well":
			t.call(one_ways, 3, "ch3_region_well_three_one_way_platforms")
			t.call(lifts.size() >= 1, true, "ch3_region_well_has_lift")
		for lift in lifts:
			# Chapter 3 authors no chapter-specific elevator speed; the pipeline
			# default (80 px/s) applies and is recorded here, not retuned.
			t.call(is_equal_approx(lift.speed, MOVING_PLATFORM_DEFAULT_SPEED), true,
				"ch3_region_lift_uses_pipeline_default_speed_%s" % room_id)
		var top_x := _top_gate_x(world, room_id)
		if top_x >= 0.0:
			# A top gate is reached with the authored elevator; its vertical
			# route column stays clear of platform slabs (BigRoomData has no
			# ladders or extra movement abilities).
			var lift: MovingPlatform = null
			for candidate in lifts:
				if candidate.position.x <= top_x and top_x <= candidate.position.x + candidate.size.x:
					lift = candidate
					break
			t.call(lift != null, true, "ch3_region_top_gate_has_lift_%s" % room_id)
			if lift != null and big != null and big.data != null:
				t.call(lift.travel.y < 0.0, true, "ch3_region_lift_travels_up_%s" % room_id)
				t.call(lift.position.y + lift.travel.y <= 120.0, true,
					"ch3_region_lift_reaches_top_%s" % room_id)
				var left := lift.position.x
				var right := lift.position.x + lift.size.x
				var blocked := false
				for platform in big.data.platforms:
					var p_left := float(platform.get("x", 0.0))
					var p_right := p_left + float(platform.get("width", 0.0))
					if minf(right, p_right) - maxf(left, p_left) > 0.0:
						blocked = true
				t.call(blocked, false, "ch3_region_lift_column_clear_%s" % room_id)
		node.free()


func _test_fixture_mirror(t: Callable) -> void:
	var fixture := _parse(FIXTURE_PATH)
	var world := _world()
	var plan := _plan()
	t.call(not fixture.is_empty(), true, "ch3_fixture_parses")
	if fixture.is_empty() or world.is_empty() or plan == null:
		return
	t.call(bool(fixture.get("fixture", false)), true, "ch3_fixture_is_marked_test_only")
	t.call(bool(fixture.get("content_pending", false)), true,
		"ch3_fixture_marks_pending_content")
	t.call(String(fixture.get("note", "")).contains("TEST FIXTURE ONLY"), true,
		"ch3_fixture_has_test_note")
	t.call(String(fixture.get("format", "")), "mds_world", "ch3_fixture_world_format")
	t.call(String(fixture.get("start_room", "")), plan.start_region(), "ch3_fixture_start_room")

	var fixture_rooms: Dictionary = fixture.get("rooms", {})
	var world_rooms: Dictionary = world.get("rooms", {})
	t.call(fixture_rooms.size(), 9, "ch3_fixture_nine_regions")
	for room_id in REGION_IDS:
		t.call(fixture_rooms.has(room_id), true, "ch3_fixture_has_region_%s" % room_id)
		if not fixture_rooms.has(room_id) or not world_rooms.has(room_id):
			continue
		var fixture_room: Dictionary = fixture_rooms[room_id]
		t.call(fixture_room.has("scene_path"), false,
			"ch3_fixture_region_has_no_scene_%s" % room_id)
		var mirror := fixture_room.duplicate()
		mirror.erase("scene_path")
		var real: Dictionary = world_rooms[room_id].duplicate()
		real.erase("scene_path")
		t.call(mirror, real, "ch3_fixture_matches_real_world_%s" % room_id)
	t.call(fixture.get("areas"), world.get("areas"), "ch3_fixture_matches_world_areas")

	# Nothing in the runtime may point at the fixture or the unwired world.
	var game_source := FileAccess.get_file_as_string(GAME_SCRIPT_PATH)
	t.call(game_source.contains("ch3_graph"), false, "ch3_fixture_not_wired_in_game")
	t.call(game_source.contains("tests/fixtures"), false, "ch3_game_never_loads_test_fixtures")


func _test_game_wiring(t: Callable) -> void:
	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	t.call(game_script != null, true, "ch3_world_game_script_loads")
	if game_script == null:
		return
	var constants: Dictionary = game_script.get_script_constant_map()
	var world_files: Array = constants.get("MDS_WORLD_FILES", [])
	var chapter_scenes: Array = constants.get("MDS_CHAPTER_SCENES", [])
	var plan_paths: Array = constants.get("CHAPTER_PLAN_PATHS", [])
	t.call(world_files.size(), 4, "ch3_world_game_has_four_world_files")
	t.call(chapter_scenes.size(), 4, "ch3_world_game_has_four_world_scenes")
	t.call(plan_paths.size(), 4, "ch3_world_game_has_four_plan_slots")
	if world_files.size() == 4:
		t.call(world_files[2], WORLD_PATH, "ch3_world_game_uses_the_big_map_world")
	if chapter_scenes.size() == 4:
		t.call((chapter_scenes[2] as PackedScene).resource_path, WORLD_SCENE_PATH,
			"ch3_world_game_uses_the_big_map_world_scene")
	if plan_paths.size() == 4:
		t.call(plan_paths[2], PLAN_PATH, "ch3_world_game_plan_slot_wired")

	var game_source := FileAccess.get_file_as_string(GAME_SCRIPT_PATH)
	t.call(game_source.contains("chapter_3_bigmap"), true,
		"ch3_world_is_referenced_by_the_game")
	# Region scenes are resolved by the world file, never hard-coded in game.gd.
	t.call(game_source.contains("ch3_bigmap"), false,
		"ch3_region_scenes_are_not_referenced_by_the_game")
	# Status #16: no gameplay source grants the shortcut ability yet.
	t.call(game_source.contains("ch3_shortcut"), false,
		"ch3_world_grants_no_shortcut")

	# The plan owns its wave content and the world now spawns from it through the
	# campaign route.
	var plan := _plan()
	t.call(plan != null, true, "ch3_world_plan_still_loads")
	if plan != null:
		t.call(plan.content_pending, false, "ch3_world_plan_content_pending_cleared")
		t.call(plan.validate_waves(), PackedStringArray(),
			"ch3_world_plan_waves_validate_clean")
		t.call(plan.boss_scene != null, true, "ch3_world_plan_boss_scene_routed")
		if plan.boss_scene != null:
			t.call(plan.boss_scene.resource_path,
				"res://scenes/bosses/last_reader.tscn",
				"ch3_world_plan_boss_scene_path")
		# The content layer pass authored the revive/rewrite base pool and the
		# Boss 3 pass routed the plan's boss scene; game.gd still does not load
		# the plan, so the world itself spawns no enemies and routes no boss.
		t.call(plan.authority_pool.size(), 2,
			"ch3_world_plan_base_authority_pool_authored")
		var wave_keys := 0
		for entry in plan.rooms:
			var table: Variant = entry.get("wave", null)
			if table is Dictionary:
				wave_keys += (table as Dictionary).size()
		t.call(wave_keys, 6, "ch3_world_plan_six_waves_authored")

	# Status #14: no vision-compression implementation anywhere in the world.
	var packed := load(WORLD_SCENE_PATH) as PackedScene
	t.call(packed != null, true, "ch3_world_scene_loads")
	if packed != null:
		var world := packed.instantiate() as MDSWorldGame
		t.call(world != null, true, "ch3_world_scene_is_mds_world")
		if world != null:
			t.call(world.world_file, WORLD_PATH, "ch3_world_scene_file")
			t.call(world.starting_room, "ch3_entry", "ch3_world_scene_start")
			t.call(world.starting_room, _plan().start_region(),
				"ch3_world_scene_uses_plan_entry")
			t.call(world.seamless_rooms, false, "ch3_world_uses_separate_rooms")
			t.call(world.room_darkness, false, "ch3_world_leaves_vision_compression_off")
			t.call(world.room_weather, true, "ch3_world_has_area_weather")
			t.call(world.room_background, true, "ch3_world_has_area_backdrop")
			world.free()

	# No chapter-3-specific gate visual authoring: the pipeline's shared
	# GateVisual pass is untouched (status: chapter 3 gate polish not scheduled).
	for room_id in REGION_IDS:
		var scene_text := FileAccess.get_file_as_string("%s/%s.tscn" % [REGION_DIR, room_id])
		t.call(scene_text.contains("GateVisual"), false,
			"ch3_no_authored_gate_visuals_%s" % room_id)


func _test_old_worlds_kept(t: Callable) -> void:
	# Old Chapter 3 world: kept for comparison, nine small MDSChapterRoom rooms.
	var old_world := _parse(OLD_CH3_WORLD_PATH)
	t.call(not old_world.is_empty(), true, "ch3_old_world_still_on_disk")
	if not old_world.is_empty():
		t.call(String(old_world.get("name", "")), "Changzi Chapter 3", "ch3_old_world_name")
		t.call(String(old_world.get("start_room", "")), "ch3_01", "ch3_old_world_start")
		var old_rooms: Dictionary = old_world.get("rooms", {})
		t.call(old_rooms.size(), 9, "ch3_old_world_nine_rooms")
		var outgoing := 0
		for room_id in old_rooms:
			var gates: Dictionary = old_rooms[room_id].get("gates", {})
			for gate_name in gates:
				if gates[gate_name].has("to"):
					outgoing += 1
			var rects: Array = old_rooms[room_id].get("rects", [])
			t.call(rects.size() >= 1, true, "ch3_old_room_has_rect_%s" % room_id)
			if not rects.is_empty():
				t.call(_rect(rects[0]).size, Vector2(1280, 720),
					"ch3_old_room_is_small_%s" % room_id)
			var scene_path := String(old_rooms[room_id].get("scene_path", ""))
			var packed := load(scene_path) as PackedScene
			t.call(packed != null, true, "ch3_old_room_scene_loads_%s" % room_id)
			if packed != null:
				var node := packed.instantiate()
				t.call(node is MDSChapterRoom, true,
					"ch3_old_room_uses_chapter_pipeline_%s" % room_id)
				t.call(node is MDSBigRoom, false, "ch3_old_room_is_not_big_room_%s" % room_id)
				node.free()
		t.call(outgoing, 17, "ch3_old_world_seventeen_outgoing_gates")
	var old_scene := load(OLD_CH3_SCENE_PATH) as PackedScene
	t.call(old_scene != null, true, "ch3_old_world_scene_still_loads")
	if old_scene != null:
		var old_game := old_scene.instantiate() as MDSWorldGame
		t.call(old_game != null, true, "ch3_old_world_scene_is_mds_world")
		if old_game != null:
			t.call(old_game.world_file, OLD_CH3_WORLD_PATH, "ch3_old_world_scene_file")
			t.call(old_game.starting_room, "ch3_01", "ch3_old_world_scene_start")
			old_game.free()

	# Chapter 1 and Chapter 2 stay exactly as they were.
	var ch1_plan := load(CH1_PLAN_PATH) as ChapterPlanData
	t.call(ch1_plan != null, true, "ch3_ch1_plan_still_loads")
	if ch1_plan != null:
		t.call(ch1_plan.big_map, false, "ch3_ch1_plan_still_linear")
		t.call(ch1_plan.rooms.size(), 9, "ch3_ch1_plan_still_nine_rooms")
		t.call(ch1_plan.clear_target(), 6, "ch3_ch1_plan_clear_target_still_six")
		t.call(ch1_plan.validate(), PackedStringArray(), "ch3_ch1_plan_validates_clean")
	var ch2_plan := load(CH2_PLAN_PATH) as ChapterPlanData
	t.call(ch2_plan != null, true, "ch3_ch2_plan_still_loads")
	if ch2_plan != null:
		t.call(ch2_plan.big_map, true, "ch3_ch2_plan_still_big_map")
		t.call(ch2_plan.rooms.size(), 9, "ch3_ch2_plan_still_nine_regions")
		t.call(ch2_plan.doors.size(), 11, "ch3_ch2_plan_still_eleven_doors")
		t.call(ch2_plan.clear_target(), 7, "ch3_ch2_plan_clear_target_still_seven")
		t.call(ch2_plan.content_pending, false, "ch3_ch2_plan_has_no_pending_content")
		t.call(ch2_plan.validate(), PackedStringArray(), "ch3_ch2_plan_validates_clean")
	var ch2_world := _parse(CH2_WORLD_PATH)
	t.call(not ch2_world.is_empty(), true, "ch3_ch2_world_still_parses")
	if not ch2_world.is_empty():
		t.call((ch2_world.get("rooms", {}) as Dictionary).size(), 9,
			"ch3_ch2_world_still_nine_regions")

	# Chapter 1 keeps its six waves and its event module; the old Chapter 3
	# waves are still on disk for the later content pass.
	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	t.call(game_script != null, true, "ch3_world_wave_source_loads")
	if game_script != null:
		var waves: Array = game_script.get_script_constant_map().get("ROOM_WAVES", [])
		t.call(waves.size() >= 3, true, "ch3_world_room_waves_present")
		if waves.size() >= 3:
			t.call((waves[0] as Array).size(), 6, "ch3_world_ch1_six_waves_unchanged")
			t.call((waves[2] as Array).size(), 6, "ch3_world_old_ch3_six_waves_kept")
	t.call(ResourceLoader.exists("res://scripts/data/ch1_event_data.gd"), true,
		"ch3_world_ch1_event_module_kept")
	t.call(ResourceLoader.exists("res://scripts/data/ch2_event_data.gd"), true,
		"ch3_world_ch2_event_module_kept")


func _instantiate(room_id: String) -> Node:
	var packed := load("%s/%s.tscn" % [REGION_DIR, room_id]) as PackedScene
	return packed.instantiate() if packed != null else null


func _plan() -> ChapterPlanData:
	return load(PLAN_PATH) as ChapterPlanData


func _world() -> Dictionary:
	return _parse(WORLD_PATH)


func _parse(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _gate(world: Dictionary, room_id: String, gate_name: String) -> Dictionary:
	var rooms: Dictionary = world.get("rooms", {})
	if not rooms.has(room_id):
		return {}
	var gates: Dictionary = rooms[room_id].get("gates", {})
	return gates.get(gate_name, {})


func _top_gate_x(world: Dictionary, room_id: String) -> float:
	var rooms: Dictionary = world.get("rooms", {})
	if not rooms.has(room_id):
		return -1.0
	var gates: Dictionary = rooms[room_id].get("gates", {})
	for gate_name in gates:
		var gate: Dictionary = gates[gate_name]
		if String(gate.get("side", "")) == "top":
			var pos: Array = gate.get("pos", [])
			if pos.size() == 2:
				return float(pos[0])
	return -1.0


func _room_keys(rooms: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for key in rooms:
		out.append(String(key))
	out.sort()
	return out


func _sorted(values: PackedStringArray) -> PackedStringArray:
	var out := values.duplicate()
	out.sort()
	return out


func _strings(value: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	if value is Array:
		for item in value:
			if item is String:
				out.append(String(item))
	return out


func _rect(value: Array) -> Rect2:
	if value.size() < 4:
		return Rect2()
	return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))


func _world_rect(world: Dictionary, room_id: String) -> Rect2:
	var rooms: Dictionary = world.get("rooms", {})
	if not rooms.has(room_id):
		return Rect2()
	var room: Dictionary = rooms[room_id]
	var local := Rect2()
	var first := true
	for value in room.get("rects", []):
		if not value is Array or value.size() < 4:
			continue
		var rect := _rect(value)
		local = rect if first else local.merge(rect)
		first = false
	var origin_value: Array = room.get("origin", [])
	var origin := Vector2.ZERO
	if origin_value.size() == 2:
		origin = Vector2(float(origin_value[0]), float(origin_value[1]))
	return Rect2(origin + local.position, local.size)


func _touching(a: Rect2, b: Rect2) -> bool:
	var vertical_edge := is_equal_approx(a.end.x, b.position.x) \
		or is_equal_approx(b.end.x, a.position.x)
	var horizontal_edge := is_equal_approx(a.end.y, b.position.y) \
		or is_equal_approx(b.end.y, a.position.y)
	var y_overlap := minf(a.end.y, b.end.y) - maxf(a.position.y, b.position.y)
	var x_overlap := minf(a.end.x, b.end.x) - maxf(a.position.x, b.position.x)
	return (vertical_edge and y_overlap > 0.0) or (horizontal_edge and x_overlap > 0.0)


func _reachable(world: Dictionary, start: String) -> PackedStringArray:
	var out := PackedStringArray()
	var rooms: Dictionary = world.get("rooms", {})
	if not rooms.has(start):
		return out
	var seen := {start: true}
	var queue: Array[String] = [start]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		out.append(current)
		var gates: Dictionary = rooms[current].get("gates", {})
		for gate_name in gates:
			var target := String(gates[gate_name].get("to", ""))
			if target.is_empty() or not rooms.has(target) or seen.has(target):
				continue
			seen[target] = true
			queue.append(target)
	return out
