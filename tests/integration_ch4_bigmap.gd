extends SceneTree

## Chapter 4 big-map acceptance: the real nine-region world and its door graph,
## camera/fall limits, vertical transit, hidden vault, one-shot content, the
## two-arena region, the event page, the shortcut barrier, a world-level save /
## resume, the Smiling Archivist boss and the campaign boundary.
##
## The campaign loads this big-map world for Chapter 4 (pass 91) and the chapter
## ends the campaign. This suite still attaches the chapter-4 plan and world to
## the live main scene so the whole graph can be walked from one mount; it never
## touches `CHAPTER_PLAN_PATHS` or chapter routing, and it never grants
## `ch4_shortcut` from a gameplay source.

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
## Every region that passed the structural/backdrop/weather/ambient checks, so
## the chapter-4 motif record covers all nine regions, not just the ones the
## walk happened to revisit.
var checked_regions: Dictionary = {}

const RUN_PATH := "user://test_ch4_bigmap_run.cfg"
const PROFILE_PATH := "user://test_ch4_bigmap_profile.cfg"
const CH4_WORLD_FILE := "res://scenes/mds/chapter_4_bigmap.mdsworld.json"

## Every connected gate in the nine-region graph, in one walkable order:
## [gate in the current room, region it leads to, gate it arrives at].
## Revisited gates are fine; the run ends at the boss dead end.
const WALK: Array = [
	["right1", "ch4_branch_a", "left1"],
	["left1", "ch4_entry", "right1"],
	["bot1", "ch4_branch_b", "top1"],
	["bot1", "ch4_vault", "top1"],
	["top1", "ch4_branch_b", "bot1"],
	["top1", "ch4_entry", "bot1"],
	["right1", "ch4_branch_a", "left1"],
	["bot1", "ch4_hub", "top1"],
	["left1", "ch4_branch_b", "right1"],
	["right1", "ch4_hub", "left1"],
	["top1", "ch4_branch_a", "bot1"],
	["bot1", "ch4_hub", "top1"],
	["right1", "ch4_event", "left1"],
	["left1", "ch4_hub", "right1"],
	["shortcut", "ch4_entry", "shortcut_arrival"],
	["right1", "ch4_branch_a", "left1"],
	["bot1", "ch4_hub", "top1"],
	["bot1", "ch4_well", "top1"],
	["top1", "ch4_hub", "bot1"],
	["right1", "ch4_event", "left1"],
	["bot1", "ch4_elite", "top1"],
	["top1", "ch4_event", "bot1"],
	["left1", "ch4_hub", "right1"],
	["left1", "ch4_branch_b", "right1"],
	["right1", "ch4_hub", "left1"],
	["bot1", "ch4_well", "top1"],
	["right1", "ch4_elite", "left1"],
	["left1", "ch4_well", "right1"],
	["right1", "ch4_elite", "left1"],
	["right1", "ch4_boss", "left1"],
]


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("CH4 BIGMAP FAIL: " + label)


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


## Attaches the chapter-4 plan and the real big-map world to the live scene,
## exactly the way the game builds a chapter world. `save_data` restores a
## world-level checkpoint (the same dictionary `_build_run_save` stores under
## `mds`).
func _mount_chapter_4(scene, start_room := "ch4_entry",
		save_data: Dictionary = {}, reset_progress := true) -> bool:
	var plan := load("res://resources/chapters/chapter_4_demo.tres") as ChapterPlanData
	if plan == null or not plan.big_map:
		return false
	scene._teardown_mds(false)
	scene._chapter = 3
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
	scene._map_overlay.set_chapter(3)
	scene._map_overlay.set_world(CH4_WORLD_FILE)
	var chapter := CampaignData.chapter(3)
	var flow := root.get_node_or_null("Flow") as GameFlow
	var difficulty: int = flow.difficulty if flow != null else 0
	scene.hud.set_region("%s · %s" % [chapter["region"],
		Difficulty.display_name(difficulty)])
	scene.hud.set_progress(scene._cleared_in_chapter, scene._chapter_progress_total())
	scene.hud.set_objective(String(chapter["objective"]))
	scene.hud.hide_boss()
	var camera := scene.player.get_node_or_null("Camera2D") as Camera2D
	var world := (load("res://scenes/mds/chapter_4_bigmap_world.tscn")
		as PackedScene).instantiate() as MDSWorldGame
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.player = scene.player
	world.camera = camera
	world.world_file = CH4_WORLD_FILE
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


## One room's structural/camera/fall/backdrop/weather/ambient check, run after
## every real arrival.
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
	# Chapter 4's nine regions are authored as single rectangles, so MDS's
	# camera has no partition to switch between; record that state explicitly.
	check(mds.world.get_local_rects(room_id).size() == 1,
		"region_single_rect_%s" % room_id)
	check(String(room.area_info.get("area", "")) == "Smiling Theater",
		"region_area_%s" % room_id)
	_check_backdrop(room, room_id)
	_check_weather(mds, room, room_id)
	_check_background(mds, room, room_id)
	_check_ambient(room, room_id)
	_check_gate_visuals(mds, room, room_id)
	checked_regions[room_id] = true


## The smiling theatre is a tiled painted backdrop (no pixel-art filter); the
## big-map pipeline adds no separate theatre layer, so the old linear world's
## TheaterBackdrop stays the only one in the project.
func _check_backdrop(room: MDSBigRoom, room_id: String) -> void:
	check(not room.backdrop_tiles.is_empty(), "region_backdrop_%s" % room_id)
	if room.backdrop_tiles.is_empty():
		return
	var texture: Texture2D = room.backdrop_tiles[0].texture
	check(texture != null, "region_backdrop_texture_%s" % room_id)
	if texture != null:
		check(texture.resource_path.ends_with("assets/backgrounds/smiling_theater.png"),
			"region_backdrop_smiling_theater_%s" % room_id)
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
	var theater_layers := 0
	var sea_layers := 0
	for node in room.find_children("*", "", true, false):
		if node is TheaterBackdrop:
			theater_layers += 1
		if node is LivingBackdrop:
			sea_layers += 1
	check(theater_layers == 0, "region_no_theater_layer_%s" % room_id)
	check(sea_layers == 0, "region_no_living_backdrop_%s" % room_id)


## The area's ash embers and light shafts really reach the room; the stage
## motif is recorded as authored (pass-50 section E stays an open question).
func _check_weather(mds, room: MDSBigRoom, room_id: String) -> void:
	var spec := String(room.area_info.get("weather", ""))
	check(spec.contains("embers"), "region_weather_embers_%s" % room_id)
	check(spec.contains("light_shafts"), "region_weather_light_shafts_%s" % room_id)
	check(mds.weather != null, "region_weather_node_%s" % room_id)
	if mds.weather != null:
		check(mds.weather.name == MDSEnvironment.NODE_NAME,
			"region_weather_named_%s" % room_id)
		check(mds.weather.get_node_or_null("Embers") != null,
			"region_weather_embers_effect_%s" % room_id)
		check(mds.weather.get_node_or_null("LightShafts") != null,
			"region_weather_light_shafts_effect_%s" % room_id)
	check(mds.room_darkness == false, "region_darkness_off_%s" % room_id)
	check(room.get_node_or_null("MDSDarkness") == null,
		"region_no_darkness_node_%s" % room_id)


