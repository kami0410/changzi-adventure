extends SceneTree

## Times each heavy shape separately (frame avg/worst over 90 frames after cast).

const LOAD := [
	["missile", {&"damage": 4.0, &"projectiles": 96.0, &"homing": 1.2, &"spread": 2.4, &"burn": 2.0, &"explosion": 0.6}, [&"flame"]],
	["missile_plain", {&"damage": 4.0, &"projectiles": 96.0, &"homing": 1.2, &"spread": 2.4}, [&"flame"]],
	["meteor", {&"damage": 8.0, &"projectiles": 24.0, &"explosion": 1.5}, [&"star"]],
	["domain", {&"damage": 4.0, &"duration": 6.0, &"slow": 0.3, &"pulses": 3.0}, [&"crown"]],
	["beam", {&"damage": 6.0, &"projectiles": 9.0, &"pulses": 6.0, &"spread": 2.0}, [&"eye"]],
	["quake", {&"damage": 6.0, &"pulses": 6.0, &"spread": 4.0}, [&"earth"]],
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
	var room: ArenaRoom = scene._rooms[2]
	scene.player.global_position = room.global_position + Vector2(-380, 250)
	(scene.player.get_node("Camera2D") as Camera2D).reset_smoothing()
	await create_timer(0.3).timeout
	scene._update_room_locks()
	scene.player._invulnerable_left = 1000.0
	for enemy in room.get_node("Enemies").get_children():
		if enemy is Enemy:
			enemy.max_health = 1000000
			enemy.health = 1000000
	await create_timer(0.5).timeout
	for entry in LOAD:
		var phrase := ResolvedPhrase.new()
		phrase.components = entry[1]
		phrase.tags.assign(entry[2])
		var shape := StringName(String(entry[0]).get_slice("_", 0))
		phrase.spell = SpellStyle.decide(phrase.tags, phrase.components)
		phrase.spell[&"shape"] = shape
		phrase.spell[&"range"] = float(SpellStyle.base_for(shape)[&"range"])
		scene.run_state.ink = scene.run_state.max_ink
		scene.phrase_caster.equip_phrase(0, phrase)
		scene.phrase_caster._cooldowns[0] = 0.0
		var start := Time.get_ticks_usec()
		scene.phrase_caster.cast(0)
		var cast_ms := float(Time.get_ticks_usec() - start) / 1000.0
		var result := await _measure(90)
		print("PART %-14s cast=%.2fms avg=%.2fms worst=%.2fms nodes=%d" % [entry[0], cast_ms, result[0], result[1], scene.get_child_count()])
		await create_timer(1.5).timeout
	quit()


func _measure(frames: int) -> Array:
	var total := 0.0
	var worst := 0.0
	var last := Time.get_ticks_usec()
	for index in frames:
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := float(now - last) / 1000.0
		last = now
		total += ms
		worst = maxf(worst, ms)
	return [total / frames, worst]
