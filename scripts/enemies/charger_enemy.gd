class_name ChargerEnemy
extends Enemy

## 冲锋敌人（空白人）：贴近到冲锋距离后，先停顿蓄力，再直线冲锋。

@export var charge_range: float = 280.0
@export var charge_speed: float = 420.0
@export var charge_windup: float = 0.5
@export var charge_duration: float = 0.45

var _charge_windup_left: float = 0.0
var _charge_left: float = 0.0
var _charge_direction: Vector2 = Vector2.RIGHT
var _charge_hit: bool = false
var _charging: bool = false


func _ready() -> void:
	attack_variant_count = 2
	super._ready()


func _on_state_entered(previous: StringName, next: StringName) -> void:
	super._on_state_entered(previous, next)
	if next == STATE_ATTACK:
		var variant := get_attack_variant()
		_charge_windup_left = charge_windup * (0.7 if variant <= 1 else 1.0)
		_charge_left = charge_duration * (0.62 if variant <= 1 else 1.0)
		_charge_hit = false
		_charging = false
		_charge_direction = Vector2(_facing, 0.0)
		if _motion != null:
			_motion.play(&"windup", _charge_windup_left)


func _chase_behavior(_delta: float) -> void:
	if not _has_valid_target():
		change_state(STATE_IDLE)
		return
	var distance := _distance_to_target()
	if distance > deaggro_range:
		change_state(STATE_IDLE)
		return
	if distance <= charge_range and _attack_cooldown_left <= 0.0:
		_face_direction(target.global_position.x - global_position.x)
		change_state(STATE_ATTACK)
		return
	if distance <= attack_range:
		velocity.x = 0.0
		if _attack_cooldown_left <= 0.0:
			_face_direction(target.global_position.x - global_position.x)
			change_state(STATE_ATTACK)
		return
	_move_toward_target(get_move_speed())


func _attack_behavior(delta: float) -> void:
	if _charge_windup_left > 0.0:
		_charge_windup_left = maxf(_charge_windup_left - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, charge_speed * 4.0 * delta)
		return
	if not _charging:
		_charging = true
		_charge_hit = false
		if _has_valid_target():
			_charge_direction = Vector2(signf(target.global_position.x - global_position.x), 0.0)
		else:
			_charge_direction = Vector2(_facing, 0.0)
	_charge_left = maxf(_charge_left - delta, 0.0)
	var variant := get_attack_variant()
	velocity.x = _charge_direction.x * charge_speed * (1.0 + (variant - 1) * 0.18)
	if not _charge_hit and _has_valid_target() and _distance_to_target() <= attack_range + 10.0:
		_charge_hit = true
		_damage_target(get_attack_damage() if variant <= 1 else maxi(int(roundf(get_attack_damage() * 1.4)), get_attack_damage() + 1))
		if variant >= 2:
			CombatFX.spawn(get_parent(), global_position + Vector2(0, -20), &"shockwave", telegraph_color, _facing, 64)
	if variant >= 2 and is_on_wall() and _charge_left > 0.05:
		_charge_left = 0.0
		if _motion != null:
			_motion.play(&"slam", 0.3)
		if is_inside_tree():
			CombatFX.spawn(get_parent(), global_position + Vector2(0, 0), &"shockwave", Color("e6a45f"), _facing, 88)
			CombatFX.spawn(get_parent(), global_position + Vector2(0, -18), &"dust", Color("b8a483"), _facing, 54)
		for enemy_target in get_tree().get_nodes_in_group("player"):
			if enemy_target.global_position.distance_to(global_position) < 92.0:
				enemy_target.take_damage(maxi(get_attack_damage() / 2, 1))
	if _charge_left <= 0.0:
		_finish_attack()
