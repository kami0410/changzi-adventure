extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var flow := root.get_node("Flow")
	flow.auto_save = false
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.8).timeout
	if scene._story.is_open():
		scene._story.close()
	await create_timer(0.2).timeout
	await _capture("polish_start")
	scene.player.global_position = Vector2(1490, 530)
	(scene.player.get_node("Camera2D") as Camera2D).reset_smoothing()
	await create_timer(0.7).timeout
	Input.action_press("move_right")
	await create_timer(0.3).timeout
	Input.action_release("move_right")
	scene.player._on_attack_requested()
	await create_timer(0.06).timeout
	await _capture("polish_attack")
	scene._toggle_overlay(scene.inventory_ui)
	await _capture("polish_inventory")
	scene._close_overlay()
	scene._toggle_overlay(scene.codex_ui)
	await _capture("polish_codex")
	var word_buttons: Array[Node] = scene.codex_ui._word_grid.find_children("*", "Button", true, false)
	if not word_buttons.is_empty():
		(word_buttons[0] as Button).pressed.emit()
	await process_frame
	scene.codex_ui._clear_selection()
	scene._close_overlay()
	for enemy in scene._rooms[0].get_node("Enemies").get_children():
		if enemy is Enemy:
			enemy.take_damage(10000)
	await create_timer(0.6).timeout
	await _capture("polish_reward")
	if scene._reward_ui.visible:
		scene._reward_ui._choose(0)
	await create_timer(0.1).timeout
	paused = false
	root.remove_child(scene)
	scene.free()
	var hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await create_timer(0.8).timeout
	await _capture("polish_hub")
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
