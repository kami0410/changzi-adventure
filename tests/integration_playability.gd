extends SceneTree
var failures: int = 0
var assertions: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("INTEGRATION FAIL: " + label)

func _wait_room_id(mds, room_id: String, timeout := 5.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if not mds.changing_room and mds.current_room == room_id:
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _wait_mds(scene, timeout := 8.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._mds_world != null and not scene._mds_world.changing_room and not scene._mds_world.current_room.is_empty():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _wait_world_room(world, room_id: String, timeout := 8.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if not world.changing_room and world.current_room == room_id and world.room_node != null:
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


## Drops the real player onto [param surface_y] at [param x] and waits for the
## feet to settle. The 240 px fall starts above the target; callers pick an x
## that is not under a higher platform.
func _drop_onto(player: Player, x: float, surface_y: float) -> bool:
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(x, surface_y - Player.FOOT_Y - 240.0)
	for _frame in 240:
		await physics_frame
		if player.is_on_floor() \
				and absf(player.global_position.y + Player.FOOT_Y - surface_y) <= 2.0:
			return true
	return false


## Fixture for the Chapter 2+ room production line: two areas with different
## looks, a 2560x1440 room and an L-shaped 3840x1440 union. Nothing here is
## chapter content; the world lives under tests/fixtures.
func _test_big_room_pipeline() -> void:
	var world := MDSWorldGame.new()
	world.name = "BigRoomFixtureWorld"
	world.world_file = "res://tests/fixtures/big_room/world.mdsworld.json"
	world.starting_room = "big_wide"
	world.fade_time = 0.0
	world.room_weather = true
	world.room_background = true
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	player.name = "Player"
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	player.add_child(camera)
	world.add_child(player)
	world.player = player
	world.camera = camera
	root.add_child(world)
	current_scene = world
	if camera.is_inside_tree():
		camera.make_current()
	check(await _wait_world_room(world, "big_wide"), "big_room_fixture_starts")
	var room := world.room_node as MDSBigRoom
	check(room != null, "big_room_fixture_uses_pipeline")
	if room == null:
		_cleanup_big_world(world)
		return

	var wide_bounds: Rect2 = world.world.get_room_bounds("big_wide")
	check(wide_bounds.size == Vector2(2560, 1440), "big_room_variable_size_bounds")
	check(camera.limit_left == 0 and camera.limit_top == 0, "big_room_camera_origin_limits")
	check(camera.limit_right == 2560, "big_room_camera_right_limit")
	check(camera.limit_bottom == 1440, "big_room_camera_bottom_limit")

	room.data = _wide_room_data()
	room.build()
	check(room.validation_errors.is_empty(), "big_room_wide_layout_valid")
	check(room.built_ground_surfaces.size() == 2, "big_room_wide_ground_layers")
	check(room.built_platform_surfaces.size() == 4, "big_room_wide_platforms")
	check(String(room.area_info.get("area", "")) == "Wide Ruins", "big_room_area_from_world")
	check(String(room.area_info.get("backdrop_source", "")) == "area",
		"big_room_backdrop_from_area")
	check(room.backdrop_tiles.size() == 4, "big_room_backdrop_tiles_cover_width")
	check(room.backdrop_rect_local() == Rect2(0, 0, 2560, 1440), "big_room_backdrop_rect")
	check(room.backdrop_tiles[0].texture.resource_path.ends_with("ink_archive_far.png"),
		"big_room_area_backdrop_image")
	check(String(room.area_info.get("weather", "")).contains("fireflies"),
		"big_room_weather_per_area")
	check(String(room.area_info.get("background", "")) == "aurora",
		"big_room_dynamic_background_per_area")
	check(room.get_node_or_null("MDSWeather") != null, "big_room_mds_weather_applied")
	check(room.get_node_or_null("MDSBackground") != null, "big_room_mds_background_applied")

	var right_gate := MDSGate.find_gate(room, "right1")
	check(right_gate != null, "big_room_generates_gate_nodes")
	if right_gate != null:
		check(right_gate.position == Vector2(2552, 1280), "big_room_gate_world_position")
		check(right_gate.mode == MDSGate.Mode.TOUCH, "big_room_touch_gate")
	var door := MDSGate.find_gate(room, "door1")
	check(door != null and door.mode == MDSGate.Mode.INTERACT, "big_room_door_gate")
	if door != null:
		check(door.prompt.contains("按"), "big_room_door_prompt")

	var ambient := room.get_node_or_null("Ambient") as BigRoomAmbient
	check(ambient != null, "big_room_ambient")
	if ambient != null:
		player.global_position = Vector2(200, 1200)
		await process_frame
		var first_window := ambient.view_window()
		check(first_window.size.x > 0.0 and first_window.size.x < 2560.0,
			"big_room_ambient_camera_limited")
		check(ambient.mote_count() > 0, "big_room_ambient_motes")
		player.global_position = Vector2(2100, 1200)
		await process_frame
		await process_frame
		var moved_window := ambient.view_window()
		check(moved_window.position.x > first_window.position.x,
			"big_room_ambient_follows_camera")
		check(room.room_bounds.encloses(moved_window), "big_room_ambient_stays_in_bounds")

	check(await _drop_onto(player, 2100.0, 1360.0), "big_room_ground_landing")
	check(await _drop_onto(player, 1150.0, 1280.0), "big_room_terrace_landing")
	check(await _drop_onto(player, 400.0, 1200.0), "big_room_low_platform_landing")
	check(await _drop_onto(player, 1250.0, 1040.0), "big_room_mid_platform_landing")
	check(await _drop_onto(player, 1650.0, 960.0), "big_room_high_platform_landing")

	await _test_vertical_props(world, room, player)

	await world.load_room("big_l")
	check(await _wait_world_room(world, "big_l"), "big_room_l_room_loads")
	room = world.room_node as MDSBigRoom
	check(room != null, "big_room_l_uses_pipeline")
	if room == null:
		_cleanup_big_world(world)
		return
	check(world.world.get_local_rects("big_l").size() == 2, "big_room_l_has_two_rects")
	check(world.world.get_room_bounds("big_l").size == Vector2(3840, 1440),
		"big_room_l_union_bounds")
	check(not world.world.room_contains("big_l", Vector2(5600, 400)),
		"big_room_l_notch_outside_union")
	check(world.world.room_contains("big_l", Vector2(5600, 1000)),
		"big_room_l_second_rect_walkable")
	check(camera.limit_left == 2560 and camera.limit_right == 6400,
		"big_room_l_camera_limits")
	check(camera.limit_top == 0 and camera.limit_bottom == 1440,
		"big_room_l_camera_vertical_limits")
	room.data = _l_room_data()
	room.build()
	check(room.validation_errors.is_empty(), "big_room_l_layout_valid")
	check(room.room_bounds == Rect2(0, 0, 3840, 1440), "big_room_l_local_bounds")
	check(String(room.area_info.get("area", "")) == "Lower Vault", "big_room_l_area")
	check(String(room.area_info.get("backdrop_source", "")) == "area", "big_room_l_backdrop_area")
	check(room.backdrop_tiles.size() == 6, "big_room_l_backdrop_tiles_cover_width")
	check(room.backdrop_rect_local() == Rect2(0, 0, 3840, 1440), "big_room_l_backdrop_rect")
	check(room.backdrop_tiles[0].texture.resource_path.ends_with("ink_archive_mid.png"),
		"big_room_l_area_backdrop_image")
	check(String(room.area_info.get("weather", "")).contains("embers"), "big_room_l_weather")
	check(String(room.area_info.get("background", "")) == "ember_glow",
		"big_room_l_dynamic_background")
	var area_color: Color = room.area_info.get("color", Color.WHITE)
	var l_ambient := room.get_node_or_null("Ambient") as BigRoomAmbient
	check(l_ambient != null, "big_room_l_ambient")
	if l_ambient != null:
		check(l_ambient.kind == &"embers", "big_room_l_ambient_kind")
		check(is_equal_approx(l_ambient.tint.r, area_color.r)
			and is_equal_approx(l_ambient.tint.g, area_color.g)
			and is_equal_approx(l_ambient.tint.b, area_color.b),
			"big_room_l_ambient_tinted_by_area")

	var l_origin: Vector2 = world.world.get_origin("big_l")
	check(await _drop_onto(player, l_origin.x + 3200.0, 1360.0),
		"big_room_l_ground_landing")
	check(await _drop_onto(player, l_origin.x + 2800.0, 1280.0),
		"big_room_l_platform_landing")
	_cleanup_big_world(world)


## Chapter 2 step 3 fixtures: one-way platforms, collapsing platforms, moving
## platforms/elevators and a conditional shortcut gate. These are pipeline
## fixtures added to the existing big-room test world, not chapter content.
func _test_vertical_props(world, room: MDSBigRoom, player: Player) -> void:
	# --- Shortcut: a world-authored `requires` becomes an MDSGateBarrier that
	# opens permanently and records its state in the MDS save.
	var shortcut_gate := MDSGate.find_gate(room, "shortcut")
	check(shortcut_gate != null, "props_shortcut_gate_generated")
	var barrier := room.get_node_or_null("Barrier_shortcut") as MDSGateBarrier
	check(barrier != null, "props_shortcut_barrier_generated")
	if barrier != null:
		check(not barrier.is_open, "props_shortcut_starts_closed")
		check(barrier.get_requirements() == PackedStringArray(["ch2_shortcut"]),
			"props_shortcut_requirements")
		world.grant_ability("ch2_shortcut")
		check(barrier.is_open, "props_shortcut_opens_on_ability")
		check(world.is_object_stored(barrier), "props_shortcut_state_stored")
		check(world.get_save_data().get("stored", []).has(world.object_id(barrier)),
			"props_shortcut_state_saved")

	# --- One-way platform: land from above, drop through with down+jump, jump
	# up through it from below, and keep down+jump a normal jump on solid ground.
	var one_way := OneWayPlatform.new()
	one_way.name = "TestOneWay"
	one_way.position = Vector2(1850, 1280)
	one_way.size = Vector2(200, 16)
	room.add_child(one_way)
	await physics_frame
	check(one_way.is_in_group(OneWayPlatform.GROUP), "props_one_way_group")
	var one_way_shape := one_way.collision_shape()
	check(one_way_shape != null and one_way_shape.one_way_collision,
		"props_one_way_collision_flag")
	var hp := player.health
	check(await _drop_onto(player, 1950.0, 1280.0), "props_one_way_top_landing")

	await _press_down_jump()
	check(await _wait_landed(player, 1360.0), "props_one_way_drop_through")
	check(player.health == hp, "props_one_way_drop_no_fall_damage")

	# Jump from the ground below: the one-way shape must not block the ascent
	# and the player lands on its top face.
	Input.action_press("jump")
	for _frame in 24:
		await physics_frame
	Input.action_release("jump")
	check(await _wait_landed(player, 1280.0), "props_one_way_from_below_lands_on_top")
	check(player.health == hp, "props_one_way_from_below_no_fall_damage")

	await _press_down_jump()
	check(await _wait_landed(player, 1360.0), "props_one_way_drops_again")

	# Chapter 1 ground uses solid bodies; down+jump there must still be a jump.
	# Step clear of the one-way platform so the jump can land back on ground.
	player.global_position = Vector2(1750.0, 1360.0 - Player.FOOT_Y)
	player.velocity = Vector2.ZERO
	await physics_frame
	var feet := player.global_position.y + Player.FOOT_Y
	Input.action_press("move_down")
	Input.action_press("jump")
	var peak := feet
	for _frame in 24:
		await physics_frame
		peak = minf(peak, player.global_position.y + Player.FOOT_Y)
	Input.action_release("jump")
	Input.action_release("move_down")
	check(peak < feet - 8.0, "props_solid_ground_down_jump_still_jumps")
	check(await _wait_landed(player, 1360.0), "props_solid_ground_landing")

	# --- Collapsing platform: readable warning, fall, restore. The player drops
	# to the ground below without being treated as falling out of the world.
	var collapse := CollapsingPlatform.new()
	collapse.name = "TestCollapse"
	collapse.position = Vector2(2100, 1280)
	collapse.size = Vector2(160, 16)
	collapse.warn_time = 1.2
	collapse.fall_time = 0.25
	collapse.respawn_time = 1.2
	room.add_child(collapse)
	await physics_frame
	var collapse_hp := player.health
	check(await _drop_onto(player, 2180.0, 1280.0), "props_collapse_top_landing")
	var warned := false
	var warned_progress := 0.0
	var warned_offset := Vector2.ZERO
	var fell := false
	for _frame in 180:
		await physics_frame
		if collapse.is_warning():
			warned = true
			warned_progress = maxf(warned_progress, collapse.warning_progress())
			warned_offset = collapse.visual_offset()
		if collapse.has_collapsed():
			fell = true
			break
	check(warned, "props_collapse_warns")
	check(warned_progress > 0.15, "props_collapse_warning_progresses")
	check(warned_offset.length() > 0.01, "props_collapse_warning_shakes")
	check(fell, "props_collapse_falls")
	check(not collapse.is_solid(), "props_collapse_collision_off")
	check(await _wait_landed(player, 1360.0), "props_collapse_player_reaches_ground")
	check(player.health == collapse_hp, "props_collapse_no_false_fall_damage")
	var restored := false
	for _frame in 180:
		await physics_frame
		if collapse.state == CollapsingPlatform.State.IDLE and collapse.is_solid():
			restored = true
			break
	check(restored, "props_collapse_restores")

	# --- Vertical elevator: carries the player without sliding or clipping and
	# stays inside the room union MDS gave the camera.
	var mover := MovingPlatform.new()
	mover.name = "TestMover"
	mover.position = Vector2(2280, 1280)
	mover.size = Vector2(120, 16)
	mover.travel = Vector2(0, -160)
	mover.speed = 80.0
	mover.pause_time = 0.3
	mover.start_delay = 100.0
	room.add_child(mover)
	await physics_frame
	check(mover.bounds_resolved, "props_mover_bounds_resolved")
	check(mover.room_bounds == room.room_bounds, "props_mover_uses_room_union")
	check(not mover.travel_clamped, "props_mover_travel_inside_room")
	check(await _drop_onto(player, 2340.0, 1280.0), "props_mover_landing")
	mover.restart(0.05)
	var mover_offset := player.global_position - mover.global_position
	var mover_start := mover.position.y
	var moved := false
	for _frame in 45:
		await physics_frame
		if mover.position.y < mover_start - 10.0:
			moved = true
	check(moved, "props_mover_moves")
	check(player.is_on_floor(), "props_mover_player_stays_on_floor")
	check((player.global_position - mover.global_position).distance_to(mover_offset) < 8.0,
		"props_mover_carries_player")
	check(room.room_bounds.encloses(mover.platform_rect()), "props_mover_stays_in_room")

	# --- Horizontal ferry: same carry contract on the other axis.
	var ferry := MovingPlatform.new()
	ferry.name = "TestFerry"
	ferry.position = Vector2(600, 1000)
	ferry.size = Vector2(120, 16)
	ferry.travel = Vector2(120, 0)
	ferry.speed = 90.0
	ferry.pause_time = 0.2
	ferry.start_delay = 100.0
	room.add_child(ferry)
	await physics_frame
	check(await _drop_onto(player, 660.0, 1000.0), "props_ferry_landing")
	ferry.restart(0.05)
	var ferry_offset := player.global_position - ferry.global_position
	var ferry_start := ferry.position.x
	for _frame in 45:
		await physics_frame
	check(ferry.position.x > ferry_start + 10.0, "props_ferry_moves_horizontally")
	check((player.global_position - ferry.global_position).distance_to(ferry_offset) < 8.0,
		"props_ferry_carries_player")
	check(room.room_bounds.encloses(ferry.platform_rect()), "props_ferry_stays_in_room")

	# --- Authored travel beyond the union is clamped, not followed.
	var edge := MovingPlatform.new()
	edge.name = "TestEdgeMover"
	edge.position = Vector2(2440, 1120)
	edge.size = Vector2(120, 16)
	edge.travel = Vector2(200, 0)
	room.add_child(edge)
	await physics_frame
	check(edge.travel_clamped, "props_mover_reports_clamp")
	check(is_equal_approx(edge.effective_travel.x, 0.0), "props_mover_clamped_to_camera_limit")
	check(edge.platform_rect().end.x <= 2560.0, "props_mover_clamp_inside_room")


func _press_down_jump() -> void:
	Input.action_press("move_down")
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	await physics_frame
	Input.action_release("move_down")


func _wait_landed(player: Player, surface_y: float, frames := 240) -> bool:
	for _frame in frames:
		await physics_frame
		if player.is_on_floor() \
				and absf(player.global_position.y + Player.FOOT_Y - surface_y) <= 2.0:
			return true
	return false


func _wide_room_data() -> BigRoomData:
	var data := BigRoomData.new()
	data.size = Vector2i(2560, 1440)
	data.ground = [
		{"x": 0.0, "y": 1360.0, "width": 2560.0, "height": 80.0},
		{"x": 0.0, "y": 1280.0, "width": 1280.0, "height": 80.0},
	]
	data.platforms = [
		{"x": 200.0, "y": 1200.0, "width": 400.0},
		{"x": 700.0, "y": 1120.0, "width": 400.0},
		{"x": 1200.0, "y": 1040.0, "width": 400.0},
		{"x": 1300.0, "y": 960.0, "width": 400.0},
	]
	data.ambient_kind = &"motes"
	data.ambient_density = 0.6
	return data


func _l_room_data() -> BigRoomData:
	var data := BigRoomData.new()
	data.size = Vector2i(3840, 1440)
	data.ground = [
		{"x": 0.0, "y": 1360.0, "width": 2560.0, "height": 80.0},
		{"x": 2560.0, "y": 1360.0, "width": 1280.0, "height": 80.0},
	]
	data.platforms = [{"x": 2600.0, "y": 1280.0, "width": 400.0}]
	data.ambient_kind = &"embers"
	return data


func _cleanup_big_world(world) -> void:
	if current_scene == world:
		current_scene = null
	if is_instance_valid(world):
		if world.get_parent() != null:
			root.remove_child(world)
		world.free()


## Chapter 2 big-map structure. The real region world replaces the old nine
## small rooms, so this covers plan-driven start/clear/fall semantics, all nine
## regions loading, the door graph, per-node content settlement and the one-way
## boss entrance. Chapter 1 remains the linear demo (covered above).
func _test_ch2_big_map(scene) -> void:
	var mds = scene._mds_world
	var plan: ChapterPlanData = scene._chapter_plan
	check(plan != null and plan.big_map, "chapter_2_plan_is_big_map")
	if plan == null or not plan.big_map:
		return
	check(mds.current_room == "ch2_entry", "chapter_2_starts_at_plan_entry")
	check(mds.current_room == plan.start_region(), "chapter_2_start_room_comes_from_plan")
	check(scene._chapter_clear_target() == 7, "chapter_2_clear_target_seven")
	check(scene._chapter_progress_total() == 8, "chapter_2_progress_total_includes_boss")
	check(is_equal_approx(scene._fall_limit_local, 1680.0), "chapter_2_entry_fall_plane_from_plan")
	check(scene._map_overlay.title_text() == "呼吸废墟地图", "chapter_2_map_title_region")
	check(scene._map_overlay.title_text() != "档案馆地图",
		"chapter_2_map_title_not_chapter_1")
	scene._map_overlay.open()
	check(scene._map_overlay.is_open(), "chapter_2_map_opens")
	check(scene._map_overlay.map_view.is_room_revealed("ch2_entry"), "chapter_2_map_reveals_entry")
	scene._map_overlay.close()

	var entry_room := mds.room_node as MDSBigRoom
	check(entry_room != null, "chapter_2_entry_uses_big_room_pipeline")
	if entry_room != null:
		check(entry_room.validation_errors.is_empty(), "chapter_2_entry_geometry_valid")
		check(entry_room.get_node_or_null("shortcut_arrival") != null,
			"chapter_2_entry_authors_shortcut_arrival")
		var shortcut_arrival := MDSGate.find_gate(entry_room, "shortcut_arrival")
		check(shortcut_arrival != null and shortcut_arrival.mode == MDSGate.Mode.TOUCH,
			"chapter_2_shortcut_arrival_is_inert_touch_gate")

	for room_id in plan.room_ids():
		var id := String(room_id)
		await mds.load_room(id)
		check(await _wait_room_id(mds, id), "chapter_2_region_loaded_%s" % id)
		var room := mds.room_node as MDSBigRoom
		check(room != null, "chapter_2_region_pipeline_%s" % id)
		if room == null:
			continue
		check(room.validation_errors.is_empty(), "chapter_2_region_geometry_%s" % id)
		check(room.data != null, "chapter_2_region_data_%s" % id)
		var size := plan.region_size(id)
		check(room.room_bounds.size == Vector2(size), "chapter_2_region_bounds_%s" % id)
		check(is_equal_approx(scene._fall_limit_local, plan.region_fall_limit(id)),
			"chapter_2_region_fall_plane_%s" % id)
		check(is_equal_approx(scene._fall_limit_local, float(size.y) + 240.0),
			"chapter_2_region_fall_margin_%s" % id)
		check(String(room.area_info.get("area", "")) == "Breathing Ruins",
			"chapter_2_region_area_%s" % id)
		check(not room.backdrop_tiles.is_empty(), "chapter_2_region_backdrop_%s" % id)
		check(String(room.area_info.get("weather", "")).contains("fog"),
			"chapter_2_region_weather_%s" % id)

		# Every authored and arrival gate is present on the loaded scene.
		for door in plan.doors:
			for key in ["from_gate", "to_gate"]:
				if String(door.get(key, "")) == "":
					continue
				var belongs := false
				if key == "from_gate":
					belongs = String(door.get("from", "")) == id
				else:
					belongs = String(door.get("to", "")) == id
				if not belongs:
					continue
				var gate_name := String(door[key])
				var gate := MDSGate.find_gate(room, gate_name)
				check(gate != null, "chapter_2_gate_present_%s_%s" % [id, gate_name])
				if gate == null:
					continue
				var side := String(mds.world.get_gate_side(id, gate_name))
				if side == "door" and gate_name != "shortcut_arrival":
					check(gate.mode == MDSGate.Mode.INTERACT,
						"chapter_2_door_gate_interacts_%s_%s" % [id, gate_name])
				else:
					check(gate.mode == MDSGate.Mode.TOUCH,
						"chapter_2_walk_gate_touches_%s_%s" % [id, gate_name])

		var plan_room := plan.room(id)
		var expected_chests := _plan_strings(plan_room.get("chests", []))
		var expected_steles := _plan_strings(plan_room.get("steles", []))
		check(scene._chests.size() == expected_chests.size(), "chapter_2_chest_count_%s" % id)
		check(scene._steles.size() == expected_steles.size(), "chapter_2_stele_count_%s" % id)
		for chest in scene._chests:
			check(expected_chests.has(String(chest.get_meta(&"content_id", ""))),
				"chapter_2_chest_id_%s_%s" % [id, chest.name])
		for stele in scene._steles:
			check(expected_steles.has(String(stele.get_meta(&"content_id", ""))),
				"chapter_2_stele_id_%s_%s" % [id, stele.name])
		if String(plan_room.get("type", "")) != "boss":
			var expected_encounters := _plan_strings(plan_room.get("encounters", []))
			var arenas: Array[ArenaRoom] = scene._room_arenas(
				room, room.get_node_or_null("Arena") as ArenaRoom)
			check(arenas.size() == expected_encounters.size(), "chapter_2_encounter_count_%s" % id)
			var region_type := String(plan_room.get("type", ""))
			for arena in arenas:
				var encounter_id := String(arena.get_meta(&"encounter_id", ""))
				check(expected_encounters.has(encounter_id),
					"chapter_2_encounter_id_%s_%s" % [id, arena.name])
				# Wave wiring: each combat encounter spawns its own plan wave;
				# the event encounter owns no wave and never spawns enemies.
				var wave := plan.wave_for(id, encounter_id)
				if region_type == "event":
					check(wave.is_empty(), "chapter_2_event_wave_absent_%s" % id)
					check(arena.enemy_count() == 0, "chapter_2_event_arena_empty_%s" % id)
					check(not scene._rooms.has(arena),
						"chapter_2_event_arena_not_registered_%s" % id)
				else:
					check(not wave.is_empty(),
						"chapter_2_wave_present_%s_%s" % [id, arena.name])
					var first_group: Array = wave.slice(0, mini(2, wave.size()))
					check(arena.enemy_count() == first_group.size(),
						"chapter_2_wave_count_%s_%s" % [id, arena.name])
					check(_arena_enemy_ids(arena) == first_group,
						"chapter_2_wave_enemies_%s_%s" % [id, arena.name])
					check(scene._rooms.has(arena),
						"chapter_2_wave_arena_registered_%s_%s" % [id, arena.name])
					# Big-map arenas anchor the spawn point on the walkable
					# surface; a legacy +250 offset would bury the wave.
					var arena_ground := _ground_surface_y(room)
					var above_ground := true
					for enemy in arena.get_node(ArenaRoom.ENEMIES_NODE).get_children():
						if enemy is Node2D and enemy.global_position.y >= arena_ground:
							above_ground = false
					check(above_ground, "chapter_2_wave_spawns_above_ground_%s_%s"
						% [id, arena.name])

		match id:
			"ch2_hub":
				check(scene._shops.size() == 1, "chapter_2_hub_has_shop")
				if scene._shops.size() == 1:
					check(scene._shops[0].shop_id == &"ch2_hub_shop", "chapter_2_hub_shop_id")
				check(room.get_node_or_null("Bench") is BenchCheckpoint,
					"chapter_2_hub_has_bench")
				var barrier := room.get_node_or_null("Barrier_shortcut") as MDSGateBarrier
				check(barrier != null, "chapter_2_hub_shortcut_barrier")
				if barrier != null:
					check(not barrier.is_open, "chapter_2_hub_shortcut_starts_closed")
					mds.grant_ability("ch2_shortcut")
					check(barrier.is_open, "chapter_2_hub_shortcut_opens")
					check(mds.get_save_data().get("stored", []).has(mds.object_id(barrier)),
						"chapter_2_hub_shortcut_state_saved")
				var shortcut_gate := MDSGate.find_gate(room, "shortcut")
				check(shortcut_gate != null, "chapter_2_hub_shortcut_gate")
				if shortcut_gate != null:
					var transition := shortcut_gate.get_transition()
					check(String(transition.get("room", "")) == "ch2_entry",
						"chapter_2_hub_shortcut_target")
					var gate_data: Dictionary = mds.world.get_gate("ch2_hub", "shortcut")
					check(_plan_strings(gate_data.get("requires", [])) == PackedStringArray(["ch2_shortcut"]),
						"chapter_2_hub_shortcut_requires")
			"ch2_well":
				check(room.get_node_or_null("Lift") is MovingPlatform,
					"chapter_2_well_has_lift")
				check(room.find_children("*", "OneWayPlatform", true, false).size() == 3,
					"chapter_2_well_has_one_way_platforms")
				var origin: Vector2 = mds.world.get_origin("ch2_well")
				var lower_health: int = scene.player.health
				scene.player.global_position = origin + Vector2(1200, 2100)
				await physics_frame
				await physics_frame
				check(scene.player.global_position.y > origin.y + 1900.0,
					"chapter_2_well_lower_layer_survives")
				check(scene.player.health == lower_health, "chapter_2_well_lower_layer_no_damage")
			"ch2_vault":
				check(scene._chests.size() == 2, "chapter_2_vault_two_chests")
				check(scene._steles.size() == 2, "chapter_2_vault_two_steles")
				var chest1 := room.get_node_or_null("Chest1") as TreasureChest
				var chest2 := room.get_node_or_null("Chest2") as TreasureChest
				check(chest1 != null and chest2 != null, "chapter_2_vault_named_chests")
				if chest1 != null:
					scene._open_chest(chest1)
					await process_frame
					check(scene._opened_chests.has("ch2_vault/Chest1"),
						"chapter_2_vault_chest1_recorded")
					check(not scene._opened_chests.has("ch2_vault/Chest2"),
						"chapter_2_vault_chest2_not_recorded")
				var stele1 := room.get_node_or_null("Stele1") as MemoryStele
				var stele2 := room.get_node_or_null("Stele2") as MemoryStele
				check(stele1 != null and stele2 != null, "chapter_2_vault_named_steles")
				if stele1 != null:
					scene.player.global_position = stele1.global_position
					scene._claim_nearest_stele()
					await process_frame
					check(scene._claimed_steles.has("ch2_vault/Stele1"),
						"chapter_2_vault_stele1_recorded")
					check(not scene._claimed_steles.has("ch2_vault/Stele2"),
						"chapter_2_vault_stele2_not_recorded")
				await mds.load_room("ch2_vault")
				check(await _wait_room_id(mds, "ch2_vault"), "chapter_2_vault_reloads")
				room = mds.room_node as MDSBigRoom
				var kept1 := room.get_node_or_null("Chest1") as TreasureChest
				var kept2 := room.get_node_or_null("Chest2") as TreasureChest
				check(kept1 != null and kept1.is_open, "chapter_2_vault_chest1_stays_open")
				check(kept2 != null and not kept2.is_open, "chapter_2_vault_chest2_stays_closed")
				check(scene._steles.size() == 1, "chapter_2_vault_claimed_stele_removed")
				if scene._steles.size() == 1:
					check(String(scene._steles[0].get_meta(&"content_id", ""))
						== "ch2_vault/Stele2", "chapter_2_vault_remaining_stele")
			"ch2_event":
				# The big-map event region owns a real entry trigger: loading the
				# region schedules the Chapter 2 page through the per-chapter
				# route, exactly like Chapter 1's event room. Copy and options
				# come from Ch2EventData keyed by the plan node id, and picking
				# the variant must not roll the run RNG.
				var flow := root.get_node_or_null("Flow") as GameFlow
				var rng_before: int = scene.run_state.rng.state
				check(await _wait_story(scene), "chapter_2_event_page_opens")
				check(scene.run_state.rng.state == rng_before,
					"chapter_2_event_page_keeps_run_rng")
				var expected_event := Ch2EventData.pick(
					scene.run_state.run_seed, "ch2_event/event")
				check(not expected_event.is_empty(), "chapter_2_event_variant_resolves")
				check(scene._story._eyebrow.text
					== String(expected_event.get("eyebrow", "")),
					"chapter_2_event_uses_chapter_2_copy")
				check(scene._story._title.text == String(expected_event.get("title", "")),
					"chapter_2_event_title_matches_seed")
				check(scene._story._options.get_child_count() == 2,
					"chapter_2_event_has_two_choices")
				if scene._story._options.get_child_count() == 2:
					check((scene._story._options.get_child(0) as Button).text.begins_with(
						String(expected_event.get("read_label", ""))),
						"chapter_2_event_read_label")
					check((scene._story._options.get_child(1) as Button).text.begins_with(
						String(expected_event.get("take_label", ""))),
						"chapter_2_event_take_label")
				var pages_before: int = scene.run_state.pages
				var clears_before: int = scene._cleared_in_chapter
				scene._story.choose(1)
				await create_timer(0.2).timeout
				check(scene.run_state.pages == pages_before + Ch2EventData.PAGES_REWARD,
					"chapter_2_event_taking_pays_pages")
				check(scene.hud.get_message_text()
					== String(expected_event.get("take_message", "")) % Ch2EventData.PAGES_REWARD,
					"chapter_2_event_take_message")
				check(scene._cleared_encounters.has("ch2_event/event"),
					"chapter_2_event_encounter_settles")
				check(scene._cleared_in_chapter == clears_before + 1,
					"chapter_2_event_counts_once")
				check(scene.run_state.rng.state == rng_before,
					"chapter_2_event_take_keeps_run_rng")

				# The settled node survives through the real run-save file. A
				# resumed run restores cleared_encounters before the room loads,
				# so the entry trigger stays quiet there too.
				if flow != null:
					var old_auto_save: bool = flow.auto_save
					var old_run_path: String = flow.run_save_path
					var event_save_path := "user://test_playability_ch2_event_run.cfg"
					flow.auto_save = true
					flow.run_save_path = event_save_path
					check(scene.save_run_now(), "chapter_2_event_saves")
					var event_save := RunSave.read(event_save_path)
					var saved_clears: Array = event_save.get("progress", {}).get(
						"cleared_encounters", [])
					check(saved_clears.has("ch2_event/event"),
						"chapter_2_event_save_marks_node")
					RunSave.clear(event_save_path)
					flow.auto_save = old_auto_save
					flow.run_save_path = old_run_path

				# Settled node: re-entering the region neither reopens the page
				# nor pays again, and the clear progress stays put.
				await mds.load_room("ch2_event")
				check(await _wait_room_id(mds, "ch2_event"), "chapter_2_event_reloads")
				await create_timer(1.2).timeout
				check(not scene._story.is_open(),
					"chapter_2_event_no_retrigger_after_settle")
				check(not paused, "chapter_2_event_no_retrigger_pause")
				check(scene._cleared_in_chapter == clears_before + 1,
					"chapter_2_event_no_double_count")
				check(not scene._reward_ui.visible,
					"chapter_2_event_no_duplicate_reward")

				# Exercise the "read" effect through the same entry trigger. The
				# rewind is test scaffolding only: it restores the pre-choice
				# state so a second fresh page can be checked without a new run.
				scene._cleared_encounters.erase("ch2_event/event")
				scene._cleared_in_chapter -= 1
				scene._event_room_id = ""
				await mds.load_room("ch2_event")
				check(await _wait_room_id(mds, "ch2_event"), "chapter_2_event_read_reloads")
				check(await _wait_story(scene), "chapter_2_event_read_page_opens")
				var decoded_before: int = 0
				if flow != null and flow.profile != null:
					decoded_before = flow.profile.decoded_words.size()
				var pages_before_read: int = scene.run_state.pages
				var corruption_before: int = scene.run_state.corruption
				var corruption_multiplier: float = scene.run_state.corruption_gain_multiplier
				scene._story.choose(0)
				await create_timer(0.3).timeout
				var expected_corruption := mini(corruption_before + maxi(
					int(ceilf(float(Ch2EventData.CORRUPTION_COST) * corruption_multiplier)), 1), 100)
				check(scene.run_state.corruption == expected_corruption,
					"chapter_2_event_reading_pays_corruption")
				# Reading either decodes exactly one owned fragment (no pages) or,
				# when the profile already knows every fragment, pays the fixed
				# fallback pages instead. Both outcomes are part of Ch2EventData's
				# contract; the test profile may be fully decoded or not.
				var decoded_after: int = 0
				if flow != null and flow.profile != null:
					decoded_after = flow.profile.decoded_words.size()
				var decoded_delta: int = decoded_after - decoded_before
				var pages_delta: int = scene.run_state.pages - pages_before_read
				check((decoded_delta == 1 and pages_delta == 0)
					or (decoded_delta == 0 and pages_delta == Ch2EventData.FALLBACK_PAGES),
					"chapter_2_event_reading_pays_word_or_fallback")
				check(scene._cleared_encounters.has("ch2_event/event"),
					"chapter_2_event_read_settles")
				check(scene._cleared_in_chapter == clears_before + 1,
					"chapter_2_event_read_counts_once")
			"ch2_elite":
				check(String(mds.world.get_transition("ch2_elite", "right1").get("room", ""))
					== "ch2_boss", "chapter_2_elite_boss_door")
				check(mds.world.get_transition("ch2_boss", "left1").is_empty(),
					"chapter_2_boss_door_is_one_way")
			"ch2_boss":
				check(is_instance_valid(scene._boss), "chapter_2_boss_spawned")
				check(scene._mds_boss_arena != null, "chapter_2_boss_arena_registered")
				check(plan.wave_for("ch2_boss", "ch2_boss/Arena").is_empty(),
					"chapter_2_boss_consumes_no_ordinary_wave")
				check(not plan.room("ch2_boss").has("wave"),
					"chapter_2_boss_region_authors_no_wave")
				var lung := scene._boss as LungBellGuardian
				check(lung != null, "chapter_2_boss_uses_lung_guardian_scene")
				if lung != null:
					check(lung.is_inhaling(), "chapter_2_boss_starts_inhaling")
					check(lung.damage_multiplier()
						== LungBellGuardian.INHALE_DAMAGE_MULT,
						"chapter_2_boss_breath_mechanic_active")
					check(lung.global_position.y < _ground_surface_y(room),
						"chapter_2_boss_spawns_above_ground")
					if scene._mds_boss_arena != null:
						scene.player.global_position = scene._mds_boss_arena.global_position
						scene._update_room_locks()
						var waves_before := lung.get_breath_wave_count()
						lung.breath_left = 0.01
						# 120 FPS: one frame advances the timer by ~0.0083 s.
						for _frame in 4:
							await process_frame
						check(lung.get_breath_wave_count() > waves_before,
							"chapter_2_boss_exhale_spawns_wave_in_world")

	# Two encounters in one region settle under their own node ids, exactly once.
	await mds.load_room("ch2_branch_a")
	check(await _wait_room_id(mds, "ch2_branch_a"), "chapter_2_branch_a_reloads")
	var branch: Node = mds.room_node
	var arena_a := branch.get_node_or_null("Arena") as ArenaRoom
	var arena_b := branch.get_node_or_null("Arena2") as ArenaRoom
	check(arena_a != null and arena_b != null, "chapter_2_branch_a_two_arenas")
	if arena_a != null and arena_b != null:
		var before: int = scene._cleared_in_chapter
		# Clear the first encounter through the real arena: lock it, kill the
		# spawned wave (including the queued second group), and settle once.
		scene.player.global_position = arena_a.global_position
		scene._update_room_locks()
		check(arena_a.is_locked(), "chapter_2_first_encounter_locks")
		for attempt in 5:
			for enemy in arena_a.get_node(ArenaRoom.ENEMIES_NODE).get_children():
				if enemy is Enemy and not enemy.dead:
					enemy.take_damage(100000)
			await create_timer(0.4).timeout
			if arena_a.is_cleared():
				break
		check(arena_a.is_cleared(), "chapter_2_first_encounter_cleared_in_combat")
		check(await _wait_reward(scene), "chapter_2_first_encounter_reward")
		check(scene._cleared_in_chapter == before + 1, "chapter_2_first_encounter_counts")
		check(scene._cleared_encounters.has("ch2_branch_a/Arena"),
			"chapter_2_first_encounter_id")
		check(not scene._cleared_encounters.has("ch2_branch_a/Arena2"),
			"chapter_2_second_encounter_not_marked")
		scene._reward_ui._choose(0)
		await process_frame
		# The second encounter owns its own entry zone: standing in it locks
		# only that arena, never the whole region.
		scene.player.global_position = arena_b.global_position + Vector2(0, -120)
		await process_frame
		await process_frame
		check(arena_b.is_locked(), "chapter_2_second_encounter_locks_alone")
		check(not arena_a.is_locked(), "chapter_2_first_encounter_does_not_lock")
		for attempt in 5:
			for enemy in arena_b.get_node(ArenaRoom.ENEMIES_NODE).get_children():
				if enemy is Enemy and not enemy.dead:
					enemy.take_damage(100000)
			await create_timer(0.4).timeout
			if arena_b.is_cleared():
				break
		check(arena_b.is_cleared(), "chapter_2_second_encounter_cleared_in_combat")
		check(await _wait_reward(scene), "chapter_2_second_encounter_reward")
		check(scene._cleared_in_chapter == before + 2, "chapter_2_second_encounter_counts")
		check(scene._cleared_encounters.has("ch2_branch_a/Arena2"),
			"chapter_2_second_encounter_id")
		scene._reward_ui._choose(0)
		await process_frame
		var settled: int = scene._cleared_in_chapter
		arena_b.cleared.emit()
		await process_frame
		check(scene._cleared_in_chapter == settled, "chapter_2_encounter_settles_once")

	for encounter_id in plan.encounter_ids():
		if scene._cleared_encounters.has(encounter_id):
			continue
		check(scene._mark_encounter_cleared(encounter_id.get_slice("/", 0), encounter_id),
			"chapter_2_marks_encounter_%s" % encounter_id)
	check(scene._cleared_in_chapter == 7, "chapter_2_all_seven_encounters_cleared")
	check(scene._cleared_in_chapter == plan.clear_target(),
		"chapter_2_clears_match_plan_target")

	# Cleared encounters stay cleared on reload, per node id: the region never
	# respawns as a whole and no cleared arena is registered for locking.
	await mds.load_room("ch2_branch_a")
	check(await _wait_room_id(mds, "ch2_branch_a"), "chapter_2_cleared_branch_reloads")
	var cleared_room: Node = mds.room_node
	var cleared_a := cleared_room.get_node_or_null("Arena") as ArenaRoom
	var cleared_b := cleared_room.get_node_or_null("Arena2") as ArenaRoom
	check(cleared_a != null and cleared_a.enemy_count() == 0,
		"chapter_2_cleared_encounter_not_respawned")
	check(cleared_b != null and cleared_b.enemy_count() == 0,
		"chapter_2_cleared_second_encounter_not_respawned")
	check(not scene._rooms.has(cleared_a) and not scene._rooms.has(cleared_b),
		"chapter_2_cleared_encounters_not_registered")

	# The boss outro/choice still works on the new region world (test-only start).
	await mds.load_room("ch2_boss")
	check(await _wait_room_id(mds, "ch2_boss"), "chapter_2_boss_reloads")
	check(is_instance_valid(scene._boss), "chapter_2_boss_respawns")
	if is_instance_valid(scene._boss):
		var boss_arena := mds.room_node.get_node_or_null("Arena") as ArenaRoom
		if boss_arena != null:
			scene.player.global_position = boss_arena.global_position
			scene._update_room_locks()
		var entrance_line := BossEntranceData.pick(scene.run_state.run_seed, 1)
		check(BossEntranceData.variants(1).has(entrance_line),
			"chapter_2_boss_entrance_uses_chapter_2_copy")
		check(scene.hud.get_message_text() == entrance_line,
			"chapter_2_boss_entrance_matches_seed")
		var boss_chapter := CampaignData.chapter(1)
		for phase in [2, 3]:
			var phase_line := BossPhaseData.pick(scene.run_state.run_seed, phase, 1)
			scene._on_boss_phase(boss_chapter, phase)
			check(BossPhaseData.variants(phase, 1).has(phase_line),
				"chapter_2_boss_phase_%d_uses_chapter_2_copy" % phase)
			check(scene.hud.get_message_text()
				== "%s · 第 %d 阶段：%s" % [boss_chapter["boss_name"], phase, phase_line],
				"chapter_2_boss_phase_%d_matches_seed" % phase)
		scene.player._invulnerable_left = 100
		scene._boss.take_damage(100000)
		# Pass 86: pausing during the 1.2 s beat must delay the required pick.
		# It used to open behind the pause menu (layer 100), where the pick was
		# invisible and Resume was refused, leaving the page stuck.
		await create_timer(0.3).timeout
		scene._toggle_pause()
		await create_timer(1.5).timeout
		check(not scene._authority_choice.is_open(), "chapter_2_authority_waits_for_pause")
		check(scene.pause_menu.is_open() and paused, "chapter_2_authority_pause_holds")
		scene._toggle_pause()
		# Pass 86: the door the dying boss just unlocked is live during the beat.
		# Opening the required pick under the MDS fade (layer 100, above $UI)
		# would freeze the transition with the pick invisible on a black screen.
		mds.load_room("ch2_entry")
		await create_timer(0.15).timeout
		check(mds.changing_room, "chapter_2_authority_transition_runs")
		check(not scene._authority_choice.is_open(), "chapter_2_authority_waits_for_transition")
		check(await _wait_room_id(mds, "ch2_entry"), "chapter_2_authority_transition_finishes")
		check(not scene._authority_choice.is_open() and not paused,
			"chapter_2_authority_waits_for_fade_in")
		check(await _wait_authority_choice(scene), "chapter_2_authority_choice_opens")
		await process_frame
		check(not scene.hud.visible, "chapter_2_authority_hides_hud")
		var flow := root.get_node_or_null("Flow") as GameFlow
		var profile: Profile = flow.profile if flow != null else null
		var expected_pool := AuthorityController.build_pool(
			scene._chapter_plan.authority_pool, scene.run_state, profile, scene._records)
		var pool_ids: Array[StringName] = []
		for authority in expected_pool:
			pool_ids.append(authority.id)
		check(pool_ids.has(&"revive"), "chapter_2_authority_offers_revive")
		check(pool_ids.has(&"rewrite"), "chapter_2_authority_offers_rewrite")
		check(scene._authority_choice.get_button_count() == expected_pool.size(),
			"chapter_2_authority_choice_matches_pool")
		scene._authority_choice._choose(0)
		await create_timer(1.5).timeout
		check(scene.run_state.authority != null, "chapter_2_authority_granted")
		check(scene._story.is_open(), "chapter_2_outro")
		scene._story.close()
		await process_frame
		check(scene._story.is_open(), "chapter_2_choice")
		scene._story.choose(0)
		await create_timer(1.2).timeout
		# Pass 80: the Chapter 2 ending now hands off into Chapter 3 in place.
		# The authored choice effects are unchanged; the Chapter 3 intro replaces
		# the ending screen and the campaign keeps running.
		var audio := root.get_node_or_null("Audio") as AudioManager
		check(scene._chapter == 2, "chapter_2_hands_off_to_chapter_3")
		check(not scene._finished, "chapter_2_does_not_finish_campaign")
		check(not scene.ending_screen.visible, "chapter_2_no_ending_screen")
		check(scene._story.is_open() and not scene._story._choice_mode,
			"chapter_3_intro_opens_after_chapter_2")
		check(scene._story._eyebrow.text.contains("第 3 章"),
			"chapter_3_handoff_intro_eyebrow")
		check(scene._story._body.text.contains(String(CampaignData.chapter(2)["intro"][0])),
			"chapter_3_intro_uses_chapter_3_lines")
		check(scene._chapter_plan != null and scene._chapter_plan.big_map,
			"chapter_3_plan_active_after_handoff")
		check(audio != null
			and audio._current_music == String(CampaignData.chapter(2)["music"]),
			"chapter_3_music_on_handoff")
		check(audio != null and audio._voice.stream != null
			and String(audio._voice.stream.resource_path).ends_with("ch3_intro.ogg"),
			"chapter_3_intro_voice_on_handoff")


## Chapter 4 big map through the real campaign route (pass 91): the Chapter 3
## ending hands off into the Chapter 4 intro, the plan's entry region spawns the
## player on its authored SpawnPoint, a real encounter clear advances the chapter
## counter, the event region settles once, and Boss 4 ends the campaign. The
## Chapter 4 plan/world are the routed ones — nothing is mounted here.
func _test_ch4_big_map(scene) -> void:
	var mds = scene._mds_world
	var plan: ChapterPlanData = scene._chapter_plan
	check(plan != null and plan.big_map, "chapter_4_plan_is_big_map")
	if plan == null or not plan.big_map:
		return
	check(String(plan.resource_path).ends_with("chapter_4_demo.tres"),
		"chapter_4_loads_its_own_plan")
	check(mds.current_room == "ch4_entry", "chapter_4_starts_at_plan_entry")
	check(mds.current_room == plan.start_region(), "chapter_4_start_room_comes_from_plan")
	check(scene._chapter_clear_target() == 7, "chapter_4_clear_target_seven")
	check(scene._chapter_progress_total() == 8, "chapter_4_progress_total_includes_boss")
	check(is_equal_approx(scene._fall_limit_local, 1680.0),
		"chapter_4_entry_fall_plane_from_plan")
	check(scene._map_overlay.title_text() == "笑面剧场地图", "chapter_4_map_title_region")
	check(scene._map_overlay.title_text() != "档案馆地图",
		"chapter_4_map_title_not_chapter_1")
	check(scene._cleared_in_chapter == 0, "chapter_4_starts_with_clear_zero")
	var entry_room := mds.room_node as MDSBigRoom
	check(entry_room != null, "chapter_4_entry_uses_big_room_pipeline")
	if entry_room == null:
		return
	check(entry_room.validation_errors.is_empty(), "chapter_4_entry_geometry_valid")
	var spawn := entry_room.get_node_or_null("SpawnPoint") as Marker2D
	check(spawn != null, "chapter_4_entry_spawn_marker")
	if spawn != null:
		check(scene.player.global_position.distance_to(spawn.global_position) < 2.0,
			"chapter_4_entry_spawn_position")
	await physics_frame
	check(scene.player.is_on_floor(), "chapter_4_entry_player_on_floor")

	# A real combat encounter: the branch arena locks, the spawned wave dies, and
	# the clear counts once against the plan target.
	await mds.load_room("ch4_branch_a")
	check(await _wait_room_id(mds, "ch4_branch_a"), "chapter_4_branch_a_loads")
	var branch := mds.room_node as MDSBigRoom
	var arena: ArenaRoom = null
	if branch != null:
		arena = branch.get_node_or_null("Arena") as ArenaRoom
	check(arena != null, "chapter_4_branch_a_arena_present")
	if arena != null:
		scene.player.global_position = arena.global_position
		scene._update_room_locks()
		check(arena.is_locked(), "chapter_4_first_encounter_locks")
		for attempt in 5:
			for enemy in arena.get_node(ArenaRoom.ENEMIES_NODE).get_children():
				if enemy is Enemy and not enemy.dead:
					enemy.take_damage(100000)
			await create_timer(0.4).timeout
			if arena.is_cleared():
				break
		check(arena.is_cleared(), "chapter_4_first_encounter_cleared_in_combat")
		check(await _wait_reward(scene), "chapter_4_first_encounter_reward")
		check(scene._cleared_in_chapter == 1, "chapter_4_first_encounter_counts")
		check(scene._cleared_encounters.has("ch4_branch_a/Arena"),
			"chapter_4_first_encounter_id")
		scene._reward_ui._choose(0)
		await process_frame

	await _test_ch4_bigmap_event_trigger(scene)
	await _test_ch4_bigmap_boss(scene)


## Chapter 3 big map through the real campaign route (pass 80): the Chapter 2
## ending hands off into the Chapter 3 intro, the plan's entry region spawns the
## player on its authored SpawnPoint, a real encounter clear advances the
## chapter counter, the event region settles once, and Boss 3 closes the chapter
## without entering Chapter 4.
func _test_ch3_big_map(scene) -> void:
	var mds = scene._mds_world
	var plan: ChapterPlanData = scene._chapter_plan
	check(plan != null and plan.big_map, "chapter_3_plan_is_big_map")
	if plan == null or not plan.big_map:
		return
	check(mds.current_room == "ch3_entry", "chapter_3_starts_at_plan_entry")
	check(mds.current_room == plan.start_region(), "chapter_3_start_room_comes_from_plan")
	check(scene._chapter_clear_target() == 7, "chapter_3_clear_target_seven")
	check(scene._chapter_progress_total() == 8, "chapter_3_progress_total_includes_boss")
	check(is_equal_approx(scene._fall_limit_local, 1680.0),
		"chapter_3_entry_fall_plane_from_plan")
	check(scene._map_overlay.title_text() == "无光海地图", "chapter_3_map_title_region")
	check(scene._map_overlay.title_text() != "档案馆地图",
		"chapter_3_map_title_not_chapter_1")
	check(scene._cleared_in_chapter == 0, "chapter_3_starts_with_clear_zero")
	var entry_room := mds.room_node as MDSBigRoom
	check(entry_room != null, "chapter_3_entry_uses_big_room_pipeline")
	if entry_room == null:
		return
	check(entry_room.validation_errors.is_empty(), "chapter_3_entry_geometry_valid")
	var spawn := entry_room.get_node_or_null("SpawnPoint") as Marker2D
	check(spawn != null, "chapter_3_entry_spawn_marker")
	if spawn != null:
		check(scene.player.global_position.distance_to(spawn.global_position) < 2.0,
			"chapter_3_entry_spawn_position")
	await physics_frame
	check(scene.player.is_on_floor(), "chapter_3_entry_player_on_floor")

	# A real combat encounter: the branch arena locks, the spawned wave dies, and
	# the clear counts once against the plan target.
	await mds.load_room("ch3_branch_a")
	check(await _wait_room_id(mds, "ch3_branch_a"), "chapter_3_branch_a_loads")
	var branch := mds.room_node as MDSBigRoom
	var arena: ArenaRoom = null
	if branch != null:
		arena = branch.get_node_or_null("Arena") as ArenaRoom
	check(arena != null, "chapter_3_branch_a_arena_present")
	if arena != null:
		scene.player.global_position = arena.global_position
		scene._update_room_locks()
		check(arena.is_locked(), "chapter_3_first_encounter_locks")
		for attempt in 5:
			for enemy in arena.get_node(ArenaRoom.ENEMIES_NODE).get_children():
				if enemy is Enemy and not enemy.dead:
					enemy.take_damage(100000)
			await create_timer(0.4).timeout
			if arena.is_cleared():
				break
		check(arena.is_cleared(), "chapter_3_first_encounter_cleared_in_combat")
		check(await _wait_reward(scene), "chapter_3_first_encounter_reward")
		check(scene._cleared_in_chapter == 1, "chapter_3_first_encounter_counts")
		check(scene._cleared_encounters.has("ch3_branch_a/Arena"),
			"chapter_3_first_encounter_id")
		scene._reward_ui._choose(0)
		await process_frame

	await _test_ch3_bigmap_event_trigger(scene)
	await _test_ch3_bigmap_boss(scene)


## Chapter 3 event region. The region-level entry trigger added for Chapter 2 is
## chapter-agnostic — a big-map region whose plan type is `event` and whose
## chapter authors event data — so the Chapter 3 plan needs no separate trigger.
## Since pass 80 the campaign itself loads the Chapter 3 plan and big-map world,
## so this walks the live routed world into `ch3_event`.
func _test_ch3_bigmap_event_trigger(scene) -> void:
	var plan: ChapterPlanData = scene._chapter_plan
	check(plan != null and plan.big_map, "chapter_3_plan_is_big_map")
	if plan == null or not plan.big_map:
		return
	var flow := root.get_node_or_null("Flow") as GameFlow
	var world := scene._mds_world as MDSWorldGame
	check(world != null, "chapter_3_event_world_is_routed")
	if world == null:
		return
	await world.load_room("ch3_event")
	check(await _wait_room_id(world, "ch3_event"), "chapter_3_event_region_loads")
	var room := world.room_node as MDSBigRoom
	check(room != null, "chapter_3_event_region_uses_big_room_pipeline")
	check(scene._chapter_clear_target() == 7, "chapter_3_event_clear_target_seven")
	check(scene._chapter_progress_total() == 8, "chapter_3_event_progress_includes_boss")
	check(is_equal_approx(scene._fall_limit_local, 1680.0),
		"chapter_3_event_fall_plane_from_plan")

	# Entering the region opens the Chapter 3 page through the same trigger the
	# Chapter 2 region uses. Copy comes from Ch3EventData keyed by the plan node
	# id, and resolving the variant must not roll the run RNG.
	var rng_before: int = scene.run_state.rng.state
	var page_open: bool = await _wait_story(scene)
	check(page_open, "chapter_3_event_page_opens")
	if not page_open:
		scene._teardown_mds(false)
		scene._chapter_plan = null
		return
	check(scene.run_state.rng.state == rng_before, "chapter_3_event_page_keeps_run_rng")
	var expected_event := Ch3EventData.pick(scene.run_state.run_seed, "ch3_event/event")
	check(not expected_event.is_empty(), "chapter_3_event_variant_resolves")
	check(scene._story._eyebrow.text == String(expected_event.get("eyebrow", "")),
		"chapter_3_event_uses_chapter_3_copy")
	check(scene._story._title.text == String(expected_event.get("title", "")),
		"chapter_3_event_title_matches_seed")
	check(scene._story._options.get_child_count() == 2,
		"chapter_3_event_has_two_choices")
	if scene._story._options.get_child_count() == 2:
		check((scene._story._options.get_child(0) as Button).text.begins_with(
			String(expected_event.get("read_label", ""))), "chapter_3_event_read_label")
		check((scene._story._options.get_child(1) as Button).text.begins_with(
			String(expected_event.get("take_label", ""))), "chapter_3_event_take_label")
	var pages_before: int = scene.run_state.pages
	var clears_before: int = scene._cleared_in_chapter
	scene._story.choose(1)
	await create_timer(0.2).timeout
	check(scene.run_state.pages == pages_before + Ch3EventData.PAGES_REWARD,
		"chapter_3_event_taking_pays_pages")
	check(scene.hud.get_message_text()
		== String(expected_event.get("take_message", "")) % Ch3EventData.PAGES_REWARD,
		"chapter_3_event_take_message")
	check(scene._cleared_encounters.has("ch3_event/event"),
		"chapter_3_event_encounter_settles")
	check(scene._cleared_in_chapter == clears_before + 1,
		"chapter_3_event_counts_once")
	check(scene.run_state.rng.state == rng_before, "chapter_3_event_take_keeps_run_rng")

	# The settled node survives through the real run-save file under the same
	# key the trigger reads.
	if flow != null:
		var old_auto_save: bool = flow.auto_save
		var old_run_path: String = flow.run_save_path
		var event_save_path := "user://test_playability_ch3_event_run.cfg"
		flow.auto_save = true
		flow.run_save_path = event_save_path
		check(scene.save_run_now(), "chapter_3_event_saves")
		var event_save := RunSave.read(event_save_path)
		var saved_clears: Array = event_save.get("progress", {}).get(
			"cleared_encounters", [])
		check(saved_clears.has("ch3_event/event"), "chapter_3_event_save_marks_node")
		RunSave.clear(event_save_path)
		flow.auto_save = old_auto_save
		flow.run_save_path = old_run_path

	# A settled node stays quiet: re-entering neither reopens the page nor pays.
	await world.load_room("ch3_event")
	check(await _wait_room_id(world, "ch3_event"), "chapter_3_event_reloads")
	await create_timer(1.2).timeout
	check(not scene._story.is_open(), "chapter_3_event_no_retrigger_after_settle")
	check(not paused, "chapter_3_event_no_retrigger_pause")
	check(scene._cleared_in_chapter == clears_before + 1,
		"chapter_3_event_no_double_count")
	check(not scene._reward_ui.visible, "chapter_3_event_no_duplicate_reward")

	# Exercise the "read" effect through the same entry trigger. The rewind is
	# test scaffolding only: it restores the pre-choice state so a second fresh
	# page can be checked without a new run.
	scene._cleared_encounters.erase("ch3_event/event")
	scene._cleared_in_chapter -= 1
	scene._event_room_id = ""
	await world.load_room("ch3_event")
	check(await _wait_room_id(world, "ch3_event"), "chapter_3_event_read_reloads")
	var read_open: bool = await _wait_story(scene)
	check(read_open, "chapter_3_event_read_page_opens")
	if not read_open:
		return
	var decoded_before: int = 0
	if flow != null and flow.profile != null:
		decoded_before = flow.profile.decoded_words.size()
	var pages_before_read: int = scene.run_state.pages
	var corruption_before: int = scene.run_state.corruption
	var corruption_multiplier: float = scene.run_state.corruption_gain_multiplier
	scene._story.choose(0)
	await create_timer(0.3).timeout
	var expected_corruption := mini(corruption_before + maxi(
		int(ceilf(float(Ch3EventData.CORRUPTION_COST) * corruption_multiplier)), 1), 100)
	check(scene.run_state.corruption == expected_corruption,
		"chapter_3_event_reading_pays_corruption")
	# Reading either decodes exactly one owned fragment (no pages) or, when the
	# profile already knows every fragment, pays the fixed fallback pages.
	var decoded_after: int = 0
	if flow != null and flow.profile != null:
		decoded_after = flow.profile.decoded_words.size()
	var decoded_delta: int = decoded_after - decoded_before
	var pages_delta: int = scene.run_state.pages - pages_before_read
	check((decoded_delta == 1 and pages_delta == 0)
		or (decoded_delta == 0 and pages_delta == Ch3EventData.FALLBACK_PAGES),
		"chapter_3_event_reading_pays_word_or_fallback")
	check(scene._cleared_encounters.has("ch3_event/event"),
		"chapter_3_event_read_settles")
	check(scene._cleared_in_chapter == clears_before + 1,
		"chapter_3_event_read_counts_once")

	# Leave the routed world in place for the boss leg; it keeps the event node
	# settled exactly as the campaign would.
	scene._event_room_id = ""


## Chapter 4 event region. The region-level entry trigger added with Chapter 2 is
## chapter-agnostic — a big-map region whose plan type is `event` and whose
## chapter authors event data — so the Chapter 4 plan needs no separate trigger.
## Since pass 91 the campaign itself loads the Chapter 4 plan and big-map world,
## so this walks the live routed world into `ch4_event`.
func _test_ch4_bigmap_event_trigger(scene) -> void:
	var plan: ChapterPlanData = scene._chapter_plan
	check(plan != null and plan.big_map, "chapter_4_event_plan_is_big_map")
	if plan == null or not plan.big_map:
		return
	# Lock the route pass 91 installs: all four chapters load their big-map
	# plans/worlds, the legacy Chapter 4 world stays on disk but unrouted, and
	# the Chapter 4 plan keeps its wired waves / 7-clear target / boss scene. No
	# Chapter 4-only trigger code exists either.
	var game_script := load("res://scripts/game.gd") as GDScript
	var constants: Dictionary = game_script.get_script_constant_map() if game_script != null else {}
	var plan_paths: Array = constants.get("CHAPTER_PLAN_PATHS", [])
	var world_files: Array = constants.get("MDS_WORLD_FILES", [])
	var world_scenes: Array = constants.get("MDS_CHAPTER_SCENES", [])
	check(plan_paths.size() == 4, "chapter_4_game_keeps_four_plan_slots")
	if plan_paths.size() == 4:
		check(String(plan_paths[3]).ends_with("chapter_4_demo.tres"),
			"chapter_4_plan_slot_wired")
		check(String(plan_paths[2]).ends_with("chapter_3_demo.tres"),
			"chapter_3_plan_slot_wired")
		check(String(plan_paths[1]).ends_with("chapter_2_demo.tres"),
			"chapter_2_plan_slot_unchanged")
		check(String(plan_paths[0]).ends_with("chapter_1_demo.tres"),
			"chapter_1_plan_slot_unchanged")
	if world_files.size() == 4:
		check(String(world_files[3]).ends_with("chapter_4_bigmap.mdsworld.json"),
			"chapter_4_loads_big_map_world")
		check(String(world_files[2]).ends_with("chapter_3_bigmap.mdsworld.json"),
			"chapter_3_loads_big_map_world")
	if world_scenes.size() == 4:
		check((world_scenes[3] as PackedScene).resource_path
			== "res://scenes/mds/chapter_4_bigmap_world.tscn",
			"chapter_4_uses_big_map_world_scene")
	check(plan.clear_target() == 7, "chapter_4_event_clear_target_seven")
	check(plan.encounter_ids().size() == 7, "chapter_4_event_encounters_unchanged")
	check(plan.content_pending == false, "chapter_4_event_waves_stay_wired")
	check(plan.wave_for("ch4_branch_a", "ch4_branch_a/Arena").size() == 2,
		"chapter_4_event_wave_table_unchanged")
	check(plan.boss_scene != null
		and plan.boss_scene.resource_path == "res://scenes/bosses/smiling_archivist.tscn",
		"chapter_4_event_boss_scene_routed_but_dormant")
	check(FileAccess.file_exists("res://scenes/mds/chapter_4.mdsworld.json"),
		"chapter_4_old_world_still_present")
	check(FileAccess.file_exists("res://scenes/mds/chapter_4_world.tscn"),
		"chapter_4_old_world_scene_still_present")
	check(FileAccess.file_exists("res://scenes/mds/chapter_4_bigmap.mdsworld.json"),
		"chapter_4_region_world_still_present")
	var game_source := FileAccess.get_file_as_string("res://scripts/game.gd")
	check(not game_source.contains("ch4_event"), "chapter_4_has_no_dedicated_event_trigger")
	check(game_source.contains("chapter_4_bigmap"),
		"chapter_4_region_world_is_routed")
	# Chapters 1–3 keep their event numbers; only the Chapter 4 table is new.
	# Their own suites cover the full copy and the Chapter 1 room trigger.
	check(Ch1EventData.CORRUPTION_COST == 8 and Ch1EventData.PAGES_REWARD == 12
		and Ch1EventData.FALLBACK_PAGES == 6, "chapter_1_event_numbers_unchanged")
	check(Ch2EventData.CORRUPTION_COST == 8 and Ch2EventData.PAGES_REWARD == 12
		and Ch2EventData.FALLBACK_PAGES == 6, "chapter_2_event_numbers_unchanged")
	check(Ch3EventData.CORRUPTION_COST == 8 and Ch3EventData.PAGES_REWARD == 12
		and Ch3EventData.FALLBACK_PAGES == 6, "chapter_3_event_numbers_unchanged")

	var flow := root.get_node_or_null("Flow") as GameFlow
	var world := scene._mds_world as MDSWorldGame
	check(world != null, "chapter_4_event_world_is_routed")
	if world == null:
		return
	await world.load_room("ch4_event")
	check(await _wait_room_id(world, "ch4_event"), "chapter_4_event_region_loads")
	var room := world.room_node as MDSBigRoom
	check(room != null, "chapter_4_event_region_uses_big_room_pipeline")
	# The routed plan drives the clear target and the fall plane.
	check(scene._chapter_clear_target() == 7, "chapter_4_event_clear_target_from_plan")
	check(scene._chapter_progress_total() == 8, "chapter_4_event_progress_includes_boss")
	check(is_equal_approx(scene._fall_limit_local, 1680.0),
		"chapter_4_event_fall_plane_from_plan")

	# Entering the region opens the Chapter 4 page through the same trigger the
	# Chapter 2/3 regions use. Copy comes from Ch4EventData keyed by the plan
	# node id, and resolving the variant must not roll the run RNG.
	var rng_before: int = scene.run_state.rng.state
	var page_open: bool = await _wait_story(scene)
	check(page_open, "chapter_4_event_page_opens")
	if not page_open:
		return
	check(scene.run_state.rng.state == rng_before, "chapter_4_event_page_keeps_run_rng")
	var expected_event := Ch4EventData.pick(scene.run_state.run_seed, "ch4_event/event")
	check(not expected_event.is_empty(), "chapter_4_event_variant_resolves")
	check(scene._story._eyebrow.text == String(expected_event.get("eyebrow", "")),
		"chapter_4_event_uses_chapter_4_copy")
	check(scene._story._title.text == String(expected_event.get("title", "")),
		"chapter_4_event_title_matches_seed")
	check(scene._story._options.get_child_count() == 2,
		"chapter_4_event_has_two_choices")
	if scene._story._options.get_child_count() == 2:
		check((scene._story._options.get_child(0) as Button).text.begins_with(
			String(expected_event.get("read_label", ""))), "chapter_4_event_read_label")
		check((scene._story._options.get_child(1) as Button).text.begins_with(
			String(expected_event.get("take_label", ""))), "chapter_4_event_take_label")
	var pages_before: int = scene.run_state.pages
	var clears_before: int = scene._cleared_in_chapter
	scene._story.choose(1)
	await create_timer(0.2).timeout
	check(scene.run_state.pages == pages_before + Ch4EventData.PAGES_REWARD,
		"chapter_4_event_taking_pays_pages")
	check(scene.hud.get_message_text()
		== String(expected_event.get("take_message", "")) % Ch4EventData.PAGES_REWARD,
		"chapter_4_event_take_message")
	check(scene._cleared_encounters.has("ch4_event/event"),
		"chapter_4_event_encounter_settles")
	check(scene._cleared_in_chapter == clears_before + 1,
		"chapter_4_event_counts_once")
	# The HUD denominator comes from the plan (7 encounters + boss) and the
	# numerator counts this chapter's clears, including the encounter the chain
	# fought before the event region.
	var progress_label := scene.hud.find_child("Progress", true, false) as Label
	check(progress_label != null
		and progress_label.text == "档案  %d / 8" % (clears_before + 1),
		"chapter_4_event_hud_progress_counts_clears")
	check(scene.run_state.rng.state == rng_before, "chapter_4_event_take_keeps_run_rng")

	# The settled node survives through the real run-save file under the same
	# key the trigger reads.
	if flow != null:
		var old_auto_save: bool = flow.auto_save
		var old_run_path: String = flow.run_save_path
		var event_save_path := "user://test_playability_ch4_event_run.cfg"
		flow.auto_save = true
		flow.run_save_path = event_save_path
		check(scene.save_run_now(), "chapter_4_event_saves")
		var event_save := RunSave.read(event_save_path)
		var saved_clears: Array = event_save.get("progress", {}).get(
			"cleared_encounters", [])
		check(saved_clears.has("ch4_event/event"), "chapter_4_event_save_marks_node")
		RunSave.clear(event_save_path)
		flow.auto_save = old_auto_save
		flow.run_save_path = old_run_path

	# A settled node stays quiet: re-entering neither reopens the page nor pays.
	await world.load_room("ch4_event")
	check(await _wait_room_id(world, "ch4_event"), "chapter_4_event_reloads")
	await create_timer(1.2).timeout
	check(not scene._story.is_open(), "chapter_4_event_no_retrigger_after_settle")
	check(not paused, "chapter_4_event_no_retrigger_pause")
	check(scene._cleared_in_chapter == clears_before + 1,
		"chapter_4_event_no_double_count")
	check(not scene._reward_ui.visible, "chapter_4_event_no_duplicate_reward")

	# Exercise the "read" effect through the same entry trigger. The rewind is
	# test scaffolding only: it restores the pre-choice state so a second fresh
	# page can be checked without a new run.
	scene._cleared_encounters.erase("ch4_event/event")
	scene._cleared_in_chapter -= 1
	scene._event_room_id = ""
	await world.load_room("ch4_event")
	check(await _wait_room_id(world, "ch4_event"), "chapter_4_event_read_reloads")
	var read_open: bool = await _wait_story(scene)
	check(read_open, "chapter_4_event_read_page_opens")
	if not read_open:
		return
	var decoded_before: int = 0
	if flow != null and flow.profile != null:
		decoded_before = flow.profile.decoded_words.size()
	var pages_before_read: int = scene.run_state.pages
	var corruption_before: int = scene.run_state.corruption
	var corruption_multiplier: float = scene.run_state.corruption_gain_multiplier
	# Test scaffolding only: park the purify_flow relic's five-second timer so a
	# tick cannot strip a point inside the 0.3 s resolve window. The event cost is
	# still asserted exactly.
	scene.relic_effects._purify_seconds = 0.0
	scene._story.choose(0)
	await create_timer(0.3).timeout
	var expected_corruption := mini(corruption_before + maxi(
		int(ceilf(float(Ch4EventData.CORRUPTION_COST) * corruption_multiplier)), 1), 100)
	check(scene.run_state.corruption == expected_corruption,
		"chapter_4_event_reading_pays_corruption")
	# Reading either decodes exactly one owned fragment (no pages) or, when the
	# profile already knows every fragment, pays the fixed fallback pages.
	var decoded_after: int = 0
	if flow != null and flow.profile != null:
		decoded_after = flow.profile.decoded_words.size()
	var decoded_delta: int = decoded_after - decoded_before
	var pages_delta: int = scene.run_state.pages - pages_before_read
	check((decoded_delta == 1 and pages_delta == 0)
		or (decoded_delta == 0 and pages_delta == Ch4EventData.FALLBACK_PAGES),
		"chapter_4_event_reading_pays_word_or_fallback")
	check(scene._cleared_encounters.has("ch4_event/event"),
		"chapter_4_event_read_settles")
	check(scene._cleared_in_chapter == clears_before + 1,
		"chapter_4_event_read_counts_once")

	# Leave the routed world in place for the boss leg; it keeps the event node
	# settled exactly as the campaign would.
	scene._event_room_id = ""


func _count_nodes_of_type(parent: Node, type_name: String) -> int:
	return _children_of_type(parent, type_name).size()


func _children_of_type(parent: Node, type_name: String) -> Array:
	var out: Array = []
	if parent == null:
		return out
	for child in parent.get_children():
		if child.get_script() == null:
			continue
		var script_path := (child.get_script() as Script).resource_path
		if script_path.get_file().get_basename() == type_name.to_snake_case():
			out.append(child)
	return out


## Chapter 3 boss: the plan routes the LastReader scene, the live boss spawns
## above the region floor, the chapter-3 phase copy is selected with the
## chapter index key, the blank-page window runs on the real boss, and a
## defeated boss stays down on reload. Since pass 80 the campaign itself routes
## this plan and world, so the boss runs on the live routed world.
func _test_ch3_bigmap_boss(scene) -> void:
	var plan: ChapterPlanData = scene._chapter_plan
	check(plan != null and plan.big_map, "chapter_3_boss_plan_is_big_map")
	if plan == null or not plan.big_map:
		return
	check(plan.boss_scene != null, "chapter_3_boss_plan_routes_scene")
	if plan.boss_scene != null:
		check(plan.boss_scene.resource_path == "res://scenes/bosses/last_reader.tscn",
			"chapter_3_boss_plan_scene_is_last_reader")
	# Lock the route: Chapter 3 loads its big-map plan/world (pass 80), Chapter 4
	# is wired too (pass 91), and the Chapter 3 plan keeps its 7 encounters /
	# authored waves / base authority pool.
	var game_script := load("res://scripts/game.gd") as GDScript
	var constants: Dictionary = game_script.get_script_constant_map() if game_script != null else {}
	var plan_paths: Array = constants.get("CHAPTER_PLAN_PATHS", [])
	var world_files: Array = constants.get("MDS_WORLD_FILES", [])
	check(plan_paths.size() == 4, "game_keeps_four_plan_slots")
	if plan_paths.size() == 4:
		check(String(plan_paths[2]).ends_with("chapter_3_demo.tres"),
			"chapter_3_plan_slot_wired")
		check(String(plan_paths[3]).ends_with("chapter_4_demo.tres"),
			"chapter_4_plan_slot_wired")
		check(ResourceLoader.exists("res://resources/chapters/chapter_4_demo.tres"),
			"chapter_4_plan_present")
	check(world_files.size() == 4, "game_keeps_four_world_files")
	if world_files.size() == 4:
		check(String(world_files[2]).ends_with("chapter_3_bigmap.mdsworld.json"),
			"chapter_3_loads_big_map_world")
	check(plan.clear_target() == 7, "chapter_3_clear_target_unchanged")
	check(plan.encounter_ids().size() == 7, "chapter_3_encounters_unchanged")
	check(plan.wave_for("ch3_branch_a", "ch3_branch_a/Arena").size() == 2,
		"chapter_3_wave_table_unchanged")
	var plan_authority_ids: Array[StringName] = []
	for authority in plan.authority_pool:
		plan_authority_ids.append(authority.id)
	check(plan_authority_ids.has(&"revive") and plan_authority_ids.has(&"rewrite"),
		"chapter_3_authority_pool_unchanged")
	var world := scene._mds_world as MDSWorldGame
	check(world != null, "chapter_3_boss_world_is_routed")
	if world == null:
		return
	await world.load_room("ch3_boss")
	check(await _wait_room_id(world, "ch3_boss"), "chapter_3_boss_region_loads")
	var room := world.room_node as MDSBigRoom
	check(room != null, "chapter_3_boss_region_uses_big_room_pipeline")
	await process_frame
	var boss: LastReader = scene._boss as LastReader
	check(boss != null, "chapter_3_boss_spawns")
	check(scene._boss is InkArchivist, "chapter_3_boss_reuses_generic_flow")
	check(not (scene._boss is LungBellGuardian), "chapter_3_boss_is_not_chapter_2")
	check(not (scene._boss is InkArchivistCh1), "chapter_3_boss_is_not_chapter_1")
	if boss == null:
		return
	var chapter := CampaignData.chapter(2)
	check(boss.data.contact_damage == int(chapter["boss_damage"]),
		"chapter_3_boss_damage_from_campaign")
	check(is_equal_approx(boss.data.speed, float(chapter["boss_speed"])),
		"chapter_3_boss_speed_from_campaign")
	var flow := root.get_node_or_null("Flow") as GameFlow
	var difficulty: int = flow.difficulty if flow != null else 0
	var expected_hp := maxi(int(round(float(chapter["boss_hp"])
		* Difficulty.enemy_health(difficulty))), 1)
	check(boss.max_health == expected_hp, "chapter_3_boss_health_from_campaign")
	var arena := room.get_node_or_null("Arena") as ArenaRoom
	check(arena != null, "chapter_3_boss_arena_present")
	if arena != null:
		check(boss.global_position.y < arena.global_position.y,
			"chapter_3_boss_spawns_above_ground")

	# Phase copy uses the chapter-3 table (chapter index mixed into the key), so
	# it never falls back to the Chapter 1/2 lines.
	scene._on_boss_phase(chapter, 2)
	var expected_phase_line := BossPhaseData.pick(scene.run_state.run_seed, 2, 2)
	check(expected_phase_line != "", "chapter_3_boss_phase_line_authored")
	check(scene.hud.get_message_text()
		== "最后的读者 · 第 2 阶段：" + expected_phase_line,
		"chapter_3_boss_phase_uses_chapter_3_copy")

	# The blank-page burst window runs on the live boss.
	boss.max_health = 100
	boss.health = 32
	boss.phase = 2
	boss.check_phase()
	check(boss.phase == 3, "chapter_3_boss_live_phase_three")
	check(boss.is_blank_page_open(), "chapter_3_boss_blank_page_opens")
	check(is_equal_approx(boss.damage_multiplier(), LastReader.BLANK_PAGE_OPEN_MULT),
		"chapter_3_boss_blank_page_exposes")
	boss._process(LastReader.BLANK_PAGE_OPEN_TIME + 0.01)
	check(not boss.is_blank_page_open(), "chapter_3_boss_blank_page_closes")
	check(is_equal_approx(boss.damage_multiplier(), LastReader.BLANK_PAGE_CLOSED_MULT),
		"chapter_3_boss_closed_book_armors")


	# The inherited beats still fire on the live boss: phase 1's odd beat is the
	# page wave (one bolt) and phase 3's ink-rain beat drops three warnings.
	var enemies_root := boss.get_parent()
	boss.max_health = 100
	boss.health = 90
	boss.phase = 1
	boss.attack_cycle = 0
	var bolts_before := _count_nodes_of_type(enemies_root, "HostileBolt")
	boss._perform_attack()
	check(_count_nodes_of_type(enemies_root, "HostileBolt") - bolts_before == 1,
		"chapter_3_boss_live_page_wave")
	boss.phase = 3
	boss.attack_cycle = 2
	var warnings_before := _count_nodes_of_type(enemies_root, "InkWarning")
	boss._perform_attack()
	check(_count_nodes_of_type(enemies_root, "InkWarning") - warnings_before == 3,
		"chapter_3_boss_live_ink_rain")
	for hazard in get_nodes_in_group("hostile_hazards"):
		hazard.queue_free()

	# The Chapter 3 ending: defeating the Last Reader through the real flow
	# grants the authored authority, plays the Chapter 3 outro and choice, then
	# (since pass 91) hands off into the Chapter 4 intro in place.
	if arena != null:
		scene.player.global_position = arena.global_position
		scene._update_room_locks()
	scene.player._invulnerable_left = 100
	boss.take_damage(100000)
	check(await _wait_authority_choice(scene), "chapter_3_authority_choice_opens")
	await process_frame
	check(not scene.hud.visible, "chapter_3_authority_hides_hud")
	var expected_pool := AuthorityController.build_pool(
		plan.authority_pool, scene.run_state, flow.profile if flow != null else null,
		scene._records)
	var pool_ids: Array[StringName] = []
	for authority in expected_pool:
		pool_ids.append(authority.id)
	check(pool_ids.has(&"revive"), "chapter_3_authority_offers_revive")
	check(pool_ids.has(&"rewrite"), "chapter_3_authority_offers_rewrite")
	check(scene._authority_choice.get_button_count() == expected_pool.size(),
		"chapter_3_authority_choice_matches_pool")
	scene._authority_choice._choose(0)
	await create_timer(1.5).timeout
	check(scene.run_state.authority != null, "chapter_3_authority_granted")
	check(scene._story.is_open(), "chapter_3_outro")
	scene._story.close()
	await process_frame
	check(scene._story.is_open(), "chapter_3_choice")
	scene._story.choose(0)
	await create_timer(1.2).timeout
	# Pass 91: the Chapter 3 choice hands off into Chapter 4 in place. The
	# authored choice effects are unchanged; the Chapter 4 intro replaces the
	# ending screen and the campaign keeps running.
	var audio := root.get_node_or_null("Audio") as AudioManager
	check(scene._chapter == 3, "chapter_3_hands_off_to_chapter_4")
	check(not scene._finished, "chapter_3_does_not_finish_campaign")
	check(not scene.ending_screen.visible, "chapter_3_no_ending_screen")
	check(scene._story.is_open() and not scene._story._choice_mode,
		"chapter_4_intro_opens_after_chapter_3")
	check(scene._story._eyebrow.text.contains("第 4 章"),
		"chapter_4_handoff_intro_eyebrow")
	check(scene._story._body.text.contains(String(CampaignData.chapter(3)["intro"][0])),
		"chapter_4_intro_uses_chapter_4_lines")
	check(scene._chapter_plan != null and scene._chapter_plan.big_map
		and String(scene._chapter_plan.resource_path).ends_with("chapter_4_demo.tres"),
		"chapter_4_plan_active_after_handoff")
	check(audio != null
		and audio._current_music == String(CampaignData.chapter(3)["music"]),
		"chapter_4_music_on_handoff")
	check(audio != null and audio._voice.stream != null
		and String(audio._voice.stream.resource_path).ends_with("ch4_intro.ogg"),
		"chapter_4_intro_voice_on_handoff")
	# The Chapter 4 intro is open and the campaign moved on, so the "defeated boss
	# stays down on reload" check cannot replay inside Chapter 3 any more; it lives
	# in `integration_ch3_bigmap._test_boss` (the boss-defeated reload there starts
	# from its own resume checkpoint). Leave the scene in the handoff state the
	# real flow produces: the caller closes the intro and boots Chapter 4.


## Chapter 4 boss: the plan routes the SmilingArchivist scene, the live boss
## spawns above the region floor with the campaign-table stats, the chapter-4
## phase copy is selected with the chapter index key, the authored mirror fan /
## ink rain / rewrite beats fire on the real boss, and a defeated boss stays down
## on reload. Defeating it runs the authored chapter-end chain (authority →
## Chapter 4 outro → authored choice → campaign end), locks that copy and the
## ending rule, and proves the campaign stops at Chapter 4 (chapter_count() == 4,
## no fifth chapter). Since pass 91 the campaign itself routes this plan and
## world, so the boss runs on the live routed world; no dedicated mechanic
## extension (delete-word / copy-weapon / stage traps) lands here.
func _test_ch4_bigmap_boss(scene) -> void:
	var plan: ChapterPlanData = scene._chapter_plan
	check(plan != null and plan.big_map, "chapter_4_boss_plan_is_big_map")
	if plan == null or not plan.big_map:
		return
	check(plan.boss_scene != null, "chapter_4_boss_plan_routes_scene")
	if plan.boss_scene != null:
		check(plan.boss_scene.resource_path == "res://scenes/bosses/smiling_archivist.tscn",
			"chapter_4_boss_plan_scene_is_smiling_archivist")
	# Lock the route pass 91 installs: Chapter 4 loads its plan and big-map
	# world, the legacy Chapter 4 world stays on disk but unrouted, Chapter 3
	# keeps its wired plan/world (pass 80), and the Chapter 4 plan keeps its 7
	# encounters / authored waves / base authority pool.
	var game_script := load("res://scripts/game.gd") as GDScript
	var constants: Dictionary = game_script.get_script_constant_map() if game_script != null else {}
	var plan_paths: Array = constants.get("CHAPTER_PLAN_PATHS", [])
	var world_files: Array = constants.get("MDS_WORLD_FILES", [])
	check(plan_paths.size() == 4, "chapter_4_boss_game_keeps_four_plan_slots")
	if plan_paths.size() == 4:
		check(String(plan_paths[3]).ends_with("chapter_4_demo.tres"),
			"chapter_4_boss_plan_slot_wired")
		check(String(plan_paths[2]).ends_with("chapter_3_demo.tres"),
			"chapter_3_boss_plan_slot_wired")
	check(world_files.size() == 4, "chapter_4_boss_game_keeps_four_world_files")
	if world_files.size() == 4:
		check(String(world_files[3]).ends_with("chapter_4_bigmap.mdsworld.json"),
			"chapter_4_boss_loads_big_map_world")
	check(FileAccess.file_exists("res://scenes/mds/chapter_4.mdsworld.json"),
		"chapter_4_old_world_still_present")
	check(FileAccess.file_exists("res://scenes/mds/chapter_4_world.tscn"),
		"chapter_4_old_world_scene_still_present")
	check(plan.clear_target() == 7, "chapter_4_boss_clear_target_unchanged")
	check(plan.encounter_ids().size() == 7, "chapter_4_boss_encounters_unchanged")
	check(plan.content_pending == false, "chapter_4_boss_waves_stay_wired")
	check(plan.wave_for("ch4_branch_a", "ch4_branch_a/Arena").size() == 2,
		"chapter_4_boss_wave_table_unchanged")
	var plan_authority_ids: Array[StringName] = []
	for authority in plan.authority_pool:
		plan_authority_ids.append(authority.id)
	check(plan_authority_ids.has(&"revive") and plan_authority_ids.has(&"rewrite"),
		"chapter_4_boss_authority_pool_unchanged")

	var world := scene._mds_world as MDSWorldGame
	check(world != null, "chapter_4_boss_world_is_routed")
	if world == null:
		return
	await world.load_room("ch4_boss")
	check(await _wait_room_id(world, "ch4_boss"), "chapter_4_boss_region_loads")
	var room := world.room_node as MDSBigRoom
	check(room != null, "chapter_4_boss_region_uses_big_room_pipeline")
	await process_frame
	var boss: SmilingArchivist = scene._boss as SmilingArchivist
	check(boss != null, "chapter_4_boss_spawns")
	check(scene._boss is InkArchivist, "chapter_4_boss_reuses_generic_flow")
	check(not (scene._boss is LastReader), "chapter_4_boss_is_not_chapter_3")
	check(not (scene._boss is LungBellGuardian), "chapter_4_boss_is_not_chapter_2")
	check(not (scene._boss is InkArchivistCh1), "chapter_4_boss_is_not_chapter_1")
	if boss == null:
		return
	var chapter := CampaignData.chapter(3)
	# The Chapter 4 ending copy is authored and must stay untouched: four outro
	# lines, the two authored choices and the ch4_outro voice asset. Chapter 4 is
	# the last chapter, so there is no fifth chapter to enter.
	check(CampaignData.chapter_count() == 4, "chapter_4_is_the_last_chapter")
	check(chapter["outro"].size() == 4, "chapter_4_outro_copy_authored")
	check(String(chapter.get("voice_outro", "")) == "ch4_outro",
		"chapter_4_outro_voice_key")
	check(ResourceLoader.exists("res://assets/audio/voice/zh_cn/ch4_outro.ogg"),
		"chapter_4_outro_voice_present")
	var chapter_options: Array = chapter["choice"]["options"]
	check(chapter_options.size() == 2, "chapter_4_choice_has_two_options")
	check(String(chapter_options[0].get("label", "")) == "重写名册",
		"chapter_4_choice_kept_rewrite")
	check(String(chapter_options[1].get("label", "")) == "焚毁名册",
		"chapter_4_choice_kept_burn")
	check(boss.data.contact_damage == int(chapter["boss_damage"]),
		"chapter_4_boss_damage_from_campaign")
	check(is_equal_approx(boss.data.speed, float(chapter["boss_speed"])),
		"chapter_4_boss_speed_from_campaign")
	var flow := root.get_node_or_null("Flow") as GameFlow
	var difficulty: int = flow.difficulty if flow != null else 0
	var expected_hp := maxi(int(round(float(chapter["boss_hp"])
		* Difficulty.enemy_health(difficulty))), 1)
	check(boss.max_health == expected_hp, "chapter_4_boss_health_from_campaign")
	var arena := room.get_node_or_null("Arena") as ArenaRoom
	check(arena != null, "chapter_4_boss_arena_present")
	if arena != null:
		check(boss.global_position.y < arena.global_position.y,
			"chapter_4_boss_spawns_above_ground")

	# Phase copy uses the chapter-4 table (chapter index mixed into the key), so
	# it never falls back to the Chapter 1/2/3 lines.
	scene._on_boss_phase(chapter, 2)
	var expected_phase_line := BossPhaseData.pick(scene.run_state.run_seed, 2, 3)
	check(expected_phase_line != "", "chapter_4_boss_phase_line_authored")
	check(scene.hud.get_message_text()
		== "笑面史官 · 第 2 阶段：" + expected_phase_line,
		"chapter_4_boss_phase_uses_chapter_4_copy")
	scene._on_boss_phase(chapter, 3)
	var expected_phase_3_line := BossPhaseData.pick(scene.run_state.run_seed, 3, 3)
	check(expected_phase_3_line != "", "chapter_4_boss_phase_3_line_authored")
	check(scene.hud.get_message_text()
		== "笑面史官 · 第 3 阶段：" + expected_phase_3_line,
		"chapter_4_boss_phase_3_uses_chapter_4_copy")

	# The authored beats fire on the live boss: the mirror fan is three bolts,
	# phase 3's ink rain drops three warnings, and the rewrite beat seals the
	# player's first phrase slot.
	scene.player._invulnerable_left = 100
	var enemies_root := boss.get_parent()
	boss.max_health = 100
	boss.health = 90
	boss.phase = 2
	boss.attack_cycle = 2
	var bolts_before := _count_nodes_of_type(enemies_root, "HostileBolt")
	boss._perform_attack()
	var fan_bolts := _children_of_type(enemies_root, "HostileBolt")
	check(fan_bolts.size() - bolts_before == 3, "chapter_4_boss_live_mirror_fan")
	var fan_damage := maxi(int(float(chapter["boss_damage"]) * 0.7), 1)
	var fan_headings: Dictionary = {}
	for index in range(bolts_before, fan_bolts.size()):
		var bolt := fan_bolts[index] as HostileBolt
		fan_headings[snappedf(bolt.direction.angle(), 0.01)] = true
		check(bolt.damage == fan_damage, "chapter_4_boss_live_mirror_damage")
		check(is_equal_approx(bolt.speed, 280.0), "chapter_4_boss_live_mirror_speed")
	check(fan_headings.size() == 3, "chapter_4_boss_live_mirror_three_headings")
	boss.phase = 3
	boss.attack_cycle = 5
	var warnings_before := _count_nodes_of_type(enemies_root, "InkWarning")
	boss._perform_attack()
	var rain_warnings := _children_of_type(enemies_root, "InkWarning")
	check(rain_warnings.size() - warnings_before == 3,
		"chapter_4_boss_live_ink_rain")
	var rain_damage := maxi(int(float(chapter["boss_damage"]) * 0.75), 1)
	for index in range(warnings_before, rain_warnings.size()):
		check((rain_warnings[index] as InkWarning).damage == rain_damage,
			"chapter_4_boss_live_ink_rain_damage")
	scene.player.disabled_phrase_slots[0] = false
	boss.attack_cycle = 3
	boss._perform_attack()
	check(scene.player.disabled_phrase_slots[0] == true,
		"chapter_4_boss_live_rewrite_seals_slot")
	scene.player.disabled_phrase_slots[0] = false
	for hazard in get_nodes_in_group("hostile_hazards"):
		hazard.queue_free()

	# The Chapter 4 ending: defeating the Smiling Archivist through the real flow
	# grants the authored authority, plays the Chapter 4 outro and choice, and
	# finishes the campaign (Chapter 4 is the last authored chapter).
	if arena != null:
		scene.player.global_position = arena.global_position
		scene._update_room_locks()
	scene.player._invulnerable_left = 100
	boss.take_damage(100000)
	check(await _wait_authority_choice(scene), "chapter_4_authority_choice_opens")
	var expected_pool := AuthorityController.build_pool(
		plan.authority_pool, scene.run_state, flow.profile if flow != null else null,
		scene._records)
	var pool_ids: Array[StringName] = []
	for authority in expected_pool:
		pool_ids.append(authority.id)
	check(pool_ids.has(&"revive"), "chapter_4_authority_offers_revive")
	check(pool_ids.has(&"rewrite"), "chapter_4_authority_offers_rewrite")
	check(scene._authority_choice.get_button_count() == expected_pool.size(),
		"chapter_4_authority_choice_matches_pool")
	scene._authority_choice._choose(0)
	await create_timer(1.5).timeout
	check(scene.run_state.authority != null, "chapter_4_authority_granted")
	check(scene._story.is_open(), "chapter_4_outro")
	check(not scene._story._choice_mode, "chapter_4_outro_is_story_page")
	check(scene._story._title.text == String(chapter["title"]),
		"chapter_4_outro_uses_chapter_title")
	check(scene._story._body.text == "\n".join(chapter["outro"]),
		"chapter_4_outro_uses_authored_copy")
	check(scene._story._voice_id == "ch4_outro", "chapter_4_outro_plays_authored_voice")
	scene._story.close()
	await process_frame
	check(scene._story.is_open(), "chapter_4_choice")
	check(scene._story._choice_mode, "chapter_4_choice_is_choice_page")
	check(scene._story._title.text == String(chapter["choice"]["title"]),
		"chapter_4_choice_uses_authored_title")
	check(scene._story._body.text == String(chapter["choice"]["body"]),
		"chapter_4_choice_uses_authored_body")
	check(scene._story._options.get_child_count() == chapter_options.size(),
		"chapter_4_choice_button_count")
	if scene._story._options.get_child_count() == 2:
		check((scene._story._options.get_child(0) as Button).text == "%s\n%s" % [
			chapter_options[0].get("label", ""), chapter_options[0].get("note", "")],
			"chapter_4_rewrite_button_text")
		check((scene._story._options.get_child(1) as Button).text == "%s\n%s" % [
			chapter_options[1].get("label", ""), chapter_options[1].get("note", "")],
			"chapter_4_burn_button_text")
	var mercy_before: int = scene._mercy
	var corruption_before: int = scene.run_state.corruption
	scene._story.choose(0)
	await create_timer(1.2).timeout
	check(scene._mercy == mercy_before + 1, "chapter_4_choice_applies_mercy")
	check(scene.run_state.corruption == corruption_before,
		"chapter_4_rewrite_choice_adds_no_corruption")
	check(not scene._burned_final, "chapter_4_rewrite_choice_keeps_record")
	check(scene._chapter == 3, "chapter_4_ends_at_campaign_end")
	check(scene._finished, "chapter_4_completes_campaign")
	check(scene.ending_screen.visible, "chapter_4_end_screen_visible")
	check(scene._boss_defeated, "chapter_4_boss_recorded_defeated")
	if flow != null:
		var expected_ending := CampaignData.ending_for(true,
			scene.run_state.corruption, scene._mercy, scene._burned_final)
		check(flow.last_ending.get("id", &"") == expected_ending.get("id", &""),
			"chapter_4_ending_follows_authored_rule")
		if flow.profile != null:
			check(flow.profile.endings.has(String(expected_ending.get("id", &""))),
				"chapter_4_ending_saved_to_profile")

	# A defeated boss stays down on reload (the resume guard is
	# chapter-agnostic). `_finished` keeps the deferred aftermath quiet while the
	# room is re-entered; the ending paused the tree, so unpause for the reload.
	paused = false
	scene._finished = true
	scene._boss_defeated = true
	if is_instance_valid(scene._boss):
		scene._boss.queue_free()
	scene._boss = null
	await world.load_room("ch4_boss")
	check(await _wait_room_id(world, "ch4_boss"), "chapter_4_boss_reloads")
	await create_timer(0.3).timeout
	check(scene._boss == null, "chapter_4_boss_no_second_spawn")
	var reloaded := world.room_node as MDSBigRoom
	if reloaded != null:
		var reloaded_arena := reloaded.get_node_or_null("Arena") as ArenaRoom
		var bosses := 0
		if reloaded_arena != null:
			for child in reloaded_arena.get_node(ArenaRoom.ENEMIES_NODE).get_children():
				if child is SmilingArchivist:
					bosses += 1
		check(bosses == 0, "chapter_4_boss_room_holds_no_boss")
	# Leave the routed world live in the finished state the campaign ending left
	# behind; the campaign ends here, so nothing starts a fifth chapter.
	scene._finished = true
	scene._boss_defeated = true
	scene._event_room_id = ""


## Waits for the deferred reward overlay a cleared arena opens.
func _wait_reward(scene, timeout := 2.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._reward_ui.visible:
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


## Waits for a story/event page (outro, choice or event copy).
func _wait_story(scene, timeout := 3.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._story != null and scene._story.is_open():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


## Waits for the boss authority choice (it opens after a 1.2 s beat).
func _wait_authority_choice(scene, timeout := 4.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._authority_choice != null and scene._authority_choice.is_open():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


## Plan arrays arrive as untyped Arrays; compare them order-insensitively.
## World y of a big-map room's first walkable ground surface.
func _ground_surface_y(room: MDSBigRoom) -> float:
	if room != null and room.data != null and not room.data.ground.is_empty():
		var entry: Dictionary = room.data.ground[0]
		var value: Variant = entry.get("y", null)
		if value is int or value is float:
			return room.to_global(Vector2(0, float(value))).y
	return room.global_position.y + room.room_bounds.size.y


func _plan_strings(value: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	if value is Array:
		for item in value:
			if item is String:
				out.append(String(item))
	out.sort()
	return out


## Enemy data ids spawned in [param arena], in spawn order.
func _arena_enemy_ids(arena: ArenaRoom) -> Array:
	var out: Array = []
	var root: Node = arena.get_node_or_null(ArenaRoom.ENEMIES_NODE)
	if root == null:
		return out
	for child in root.get_children():
		if child is Enemy and child.data != null:
			out.append(child.data.id)
	return out


## The Chapter 1 legacy linear room pass. Since pass 91 every later chapter runs
## its own big-map leg (`_test_ch2_big_map` / `_test_ch3_big_map` /
## `_test_ch4_big_map`), so this only ever sees `chapter_index == 0`; the old
## Chapter 4 stage-art audit now lives on the big-map regions in
## `integration_ch4_bigmap`.
func _test_mds_chapter(scene, chapter_index: int) -> void:
	var mds = scene._mds_world
	var prefix := "ch%d" % (chapter_index + 1)
	check(mds.current_room == "%s_01" % prefix, "chapter_%d_mds_starts" % (chapter_index + 1))
	var expected_title := "档案馆地图"
	if chapter_index > 0:
		expected_title = "%s地图" % String(CampaignData.chapter(chapter_index).get("region", ""))
	check(scene._map_overlay.title_text() == expected_title,
		"chapter_%d_map_title" % (chapter_index + 1))
	scene._map_overlay.open()
	check(scene._map_overlay.is_open(), "chapter_%d_map_opens" % (chapter_index + 1))
	check(scene._map_overlay.map_view.is_room_revealed("%s_01" % prefix), "chapter_%d_map_reveals_start" % (chapter_index + 1))
	scene._map_overlay.close()
	for room_index in 6:
		var expected := "%s_%02d" % [prefix, room_index + 1]
		if room_index > 0 and mds.current_room != expected:
			await mds.load_room(expected)
		check(mds.current_room == expected, "chapter_%d_room_%d_loaded" % [chapter_index, room_index])
		var arena := mds.room_node.get_node_or_null("Arena") as ArenaRoom
		check(arena != null, "chapter_%d_room_%d_has_arena" % [chapter_index, room_index])
		if arena == null:
			continue
		if chapter_index == 0 and room_index == 4:
			# Chapter 1 demo event room: no fight, a two-way choice instead.
			await create_timer(1.0).timeout
			check(scene._story.is_open(), "chapter_1_event_choice_opens")
			scene._story.choose(0)
			await create_timer(0.3).timeout
			check(scene._cleared_encounters.has("ch1_05/event"), "chapter_1_event_marks_cleared")
			continue
		scene.player.global_position = arena.global_position
		scene._update_room_locks()
		check(arena.is_locked(), "chapter_%d_room_%d_locks" % [chapter_index, room_index])
		for attempt in 4:
			for enemy in arena.get_node("Enemies").get_children():
				if enemy is Enemy and not enemy.dead:
					enemy.take_damage(100000)
			await create_timer(0.4).timeout
			if arena.is_cleared():
				break
		check(arena.is_cleared(), "chapter_%d_room_%d_clears" % [chapter_index, room_index])
		check(scene._reward_ui.visible, "chapter_%d_room_%d_reward" % [chapter_index, room_index])
		scene._reward_ui._choose(0)
		await process_frame
		if chapter_index == 0 and room_index == 0:
			# Big-map decoupling: a room can hold a second encounter. It must be
			# registered and keyed by its own node id, and a repeated clear must
			# not count or pay again.
			var second_arena := ArenaRoom.new()
			second_arena.name = "Arena2"
			second_arena.position = arena.position + Vector2(140, 0)
			mds.room_node.add_child(second_arena)
			scene._on_mds_room_loaded(expected)
			check(scene._rooms.has(second_arena), "chapter_1_second_encounter_registered")
			check(String(second_arena.get_meta(&"encounter_id", "")) == "ch1_01/Arena2",
				"chapter_1_second_encounter_uses_node_id")
			check(scene._cleared_encounters.has("ch1_01/Arena"),
				"chapter_1_first_encounter_kept_its_id")
			check(not scene._cleared_encounters.has("ch1_01/Arena2"),
				"chapter_1_second_encounter_not_marked_by_room_key")
			check(second_arena.cleared.get_connections().size() == 1,
				"chapter_1_second_encounter_signal_wired")
			var clears_before: int = scene._cleared_in_chapter
			scene._cleared_encounters["ch1_01/Arena2"] = true
			second_arena.cleared.emit()
			await process_frame
			check(scene._cleared_in_chapter == clears_before,
				"chapter_1_second_encounter_not_double_counted")
			check(not scene._reward_ui.visible, "chapter_1_second_encounter_no_duplicate_reward")
			scene._cleared_encounters.erase("ch1_01/Arena2")
			mds.room_node.remove_child(second_arena)
			second_arena.free()
			scene._on_mds_room_loaded(expected)
			check(scene._rooms.is_empty(), "chapter_1_second_encounter_cleanup")
		if room_index == 0:
			# Exercise a real MDS gate, not only programmatic room loads.
			var gate := MDSGate.find_gate(mds.room_node, "right1")
			check(gate != null, "chapter_%d_right_gate_present" % (chapter_index + 1))
			if gate != null:
				gate.use()
				check(await _wait_room_id(mds, "%s_02" % prefix), "chapter_%d_gate_transition" % (chapter_index + 1))
		if room_index == 2:
			# The hidden vault is optional: enter, see two rewards, come back.
			var vault_gate := MDSGate.find_gate(mds.room_node, "door1")
			check(vault_gate != null, "chapter_%d_vault_door_present" % (chapter_index + 1))
			if vault_gate != null:
				await create_timer(0.4).timeout
				vault_gate.use()
				check(await _wait_room_id(mds, "%s_vault" % prefix), "chapter_%d_vault_reached" % (chapter_index + 1))
				check(scene._chests.size() >= 1, "chapter_%d_vault_has_chest" % (chapter_index + 1))
				check(scene._steles.size() >= 1, "chapter_%d_vault_has_stele" % (chapter_index + 1))
				var vault_back := MDSGate.find_gate(mds.room_node, "door1")
				check(vault_back != null, "chapter_%d_vault_return_present" % (chapter_index + 1))
				if vault_back != null:
					await create_timer(0.4).timeout
					vault_back.use()
					check(await _wait_room_id(mds, expected), "chapter_%d_vault_return" % (chapter_index + 1))
	check(scene._cleared_in_chapter == 6, "chapter_%d_six_rooms_cleared" % (chapter_index + 1))
	await mds.load_room("%s_rest" % prefix)
	check(mds.current_room == "%s_rest" % prefix, "chapter_%d_rest_room_reached" % (chapter_index + 1))
	check(scene._shops.size() == 1, "chapter_%d_rest_room_has_shop" % (chapter_index + 1))
	check(scene._steles.size() == 1, "chapter_%d_rest_room_has_stele" % (chapter_index + 1))
	var shortcut := MDSGate.find_gate(mds.room_node, "door2")
	check(shortcut != null, "chapter_%d_shortcut_present" % (chapter_index + 1))
	if shortcut != null:
		await create_timer(0.4).timeout
		shortcut.use()
		check(await _wait_room_id(mds, "%s_02" % prefix), "chapter_%d_shortcut_reached" % (chapter_index + 1))
		await mds.load_room("%s_rest" % prefix)
		check(mds.current_room == "%s_rest" % prefix, "chapter_%d_shortcut_back_to_rest" % (chapter_index + 1))
	if not scene._shops.is_empty():
		check(scene._shops[0].shop_id == StringName("ch%d_rest_shop" % (chapter_index + 1)), "chapter_%d_shop_id" % (chapter_index + 1))
	await mds.load_room("%s_boss" % prefix)
	check(mds.current_room == "%s_boss" % prefix, "chapter_%d_boss_room_reached" % (chapter_index + 1))
	var boss_arena := mds.room_node.get_node_or_null("Arena") as ArenaRoom
	check(boss_arena != null, "chapter_%d_boss_arena_present" % (chapter_index + 1))
	check(is_instance_valid(scene._boss) and not scene._boss.dead, "chapter_%d_boss_spawned" % (chapter_index + 1))
	if boss_arena != null:
		scene.player.global_position = boss_arena.global_position
		scene._update_room_locks()
		check(boss_arena.is_locked(), "chapter_%d_boss_room_locks" % (chapter_index + 1))
		scene.player._invulnerable_left = 100
		if chapter_index == 0:
			check(scene._boss is InkArchivistCh1,
				"chapter_1_boss_uses_authored_scene")
		scene._boss.take_damage(100000)
		await process_frame
		if chapter_index == 0:
			await create_timer(1.5).timeout
			check(scene._authority_choice.visible, "chapter_1_authority_choice_opens")
			scene._authority_choice._choose(0)
			await create_timer(0.4).timeout
			check(scene.run_state.authority != null, "chapter_1_authority_applied")
	check(scene._story.is_open(), "chapter_%d_outro" % (chapter_index + 1))
	scene._story.close()
	await process_frame
	check(scene._story.is_open(), "chapter_%d_choice" % (chapter_index + 1))
	scene._story.choose(0)
	await create_timer(0.35).timeout
	await create_timer(0.8).timeout
	# Chapter 1 hands the campaign to the Chapter 2 big map in place: the authored
	# choice effects are unchanged, the demo flag still records the clear, and the
	# Chapter 2 intro replaces the ending screen. (Chapters 2–4 run their own
	# big-map legs, and Chapters 3/4 hand off / end in those legs.)
	var flow := root.get_node_or_null("Flow") as GameFlow
	check(scene._chapter == 1, "chapter_1_enters_chapter_2")
	check(not scene._finished, "chapter_1_does_not_finish_campaign")
	check(not scene.ending_screen.visible, "chapter_1_no_ending_screen")
	check(scene._story.is_open() and not scene._story._choice_mode,
		"chapter_2_intro_opens_after_choice")
	check(scene._story._title.text == String(CampaignData.chapter(1)["title"]),
		"chapter_2_intro_uses_chapter_2_title")
	check(scene._story._body.text.contains(String(CampaignData.chapter(1)["intro"][0])),
		"chapter_2_intro_uses_chapter_2_lines")
	check(scene._chapter_plan != null and scene._chapter_plan.big_map,
		"chapter_2_plan_active_after_handoff")
	check(flow != null and flow.profile != null and flow.profile.demo_cleared,
		"chapter_1_still_marks_demo_cleared")
	var audio := root.get_node_or_null("Audio") as AudioManager
	check(audio != null
		and audio._current_music == String(CampaignData.chapter(1)["music"]),
		"chapter_2_music_on_handoff")
	check(audio != null and audio._voice.stream != null
		and String(audio._voice.stream.resource_path).ends_with("ch2_intro.ogg"),
		"chapter_2_intro_voice_on_handoff")

func _run() -> void:
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	# Production-line fixture first: it owns its own MDS world and player, and
	# is torn down before the real campaign boots.
	await _test_big_room_pipeline()
	flow.difficulty = 2
	flow.profile.archive_levels = {"vitality": 2, "ink": 1, "damage": 1, "ward": 1}
	if OS.get_cmdline_user_args().has("--expect-packed"):
		check(not FileAccess.file_exists("res://tests/run_tests.gd"), "tests excluded from mounted export package")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await physics_frame
	check(scene._chapters.size() == 4, "campaign_has_four_chapters")
	check(scene._story.is_open(), "chapter_intro_is_visible")
	var audio := root.get_node("Audio") as AudioManager
	print("AUDIO STATE current=", audio._current_music, " playing=", audio._music.playing if audio._music != null else "null")
	check(audio._music.playing, "chapter_music_plays")
	check(audio._voice.playing, "chapter_voice_plays")
	scene._story.close()
	await process_frame
	check(not scene._ending_pending, "first_chapter_becomes_playable")
	check(scene._mds_active, "chapter_1_uses_mds")
	check(await _wait_mds(scene), "mds_first_room_loads")
	check(scene._map_overlay.title_text() == "档案馆地图", "chapter_1_map_title_unchanged")
	check(scene._mds_world.current_room == "ch1_01", "mds_starts_in_first_room")
	check(scene._rooms.size() == 1, "mds_current_room_registered")
	check(scene.player.max_health >= 120, "archive_vitality_applies")
	check(scene.run_state.max_ink >= 105, "archive_ink_applies")
	check(is_equal_approx(scene._archive_damage_multiplier, 1.04), "archive_damage_applies")
	check(
		is_equal_approx(scene.run_state.corruption_gain_multiplier, Difficulty.corruption_multiplier(2) / 1.02),
		"archive_ward_applies"
	)
	check(scene.hud.region_label.text.contains("深渊"), "difficulty_shown")
	var first_arena: ArenaRoom = scene._mds_world.room_node.get_node("Arena")
	var scaled_enemy := false
	for enemy in first_arena.get_node("Enemies").get_children():
		if enemy is Enemy and enemy.data != null and enemy.data.max_health > 22:
			scaled_enemy = true
	check(scaled_enemy, "difficulty_scales_enemy_health")
	check(scene._chests.is_empty(), "mds_room_1_has_no_chest")
	check(scene.run_state.inventory.relics.is_empty(), "no_unearned_relics_at_spawn")
	check(not scene._rooms[0].is_locked(), "mds_spawn_does_not_lock_before_entry")

	# The in-run shop's rest card must state the numbers _apply_reward really
	# applies (pass 70: it promised 45 HP / 30 ink while healing 35 and
	# restoring 45 ink).
	var rest_offer: Dictionary = RunLoot.shop_offers(scene.run_state, 0, flow.profile)[0]
	check(String(rest_offer["title"]) == "缝合书页", "run_shop_rest_title")
	var rest_hp_before: int = scene.player.health
	var rest_ink_before: int = scene.run_state.ink
	var rest_corruption_before: int = scene.run_state.corruption
	scene.player.health = 10
	scene.run_state.ink = 0
	scene.run_state.corruption = 40
	scene._apply_reward(rest_offer)
	var rest_hp: int = scene.player.health - 10
	var rest_ink: int = scene.run_state.ink
	var rest_purified: int = 40 - scene.run_state.corruption
	var rest_copy := String(rest_offer["description"])
	check(rest_hp == 35, "run_shop_rest_heals_35")
	check(rest_ink == 45, "run_shop_rest_restores_45_ink")
	check(rest_purified == 12, "run_shop_rest_purifies_12")
	check(rest_copy.contains(str(rest_hp)) and rest_copy.contains(str(rest_ink))
		and rest_copy.contains(str(rest_purified)), "run_shop_rest_copy_matches_effect")
	scene.player.health = rest_hp_before
	scene.run_state.ink = rest_ink_before
	scene.run_state.corruption = rest_corruption_before

	var starter: WeaponData = scene.run_state.inventory.weapons[0]
	var candidate := preload("res://resources/weapons/miasma_bow.tres") as WeaponData
	scene._acquire_weapon(candidate)
	check(scene.run_state.inventory.weapons[0] == candidate, "weapon_reward_equips")
	check(scene.player.weapons[0].data == candidate, "weapon_reward_reaches_player")
	var dropped: Pickup = null
	for child in scene.get_children():
		if child is Pickup and child.kind == &"weapon" and child.resource == starter:
			dropped = child
	check(dropped != null, "previous_weapon_drops_instead_of_vanishing")
	scene.player.global_position = dropped.global_position
	dropped._on_body_entered(scene.player)
	check(scene._try_pickup_nearest(), "weapon_pickup_needs_interact")
	await process_frame
	check(scene.run_state.inventory.weapons[0] == starter, "dropped_weapon_can_be_picked_back")

	# Corruption 100 is a survivable 30-second frenzy, not an instant loss.
	var base_max: int = scene.player.max_health
	scene.run_state.corruption = 99
	scene.run_state.add_corruption(1)
	check(scene._frenzy_active, "corruption_100_starts_frenzy")
	check(scene.player.max_health < base_max, "frenzy_reduces_max_health")
	check(scene.player.health <= scene.player.max_health, "frenzy_health_clamped")
	scene._frenzy_left = 0.01
	scene._update_corruption_frenzy(0.02)
	check(not scene._frenzy_active, "frenzy_ends_after_duration")
	check(scene.player.max_health == base_max, "frenzy_restores_max_health")
	check(scene.run_state.corruption < 100, "frenzy_drops_corruption")
	scene.run_state.set_corruption(0)
	scene._apply_corruption_penalties()

	# --- Fall plane: Chapter 1 keeps the legacy 850 px room-local rule. ---
	var fall_origin: Vector2 = scene._mds_world.world.get_origin("ch1_01")
	var fall_checkpoint: Vector2 = scene._last_checkpoint
	check(is_equal_approx(scene._fall_limit_local, ChapterPlanData.DEFAULT_FALL_Y),
		"fall_ch1_default_limit")
	check(scene._chapter_clear_target() == 6, "ch1_clear_target_from_plan")
	check(scene._chapter_progress_total() == 7, "ch1_progress_total_from_plan")
	scene.player.global_position = fall_origin + Vector2(200, 700)
	await process_frame
	await process_frame
	check(scene.player.global_position.y < fall_origin.y + 800.0, "fall_ch1_above_plane_safe")
	var fall_health: int = scene.player.health
	scene.player.global_position = fall_origin + Vector2(200, 851)
	await process_frame
	await process_frame
	check(absf(scene.player.global_position.x - fall_checkpoint.x) < 8.0
		and absf(scene.player.global_position.y - fall_checkpoint.y) < 40.0,
		"fall_ch1_returns_to_checkpoint")
	# Fall damage goes through the normal taken-damage multiplier (difficulty,
	# corruption), exactly like it did before the plane became configurable.
	var expected_fall_damage := maxi(
		1, int(ceilf(15.0 * scene.player.damage_taken_multiplier)))
	check(scene.player.health == fall_health - expected_fall_damage,
		"fall_ch1_damage_unchanged")

	# A configured plane (what the big-map chapter plans will author) keeps a
	# lower area alive instead of treating it as a fall. The resolver is read
	# from the plan without touching any real chapter data.
	var tall_plan := ChapterPlanData.new()
	tall_plan.rooms.append({"id": "ch1_01", "type": "combat", "fall_y": 2000.0})
	var real_plan: ChapterPlanData = scene._chapter_plan
	scene._chapter_plan = tall_plan
	check(is_equal_approx(scene._resolve_fall_limit("ch1_01"), 2000.0),
		"fall_plan_override_read")
	scene._fall_limit_local = 2000.0
	var lower_health: int = scene.player.health
	scene.player.global_position = fall_origin + Vector2(200, 1200)
	await process_frame
	await process_frame
	check(scene.player.global_position.y > fall_origin.y + 1100.0, "fall_lower_area_survives")
	check(scene.player.health == lower_health, "fall_lower_area_no_damage")
	scene.player.global_position = fall_origin + Vector2(200, 2001)
	await process_frame
	await process_frame
	check(absf(scene.player.global_position.x - fall_checkpoint.x) < 8.0
		and absf(scene.player.global_position.y - fall_checkpoint.y) < 40.0,
		"fall_configured_plane_returns")
	scene._chapter_plan = real_plan
	scene._fall_limit_local = scene._resolve_fall_limit("ch1_01")
	check(is_equal_approx(scene._fall_limit_local, ChapterPlanData.DEFAULT_FALL_Y),
		"fall_ch1_limit_restored")

	for chapter_index in CampaignData.chapter_count():
		var handoff := false
		if chapter_index > 0:
			scene._finished = false
			scene.ending_screen.visible = false
			scene.get_tree().paused = false
			# Chapters 1–2 hand the campaign to the next chapter in place.
			# Continue from the intro already opened instead of starting the
			# chapter a second time.
			handoff = scene._chapter == chapter_index \
				and scene._story.is_open() and not scene._story._choice_mode
			if handoff:
				check(scene._story._eyebrow.text.contains("第 %d 章" % (chapter_index + 1)),
					"chapter_%d_handoff_intro_eyebrow" % (chapter_index + 1))
			else:
				# Start the remaining chapters explicitly for structural coverage.
				scene._ending_pending = false
				scene._start_chapter(chapter_index)
				await create_timer(0.2).timeout
				check(scene._story.is_open(), "chapter_%d_intro" % (chapter_index + 1))
			scene._story.close()
			await process_frame
			check(await _wait_mds(scene), "chapter_%d_mds_loads" % (chapter_index + 1))
		check(scene._chapter == chapter_index, "chapter_index_%d" % chapter_index)
		if chapter_index == 1:
			# Chapter 2 is reached through the real Chapter 1 completion page;
			# the loop also starts it explicitly when needed for structure.
			check(scene._cleared_in_chapter == 0, "chapter_2_starts_with_clear_zero")
			var spawn := scene._mds_world.room_node.get_node_or_null("SpawnPoint") as Marker2D
			check(spawn != null, "chapter_2_handoff_spawn_marker")
			if spawn != null:
				check(scene.player.global_position.distance_to(spawn.global_position) < 2.0,
					"chapter_2_handoff_spawn_position")
			await physics_frame
			check(scene.player.is_on_floor(), "chapter_2_handoff_player_on_floor")
			check(is_equal_approx(scene._fall_limit_local, 1680.0),
				"chapter_2_fall_plane_from_plan")
			check(scene._chapter_clear_target() == 7, "chapter_2_clear_target_from_plan")
			check(scene._chapter_progress_total() == 8, "chapter_2_progress_total_from_plan")
			await _test_ch2_big_map(scene)
		elif chapter_index == 2:
			# Chapter 3 is reached through the real Chapter 2 completion page and
			# runs on the routed plan/world; its choice hands off to Chapter 4.
			await _test_ch3_big_map(scene)
		elif chapter_index == 3:
			# Chapter 4 is reached through the real Chapter 3 completion page and
			# runs on the routed plan/world; Boss 4 ends the campaign.
			await _test_ch4_big_map(scene)
		else:
			# Chapter 1 keeps the legacy linear rooms and the room-local fall
			# plane; its completion page hands off to the Chapter 2 big map.
			check(is_equal_approx(scene._fall_limit_local, ChapterPlanData.DEFAULT_FALL_Y),
				"chapter_%d_fall_plane_default" % (chapter_index + 1))
			check(scene._chapter_clear_target() == 6,
				"chapter_%d_clear_target_default" % (chapter_index + 1))
			await _test_mds_chapter(scene, chapter_index)
	await create_timer(1.0).timeout
	check(scene._finished, "campaign_reaches_ending")
	check(scene.ending_screen.visible, "ending_screen_visible")
	check(flow.last_ending.get("id", &"") == &"restored", "merciful_run_reaches_restored_ending")
	paused = false
	root.remove_child(scene)
	scene.free()
	if audio._music != null:
		audio._music.stop()
		audio._music.stream = null
	if audio._voice != null:
		audio._voice.stop()
		audio._voice.stream = null
	# Pass 97: one continuous new-game -> ending chain on the real surfaces.
	await _test_full_campaign_chain()
	if audio._music != null:
		audio._music.stop()
		audio._music.stream = null
	if audio._voice != null:
		audio._voice.stop()
		audio._voice.stream = null
	print("INTEGRATION: %d checks, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)




# --- Pass 97: full 1->4 campaign chain ----------------------------------------
#
# One continuous run on the real surfaces: a fresh profile boots the real Hub,
# the authored tutorial steps are walked, the run starts through the Hub's own
# request, and every chapter handoff is crossed with real MDS gates, real arena
# fights, the real reward/event/authority/story pages and the real run-save
# file. Progression never calls `load_room` or `_mark_encounter_cleared`; the
# only harness liberty is standing the player inside an arena (the same
# technique the big-map suites use), never a room transition.

const CHAIN_RUN_PATH := "user://test_chain_run.cfg"
const CHAIN_PROFILE_PATH := "user://test_chain_profile.cfg"

var _chain_constants: Dictionary = {}
## Chapter 4's boss-death checkpoint, written before its authority pick, so it
## still carries the Chapter 3 authority. Replayed by the cross-chapter leg.
var _chain_boss_checkpoint: Dictionary = {}


func _chain_game_constants() -> Dictionary:
	if _chain_constants.is_empty():
		var script := load("res://scripts/game.gd") as GDScript
		if script != null:
			_chain_constants = script.get_script_constant_map()
	return _chain_constants


func _chain_prefix(chapter_index: int) -> String:
	return "ch%d" % (chapter_index + 1)


func _chain_room(chapter_index: int, region: String) -> String:
	return "%s_%s" % [_chain_prefix(chapter_index), region]


func _chain_audio() -> AudioManager:
	return root.get_node_or_null("Audio") as AudioManager


func _chain_voice_ends_with(suffix: String) -> bool:
	var audio := _chain_audio()
	return audio != null and audio._voice.stream != null \
		and String(audio._voice.stream.resource_path).ends_with(suffix)


func _chain_music_is(path: String) -> bool:
	var audio := _chain_audio()
	return audio != null and audio._current_music == path


## Uses the authored gate [param gate_name] and waits for its target room. A
## floor arrival keeps that same gate inert for 1.2 s (pass 36), so that grace
## is waited out first.
func _chain_use_gate(scene, gate_name: String, expected_room: String) -> bool:
	var mds = scene._mds_world
	var from_room: String = mds.current_room
	var gate := MDSGate.find_gate(mds.room_node, gate_name)
	check(gate != null, "chain_gate_present_%s_%s" % [from_room, gate_name])
	if gate == null:
		return false
	var wait := 0.45
	if mds._arrival_gate == gate_name:
		var grace_left: float = float(mds._arrival_grace_until - Time.get_ticks_msec()) / 1000.0
		wait = maxf(wait, grace_left + 0.15)
	await create_timer(wait).timeout
	scene.player.velocity = Vector2.ZERO
	gate.use()
	var arrived := await _wait_room_id(mds, expected_room, 6.0)
	check(arrived, "chain_gate_walk_%s_%s_to_%s" % [from_room, gate_name, expected_room])
	return arrived


## Locks [param arena] by standing the real player inside its entry band, then
## kills everything that spawns (queued waves included) through the normal
## damage path until the arena clears and the reward page opens.
func _chain_clear_arena(scene, arena: ArenaRoom, label: String) -> bool:
	if arena == null:
		check(false, "chain_arena_missing_" + label)
		return false
	scene.player._invulnerable_left = 999.0
	scene.player.global_position = arena.global_position + Vector2(0, -120)
	scene.player.velocity = Vector2.ZERO
	scene._update_room_locks()
	check(arena.is_locked(), "chain_arena_locks_" + label)
	for _attempt in 12:
		var enemies := arena.get_node_or_null(ArenaRoom.ENEMIES_NODE)
		if enemies != null:
			for enemy in enemies.get_children():
				if enemy is Enemy and not enemy.dead:
					enemy.take_damage(100000)
		await create_timer(0.35).timeout
		if arena.is_cleared():
			break
	check(arena.is_cleared(), "chain_arena_clears_" + label)
	var reward_open := await _wait_reward(scene, 3.0)
	check(reward_open, "chain_reward_opens_" + label)
	return reward_open


## Takes the rest card (index 2) so combat rewards never add corruption; the
## campaign-end judgement then depends on the authored chapter choices alone.
func _chain_take_rest_reward(scene, label: String) -> void:
	check(scene._reward_ui.visible, "chain_reward_visible_" + label)
	if not scene._reward_ui.visible:
		return
	check(scene._reward_options.size() == 3, "chain_reward_three_cards_" + label)
	scene._reward_ui._choose(2)
	await process_frame
	await process_frame
	check(not scene._reward_ui.visible, "chain_reward_closed_" + label)
	check(not paused, "chain_reward_unpauses_" + label)


## Reads the live checkpoint and checks the keys a handoff contract depends on.
func _chain_read_save(label: String, expectation: Dictionary) -> Dictionary:
	var saved := RunSave.read(CHAIN_RUN_PATH)
	check(not saved.is_empty(), "chain_save_written_" + label)
	if saved.is_empty():
		return saved
	var run: Dictionary = saved.get("run", {})
	var progress: Dictionary = saved.get("progress", {})
	var authority: Dictionary = saved.get("authority", {})
	var world: Dictionary = saved.get("world", {})
	for key in expectation:
		match String(key):
			"chapter":
				check(int(run.get("chapter", -1)) == int(expectation[key]),
					"chain_save_chapter_" + label)
			"room":
				check(String(run.get("room", "")) == String(expectation[key]),
					"chain_save_room_" + label)
			"cleared":
				check(int(progress.get("cleared_in_chapter", -1)) == int(expectation[key]),
					"chain_save_cleared_" + label)
			"authority":
				check(String(authority.get("id", "")) == String(expectation[key]),
					"chain_save_authority_" + label)
			"authority_chapter":
				check(int(authority.get("chapter", -99)) == int(expectation[key]),
					"chain_save_authority_chapter_" + label)
			"mercy":
				check(int(run.get("mercy", -99)) == int(expectation[key]),
					"chain_save_mercy_" + label)
			"pages_min":
				check(int(run.get("pages", -1)) >= int(expectation[key]),
					"chain_save_pages_" + label)
			"boss_defeated":
				check(bool(world.get("boss_defeated", false)) == bool(expectation[key]),
					"chain_save_boss_defeated_" + label)
			"encounters_include":
				var ids: Array = progress.get("cleared_encounters", [])
				for id in expectation[key] as Array:
					check(ids.has(String(id)), "chain_save_encounter_%s_%s" % [label, id])
			"encounters_empty":
				check((progress.get("cleared_encounters", []) as Array).is_empty(),
					"chain_save_encounters_empty_" + label)
	return saved


func _chain_wait_intro(scene, chapter_index: int, timeout := 4.0) -> bool:
	var left := timeout
	while left > 0.0:
		if scene._chapter == chapter_index and scene._story != null \
				and scene._story.is_open() and not scene._story._choice_mode:
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _chain_wait_on_floor(scene, frames := 40) -> bool:
	for _frame in frames:
		await physics_frame
		if scene.player.is_on_floor():
			return true
	return false


## Chapter 2–4 handoff contract: routing switched, intro text/voice/music, spawn
## marker reached on foot, plan-driven clear target / HUD denominator / fall
## plane / map title, and a chapter that starts from a clean slate.
func _chain_check_chapter_opening(scene, chapter_index: int) -> void:
	var number := chapter_index + 1
	var prefix := _chain_prefix(chapter_index)
	var chapter := CampaignData.chapter(chapter_index)
	var constants := _chain_game_constants()
	var plan_paths: Array = constants.get("CHAPTER_PLAN_PATHS", [])
	var world_files: Array = constants.get("MDS_WORLD_FILES", [])
	var world_scenes: Array = constants.get("MDS_CHAPTER_SCENES", [])
	var plan: ChapterPlanData = scene._chapter_plan
	check(await _chain_wait_intro(scene, chapter_index),
		"chain_intro_open_%d" % number)
	check(scene._chapter == chapter_index, "chain_chapter_index_%d" % number)
	check(plan != null and plan.big_map, "chain_plan_is_big_map_%d" % number)
	if plan != null:
		check(plan_paths.size() == 4
			and String(plan_paths[chapter_index]) == plan.resource_path,
			"chain_plan_routed_%d" % number)
		check(plan.start_region() == "%s_entry" % prefix,
			"chain_plan_start_region_%d" % number)
	# Intro page: eyebrow, title, every authored line, voice and music key.
	check(scene._story._eyebrow.text.contains("第 %d 章" % int(chapter["number"])),
		"chain_intro_eyebrow_%d" % number)
	check(scene._story._title.text == String(chapter["title"]),
		"chain_intro_title_%d" % number)
	var intro: Array = chapter["intro"]
	for line_index in intro.size():
		check(scene._story._body.text.contains(String(intro[line_index])),
			"chain_intro_line_%d_%d" % [number, line_index])
	check(_chain_music_is(String(chapter["music"])), "chain_music_%d" % number)
	check(_chain_voice_ends_with("%s.ogg" % String(chapter["voice_intro"])),
		"chain_intro_voice_%d" % number)
	scene._story.close()
	await process_frame
	check(not scene._ending_pending, "chain_intro_closes_%d" % number)
	check(await _wait_mds(scene), "chain_mds_ready_%d" % number)
	check(scene._mds_world.world_file == String(world_files[chapter_index]),
		"chain_world_routed_%d" % number)
	check(world_scenes.size() == 4 and scene._mds_world.scene_file_path
		== (world_scenes[chapter_index] as PackedScene).resource_path,
		"chain_world_scene_routed_%d" % number)
	check(scene._mds_world.current_room == "%s_entry" % prefix,
		"chain_starts_at_entry_%d" % number)
	# Spawn: the authored entrance marker, standing on it rather than falling in.
	var spawn := scene._mds_world.room_node.get_node_or_null("SpawnPoint") as Marker2D
	check(spawn != null, "chain_spawn_marker_%d" % number)
	if spawn != null:
		check(scene.player.global_position.distance_to(spawn.global_position) < 2.0,
			"chain_spawn_at_marker_%d" % number)
	check(await _chain_wait_on_floor(scene), "chain_spawn_on_floor_%d" % number)
	# Plan-driven numbers, HUD denominator, fall plane and map title.
	check(scene._chapter_clear_target() == 7, "chain_clear_target_%d" % number)
	check(scene._chapter_progress_total() == 8, "chain_progress_total_%d" % number)
	var progress_label := scene.hud.find_child("Progress", true, false) as Label
	check(progress_label != null and progress_label.text == "档案  0 / 8",
		"chain_hud_denominator_%d" % number)
	var entry_size: Vector2 = plan.region_size("%s_entry" % prefix) if plan != null \
		else Vector2.ZERO
	check(is_equal_approx(scene._fall_limit_local, entry_size.y + 240.0),
		"chain_fall_plane_from_plan_%d" % number)
	check(is_equal_approx(scene._fall_limit_local, 1680.0),
		"chain_fall_plane_authored_%d" % number)
	check(scene._map_overlay.title_text() == "%s地图" % String(chapter["region"]),
		"chain_map_title_%d" % number)
	# The handoff clears the chapter it left: no progress, no dead boss.
	check(scene._cleared_in_chapter == 0, "chain_cleared_zero_%d" % number)
	check(scene._cleared_encounters.is_empty(), "chain_encounters_empty_%d" % number)
	check(not scene._boss_defeated, "chain_boss_reset_%d" % number)


## Walks one Chapter 2–4 big map end to end on real gates: entry -> branch_b
## (fight) -> hub -> branch_a (two fights) -> hub -> event (one-shot page) ->
## hub -> well (two fights) -> elite (fight) -> boss -> authority -> outro ->
## chapter-end choice. Returns right after the choice; the handoff (or the
## campaign end on Chapter 4) is left running for the caller to assert.
func _chain_walk_big_map(scene, choice_index: int, chapter_index: int) -> void:
	var number := chapter_index + 1
	var chapter := CampaignData.chapter(chapter_index)
	# --- entry -> branch_b -> hub -> branch_a.
	check(await _chain_use_gate(scene, "bot1", _chain_room(chapter_index, "branch_b")),
		"chain_ch%d_entry_to_branch_b" % number)
	await _chain_clear_arena(scene,
		scene._mds_world.room_node.get_node_or_null("Arena") as ArenaRoom,
		"ch%d_branch_b" % number)
	await _chain_take_rest_reward(scene, "ch%d_branch_b" % number)
	check(scene._cleared_in_chapter == 1, "chain_ch%d_first_clear" % number)
	check(scene._cleared_encounters.has(
		"%s/Arena" % _chain_room(chapter_index, "branch_b")),
		"chain_ch%d_branch_b_settled" % number)
	check(await _chain_use_gate(scene, "right1", _chain_room(chapter_index, "hub")),
		"chain_ch%d_branch_b_to_hub" % number)
	check(await _chain_use_gate(scene, "top1", _chain_room(chapter_index, "branch_a")),
		"chain_ch%d_hub_to_branch_a" % number)
	for arena_name in ["Arena", "Arena2"]:
		await _chain_clear_arena(scene,
			scene._mds_world.room_node.get_node_or_null(arena_name) as ArenaRoom,
			"ch%d_branch_a_%s" % [number, arena_name])
		await _chain_take_rest_reward(scene, "ch%d_branch_a_%s" % [number, arena_name])
	check(scene._cleared_in_chapter == 3, "chain_ch%d_three_clears" % number)
	# --- back to the hub, then the one-shot event region.
	check(await _chain_use_gate(scene, "bot1", _chain_room(chapter_index, "hub")),
		"chain_ch%d_branch_a_to_hub" % number)
	check(await _chain_use_gate(scene, "right1", _chain_room(chapter_index, "event")),
		"chain_ch%d_hub_to_event" % number)
	check(await _wait_story(scene, 4.0), "chain_ch%d_event_page" % number)
	check(scene._story._choice_mode, "chain_ch%d_event_is_choice" % number)
	var event_id := RoomProgress.event_encounter_id(_chain_room(chapter_index, "event"))
	var pages_before: int = scene.run_state.pages
	scene._story.choose(1)
	await create_timer(0.4).timeout
	check(scene._cleared_encounters.has(event_id), "chain_ch%d_event_settled" % number)
	check(scene.run_state.pages == pages_before + 12, "chain_ch%d_event_pages" % number)
	check(scene._cleared_in_chapter == 4, "chain_ch%d_four_clears" % number)
	check(not scene._story.is_open(), "chain_ch%d_event_closed" % number)
	# Leaving and re-entering must not reopen a settled event page.
	check(await _chain_use_gate(scene, "left1", _chain_room(chapter_index, "hub")),
		"chain_ch%d_event_to_hub" % number)
	check(await _chain_use_gate(scene, "right1", _chain_room(chapter_index, "event")),
		"chain_ch%d_hub_to_event_again" % number)
	await create_timer(1.2).timeout
	check(not scene._story.is_open(), "chain_ch%d_event_one_shot" % number)
	check(await _chain_use_gate(scene, "left1", _chain_room(chapter_index, "hub")),
		"chain_ch%d_event_back_to_hub" % number)
	# --- the well's two arenas, the elite, then the one-way boss door.
	check(await _chain_use_gate(scene, "bot1", _chain_room(chapter_index, "well")),
		"chain_ch%d_hub_to_well" % number)
	for arena_name in ["Arena", "Arena2"]:
		await _chain_clear_arena(scene,
			scene._mds_world.room_node.get_node_or_null(arena_name) as ArenaRoom,
			"ch%d_well_%s" % [number, arena_name])
		await _chain_take_rest_reward(scene, "ch%d_well_%s" % [number, arena_name])
	check(scene._cleared_in_chapter == 6, "chain_ch%d_six_clears" % number)
	check(await _chain_use_gate(scene, "right1", _chain_room(chapter_index, "elite")),
		"chain_ch%d_well_to_elite" % number)
	await _chain_clear_arena(scene,
		scene._mds_world.room_node.get_node_or_null("Arena") as ArenaRoom,
		"ch%d_elite" % number)
	await _chain_take_rest_reward(scene, "ch%d_elite" % number)
	check(scene._cleared_in_chapter == 7, "chain_ch%d_target_met" % number)
	check(scene._cleared_in_chapter == scene._chapter_clear_target(),
		"chain_ch%d_target_matches_plan" % number)
	# --- boss: the plan's scene, the real fight, this chapter's authority pick.
	check(await _chain_use_gate(scene, "right1", _chain_room(chapter_index, "boss")),
		"chain_ch%d_elite_to_boss" % number)
	await process_frame
	var boss_arena := scene._mds_world.room_node.get_node_or_null("Arena") as ArenaRoom
	check(boss_arena != null, "chain_ch%d_boss_arena" % number)
	check(scene._boss != null and is_instance_valid(scene._boss) and not scene._boss.dead,
		"chain_ch%d_boss_spawned" % number)
	var plan: ChapterPlanData = scene._chapter_plan
	check(plan != null and plan.boss_scene != null and scene._boss != null
		and scene._boss.scene_file_path == plan.boss_scene.resource_path,
		"chain_ch%d_boss_scene_routed" % number)
	var objective := scene.hud.find_child("Objective", true, false) as Label
	check(objective != null and objective.text == "击败 %s" % String(chapter["boss_name"]),
		"chain_ch%d_boss_objective" % number)
	if boss_arena == null or scene._boss == null:
		return
	scene.player._invulnerable_left = 999.0
	scene.player.global_position = boss_arena.global_position + Vector2(0, -120)
	scene.player.velocity = Vector2.ZERO
	scene._update_room_locks()
	check(boss_arena.is_locked(), "chain_ch%d_boss_locks" % number)
	scene._boss.take_damage(100000)
	# `_on_boss_died` writes the pre-pick checkpoint synchronously, so the final
	# chapter's copy still carries the previous chapter's authority.
	if chapter_index == CampaignData.chapter_count() - 1:
		_chain_boss_checkpoint = RunSave.read(CHAIN_RUN_PATH)
		check(not _chain_boss_checkpoint.is_empty(),
			"chain_ch4_boss_checkpoint_saved")
		if not _chain_boss_checkpoint.is_empty():
			var snap_run: Dictionary = _chain_boss_checkpoint.get("run", {})
			var snap_world: Dictionary = _chain_boss_checkpoint.get("world", {})
			var snap_authority: Dictionary = _chain_boss_checkpoint.get("authority", {})
			check(int(snap_run.get("chapter", -1)) == chapter_index,
				"chain_ch4_boss_checkpoint_chapter")
			check(String(snap_run.get("room", "")) == _chain_room(chapter_index, "boss"),
				"chain_ch4_boss_checkpoint_room")
			check(bool(snap_world.get("boss_defeated", false)),
				"chain_ch4_boss_checkpoint_boss_dead")
			check(int(snap_authority.get("chapter", -99)) == chapter_index - 1,
				"chain_ch4_boss_checkpoint_carries_previous_authority")
	check(await _wait_authority_choice(scene, 5.0), "chain_ch%d_authority_opens" % number)
	check(scene._authority_choice.get_button_count() >= 2,
		"chain_ch%d_authority_pool" % number)
	scene._authority_choice._choose(0)
	await create_timer(0.4).timeout
	check(scene.run_state.authority != null, "chain_ch%d_authority_applied" % number)
	check(scene._authority_granted_chapter == chapter_index,
		"chain_ch%d_authority_chapter" % number)
	scene.save_run_now()
	_chain_read_save("ch%d_after_authority" % number, {
		"chapter": chapter_index,
		"room": _chain_room(chapter_index, "boss"),
		"cleared": 7,
		"authority_chapter": chapter_index,
		"boss_defeated": true,
	})
	# --- outro -> chapter-end choice.
	check(await _wait_story(scene, 4.0), "chain_ch%d_outro" % number)
	check(scene._story._title.text == String(chapter["title"]),
		"chain_ch%d_outro_title" % number)
	check(scene._story._body.text.contains(String(chapter["outro"][0])),
		"chain_ch%d_outro_lines" % number)
	check(_chain_voice_ends_with("%s.ogg" % String(chapter["voice_outro"])),
		"chain_ch%d_outro_voice" % number)
	check(_chain_music_is(String(chapter["music"])),
		"chain_ch%d_outro_music" % number)
	scene._story.close()
	await create_timer(0.25).timeout
	check(scene._story.is_open() and scene._story._choice_mode,
		"chain_ch%d_end_choice" % number)
	var choice: Dictionary = chapter["choice"]
	check(scene._story._body.text == String(choice["body"]),
		"chain_ch%d_choice_body" % number)
	check(scene._story._options.get_child_count() == (choice["options"] as Array).size(),
		"chain_ch%d_choice_options" % number)
	var mercy_before: int = scene._mercy
	var corruption_before: int = scene.run_state.corruption
	scene._story.choose(choice_index)
	await create_timer(0.25).timeout
	var option: Dictionary = (choice["options"] as Array)[choice_index]
	check(scene._mercy == mercy_before + int(option.get("mercy", 0)),
		"chain_ch%d_choice_mercy" % number)
	if option.has("corruption"):
		check(scene.run_state.corruption > corruption_before,
			"chain_ch%d_choice_corruption" % number)
	if chapter["id"] == &"smiling_theater":
		check(scene._burned_final == (choice_index == 1),
			"chain_ch4_burn_flag_follows_choice")


func _chain_cleanup(flow) -> void:
	RunSave.clear(CHAIN_RUN_PATH)
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = CHAIN_PROFILE_PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if flow != null:
		flow.auto_save = false
		flow.run_save_path = RunSave.DEFAULT_PATH
		flow.profile_path = GameFlow.DEFAULT_PROFILE_PATH
		flow.resume_requested = false


## Task 1 of pass 97: one real run from a fresh profile to the ending screen,
## then a real checkpoint resume that walks the other ending.
func _test_full_campaign_chain() -> void:
	var flow := root.get_node_or_null("Flow") as GameFlow
	var audio := root.get_node_or_null("Audio") as AudioManager
	if flow == null or audio == null:
		check(false, "chain_autoloads_present")
		return
	# Real saves on temp paths: the chain must write and re-read checkpoints.
	flow.profile_path = CHAIN_PROFILE_PATH
	flow.run_save_path = CHAIN_RUN_PATH
	flow.auto_save = true
	flow.resume_requested = false
	flow.difficulty = 2
	flow.reset_profile()
	flow.title_shown_this_session = true
	check(flow.profile != null and not flow.profile.tutorial_done,
		"chain_fresh_profile")

	# --- Boot: the real Hub, the authored tutorial steps, the real run request.
	var hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await create_timer(0.6).timeout
	check(hub.tutorial_flow != null and hub.tutorial_flow.is_active(),
		"chain_tutorial_starts")
	check(hub.tutorial_flow.get_hint().contains("第 1 步"), "chain_tutorial_step_1")
	hub._open_tutorial_codex()
	await create_timer(0.25).timeout
	check(paused and hub._tutorial_codex.visible, "chain_tutorial_codex_opens")
	check(hub.tutorial_flow.get_hint().contains("第 2 步"), "chain_tutorial_step_2")
	hub._close_tutorial_codex()
	await create_timer(0.25).timeout
	check(not paused, "chain_tutorial_codex_closes")
	var tutorial_words: Array[WordData] = []
	for word in hub._tutorial_run.inventory.words:
		if tutorial_words.size() < 2 and word != null:
			tutorial_words.append(word)
	var tutorial_phrase: ResolvedPhrase = PhraseResolver.new().resolve(tutorial_words)
	check(tutorial_phrase != null, "chain_tutorial_phrase_resolves")
	hub._on_tutorial_phrase_equipped(0, tutorial_phrase)
	await create_timer(0.2).timeout
	check(hub.tutorial_flow.get_hint().contains("训练碑"), "chain_tutorial_step_3")
	hub.interact_with(hub.training_dummy)
	await create_timer(0.25).timeout
	check(not hub.tutorial_flow.is_active(), "chain_tutorial_finishes")
	check(flow.profile.tutorial_done, "chain_tutorial_persisted")
	var saved_profile := Profile.new()
	root.add_child(saved_profile)
	check(saved_profile.load_profile(CHAIN_PROFILE_PATH)
		and saved_profile.tutorial_done, "chain_tutorial_on_disk")
	saved_profile.queue_free()
	# A real run request boots the real game scene through the Hub's own path.
	hub.request_run()
	var booted := false
	for _i in 160:
		await create_timer(0.05).timeout
		if current_scene != null and current_scene.has_method("_start_chapter"):
			booted = true
			break
	check(booted, "chain_run_request_boots_game")
	var scene = current_scene
	if scene == null or not scene.has_method("_start_chapter"):
		_chain_cleanup(flow)
		return

	# --- Chapter 1: intro -> five fights + one event -> boss 1 -> choice.
	# The chapter start is deferred behind `_ready`, so wait for the authored
	# intro page instead of sampling the frame the scene swap lands on.
	check(await _chain_wait_intro(scene, 0, 6.0), "chain_ch1_intro")
	check(scene._chapter == 0, "chain_chapter_1_boots")
	check(scene._story.is_open(), "chain_ch1_intro_open")
	check(scene._story._eyebrow.text.contains("第 1 章"), "chain_ch1_intro_eyebrow")
	check(scene._story._title.text == String(CampaignData.chapter(0)["title"]),
		"chain_ch1_intro_title")
	check(_chain_music_is(String(CampaignData.chapter(0)["music"])), "chain_ch1_music")
	check(_chain_voice_ends_with("ch1_intro.ogg"), "chain_ch1_intro_voice")
	scene._story.close()
	await process_frame
	check(await _wait_mds(scene), "chain_ch1_mds_ready")
	check(scene._mds_world.current_room == "ch1_01", "chain_ch1_starts_room_1")
	check(scene._chapter_clear_target() == 6, "chain_ch1_clear_target")
	check(scene._chapter_progress_total() == 7, "chain_ch1_progress_total")
	var ch1_progress := scene.hud.find_child("Progress", true, false) as Label
	check(ch1_progress != null and ch1_progress.text == "档案  0 / 7",
		"chain_ch1_hud_denominator")
	check(is_equal_approx(scene._fall_limit_local, ChapterPlanData.DEFAULT_FALL_Y),
		"chain_ch1_fall_plane")
	for room_number in [1, 2, 3, 4, 5, 6]:
		var room_id := "ch1_%02d" % room_number
		if room_number > 1:
			check(await _chain_use_gate(scene, "right1", room_id),
				"chain_ch1_gate_room_%d" % room_number)
		check(scene._mds_world.current_room == room_id,
			"chain_ch1_room_%d" % room_number)
		if room_number == 5:
			# Authored event room: the page opens on entry and takes a choice;
			# no fight and no reward page.
			check(await _wait_story(scene, 4.0), "chain_ch1_event_page")
			var ch1_event_before: int = scene.run_state.pages
			scene._story.choose(1)
			await create_timer(0.4).timeout
			check(scene.run_state.pages == ch1_event_before + 12,
				"chain_ch1_event_pages")
			check(scene._cleared_encounters.has("ch1_05/event"),
				"chain_ch1_event_settled")
			check(scene._cleared_in_chapter == 5, "chain_ch1_five_clears")
			continue
		await _chain_clear_arena(scene,
			scene._mds_world.room_node.get_node_or_null("Arena") as ArenaRoom,
			"ch1_room_%d" % room_number)
		await _chain_take_rest_reward(scene, "ch1_room_%d" % room_number)
		# The Chapter 1 event room (room 5) counts as one clear too, so a combat
		# room's clear count equals its room number on this route.
		var expected_clears: int = room_number
		check(scene._cleared_in_chapter == expected_clears,
			"chain_ch1_clear_count_%d" % room_number)
		if room_number == 3:
			# Optional vault through its interact door and back.
			check(await _chain_use_gate(scene, "door1", "ch1_vault"),
				"chain_ch1_vault_entered")
			check(scene._chests.size() >= 1 and scene._steles.size() >= 1,
				"chain_ch1_vault_content")
			check(await _chain_use_gate(scene, "door1", "ch1_03"),
				"chain_ch1_vault_returned")
	check(scene._cleared_in_chapter == 6, "chain_ch1_six_clears")
	check(await _chain_use_gate(scene, "right1", "ch1_rest"), "chain_ch1_rest_room")
	check(await _chain_use_gate(scene, "right1", "ch1_boss"), "chain_ch1_boss_room")
	await process_frame
	var ch1_boss_arena := scene._mds_world.room_node.get_node_or_null("Arena") as ArenaRoom
	check(scene._boss is InkArchivistCh1, "chain_ch1_boss_scene")
	check(ch1_boss_arena != null, "chain_ch1_boss_arena")
	if ch1_boss_arena != null and scene._boss != null:
		scene.player._invulnerable_left = 999.0
		scene.player.global_position = ch1_boss_arena.global_position + Vector2(0, -120)
		scene.player.velocity = Vector2.ZERO
		scene._update_room_locks()
		check(ch1_boss_arena.is_locked(), "chain_ch1_boss_locks")
		scene._boss.take_damage(100000)
	check(await _wait_authority_choice(scene, 5.0), "chain_ch1_authority_opens")
	scene._authority_choice._choose(0)
	await create_timer(0.4).timeout
	check(scene.run_state.authority != null, "chain_ch1_authority_applied")
	check(scene._authority_granted_chapter == 0, "chain_ch1_authority_chapter")
	check(await _wait_story(scene, 4.0), "chain_ch1_outro")
	check(_chain_voice_ends_with("ch1_outro.ogg"), "chain_ch1_outro_voice")
	scene._story.close()
	await create_timer(0.25).timeout
	check(scene._story.is_open() and scene._story._choice_mode, "chain_ch1_end_choice")
	check(not flow.profile.demo_cleared, "chain_ch1_demo_not_cleared_yet")
	scene._story.choose(0)
	# --- Handoff 1 -> 2.
	check(await _chain_wait_intro(scene, 1, 4.0), "chain_handoff_1_opens_chapter_2")
	check(not scene._finished, "chain_handoff_1_no_ending")
	check(flow.profile.demo_cleared, "chain_handoff_1_demo_cleared")
	var disk_profile := Profile.new()
	root.add_child(disk_profile)
	check(disk_profile.load_profile(CHAIN_PROFILE_PATH) and disk_profile.demo_cleared,
		"chain_handoff_1_demo_cleared_on_disk")
	disk_profile.queue_free()
	check(scene._mercy == 1, "chain_handoff_1_mercy_choice_applied")
	await _chain_check_chapter_opening(scene, 1)
	_chain_read_save("ch2_entry", {
		"chapter": 1,
		"room": "ch2_entry",
		"cleared": 0,
		"mercy": 1,
		"pages_min": 12,
		"encounters_empty": true,
		"boss_defeated": false,
	})
	# --- Chapter 2 -> handoff 2 -> 3.
	await _chain_walk_big_map(scene, 0, 1)
	check(await _chain_wait_intro(scene, 2, 4.0), "chain_handoff_2_opens_chapter_3")
	check(not scene._finished, "chain_handoff_2_no_ending")
	check(scene._mercy == 2, "chain_handoff_2_mercy_accumulated")
	check(flow.profile.endings.is_empty(), "chain_handoff_2_records_no_ending")
	await _chain_check_chapter_opening(scene, 2)
	_chain_read_save("ch3_entry", {
		"chapter": 2,
		"room": "ch3_entry",
		"cleared": 0,
		"mercy": 2,
		"encounters_empty": true,
		"boss_defeated": false,
	})
	# --- Chapter 3 -> handoff 3 -> 4.
	await _chain_walk_big_map(scene, 0, 2)
	check(await _chain_wait_intro(scene, 3, 4.0), "chain_handoff_3_opens_chapter_4")
	check(not scene._finished, "chain_handoff_3_no_ending")
	check(scene._mercy == 3, "chain_handoff_3_mercy_accumulated")
	check(flow.profile.endings.is_empty(), "chain_handoff_3_records_no_ending")
	await _chain_check_chapter_opening(scene, 3)
	_chain_read_save("ch4_entry", {
		"chapter": 3,
		"room": "ch4_entry",
		"cleared": 0,
		"mercy": 3,
		"encounters_empty": true,
		"boss_defeated": false,
	})
	# --- Chapter 4: burn the roster and end the campaign.
	await _chain_walk_big_map(scene, 1, 3)
	check(scene._burned_final, "chain_ch4_burned_flag")
	check(await _chain_wait_finished(scene, 4.0), "chain_campaign_ends")
	check(scene.ending_screen.visible, "chain_ending_screen")
	check(flow.last_ending.get("id", &"") == &"burned", "chain_burned_ending")
	check(paused, "chain_ending_pauses")
	check(flow.profile.endings.has("burned"), "chain_burned_recorded")
	check(not FileAccess.file_exists(CHAIN_RUN_PATH), "chain_ending_clears_checkpoint")
	var burned_title := scene.ending_screen.get_node_or_null(
		"Center/Panel/Margin/VBox/Title") as Label
	check(burned_title != null and burned_title.text == "焚毁档案",
		"chain_burned_end_screen_title")
	check(_chain_voice_ends_with("ending_burned.ogg"), "chain_burned_ending_voice")
	# `ending_for` has no chapter term (CampaignData): the judgement point is the
	# campaign end, so the same merciful run reaches `restored` when the final
	# choice rewrites the roster instead of burning it. The README line naming
	# the third chapter end as that point is stale copy (recorded in the pass-97
	# notes); the rule itself is untouched here.
	check(CampaignData.ending_for(true, 0, 3, false).get("id", &"") == &"restored",
		"chain_restored_rule_reachable")
	check(CampaignData.ending_for(true, 0, 0, true).get("id", &"") == &"burned",
		"chain_burned_rule_wins")
	# --- Cross-chapter carry-over: replay the Chapter 4 boss-death checkpoint.
	# It was written before Chapter 4's authority pick, carrying the Chapter 3
	# authority. Resuming must keep the inherited authority, still offer this
	# chapter's pick (pass 83), name the objective after Chapter 4's boss
	# (pass 84), and never spawn a second boss.
	paused = false
	root.remove_child(scene)
	scene.free()
	await process_frame
	check(not _chain_boss_checkpoint.is_empty(), "chain_boss_snapshot_captured")
	if _chain_boss_checkpoint.is_empty():
		_chain_cleanup(flow)
		return
	check(RunSave.write(_chain_boss_checkpoint, CHAIN_RUN_PATH), "chain_snapshot_written")
	flow.resume_requested = true
	var resumed = load("res://scenes/main.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	await create_timer(0.5).timeout
	check(await _wait_mds(resumed), "chain_resume_boots")
	check(resumed._chapter == 3, "chain_resume_chapter_4")
	check(resumed._mds_world.current_room == "ch4_boss", "chain_resume_boss_room")
	check(resumed._boss == null, "chain_resume_no_second_boss")
	check(resumed._boss_defeated, "chain_resume_boss_defeated")
	check(resumed.run_state.authority != null, "chain_resume_authority_carried")
	check(resumed._authority_granted_chapter == 2,
		"chain_resume_authority_chapter_carried")
	var objective := resumed.hud.find_child("Objective", true, false) as Label
	check(objective != null and objective.text == "笑面史官已经倒下",
		"chain_resume_objective_uses_this_chapter_boss")
	# Pass 97 regression: the checkpoint restores the player inside the boss
	# arena, so the lock pass must not re-arm a room whose boss is already down.
	# Before the fix it re-locked the arena, replayed the boss entrance sting and
	# replaced the "已经倒下" objective with a fresh kill order while the
	# authority pick was already pending.
	var resume_boss_arena: ArenaRoom = resumed._mds_boss_arena
	check(resume_boss_arena != null and not resume_boss_arena.is_locked(),
		"chain_resume_dead_boss_room_stays_open")
	check(not resumed._boss_entrance_started,
		"chain_resume_dead_boss_no_entrance_replay")
	check(_chain_music_is(String(CampaignData.chapter(3)["music"])),
		"chain_resume_dead_boss_keeps_chapter_music")
	check(await _wait_authority_choice(resumed, 6.0),
		"chain_resume_authority_pick_offered")
	resumed._authority_choice._choose(0)
	await create_timer(0.4).timeout
	check(resumed._authority_granted_chapter == 3,
		"chain_resume_authority_chapter_updated")
	check(await _wait_story(resumed, 5.0), "chain_resume_outro")
	check(_chain_voice_ends_with("ch4_outro.ogg"), "chain_resume_outro_voice")
	resumed._story.close()
	await create_timer(0.3).timeout
	check(resumed._story.is_open() and resumed._story._choice_mode,
		"chain_resume_end_choice")
	resumed._story.choose(0)
	check(await _chain_wait_finished(resumed, 4.0), "chain_resume_campaign_ends")
	check(flow.last_ending.get("id", &"") == &"restored", "chain_resume_restored_ending")
	check(flow.profile.endings.has("burned") and flow.profile.endings.has("restored"),
		"chain_both_endings_recorded")
	var restored_title := resumed.ending_screen.get_node_or_null(
		"Center/Panel/Margin/VBox/Title") as Label
	check(restored_title != null and restored_title.text == "复原",
		"chain_restored_end_screen_title")
	var echoes := resumed.ending_screen.get_node_or_null(
		"Center/Panel/Margin/VBox/Echoes") as Label
	check(echoes != null and not echoes.text.is_empty(), "chain_restored_end_echoes")
	# The end screen and the gallery read the same record.
	var gallery := EndingGalleryUI.new()
	root.add_child(gallery)
	gallery.open(flow.profile)
	var restored_index := -1
	var burned_index := -1
	for index in gallery.get_entry_count():
		var text := gallery.get_entry_text(index)
		if text.begins_with("复原"):
			restored_index = index
		elif text.begins_with("焚毁档案"):
			burned_index = index
	check(restored_index >= 0 and gallery.is_unlocked(restored_index),
		"chain_gallery_restored_unlocked")
	check(burned_index >= 0 and gallery.is_unlocked(burned_index),
		"chain_gallery_burned_unlocked")
	gallery.close()
	gallery.queue_free()
	paused = false
	root.remove_child(resumed)
	resumed.free()
	await process_frame
	_chain_cleanup(flow)


func _chain_wait_finished(scene, timeout := 4.0) -> bool:
	var left := timeout
	while left > 0.0:
		if scene._finished:
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false
