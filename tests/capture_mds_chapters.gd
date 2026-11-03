extends SceneTree

## Visual QA for all four MDS chapter worlds: entry room and boss room each.
## Run windowed (screenshots need a renderer):
##   Godot --path . --resolution 1280x720 --script tests/capture_mds_chapters.gd -- --out-dir=res://artifacts/mds

var _dir := "res://artifacts/mds"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
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
	await create_timer(0.4).timeout
	for chapter_index in CampaignData.chapter_count():
		if scene._story.is_open():
			scene._story.close()
		if chapter_index > 0:
			scene._start_mds_chapter(chapter_index)
			await create_timer(0.3).timeout
			if scene._story.is_open():
				scene._story.close()
		await _wait_mds(scene)
		await create_timer(0.35).timeout
		await _capture("ch%d_%s" % [chapter_index + 1, CampaignData.chapter(chapter_index)["id"]])
		var prefix := "ch%d" % (chapter_index + 1)
		await scene._mds_world.load_room("%s_boss" % prefix)
		await create_timer(0.3).timeout
		var boss_arena: ArenaRoom = scene._mds_world.room_node.get_node("Arena")
		scene.player.global_position = boss_arena.global_position
		scene._update_room_locks()
		await create_timer(1.3).timeout
		await _capture("ch%d_boss" % (chapter_index + 1))
	quit()


func _wait_mds(scene, timeout := 8.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._mds_world != null and not scene._mds_world.changing_room and not scene._mds_world.current_room.is_empty():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _capture(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_dir.path_join(file + ".png"))
	print("CAPTURE ", file)
