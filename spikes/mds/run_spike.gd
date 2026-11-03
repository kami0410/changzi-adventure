extends SceneTree

## MDS spike runner: loads the 3-room spike world with the real Player, walks
## through battle → chest → boss, and reports what works plus frame times.
## Godot --path . --resolution 1280x720 --script spikes/mds/run_spike.gd -- --out-dir=res://artifacts/audit

const WORLD := "res://spikes/mds/spike.mdsworld.json"
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var _checks := 0
var _fails := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
	print("SPIKE %s %s" % ["PASS" if ok else "FAIL", label])


func _run() -> void:
	(root.get_node("Flow") as GameFlow).auto_save = false
	var game := Node2D.new()
	game.name = "SpikeGame"
	root.add_child(game)
	current_scene = game
	var player := PLAYER_SCENE.instantiate() as Player
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	var world_game := MDSWorldGame.new()
	world_game.name = "World"
	world_game.world_file = WORLD
	world_game.player = player
	world_game.camera = camera
	world_game.fade_time = 0.15
	world_game.room_darkness = false
	world_game.exploration_file = ""
	game.add_child(world_game)
	world_game.add_child(player)
	world_game.player = player
	world_game.camera = camera
	await _until(func() -> bool: return world_game.current_room == "spike_battle" and not world_game.changing_room, 5.0)
	check(world_game.current_room == "spike_battle", "starts_in_battle_room")
	check(world_game.room_node != null and world_game.room_node.get_node_or_null("Arena") is ArenaRoom, "arena_room_runs_inside_mds_room")
	check(player.is_inside_tree() and player.health > 0, "existing_player_scene_accepted")
	check(camera.limit_right == 1280 and camera.limit_left == 0, "camera_limited_to_room")
	check(world_game.weather != null, "area_weather_attached")
	var arena: ArenaRoom = world_game.room_node.get_node("Arena")
	player.global_position = Vector2(400, 530)
	await process_frame
	arena.lock_until_cleared()
	check(arena.is_locked(), "battle_room_locks")
	var frame_ms := await _measure(120)
	print("SPIKE frame battle+weather avg=%.2fms worst=%.2fms" % frame_ms)
	await _capture("mds_spike_battle")
	for enemy in arena.get_node("Enemies").get_children():
		if enemy is Enemy:
			enemy.take_damage(100000)
	await create_timer(0.6).timeout
	check(arena.is_cleared(), "battle_room_clears")
	player.global_position = Vector2(1250, 470)
	await _until(func() -> bool: return world_game.current_room == "spike_chest" and not world_game.changing_room, 4.0)
	check(world_game.current_room == "spike_chest", "gate_moves_to_chest_room")
	check(player.global_position.x > 1280.0 and player.global_position.x < 1600.0, "player_placed_at_entry_gate")
	var chest := world_game.room_node.find_children("*", "TreasureChest", true, false)
	check(not chest.is_empty() and (chest[0] as TreasureChest).open(), "chest_opens")
	# MDS ignores gates for gate_cooldown (0.35 s) after arriving; walk away first.
	await create_timer(0.6).timeout
	player.global_position = Vector2(2530, 470)
	await _until(func() -> bool: return world_game.current_room == "spike_boss" and not world_game.changing_room, 4.0)
	check(world_game.current_room == "spike_boss", "gate_moves_to_boss_room")
	check(world_game.background != null, "boss_background_attached")
	var boss_ms := await _measure(120)
	print("SPIKE frame boss+background avg=%.2fms worst=%.2fms" % boss_ms)
	await _capture("mds_spike_boss")
	var boss_arena: ArenaRoom = world_game.room_node.get_node("Arena")
	var bosses := boss_arena.get_node("Enemies").get_children()
	check(not bosses.is_empty() and bosses[0] is InkArchivist, "boss_spawned_with_existing_script")
	# Uncapped cost: how much frame time the atmosphere layers really take.
	Engine.max_fps = 0
	var uncapped := await _measure(240)
	print("SPIKE uncapped boss+void_pulse avg=%.2fms worst=%.2fms" % uncapped)
	var room_rect := Rect2(world_game.world.get_origin("spike_boss"), Vector2(1280, 720))
	var heavy := MDSEnvironment.build("volcanic, creatures(creature=bats)", room_rect)
	check(heavy != null, "heat_haze_and_creatures_build")
	if heavy != null:
		world_game.add_child(heavy)
		await create_timer(0.5).timeout
		var heavy_ms := await _measure(240)
		print("SPIKE uncapped +volcanic(heat_haze)+creatures avg=%.2fms worst=%.2fms" % heavy_ms)
		await _capture("mds_spike_heat_haze")
		heavy.queue_free()
		await process_frame
	var plain := await _measure(240)
	print("SPIKE uncapped after removing heavy layers avg=%.2fms worst=%.2fms" % plain)
	Engine.max_fps = 120
	print("SPIKE RESULT %d checks, %d failed" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func _until(condition: Callable, timeout: float) -> void:
	var left := timeout
	while left > 0.0 and not condition.call():
		await process_frame
		left -= 1.0 / 60.0


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


func _capture(file: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var directory := "res://artifacts"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			directory = argument.trim_prefix("--out-dir=")
	root.get_texture().get_image().save_png(directory.path_join(file + ".png"))
	print("CAPTURE ", file)
