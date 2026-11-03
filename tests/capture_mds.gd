extends SceneTree

## Captures the MDS chapter-1 pilot: entry, combat, chest, rest and boss rooms.
## Run windowed (screenshots need a renderer):
##   Godot --path . --resolution 1280x720 --script tests/capture_mds.gd -- --out-dir=res://artifacts/mds

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
	await create_timer(0.5).timeout
	scene._story.close()
	await _wait_mds(scene)
	scene.player.global_position = Vector2(40, 560)
	await create_timer(0.3).timeout
	await _capture("mds_01_entry")
	scene._map_overlay.open()
	await create_timer(0.2).timeout
	await _capture("mds_06_map")
	scene._map_overlay.close()

	var arena: ArenaRoom = scene._mds_world.room_node.get_node("Arena")
	scene.player.global_position = arena.global_position
	scene._update_room_locks()
	await create_timer(0.5).timeout
	await _capture("mds_02_combat")

	await scene._mds_world.load_room("ch1_03")
	await create_timer(0.3).timeout
	await _capture("mds_03_chest")

	await scene._mds_world.load_room("ch1_rest")
	await create_timer(0.3).timeout
	await _capture("mds_04_rest")

	await scene._mds_world.load_room("ch1_vault")
	await create_timer(0.3).timeout
	await _capture("mds_04b_vault")

	await scene._mds_world.load_room("ch1_boss")
	await create_timer(0.3).timeout
	var boss_arena: ArenaRoom = scene._mds_world.room_node.get_node("Arena")
	scene.player.global_position = boss_arena.global_position
	scene._update_room_locks()
	await create_timer(1.4).timeout
	await _capture("mds_05_boss")

	await scene._mds_world.load_room("ch1_04")
	await create_timer(0.5).timeout
	await _capture("mds_07_elite")
	await scene._mds_world.load_room("ch1_05")
	await create_timer(1.2).timeout
	await _capture("mds_08_event")
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
