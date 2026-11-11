extends "res://tests/capture_bigmap_chapters.gd"

## Frame cost of real rooms (1.1): CPU process/physics time, draw calls, canvas
## items and node counts per room, plus a screenshot of each. Draw calls and
## process time are what the phone pays for, so this is the regression gate for
## Android performance work.
##   godot --path . --resolution 1280x720 --audio-driver Dummy \
##     -s res://tests/bench_frame.gd -- --out-dir=res://artifacts/bench

const ROOMS := [
	[-1, "ch1_02"], [-1, "ch1_05"],
	[0, "ch2_entry"], [0, "ch2_hub"], [0, "ch2_well"], [0, "ch2_boss"],
	[1, "ch3_hub"], [2, "ch4_hub"],
]


func _run() -> void:
	_dir = "res://artifacts/bench"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			_dir = argument.trim_prefix("--out-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.title_shown_this_session = true
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.7).timeout
	_close_story(scene)
	if not await _wait_chapter_one(scene):
		quit(1)
		return
	scene.player._invulnerable_left = 6000.0
	var mounted := -1
	for entry in ROOMS:
		var chapter: int = entry[0]
		if chapter != mounted and chapter >= 0:
			if not await _mount_chapter(scene, CHAPTERS[chapter]):
				continue
			mounted = chapter
		if not await _load_room(scene, String(entry[1])):
			print("BENCH %s failed to load" % entry[1])
			continue
		await create_timer(1.0).timeout
		_close_story(scene)
		await create_timer(0.5).timeout
		await _measure_room(scene, String(entry[1]))
	quit()


func _measure_room(scene, room_id: String) -> void:
	# Uncapped wall-clock frame time: the whole cost of a frame (scripts,
	# physics, canvas culling and draw submission), not just script time.
	var cap := Engine.max_fps
	Engine.max_fps = 0
	var frames := 240
	var worst := 0.0
	var draws := 0.0
	var items := 0.0
	var times := PackedFloat32Array()
	var last := Time.get_ticks_usec()
	for index in frames:
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := float(now - last) / 1000.0
		last = now
		times.append(ms)
		worst = maxf(worst, ms)
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		items += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	Engine.max_fps = cap
	times.sort()
	print("BENCH %-12s median=%.2fms p95=%.2fms worst=%.2fms draws=%.0f objects=%.0f nodes=%d enemies=%d vram=%.0fMB" % [
		room_id, times[frames / 2], times[int(frames * 0.95)], worst, draws / frames, items / frames,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		get_nodes_in_group("enemies").size(),
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
	])
	await _capture(_dir.path_join(room_id))
