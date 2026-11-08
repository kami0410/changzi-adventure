extends SceneTree

## Touch layout review (1.0.1): the Hub and a Chapter 1 room with the touch
## overlay forced on, at whatever window size is passed.
##   godot --path . --resolution 2400x1080 --audio-driver Dummy \
##     -s res://tests/capture_touch.gd -- --out-dir=res://artifacts/touch

var _dir := "res://artifacts/touch"


func _initialize() -> void:
	_run.call_deferred()


func _capture(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var size := root.get_texture().get_size()
	var path := _dir.path_join("%s_%dx%d.png" % [file, size.x, size.y])
	root.get_texture().get_image().save_png(path)
	print("CAPTURE ", path)


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			_dir = argument.trim_prefix("--out-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.title_shown_this_session = true
	flow._set_using_touch(true)

	var hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await create_timer(0.8).timeout
	if hub.dialogue_ui != null and hub.dialogue_ui.is_open():
		hub.dialogue_ui.close()
	await create_timer(0.3).timeout
	await _capture("hub")
	root.remove_child(hub)
	hub.free()

	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.6).timeout
	if scene._story.is_open():
		scene._story.close()
	await create_timer(1.5).timeout
	scene.player._invulnerable_left = 600.0
	# A finger on the stick so its drawn state is visible.
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = Vector2(200, flow.touch_overlay.screen_size().y - 160)
	flow.touch_overlay._input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = touch.position + Vector2(50, 0)
	flow.touch_overlay._input(drag)
	await create_timer(0.2).timeout
	await _capture("run")
	quit(0)
