class_name HoverShooterEnemy
extends FlyerEnemy

## 血瞳：悬浮在玩家斜上方保持距离，蓄力后射出慢速追踪泪弹；从不俯冲。
## 逼玩家跳上平台或翻滚穿过弹幕，而不是站桩输出。

@export var keep_distance: float = 230.0
@export var tear_speed: float = 170.0
@export var tear_turn: float = 1.6
@export var tear_tint: Color = Color("e0485a")

var _side := 1.0
var _shot := false


func _ready() -> void:
	super._ready()
	attack_variant_count = 3
	_side = -1.0 if randf() < 0.5 else 1.0


func _chase_behavior(_delta: float) -> void:
	if not _has_valid_target():
		change_state(STATE_IDLE)
		return
	var distance := _distance_to_target()
	if distance > deaggro_range:
		change_state(STATE_IDLE)
		return
	# Swap sides when the player walks past, so it keeps circling the fight.
	if signf(global_position.x - target.global_position.x) != _side and absf(global_position.x - target.global_position.x) > 40.0:
		_side = signf(global_position.x - target.global_position.x)
	var goal := target.global_position + Vector2(_side * keep_distance, -hover_height - 40.0)
	var to_goal := goal - global_position
	if to_goal.length() > 12.0:
		velocity = to_goal.normalized() * get_move_speed()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, get_move_speed())
	_face_direction(target.global_position.x - global_position.x)
	if distance <= keep_distance + 120.0 and _attack_cooldown_left <= 0.0:
		change_state(STATE_ATTACK)


func _on_state_entered(previous: StringName, next: StringName) -> void:
	super._on_state_entered(previous, next)
	if next == STATE_ATTACK:
		_shot = false


func _attack_behavior(delta: float) -> void:
	if not _has_valid_target():
		_finish_attack()
		return
	velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
	_face_direction(target.global_position.x - global_position.x)
	_attack_windup_left = maxf(_attack_windup_left - delta, 0.0)
	_attack_left = maxf(_attack_left - delta, 0.0)
	if not _shot and _attack_windup_left <= 0.0:
		_shot = true
		_fire_tears(get_attack_variant())
	if _attack_left <= 0.0:
		_finish_attack()


func _fire_tears(variant: int) -> void:
	if not is_inside_tree():
		return
	var origin := global_position + Vector2(0, -8)
	var heading := origin.direction_to(target.global_position + Vector2(0, -24))
	var count := 1 if variant == 1 else (2 if variant == 2 else 3)
	for i in count:
		var spread := 0.0 if count == 1 else lerpf(-0.3, 0.3, float(i) / float(count - 1))
		var bolt := HostileBolt.launch(get_parent(), origin, heading.rotated(spread),
			maxi(int(roundf(get_attack_damage() * 0.8)), 1), tear_speed)
		bolt.tint = tear_tint
		if bolt.has_method(&"set_homing"):
			bolt.call(&"set_homing", target, tear_turn)
	CombatFX.spawn(get_parent(), origin, &"cast", tear_tint, _facing, 40)
