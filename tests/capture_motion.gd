extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	(root.get_node("Flow") as GameFlow).auto_save = false
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.player.position = Vector2(640, 530)
	(scene.player.get_node("Camera2D") as Camera2D).reset_smoothing()
	await create_timer(0.3).timeout
	if scene._story.is_open():
		scene._story.close()
	await create_timer(0.2).timeout
	for i in 40:
		if i == 5:
			Input.action_press("move_right")
		if i == 15:
			Input.action_release("move_right")
			Input.action_press("attack")
		if i == 22:
			Input.action_release("attack")
			scene.player.start_dodge()
		if i == 29:
			Input.action_press("jump")
		if i == 33:
			Input.action_release("jump")
		await create_timer(0.06).timeout
		await RenderingServer.frame_post_draw
		if i in [5, 8, 11, 15, 22, 27, 28, 29, 30, 31, 32, 33, 35]:
			print("PSTATE ", i, " pos=", scene.player.global_position, " action=", scene.player._motion.current_action(), " floor=", scene.player.is_on_floor(), " vy=", scene.player.velocity.y, " anim=", scene.player._frame_anim, " tex=", scene.player.sprite_visual.texture.resource_path)
		root.get_texture().get_image().save_png("res://artifacts/motion_%02d.png" % i)
	Input.action_release("move_right")
	Input.action_release("attack")
	Input.action_release("jump")
	print("MOTION CAPTURE 40 frames")
	quit()
