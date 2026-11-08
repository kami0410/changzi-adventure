class_name PulseEnemy
extends FlyerEnemy

## 渊母：慢慢漂向玩家的发光水母。靠近后触须收拢蓄力，放出一圈电脉冲；
## 脉冲范围大但前摇长，看到收拢就翻滚出圈。被打中时会短暂缩起（受伤减半）。

@export var pulse_radius: float = 120.0
@export var drift_speed_scale: float = 0.6
@export var pulse_tint: Color = Color("7ff0dc")

var _pulsed := false


func _chase_behavior(delta: float) -> void:
	if not _has_valid_target():
		change_state(STATE_IDLE)
		return
	var distance := _distance_to_target()
	if distance > deaggro_range:
		change_state(STATE_IDLE)
		return
	if distance <= attack_range and _attack_cooldown_left <= 0.0:
		change_state(STATE_ATTACK)
		return
	_bob_time += delta * bob_speed
	var goal := target.global_position + Vector2(0.0, -hover_height)
	var direction := global_position.direction_to(goal)
	velocity = direction * get_move_speed() * drift_speed_scale + Vector2(0, sin(_bob_time) * bob_amplitude * 4.0)
	_face_direction(direction.x)


func _on_state_entered(previous: StringName, next: StringName) -> void:
	super._on_state_entered(previous, next)
	if next == STATE_ATTACK:
		_pulsed = false
		if is_inside_tree():
			CombatFX.spawn(get_parent(), global_position, &"telegraph", pulse_tint, _facing, pulse_radius)


func _attack_behavior(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
	_attack_windup_left = maxf(_attack_windup_left - delta, 0.0)
	_attack_left = maxf(_attack_left - delta, 0.0)
	if not _pulsed and _attack_windup_left <= 0.0:
		_pulsed = true
		if is_inside_tree():
			VFX.spawn(get_parent(), &"spell_lightning", global_position, false, 1.2)
			var audio := get_node_or_null("/root/Audio")
			if audio != null:
				audio.call("play_sfx", &"jelly_pulse")
			CombatFX.spawn(get_parent(), global_position, &"shockwave", pulse_tint, _facing, pulse_radius)
		if _has_valid_target() and _distance_to_target() <= pulse_radius:
			_damage_target(get_attack_damage())
	if _attack_left <= 0.0:
		_finish_attack()


func take_damage(amount: int) -> void:
	# Mid-pulse the bell is clenched: hits glance off for half.
	if state == STATE_ATTACK and not _pulsed:
		amount = maxi(amount / 2, 1)
	super.take_damage(amount)


func creature_phase() -> StringName:
	return &"attack" if _pulsed else &"windup"
