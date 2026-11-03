extends SceneTree

## Frame-time stress test for v3 spells: casts the heaviest shapes back to back
## in a live room and reports average / worst process frame time.
## Godot --path . --resolution 1280x720 --script tests/bench_spells.gd

const LOAD := [
	["missile", {&"damage": 4.0, &"projectiles": 96.0, &"homing": 1.2, &"spread": 2.4, &"burn": 2.0, &"explosion": 0.6}, [&"flame"]],
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
			enemy.data = enemy.data.duplicate()
			enemy.max_health = 1000000
			enemy.health = 1000000
	await create_timer(0.5).timeout
	var baseline := await _measure(60)
	for entry in LOAD:
		var phrase := ResolvedPhrase.new()
		phrase.components = entry[1]
		phrase.tags.assign(entry[2])
		phrase.spell = SpellStyle.decide(phrase.tags, phrase.components)
		phrase.spell[&"shape"] = StringName(entry[0])
		phrase.spell[&"range"] = float(SpellStyle.base_for(StringName(entry[0]))[&"range"])
		scene.run_state.ink = scene.run_state.max_ink
		scene.phrase_caster.equip_phrase(0, phrase)
		scene.phrase_caster._cooldowns[0] = 0.0
		scene.phrase_caster.cast(0)
		await process_frame
	var timeline: Array[String] = []
	var last := Time.get_ticks_usec()
	for index in 48:
		await process_frame
		var now := Time.get_ticks_usec()
		if index % 4 == 0:
			timeline.append("%.1f[p%.1f f%.1f d%d n%d]" % [
				float(now - last) / 1000.0,
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			])
		last = now
	print("BENCH timeline ", " ".join(timeline))
	var loaded := await _measure(240)
	var counts: Dictionary = {}
	for node in scene.get_children():
		var key: String = node.get_class() if node.get_script() == null else String(node.get_script().get_global_name())
		counts[key] = int(counts.get(key, 0)) + 1
	print("BENCH children ", counts)
	print("BENCH baseline avg=%.2fms worst=%.2fms" % baseline)
	print("BENCH loaded   avg=%.2fms worst=%.2fms  bolts=%d zones=%d" % [loaded[0], loaded[1], get_nodes_in_group(&"spell_bolts").size(), get_nodes_in_group(&"spell_zones").size()])
	print("BENCH fps=%d" % Engine.get_frames_per_second())
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
