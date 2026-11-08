extends RefCounted

## Roll / air dash / perfect dodge rules on a player outside the tree
## (outside the tree a dodge counts as grounded, so it is a roll).


func run(t: Callable) -> void:
	var player := Player.new()
	player.facing = Vector2.RIGHT
	t.call(player.start_dodge(-1.0), true, "roll_starts")
	t.call(player.dodge_kind, &"roll", "roll_kind_on_ground")
	t.call(player.facing, Vector2.LEFT, "roll_turns_to_held_direction")
	t.call(player.velocity.x < 0.0, true, "roll_moves_backwards_when_held")
	t.call(player.is_rolling_invulnerable(), true, "roll_iframes_open")
	t.call(player.start_dodge(1.0), false, "no_second_roll_mid_roll")

	var perfect := [0]
	player.perfect_dodged.connect(func() -> void: perfect[0] += 1)
	player.take_damage(25, Vector2(100, 0))
	t.call(player.health, 100, "perfect_dodge_takes_no_damage")
	t.call(perfect[0], 1, "perfect_dodge_signal")
	t.call(player._dodge_cooldown_left, 0.0, "perfect_dodge_refunds_cooldown")
	player.take_damage(25, Vector2(100, 0))
	t.call(perfect[0], 1, "perfect_dodge_once_per_roll")
	t.call(player.health, 100, "roll_still_invulnerable_after_perfect")

	# The roll speed eases out: fast at the start, slower at the end.
	var early := player._dodge_velocity()
	player._dodge_left = player._roll_total * 0.1
	var late := player._dodge_velocity()
	t.call(early > late, true, "roll_speed_eases_out")

	# Ending the roll opens the roll-strike window.
	player._end_dodge()
	t.call(player.is_dodging, false, "roll_ends")
	t.call(player._roll_strike_left > 0.0, true, "roll_strike_window_opens")
	t.call(player.dodge_kind, &"", "dodge_kind_cleared")

	# Fall recovery cancels the roll so the fall damage still lands.
	var faller := Player.new()
	faller.start_dodge()
	faller.cancel_dodge()
	faller.take_damage(15)
	t.call(faller.health, 85, "cancel_dodge_lets_fall_damage_land")

	# Vulnerable tail: past the iframes a hit lands normally.
	var tail := Player.new()
	tail.start_dodge()
	tail._roll_iframes_left = 0.0
	tail._invulnerable_left = 0.0
	tail.take_damage(10, Vector2.ZERO)
	t.call(tail.health, 90, "roll_recovery_is_vulnerable")

	t.call(player.roll_iframes < player.dodge_duration, true, "roll_has_recovery_frames")
	t.call(player.roll_height < Player.STAND_HEIGHT, true, "roll_is_lower_than_standing")
	player.free()
	faller.free()
	tail.free()
