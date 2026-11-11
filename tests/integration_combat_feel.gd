extends SceneTree

## 1.1 combat fixes in the real run scene:
## - an enemy dropped on the player's head slides off instead of standing
##   there out of reach.
##   godot --headless --path . -s res://tests/integration_combat_feel.gd

var failures := 0
var assertions := 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("INTEGRATION FAIL: " + label)


func _run() -> void:
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.title_shown_this_session = true
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var left := 10.0
	while left > 0.0 and (scene._mds_world == null or scene._mds_world.changing_room \
			or scene._mds_world.current_room.is_empty()):
		await create_timer(0.05).timeout
		left -= 0.05
	if scene._story.is_open():
		scene._story.close()
	var player: Player = scene.player
	player._invulnerable_left = 600.0
	for _frame in 90:
		await physics_frame
	check(player.is_on_floor(), "player_settled_on_floor")
	await _test_head_stand(scene, player)
	print("INTEGRATION combat feel: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)


func _test_head_stand(scene, player: Player) -> void:
	var enemy := (load("res://scenes/enemies/ink_hound.tscn") as PackedScene).instantiate() as Enemy
	player.get_parent().add_child(enemy)
	# Asleep: no AI steering, so only the slide can move it sideways.
	enemy.set_physics_process(true)
	enemy.aggro_range = 0.0
	enemy.patrol_radius = 0.0
	enemy.global_position = player.global_position + Vector2(0, -120)
	var rested_on_head := 0
	for _frame in 120:
		await physics_frame
		player.velocity.x = 0.0
		var above := enemy.global_position.y < player.global_position.y - 20.0
		var over := absf(enemy.global_position.x - player.global_position.x) < 14.0
		if above and over and enemy.is_on_floor():
			rested_on_head += 1
	check(rested_on_head <= 6, "enemy_does_not_rest_on_player_head (%d frames)" % rested_on_head)
	check(absf(enemy.global_position.x - player.global_position.x) > 20.0, "enemy_ends_beside_player")
	check(enemy.global_position.y > player.global_position.y - 30.0, "enemy_ends_on_the_ground")
	enemy.queue_free()
