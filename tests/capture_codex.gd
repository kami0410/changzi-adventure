extends SceneTree

## Opens the codex with every word owned and a v3 sentence typed in.
## Godot --path . --resolution 1280x720 --script tests/capture_codex.gd -- --out-dir=res://artifacts/audit

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	(root.get_node("Flow") as GameFlow).auto_save = false
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.5).timeout
	if scene._story.is_open():
		scene._story.close()
	for entry in ContentLibrary.WORDS:
		if not scene.run_state.inventory.has_word(entry.id):
			scene.run_state.inventory.add_word(entry)
	await process_frame
	scene._toggle_overlay(scene.codex_ui)
	await process_frame
	scene.codex_ui._free_text.text = "一百颗追踪的火星爆炸"
	scene.codex_ui._on_free_text_submitted("一百颗追踪的火星爆炸")
	await create_timer(0.2).timeout
	await _capture("codex_v3")
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
