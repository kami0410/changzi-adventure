extends SceneTree

## Chapter 2 big-map acceptance: the real door graph, arrival rules, camera
## bounds, fall planes, vertical transit, hidden vault, bench, shortcut
## persistence, multi-content resume, and the boss aftermath resume.
##
## Since pass 76–77 the campaign hands Chapter 1 off to Chapter 2, but this
## suite still starts Chapter 2 explicitly so it can assert the big-map graph
## without replaying the whole first chapter. Since pass 80 the Chapter 2 ending
## hands off into Chapter 3 (Chapter 4 stays unreachable).

var failures: int = 0
var assertions: int = 0
var arrival: Dictionary = {}
## Gate count per region that has passed the visual checks, to prove all nine
## regions' gates (22 in total) carry a door visual and caption.
var gate_visual_regions: Dictionary = {}

const RUN_PATH := "user://test_ch2_bigmap_run.cfg"
const PROFILE_PATH := "user://test_ch2_bigmap_profile.cfg"

## Every connected gate in the nine-region graph, in one walkable path:
## [gate in the current room, room it leads to, gate it arrives at].
const WALK: Array = [
	["right1", "ch2_branch_a", "left1"],
	["left1", "ch2_entry", "right1"],
	["bot1", "ch2_branch_b", "top1"],
	["top1", "ch2_entry", "bot1"],
	["right1", "ch2_branch_a", "left1"],
	["bot1", "ch2_hub", "top1"],
	["top1", "ch2_branch_a", "bot1"],
	["bot1", "ch2_hub", "top1"],
	["left1", "ch2_branch_b", "right1"],
	["bot1", "ch2_vault", "top1"],
	["top1", "ch2_branch_b", "bot1"],
	["right1", "ch2_hub", "left1"],
	["right1", "ch2_event", "left1"],
	["left1", "ch2_hub", "right1"],
	["bot1", "ch2_well", "top1"],
	["top1", "ch2_hub", "bot1"],
	["bot1", "ch2_well", "top1"],
	["right1", "ch2_elite", "left1"],
	["left1", "ch2_well", "right1"],
	["right1", "ch2_elite", "left1"],
	["top1", "ch2_event", "bot1"],
	["left1", "ch2_hub", "right1"],
	["right1", "ch2_event", "left1"],
	["bot1", "ch2_elite", "top1"],
	["right1", "ch2_boss", "left1"],
]


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("CH2 BIGMAP FAIL: " + label)


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


func _objective_text(scene) -> String:
	var label := scene.hud.find_child("Objective", true, false) as Label
	return label.text if label != null else ""


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


## One spawned enemy's shared-path art. A wired enemy renders its own PNG at
## white; one without dedicated art keeps the Chapter 1 painting and the
## fallback tint. Pass 78 closed the Chapter 2 gap, so every wave here is wired.
func _check_enemy_art(arena: ArenaRoom, id: StringName, sprite_suffix: String,
		tint: Color) -> void:
	var found: Enemy = null
	for child in arena.get_node(ArenaRoom.ENEMIES_NODE).get_children():
		if child is Enemy and child.data != null and child.data.id == id:
			found = child
			break
	check(found != null, "ch2_enemy_present_%s" % id)
	if found == null:
		return
	check(found.sprite_visual != null, "ch2_enemy_sprite_%s" % id)
	if found.sprite_visual == null:
		return
	check(found.sprite_visual.texture != null
		and found.sprite_visual.texture.resource_path.ends_with(sprite_suffix),
		"ch2_enemy_art_%s" % id)
	check(found.sprite_visual.modulate == tint, "ch2_enemy_art_tint_%s" % id)


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


func _start_chapter_2(scene) -> bool:
	scene._finished = false
	scene._ending_pending = false
	scene.ending_screen.visible = false
	paused = false
	scene._start_chapter(1)
	await create_timer(0.3).timeout
	_close_story(scene)
	return await _wait_mds(scene)


## One room's structural/camera/fall checks, run after every real arrival.
func _check_region(scene, room_id: String) -> void:
	var mds = scene._mds_world
	var plan: ChapterPlanData = scene._chapter_plan
	var room := mds.room_node as MDSBigRoom
	check(room != null, "region_pipeline_%s" % room_id)
	if room == null:
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
	check(String(room.area_info.get("area", "")) == "Breathing Ruins",
		"region_area_%s" % room_id)
	check(not room.backdrop_tiles.is_empty(), "region_backdrop_%s" % room_id)
	if not room.backdrop_tiles.is_empty():
		# The grid is floor-anchored and mirrored above the bottom row, so the
		# painting's own floor line sits on the room floor and every seam is a
		# matched edge row rather than a sky/foreground butt joint.
		var texture: Texture2D = room.backdrop_tiles[0].texture
		var tile_height := float(texture.get_height()) * room.backdrop_tiles[0].scale.y
		var columns := 0
		for tile in room.backdrop_tiles:
			if is_equal_approx(tile.position.y, room.backdrop_tiles[0].position.y):
				columns += 1
		var bottom := room.backdrop_tiles[room.backdrop_tiles.size() - columns]
		check(not bottom.flip_v, "region_backdrop_floor_upright_%s" % room_id)
		check(is_equal_approx(bottom.position.y + tile_height * 0.5,
			room.room_bounds.end.y), "region_backdrop_floor_anchored_%s" % room_id)
		var mirrored := true
		for index in range(room.backdrop_tiles.size() - columns):
			if room.backdrop_tiles[index].flip_v \
					== room.backdrop_tiles[index + columns].flip_v:
				mirrored = false
		check(mirrored, "region_backdrop_rows_mirrored_%s" % room_id)
	check(String(room.area_info.get("weather", "")).contains("fog"),
		"region_weather_%s" % room_id)
	_check_gate_visuals(mds, room_id)


