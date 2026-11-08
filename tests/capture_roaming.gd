extends "res://tests/capture_bigmap_chapters.gd"

## Roaming encounters (0.15) in the real game: a Chapter 1 room and a
## Chapter 2 region right after loading, then a second later (patrol moved
## them), with the camera pulled out so the whole spread is visible.
##   godot --path . --resolution 1280x720 --audio-driver Dummy \
##     -s res://tests/capture_roaming.gd -- --out-dir=res://artifacts/screens


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			_dir = argument.trim_prefix("--out-dir=")
	var directory := _dir.path_join("roaming")
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
		quit(1)
		return
	scene.player._invulnerable_left = 600.0
	await _load_room(scene, "ch1_02")
	await create_timer(0.5).timeout
	_close_story(scene)
	await _capture(directory.path_join("ch1_room"))
	_report(scene, "ch1_02")
	if await _mount_chapter(scene, CHAPTERS[0]):
		await create_timer(0.5).timeout
		_close_story(scene)
		if await _load_room(scene, "ch2_branch_a"):
			await create_timer(0.4).timeout
			_close_story(scene)
			var camera := scene.player.get_node_or_null("Camera2D") as Camera2D
			camera.zoom = Vector2(0.5, 0.5)
			await create_timer(0.3).timeout
			await _capture(directory.path_join("ch2_region_overview"))
			_report(scene, "ch2_branch_a")
			await create_timer(1.5).timeout
			await _capture(directory.path_join("ch2_region_later"))
			camera.zoom = Vector2.ONE
	quit()


func _report(scene, room_id: String) -> void:
	var lines: Array[String] = []
	for arena in scene._rooms:
		lines.append("%s roaming=%s locked=%s enemies=%d" % [arena.name, arena.roaming, arena.is_locked(), arena.enemy_count()])
	for enemy in get_nodes_in_group("enemies"):
		var e := enemy as Enemy
		lines.append("  %s at %s state=%s patrol=%.0f" % [e.data.id if e.data else e.name, e.global_position.round(), e.state, e.patrol_radius])
	printerr("ROAM ", room_id, "\n", "\n".join(lines))
