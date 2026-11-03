class_name SwarmEnemy
extends Enemy

## 残页群：低血量、高机动的纸片集群。会绕圈、折返、连续俯冲，
## 用数量压迫玩家，而不是靠单次高伤。

@export var hovering_height: float = 58.0
@export var weave_speed: float = 3.6
@export var dart_speed: float = 430.0
@export var dart_duration: float = 0.24


var _weave_time := 0.0
var _dart_direction := Vector2.LEFT
var _dart_hit := false
var _darting := false


func _ready() -> void:
	apply_gravity = false
	attack_variant_count = 3
	super._ready()


func _idle_behavior(delta: float) -> void:
	_weave_time += delta * weave_speed
	velocity = Vector2(sin(_weave_time) * 20.0, sin(_weave_time * 1.7) * 16.0)
	if _has_valid_target() and _in_aggro_range():
		change_state(STATE_CHASE)


func _chase_behavior(delta: float) -> void:
	if not _has_valid_target():
		change_state(STATE_IDLE)
		return
	var distance := _distance_to_target()
	if distance > deaggro_range:
		change_state(STATE_IDLE)
		return
	_face_direction(target.global_position.x - global_position.x)
	if distance <= attack_range and _attack_cooldown_left <= 0.0:
		change_state(STATE_ATTACK)
		return
	_weave_time += delta * weave_speed
	var goal := target.global_position + Vector2(sin(_weave_time) * 52.0, -hovering_height + sin(_weave_time * 1.4) * 12.0)
	var direction := global_position.direction_to(goal)
	velocity = direction * get_move_speed()


func _on_state_entered(previous: StringName, next: StringName) -> void:
	super._on_state_entered(previous, next)
	if next == STATE_ATTACK:
		_darting = false
		_dart_hit = false
		if _motion != null:
			_motion.play(&"windup", attack_windup)


func _attack_behavior(delta: float) -> void:
	if not _has_valid_target():
		_finish_attack()
		return
	if _attack_windup_left > 0.0:
		_attack_windup_left = maxf(_attack_windup_left - delta, 0.0)
		velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
		return
	if not _darting:
		_darting = true
		_dart_hit = false
		_dart_direction = global_position.direction_to(target.global_position + Vector2(0, -16))
		velocity = _dart_direction * dart_speed
		CombatFX.spawn(get_parent(), global_position, &"telegraph", telegraph_color, _facing, 34)
	_attack_left = maxf(_attack_left - delta, 0.0)
	velocity = _dart_direction * dart_speed
	if not _dart_hit and _distance_to_target() <= attack_range + 8.0:
		_dart_hit = true
		_damage_target(get_attack_damage())
		CombatFX.spawn(get_parent(), global_position, &"hit", Color("d6b6e8"), _facing, 28)
	if _attack_left <= 0.0 or _dart_hit:
		_finish_attack()


func _finish_attack() -> void:
	super._finish_attack()
	_attack_cooldown_left = attack_cooldown * (0.7 if get_attack_variant() >= 3 else 0.9)
