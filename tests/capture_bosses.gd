extends SceneTree

## Captures each chapter's boss arena to check sprite grounding and scale.
## Godot --path . --script tests/capture_bosses.gd -- --out-dir=res://artifacts/audit

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	(root.get_node("Flow") as GameFlow).auto_save = false
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.5).timeout
	for chapter in 4:
		if chapter > 0:
			scene._start_chapter(chapter)
			await create_timer(0.3).timeout
		if scene._story.is_open():
			scene._story.close()
		await create_timer(0.2).timeout
		var boss_room: Node2D = scene._rooms.back()
		scene.player.global_position = Vector2(boss_room.global_position.x - 300.0, 530)
		(scene.player.get_node("Camera2D") as Camera2D).reset_smoothing()
		await create_timer(0.6).timeout
		await _capture("boss_ch%d" % (chapter + 1))
	quit()


func _capture(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var directory := "res://artifacts"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			directory = argument.trim_prefix("--out-dir=")
	root.get_texture().get_image().save_png(directory.path_join(file + ".png"))
	print("CAPTURE ", file)
