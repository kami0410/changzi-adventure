extends "res://tests/capture_bigmap_chapters.gd"

## 0.13 sample frames: the roll, a called elevator and its panel, the
## per-chapter terrain tiles and a seeded Chapter 1 layout. Needs a real
## display (see capture_bigmap_chapters.gd). Output stays in artifacts/.
##   godot --path . --resolution 1280x720 --audio-driver Dummy \
##     -s res://tests/capture_polish_013.gd -- --out-dir=res://artifacts/screens


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			_dir = argument.trim_prefix("--out-dir=")
	var directory := _dir.path_join("polish013")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.title_shown_this_session = true
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.7).timeout
	_close_story(scene)
	if not await _wait_chapter_one(scene):
		push_error("chapter 1 never loaded")
		quit(1)
		return
	# Chapter 1: a combat room with this run's seeded layout.
	await _load_room(scene, "ch1_02")
	await create_timer(0.6).timeout
	_close_story(scene)
	_place(scene, _local_to_global(scene, Vector2(200, 544)))
	await create_timer(0.6).timeout
	await _capture(directory.path_join("ch1_seeded_layout"))
	# Roll sequence on flat floor.
	scene.player.facing = Vector2.RIGHT
	scene.player.start_dodge(1.0)
	for index in 4:
		await create_timer(0.07).timeout
		await _capture(directory.path_join("roll_%d" % index))
	# Chapter 2: called elevator, standing at the bottom panel.
	var ch2: Dictionary = CHAPTERS[0]
	if await _mount_chapter(scene, ch2):
		await create_timer(0.6).timeout
		_close_story(scene)
		_place(scene, _local_to_global(scene, ENTRY_STAND))
		await create_timer(0.5).timeout
		await _capture(directory.path_join("ch2_entry_tiles"))
		if await _load_room(scene, "ch2_hub"):
			await create_timer(0.6).timeout
			_close_story(scene)
			var lift := scene._mds_world.room_node.get_node_or_null("Lift") as MovingPlatform
			if lift != null:
				var panel: Vector2 = lift.panel_position(0)
				_place(scene, panel + Vector2(-20, -Player.FOOT_Y))
				await create_timer(0.6).timeout
				await _capture(directory.path_join("ch2_lift_panel"))
				_place(scene, lift.global_position + Vector2(80, -Player.FOOT_Y - 4))
				await create_timer(0.4).timeout
				await _capture(directory.path_join("ch2_lift_rider"))
				lift.try_interact(scene.player.global_position + Vector2(0, Player.FOOT_Y))
				await create_timer(1.6).timeout
				await _capture(directory.path_join("ch2_lift_riding"))
	for chapter in [CHAPTERS[1], CHAPTERS[2]]:
		if await _mount_chapter(scene, chapter):
			await create_timer(0.6).timeout
			_close_story(scene)
			_place(scene, _local_to_global(scene, ENTRY_STAND))
			await create_timer(0.5).timeout
			await _capture(directory.path_join("%s_entry_tiles" % chapter["prefix"]))
	quit()
