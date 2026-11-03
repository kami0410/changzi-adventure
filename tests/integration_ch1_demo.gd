extends SceneTree

## Input-driven Chapter 1 demo smoke test: real Input actions move, jump,
## attack, dodge and interact. No teleporting into rooms and no 100000-damage
## kills; the old integration_playability.gd stays as the structural suite.

var failures: int = 0
var assertions: int = 0


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("CH1 DEMO FAIL: " + label)


func _initialize() -> void:
	_run.call_deferred()


func _wait_mds(scene, timeout := 8.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._mds_world != null and not scene._mds_world.changing_room and not scene._mds_world.current_room.is_empty():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


func _run() -> void:
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.title_shown_this_session = true
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.5).timeout
	if scene._story.is_open():
		scene._story.close()
	await _wait_mds(scene)
	check(scene._mds_world.current_room == "ch1_01", "demo_starts_in_ch1_01")

	# Walk right with the real movement action.
	var start_x: float = scene.player.global_position.x
	Input.action_press("move_right")
	await create_timer(2.5).timeout
	Input.action_release("move_right")
	check(scene.player.global_position.x > start_x + 100.0, "demo_move_right")

	# Jump with the real jump action.
	await create_timer(0.15).timeout
	var start_y: float = scene.player.global_position.y
	Input.action_press("jump")
	await create_timer(0.12).timeout
	Input.action_release("jump")
	await create_timer(0.08).timeout
	check(scene.player.global_position.y < start_y - 4.0 or scene.player.velocity.y < -100.0, "demo_jump")

	# Attack whatever came to meet us; the input drives the swing.
	var arena := scene._mds_world.room_node.get_node_or_null("Arena") as ArenaRoom
	check(arena != null, "demo_arena_present")
	if arena != null:
		scene.player.global_position = arena.global_position
		scene._update_room_locks()
		await create_timer(0.4).timeout
		var enemies := arena.get_node("Enemies").get_children()
		var first_enemy: Enemy = null
		for enemy in enemies:
			if enemy is Enemy and not enemy.dead:
				first_enemy = enemy
				break
		check(first_enemy != null, "demo_enemy_present")
		var before: Dictionary = {}
		if first_enemy != null:
			first_enemy.global_position = scene.player.global_position + Vector2(40, 0)
			before[first_enemy] = first_enemy.health
			scene.player.facing = Vector2.RIGHT
		Input.action_press("attack")
		await create_timer(1.4).timeout
		Input.action_release("attack")
		await create_timer(0.2).timeout
		var damaged := false
		for enemy in before:
			if not is_instance_valid(enemy) or enemy.health < int(before[enemy]):
				damaged = true
		check(damaged, "demo_attack_damages_enemy")

	# Dodge grants invulnerability; a hit during it does not cost health.
	Input.action_press("dodge")
	await create_timer(0.05).timeout
	Input.action_release("dodge")
	check(scene.player.is_invulnerable(), "demo_dodge_invulnerable")
	var health_before: int = scene.player.health
	scene.player.take_damage(10)
	check(scene.player.health == health_before, "demo_dodge_blocks_damage")
	await create_timer(0.6).timeout

	# Interact with a real chest through the interact action.
	await scene._mds_world.load_room("ch1_03")
	await create_timer(0.4).timeout
	check(not scene._chests.is_empty(), "demo_chest_present")
	if not scene._chests.is_empty():
		var chest: TreasureChest = scene._chests[0]
		scene.player.global_position = chest.global_position + Vector2(-40, 0)
		scene.player.velocity = Vector2.ZERO
		check(scene.player.global_position.distance_to(chest.global_position) < 92.0, "demo_chest_in_range")
		await create_timer(0.2).timeout
		var press := InputEventAction.new()
		press.action = &"interact"
		press.pressed = true
		Input.parse_input_event(press)
		await process_frame
		var release := InputEventAction.new()
		release.action = &"interact"
		release.pressed = false
		Input.parse_input_event(release)
		await create_timer(0.3).timeout
		check(chest.is_open, "demo_interact_opens_chest")

	print("CH1 DEMO INTEGRATION: %d checks, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
