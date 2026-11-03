extends SceneTree

## Captures the Hub at 1280x720 to review NPC scale, labels, prompts and foot alignment.
## Run windowed (not --headless) so the GL Compatibility renderer draws:
## Godot --path . --script tests/capture_hub.gd -- --out-dir=res://artifacts

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	(root.get_node("Flow") as GameFlow).auto_save = false
	var hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await create_timer(0.4).timeout
	for child in hub.get_children():
		if child is TitleScreen:
			child._start()
	await create_timer(0.3).timeout
	if hub.dialogue_ui != null and hub.dialogue_ui.is_open():
		hub.dialogue_ui.close()
	await create_timer(0.3).timeout
	await _capture("hub_overview")
	for npc_name in ["NPC_Wenjin", "NPC_Luchen", "NPC_Ayan", "NPC_Guru", "NPC_Baiyu"]:
		var npc := hub.get_node_or_null(npc_name) as Node2D
		if npc == null:
			continue
		hub.player.global_position = Vector2(npc.global_position.x - 40.0, 530)
		await create_timer(0.35).timeout
		await _capture("hub_near_" + npc_name.trim_prefix("NPC_").to_lower())
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
