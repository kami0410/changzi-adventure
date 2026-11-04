extends SceneTree

## Captures the authority picker and the campaign ending screen, the two
## UI states missing from the screenshot set. Rendering needs a real
## DisplayServer, so run it under xvfb (headless has a dummy renderer):
##   xvfb-run -a godot --path . --resolution 1280x720 --rendering-driver opengl3 \
##     --audio-driver Dummy -s tests/capture_authority_ending.gd -- --out-dir=res://artifacts/screens

var _dir := "res://artifacts/screens"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			_dir = argument.trim_prefix("--out-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.7).timeout
	# The chapter intro story covers the whole screen; close it first.
	if scene._story.is_open():
		scene._story.close()
	await create_timer(0.3).timeout
	if scene._chapter_plan == null or scene._chapter_plan.authority_pool.is_empty():
		push_error("chapter 1 authority pool is empty")
		quit(1)
		return
	scene._authority_choice.open(scene._chapter_plan.authority_pool)
	# The picker pauses the tree; unpause only so the offscreen renderer keeps
	# drawing frames, the overlay itself stays visible.
	paused = false
	await create_timer(0.3).timeout
	await _capture("19_authority_choice")
	scene._authority_choice._choose(0)
	await create_timer(0.2).timeout
	scene.ending_screen.show_campaign_ending(
		true, 30, CampaignData.ending_for(true, 20, 3, false), 4, 37, true
	)
	await create_timer(0.3).timeout
	await _capture("20_ending")
	quit()


func _capture(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_dir.path_join(file + ".png"))
	print("CAPTURE ", file)
