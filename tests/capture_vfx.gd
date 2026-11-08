extends "res://tests/capture_bigmap_chapters.gd"

## Combat VFX in the real game frame: a real swing + hit on a live enemy, then
## every exported effect laid out on the floor of a Chapter 1 room.
##   godot --path . --resolution 1280x720 --audio-driver Dummy \
##     -s res://tests/capture_vfx.gd -- --out-dir=res://artifacts/screens


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			_dir = argument.trim_prefix("--out-dir=")
	var directory := _dir.path_join("vfx")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.title_shown_this_session = true
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.7).timeout
	_close_story(scene)
	if not await _wait_chapter_one(scene):
		quit(1)
		return
	scene.player._invulnerable_left = 60.0
	# Real swing into the room's enemies.
	var enemies := get_nodes_in_group("enemies")
	if not enemies.is_empty():
		var target := enemies[0] as Node2D
		scene.player.global_position = target.global_position + Vector2(-60, 0)
		scene.player.facing = Vector2.RIGHT
		for i in 3:
			scene.player.attack_requested.emit()
			await create_timer(0.09).timeout
			await _capture(directory.path_join("swing_%d" % i))
			await create_timer(0.2).timeout
	# Gallery: every effect, five per row, on the floor line.
	for enemy in get_nodes_in_group("enemies"):
		(enemy as Node).queue_free()
	var ids := ["slash_light", "slash_heavy", "smash", "whip", "flurry",
		"hit_spark", "hit_crit", "parry", "enemy_die", "elite_die",
		"enemy_spawn", "respawn", "chest_open", "heal", "cast_circle",
		"spell_fire", "spell_lightning", "spell_ice", "spell_shadow", "spell_holy"]
	var origin: Vector2 = scene._mds_world.room_node.global_position
	for page in 4:
		for i in 5:
			var id: String = ids[page * 5 + i]
			VFX.spawn(scene._mds_world.room_node, StringName(id), origin + Vector2(140 + i * 250, 560))
		await create_timer(0.3).timeout
		await _capture(directory.path_join("gallery_%d" % page))
		await create_timer(1.6).timeout
	quit()
