extends RefCounted

func run(t: Callable) -> void:
	var player := preload("res://scenes/player/player.tscn").instantiate() as Player
	t.call(player.collision_mask, 3, "walking_collides_with_world_and_enemies")
	player.start_dodge()
	t.call(player.collision_mask, 1, "dodge_passes_enemies_but_not_walls")
	t.call(player.is_invulnerable(), true, "dodge_has_iframes")
	player.free()
	var actor := ActorMotion.new()
	actor.play(&"death", 0.3)
	actor._process(0.4)
	t.call(actor._death_finished, true, "death_pose_does_not_snap_back_to_idle")
	actor.play(&"idle")
	t.call(actor._death_finished, false, "new_action_resets_death_state")
	actor.free()