## `blood_moon` is the area's boss-room animated background; every other region
## has none. (The stage-motif presentation decision stays open.)
func _check_background(mds, room: MDSBigRoom, room_id: String) -> void:
	var plan: ChapterPlanData = current_scene._chapter_plan
	var is_boss := plan != null \
		and String(plan.room(room_id).get("type", "")) == "boss"
	var background := String(room.area_info.get("background", ""))
	if is_boss:
		check(background == "blood_moon", "region_boss_background_%s" % room_id)
		check(mds.background != null, "region_boss_background_node_%s" % room_id)
		check(mds.get_background_value(room_id) == "blood_moon",
			"region_boss_background_spec_%s" % room_id)
	else:
		check(background == "", "region_plain_background_%s" % room_id)
		check(mds.background == null, "region_plain_background_node_%s" % room_id)


## Every region authors the ash-ember ambience (rising motes) on top of the
## painted backdrop; the node is the shared BigRoomAmbient, not a new layer.
func _check_ambient(room: MDSBigRoom, room_id: String) -> void:
	check(room.data != null and room.data.ambient_kind == &"embers",
		"region_ambient_kind_%s" % room_id)
	var ambient := room.get_node_or_null("Ambient") as BigRoomAmbient
	check(ambient != null, "region_ambient_node_%s" % room_id)
	if ambient != null:
		check(ambient.kind == &"embers", "region_ambient_embers_%s" % room_id)
		check(ambient.z_index == -8, "region_ambient_behind_actors_%s" % room_id)
		check(is_equal_approx(ambient.density, 0.5), "region_ambient_density_%s" % room_id)


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
			# The panel unrolls into the room: its wall-side edge stays on the
			# gate line, so no part of the doorway hangs outside the room.
			var wall_edge := door_rect.end.x if side == "right" else door_rect.position.x
			check(is_equal_approx(wall_edge, gate.position.x),
				"region_gate_visual_door_unrolls_inward_%s" % tag)
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
	# A hatch is 96 px wide after the quarter turn: like the side doors, it
	# must not overhang a room edge (the chapter-3 caption overflow fix kept
	# labels in, this keeps the doorway itself in on both axes).
	if side == "top" or side == "bot":
		var direction := 1.0 if side == "top" else -1.0
		var hatch_center := gate.position + Vector2(0.0, direction * GateVisual.HATCH_HALF)
		var hatch_rect := Rect2(
			hatch_center - Vector2(GateVisual.HEIGHT * 0.5, GateVisual.HATCH_HALF),
			Vector2(GateVisual.HEIGHT, GateVisual.HATCH_HALF * 2.0))
		check(bounds.encloses(hatch_rect),
			"region_gate_visual_hatch_inside_room_%s" % tag)


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


## Sorted art paths of the enemies actually standing in the arena. Chapter 4's
## `mask_enemy` / `seat_husk` are art variants that reuse the hanging-scribe /
## collapse-husk enemy scenes, so their runtime `data.id` stays the base
## scene's; the painting on the sprite is what identifies the spawn.
func _enemy_art_paths(arena: ArenaRoom) -> PackedStringArray:
	var paths := PackedStringArray()
	if arena == null:
		return paths
	for child in arena.get_node(ArenaRoom.ENEMIES_NODE).get_children():
		if child is Enemy and child.sprite_visual != null \
				and child.sprite_visual.texture != null:
			paths.append(child.sprite_visual.texture.resource_path)
	paths.sort()
	return paths


## The art the plan's wave asks for, in the same sorted path order.
func _expected_art_paths(wave: Array, art: Dictionary) -> PackedStringArray:
	var paths := PackedStringArray()
	for id in wave:
		var texture: Texture2D = art.get(id, null)
		if texture != null:
			paths.append(texture.resource_path)
	paths.sort()
	return paths


## One spawned enemy's shared-path art. Chapter 4's eight spawn ids all carry
## their own painting (the pass-50 audit), so every one of these must render
## its own PNG at white with no fallback tint. No art is added or changed here.
func _check_enemy_art(arena: ArenaRoom, sprite_suffix: String, tint: Color) -> void:
	var found: Enemy = null
	if arena != null:
		for child in arena.get_node(ArenaRoom.ENEMIES_NODE).get_children():
			if child is Enemy and child.sprite_visual != null \
					and child.sprite_visual.texture != null \
					and child.sprite_visual.texture.resource_path.ends_with(sprite_suffix):
				found = child
				break
	check(found != null, "ch4_enemy_present_%s" % sprite_suffix.get_file())
	if found == null:
		return
	check(found.sprite_visual.modulate == tint,
		"ch4_enemy_art_tint_%s" % sprite_suffix.get_file())


