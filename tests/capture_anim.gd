extends SceneTree

## Captures the player's frame animation in a quiet room for visual QA.

var _scene: Node
var _index := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.title_shown_this_session = true
	_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene)
	current_scene = _scene
	await create_timer(0.5).timeout
	_scene._story.close()
	await _wait_mds(_scene)
	await create_timer(0.8).timeout
	await _scene._mds_world.load_room("ch1_rest")
	await create_timer(0.5).timeout
	var room_node: Node2D = _scene._mds_world.room_node
	_scene.player.global_position = room_node.global_position + Vector2(640, 500)
	_scene.player._invulnerable_left = 999.0
	(_scene.player.get_node("Camera2D") as Camera2D).reset_smoothing()
	await create_timer(0.5).timeout

	await _sample("idle", 3, 0.08)
	Input.action_press("move_right")
	await _sample("run", 8, 0.05)
	Input.action_release("move_right")
	Input.action_press("attack")
	await _sample("attack", 4, 0.05)
	Input.action_release("attack")
	_scene.player.start_dodge()
	await _sample("dodge", 3, 0.05)
	await create_timer(0.4).timeout
	Input.action_press("jump")
	await _sample("jump", 6, 0.05)
	Input.action_release("jump")
	await create_timer(0.5).timeout
	_scene.player.play_cast_pose()
	await _sample("cast", 3, 0.06)
	await create_timer(0.4).timeout
	_scene.player._invulnerable_left = 0.0
	_scene.player.take_damage(10)
	await _sample("hurt", 4, 0.06)
	await create_timer(0.4).timeout
	Input.action_press("move_left")
	await _sample("run_left", 4, 0.06)
	Input.action_release("move_left")
	print("ANIM CAPTURE DONE")
	quit()


func _wait_mds(scene, timeout := 8.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._mds_world != null and not scene._mds_world.changing_room and not scene._mds_world.current_room.is_empty():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _sample(label: String, count: int, step: float) -> void:
	for index in count:
		await create_timer(step).timeout
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png("res://artifacts/anim_%02d_%s_%d.png" % [_index, label, index])
		var camera := _scene.player.get_node("Camera2D") as Camera2D
		print("ANIM ", _index, " ", label, " ", _scene.player.global_position, " screen=", _scene.player.global_position - camera.get_screen_center_position() + Vector2(640, 360))
		_index += 1
