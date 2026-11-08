extends SceneTree

## Representative 1280x720 frames of the Chapter 2–4 big-map worlds, for the
## user's sample-image request: entrance panorama, vertical region and boss
## fight per chapter. Rendering needs a real display (headless uses the dummy
## renderer), so run it under xvfb:
##   xvfb-run -a godot --path . --resolution 1280x720 --rendering-driver opengl3 \
##     --audio-driver Dummy -s tests/capture_bigmap_chapters.gd -- \
##     --out-dir=res://artifacts/screens
##
## Chapters 2–4 are routed into the campaign since passes 80/91, but this
## harness still mounts the authored chapter plan and big-map world on the live
## main scene so a single run can frame all three chapters from their entrance.
## It never touches `CHAPTER_PLAN_PATHS`, the chapter routing or any gameplay
## value; it only positions the player and resets the camera for framing.
## Screenshots stay out of git (`artifacts/`).

var _dir := "res://artifacts/screens"

## One entry per chapter, in campaign order. `index` is the 0-based chapter the
## mounted plan belongs to, matching `_chapter` in game.gd.
const CHAPTERS: Array = [
	{
		"index": 1,
		"prefix": "ch2",
		"folder": "ch2",
		"plan": "res://resources/chapters/chapter_2_demo.tres",
		"world": "res://scenes/mds/chapter_2_bigmap_world.tscn",
		"world_file": "res://scenes/mds/chapter_2_bigmap.mdsworld.json",
		"entry_shot": "ch2_entry_panorama",
		"vertical_room": "ch2_well",
		"vertical_shot": "ch2_well_shaft",
		"boss_shot": "ch2_boss_lung_bell",
	},
	{
		"index": 2,
		"prefix": "ch3",
		"folder": "ch3",
		"plan": "res://resources/chapters/chapter_3_demo.tres",
		"world": "res://scenes/mds/chapter_3_bigmap_world.tscn",
		"world_file": "res://scenes/mds/chapter_3_bigmap.mdsworld.json",
		"entry_shot": "ch3_entry_panorama",
		"vertical_room": "ch3_well",
		"vertical_shot": "ch3_well_shaft",
		"boss_shot": "ch3_boss_last_reader",
	},
	{
		"index": 3,
		"prefix": "ch4",
		"folder": "ch4",
		"plan": "res://resources/chapters/chapter_4_demo.tres",
		"world": "res://scenes/mds/chapter_4_bigmap_world.tscn",
		"world_file": "res://scenes/mds/chapter_4_bigmap.mdsworld.json",
		"entry_shot": "ch4_entry_theater",
		"vertical_room": "ch4_well",
		"vertical_shot": "ch4_well_backstage",
		"boss_shot": "ch4_boss_smiling_archivist",
	},
]

## Where the player stands in each shot, in room-local px (feet on the authored
## surface: platform/boss positions minus Player.FOOT_Y). Entry rooms share the
## same 2560x1440 staircase, so one position fits all three.
const ENTRY_STAND := Vector2(1100, 1168)      # platform at (960, 1184) w=320
const WELL_STAND := Vector2(480, 1184)        # OneWay3 at (320, 1200) w=320
const BOSS_STAND := Vector2(2420, 2048)       # platform at (2400, 2064) w=400


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			_dir = argument.trim_prefix("--out-dir=")
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.title_shown_this_session = true
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.7).timeout
	_close_story(scene)
	if not await _wait_chapter_one(scene):
		push_error("chapter 1 never loaded; cannot mount the big-map chapters")
		quit(1)
		return
	for chapter in CHAPTERS:
		if not await _capture_chapter(scene, chapter):
			push_error("chapter %s capture aborted" % chapter["prefix"])
	quit()


## Boots the live scene into one authored chapter plan/world, the same hook the
## chapter 2/3/4 acceptance suites use for reachability-free checks.
func _mount_chapter(scene, chapter: Dictionary) -> bool:
	var plan := load(String(chapter["plan"])) as ChapterPlanData
	if plan == null or not plan.big_map:
		return false
	scene._teardown_mds(false)
	scene._chapter = int(chapter["index"])
	scene._chapter_plan = plan
	scene._mds_active = true
	scene._event_room_id = ""
	scene._ending_pending = false
	scene._finished = false
	paused = false
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
	scene._map_overlay.set_chapter(int(chapter["index"]))
	scene._map_overlay.set_world(String(chapter["world_file"]))
	var data := CampaignData.chapter(int(chapter["index"]))
	var running := root.get_node_or_null("Flow") as GameFlow
	var difficulty: int = running.difficulty if running != null else 0
	scene.hud.set_region("%s · %s" % [data["region"], Difficulty.display_name(difficulty)])
	scene.hud.set_progress(0, scene._chapter_progress_total())
	scene.hud.set_objective(String(data["objective"]))
	# The live scene was just showing Chapter 1's objective toast; clear it so a
	# sample frame shows the settled room HUD instead of another chapter's copy.
	scene.hud.show_message("")
	scene.hud.hide_boss()
	var camera := scene.player.get_node_or_null("Camera2D") as Camera2D
	var world := (load(String(chapter["world"])) as PackedScene).instantiate() as MDSWorldGame
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.player = scene.player
	world.camera = camera
	world.world_file = String(chapter["world_file"])
	world.starting_room = "%s_entry" % chapter["prefix"]
	world.map_view = scene._map_overlay.map_view
	world.room_loaded.connect(scene._on_mds_room_loaded)
	scene.add_child(world)
	scene._mds_world = world
	if not await _wait_mds(scene):
		return false
	return await _wait_room(scene, "%s_entry" % chapter["prefix"])


