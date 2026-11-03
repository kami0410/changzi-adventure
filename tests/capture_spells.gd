extends SceneTree

## Casts each v3 spell shape in a live chapter-1 room and captures mid-flight.
## Godot --path . --resolution 1280x720 --script tests/capture_spells.gd -- --out-dir=res://artifacts/audit

const SPELLS := [
	["missile", "追踪弹幕", {&"damage": 6.0, &"projectiles": 16.0, &"homing": 1.2, &"spread": 1.6, &"burn": 2.0}, [&"flame", &"star"], 0.32],
	["quake", "地裂", {&"damage": 10.0, &"knockback": 2.0}, [&"earth"], 0.22],
	["meteor", "坠星", {&"damage": 14.0, &"projectiles": 4.0, &"explosion": 1.5}, [&"star"], 0.52],
	["beam", "贯光", {&"damage": 9.0, &"pulses": 3.0, &"pierce": 3.0}, [&"eye", &"light"], 0.06],
	["domain", "领域", {&"damage": 8.0, &"duration": 4.0, &"slow": 0.3}, [&"crown"], 0.5],
	["vortex", "漩涡", {&"damage": 6.0, &"pull": 2.0}, [&"time", &"space"], 0.6],
	["chain", "连锁", {&"damage": 9.0, &"chain": 6.0, &"projectiles": 6.0, &"homing": 1.0}, [&"thunder"], 0.1],
]


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
	await create_timer(0.2).timeout
	var room: ArenaRoom = scene._rooms[2]
	scene.player.global_position = room.global_position + Vector2(-380, 250)
	(scene.player.get_node("Camera2D") as Camera2D).reset_smoothing()
	await create_timer(0.3).timeout
	scene._update_room_locks()
	scene.player._invulnerable_left = 1000.0
	for enemy in room.get_node("Enemies").get_children():
		if enemy is Enemy:
			enemy.data = enemy.data.duplicate()
			enemy.data.max_health = 100000
			enemy.max_health = 100000
			enemy.health = 100000
	await create_timer(0.8).timeout
	for entry in SPELLS:
		var phrase := ResolvedPhrase.new()
		phrase.display_name = entry[1]
		phrase.components = entry[2]
		phrase.tags.assign(entry[3])
		phrase.spell = SpellStyle.decide(phrase.tags, phrase.components)
		phrase.spell[&"shape"] = StringName(entry[0])
		phrase.spell[&"color"] = SpellStyle.color_for(phrase.tags, StringName(entry[0]))
		phrase.spell[&"range"] = float(SpellStyle.base_for(StringName(entry[0]))[&"range"])
		phrase.ink_cost = 0
		phrase.cooldown = 0.0
		scene.run_state.ink = scene.run_state.max_ink
		scene.phrase_caster.equip_phrase(0, phrase)
		scene.phrase_caster._cooldowns[0] = 0.0
		scene.player.facing = Vector2.RIGHT
		scene.phrase_caster.cast(0)
		await create_timer(float(entry[4])).timeout
		await _capture("spell_" + String(entry[0]))
		await create_timer(0.9).timeout
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
