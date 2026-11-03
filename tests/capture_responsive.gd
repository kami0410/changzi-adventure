extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	(root.get_node("Flow") as GameFlow).auto_save = false
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.3).timeout
	for dimensions in [Vector2i(1600, 900), Vector2i(1600, 720), Vector2i(960, 540)]:
		root.size = dimensions
		await create_timer(0.2).timeout
		scene._toggle_overlay(scene.codex_ui)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/polish_codex_%dx%d.png" % [dimensions.x, dimensions.y])
		var panel := scene.codex_ui.find_child("Panel", true, false) as Control
		print("LAYOUT ", dimensions, " viewport=", scene.codex_ui.get_viewport_rect().size, " panel=", panel.get_global_rect())
		scene._close_overlay()
	root.size = Vector2i(1280, 720)
	scene.player._invulnerable_left = 100
	scene.player.position = Vector2(6750, 530)
	scene._update_room_locks()
	(scene.player.get_node("Camera2D") as Camera2D).reset_smoothing()
	scene._boss.health = 70
	scene._boss.check_phase()
	await create_timer(0.8).timeout
	scene._boss._ink_rain()
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/polish_boss.png")
	quit()