func _capture_chapter(scene, chapter: Dictionary) -> bool:
	var prefix := String(chapter["prefix"])
	var folder := String(chapter["folder"])
	var directory := _dir.path_join(folder)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	if not await _mount_chapter(scene, chapter):
		return false
	await create_timer(0.6).timeout
	_close_story(scene)
	# 1) Entrance panorama: the authored spawn staircase, the region's backdrop
	# and the ground/side gates. Stand on the middle platform so the frame shows
	# the room's scale instead of the left wall.
	_place(scene, _local_to_global(scene, ENTRY_STAND))
	await create_timer(0.45).timeout
	if not await _capture(directory.path_join(String(chapter["entry_shot"]))):
		return false
	# 2) Vertical region: a 2160 px shaft. Wait for the authored lift to rise
	# into frame so the elevator, the one-way platforms and the depth all read.
	var vertical_room := String(chapter["vertical_room"])
	if not await _load_room(scene, vertical_room):
		return false
	await create_timer(0.5).timeout
	_close_story(scene)
	_place(scene, _local_to_global(scene, WELL_STAND))
	await create_timer(0.4).timeout
	await _wait_lift(scene)
	await _capture(directory.path_join(String(chapter["vertical_shot"])))
	# 3) Boss arena: the real encounter (spawned by the room's own plan region),
	# framed shortly after the entrance so the boss and its letterbox line show.
	var boss_room := "%s_boss" % prefix
	if not await _load_room(scene, boss_room):
		return false
	await create_timer(0.35).timeout
	_close_story(scene)
	_place(scene, _local_to_global(scene, BOSS_STAND))
	await create_timer(0.25).timeout
	scene._update_room_locks()
	await create_timer(2.6).timeout
	await _capture(directory.path_join(String(chapter["boss_shot"])))
	return true


## Room-local px to world px for the region currently loaded.
func _local_to_global(scene, local: Vector2) -> Vector2:
	var room := scene._mds_world.room_node as Node2D
	if room == null:
		return local
	return room.to_global(local)


func _place(scene, world_position: Vector2) -> void:
	scene.player.velocity = Vector2.ZERO
	scene.player.global_position = world_position
	var camera := scene.player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.reset_smoothing()


func _wait_chapter_one(scene, timeout := 10.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._mds_world != null and not scene._mds_world.changing_room \
				and not scene._mds_world.current_room.is_empty():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _wait_mds(scene, timeout := 10.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._mds_world != null and not scene._mds_world.changing_room \
				and not scene._mds_world.current_room.is_empty():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _wait_room(scene, room_id: String, timeout := 10.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._mds_world != null and not scene._mds_world.changing_room \
				and scene._mds_world.current_room == room_id:
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _load_room(scene, room_id: String) -> bool:
	await scene._mds_world.load_room(room_id)
	return await _wait_room(scene, room_id)


## Waits for the authored lift to rise into the shaft frame. The lift ping-pongs
## at the pipeline's default 70 px/s, so waiting keeps its real timing instead of
## teleporting it for the picture.
func _wait_lift(scene, timeout := 26.0) -> void:
	var room: Node2D = scene._mds_world.room_node
	if room == null:
		return
	var lift := room.get_node_or_null("Lift") as MovingPlatform
	if lift == null:
		return
	var left: float = timeout
	while left > 0.0:
		var y: float = lift.global_position.y - room.global_position.y
		if y <= 1140.0 and y >= 1000.0:
			return
		await create_timer(0.08).timeout
		left -= 0.08


func _close_story(scene) -> void:
	if scene._story != null and scene._story.is_open():
		scene._story.close()


func _capture(path: String) -> bool:
	if not path.ends_with(".png"):
		path += ".png"
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("empty frame for " + path)
		return false
	var size := image.get_size()
	# A black or blank frame is not a usable sample: sample a small grid and
	# require some real variance between the darkest and brightest probe.
	var darkest := 1.0
	var brightest := 0.0
	for x in range(0, size.x, 160):
		for y in range(0, size.y, 90):
			var value := image.get_pixel(x, y).get_luminance()
			darkest = minf(darkest, value)
			brightest = maxf(brightest, value)
	var saved := image.save_png(path)
	var player_screen: Vector2 = current_scene.player.get_global_transform_with_canvas().origin
	print("CAPTURE %s size=%dx%d saved=%s contrast=%.3f player_screen=%s"
		% [path, size.x, size.y, str(saved), brightest - darkest, str(player_screen)])
	return saved == OK and size == Vector2i(1280, 720) and brightest - darkest > 0.02