## Live audit of one planned wave: every spawned enemy paints one of the
## dedicated PNGs the wave names and renders at white (no fallback art in the
## chapter). `mask_enemy` / `seat_husk` are art variants on the base enemy
## scenes, so their painting is what identifies them here.
func _check_wave_enemy_art(arena: ArenaRoom, wave: Array, art: Dictionary,
		tag: String) -> void:
	var expected := _expected_art_paths(wave, art)
	var index := 0
	for child in arena.get_node(ArenaRoom.ENEMIES_NODE).get_children():
		if not (child is Enemy) or child.sprite_visual == null:
			continue
		var texture: Texture2D = child.sprite_visual.texture
		check(texture != null, "wave_enemy_texture_%s_%d" % [tag, index])
		if texture != null:
			check(expected.has(texture.resource_path),
				"wave_enemy_dedicated_art_%s_%d" % [tag, index])
		check(child.sprite_visual.modulate == Color.WHITE,
			"wave_enemy_white_tint_%s_%d" % [tag, index])
		index += 1


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
## measurement the Chapter 2/3 acceptance used).
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

	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.4).timeout
	_close_story(scene)
	check(await _wait_mds(scene), "boots_chapter_1")
	check(await _mount_chapter_4(scene), "chapter_4_bigmap_mounts")
	var mds = scene._mds_world
	mds.room_loaded.connect(_on_room_loaded_capture)
	var plan: ChapterPlanData = scene._chapter_plan
	check(plan != null and plan.big_map, "chapter_4_plan_is_big_map")
	if plan == null or not plan.big_map:
		_finish(scene)
		return

	# --- The Chapter 4 route (pass 91): slot 3 carries this plan, the game
	# loads this big-map world, the legacy chapter-4 world stays on disk, and the
	# plan content the earlier passes authored is unchanged.
	var game_script := load("res://scripts/game.gd") as GDScript
	var constants: Dictionary = game_script.get_script_constant_map() if game_script != null else {}
	var enemy_art: Dictionary = constants.get("ENEMY_ART", {})
	var plan_paths: Array = constants.get("CHAPTER_PLAN_PATHS", [])
	var world_files: Array = constants.get("MDS_WORLD_FILES", [])
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
	check(FileAccess.file_exists("res://scenes/mds/chapter_4.mdsworld.json"),
		"legacy_chapter_4_world_exists")
	check(FileAccess.file_exists("res://scenes/mds/chapter_4_world.tscn"),
		"legacy_chapter_4_world_scene_exists")
	check(plan.start_region() == "ch4_entry", "chapter_4_starts_at_entry")
	check(plan.clear_target() == 7, "chapter_4_clear_target_seven")
	check(plan.encounter_ids().size() == 7, "chapter_4_seven_encounters")
	check(not plan.content_pending, "chapter_4_content_landed")
	check(plan.boss_scene != null
		and plan.boss_scene.resource_path == "res://scenes/bosses/smiling_archivist.tscn",
		"chapter_4_boss_scene_routes_smiling_archivist")
	var plan_authority_ids: Array[StringName] = []
	for authority in plan.authority_pool:
		plan_authority_ids.append(authority.id)
	check(plan_authority_ids.has(&"revive") and plan_authority_ids.has(&"rewrite"),
		"chapter_4_authority_pool_has_base")
	check(plan.wave_for("ch4_boss", "ch4_boss/Arena").is_empty(),
		"chapter_4_boss_has_no_ordinary_wave")
	check(plan.wave_for("ch4_event", "ch4_event/event").is_empty(),
		"chapter_4_event_has_no_ordinary_wave")

	# --- Plan graph: the entry reaches every region, doors are mirrored unless
	# explicitly one-way, and the only requirement is the shortcut ability.
	check(scene._chapter == 3, "running_chapter_4")
	check(mds.current_room == "ch4_entry", "chapter_4_starts_at_entry_room")
	check(mds.current_room == plan.start_region(), "chapter_4_start_from_plan")
	check(scene._chapter_clear_target() == 7, "chapter_4_runtime_clear_target")
	check(scene._chapter_progress_total() == 8, "chapter_4_progress_total_includes_boss")
	check(is_equal_approx(scene._fall_limit_local, 1680.0), "chapter_4_entry_fall_plane")
	check(not scene._story.is_open() and not paused, "chapter_4_no_intro_modal")
	check(_progress_text(scene) == "档案  0 / 8", "chapter_4_hud_progress_starts")
	# The chapter table carries the campaign objective, but the loaded room owns
	# the HUD line: `ch4_entry` is a no-combat region, so its runtime objective
	# replaces the chapter line the moment the room reports in.
	check(not String(CampaignData.chapter(3)["objective"]).is_empty(),
		"chapter_4_objective_authored")
	# `ch4_entry` has no combat and no rest facilities, so it must not borrow
	# the shop/bench arrival copy; the objective only points onward.
	check(_objective_text(scene) == "继续前进", "chapter_4_hud_entry_objective")
	check(not scene._rest_greeted.has("ch4_entry"), "chapter_4_entry_no_rest_copy")

	# Map overlay: chapter 4 derives its title from the authored region, and the
	# overlay draws the chapter-4 big-map world rather than the legacy one.
	check(String(CampaignData.chapter(3).get("region", "")) == "笑面剧场",
		"chapter_4_region_authored")
	check(scene._map_overlay.title_text() == "笑面剧场地图", "chapter_4_map_title")
	check(scene._map_overlay.map_view.world_file == CH4_WORLD_FILE,
		"chapter_4_map_uses_bigmap_world")
	check(scene._map_overlay.map_view.world != null
		and scene._map_overlay.map_view.world.get_room_ids().size() == 9,
		"chapter_4_map_has_nine_regions")
	var map_view = scene._map_overlay.map_view
	map_view.reveal_all = false
	check(map_view.is_room_revealed("ch4_entry"), "map_reveals_entry")
	check(not map_view.is_room_revealed("ch4_vault"), "map_hides_vault")

	var reachable := _bfs_rooms(plan)
	check(reachable.size() == plan.room_ids().size(), "chapter_4_all_regions_reachable")
	for room_id in plan.room_ids():
		check(reachable.has(String(room_id)), "chapter_4_reachable_%s" % room_id)
	check(reachable.has("ch4_hub"), "chapter_4_hub_reachable")
	check(reachable.has("ch4_vault"), "chapter_4_vault_reachable")
	check(reachable.has("ch4_event"), "chapter_4_event_reachable")
	check(reachable.has("ch4_boss"), "chapter_4_boss_reachable")
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
	check(one_way_doors.size() == 2, "chapter_4_two_one_way_doors")
	check(one_way_doors.has("elite_boss"), "chapter_4_elite_boss_one_way")
	check(one_way_doors.has("hub_shortcut_entry"), "chapter_4_shortcut_one_way")
	var shortcut_doors := 0
	for door in plan.doors:
		var requires: Array = door.get("requires", [])
		if requires.is_empty():
			continue
		shortcut_doors += 1
		check(String(door.get("from", "")) == "ch4_hub", "shortcut_from_hub")
		check(String(door.get("from_gate", "")) == "shortcut", "shortcut_gate_name")
		check(requires.size() == 1 and String(requires[0]) == "ch4_shortcut",
			"shortcut_requires_ability")
	check(shortcut_doors == 1, "chapter_4_single_required_door")
	check(plan.shortcut_ids().has("hub_shortcut_entry"), "chapter_4_shortcut_planned")

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
	check(arrival_gates.has("ch4_entry/shortcut_arrival"),
		"world_shortcut_arrival_is_arrival_only")
	check(arrival_gates.has("ch4_boss/left1"), "world_boss_gate_is_arrival_only")

	# --- Fresh-run spawn: `ch4_entry` authors a save_point marker on its first
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
		check(mds._spawn_position("ch4_entry", "", Vector2.INF)
			.distance_to(spawn.global_position) < 1.0, "entry_spawn_precedes_label")
		var label_pos: Vector2 = mds.world.get_room_label_pos("ch4_entry")
		check(spawn.global_position.y > label_pos.y + 400.0,
			"entry_spawn_not_room_label_anchor")
		var settled: Vector2 = scene.player.global_position
		await physics_frame
		check(scene.player.is_on_floor(), "entry_spawn_on_floor")
		await create_timer(0.3).timeout
		check(scene.player.global_position.distance_to(settled) < 1.0,
			"entry_spawn_no_air_fall")
	_check_region(scene, "ch4_entry")

	# Keep the player alive while the suite drives him through live arenas; the
	# damage checks below clear this again.
	scene.player._invulnerable_left = 10000

	# --- The event node is settled up front so walking through its region
	# during the graph sweep cannot open a paused page mid-transition. The event
	# trigger gets its own fresh section later.
	scene._cleared_encounters["ch4_event/event"] = true
	scene._cleared_in_chapter = 1

	# --- Hidden vault: first discovery, map reveal, and one-shot chest/stele
	# that stay settled through a room reload.
	await mds.load_room("ch4_vault")
	check(await _wait_room(scene, "ch4_vault"), "vault_loads")
	await process_frame
	var vault_line := VaultRoomData.pick(scene.run_state.run_seed, "ch4_vault")
	check(scene._discovered_vaults.has("ch4_vault"), "vault_first_discovery_recorded")
	check(scene.hud.get_message_text() == vault_line, "vault_first_discovery_copy")
	check(map_view.is_room_revealed("ch4_vault"), "vault_first_discovery_reveals_map")
	_check_region(scene, "ch4_vault")
	check(scene._chests.size() == 1, "vault_one_chest")
	check(scene._steles.size() == 1, "vault_one_stele")
	var vault_chest := mds.room_node.get_node_or_null("Chest1") as TreasureChest
	var vault_stele := mds.room_node.get_node_or_null("Stele1") as MemoryStele
	check(vault_chest != null and vault_stele != null, "vault_named_content")
	if vault_chest != null:
		scene._open_chest(vault_chest)
		await process_frame
	check(scene._opened_chests.has("ch4_vault/Chest1"), "vault_chest_one_shot")
	if vault_stele != null:
		scene.player.global_position = vault_stele.global_position
		scene.player.velocity = Vector2.ZERO
		await physics_frame
		scene._claim_nearest_stele()
		await process_frame
	check(scene._claimed_steles.has("ch4_vault/Stele1"), "vault_stele_one_shot")
	var after_claim_message: String = scene.hud.get_message_text()
	await mds.load_room("ch4_vault")
	check(await _wait_room(scene, "ch4_vault"), "vault_reloads")
	await process_frame
	var kept_chest := mds.room_node.get_node_or_null("Chest1") as TreasureChest
	check(kept_chest != null and kept_chest.is_open, "vault_chest_stays_open")
	check(scene._steles.is_empty(), "vault_claimed_stele_removed")
	check(scene.hud.get_message_text() == after_claim_message,
		"vault_reload_does_not_repeat_discovery")
	check(not scene._reward_ui.visible, "vault_no_false_reward")

	# --- The other three one-shot props (one chest in each of branch A and the
	# well, one stele in the hub) settle under their own node ids too.
	await mds.load_room("ch4_hub")
	check(await _wait_room(scene, "ch4_hub"), "hub_loads")
	await process_frame
	check(scene._shops.size() == 1, "hub_has_one_shop")
	if scene._shops.size() == 1:
		check(String(scene._shops[0].shop_id) == "ch4_hub_shop", "hub_shop_id")
	check(bool(plan.room("ch4_hub").get("rest", false)), "hub_is_rest_region")
	_check_region(scene, "ch4_hub")
	# The hub authors a Shop and a Bench, so it keeps the rest branch that the
	# entry region (same pipeline, no facilities) no longer takes.
	check(scene._rest_greeted.has("ch4_hub"), "chapter_4_hub_keeps_rest_copy")
	check(_objective_text(scene) == "休整，或继续前进", "chapter_4_hub_rest_objective")
	check(scene._steles.size() == 1, "hub_one_stele")
	var hub_stele := mds.room_node.get_node_or_null("Stele1") as MemoryStele
	if hub_stele != null:
		scene.player.global_position = hub_stele.global_position
		scene.player.velocity = Vector2.ZERO
		await physics_frame
		scene._claim_nearest_stele()
		await process_frame
	check(scene._claimed_steles.has("ch4_hub/Stele1"), "hub_stele_one_shot")
	await mds.load_room("ch4_hub")
	check(await _wait_room(scene, "ch4_hub"), "hub_reloads")
	await process_frame
	check(scene._steles.is_empty(), "hub_claimed_stele_removed")

	for chest_entry in [["ch4_branch_a", "ch4_branch_a/Chest1"],
			["ch4_well", "ch4_well/Chest1"]]:
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
	await _time_load(scene, "ch4_boss", "boss_background_off")
	mds.room_background = true
	mds.room_weather = false
	await _time_load(scene, "ch4_boss", "boss_weather_off")
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
	await _time_load(scene, "ch4_boss", "boss_not_spawned")
	await process_frame
	await process_frame
	scene._boss_defeated = false
	scene._boss_aftermath_started = false
	mds.fade_time = old_fade
	# A real door transition with the authored fade: the wall-clock cost the
	# player actually sees, versus the raw build times above.
	await mds.load_room("ch4_entry")
	check(await _wait_room(scene, "ch4_entry"), "perf_restore_entry")
	# The arrival gate stays on cooldown for 0.35 s after the room reports in; a
	# real player cannot leave before it expires either, so wait it out before
	# timing the door.
	await create_timer(0.45).timeout
	var gate_started := Time.get_ticks_usec()
	var perf_gate := MDSGate.find_gate(mds.room_node, "right1")
	check(perf_gate != null, "perf_gate_present")
	if perf_gate != null:
		perf_gate.use()
		check(await _wait_room(scene, "ch4_branch_a"), "perf_gate_arrives")
		var gate_ms := (Time.get_ticks_usec() - gate_started) / 1000.0
		print("PERF: door_transition ch4_entry.right1 = %.2f ms" % gate_ms)
	check(not mds.seamless_rooms, "world_is_not_seamless")
	check(mds.world_file == CH4_WORLD_FILE, "world_file_is_bigmap")
	check(is_equal_approx(mds.fade_time, 0.22), "world_fade_authored")

	# --- All five authored lifts (branch B / hub / vault / well / elite) use the
	# pipeline's default speed and fit inside their region. This only records the
	# pace; the elevator rhythm question (status #12) is scoped to Chapter 2 and
	# is not decided or changed here.
	for lift_region in ["ch4_branch_b", "ch4_hub", "ch4_vault", "ch4_well",
			"ch4_elite"]:
		var lift_room := String(lift_region)
		await mds.load_room(lift_room)
		check(await _wait_room(scene, lift_room), "lift_room_loads_%s" % lift_room)
		await process_frame
		var lift_node := mds.room_node.get_node_or_null("Lift") as MovingPlatform
		check(lift_node != null, "lift_present_%s" % lift_room)
		if lift_node != null:
			check(is_equal_approx(lift_node.speed, 80.0),
				"lift_pipeline_speed_%s" % lift_room)
			check(not lift_node.travel_clamped,
				"lift_travel_fits_room_%s" % lift_room)
			check(mds.room_node.room_bounds.encloses(lift_node.platform_rect()),
				"lift_inside_room_%s" % lift_room)

	# --- Vertical transit: the authored lift really reaches the top gate, the
	# jump triggers it, the arrival launches up, and the floor gate does not
	# bounce the player straight back down.
	await mds.load_room("ch4_branch_b")
	check(await _wait_room(scene, "ch4_branch_b"), "lift_room_loads")
	await process_frame
	_check_region(scene, "ch4_branch_b")
	var lift := mds.room_node.get_node_or_null("Lift") as MovingPlatform
	check(lift != null, "branch_b_lift_present")
	if lift != null:
		# Chapter 4 authors no speed either, so the pipeline default 80 px/s
		# applies (status #12 is scoped to Chapter 2 and is not changed here).
		check(is_equal_approx(lift.speed, 80.0), "branch_b_lift_pipeline_speed")
		check(not lift.travel_clamped, "branch_b_lift_travel_fits_room")
		check(mds.room_node.room_bounds.encloses(lift.platform_rect()),
			"branch_b_lift_inside_room")
		scene.player.global_position = lift.global_position \
			+ Vector2(80, -16 - Player.FOOT_Y)
		scene.player.velocity = Vector2.ZERO
		# The authored 80 px/s ride takes ~17 s; the test only needs the same
		# travel, so speed the platform up for the ride itself.
		lift.speed = 700.0
		lift.restart(0.0)
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
			if mds.changing_room or mds.current_room != "ch4_branch_b":
				triggered = true
				break
		check(triggered, "branch_b_top_gate_triggers_on_jump")
		check(await _wait_room(scene, "ch4_entry"), "branch_b_top_gate_arrives_entry")
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
		check(mds.current_room == "ch4_entry", "bot_arrival_does_not_bounce_back")
		check(not mds.changing_room, "bot_arrival_settles")
		check(not paused, "bot_arrival_not_paused")
		await process_frame
		_check_region(scene, "ch4_entry")

	# --- The whole connected graph, one gate at a time. Every arrival gets the
	# exact spawn point, exit-velocity rule, camera bounds and a modal-free HUD.
	# The shortcut's condition is checked closed here and opened only through a
	# test-injected ability; no gameplay source grants `ch4_shortcut`.
	await mds.load_room("ch4_entry")
	check(await _wait_room(scene, "ch4_entry"), "walk_starts_at_entry")
	var shortcut_checked := false
	var shortcut_granted := false
	var event_objective_checked := false
	for step in WALK:
		var step_gate := String(step[0])
		if step_gate == "shortcut" and not shortcut_granted:
			check(mds.current_room == "ch4_hub", "shortcut_step_from_hub")
			check(not mds.has_ability("ch4_shortcut"),
				"shortcut_not_granted_by_traversal")
			var closed_barrier := mds.room_node.get_node_or_null(
				"Barrier_shortcut") as MDSGateBarrier
			check(closed_barrier != null and not closed_barrier.is_open,
				"shortcut_barrier_closed_before_ability")
			mds.grant_ability("ch4_shortcut")
			await process_frame
			check(mds.has_ability("ch4_shortcut"), "shortcut_test_ability_injected")
			if closed_barrier != null:
				check(closed_barrier.is_open, "shortcut_barrier_opens_with_ability")
				check(mds.get_save_data().get("stored", []).has(
					mds.object_id(closed_barrier)), "shortcut_opening_is_stored")
			shortcut_granted = true
		var ok := await _use_gate(scene, step_gate, String(step[1]), String(step[2]))
		if not ok:
			break
		if mds.current_room == "ch4_hub" and not shortcut_checked \
				and not shortcut_granted:
			var barrier := mds.room_node.get_node_or_null(
				"Barrier_shortcut") as MDSGateBarrier
			check(barrier != null, "hub_shortcut_barrier")
			if barrier != null:
				check(not barrier.is_open, "hub_shortcut_starts_closed")
				var requirements := barrier.get_requirements()
				check(requirements.size() == 1
					and String(requirements[0]) == "ch4_shortcut",
					"hub_shortcut_requires_ability")
			var shortcut_gate := MDSGate.find_gate(mds.room_node, "shortcut")
			check(shortcut_gate != null, "hub_shortcut_gate")
			if shortcut_gate != null:
				check(shortcut_gate.mode == MDSGate.Mode.INTERACT,
					"hub_shortcut_is_a_door")
				check(String(shortcut_gate.get_transition().get("room", ""))
					== "ch4_entry", "hub_shortcut_targets_entry")
			shortcut_checked = true
		if mds.current_room == "ch4_event" and not event_objective_checked:
			check(_objective_text(scene) == "事件已经读过",
				"event_region_shows_settled_objective")
			event_objective_checked = true
		if step_gate == "shortcut":
			# The arrival gate only receives players: using it must be inert.
			walked["ch4_entry/shortcut_arrival"] = true
			var shortcut_arrival := MDSGate.find_gate(
				mds.room_node, "shortcut_arrival")
			check(shortcut_arrival != null, "entry_shortcut_arrival_present")
			if shortcut_arrival != null:
				check(shortcut_arrival.get_transition().is_empty(),
					"entry_shortcut_arrival_dead_end")
				shortcut_arrival.use()
				await create_timer(0.3).timeout
				check(mds.current_room == "ch4_entry",
					"entry_shortcut_arrival_inert")
				check(not mds.changing_room,
					"entry_shortcut_arrival_no_transition")
	check(mds.current_room == "ch4_boss", "walk_reaches_boss")
	var boss_gate := MDSGate.find_gate(mds.room_node, "left1")
	check(boss_gate != null, "boss_left_gate_present")
	if boss_gate != null:
		walked["ch4_boss/left1"] = true
		check(boss_gate.get_transition().is_empty(), "boss_door_is_one_way")
		boss_gate.use()
		await create_timer(0.4).timeout
		check(mds.current_room == "ch4_boss", "boss_dead_end_holds")
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
	# not a fall death. The three one-way platforms also drop through on
	# down+jump.
	scene.player._invulnerable_left = 0
	await mds.load_room("ch4_well")
	check(await _wait_room(scene, "ch4_well"), "well_loads")
	await process_frame
	_check_region(scene, "ch4_well")
	check(is_equal_approx(scene._fall_limit_local, 2400.0), "well_fall_plane")
	var well_origin: Vector2 = mds.world.get_origin("ch4_well")
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
	var one_way_platforms := 0
	for platform_name in ["OneWay1", "OneWay2", "OneWay3"]:
		if mds.room_node.get_node_or_null(platform_name) is OneWayPlatform:
			one_way_platforms += 1
	check(one_way_platforms == 3, "well_three_one_way_platforms")
	var one_way_platform := mds.room_node.get_node_or_null("OneWay2") as OneWayPlatform
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
	await mds.load_room("ch4_hub")
	check(await _wait_room(scene, "ch4_hub"), "bench_room_loads")
	await process_frame
	_check_region(scene, "ch4_hub")
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
		check(String(reloaded_shortcut.get_transition().get("room", "")) == "ch4_entry",
			"hub_shortcut_target_entry_on_reload")
		# `get_transition()` is the runtime target only; the one-way annotation
		# lives on the world gate. The reverse gate must not exist (that is what
		# makes the return trip impossible).
		check(bool(mds.world.get_gate("ch4_hub", "shortcut").get("one_way", false)),
			"hub_shortcut_transition_is_one_way")
		check(mds.world.get_transition("ch4_entry", "shortcut_arrival").is_empty(),
			"hub_shortcut_has_no_return_transition")

	# --- Two encounters in one region: each locks and clears on its own node
	# id, its real door bodies block/release, and a reload keeps both cleared.
	scene._cleared_encounters.clear()
	scene._legacy_cleared_rooms.clear()
	scene._cleared_in_chapter = 0
	await mds.load_room("ch4_branch_a")
	check(await _wait_room(scene, "ch4_branch_a"), "combat_room_loads")
	await process_frame
	_check_region(scene, "ch4_branch_a")
	var arena_a := mds.room_node.get_node_or_null("Arena") as ArenaRoom
	var arena_b := mds.room_node.get_node_or_null("Arena2") as ArenaRoom
	check(arena_a != null and arena_b != null, "branch_a_two_arenas")
	check(scene._rooms.size() == 2, "branch_a_two_registered_arenas")
	var ground := _ground_surface_y(mds.room_node)
	if arena_a != null:
		check(arena_a.enemy_count() == 2, "arena_a_first_wave")
		check(_enemy_art_paths(arena_a) == _expected_art_paths(
			plan.wave_for("ch4_branch_a", "ch4_branch_a/Arena"), enemy_art),
			"arena_a_uses_plan_wave")
		for enemy in arena_a.get_node(ArenaRoom.ENEMIES_NODE).get_children():
			if enemy is Node2D:
				check((enemy as Node2D).global_position.y < ground,
					"arena_a_enemy_above_ground")
		# Chapter 4's waves are all wired enemies: each must use its own PNG at
		# white (the pass-50 audit's "no fallback" conclusion, re-checked live).
		_check_enemy_art(arena_a, "assets/sprites/enemies/mask_enemy.png", Color.WHITE)
		_check_enemy_art(arena_a, "assets/sprites/enemies/seat_husk.png", Color.WHITE)
	if arena_b != null:
		check(arena_b.enemy_count() == 2, "arena_b_first_wave")
		check(_enemy_art_paths(arena_b) == _expected_art_paths(
			plan.wave_for("ch4_branch_a", "ch4_branch_a/Arena2"), enemy_art),
			"arena_b_uses_own_plan_wave")
		_check_enemy_art(arena_b, "assets/sprites/enemies/choir_summoner.png",
			Color.WHITE)
		_check_enemy_art(arena_b, "assets/sprites/enemies/page_swarm.png", Color.WHITE)
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
		check(scene._cleared_encounters.has("ch4_branch_a/Arena"),
			"arena_a_settles_own_id")
		check(not scene._cleared_encounters.has("ch4_branch_a/Arena2"),
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
		check(scene._cleared_encounters.has("ch4_branch_a/Arena2"),
			"arena_b_settles_own_id")
		check(scene._cleared_in_chapter == 2, "arena_b_counts_once")
		scene._reward_ui._choose(0)
		await process_frame
		var settled: int = scene._cleared_in_chapter
		arena_b.cleared.emit()
		await process_frame
		check(scene._cleared_in_chapter == settled, "cleared_arena_reemit_ignored")
	await mds.load_room("ch4_branch_a")
	check(await _wait_room(scene, "ch4_branch_a"), "combat_room_reloads")
	await process_frame
	var reload_a := mds.room_node.get_node_or_null("Arena") as ArenaRoom
	var reload_b := mds.room_node.get_node_or_null("Arena2") as ArenaRoom
	check(reload_a != null and reload_a.enemy_count() == 0,
		"cleared_arena_a_not_respawned")
	check(reload_b != null and reload_b.enemy_count() == 0,
		"cleared_arena_b_not_respawned")
	check(scene._rooms.is_empty(), "cleared_arenas_not_registered")
	check(not scene._reward_ui.visible, "cleared_arena_no_false_reward")

	# --- Every combat encounter in the plan spawns its authored wave in the real
	# region. Branch A's pair above was driven through lock/clear/reward; the
	# remaining four encounters are checked for live wave/art parity here so all
	# six planned waves are exercised by the acceptance run.
	for wave_region in ["ch4_branch_b", "ch4_well", "ch4_elite"]:
		var region_id := String(wave_region)
		await mds.load_room(region_id)
		check(await _wait_room(scene, region_id), "wave_region_loads_%s" % region_id)
		await process_frame
		var wave_table: Dictionary = plan.room(region_id).get("wave", {})
		check(not wave_table.is_empty(), "wave_region_authored_%s" % region_id)
		for encounter_key in wave_table:
			var encounter_id := String(encounter_key)
			var arena_name := encounter_id.get_slice("/", 1)
			var arena := mds.room_node.get_node_or_null(arena_name) as ArenaRoom
			check(arena != null, "wave_arena_present_%s_%s" % [region_id, arena_name])
			if arena != null:
				var wave := plan.wave_for(region_id, encounter_id)
				check(_enemy_art_paths(arena) == _expected_art_paths(wave, enemy_art),
					"wave_arena_uses_plan_wave_%s_%s" % [region_id, arena_name])
				# All six planned waves really spawn their dedicated paintings at
				# white in the live region, not just the branch-A pair above.
				_check_wave_enemy_art(arena, wave, enemy_art,
					"%s_%s" % [region_id, arena_name])

	# --- Clear target: the remaining five nodes bring the chapter to the plan's
	# seven, and the HUD denominator keeps the boss slot at eight.
	for encounter_id in plan.encounter_ids():
		var id := String(encounter_id)
		if scene._cleared_encounters.has(id):
			continue
		check(scene._mark_encounter_cleared(id.get_slice("/", 0), id),
			"mark_encounter_%s" % id)
	check(scene._cleared_in_chapter == 7, "chapter_4_seven_clears")
	check(scene._cleared_in_chapter == plan.clear_target(),
		"chapter_4_clears_match_plan")
	check(scene._chapter_progress_total() == 8, "chapter_4_progress_keeps_boss_slot")
	check(scene._cleared_encounters.size() == 7, "chapter_4_seven_encounter_ids")
	check(_progress_text(scene) == "档案  7 / 8", "chapter_4_hud_progress_seven")

	# --- The event copy module: seven rotating Smiling Theater pages, each with
	# the full fixed read/take pair, selected deterministically without touching
	# the run RNG (a resume must not shift the loot sequence).
	var event_variants := Ch4EventData.variants()
	check(event_variants.size() == 7, "event_seven_variants")
	var event_keys := ["eyebrow", "title", "body", "read_label", "take_label",
		"read_word_message", "read_pages_message", "take_message"]
	for event_variant in event_variants:
		for event_key in event_keys:
			check(not String(event_variant.get(event_key, "")).is_empty(),
				"event_variant_%s_%s" % [event_variant.get("eyebrow", "?"), event_key])
	var rng_state: int = scene.run_state.rng.state
	check(Ch4EventData.pick(scene.run_state.run_seed, "ch4_event/event")
		== Ch4EventData.pick(scene.run_state.run_seed, "ch4_event/event"),
		"event_pick_deterministic")
	check(scene.run_state.rng.state == rng_state, "event_pick_does_not_consume_rng")

	# --- The event region's real page: rewound once so the region trigger can
	# open it, then it pays once and stays quiet on a reload.
	scene._cleared_encounters.erase("ch4_event/event")
	scene._cleared_in_chapter -= 1
	scene._event_room_id = ""
	await mds.load_room("ch4_event")
	check(await _wait_room(scene, "ch4_event"), "event_region_loads")
	_check_region(scene, "ch4_event")
	var page_open := await _wait_story(scene)
	check(page_open, "event_page_opens")
	if page_open:
		var expected_event := Ch4EventData.pick(
			scene.run_state.run_seed, "ch4_event/event")
		check(not expected_event.is_empty(), "event_variant_resolves")
		check(scene._story._eyebrow.text == String(expected_event.get("eyebrow", "")),
			"event_uses_chapter_4_copy")
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
		check(scene.run_state.pages == pages_before + Ch4EventData.PAGES_REWARD,
			"event_taking_pays_pages")
		check(scene.hud.get_message_text()
			== String(expected_event.get("take_message", "")) % Ch4EventData.PAGES_REWARD,
			"event_take_message")
		check(scene._cleared_encounters.has("ch4_event/event"),
			"event_encounter_settles")
		check(scene._cleared_in_chapter == clears_before + 1,
			"event_counts_once")
		check(scene._cleared_in_chapter == 7, "event_restores_seven_clears")
	await mds.load_room("ch4_event")
	check(await _wait_room(scene, "ch4_event"), "event_region_reloads")
	await create_timer(1.2).timeout
	check(not scene._story.is_open(), "event_no_retrigger_after_settle")
	check(not paused, "event_no_retrigger_pause")
	check(scene._cleared_in_chapter == 7, "event_no_double_count")
	check(not scene._reward_ui.visible, "event_no_duplicate_reward")

	# --- Save inside the hidden vault with the seven clears, the shortcut and
	# the settled content; the MDS dictionary is restored into a fresh world the
	# same way a resume does. (The campaign itself cannot resume into the chapter
	# 4 big map yet: its plan slot is empty by design.)
	flow.auto_save = true
	await mds.load_room("ch4_vault")
	check(await _wait_room(scene, "ch4_vault"), "save_room_loads")
	await process_frame
	var vault_origin: Vector2 = mds.world.get_origin("ch4_vault")
	scene.player.global_position = vault_origin + Vector2(1200, 1408)
	scene.player.velocity = Vector2.ZERO
	await physics_frame
	var saved_position: Vector2 = scene.player.global_position
	check(scene.save_run_now(), "chapter_4_run_save_writes")
	var saved := RunSave.read(RUN_PATH)
	var saved_run: Dictionary = saved.get("run", {})
	var saved_progress: Dictionary = saved.get("progress", {})
	var saved_world: Dictionary = saved.get("world", {})
	var saved_mds: Dictionary = saved.get("mds", {})
	check(int(saved_run.get("chapter", -1)) == 3, "chapter_4_save_chapter")
	check(String(saved_run.get("room", "")) == "ch4_vault", "chapter_4_save_room")
	check(int(saved_progress.get("cleared_in_chapter", 0)) == 7,
		"chapter_4_save_clear_count")
	check((saved_progress.get("cleared_encounters", []) as Array).size() == 7,
		"chapter_4_save_encounter_ids")
	check((saved_progress.get("vaults", []) as Array).has("ch4_vault"),
		"chapter_4_save_vault_discovery")
	check((saved_world.get("claimed_stele_ids", []) as Array).has("ch4_vault/Stele1"),
		"chapter_4_save_vault_stele")
	check((saved_world.get("claimed_stele_ids", []) as Array).has("ch4_hub/Stele1"),
		"chapter_4_save_hub_stele")
	check((saved_world.get("opened_chest_ids", []) as Array).has("ch4_vault/Chest1"),
		"chapter_4_save_vault_chest")
	check((saved_world.get("opened_chest_ids", []) as Array).has("ch4_branch_a/Chest1"),
		"chapter_4_save_branch_chest")
	check((saved_world.get("opened_chest_ids", []) as Array).has("ch4_well/Chest1"),
		"chapter_4_save_well_chest")
	check((saved_world.get("opened_chest_ids", []) as Array).size() == 3,
		"chapter_4_save_three_chests")
	check((saved_mds.get("abilities", []) as Array).has("ch4_shortcut"),
		"chapter_4_save_shortcut_ability")
	check((saved_mds.get("stored", []) as Array).has("ch4_hub/Barrier_shortcut"),
		"chapter_4_save_shortcut_barrier")
	check(String(saved_mds.get("room", "")) == "ch4_vault", "chapter_4_save_mds_room")
	check((saved_mds.get("visited", []) as Array).has("ch4_boss"),
		"chapter_4_save_mds_visits")
	flow.auto_save = false

	# Restore the saved MDS dictionary into a fresh chapter-4 world. The room,
	# coordinates, visited map, ability and opened barrier all come back.
	scene.hud.show_message("__resume_sentinel__")
	check(await _mount_chapter_4(scene, "ch4_entry", saved_mds, false),
		"chapter_4_world_resume_mounts")
	mds = scene._mds_world
	check(await _wait_room(scene, "ch4_vault"), "chapter_4_world_resume_room")
	check(not scene._story.is_open() and not paused, "chapter_4_world_resume_no_modal")
	check(scene.player.global_position.distance_to(saved_position) < 8.0,
		"chapter_4_world_resume_position")
	check(scene.hud.get_message_text() == "__resume_sentinel__",
		"chapter_4_world_resume_no_repeat_discovery")
	check(scene._cleared_in_chapter == 7, "chapter_4_world_resume_clear_count")
	check(scene._cleared_encounters.size() == 7, "chapter_4_world_resume_encounter_ids")
	check(mds.has_ability("ch4_shortcut"), "chapter_4_world_resume_shortcut_ability")
	check(map_view.is_room_revealed("ch4_vault"), "chapter_4_world_resume_map")
	var resume_chest := mds.room_node.get_node_or_null("Chest1") as TreasureChest
	check(resume_chest != null and resume_chest.is_open,
		"chapter_4_world_resume_chest_open")
	check(scene._steles.is_empty(), "chapter_4_world_resume_stele_removed")
	await mds.load_room("ch4_hub")
	check(await _wait_room(scene, "ch4_hub"), "chapter_4_world_resume_hub")
	await process_frame
	var resume_barrier := mds.room_node.get_node_or_null(
		"Barrier_shortcut") as MDSGateBarrier
	check(resume_barrier != null and resume_barrier.is_open,
		"chapter_4_world_resume_barrier_open")
	check(scene._claimed_steles.has("ch4_hub/Stele1"),
		"chapter_4_world_resume_hub_stele")
	check(scene._steles.is_empty(), "chapter_4_world_resume_hub_stele_removed")

	# --- Boss region: the Smiling Archivist spawns above the floor in its own
	# region, the chapter-4 entrance/phase copy and authority pool are used, and
	# the real defeat chain ends the campaign at the chapter-4 boundary instead
	# of looking for a fifth chapter. Deep mechanics live in test_ch4_boss and
	# integration_playability; this section only covers the acceptance wiring.
	await mds.load_room("ch4_boss")
	check(await _wait_room(scene, "ch4_boss"), "boss_room_loads")
	await process_frame
	_check_region(scene, "ch4_boss")
	check(is_instance_valid(scene._boss), "boss_spawns_in_region")
	var boss := scene._boss as SmilingArchivist
	check(boss != null, "boss_uses_smiling_archivist")
	check(scene._boss is InkArchivist, "boss_reuses_generic_flow")
	check(not (scene._boss is LastReader), "boss_is_not_chapter_3")
	check(not (scene._boss is LungBellGuardian), "boss_is_not_chapter_2")
	check(not (scene._boss is InkArchivistCh1), "boss_is_not_chapter_1")
	check(plan.boss_scene != null
		and plan.boss_scene.resource_path.ends_with("smiling_archivist.tscn"),
		"boss_scene_routed_from_plan")
	check(scene._mds_boss_arena != null, "boss_arena_registered")
	var boss_bounds: Rect2 = mds.world.get_room_bounds("ch4_boss")
	var boss_entrance_gate := MDSGate.find_gate(mds.room_node, "left1")
	var chapter := CampaignData.chapter(3)
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
			check(boss.data.contact_damage == int(chapter["boss_damage"]),
				"boss_damage_from_campaign")
			check(is_equal_approx(boss.data.speed,
				float(chapter["boss_speed"])), "boss_speed_from_campaign")
			# The authored portrait from the campaign table is the Smiling
			# Archivist's; no fallback tint.
			check(boss.sprite_visual != null, "boss_has_sprite")
			if boss.sprite_visual != null:
				check(boss.sprite_visual.texture.resource_path.ends_with(
					"assets/sprites/bosses/smiling_archivist.png"), "boss_uses_smiling_art")
				check(boss.sprite_visual.modulate == Color.WHITE,
					"boss_no_fallback_tint")
		scene.player._invulnerable_left = 100
		scene.player.global_position = boss_arena.global_position
		await process_frame
		await process_frame
		check(boss_arena.is_locked(), "boss_arena_locks")
		check(_arena_doors_locked(boss_arena), "boss_doors_block")
		var entrance_line := BossEntranceData.pick(scene.run_state.run_seed, 3)
		check(BossEntranceData.variants(3).has(entrance_line),
			"boss_entrance_uses_chapter_4_copy")
		check(scene.hud.get_message_text() == entrance_line,
			"boss_entrance_matches_seed")
		var phase_line := BossPhaseData.pick(scene.run_state.run_seed, 2, 3)
		check(phase_line != "", "boss_phase_line_authored")
		scene._on_boss_phase(chapter, 2)
		check(scene.hud.get_message_text()
			== "%s · 第 2 阶段：%s" % [chapter["boss_name"], phase_line],
			"boss_phase_uses_chapter_4_copy")
		var phase_three_line := BossPhaseData.pick(scene.run_state.run_seed, 3, 3)
		check(phase_three_line != "", "boss_phase_three_line_authored")
		scene._on_boss_phase(chapter, 3)
		check(scene.hud.get_message_text()
			== "%s · 第 3 阶段：%s" % [chapter["boss_name"], phase_three_line],
			"boss_phase_three_uses_chapter_4_copy")
		# The plan's base pool is revive + rewrite; the two conditional entries
		# join it at their usual thresholds. Probe on a throwaway RunState so the
		# live run's corruption/records are untouched.
		var pool_probe := RunState.new()
		pool_probe.reset_for_new_run(4242)
		pool_probe.corruption = 0
		var base_ids: Array[StringName] = []
		for authority in AuthorityController.build_pool(
				plan.authority_pool, pool_probe, flow.profile, 0):
			base_ids.append(authority.id)
		check(base_ids.size() == 2 and base_ids.has(&"revive")
			and base_ids.has(&"rewrite"), "authority_base_pool_only")
		pool_probe.corruption = 40
		var devour_ids: Array[StringName] = []
		for authority in AuthorityController.build_pool(
				plan.authority_pool, pool_probe, flow.profile, 0):
			devour_ids.append(authority.id)
		check(devour_ids.has(&"devour"), "authority_devour_at_corruption_40")
		pool_probe.corruption = 0
		var archive_ids: Array[StringName] = []
		for authority in AuthorityController.build_pool(
				plan.authority_pool, pool_probe, flow.profile, 2):
			archive_ids.append(authority.id)
		check(archive_ids.has(&"archive"), "authority_archive_at_two_records")
	# Defeat through the real flow: authority pick from the plan's pool, the
	# chapter-4 outro and choice, then `_finish(true)` at the campaign end.
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
		check(scene._story._title.text == String(chapter["title"]),
			"boss_outro_uses_chapter_title")
		check(scene._story._body.text == "\n".join(chapter["outro"]),
			"boss_outro_uses_authored_copy")
		check(scene._story._voice_id == "ch4_outro",
			"boss_outro_plays_authored_voice")
		scene._story.close()
		await process_frame
		check(scene._story.is_open(), "boss_choice_opens")
		check(scene._story._choice_mode, "boss_choice_is_choice_page")
		var chapter_options: Array = chapter["choice"]["options"]
		check(scene._story._options.get_child_count() == chapter_options.size(),
			"boss_choice_button_count")
		var mercy_before: int = scene._mercy
		var corruption_before: int = scene.run_state.corruption
		scene._story.choose(0)
		await create_timer(1.6).timeout
		check(scene._mercy == mercy_before + 1, "boss_rewrite_choice_adds_mercy")
		check(scene.run_state.corruption == corruption_before,
			"boss_rewrite_choice_adds_no_corruption")
		check(not scene._burned_final, "boss_rewrite_choice_keeps_record")
		check(scene._chapter == 3, "chapter_4_ends_at_campaign_end")
		check(scene._finished, "chapter_4_completes_campaign")
		check(scene.ending_screen.visible, "chapter_4_end_screen_visible")
		check(scene._boss_defeated, "chapter_4_boss_recorded_defeated")
		check(scene._mds_world == mds, "chapter_4_keeps_its_world")
		check(mds.world_file == CH4_WORLD_FILE, "chapter_4_did_not_load_chapter_5")
		check(CampaignData.chapter_count() == 4, "chapter_4_is_the_last_chapter")
		check(plan_paths.size() == 4 and String(plan_paths[3]).ends_with(
			"chapter_4_demo.tres"), "chapter_4_plan_slot_still_wired_at_end")
		check(scene._cleared_in_chapter == 7, "chapter_4_clears_unchanged_at_end")
		if flow.profile != null:
			var expected_ending := CampaignData.ending_for(true,
				scene.run_state.corruption, scene._mercy, scene._burned_final)
			check(flow.last_ending.get("id", &"") == expected_ending.get("id", &""),
				"chapter_4_ending_follows_authored_rule")
			check(flow.profile.endings.has(String(expected_ending.get("id", &""))),
				"chapter_4_ending_saved_to_profile")
		# A defeated boss stays down on reload; the resume guard is
		# chapter-agnostic. The ending paused the tree, so unpause first.
		paused = false
		scene._finished = true
		scene._boss_defeated = true
		if is_instance_valid(scene._boss):
			scene._boss.queue_free()
		scene._boss = null
		await mds.load_room("ch4_boss")
		check(await _wait_room(scene, "ch4_boss"), "boss_room_reloads")
		await create_timer(0.3).timeout
		check(scene._boss == null, "boss_no_second_spawn")
		var reloaded := mds.room_node as MDSBigRoom
		if reloaded != null:
			var reloaded_arena := reloaded.get_node_or_null("Arena") as ArenaRoom
			var bosses := 0
			if reloaded_arena != null:
				for child in reloaded_arena.get_node(
						ArenaRoom.ENEMIES_NODE).get_children():
					if child is SmilingArchivist:
						bosses += 1
			check(bosses == 0, "boss_room_holds_no_boss")
		scene._finished = false
		scene._boss_defeated = false

	# --- Chapter-4 motif/enemy audit: every region's painted stage backdrop,
	# ember ambience and blood-moon boss background was checked above; all eight
	# spawn ids the chapter actually uses (the plan's six waves plus the legacy
	# first groups) carry their own painting and hit no fallback.
	check(checked_regions.size() == 9, "motif_checked_all_nine_regions")
	for room_id in plan.room_ids():
		check(checked_regions.has(String(room_id)), "motif_checked_%s" % room_id)
	var ch4_enemies: Dictionary = {}
	var chapter_waves: Array = constants.get("ROOM_WAVES", [])
	var enemy_fallback: Dictionary = constants.get("ENEMY_ART_FALLBACK", {})
	if chapter_waves.size() > 3:
		for wave in chapter_waves[3]:
			for enemy_id in wave:
				ch4_enemies[String(enemy_id)] = true
	var legacy_rooms: Array = chapter.get("rooms", [])
	for group in legacy_rooms:
		for enemy_id in group:
			ch4_enemies[String(enemy_id)] = true
	check(ch4_enemies.size() == 8, "chapter_4_uses_eight_spawn_ids")
	# Record (do not change) the authored density difference: every big-map wave
	# fields two enemies per encounter, while the legacy linear room groups field
	# three or four. The gap stays a pass-50 open question.
	var wave_sizes: Array[int] = []
	if chapter_waves.size() > 3:
		for wave in chapter_waves[3]:
			wave_sizes.append(wave.size())
	var legacy_sizes: Array[int] = []
	for group in legacy_rooms:
		legacy_sizes.append(group.size())
	print("NOTE: chapter-4 density bigmap_waves=%s legacy_groups=%s"
		% [wave_sizes, legacy_sizes])
	for enemy_key in ch4_enemies:
		var enemy_id := StringName(enemy_key)
		check(enemy_art.has(enemy_id), "chapter_4_enemy_art_%s" % enemy_key)
		check(not enemy_fallback.has(enemy_id),
			"chapter_4_enemy_no_fallback_%s" % enemy_key)
		if enemy_art.has(enemy_id):
			var texture: Texture2D = enemy_art[enemy_id]
			check(texture != null, "chapter_4_enemy_texture_%s" % enemy_key)
			if texture != null:
				check(ResourceLoader.exists(texture.resource_path),
					"chapter_4_enemy_texture_exists_%s" % enemy_key)
				check(texture.resource_path.contains("assets/sprites/enemies/"),
					"chapter_4_enemy_texture_is_enemy_art_%s" % enemy_key)
	# `mask_enemy`/`seat_husk` are the two art variants the pass-50 audit named:
	# they reuse enemy scenes/data but must not reuse another enemy's painting.
	check(enemy_art.get(&"mask_enemy") != enemy_art.get(&"hanging_scribe"),
		"chapter_4_mask_variant_has_own_art")
	check(enemy_art.get(&"seat_husk") != enemy_art.get(&"collapse_husk"),
		"chapter_4_seat_variant_has_own_art")

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
	# Cross-check the runtime histogram against the world file itself: chapter 4
	# really is 20 connected gates plus the shortcut arrival and the boss dead
	# end, with the same 5-5-5-5-2 side split.
	var world_sides: Dictionary = {}
	var world_directed := 0
	var world_arrivals: Array = []
	for room_key in mds.world.get_room_ids():
		var world_room := String(room_key)
		for gate_key in mds.world.get_gates(world_room).keys():
			var world_gate := String(gate_key)
			var world_side: String = mds.world.get_gate_side(world_room, world_gate)
			world_sides[world_side] = int(world_sides.get(world_side, 0)) + 1
			if mds.world.get_transition(world_room, world_gate).is_empty():
				world_arrivals.append("%s/%s" % [world_room, world_gate])
			else:
				world_directed += 1
	check(world_sides == side_total, "gate_visuals_side_histogram_matches_world")
	check(world_directed == 20, "gate_visuals_world_connected_gates")
	world_arrivals.sort()
	check(world_arrivals == ["ch4_boss/left1", "ch4_entry/shortcut_arrival"],
		"gate_visuals_world_arrival_gates")

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
