extends SceneTree

## Chapter 3 big-map acceptance: the real nine-region world and its door graph,
## camera/fall limits, vertical transit, hidden vault, one-shot content, the
## two-arena region, the event page, the shortcut barrier, a world-level save /
## resume, the Last Reader boss and the chapter-3 boundary.
##
## The campaign loads this big-map world for Chapter 3 (pass 80); since pass 91
## the chapter-3 boundary hands off into the Chapter 4 big map instead of ending.
## This suite attaches the chapter-3 plan and the big-map world to the live main
## scene for the checks only; it never touches `CHAPTER_PLAN_PATHS` or chapter
## routing.

var failures: int = 0
var assertions: int = 0
var arrival: Dictionary = {}
## Gate count per region that passed the visual checks, to prove all nine
## regions' gates carry the pipeline's doorway visual.
var gate_visual_regions: Dictionary = {}
## Per-region side histogram and [connected, arrival] split, so the run can
## prove the 22 gates really are 5 left + 5 right + 5 top + 5 bot + 2 mid-room
## doors, 20 with a destination and 2 arrival-only.
var gate_visual_sides: Dictionary = {}
var gate_visual_kinds: Dictionary = {}
## Every `room/gate` the walk really used, to prove the graph is not just read.
var walked: Dictionary = {}

const RUN_PATH := "user://test_ch3_bigmap_run.cfg"
const PROFILE_PATH := "user://test_ch3_bigmap_profile.cfg"
const CH3_WORLD_FILE := "res://scenes/mds/chapter_3_bigmap.mdsworld.json"

## Every connected gate in the nine-region graph, in one walkable order:
## [gate in the current room, region it leads to, gate it arrives at].
## Revisited gates are fine; the run ends at the boss dead end.
const WALK: Array = [
	["right1", "ch3_branch_a", "left1"],
	["left1", "ch3_entry", "right1"],
	["bot1", "ch3_branch_b", "top1"],
	["bot1", "ch3_vault", "top1"],
	["top1", "ch3_branch_b", "bot1"],
	["right1", "ch3_hub", "left1"],
	["left1", "ch3_branch_b", "right1"],
	["top1", "ch3_entry", "bot1"],
	["bot1", "ch3_branch_b", "top1"],
	["right1", "ch3_hub", "left1"],
	["top1", "ch3_branch_a", "bot1"],
	["bot1", "ch3_hub", "top1"],
	["bot1", "ch3_well", "top1"],
	["top1", "ch3_hub", "bot1"],
	["right1", "ch3_event", "left1"],
	["left1", "ch3_hub", "right1"],
	["right1", "ch3_event", "left1"],
	["bot1", "ch3_elite", "top1"],
	["top1", "ch3_event", "bot1"],
	["left1", "ch3_hub", "right1"],
	["shortcut", "ch3_entry", "shortcut_arrival"],
	["right1", "ch3_branch_a", "left1"],
	["bot1", "ch3_hub", "top1"],
	["bot1", "ch3_well", "top1"],
	["right1", "ch3_elite", "left1"],
	["left1", "ch3_well", "right1"],
	["right1", "ch3_elite", "left1"],
	["right1", "ch3_boss", "left1"],
]


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("CH3 BIGMAP FAIL: " + label)


func _on_room_loaded_capture(room_id: String) -> void:
	var scene = current_scene
	if scene == null or scene.player == null:
		return
	arrival = {
		"room": room_id,
		"pos": scene.player.global_position,
		"vel": scene.player.velocity,
	}