## Every world gate in the region has a visible GateVisual in ChapterDoor's
## language: side matches the world file, caption says where it leads (or
## "来路" for the arrival-only gates), and the visual adds no collision.
func _check_gate_visuals(mds, room_id: String) -> void:
	var gate_names: Array = mds.world.get_gates(room_id).keys()
	var visual_gates := 0
	for key in gate_names:
		var gate_name := String(key)
		var gate := MDSGate.find_gate(mds.room_node, gate_name)
		check(gate != null, "region_gate_%s_%s" % [room_id, gate_name])
		if gate == null:
			continue
		var marker := gate.get_node_or_null(MDSBigRoom.GATE_VISUAL_NAME) as GateVisual
		check(marker != null, "region_gate_visual_%s_%s" % [room_id, gate_name])
		if marker == null:
			continue
		visual_gates += 1
		check(marker.visible and marker.is_visible_in_tree(),
			"region_gate_visual_visible_%s_%s" % [room_id, gate_name])
		check(marker.side == mds.world.get_gate_side(room_id, gate_name),
			"region_gate_visual_side_%s_%s" % [room_id, gate_name])
		check(marker.caption_label() != null and not marker.caption_text().is_empty(),
			"region_gate_visual_caption_%s_%s" % [room_id, gate_name])
		var transition: Dictionary = mds.world.get_transition(room_id, gate_name)
		if transition.is_empty():
			check(marker.arrival,
				"region_gate_visual_arrival_%s_%s" % [room_id, gate_name])
			check(marker.caption_text() == GateVisual.CAPTION_ARRIVAL,
				"region_gate_visual_arrival_copy_%s_%s" % [room_id, gate_name])
		else:
			check(not marker.arrival,
				"region_gate_visual_target_%s_%s" % [room_id, gate_name])
			var to_room := String(transition.get("room", ""))
			var to_name := str(mds.world.get_room_value(to_room, "name", to_room))
			check(marker.caption_text() == GateVisual.CAPTION_ARROW + to_name,
				"region_gate_visual_target_copy_%s_%s" % [room_id, gate_name])
		# The presentation half must never add a second trigger or collide.
		check(marker.find_children("*", "CollisionObject2D", true, false).is_empty(),
			"region_gate_visual_no_collision_%s_%s" % [room_id, gate_name])
		check(marker.get_class() == "Node2D",
			"region_gate_visual_not_body_%s_%s" % [room_id, gate_name])
	check(visual_gates == gate_names.size(), "region_gate_visual_count_%s" % room_id)
	gate_visual_regions[room_id] = gate_names.size()


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
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.4).timeout
	_close_story(scene)
	check(await _wait_mds(scene), "boots_chapter_1")
	check(await _start_chapter_2(scene), "chapter_2_starts")
	var mds = scene._mds_world
	mds.room_loaded.connect(_on_room_loaded_capture)
	var plan: ChapterPlanData = scene._chapter_plan
	check(plan != null and plan.big_map, "chapter_2_plan_is_big_map")
	if plan == null or not plan.big_map:
		_finish(scene)
		return

	# --- Plan graph: entry reaches every region, doors are mirrored unless
	# explicitly one-way, and the only requirement is the shortcut ability.
	check(scene._chapter == 1, "running_chapter_2")
	check(mds.current_room == "ch2_entry", "chapter_2_starts_at_entry")
	check(mds.current_room == plan.start_region(), "chapter_2_start_from_plan")
	check(scene._chapter_clear_target() == 7, "chapter_2_clear_target_seven")
	check(scene._chapter_progress_total() == 8, "chapter_2_progress_total_includes_boss")
	check(is_equal_approx(scene._fall_limit_local, 1680.0), "chapter_2_entry_fall_plane")
	check(not scene._story.is_open() and not paused, "chapter_2_intro_closed")
	# `ch2_entry` has no combat and no rest facilities (shop/bench), so it must
	# not borrow the shop/bench arrival copy; the objective only points onward.
	check(_objective_text(scene) == "继续前进", "chapter_2_hud_entry_objective")
	check(not scene._rest_greeted.has("ch2_entry"), "chapter_2_entry_no_rest_copy")

	# --- Fresh-run spawn: `ch2_entry` authors a save_point marker on its first
	# step. MDS prefers it over the room-label anchor (the centre of the
	# largest rect, which for a 2560x1440 region is mid-air), so the player
	# stands on the step from the first frame instead of falling into place.
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
		check(mds._spawn_position("ch2_entry", "", Vector2.INF)
			.distance_to(spawn.global_position) < 1.0, "entry_spawn_precedes_label")
		var label_pos: Vector2 = mds.world.get_room_label_pos("ch2_entry")
		check(spawn.global_position.y > label_pos.y + 400.0,
			"entry_spawn_not_room_label_anchor")
		var settled: Vector2 = scene.player.global_position
		await physics_frame
		check(scene.player.is_on_floor(), "entry_spawn_on_floor")
		await create_timer(0.3).timeout
		check(scene.player.global_position.distance_to(settled) < 1.0,
			"entry_spawn_no_air_fall")

	var reachable := _bfs_rooms(plan)
	check(reachable.size() == plan.room_ids().size(), "chapter_2_all_regions_reachable")
	for room_id in plan.room_ids():
		check(reachable.has(String(room_id)), "chapter_2_reachable_%s" % room_id)
	check(reachable.has("ch2_hub"), "chapter_2_rest_reachable")
	check(reachable.has("ch2_vault"), "chapter_2_vault_reachable")
	check(reachable.has("ch2_boss"), "chapter_2_boss_reachable")
	var one_way := 0
	for door in plan.doors:
		var door_id := String(door.get("id", ""))
		check(not String(door.get("from", "")).is_empty(), "door_from_%s" % door_id)
		check(not String(door.get("to", "")).is_empty(), "door_to_%s" % door_id)
		if bool(door.get("one_way", false)):
			one_way += 1
			continue
		# The plan lists each connection once; the world must carry the
		# mirrored gate so the player can come back.
		var reverse: Dictionary = mds.world.get_transition(
			String(door.get("to", "")), String(door.get("to_gate", "")))
		check(String(reverse.get("room", "")) == String(door.get("from", "")),
			"door_two_way_room_%s" % door_id)
		check(String(reverse.get("gate", "")) == String(door.get("from_gate", "")),
			"door_two_way_gate_%s" % door_id)
	check(one_way == 2, "chapter_2_two_one_way_doors")
	var shortcut_doors := 0
	for door in plan.doors:
		var requires: Array = door.get("requires", [])
		if requires.is_empty():
			continue
		shortcut_doors += 1
		check(String(door.get("from", "")) == "ch2_hub", "shortcut_from_hub")
		check(String(door.get("from_gate", "")) == "shortcut", "shortcut_gate_name")
		check(requires.size() == 1 and String(requires[0]) == "ch2_shortcut",
			"shortcut_requires_ability")
	check(shortcut_doors == 1, "chapter_2_single_required_door")
	_check_region(scene, "ch2_entry")

	# --- Hidden vault: first discovery, map reveal, and per-node one-shot
	# content (two chests + two steles) that survives a room reload.
	var map_view = scene._map_overlay.map_view
	map_view.reveal_all = false
	check(map_view.is_room_revealed("ch2_entry"), "map_reveals_entry")
	check(not map_view.is_room_revealed("ch2_vault"), "map_hides_vault")
	await mds.load_room("ch2_vault")
	check(await _wait_room(scene, "ch2_vault"), "vault_loads")
	await process_frame
	var vault_line := VaultRoomData.pick(scene.run_state.run_seed, "ch2_vault")
	check(scene._discovered_vaults.has("ch2_vault"), "vault_first_discovery_recorded")
	check(scene.hud.get_message_text() == vault_line, "vault_first_discovery_copy")
	check(map_view.is_room_revealed("ch2_vault"), "vault_first_discovery_reveals_map")
	_check_region(scene, "ch2_vault")
	check(scene._chests.size() == 2, "vault_two_chests")
	check(scene._steles.size() == 2, "vault_two_steles")
	var chest1 := mds.room_node.get_node_or_null("Chest1") as TreasureChest
	var chest2 := mds.room_node.get_node_or_null("Chest2") as TreasureChest
	var stele1 := mds.room_node.get_node_or_null("Stele1") as MemoryStele
	var stele2 := mds.room_node.get_node_or_null("Stele2") as MemoryStele
	check(chest1 != null and chest2 != null, "vault_named_chests")
	check(stele1 != null and stele2 != null, "vault_named_steles")
	if chest1 != null:
		scene._open_chest(chest1)
		await process_frame
	check(scene._opened_chests.has("ch2_vault/Chest1"), "vault_chest1_one_shot")
	check(not scene._opened_chests.has("ch2_vault/Chest2"), "vault_chest2_not_opened")
	if stele1 != null:
		scene.player.global_position = stele1.global_position
		scene.player.velocity = Vector2.ZERO
		await physics_frame
		scene._claim_nearest_stele()
		await process_frame
	check(scene._claimed_steles.has("ch2_vault/Stele1"), "vault_stele1_one_shot")
	check(not scene._claimed_steles.has("ch2_vault/Stele2"), "vault_stele2_not_claimed")
	var after_claim_message: String = scene.hud.get_message_text()
	await mds.load_room("ch2_vault")
	check(await _wait_room(scene, "ch2_vault"), "vault_reloads")
	await process_frame
	var kept1 := mds.room_node.get_node_or_null("Chest1") as TreasureChest
	var kept2 := mds.room_node.get_node_or_null("Chest2") as TreasureChest
	check(kept1 != null and kept1.is_open, "vault_chest1_stays_open")
	check(kept2 != null and not kept2.is_open, "vault_chest2_stays_closed")
	check(scene._steles.size() == 1, "vault_claimed_stele_removed")
	if scene._steles.size() == 1:
		check(String(scene._steles[0].get_meta(&"content_id", "")) == "ch2_vault/Stele2",
			"vault_remaining_stele")
	check(scene._discovered_vaults.has("ch2_vault"), "vault_discovery_survives_reload")
	check(scene.hud.get_message_text() == after_claim_message,
		"vault_reload_does_not_repeat_discovery")
	check(not scene._reward_ui.visible, "vault_no_false_reward")

	# --- Pass 78 art: branch_b is the one real Chapter 2 wave that spawns the
	# lung moth and the breath hound. Both now paint their own PNG at white.
	# Check it before the lift section marks every encounter cleared.
	await mds.load_room("ch2_branch_b")
	check(await _wait_room(scene, "ch2_branch_b"), "art_room_loads")
	await process_frame
	var art_arena := mds.room_node.get_node_or_null("Arena") as ArenaRoom
	check(art_arena != null, "art_arena_present")
	if art_arena != null:
		_check_enemy_art(art_arena, &"lung_moth",
			"assets/sprites/enemies/lung_moth.png", Color.WHITE)
		_check_enemy_art(art_arena, &"breath_hound",
			"assets/sprites/enemies/breath_hound.png", Color.WHITE)

	# --- Vertical transit: the authored lift really reaches the top gate, the
	# jump triggers it, the arrival launches up, and the floor gate does not
	# bounce the player straight back down (the acceptance defect).
	for encounter_id in plan.encounter_ids():
		scene._cleared_encounters[String(encounter_id)] = true
	scene._cleared_in_chapter = plan.clear_target()
	await mds.load_room("ch2_branch_b")
	check(await _wait_room(scene, "ch2_branch_b"), "lift_room_loads")
	await process_frame
	var lift := mds.room_node.get_node_or_null("Lift") as MovingPlatform
	check(lift != null, "branch_b_lift_present")
	if lift != null:
		check(is_equal_approx(lift.speed, 70.0), "branch_b_lift_authored_speed")
		check(not lift.travel_clamped, "branch_b_lift_travel_fits_room")
		check(mds.room_node.room_bounds.encloses(lift.platform_rect()),
			"branch_b_lift_inside_room")
		scene.player.global_position = lift.global_position \
			+ Vector2(80, -16 - Player.FOOT_Y)
		scene.player.velocity = Vector2.ZERO
		# The authored 70 px/s ride takes ~19 s; the test only needs the same
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
			if mds.changing_room or mds.current_room != "ch2_branch_b":
				triggered = true
				break
		check(triggered, "branch_b_top_gate_triggers_on_jump")
		check(await _wait_room(scene, "ch2_entry"), "branch_b_top_gate_arrives_entry")
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
		# ignore that return, or the lift ride would bounce them to branch_b.
		await create_timer(2.0).timeout
		check(mds.current_room == "ch2_entry", "bot_arrival_does_not_bounce_back")
		check(not mds.changing_room, "bot_arrival_settles")
		check(not paused, "bot_arrival_not_paused")
		await process_frame
		_check_region(scene, "ch2_entry")

	# --- The whole connected graph, one gate at a time. Every arrival gets the
	# exact spawn point, exit-velocity rule, camera bounds and a modal-free HUD.
	for step in WALK:
		if mds.current_room == "ch2_entry" and arrival.is_empty():
			await mds.load_room("ch2_entry")
			check(await _wait_room(scene, "ch2_entry"), "walk_reloads_entry")
		var ok := await _use_gate(scene, String(step[0]), String(step[1]), String(step[2]))
		if not ok:
			break
	check(mds.current_room == "ch2_boss", "walk_reaches_boss")
	var boss_gate := MDSGate.find_gate(mds.room_node, "left1")
	check(boss_gate != null, "boss_left_gate_present")
	if boss_gate != null:
		check(boss_gate.get_transition().is_empty(), "boss_door_is_one_way")
		boss_gate.use()
		await create_timer(0.4).timeout
		check(mds.current_room == "ch2_boss", "boss_dead_end_holds")
		check(not mds.changing_room, "boss_dead_end_not_changing")

	# --- Lower layer: falling into the well's lower half is normal traversal,
	# not a fall death. The one-way platforms also drop through on down+jump.
	await mds.load_room("ch2_well")
	check(await _wait_room(scene, "ch2_well"), "well_loads")
	await process_frame
	_check_region(scene, "ch2_well")
	var well_origin: Vector2 = mds.world.get_origin("ch2_well")
	var well_lift := mds.room_node.get_node_or_null("Lift") as MovingPlatform
	check(well_lift != null, "well_lift_present")
	if well_lift != null:
		check(not well_lift.travel_clamped, "well_lift_travel_fits_room")
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
	await mds.load_room("ch2_hub")
	check(await _wait_room(scene, "ch2_hub"), "bench_room_loads")
	await process_frame
	_check_region(scene, "ch2_hub")
	# Hubs author a Shop and a Bench, so they keep the rest branch that the
	# entry regions (same pipeline, no facilities) no longer take.
	check(scene._rest_greeted.has("ch2_hub"), "chapter_2_hub_keeps_rest_copy")
	check(_objective_text(scene) == "休整，或继续前进", "chapter_2_hub_rest_objective")
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
		check(scene.hud.get_message_text() == BenchCheckpoint.MESSAGE,
			"bench_message")
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

	# --- Shortcut: the barrier starts closed, the ability opens it, the door is
	# one-way into the entry, and its arrival gate is inert.
	var barrier := mds.room_node.get_node_or_null("Barrier_shortcut") as MDSGateBarrier
	check(barrier != null, "hub_shortcut_barrier")
	if barrier != null:
		# 0.13: reaching the hub opens the shortcut (no longer status #16).
		check(barrier.is_open and mds.has_ability("ch2_shortcut"), "hub_shortcut_opens_on_arrival")
		mds.grant_ability("ch2_shortcut")
		await process_frame
		check(barrier.is_open, "hub_shortcut_opens_with_ability")
		check(mds.get_save_data().get("stored", []).has(mds.object_id(barrier)),
			"hub_shortcut_state_stored")
	var shortcut_gate := MDSGate.find_gate(mds.room_node, "shortcut")
	check(shortcut_gate != null, "hub_shortcut_gate")
	if shortcut_gate != null:
		check(shortcut_gate.mode == MDSGate.Mode.INTERACT, "hub_shortcut_is_door")
		check(String(shortcut_gate.get_transition().get("room", "")) == "ch2_entry",
			"hub_shortcut_targets_entry")
		check(String(shortcut_gate.get_transition().get("gate", "")) == "shortcut_arrival",
			"hub_shortcut_arrival_gate")
		var shortcut_ok := await _use_gate(scene, "shortcut", "ch2_entry",
			"shortcut_arrival")
		check(shortcut_ok, "hub_shortcut_traverses")
		if shortcut_ok:
			var shortcut_arrival := MDSGate.find_gate(mds.room_node, "shortcut_arrival")
			check(shortcut_arrival != null, "entry_shortcut_arrival_present")
			if shortcut_arrival != null:
				check(shortcut_arrival.get_transition().is_empty(),
					"entry_shortcut_arrival_dead_end")
				shortcut_arrival.use()
				await create_timer(0.3).timeout
				check(mds.current_room == "ch2_entry", "entry_shortcut_arrival_inert")
				check(not mds.changing_room, "entry_shortcut_arrival_no_transition")

	# --- Two encounters in one region: each locks and clears on its own node
	# id, its real door bodies block/release, and a reload keeps both cleared.
	scene._cleared_encounters.clear()
	scene._legacy_cleared_rooms.clear()
	scene._cleared_in_chapter = 0
	await mds.load_room("ch2_branch_a")
	check(await _wait_room(scene, "ch2_branch_a"), "combat_room_loads")
	await process_frame
	_check_region(scene, "ch2_branch_a")
	var arena_a := mds.room_node.get_node_or_null("Arena") as ArenaRoom
	var arena_b := mds.room_node.get_node_or_null("Arena2") as ArenaRoom
	check(arena_a != null and arena_b != null, "branch_a_two_arenas")
	check(scene._rooms.size() == 2, "branch_a_two_registered_arenas")
	var ground := _ground_surface_y(mds.room_node)
	if arena_a != null:
		check(arena_a.enemy_count() == 2, "arena_a_first_wave")
		var choir: Enemy = null
		for enemy in arena_a.get_node(ArenaRoom.ENEMIES_NODE).get_children():
			if enemy is Node2D:
				check((enemy as Node2D).global_position.y < ground,
					"arena_a_enemy_above_ground")
			if enemy is Enemy and enemy.data != null and enemy.data.id == &"choir_summoner":
				choir = enemy
		# Chapter 2's choir summoner owns a dedicated sprite, so the shared
		# spawn path must use it and must not apply the Chapter 1 fallback tint.
		check(choir != null, "arena_a_spawns_choir_summoner")
		if choir != null:
			check(choir.sprite_visual != null, "choir_summoner_has_sprite")
			if choir.sprite_visual != null:
				check(choir.sprite_visual.texture.resource_path.ends_with(
					"assets/sprites/enemies/choir_summoner.png"),
					"choir_summoner_uses_dedicated_art")
				check(choir.sprite_visual.modulate == Color.WHITE,
					"choir_summoner_no_fallback_tint")
	if arena_a != null and arena_b != null:
		scene.player._invulnerable_left = 100
		scene.player.global_position = arena_a.global_position + Vector2(0, -120)
		await process_frame
		await process_frame
		check(arena_a.is_locked(), "arena_a_locks")
		check(not arena_b.is_locked(), "arena_b_stays_open")
		check(_arena_doors_locked(arena_a), "arena_a_doors_block")
		var objective_label := scene.hud.find_child("Objective", true, false) as Label
		check(objective_label != null
			and objective_label.text.contains("肃清此房间"),
			"arena_a_objective")
		check(await _kill_arena(arena_a), "arena_a_clears")
		check(_arena_doors_open(arena_a), "arena_a_doors_release")
		check(await _wait_reward(scene), "arena_a_reward_opens")
		check(scene._cleared_encounters.has("ch2_branch_a/Arena"),
			"arena_a_settles_own_id")
		check(not scene._cleared_encounters.has("ch2_branch_a/Arena2"),
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
		# Pass 78 closed the Chapter 2 art gap: both enemies in this wave paint
		# their own PNG at white instead of the tinted Chapter 1 fallback.
		_check_enemy_art(arena_b, &"rust_whisperer",
			"assets/sprites/enemies/rust_whisperer.png", Color.WHITE)
		_check_enemy_art(arena_b, &"collapse_husk",
			"assets/sprites/enemies/collapse_husk.png", Color.WHITE)
		check(await _kill_arena(arena_b), "arena_b_clears")
		check(_arena_doors_open(arena_b), "arena_b_doors_release")
		check(await _wait_reward(scene), "arena_b_reward_opens")
		check(scene._cleared_encounters.has("ch2_branch_a/Arena2"),
			"arena_b_settles_own_id")
		check(scene._cleared_in_chapter == 2, "arena_b_counts_once")
		scene._reward_ui._choose(0)
		await process_frame
		var settled: int = scene._cleared_in_chapter
		arena_b.cleared.emit()
		await process_frame
		check(scene._cleared_in_chapter == settled, "cleared_arena_reemit_ignored")
	await mds.load_room("ch2_branch_a")
	check(await _wait_room(scene, "ch2_branch_a"), "combat_room_reloads")
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
	check(scene._cleared_in_chapter == 7, "chapter_2_seven_clears")
	check(scene._cleared_in_chapter == plan.clear_target(), "chapter_2_clears_match_plan")
	check(scene._chapter_progress_total() == 8, "chapter_2_progress_keeps_boss_slot")
	check(scene._cleared_encounters.size() == 7, "chapter_2_seven_encounter_ids")

	# --- Boss region: unique scene, anchored spawn, arena doors inside the
	# room and clear of the entrance, entrance/phase copy, and no ordinary wave.
	await mds.load_room("ch2_boss")
	check(await _wait_room(scene, "ch2_boss"), "boss_room_loads")
	await process_frame
	_check_region(scene, "ch2_boss")
	check(is_instance_valid(scene._boss), "boss_spawns_in_region")
	check(scene._boss is LungBellGuardian, "boss_uses_lung_guardian")
	check(scene._mds_boss_arena != null, "boss_arena_registered")
	check(plan.wave_for("ch2_boss", "ch2_boss/Arena").is_empty(),
		"boss_region_has_no_ordinary_wave")
	var boss_bounds: Rect2 = mds.world.get_room_bounds("ch2_boss")
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
		if is_instance_valid(scene._boss):
			check(scene._boss.global_position.y < _ground_surface_y(mds.room_node),
				"boss_spawns_above_ground")
		scene.player._invulnerable_left = 100
		scene.player.global_position = boss_arena.global_position
		await process_frame
		await process_frame
		check(boss_arena.is_locked(), "boss_arena_locks")
		check(_arena_doors_locked(boss_arena), "boss_doors_block")
		var entrance_line := BossEntranceData.pick(scene.run_state.run_seed, 1)
		check(BossEntranceData.variants(1).has(entrance_line),
			"boss_entrance_uses_chapter_2_copy")
		check(scene.hud.get_message_text() == entrance_line,
			"boss_entrance_matches_seed")
		var chapter := CampaignData.chapter(1)
		var phase_line := BossPhaseData.pick(scene.run_state.run_seed, 2, 1)
		check(BossPhaseData.variants(2, 1).has(phase_line),
			"boss_phase_uses_chapter_2_copy")
		scene._on_boss_phase(chapter, 2)
		check(scene.hud.get_message_text()
			== "%s · 第 2 阶段：%s" % [chapter["boss_name"], phase_line],
			"boss_phase_matches_seed")

	# --- Raw construction timing baseline. Fade is off so the number is the
	# room build, not the 0.22 s transition. Logged for the status file.
	var old_fade: float = mds.fade_time
	mds.fade_time = 0.0
	for room_id in plan.room_ids():
		var started := Time.get_ticks_usec()
		await mds.load_room(String(room_id))
		var loaded_timing := await _wait_room(scene, String(room_id))
		var elapsed := (Time.get_ticks_usec() - started) / 1000.0
		check(loaded_timing, "timing_load_%s" % room_id)
		print("PERF: load %s = %.2f ms" % [room_id, elapsed])
	mds.fade_time = old_fade

	# --- Save inside the hidden vault with multi-content, shortcut and clear
	# progress; resume must land in the same room with the same one-shot state.
	flow.auto_save = true
	await mds.load_room("ch2_vault")
	check(await _wait_room(scene, "ch2_vault"), "save_room_loads")
	await process_frame
	var vault_origin: Vector2 = mds.world.get_origin("ch2_vault")
	scene.player.global_position = vault_origin + Vector2(1200, 1408)
	scene.player.velocity = Vector2.ZERO
	await physics_frame
	var saved_position: Vector2 = scene.player.global_position
	check(scene.save_run_now(), "ch2_run_save_writes")
	var saved := RunSave.read(RUN_PATH)
	var saved_run: Dictionary = saved.get("run", {})
	var saved_progress: Dictionary = saved.get("progress", {})
	var saved_world: Dictionary = saved.get("world", {})
	var saved_mds: Dictionary = saved.get("mds", {})
	check(int(saved_run.get("chapter", -1)) == 1, "ch2_save_chapter")
	check(String(saved_run.get("room", "")) == "ch2_vault", "ch2_save_room")
	check(int(saved_progress.get("cleared_in_chapter", 0)) == 7, "ch2_save_clear_count")
	check((saved_progress.get("cleared_encounters", []) as Array).size() == 7,
		"ch2_save_encounter_ids")
	check((saved_progress.get("vaults", []) as Array).has("ch2_vault"),
		"ch2_save_vault_discovery")
	check((saved_world.get("claimed_stele_ids", []) as Array).has("ch2_vault/Stele1"),
		"ch2_save_stele_id")
	check((saved_world.get("opened_chest_ids", []) as Array).has("ch2_vault/Chest1"),
		"ch2_save_chest_id")
	check((saved_world.get("opened_chest_ids", []) as Array).size() == 1,
		"ch2_save_only_opened_chest")
	check((saved_mds.get("abilities", []) as Array).has("ch2_shortcut"),
		"ch2_save_shortcut_ability")
	check(String(saved_mds.get("room", "")) == "ch2_vault", "ch2_save_mds_room")
	check((saved_mds.get("visited", []) as Array).has("ch2_boss"),
		"ch2_save_mds_visits")
	await _free_scene(scene)

	flow.resume_requested = true
	var resumed = load("res://scenes/main.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	await create_timer(0.4).timeout
	_close_story(resumed)
	check(await _wait_mds(resumed), "ch2_resume_boots")
	check(resumed._chapter == 1, "ch2_resume_chapter")
	check(resumed._mds_world.current_room == "ch2_vault", "ch2_resume_room")
	check(not resumed._story.is_open(), "ch2_resume_skips_intro")
	check(resumed.player.global_position.distance_to(saved_position) < 8.0,
		"ch2_resume_exact_position")
	check(resumed._cleared_in_chapter == 7, "ch2_resume_clear_count")
	check(resumed._cleared_encounters.size() == 7, "ch2_resume_encounter_ids")
	check(resumed._opened_chests.has("ch2_vault/Chest1"), "ch2_resume_chest1")
	check(not resumed._opened_chests.has("ch2_vault/Chest2"), "ch2_resume_chest2_closed")
	check(resumed._claimed_steles.has("ch2_vault/Stele1"), "ch2_resume_stele1")
	check(not resumed._claimed_steles.has("ch2_vault/Stele2"), "ch2_resume_stele2_present")
	check(resumed._discovered_vaults.has("ch2_vault"), "ch2_resume_vault_discovery")
	check(resumed._mds_world.has_ability("ch2_shortcut"), "ch2_resume_shortcut_ability")
	check(resumed._map_overlay.map_view.is_room_revealed("ch2_vault"),
		"ch2_resume_map_reveal")
	var resume_chest1 := resumed._mds_world.room_node.get_node_or_null("Chest1") as TreasureChest
	var resume_chest2 := resumed._mds_world.room_node.get_node_or_null("Chest2") as TreasureChest
	check(resume_chest1 != null and resume_chest1.is_open, "ch2_resume_chest1_visual")
	check(resume_chest2 != null and not resume_chest2.is_open, "ch2_resume_chest2_visual")
	check(resumed._steles.size() == 1, "ch2_resume_one_stele_left")
	if resumed._steles.size() == 1:
		check(String(resumed._steles[0].get_meta(&"content_id", ""))
			== "ch2_vault/Stele2", "ch2_resume_remaining_stele")
	_check_region(resumed, "ch2_vault")
	await resumed._mds_world.load_room("ch2_hub")
	check(await _wait_room(resumed, "ch2_hub"), "ch2_resume_hub_loads")
	await process_frame
	var resumed_barrier := resumed._mds_world.room_node.get_node_or_null(
		"Barrier_shortcut") as MDSGateBarrier
	check(resumed_barrier != null and resumed_barrier.is_open,
		"ch2_resume_shortcut_barrier_open")

	# --- Boss defeat checkpoint: quit before the authority pick; resuming must
	# not spawn a second boss, must finish the authority/outro, and (since pass
	# 80) hands off into the Chapter 3 intro at the Chapter 2 boundary.
	await resumed._mds_world.load_room("ch2_boss")
	check(await _wait_room(resumed, "ch2_boss"), "ch2_resume_boss_loads")
	await process_frame
	check(is_instance_valid(resumed._boss), "ch2_resume_boss_spawns")
	check(resumed._mds_boss_arena != null, "ch2_resume_boss_arena")
	if not is_instance_valid(resumed._boss) or resumed._mds_boss_arena == null:
		_finish(resumed)
		return
	resumed.player._invulnerable_left = 100
	resumed.player.global_position = resumed._mds_boss_arena.global_position
	await process_frame
	await process_frame
	check(resumed._mds_boss_arena.is_locked(), "ch2_resume_boss_locks")
	resumed._boss.take_damage(100000)
	await process_frame
	check(resumed._boss_defeated, "ch2_boss_defeat_recorded")
	check(resumed.save_run_now(), "ch2_boss_defeat_save_writes")
	var defeat_save := RunSave.read(RUN_PATH)
	check(bool(defeat_save.get("world", {}).get("boss_defeated", false)),
		"ch2_boss_defeat_in_save")
	check(String(defeat_save.get("run", {}).get("room", "")) == "ch2_boss",
		"ch2_boss_defeat_save_room")
	check(int(defeat_save.get("run", {}).get("chapter", -1)) == 1,
		"ch2_boss_defeat_save_chapter")
	check((defeat_save.get("authority", {}) as Dictionary).is_empty(),
		"ch2_boss_defeat_save_before_authority")
	await _free_scene(resumed)

	flow.resume_requested = true
	var aftermath = load("res://scenes/main.tscn").instantiate()
	root.add_child(aftermath)
	current_scene = aftermath
	await create_timer(0.4).timeout
	_close_story(aftermath)
	check(await _wait_mds(aftermath), "ch2_aftermath_boots")
	check(aftermath._chapter == 1, "ch2_aftermath_chapter")
	check(aftermath._mds_world.current_room == "ch2_boss", "ch2_aftermath_room")
	check(aftermath._boss_defeated, "ch2_aftermath_defeat_restored")
	check(not is_instance_valid(aftermath._boss), "ch2_aftermath_no_second_boss")
	check(aftermath._mds_boss_arena != null, "ch2_aftermath_arena_registered")
	check(await _wait_authority_choice(aftermath), "ch2_aftermath_authority_opens")
	var expected_pool := AuthorityController.build_pool(
		aftermath._chapter_plan.authority_pool, aftermath.run_state,
		flow.profile, aftermath._records)
	var pool_ids: Array[StringName] = []
	for authority in expected_pool:
		pool_ids.append(authority.id)
	check(aftermath._authority_choice.get_button_count() == expected_pool.size(),
		"ch2_aftermath_pool_size")
	check(pool_ids.has(&"revive"), "ch2_aftermath_offers_revive")
	check(pool_ids.has(&"rewrite"), "ch2_aftermath_offers_rewrite")
	aftermath._authority_choice._choose(0)
	await create_timer(0.4).timeout
	check(aftermath.run_state.authority != null, "ch2_aftermath_authority_applied")
	check(await _wait_story(aftermath), "ch2_aftermath_outro")
	aftermath._story.close()
	await process_frame
	check(aftermath._story.is_open(), "ch2_aftermath_choice")
	aftermath._story.choose(0)
	await create_timer(1.6).timeout
	# Pass 80: the Chapter 2 ending now hands off into Chapter 3 instead of
	# stopping; the Chapter 3 intro replaces the ending screen.
	check(aftermath._chapter == 2, "ch2_aftermath_enters_chapter_3")
	check(not aftermath._finished, "ch2_aftermath_does_not_finish")
	check(not aftermath.ending_screen.visible, "ch2_aftermath_no_end_screen")
	check(aftermath._story.is_open() and not aftermath._story._choice_mode,
		"ch2_aftermath_opens_chapter_3_intro")

	# --- Gate visuals covered every region the graph has, and every gate in
	# them (20 connected + 2 arrival) carries a visible doorway and caption.
	check(gate_visual_regions.size() == 9, "gate_visuals_all_regions")
	var visual_total := 0
	for value in gate_visual_regions.values():
		visual_total += int(value)
	check(visual_total == 22, "gate_visuals_all_gates")

	_finish(aftermath)


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
