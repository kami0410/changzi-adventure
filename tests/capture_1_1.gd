extends "res://tests/capture_bigmap_chapters.gd"

## 1.1 in the real game: painted enemies playing drawn strips, the sentence
## line, world acts on screen, the standing-rules list, and each chapter at
## play zoom for the readability pass.
##   godot --path . --resolution 1280x720 --audio-driver Dummy \
##     -s res://tests/capture_1_1.gd -- --out-dir=res://artifacts/screens


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			_dir = argument.trim_prefix("--out-dir=")
	var directory := _dir.path_join("v1_1")
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
	scene.player._invulnerable_left = 600.0
	await _load_room(scene, "ch1_02")
	await create_timer(0.6).timeout
	_close_story(scene)
	await _capture(directory.path_join("01_ch1_room"))

	var acts: WorldActs = scene.world_acts
	# A line-up of painted enemies beside the player, mid-animation.
	for id in ["ink_hound", "scribe_bug", "blank_man", "hanging_scribe"]:
		acts.apply(WorldActs.sanitize([{"do": "summon", "id": id, "count": 1, "seconds": 8, "hostile": 1}])[0], true)
	await create_timer(0.9).timeout
	await _capture(directory.path_join("02_painted_enemies"))
	await create_timer(0.35).timeout
	await _capture(directory.path_join("03_painted_enemies_later"))

	acts.perform(WorldActs.sanitize([
		{"do": "shrink", "target": "all", "scale": 0.5, "seconds": 20},
		{"do": "platforms", "count": 4, "pattern": "stairs", "seconds": 20},
		{"do": "wall", "seconds": 20},
		{"do": "mutator", "key": "damage_dealt", "amount": 2.0, "seconds": 0},
	]), WorldActs.sanitize_rules([{"when": "on_kill", "do": [{"do": "ink", "amount": 8}], "seconds": 0}]))
	await create_timer(0.5).timeout
	await _capture(directory.path_join("04_world_acts"))

	scene._speak_cooldown = 0.0
	scene._open_speak_bar()
	scene._speak_bar.remember("所有敌人缩小十秒")
	scene._speak_bar.remember("每杀一个敌人就回墨")
	scene._speak_bar.close()
	scene._open_speak_bar()
	scene._speak_bar._line.text = "让时间变慢五秒，立起一面墙"
	await create_timer(0.3, true, false, true).timeout
	await _capture(directory.path_join("05_speak_bar"))
	scene._speak_bar.close()

	for index in CHAPTERS.size():
		if not await _mount_chapter(scene, CHAPTERS[index]):
			continue
		await create_timer(0.6).timeout
		_close_story(scene)
		await _capture(directory.path_join("1%d_chapter_%d" % [index, index + 2]))
	quit()