func _wait_mds(scene, timeout := 10.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._mds_world != null and not scene._mds_world.changing_room \
				and not scene._mds_world.current_room.is_empty():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _wait_room(scene, room_id: String, timeout := 8.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if not scene._mds_world.changing_room \
				and scene._mds_world.current_room == room_id:
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _wait_reward(scene, timeout := 3.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._reward_ui.visible:
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _wait_story(scene, timeout := 5.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._story != null and scene._story.is_open():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _wait_authority_choice(scene, timeout := 5.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._authority_choice != null and scene._authority_choice.is_open():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _close_story(scene) -> void:
	if scene._story != null and scene._story.is_open():
		scene._story.close()


func _free_scene(scene) -> void:
	paused = false
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame
	await process_frame


func _cleanup_files() -> void:
	RunSave.clear(RUN_PATH)
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = PROFILE_PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _objective_text(scene) -> String:
	var label := scene.hud.find_child("Objective", true, false) as Label
	return label.text if label != null else ""


func _progress_text(scene) -> String:
	var label := scene.hud.find_child("Progress", true, false) as Label
	return label.text if label != null else ""


## Attaches the chapter-3 plan and the real big-map world to the live scene,
## exactly the way the game builds a chapter world, but with the plan the
## campaign does not load yet. `save_data` restores a world-level checkpoint
## (the same dictionary `_build_run_save` stores under `mds`).
func _mount_chapter_3(scene, start_room := "ch3_entry",
		save_data: Dictionary = {}, reset_progress := true) -> bool:
	var plan := load("res://resources/chapters/chapter_3_demo.tres") as ChapterPlanData
	if plan == null or not plan.big_map:
		return false
	scene._teardown_mds(false)
	scene._chapter = 2
	scene._chapter_plan = plan
	scene._mds_active = true
	scene._event_room_id = ""
	scene._ending_pending = false
	scene._finished = false
	paused = false
	if reset_progress:
		scene._cleared_encounters.clear()
		scene._legacy_cleared_rooms.clear()
		scene._discovered_vaults.clear()
		scene._claimed_steles.clear()
		scene._legacy_claimed_steles.clear()
		scene._opened_chests.clear()
		scene._legacy_opened_chests.clear()
		scene._shop_cache.clear()
		scene._cleared_in_chapter = 0
		scene._boss_defeated = false
		scene._boss_aftermath_started = false
		scene._boss = null
	scene._map_overlay.set_chapter(2)
	scene._map_overlay.set_world(CH3_WORLD_FILE)
	var chapter := CampaignData.chapter(2)
	var flow := root.get_node_or_null("Flow") as GameFlow
	var difficulty: int = flow.difficulty if flow != null else 0
	scene.hud.set_region("%s · %s" % [chapter["region"],
		Difficulty.display_name(difficulty)])
	scene.hud.set_progress(scene._cleared_in_chapter, scene._chapter_progress_total())
	scene.hud.set_objective(String(chapter["objective"]))
	scene.hud.hide_boss()
	var camera := scene.player.get_node_or_null("Camera2D") as Camera2D
	var world := (load("res://scenes/mds/chapter_3_bigmap_world.tscn")
		as PackedScene).instantiate() as MDSWorldGame
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.player = scene.player
	world.camera = camera
	world.world_file = CH3_WORLD_FILE
	world.starting_room = start_room
	if not save_data.is_empty():
		world.set_save_data(save_data)
	world.map_view = scene._map_overlay.map_view
	world.room_loaded.connect(scene._on_mds_room_loaded)
	scene.add_child(world)
	scene._mds_world = world
	if not await _wait_mds(scene):
		return false
	if save_data.is_empty():
		return await _wait_room(scene, start_room)
	return true


## One room's structural/camera/fall/backdrop check, run after every real arrival.
func _check_region(scene, room_id: String) -> void:
	var mds = scene._mds_world
	var plan: ChapterPlanData = scene._chapter_plan
	var room := mds.room_node as MDSBigRoom
	check(room != null, "region_pipeline_%s" % room_id)
	if room == null or plan == null:
		return
	var size := plan.region_size(room_id)
	var bounds: Rect2 = mds.world.get_room_bounds(room_id)
	check(room.validation_errors.is_empty(), "region_geometry_%s" % room_id)
	check(mds.world.has_room(room_id), "region_world_room_%s" % room_id)
	check(bounds.size == Vector2(size), "region_bounds_%s" % room_id)
	check(room.room_bounds.size == Vector2(size), "region_room_bounds_%s" % room_id)
	check(is_equal_approx(scene._fall_limit_local, float(size.y) + 240.0),
		"region_fall_limit_%s" % room_id)
	check(is_equal_approx(scene._fall_limit_local, plan.region_fall_limit(room_id)),
		"region_fall_matches_plan_%s" % room_id)
	var cam := scene.player.get_node_or_null("Camera2D") as Camera2D
	check(cam != null, "region_camera_%s" % room_id)
	if cam != null:
		check(cam.limit_left == int(bounds.position.x), "region_camera_left_%s" % room_id)
		check(cam.limit_top == int(bounds.position.y), "region_camera_top_%s" % room_id)
		check(cam.limit_right == int(bounds.end.x), "region_camera_right_%s" % room_id)
		check(cam.limit_bottom == int(bounds.end.y), "region_camera_bottom_%s" % room_id)
	check(mds.world.room_contains(room_id, scene.player.global_position),
		"region_player_inside_%s" % room_id)
	# Chapter 3's nine regions are authored as single rectangles, so MDS's
	# camera has no partition to switch between; record that state explicitly.
	check(mds.world.get_local_rects(room_id).size() == 1,
		"region_single_rect_%s" % room_id)
	check(String(room.area_info.get("area", "")) == "Lightless Sea",
		"region_area_%s" % room_id)
	_check_backdrop(room, room_id)
	_check_weather(mds, room, room_id)
	_check_background(mds, room, room_id)
	_check_gate_visuals(mds, room, room_id)


## The lightless sea is a tiled painted backdrop (no pixel-art filter) and the
## current big-map pipeline adds no separate sea layer or darkness pass.
func _check_backdrop(room: MDSBigRoom, room_id: String) -> void:
	check(not room.backdrop_tiles.is_empty(), "region_backdrop_%s" % room_id)
	if room.backdrop_tiles.is_empty():
		return
	var texture: Texture2D = room.backdrop_tiles[0].texture
	check(texture != null, "region_backdrop_texture_%s" % room_id)
	if texture != null:
		check(texture.resource_path.ends_with("assets/backgrounds/regions/%s.webp" % room_id),
			"region_backdrop_lightless_sea_%s" % room_id)
		var tile_size := Vector2(texture.get_width(), texture.get_height())
		var columns := maxi(1, int(ceilf(room.room_bounds.size.x / tile_size.x)))
		var rows := maxi(1, int(ceilf(room.room_bounds.size.y / tile_size.y)))
		check(room.backdrop_tiles.size() == columns * rows,
			"region_backdrop_tiles_%s" % room_id)
		# The grid is floor-anchored and mirrored above the bottom row, so the
		# painting's own floor line sits on the room floor and every seam is a
		# matched edge row rather than a sky/foreground butt joint.
		var bottom := room.backdrop_tiles[room.backdrop_tiles.size() - columns]
		check(not bottom.flip_v, "region_backdrop_floor_upright_%s" % room_id)
		check(is_equal_approx(bottom.position.y + tile_size.y * 0.5,
			room.room_bounds.end.y), "region_backdrop_floor_anchored_%s" % room_id)
		var mirrored := true
		for index in range(room.backdrop_tiles.size() - columns):
			if room.backdrop_tiles[index].flip_v \
					== room.backdrop_tiles[index + columns].flip_v:
				mirrored = false
		check(mirrored, "region_backdrop_rows_mirrored_%s" % room_id)
	check(room.data != null and not room.data.backdrop_pixel_art,
		"region_backdrop_not_pixel_art_%s" % room_id)
	for tile in room.backdrop_tiles:
		check(tile.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR,
			"region_backdrop_linear_%s" % room_id)
	var sea_layers := 0
	for node in room.find_children("*", "", true, false):
		if node is LivingBackdrop:
			sea_layers += 1
	check(sea_layers == 0, "region_no_sea_layer_%s" % room_id)


## The area's fog + rain really reach the room; the lightless-sea motif is
## recorded as authored, not re-designed here.
func _check_weather(mds, room: MDSBigRoom, room_id: String) -> void:
	var spec := String(room.area_info.get("weather", ""))
	check(spec.contains("fog"), "region_weather_fog_%s" % room_id)
	check(spec.contains("rain"), "region_weather_rain_%s" % room_id)
	check(mds.weather != null, "region_weather_node_%s" % room_id)
	if mds.weather != null:
		check(mds.weather.name == MDSEnvironment.NODE_NAME,
			"region_weather_named_%s" % room_id)
		check(mds.weather.get_node_or_null("Fog") != null,
			"region_weather_fog_effect_%s" % room_id)
		check(mds.weather.get_node_or_null("Rain") != null,
			"region_weather_rain_effect_%s" % room_id)
	# 0.14: the Lightless Sea is dark (status #14 vision compression); the
	# player and enemies carry MDS lights, glowing props light their area.
	check(mds.room_darkness, "region_darkness_on_%s" % room_id)
	check(room.get_node_or_null("MDSDarkness") != null,
		"region_darkness_node_%s" % room_id)


## `deep_water` is the area's boss-room animated background; every other region
## has none. (The chapter-3 vision-compression decision stays open.)
func _check_background(mds, room: MDSBigRoom, room_id: String) -> void:
	var plan: ChapterPlanData = current_scene._chapter_plan
	var is_boss := plan != null \
		and String(plan.room(room_id).get("type", "")) == "boss"
	var background := String(room.area_info.get("background", ""))
	if is_boss:
		check(background == "deep_water", "region_boss_background_%s" % room_id)
		check(mds.background != null, "region_boss_background_node_%s" % room_id)
		check(mds.get_background_value(room_id) == "deep_water",
			"region_boss_background_spec_%s" % room_id)
	else:
		check(background == "", "region_plain_background_%s" % room_id)
		check(mds.background == null, "region_plain_background_node_%s" % room_id)


## Every world gate in the region has the shared pipeline's doorway visual:
## side matches the world file, the doorway rests on the real floor, the
## caption says where it leads (or "来路" for the arrival-only gates) and stays
## inside the room, and the marker adds no collision.
func _check_gate_visuals(mds, room: MDSBigRoom, room_id: String) -> void:
	var gate_names: Array = mds.world.get_gates(room_id).keys()
	var visual_gates := 0
	# Recount from scratch: a region can be revisited (reloads), and the
	# per-region entry must describe that room's gates, not an accumulation.
	var sides: Dictionary = {}
	var kinds: Array = [0, 0]
	for key in gate_names:
		var gate_name := String(key)
		var gate := MDSGate.find_gate(room, gate_name)
		check(gate != null, "region_gate_%s_%s" % [room_id, gate_name])
		if gate == null:
			continue
		var marker := gate.get_node_or_null(MDSBigRoom.GATE_VISUAL_NAME) as GateVisual
		check(marker != null, "region_gate_visual_%s_%s" % [room_id, gate_name])
		if marker == null:
			continue
		visual_gates += 1
		var side: String = mds.world.get_gate_side(room_id, gate_name)
		check(marker.visible and marker.is_visible_in_tree(),
			"region_gate_visual_visible_%s_%s" % [room_id, gate_name])
		check(marker.side == side,
			"region_gate_visual_side_%s_%s" % [room_id, gate_name])
		# The doorway is decoration only: it never moves its gate.
		check(marker.position == Vector2.ZERO,
			"region_gate_visual_keeps_gate_place_%s_%s" % [room_id, gate_name])
		_check_gate_doorway(room, gate, marker, side, room_id, gate_name)
		check(marker.caption_label() != null and not marker.caption_text().is_empty(),
			"region_gate_visual_caption_%s_%s" % [room_id, gate_name])
		if marker.caption_label() != null:
			_check_gate_caption(room, gate, marker, side, room_id, gate_name)
		var transition: Dictionary = mds.world.get_transition(room_id, gate_name)
		if transition.is_empty():
			# Arrival-only gates are the "来路" end: no destination, so the
			# marker draws no direction arrow (the drawing path keys on this).
			check(marker.arrival,
				"region_gate_visual_arrival_%s_%s" % [room_id, gate_name])
			check(marker.caption_text() == GateVisual.CAPTION_ARRIVAL,
				"region_gate_visual_arrival_copy_%s_%s" % [room_id, gate_name])
			kinds[1] = int(kinds[1]) + 1
		else:
			# A connected gate points at its destination and draws the chevron.
			check(not marker.arrival,
				"region_gate_visual_target_%s_%s" % [room_id, gate_name])
			var to_room := String(transition.get("room", ""))
			var to_name := str(mds.world.get_room_value(to_room, "name", to_room))
			check(marker.caption_text() == GateVisual.CAPTION_ARROW + to_name,
				"region_gate_visual_target_copy_%s_%s" % [room_id, gate_name])
			kinds[0] = int(kinds[0]) + 1
		sides[side] = int(sides.get(side, 0)) + 1
		# The presentation half must never add a second trigger or collide.
		check(marker.find_children("*", "CollisionObject2D", true, false).is_empty(),
			"region_gate_visual_no_collision_%s_%s" % [room_id, gate_name])
		check(marker.get_class() == "Node2D",
			"region_gate_visual_not_body_%s_%s" % [room_id, gate_name])
	check(visual_gates == gate_names.size(), "region_gate_visual_count_%s" % room_id)
	gate_visual_regions[room_id] = gate_names.size()
	gate_visual_sides[room_id] = sides
	gate_visual_kinds[room_id] = kinds


## Side-aware doorway placement: left/right doors unroll into the room and
## their bottom meets the real ground/step surface under the gate; door-side
## gates (the mid-room shortcut) stay centred; top/bot are the same texture
## laid on its side as a ceiling/floor hatch kept inside the room.
func _check_gate_doorway(room: MDSBigRoom, gate: MDSGate, marker: GateVisual,
		side: String, room_id: String, gate_name: String) -> void:
	var tag := "%s_%s" % [room_id, gate_name]
	var bounds := room.room_bounds
	var surface := _surface_below(room, gate.position.x, gate.position.y)
	match side:
		"left", "right":
			check(not is_inf(surface), "region_gate_visual_has_floor_%s" % tag)
			if not is_inf(surface):
				check(is_equal_approx(gate.position.y + marker.floor_offset, surface),
					"region_gate_visual_door_rests_on_floor_%s" % tag)
			var door_left := -GateVisual.WIDTH if side == "right" else 0.0
			var door_rect := Rect2(
				gate.position + Vector2(door_left, marker.floor_offset - GateVisual.HEIGHT),
				Vector2(GateVisual.WIDTH, GateVisual.HEIGHT))
			check(bounds.encloses(door_rect),
				"region_gate_visual_door_inside_room_%s" % tag)
		"door":
			check(not is_inf(surface), "region_gate_visual_has_floor_%s" % tag)
			if not is_inf(surface):
				check(is_equal_approx(gate.position.y + marker.floor_offset, surface),
					"region_gate_visual_door_rests_on_floor_%s" % tag)
			var mid_rect := Rect2(
				gate.position + Vector2(-GateVisual.WIDTH * 0.5,
					marker.floor_offset - GateVisual.HEIGHT),
				Vector2(GateVisual.WIDTH, GateVisual.HEIGHT))
			check(bounds.encloses(mid_rect),
				"region_gate_visual_door_inside_room_%s" % tag)
		"bot":
			# A floor hatch lies on the gate line itself (the floor surface).
			check(is_equal_approx(marker.floor_offset, 0.0),
				"region_gate_visual_floor_hatch_offset_%s" % tag)
			check(not is_inf(surface) and is_equal_approx(gate.position.y, surface),
				"region_gate_visual_floor_hatch_on_floor_%s" % tag)
			check(gate.position.y - GateVisual.HATCH_HALF * 2.0 >= bounds.position.y,
				"region_gate_visual_floor_hatch_inside_room_%s" % tag)
		"top":
			# A ceiling hatch hangs down into the room from the ceiling gate.
			check(gate.position.y - bounds.position.y <= 16.0,
				"region_gate_visual_ceiling_hatch_at_top_%s" % tag)
			check(gate.position.y + GateVisual.HATCH_HALF * 2.0 <= bounds.end.y,
				"region_gate_visual_ceiling_hatch_inside_room_%s" % tag)


## The caption is pulled into the room at edge gates so neither the door nor
## its label can fall outside the camera's room bounds, and sits above/below
## the doorway per side.
func _check_gate_caption(room: MDSBigRoom, gate: MDSGate, marker: GateVisual,
		side: String, room_id: String, gate_name: String) -> void:
	var tag := "%s_%s" % [room_id, gate_name]
	var label := marker.caption_label()
	var expected_x := -GateVisual.CAPTION_WIDTH * 0.5
	match side:
		"right":
			expected_x = -GateVisual.CAPTION_WIDTH
		"left":
			expected_x = 0.0
	var expected_y := marker.floor_offset - GateVisual.HEIGHT - 34.0
	match side:
		"top":
			expected_y = GateVisual.HATCH_HALF * 2.0 + 6.0
		"bot":
			expected_y = -GateVisual.HATCH_HALF * 2.0 - 32.0
	# MDSBigRoom hands every marker the room inset by the caption size, so the
	# side rule is clamped just like the room never lets the label overhang.
	var area := Rect2(
		room.room_bounds.position - gate.position,
		room.room_bounds.size - Vector2(GateVisual.CAPTION_WIDTH, GateVisual.CAPTION_HEIGHT))
	if area.size.x > 0.0:
		expected_x = clampf(expected_x, area.position.x, area.end.x)
		expected_y = clampf(expected_y, area.position.y, area.end.y)
	check(is_equal_approx(label.position.x, expected_x),
		"region_gate_visual_caption_inset_%s" % tag)
	check(is_equal_approx(label.position.y, expected_y),
		"region_gate_visual_caption_height_%s" % tag)
	var caption_rect := Rect2(gate.position + label.position, label.size)
	check(room.room_bounds.encloses(caption_rect),
		"region_gate_visual_caption_inside_room_%s" % tag)


## First walkable surface at or below [param y] under [param x], in room-local
## coordinates; the same rule MDSBigRoom uses to seat a side door on the floor.
func _surface_below(room: MDSBigRoom, x: float, y: float) -> float:
	var best := INF
	var surfaces: Array[Rect2] = []
	surfaces.append_array(room.built_ground_surfaces)
	surfaces.append_array(room.built_platform_surfaces)
	for rect in surfaces:
		if x < rect.position.x - 1.0 or x > rect.end.x + 1.0:
			continue
		if rect.position.y < y:
			continue
		best = minf(best, rect.position.y)
	return best


## Uses one gate and checks the transition, the exact arrival spot, the exit
## velocity rule, the region bounds/camera, and that no modal is stacked.
func _use_gate(scene, gate_name: String, expected_room: String,
		expected_gate: String) -> bool:
	var mds = scene._mds_world
	var from_room: String = mds.current_room
	var gate := MDSGate.find_gate(mds.room_node, gate_name)
	check(gate != null, "door_gate_present_%s_%s" % [from_room, gate_name])
	if gate == null:
		return false
	var transition: Dictionary = gate.get_transition()
	check(String(transition.get("room", "")) == expected_room,
		"door_target_%s_%s" % [from_room, gate_name])
	check(String(transition.get("gate", "")) == expected_gate,
		"door_arrival_gate_%s_%s" % [from_room, gate_name])
	# A floor arrival keeps its own gate inert for a beat; wait it out instead
	# of driving use() through the grace.
	var wait := 0.45
	if mds._arrival_gate == gate_name:
		var grace_left: float = float(
			mds._arrival_grace_until - Time.get_ticks_msec()) / 1000.0
		wait = maxf(wait, grace_left + 0.12)
	await create_timer(wait).timeout
	check(not mds.changing_room, "door_idle_before_use_%s_%s" % [from_room, gate_name])
	arrival = {}
	scene.player.velocity = Vector2.ZERO
	walked["%s/%s" % [from_room, gate_name]] = true
	gate.use()
	check(mds.changing_room, "door_transition_starts_%s_%s" % [from_room, gate_name])
	check(not paused, "door_not_paused_%s_%s" % [from_room, gate_name])
	var loaded := await _wait_room(scene, expected_room)
	check(loaded, "door_arrives_%s_%s" % [from_room, gate_name])
	if not loaded:
		return false
	check(not paused, "door_arrival_not_paused_%s_%s" % [from_room, gate_name])
	check(not scene._story.is_open(), "door_no_story_%s_%s" % [from_room, gate_name])
	check(not scene._reward_ui.visible, "door_no_reward_%s_%s" % [from_room, gate_name])
	check(not scene._map_overlay.is_open(), "door_no_map_%s_%s" % [from_room, gate_name])
	check(not scene._authority_choice.is_open(),
		"door_no_authority_%s_%s" % [from_room, gate_name])
	check(not scene._shop_ui.visible, "door_no_shop_%s_%s" % [from_room, gate_name])
	var target := MDSGate.find_gate(mds.room_node, expected_gate)
	check(target != null, "door_arrival_gate_present_%s_%s" % [from_room, gate_name])
	check(String(arrival.get("room", "")) == expected_room,
		"door_arrival_signal_%s_%s" % [from_room, gate_name])
	if target == null:
		return false
	var expected_pos: Vector2 = target.get_spawn_position()
	var captured_pos: Vector2 = arrival.get("pos", Vector2.ZERO)
	var velocity: Vector2 = arrival.get("vel", Vector2.ZERO)
	var side := target.get_side()
	# The capture lands a couple of physics frames after placement, so a floor
	# arrival is already a few pixels into its launch.
	check(absf(captured_pos.x - expected_pos.x) < 1.0,
		"door_arrival_x_%s_%s" % [from_room, gate_name])
	if side == "bot":
		check(captured_pos.y <= expected_pos.y + 0.5
			and captured_pos.y >= expected_pos.y - 24.0,
			"door_arrival_floor_liftoff_%s_%s" % [from_room, gate_name])
		check(velocity.y <= -600.0, "door_bot_exit_speed_%s_%s" % [from_room, gate_name])
	else:
		check(captured_pos.distance_to(expected_pos) < 3.0,
			"door_arrival_position_%s_%s" % [from_room, gate_name])
		if side == "top":
			check(velocity.y >= -0.001,
				"door_top_exit_velocity_%s_%s" % [from_room, gate_name])
		else:
			check(absf(velocity.x) < 0.001 and velocity.y >= -0.001,
				"door_side_exit_velocity_%s_%s" % [from_room, gate_name])
	check(mds.current_room == expected_room, "door_current_room_%s_%s" % [from_room, gate_name])
	_check_region(scene, expected_room)
	return true


func _arena_doors_locked(arena: ArenaRoom) -> bool:
	var doors := arena.get_node_or_null(ArenaRoom.DOORS_NODE)
	if doors == null or not doors.visible:
		return false
	var bodies := 0
	for child in doors.get_children():
		if child is CollisionObject2D:
			bodies += 1
			if (child as CollisionObject2D).collision_layer != 1:
				return false
	return bodies == 2


func _arena_doors_open(arena: ArenaRoom) -> bool:
	var doors := arena.get_node_or_null(ArenaRoom.DOORS_NODE)
	if doors == null or doors.visible:
		return false
	var bodies := 0
	for child in doors.get_children():
		if child is CollisionObject2D:
			bodies += 1
			if (child as CollisionObject2D).collision_layer != 0:
				return false
	return bodies == 2


## Kills the arena's current and queued waves through the real enemy exit path.
func _kill_arena(arena: ArenaRoom) -> bool:
	for _round in 8:
		var enemies := arena.get_node_or_null(ArenaRoom.ENEMIES_NODE)
		if enemies != null:
			for child in enemies.get_children():
				child.queue_free()
		for _frame in 4:
			await process_frame
		if arena.is_cleared():
			return true
	return false


func _enemy_ids(arena: ArenaRoom) -> PackedStringArray:
	var ids := PackedStringArray()
	if arena == null:
		return ids
	for child in arena.get_node(ArenaRoom.ENEMIES_NODE).get_children():
		if child is Enemy and child.data != null:
			ids.append(String(child.data.id))
	ids.sort()
	return ids


func _wave_ids(wave: Array) -> PackedStringArray:
	var ids := PackedStringArray()
	for id in wave:
		ids.append(String(id))
	ids.sort()
	return ids


## One spawned enemy's shared-path art. A wired enemy renders its own PNG at
## white; a fallback enemy keeps the Chapter 1 painting and the fallback tint.
## Pass 78 closed the Chapter 3 gap, so every call here now expects white.
func _check_enemy_art(arena: ArenaRoom, id: StringName, sprite_suffix: String,
		tint: Color) -> void:
	var found: Enemy = null
	for child in arena.get_node(ArenaRoom.ENEMIES_NODE).get_children():
		if child is Enemy and child.data != null and child.data.id == id:
			found = child
			break
	check(found != null, "ch3_enemy_present_%s" % id)
	if found == null:
		return
	check(found.sprite_visual != null, "ch3_enemy_sprite_%s" % id)
	if found.sprite_visual == null:
		return
	check(found.sprite_visual.texture != null
		and found.sprite_visual.texture.resource_path.ends_with(sprite_suffix),
		"ch3_enemy_art_%s" % id)
	check(found.sprite_visual.modulate == tint, "ch3_enemy_art_tint_%s" % id)


func _ground_surface_y(room: MDSBigRoom) -> float:
	if room != null and room.data != null and not room.data.ground.is_empty():
		var entry: Dictionary = room.data.ground[0]
		var value: Variant = entry.get("y", null)
		if value is int or value is float:
			return room.to_global(Vector2(0, float(value))).y
	return room.global_position.y + room.room_bounds.size.y


func _bfs_rooms(plan: ChapterPlanData) -> Dictionary:
	var seen: Dictionary = {}
	var start := plan.start_region()
	if start.is_empty():
		return seen
	seen[start] = true
	var queue: Array[String] = [start]
	while not queue.is_empty():
		var id: String = queue.pop_front()
		for door in plan.doors:
			if String(door.get("from", "")) != id:
				continue
			var to := String(door.get("to", ""))
			if to.is_empty() or seen.has(to):
				continue
			seen[to] = true
			queue.append(to)
	return seen


## Loads one region with the fade off and prints the raw build time (the same
## measurement the Chapter 2 acceptance used).
func _time_load(scene, room_id: String, label: String) -> void:
	var mds = scene._mds_world
	var started := Time.get_ticks_usec()
	await mds.load_room(room_id)
	var ok := await _wait_room(scene, room_id)
	var elapsed := (Time.get_ticks_usec() - started) / 1000.0
	check(ok, "perf_load_ok_%s" % label)
	print("PERF: %s = %.2f ms" % [label, elapsed])


func _run() -> void:
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.profile_path = PROFILE_PATH
	flow.run_save_path = RUN_PATH
	flow.title_shown_this_session = true
	flow.resume_requested = false
	_cleanup_files()

	# This suite checks the authored waves enemy by enemy.
	(root.get_node("Flow") as GameFlow).encounter_variation = false
	(root.get_node("Flow") as GameFlow).roaming_encounters = false
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.4).timeout
	_close_story(scene)
	check(await _wait_mds(scene), "boots_chapter_1")
	check(await _mount_chapter_3(scene), "chapter_3_bigmap_mounts")
	var mds = scene._mds_world
	mds.room_loaded.connect(_on_room_loaded_capture)
	var plan: ChapterPlanData = scene._chapter_plan
	check(plan != null and plan.big_map, "chapter_3_plan_is_big_map")
	if plan == null or not plan.big_map:
		_finish(scene)
		return

	# --- Pass 80 routes this plan and world into the campaign; pass 91 routes the
	# Chapter 4 pair too, and the legacy chapter-3/4 worlds stay on disk.
	var game_script := load("res://scripts/game.gd") as GDScript
	var constants: Dictionary = game_script.get_script_constant_map() if game_script != null else {}
	var plan_paths: Array = constants.get("CHAPTER_PLAN_PATHS", [])
	var world_files: Array = constants.get("MDS_WORLD_FILES", [])
	var chapter_scenes: Array = constants.get("MDS_CHAPTER_SCENES", [])
	check(plan_paths.size() == 4, "game_keeps_four_plan_slots")
	if plan_paths.size() == 4:
		check(String(plan_paths[2]).ends_with("chapter_3_demo.tres"),
			"chapter_3_plan_slot_wired")
		check(String(plan_paths[3]).ends_with("chapter_4_demo.tres"),
			"chapter_4_plan_slot_wired")
	check(world_files.size() == 4, "game_keeps_four_world_files")
	if world_files.size() == 4:
		check(String(world_files[2]).ends_with("chapter_3_bigmap.mdsworld.json"),
			"chapter_3_loads_big_map_world")
		check(String(world_files[3]).ends_with("chapter_4_bigmap.mdsworld.json"),
			"chapter_4_loads_big_map_world")
	check(chapter_scenes.size() == 4, "game_keeps_four_world_scenes")
	if chapter_scenes.size() == 4:
		check((chapter_scenes[2] as PackedScene).resource_path
			== "res://scenes/mds/chapter_3_bigmap_world.tscn",
			"chapter_3_uses_big_map_world_scene")
	check(FileAccess.file_exists("res://scenes/mds/chapter_3.mdsworld.json"),
		"legacy_chapter_3_world_exists")
	check(FileAccess.file_exists("res://scenes/mds/chapter_3_world.tscn"),
		"legacy_chapter_3_world_scene_exists")
	check(plan.start_region() == "ch3_entry", "chapter_3_starts_at_entry")
	check(plan.clear_target() == 7, "chapter_3_clear_target_seven")
	check(plan.encounter_ids().size() == 7, "chapter_3_seven_encounters")
	check(not plan.content_pending, "chapter_3_content_landed")
	check(plan.boss_scene != null
		and plan.boss_scene.resource_path == "res://scenes/bosses/last_reader.tscn",
		"chapter_3_boss_scene_routes_last_reader")
	var plan_authority_ids: Array[StringName] = []
	for authority in plan.authority_pool:
		plan_authority_ids.append(authority.id)
	check(plan_authority_ids.has(&"revive") and plan_authority_ids.has(&"rewrite"),
		"chapter_3_authority_pool_has_base")
	check(plan.wave_for("ch3_boss", "ch3_boss/Arena").is_empty(),
		"chapter_3_boss_has_no_ordinary_wave")
	check(plan.wave_for("ch3_event", "ch3_event/event").is_empty(),
		"chapter_3_event_has_no_ordinary_wave")

	# --- Plan graph: the entry reaches every region, doors are mirrored unless
	# explicitly one-way, and the only requirement is the shortcut ability.
	check(scene._chapter == 2, "running_chapter_3")
	check(mds.current_room == "ch3_entry", "chapter_3_starts_at_entry_room")
	check(mds.current_room == plan.start_region(), "chapter_3_start_from_plan")
	check(scene._chapter_clear_target() == 7, "chapter_3_runtime_clear_target")
	check(scene._chapter_progress_total() == 8, "chapter_3_progress_total_includes_boss")
	check(is_equal_approx(scene._fall_limit_local, 1680.0), "chapter_3_entry_fall_plane")
	check(not scene._story.is_open() and not paused, "chapter_3_no_intro_modal")
	check(_progress_text(scene) == "档案  0 / 8", "chapter_3_hud_progress_starts")
	# The chapter table carries the campaign objective, but the loaded room owns
	# the HUD line: `ch3_entry` is a no-combat region, so its runtime objective
	# replaces the chapter line the moment the room reports in.
	check(not String(CampaignData.chapter(2)["objective"]).is_empty(),
		"chapter_3_objective_authored")
	# `ch3_entry` has no combat and no rest facilities, so it must not borrow
	# the shop/bench arrival copy; the objective only points onward.
	check(_objective_text(scene) == "继续前进", "chapter_3_hud_entry_objective")
	check(not scene._rest_greeted.has("ch3_entry"), "chapter_3_entry_no_rest_copy")

	# Map overlay: chapter 3 derives its title from the authored region, and the
	# overlay draws the chapter-3 big-map world rather than the legacy one.
	check(String(CampaignData.chapter(2).get("region", "")) == "无光海",
		"chapter_3_region_authored")
	check(scene._map_overlay.title_text() == "无光海地图", "chapter_3_map_title")
	check(scene._map_overlay.map_view.world_file == CH3_WORLD_FILE,
		"chapter_3_map_uses_bigmap_world")
	check(scene._map_overlay.map_view.world != null
		and scene._map_overlay.map_view.world.get_room_ids().size() == 9,
		"chapter_3_map_has_nine_regions")
	var map_view = scene._map_overlay.map_view
	map_view.reveal_all = false
	check(map_view.is_room_revealed("ch3_entry"), "map_reveals_entry")
	check(not map_view.is_room_revealed("ch3_vault"), "map_hides_vault")

	var reachable := _bfs_rooms(plan)
	check(reachable.size() == plan.room_ids().size(), "chapter_3_all_regions_reachable")
	for room_id in plan.room_ids():
		check(reachable.has(String(room_id)), "chapter_3_reachable_%s" % room_id)
	check(reachable.has("ch3_hub"), "chapter_3_hub_reachable")
	check(reachable.has("ch3_vault"), "chapter_3_vault_reachable")
	check(reachable.has("ch3_event"), "chapter_3_event_reachable")
	check(reachable.has("ch3_boss"), "chapter_3_boss_reachable")
	var one_way_doors: Array[String] = []
	for door in plan.doors:
		var door_id := String(door.get("id", ""))
		check(not String(door.get("from", "")).is_empty(), "door_from_%s" % door_id)
		check(not String(door.get("to", "")).is_empty(), "door_to_%s" % door_id)
		if bool(door.get("one_way", false)):
			one_way_doors.append(door_id)
			continue
		# The plan lists each connection once; the world must carry the mirrored
		# gate so the player can come back.
		var reverse: Dictionary = mds.world.get_transition(
			String(door.get("to", "")), String(door.get("to_gate", "")))
		check(String(reverse.get("room", "")) == String(door.get("from", "")),
			"door_two_way_room_%s" % door_id)
		check(String(reverse.get("gate", "")) == String(door.get("from_gate", "")),
			"door_two_way_gate_%s" % door_id)
	check(one_way_doors.size() == 2, "chapter_3_two_one_way_doors")
	check(one_way_doors.has("elite_boss"), "chapter_3_elite_boss_one_way")
	check(one_way_doors.has("hub_shortcut_entry"), "chapter_3_shortcut_one_way")
	var shortcut_doors := 0
	for door in plan.doors:
		var requires: Array = door.get("requires", [])
		if requires.is_empty():
			continue
		shortcut_doors += 1
		check(String(door.get("from", "")) == "ch3_hub", "shortcut_from_hub")
		check(String(door.get("from_gate", "")) == "shortcut", "shortcut_gate_name")
		check(requires.size() == 1 and String(requires[0]) == "ch3_shortcut",
			"shortcut_requires_ability")
	check(shortcut_doors == 1, "chapter_3_single_required_door")
	check(plan.shortcut_ids().has("hub_shortcut_entry"), "chapter_3_shortcut_planned")

	# The runtime world graph: exactly 20 connected gates plus 2 arrival-only
	# gates, which the walk below has to use in full.
	var connected_gates: Dictionary = {}
	var arrival_gates: Dictionary = {}
	for world_room in mds.world.get_room_ids():
		var rid := String(world_room)
		for key in mds.world.get_gates(rid).keys():
			var gate_key := "%s/%s" % [rid, String(key)]
			if mds.world.get_transition(rid, String(key)).is_empty():
				arrival_gates[gate_key] = true
			else:
				connected_gates[gate_key] = true
	check(connected_gates.size() == 20, "world_has_twenty_connected_gates")
	check(arrival_gates.size() == 2, "world_has_two_arrival_gates")
	check(arrival_gates.has("ch3_entry/shortcut_arrival"),
		"world_shortcut_arrival_is_arrival_only")
	check(arrival_gates.has("ch3_boss/left1"), "world_boss_gate_is_arrival_only")

	# --- Fresh-run spawn: `ch3_entry` authors a save_point marker on its first
	# step, so MDS prefers it over the room-label anchor (mid-air for a
	# 2560x1440 region) and the player stands on the step from the first frame.
	var spawn := mds.room_node.get_node_or_null("SpawnPoint") as Marker2D
	check(spawn != null, "entry_spawn_marker_present")
	if spawn != null:
		var entry_room := mds.room_node as MDSBigRoom
		var step_top := 0.0
		if entry_room != null and entry_room.data != null \
				and not entry_room.data.platforms.is_empty():
			var step: Dictionary = entry_room.data.platforms[0]
			step_top = entry_room.to_global(Vector2(0.0, float(step.get("y", 0.0)))).y
		check(spawn.is_in_group(&"save_point"), "entry_spawn_marker_group")
		check(is_equal_approx(spawn.global_position.y, step_top - Player.FOOT_Y),
			"entry_spawn_stands_on_step")
		check(scene.player.global_position.distance_to(spawn.global_position) < 2.0,
			"entry_spawn_uses_marker")
		check(mds._spawn_position("ch3_entry", "", Vector2.INF)
			.distance_to(spawn.global_position) < 1.0, "entry_spawn_precedes_label")
		var label_pos: Vector2 = mds.world.get_room_label_pos("ch3_entry")
		check(spawn.global_position.y > label_pos.y + 400.0,
			"entry_spawn_not_room_label_anchor")
		var settled: Vector2 = scene.player.global_position
		await physics_frame
		check(scene.player.is_on_floor(), "entry_spawn_on_floor")
		await create_timer(0.3).timeout
		check(scene.player.global_position.distance_to(settled) < 1.0,
			"entry_spawn_no_air_fall")
	_check_region(scene, "ch3_entry")

	# Keep the player alive while the suite drives him through live arenas; the
	# damage checks below clear this again.
	scene.player._invulnerable_left = 10000

	# --- The event node is settled up front so walking through its region
	# during the graph sweep cannot open a paused page mid-transition. The event
	# trigger gets its own fresh section later.
	scene._cleared_encounters["ch3_event/event"] = true
	scene._cleared_in_chapter = 1

	# --- Hidden vault: first discovery, map reveal, and one-shot chest/stele
	# that stay settled through a room reload.
	await mds.load_room("ch3_vault")
	check(await _wait_room(scene, "ch3_vault"), "vault_loads")
	await process_frame
	var vault_line := VaultRoomData.pick(scene.run_state.run_seed, "ch3_vault")
	check(scene._discovered_vaults.has("ch3_vault"), "vault_first_discovery_recorded")
	check(scene.hud.get_message_text() == vault_line, "vault_first_discovery_copy")
	check(map_view.is_room_revealed("ch3_vault"), "vault_first_discovery_reveals_map")
	_check_region(scene, "ch3_vault")
	check(scene._chests.size() == 1, "vault_one_chest")
	check(scene._steles.size() == 1, "vault_one_stele")
	var vault_chest := mds.room_node.get_node_or_null("Chest1") as TreasureChest
	var vault_stele := mds.room_node.get_node_or_null("Stele1") as MemoryStele
	check(vault_chest != null and vault_stele != null, "vault_named_content")
	if vault_chest != null:
		scene._open_chest(vault_chest)
		await process_frame
	check(scene._opened_chests.has("ch3_vault/Chest1"), "vault_chest_one_shot")
	if vault_stele != null:
		scene.player.global_position = vault_stele.global_position
		scene.player.velocity = Vector2.ZERO
		await physics_frame
		scene._claim_nearest_stele()
		await process_frame
	check(scene._claimed_steles.has("ch3_vault/Stele1"), "vault_stele_one_shot")
	var after_claim_message: String = scene.hud.get_message_text()
	await mds.load_room("ch3_vault")
	check(await _wait_room(scene, "ch3_vault"), "vault_reloads")
	await process_frame
	var kept_chest := mds.room_node.get_node_or_null("Chest1") as TreasureChest
	check(kept_chest != null and kept_chest.is_open, "vault_chest_stays_open")
	check(scene._steles.is_empty(), "vault_claimed_stele_removed")
	check(scene.hud.get_message_text() == after_claim_message,
		"vault_reload_does_not_repeat_discovery")
	check(not scene._reward_ui.visible, "vault_no_false_reward")

	# --- The other three one-shot props (one chest in each of branch A and the
	# well, one stele in the hub) settle under their own node ids too.
	await mds.load_room("ch3_hub")
	check(await _wait_room(scene, "ch3_hub"), "hub_loads")
	await process_frame
	check(scene._shops.size() == 1, "hub_has_one_shop")
	if scene._shops.size() == 1:
		check(String(scene._shops[0].shop_id) == "ch3_hub_shop", "hub_shop_id")
	check(bool(plan.room("ch3_hub").get("rest", false)), "hub_is_rest_region")
	_check_region(scene, "ch3_hub")
	# The hub authors a Shop and a Bench, so it keeps the rest branch that the
	# entry region (same pipeline, no facilities) no longer takes.
	check(scene._rest_greeted.has("ch3_hub"), "chapter_3_hub_keeps_rest_copy")
	check(_objective_text(scene) == "休整，或继续前进", "chapter_3_hub_rest_objective")
	check(scene._steles.size() == 1, "hub_one_stele")
	var hub_stele := mds.room_node.get_node_or_null("Stele1") as MemoryStele
	if hub_stele != null:
		scene.player.global_position = hub_stele.global_position
		scene.player.velocity = Vector2.ZERO
		await physics_frame
		scene._claim_nearest_stele()
		await process_frame
	check(scene._claimed_steles.has("ch3_hub/Stele1"), "hub_stele_one_shot")
	await mds.load_room("ch3_hub")
	check(await _wait_room(scene, "ch3_hub"), "hub_reloads")
	await process_frame
	check(scene._steles.is_empty(), "hub_claimed_stele_removed")

	for chest_entry in [["ch3_branch_a", "ch3_branch_a/Chest1"],
			["ch3_well", "ch3_well/Chest1"]]:
		var chest_room := String(chest_entry[0])
		var chest_id := String(chest_entry[1])
		await mds.load_room(chest_room)
		check(await _wait_room(scene, chest_room), "chest_room_loads_%s" % chest_room)
		await process_frame
		_check_region(scene, chest_room)
		var chest := mds.room_node.get_node_or_null("Chest1") as TreasureChest
		check(chest != null, "chest_present_%s" % chest_room)
		if chest != null:
			scene._open_chest(chest)
			await process_frame
		check(scene._opened_chests.has(chest_id), "chest_one_shot_%s" % chest_room)
		await mds.load_room(chest_room)
		check(await _wait_room(scene, chest_room), "chest_room_reloads_%s" % chest_room)
		await process_frame
		var kept := mds.room_node.get_node_or_null("Chest1") as TreasureChest
		check(kept != null and kept.is_open, "chest_stays_open_%s" % chest_room)

	# --- Raw construction timing baseline, with the fade off so the number is
	# the room build (normal play covers it with the 0.22 s transition). Two
	# passes: the first visit of branch B / event / elite / boss is cold, the
	# second is hot; the rest were already loaded by the content checks above.
	var old_fade: float = mds.fade_time
	mds.fade_time = 0.0
	for room_id in plan.room_ids():
		await _time_load(scene, String(room_id), "first_%s" % room_id)
	for room_id in plan.room_ids():
		await _time_load(scene, String(room_id), "hot_%s" % room_id)
	mds.room_background = false
	await _time_load(scene, "ch3_boss", "boss_background_off")
	mds.room_background = true
	mds.room_weather = false
	await _time_load(scene, "ch3_boss", "boss_weather_off")
	mds.room_weather = true
	# Measure the boss region without spawning a boss. `_boss_defeated` makes
	# the room report the defeated state and defer the aftermath;
	# `_boss_aftermath_started` keeps that deferred call inert. The raw timing
	# block runs with the fade off, so the load can return before the
	# MessageQueue has run it: flush two frames while the guard is still up,
	# then restore the flags, or the aftermath would open the authority page
	# (pausing the tree) in the middle of the next transition.
	scene._boss_defeated = true
	scene._boss_aftermath_started = true
	await _time_load(scene, "ch3_boss", "boss_not_spawned")
	await process_frame
	await process_frame
	scene._boss_defeated = false
	scene._boss_aftermath_started = false
	mds.fade_time = old_fade
	# A real door transition with the authored fade: the wall-clock cost the
	# player actually sees, versus the raw build times above.
	await mds.load_room("ch3_entry")
	check(await _wait_room(scene, "ch3_entry"), "perf_restore_entry")
	# The arrival gate stays on cooldown for 0.35 s after the room reports in; a
	# real player cannot leave before it expires either, so wait it out before
	# timing the door.
	await create_timer(0.45).timeout
	var gate_started := Time.get_ticks_usec()
	var perf_gate := MDSGate.find_gate(mds.room_node, "right1")
	check(perf_gate != null, "perf_gate_present")
	if perf_gate != null:
		perf_gate.use()
		check(await _wait_room(scene, "ch3_branch_a"), "perf_gate_arrives")
		var gate_ms := (Time.get_ticks_usec() - gate_started) / 1000.0
		print("PERF: door_transition ch3_entry.right1 = %.2f ms" % gate_ms)
	check(not mds.seamless_rooms, "world_is_not_seamless")
	check(mds.world_file == CH3_WORLD_FILE, "world_file_is_bigmap")
	check(is_equal_approx(mds.fade_time, 0.22), "world_fade_authored")

	# --- Vertical transit: the authored lift really reaches the top gate, the
	# jump triggers it, the arrival launches up, and the floor gate does not
	# bounce the player straight back down.
	await mds.load_room("ch3_branch_b")
	check(await _wait_room(scene, "ch3_branch_b"), "lift_room_loads")
	await process_frame
	_check_region(scene, "ch3_branch_b")
	# Pass 78 wired the collapse husk's own painting; this real wave is the one
	# Chapter 3 encounter that spawns it.
	var branch_b_arena := mds.room_node.get_node_or_null("Arena") as ArenaRoom
	if branch_b_arena != null:
		_check_enemy_art(branch_b_arena, &"collapse_husk",
			"assets/sprites/enemies/collapse_husk.png", Color.WHITE)
	var lift := mds.room_node.get_node_or_null("Lift") as MovingPlatform
	check(lift != null, "branch_b_lift_present")
	if lift != null:
		# Chapter 3 authors no speed, so the pipeline default 80 px/s applies
		# (status #12 is scoped to Chapter 2 and is not changed here).
		check(is_equal_approx(lift.speed, 80.0), "branch_b_lift_pipeline_speed")
		check(not lift.travel_clamped, "branch_b_lift_travel_fits_room")
		check(mds.room_node.room_bounds.encloses(lift.platform_rect()),
			"branch_b_lift_inside_room")
		scene.player.global_position = lift.global_position \
			+ Vector2(80, -16 - Player.FOOT_Y)
		scene.player.velocity = Vector2.ZERO
		# The authored 80 px/s ride takes ~17 s; the test only needs the same
		# travel, so speed the platform up for the ride itself.
		# Called elevator: it waits at the bottom until the rider presses
		# interact. Speed the ride itself up so the test stays short.
		lift.call_speed = 1400.0
		lift.call_accel = 8000.0
		lift.restart(0.0)
		for _settle in 20:
			await physics_frame
		check(not lift.is_moving(), "branch_b_lift_waits_to_be_called")
		Input.action_press("interact")
		await process_frame
		await process_frame
		Input.action_release("interact")
		check(lift.target_stop == 1, "branch_b_lift_rider_calls_it_up")
		var lifted := false
		for _frame in 900:
			await physics_frame
			if lift.position.y <= 140.0:
				lifted = true
				break
		check(lifted, "branch_b_lift_reaches_top")
		check(scene.player.global_position.y < lift.global_position.y + 48.0,
			"branch_b_lift_carries_player")
		check(mds.room_node.room_bounds.encloses(lift.platform_rect()),
			"branch_b_lift_stays_inside")
		scene.player.global_position.x = 1280.0
		scene.player.velocity = Vector2.ZERO
		Input.action_press("jump")
		for _frame in 12:
			await physics_frame
		Input.action_release("jump")
		var triggered := false
		for _frame in 180:
			await physics_frame
			if mds.changing_room or mds.current_room != "ch3_branch_b":
				triggered = true
				break
		check(triggered, "branch_b_top_gate_triggers_on_jump")
		check(await _wait_room(scene, "ch3_entry"), "branch_b_top_gate_arrives_entry")
		await process_frame
		var entry_bot := MDSGate.find_gate(mds.room_node, "bot1")
		check(entry_bot != null, "entry_bot_gate_present")
		if entry_bot != null:
			var bot_spawn: Vector2 = entry_bot.get_spawn_position()
			var bot_pos: Vector2 = arrival.get("pos", Vector2.ZERO)
			check(absf(bot_pos.x - bot_spawn.x) < 1.0, "bot_arrival_x")
			check(bot_pos.y <= bot_spawn.y + 0.5 and bot_pos.y >= bot_spawn.y - 24.0,
				"bot_arrival_liftoff")
			check(Vector2(arrival.get("vel", Vector2.ZERO)).y <= -600.0,
				"bot_arrival_exit_speed")
		# The bot gate sits in the floor; the player falls back onto it. It must
		# ignore that return, or the lift ride would bounce them to branch B.
		await create_timer(2.0).timeout
		check(mds.current_room == "ch3_entry", "bot_arrival_does_not_bounce_back")
		check(not mds.changing_room, "bot_arrival_settles")
		check(not paused, "bot_arrival_not_paused")
		await process_frame
		_check_region(scene, "ch3_entry")

	# --- The whole connected graph, one gate at a time. Every arrival gets the
	# exact spawn point, exit-velocity rule, camera bounds and a modal-free HUD.
	# The shortcut's condition is checked closed here and opened only through a
	# test-injected ability; no gameplay source grants `ch3_shortcut` (status #16).
	await mds.load_room("ch3_entry")
	check(await _wait_room(scene, "ch3_entry"), "walk_starts_at_entry")
	var shortcut_checked := false
	var shortcut_granted := false
	var event_objective_checked := false
	for step in WALK:
		var step_gate := String(step[0])
		if step_gate == "shortcut" and not shortcut_granted:
			check(mds.current_room == "ch3_hub", "shortcut_step_from_hub")
			check(mds.has_ability("ch3_shortcut"),
				"shortcut_granted_on_hub_arrival")
			var closed_barrier := mds.room_node.get_node_or_null(
				"Barrier_shortcut") as MDSGateBarrier
			check(closed_barrier != null and closed_barrier.is_open,
				"shortcut_barrier_open_after_hub_arrival")
			mds.grant_ability("ch3_shortcut")
			await process_frame
			check(mds.has_ability("ch3_shortcut"), "shortcut_test_ability_injected")
			if closed_barrier != null:
				check(closed_barrier.is_open, "shortcut_barrier_opens_with_ability")
				check(mds.get_save_data().get("stored", []).has(
					mds.object_id(closed_barrier)), "shortcut_opening_is_stored")
			shortcut_granted = true
		var ok := await _use_gate(scene, step_gate, String(step[1]), String(step[2]))
		if not ok:
			break
		if mds.current_room == "ch3_hub" and not shortcut_checked \
				and not shortcut_granted:
			var barrier := mds.room_node.get_node_or_null(
				"Barrier_shortcut") as MDSGateBarrier
			check(barrier != null, "hub_shortcut_barrier")
			if barrier != null:
				# 0.13: reaching the hub opens the shortcut (no longer status #16).
				check(barrier.is_open and mds.has_ability("ch3_shortcut"), "hub_shortcut_opens_on_arrival")
				var requirements := barrier.get_requirements()
				check(requirements.size() == 1
					and String(requirements[0]) == "ch3_shortcut",
					"hub_shortcut_requires_ability")
			var shortcut_gate := MDSGate.find_gate(mds.room_node, "shortcut")
			check(shortcut_gate != null, "hub_shortcut_gate")
			if shortcut_gate != null:
				check(shortcut_gate.mode == MDSGate.Mode.INTERACT,
					"hub_shortcut_is_a_door")
				check(String(shortcut_gate.get_transition().get("room", ""))
					== "ch3_entry", "hub_shortcut_targets_entry")
			shortcut_checked = true
		if mds.current_room == "ch3_event" and not event_objective_checked:
			check(_objective_text(scene) == "事件已经读过",
				"event_region_shows_settled_objective")
			event_objective_checked = true
		if step_gate == "shortcut":
			# The arrival gate only receives players: using it must be inert.
			walked["ch3_entry/shortcut_arrival"] = true
			var shortcut_arrival := MDSGate.find_gate(
				mds.room_node, "shortcut_arrival")
			check(shortcut_arrival != null, "entry_shortcut_arrival_present")
			if shortcut_arrival != null:
				check(shortcut_arrival.get_transition().is_empty(),
					"entry_shortcut_arrival_dead_end")
				shortcut_arrival.use()
				await create_timer(0.3).timeout
				check(mds.current_room == "ch3_entry",
					"entry_shortcut_arrival_inert")
				check(not mds.changing_room,
					"entry_shortcut_arrival_no_transition")
	check(mds.current_room == "ch3_boss", "walk_reaches_boss")
	var boss_gate := MDSGate.find_gate(mds.room_node, "left1")
	check(boss_gate != null, "boss_left_gate_present")
	if boss_gate != null:
		walked["ch3_boss/left1"] = true
		check(boss_gate.get_transition().is_empty(), "boss_door_is_one_way")
		boss_gate.use()
		await create_timer(0.4).timeout
		check(mds.current_room == "ch3_boss", "boss_dead_end_holds")
		check(not mds.changing_room, "boss_dead_end_not_changing")
	# Every gate object in the world really carried the player (or was really
	# arrived at), and the sweep did not skip one.
	var missing_gates: Array[String] = []
	for key in connected_gates:
		if not walked.has(String(key)):
			missing_gates.append(String(key))
	for key in arrival_gates:
		if not walked.has(String(key)):
			missing_gates.append(String(key))
	check(missing_gates.is_empty(), "walk_covers_all_gates")
	check(walked.size() >= 22, "walk_gate_count")

	# --- Lower layer: falling into the well's lower half is normal traversal,
	# not a fall death. The one-way platforms also drop through on down+jump.
	scene.player._invulnerable_left = 0
	await mds.load_room("ch3_well")
	check(await _wait_room(scene, "ch3_well"), "well_loads")
	await process_frame
	_check_region(scene, "ch3_well")
	check(is_equal_approx(scene._fall_limit_local, 2400.0), "well_fall_plane")
	var well_origin: Vector2 = mds.world.get_origin("ch3_well")
	var well_lift := mds.room_node.get_node_or_null("Lift") as MovingPlatform
	check(well_lift != null, "well_lift_present")
	if well_lift != null:
		check(not well_lift.travel_clamped, "well_lift_travel_fits_room")
		check(well_lift.platform_rect().end.y <= mds.room_node.room_bounds.end.y,
			"well_lift_inside_room")
	scene.player._invulnerable_left = 0
	var lower_health: int = scene.player.health
	scene.player.global_position = well_origin + Vector2(1200, 2100)
	scene.player.velocity = Vector2.ZERO
	await physics_frame
	await physics_frame
	check(scene.player.global_position.y > well_origin.y + 1900.0,
		"well_lower_layer_reachable")
	check(scene.player.health == lower_health, "well_lower_layer_no_fall_damage")
	var one_way_platform := mds.room_node.get_node_or_null("OneWay1") as OneWayPlatform
	check(one_way_platform != null, "well_one_way_platform")
	if one_way_platform != null:
		var surface := one_way_platform.global_position.y
		scene.player.global_position = Vector2(one_way_platform.global_position.x + 160.0,
			surface - Player.FOOT_Y)
		scene.player.velocity = Vector2.ZERO
		await physics_frame
		await physics_frame
		check(scene.player.is_on_floor(), "well_one_way_landing")
		Input.action_press("move_down")
		Input.action_press("jump")
		await physics_frame
		Input.action_release("jump")
		await physics_frame
		Input.action_release("move_down")
		var dropped := false
		for _frame in 30:
			await physics_frame
			if scene.player.global_position.y > surface + 8.0:
				dropped = true
				break
		check(dropped, "well_one_way_drops_through")

	# --- Bench checkpoint: use it, fall far below the plan plane, and return to
	# the bench with a single fall hit (not the room entry).
	scene.player._invulnerable_left = 0
	await mds.load_room("ch3_hub")
	check(await _wait_room(scene, "ch3_hub"), "bench_room_loads")
	await process_frame
	_check_region(scene, "ch3_hub")
	var bench := mds.room_node.get_node_or_null("Bench") as BenchCheckpoint
	check(bench != null, "hub_bench_present")
	if bench != null:
		scene.player.global_position = bench.global_position + Vector2(0, -16)
		scene.player.velocity = Vector2.ZERO
		await physics_frame
		check(scene._try_use_bench(), "bench_use_succeeds")
		var expected_checkpoint: Vector2 = bench.respawn_position()
		check(scene._last_checkpoint.distance_to(expected_checkpoint) < 1.0,
			"bench_sets_checkpoint")
		check(scene.hud.get_message_text() == BenchCheckpoint.MESSAGE, "bench_message")
		scene.player._invulnerable_left = 0
		var bench_health: int = scene.player.health
		scene.player.global_position = bench.global_position + Vector2(0, 1700)
		await process_frame
		await process_frame
		check(scene.player.global_position.distance_to(expected_checkpoint) < 1.0,
			"bench_fall_returns_to_bench")
		var expected_damage := maxi(1,
			int(ceilf(15.0 * scene.player.damage_taken_multiplier)))
		check(scene.player.health == bench_health - expected_damage,
			"bench_fall_damage_once")
		check(not scene._story.is_open() and not paused, "bench_fall_no_modal")
	# The shortcut opened during the walk is still open after a real reload.
	var reloaded_barrier := mds.room_node.get_node_or_null(
		"Barrier_shortcut") as MDSGateBarrier
	check(reloaded_barrier != null and reloaded_barrier.is_open,
		"hub_shortcut_stays_open_on_reload")
	var reloaded_shortcut := MDSGate.find_gate(mds.room_node, "shortcut")
	check(reloaded_shortcut != null, "hub_shortcut_gate_on_reload")
	if reloaded_shortcut != null:
		check(String(reloaded_shortcut.get_transition().get("room", "")) == "ch3_entry",
			"hub_shortcut_target_entry_on_reload")
		# `get_transition()` is the runtime target only; the one-way annotation
		# lives on the world gate. The reverse gate must not exist (that is what
		# makes the return trip impossible).
		check(bool(mds.world.get_gate("ch3_hub", "shortcut").get("one_way", false)),
			"hub_shortcut_transition_is_one_way")
		check(mds.world.get_transition("ch3_entry", "shortcut_arrival").is_empty(),
			"hub_shortcut_has_no_return_transition")

	# --- Two encounters in one region: each locks and clears on its own node
	# id, its real door bodies block/release, and a reload keeps both cleared.
	scene._cleared_encounters.clear()
	scene._legacy_cleared_rooms.clear()
	scene._cleared_in_chapter = 0
	await mds.load_room("ch3_branch_a")
	check(await _wait_room(scene, "ch3_branch_a"), "combat_room_loads")
	await process_frame
	_check_region(scene, "ch3_branch_a")
	var arena_a := mds.room_node.get_node_or_null("Arena") as ArenaRoom
	var arena_b := mds.room_node.get_node_or_null("Arena2") as ArenaRoom
	check(arena_a != null and arena_b != null, "branch_a_two_arenas")
	check(scene._rooms.size() == 2, "branch_a_two_registered_arenas")
	var ground := _ground_surface_y(mds.room_node)
	if arena_a != null:
		check(arena_a.enemy_count() == 2, "arena_a_first_wave")
		check(_enemy_ids(arena_a) == _wave_ids(
			plan.wave_for("ch3_branch_a", "ch3_branch_a/Arena")),
			"arena_a_uses_plan_wave")
		for enemy in arena_a.get_node(ArenaRoom.ENEMIES_NODE).get_children():
			if enemy is Node2D:
				check((enemy as Node2D).global_position.y < ground,
					"arena_a_enemy_above_ground")
		# Since pass 78 every Chapter 3 enemy is wired. This arena's wave is two
		# wired enemies: both must use their own PNG at white (the same rule the
		# Chapter 2 audit locked).
		_check_enemy_art(arena_a, &"mirror_sniper",
			"assets/sprites/enemies/mirror_sniper.png", Color.WHITE)
		_check_enemy_art(arena_a, &"hanging_scribe",
			"assets/sprites/enemies/hanging_scribe.png", Color.WHITE)
	if arena_b != null:
		check(arena_b.enemy_count() == 2, "arena_b_first_wave")
		check(_enemy_ids(arena_b) == _wave_ids(
			plan.wave_for("ch3_branch_a", "ch3_branch_a/Arena2")),
			"arena_b_uses_own_plan_wave")
		# Pass 78 gave the Chapter 2 borrows their own paintings, so the Chapter 3
		# reuse now renders at white like every other wired enemy.
		_check_enemy_art(arena_b, &"rust_whisperer",
			"assets/sprites/enemies/rust_whisperer.png", Color.WHITE)
		_check_enemy_art(arena_b, &"lung_moth",
			"assets/sprites/enemies/lung_moth.png", Color.WHITE)
	if arena_a != null and arena_b != null:
		scene.player._invulnerable_left = 100
		scene.player.global_position = arena_a.global_position + Vector2(0, -120)
		await process_frame
		await process_frame
		check(arena_a.is_locked(), "arena_a_locks")
		check(not arena_b.is_locked(), "arena_b_stays_open")
		check(_arena_doors_locked(arena_a), "arena_a_doors_block")
		check(_objective_text(scene).contains("肃清此房间"), "arena_a_objective")
		check(await _kill_arena(arena_a), "arena_a_clears")
		check(_arena_doors_open(arena_a), "arena_a_doors_release")
		check(await _wait_reward(scene), "arena_a_reward_opens")
		check(scene._cleared_encounters.has("ch3_branch_a/Arena"),
			"arena_a_settles_own_id")
		check(not scene._cleared_encounters.has("ch3_branch_a/Arena2"),
			"arena_b_not_settled")
		check(scene._cleared_in_chapter == 1, "arena_a_counts_once")
		scene._reward_ui._choose(0)
		await process_frame
		check(not scene._reward_ui.visible and not paused, "arena_a_reward_closes")
		scene.player.global_position = arena_b.global_position + Vector2(0, -120)
		await process_frame
		await process_frame
		check(arena_b.is_locked(), "arena_b_locks")
		check(not arena_a.is_locked(), "arena_a_stays_open")
		check(_arena_doors_locked(arena_b), "arena_b_doors_block")
		check(await _kill_arena(arena_b), "arena_b_clears")
		check(_arena_doors_open(arena_b), "arena_b_doors_release")
		check(await _wait_reward(scene), "arena_b_reward_opens")
		check(scene._cleared_encounters.has("ch3_branch_a/Arena2"),
			"arena_b_settles_own_id")
		check(scene._cleared_in_chapter == 2, "arena_b_counts_once")
		scene._reward_ui._choose(0)
		await process_frame
		var settled: int = scene._cleared_in_chapter
		arena_b.cleared.emit()
		await process_frame
		check(scene._cleared_in_chapter == settled, "cleared_arena_reemit_ignored")
	await mds.load_room("ch3_branch_a")
	check(await _wait_room(scene, "ch3_branch_a"), "combat_room_reloads")
	await process_frame
	var reload_a := mds.room_node.get_node_or_null("Arena") as ArenaRoom
	var reload_b := mds.room_node.get_node_or_null("Arena2") as ArenaRoom
	check(reload_a != null and reload_a.enemy_count() == 0,
		"cleared_arena_a_not_respawned")
	check(reload_b != null and reload_b.enemy_count() == 0,
		"cleared_arena_b_not_respawned")
	check(scene._rooms.is_empty(), "cleared_arenas_not_registered")
	check(not scene._reward_ui.visible, "cleared_arena_no_false_reward")

	# --- Clear target: the remaining five nodes bring the chapter to the plan's
	# seven, and the HUD denominator keeps the boss slot at eight.
	for encounter_id in plan.encounter_ids():
		var id := String(encounter_id)
		if scene._cleared_encounters.has(id):
			continue
		check(scene._mark_encounter_cleared(id.get_slice("/", 0), id),
			"mark_encounter_%s" % id)
	check(scene._cleared_in_chapter == 7, "chapter_3_seven_clears")
	check(scene._cleared_in_chapter == plan.clear_target(),
		"chapter_3_clears_match_plan")
	check(scene._chapter_progress_total() == 8, "chapter_3_progress_keeps_boss_slot")
	check(scene._cleared_encounters.size() == 7, "chapter_3_seven_encounter_ids")
	check(_progress_text(scene) == "档案  7 / 8", "chapter_3_hud_progress_seven")

	# --- The event region's real page: rewound once so the region trigger can
	# open it, then it pays once and stays quiet on a reload.
	scene._cleared_encounters.erase("ch3_event/event")
	scene._cleared_in_chapter -= 1
	scene._event_room_id = ""
	await mds.load_room("ch3_event")
	check(await _wait_room(scene, "ch3_event"), "event_region_loads")
	_check_region(scene, "ch3_event")
	var page_open := await _wait_story(scene)
	check(page_open, "event_page_opens")
	if page_open:
		var expected_event := Ch3EventData.pick(
			scene.run_state.run_seed, "ch3_event/event")
		check(not expected_event.is_empty(), "event_variant_resolves")
		check(scene._story._eyebrow.text == String(expected_event.get("eyebrow", "")),
			"event_uses_chapter_3_copy")
		check(scene._story._title.text == String(expected_event.get("title", "")),
			"event_title_matches_seed")
		check(scene._story._options.get_child_count() == 2,
			"event_has_two_choices")
		if scene._story._options.get_child_count() == 2:
			check((scene._story._options.get_child(0) as Button).text.begins_with(
				String(expected_event.get("read_label", ""))), "event_read_label")
			check((scene._story._options.get_child(1) as Button).text.begins_with(
				String(expected_event.get("take_label", ""))), "event_take_label")
		var pages_before: int = scene.run_state.pages
		var clears_before: int = scene._cleared_in_chapter
		scene._story.choose(1)
		await create_timer(0.2).timeout
		check(scene.run_state.pages == pages_before + Ch3EventData.PAGES_REWARD,
			"event_taking_pays_pages")
		check(scene.hud.get_message_text()
			== String(expected_event.get("take_message", "")) % Ch3EventData.PAGES_REWARD,
			"event_take_message")
		check(scene._cleared_encounters.has("ch3_event/event"),
			"event_encounter_settles")
		check(scene._cleared_in_chapter == clears_before + 1,
			"event_counts_once")
		check(scene._cleared_in_chapter == 7, "event_restores_seven_clears")
	await mds.load_room("ch3_event")
	check(await _wait_room(scene, "ch3_event"), "event_region_reloads")
	await create_timer(1.2).timeout
	check(not scene._story.is_open(), "event_no_retrigger_after_settle")
	check(not paused, "event_no_retrigger_pause")
	check(scene._cleared_in_chapter == 7, "event_no_double_count")
	check(not scene._reward_ui.visible, "event_no_duplicate_reward")

	# --- Save inside the hidden vault with the seven clears, the shortcut and
	# the settled content; the MDS dictionary is restored into a fresh world the
	# same way a resume does. (The campaign itself cannot resume into the chapter
	# 3 big map yet: its plan slot is empty by design.)
	flow.auto_save = true
	await mds.load_room("ch3_vault")
	check(await _wait_room(scene, "ch3_vault"), "save_room_loads")
	await process_frame
	var vault_origin: Vector2 = mds.world.get_origin("ch3_vault")
	scene.player.global_position = vault_origin + Vector2(1200, 1408)
	scene.player.velocity = Vector2.ZERO
	await physics_frame
	var saved_position: Vector2 = scene.player.global_position
	check(scene.save_run_now(), "chapter_3_run_save_writes")
	var saved := RunSave.read(RUN_PATH)
	var saved_run: Dictionary = saved.get("run", {})
	var saved_progress: Dictionary = saved.get("progress", {})
	var saved_world: Dictionary = saved.get("world", {})
	var saved_mds: Dictionary = saved.get("mds", {})
	check(int(saved_run.get("chapter", -1)) == 2, "chapter_3_save_chapter")
	check(String(saved_run.get("room", "")) == "ch3_vault", "chapter_3_save_room")
	check(int(saved_progress.get("cleared_in_chapter", 0)) == 7,
		"chapter_3_save_clear_count")
	check((saved_progress.get("cleared_encounters", []) as Array).size() == 7,
		"chapter_3_save_encounter_ids")
	check((saved_progress.get("vaults", []) as Array).has("ch3_vault"),
		"chapter_3_save_vault_discovery")
	check((saved_world.get("claimed_stele_ids", []) as Array).has("ch3_vault/Stele1"),
		"chapter_3_save_vault_stele")
	check((saved_world.get("claimed_stele_ids", []) as Array).has("ch3_hub/Stele1"),
		"chapter_3_save_hub_stele")
	check((saved_world.get("opened_chest_ids", []) as Array).has("ch3_vault/Chest1"),
		"chapter_3_save_vault_chest")
	check((saved_world.get("opened_chest_ids", []) as Array).has("ch3_branch_a/Chest1"),
		"chapter_3_save_branch_chest")
	check((saved_world.get("opened_chest_ids", []) as Array).has("ch3_well/Chest1"),
		"chapter_3_save_well_chest")
	check((saved_world.get("opened_chest_ids", []) as Array).size() == 3,
		"chapter_3_save_three_chests")
	check((saved_mds.get("abilities", []) as Array).has("ch3_shortcut"),
		"chapter_3_save_shortcut_ability")
	check((saved_mds.get("stored", []) as Array).has("ch3_hub/Barrier_shortcut"),
		"chapter_3_save_shortcut_barrier")
	check(String(saved_mds.get("room", "")) == "ch3_vault", "chapter_3_save_mds_room")
	check((saved_mds.get("visited", []) as Array).has("ch3_boss"),
		"chapter_3_save_mds_visits")
	flow.auto_save = false

	# Restore the saved MDS dictionary into a fresh chapter-3 world. The room,
	# coordinates, visited map, ability and opened barrier all come back.
	scene.hud.show_message("__resume_sentinel__")
	check(await _mount_chapter_3(scene, "ch3_entry", saved_mds, false),
		"chapter_3_world_resume_mounts")
	mds = scene._mds_world
	check(await _wait_room(scene, "ch3_vault"), "chapter_3_world_resume_room")
	check(not scene._story.is_open() and not paused, "chapter_3_world_resume_no_modal")
	check(scene.player.global_position.distance_to(saved_position) < 8.0,
		"chapter_3_world_resume_position")
	check(scene.hud.get_message_text() == "__resume_sentinel__",
		"chapter_3_world_resume_no_repeat_discovery")
	check(scene._cleared_in_chapter == 7, "chapter_3_world_resume_clear_count")
	check(scene._cleared_encounters.size() == 7, "chapter_3_world_resume_encounter_ids")
	check(mds.has_ability("ch3_shortcut"), "chapter_3_world_resume_shortcut_ability")
	check(map_view.is_room_revealed("ch3_vault"), "chapter_3_world_resume_map")
	var resume_chest := mds.room_node.get_node_or_null("Chest1") as TreasureChest
	check(resume_chest != null and resume_chest.is_open,
		"chapter_3_world_resume_chest_open")
	check(scene._steles.is_empty(), "chapter_3_world_resume_stele_removed")
	await mds.load_room("ch3_hub")
	check(await _wait_room(scene, "ch3_hub"), "chapter_3_world_resume_hub")
	await process_frame
	var resume_barrier := mds.room_node.get_node_or_null(
		"Barrier_shortcut") as MDSGateBarrier
	check(resume_barrier != null and resume_barrier.is_open,
		"chapter_3_world_resume_barrier_open")
	check(scene._claimed_steles.has("ch3_hub/Stele1"),
		"chapter_3_world_resume_hub_stele")
	check(scene._steles.is_empty(), "chapter_3_world_resume_hub_stele_removed")

	# --- Boss region: the Last Reader spawns above the floor in its own region,
	# the chapter-3 entrance/phase copy and authority pool are used, and the
	# real defeat chain stops at the chapter-3 boundary instead of loading the
	# unauthored chapter 4. Deep mechanics live in test_ch3_boss; this section
	# only covers the acceptance wiring.
	await mds.load_room("ch3_boss")
	check(await _wait_room(scene, "ch3_boss"), "boss_room_loads")
	await process_frame
	_check_region(scene, "ch3_boss")
	check(is_instance_valid(scene._boss), "boss_spawns_in_region")
	var boss := scene._boss as LastReader
	check(boss != null, "boss_uses_last_reader")
	check(scene._boss is InkArchivist, "boss_reuses_generic_flow")
	check(not (scene._boss is LungBellGuardian), "boss_is_not_chapter_2")
	check(not (scene._boss is InkArchivistCh1), "boss_is_not_chapter_1")
	check(plan.boss_scene != null
		and plan.boss_scene.resource_path.ends_with("last_reader.tscn"),
		"boss_scene_routed_from_plan")
	check(scene._mds_boss_arena != null, "boss_arena_registered")
	var boss_bounds: Rect2 = mds.world.get_room_bounds("ch3_boss")
	var boss_entrance_gate := MDSGate.find_gate(mds.room_node, "left1")
	if scene._mds_boss_arena != null:
		var boss_arena: ArenaRoom = scene._mds_boss_arena
		check(boss_arena.global_position.x - 620.0 >= boss_bounds.position.x,
			"boss_left_door_inside_room")
		check(boss_arena.global_position.x + 620.0 <= boss_bounds.end.x,
			"boss_right_door_inside_room")
		check(_arena_doors_open(boss_arena), "boss_arena_starts_open")
		if boss_entrance_gate != null:
			check(boss_entrance_gate.global_position.x
				< boss_arena.global_position.x - 620.0,
				"boss_entrance_outside_arena_lock")
		if boss != null:
			check(boss.global_position.y < _ground_surface_y(mds.room_node),
				"boss_spawns_above_ground")
			check(boss.data.contact_damage == int(CampaignData.chapter(2)["boss_damage"]),
				"boss_damage_from_campaign")
			check(is_equal_approx(boss.data.speed,
				float(CampaignData.chapter(2)["boss_speed"])), "boss_speed_from_campaign")
			# The authored portrait from the campaign table is the Last Reader's.
			check(boss.sprite_visual != null, "boss_has_sprite")
			if boss.sprite_visual != null:
				check(boss.sprite_visual.texture.resource_path.ends_with(
					"assets/sprites/bosses/last_reader.png"), "boss_uses_last_reader_art")
				check(boss.sprite_visual.modulate == Color.WHITE,
					"boss_no_fallback_tint")
		scene.player._invulnerable_left = 100
		scene.player.global_position = boss_arena.global_position
		await process_frame
		await process_frame
		check(boss_arena.is_locked(), "boss_arena_locks")
		check(_arena_doors_locked(boss_arena), "boss_doors_block")
		var entrance_line := BossEntranceData.pick(scene.run_state.run_seed, 2)
		check(BossEntranceData.variants(2).has(entrance_line),
			"boss_entrance_uses_chapter_3_copy")
		check(scene.hud.get_message_text() == entrance_line,
			"boss_entrance_matches_seed")
		var chapter := CampaignData.chapter(2)
		var phase_line := BossPhaseData.pick(scene.run_state.run_seed, 2, 2)
		check(phase_line != "", "boss_phase_line_authored")
		scene._on_boss_phase(chapter, 2)
		check(scene.hud.get_message_text()
			== "%s · 第 2 阶段：%s" % [chapter["boss_name"], phase_line],
			"boss_phase_uses_chapter_3_copy")
	# Defeat through the real flow: authority pick from the plan's pool, the
	# chapter-3 outro and choice, then (pass 91) the Chapter 4 intro.
	if boss != null:
		boss.take_damage(100000)
		check(await _wait_authority_choice(scene), "boss_authority_choice_opens")
		var expected_pool := AuthorityController.build_pool(
			plan.authority_pool, scene.run_state, flow.profile, scene._records)
		var pool_ids: Array[StringName] = []
		for authority in expected_pool:
			pool_ids.append(authority.id)
		check(pool_ids.has(&"revive"), "boss_authority_offers_revive")
		check(pool_ids.has(&"rewrite"), "boss_authority_offers_rewrite")
		check(scene._authority_choice.get_button_count() == expected_pool.size(),
			"boss_authority_matches_pool")
		scene._authority_choice._choose(0)
		await create_timer(0.4).timeout
		check(scene.run_state.authority != null, "boss_authority_applied")
		check(await _wait_story(scene), "boss_outro_opens")
		scene._story.close()
		await process_frame
		check(scene._story.is_open(), "boss_choice_opens")
		check(scene._cleared_in_chapter == 7, "chapter_3_clears_unchanged_at_end")
		scene._story.choose(0)
		await create_timer(1.6).timeout
		# Pass 91: the chapter-3 choice hands off into the Chapter 4 intro in
		# place. The authored effects are unchanged and no ending is recorded at
		# this boundary; the new chapter resets its own clear counter.
		check(scene._chapter == 3, "chapter_3_hands_off_to_chapter_4")
		check(not scene._finished, "chapter_3_does_not_finish_campaign")
		check(not scene.ending_screen.visible, "chapter_3_no_end_screen")
		check(scene._story.is_open() and not scene._story._choice_mode,
			"chapter_3_opens_chapter_4_intro")
		check(scene._story._eyebrow.text.contains("第 4 章"),
			"chapter_3_handoff_eyebrow")
		check(scene._chapter_plan != null and scene._chapter_plan.big_map
			and String(scene._chapter_plan.resource_path).ends_with("chapter_4_demo.tres"),
			"chapter_3_handoff_loads_chapter_4_plan")

		# A defeated boss stays down on reload; the resume guard is
		# chapter-agnostic. The handoff moved the campaign on to Chapter 4, so
		# re-mount a chapter-3 world by hand in the post-boss resume state (boss
		# recorded dead, aftermath already spent) and re-enter the boss region.
		scene._story.close()
		await process_frame
		paused = false
		check(await _mount_chapter_3(scene, "ch3_entry", {}, false),
			"boss_reload_world_mounts")
		scene._finished = true
		scene._boss_defeated = true
		scene._boss_aftermath_started = true
		if is_instance_valid(scene._boss):
			scene._boss.queue_free()
		scene._boss = null
		await scene._mds_world.load_room("ch3_boss")
		check(await _wait_room(scene, "ch3_boss"), "boss_room_reloads")
		await create_timer(0.3).timeout
		check(scene._boss == null, "boss_no_second_spawn")
		var reloaded := scene._mds_world.room_node as MDSBigRoom
		if reloaded != null:
			var reloaded_arena := reloaded.get_node_or_null("Arena") as ArenaRoom
			var bosses := 0
			if reloaded_arena != null:
				for child in reloaded_arena.get_node(
						ArenaRoom.ENEMIES_NODE).get_children():
					if child is LastReader:
						bosses += 1
			check(bosses == 0, "boss_room_holds_no_boss")
		scene._finished = false
		scene._boss_defeated = false

	# --- Gate visuals covered every region the graph has, and every gate in
	# them (20 connected + 2 arrival) carries the pipeline's doorway visual.
	check(gate_visual_regions.size() == 9, "gate_visuals_all_regions")
	var visual_total := 0
	for value in gate_visual_regions.values():
		visual_total += int(value)
	check(visual_total == 22, "gate_visuals_all_gates")
	var directed_total := 0
	var arrival_total := 0
	var side_total: Dictionary = {}
	for room_id in gate_visual_kinds:
		var kinds: Array = gate_visual_kinds[room_id]
		directed_total += int(kinds[0])
		arrival_total += int(kinds[1])
		var sides: Dictionary = gate_visual_sides[room_id]
		for side in sides:
			side_total[side] = int(side_total.get(side, 0)) + int(sides[side])
	check(directed_total == 20, "gate_visuals_connected_gates")
	check(arrival_total == 2, "gate_visuals_arrival_gates")
	check(int(side_total.get("left", 0)) == 5, "gate_visuals_left_gates")
	check(int(side_total.get("right", 0)) == 5, "gate_visuals_right_gates")
	check(int(side_total.get("top", 0)) == 5, "gate_visuals_top_gates")
	check(int(side_total.get("bot", 0)) == 5, "gate_visuals_bot_gates")
	# The two mid-room gates are the hub shortcut (connected, one-way) and its
	# arrival on the entry step; both are door-side and stay centred.
	check(int(side_total.get("door", 0)) == 2, "gate_visuals_door_gates")

	_finish(scene)


func _finish(scene) -> void:
	paused = false
	var flow := root.get_node_or_null("Flow") as GameFlow
	if flow != null:
		flow.auto_save = false
	if scene != null and is_instance_valid(scene):
		if current_scene == scene:
			current_scene = null
		scene.queue_free()
	await process_frame
	_cleanup_files()
	var audio := root.get_node_or_null("Audio")
	if audio != null:
		if audio._music != null:
			audio._music.stop()
			audio._music.stream = null
		if audio._voice != null:
			audio._voice.stop()
			audio._voice.stream = null
	print("INTEGRATION: %d checks, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
