class_name MeleeEnemy
extends Enemy

## 近战敌人（墨犬、失忆回声）：基类的 chase/attack 已经是近战逻辑，
## 这里补一个攻击前摇后的短突进，让贴近更有压迫感。

@export var lunge_speed: float = 150.0
@export var lunge_duration: float = 0.12
@export var combo_length: int = 3

var _lunge_left: float = 0.0


func _ready() -> void:
	attack_variant_count = maxi(combo_length, 1)
	super._ready()


func _on_state_entered(previous: StringName, next: StringName) -> void:
	super._on_state_entered(previous, next)
	if next == STATE_ATTACK:
		_lunge_left = lunge_duration
		var variant := get_attack_variant()
		if variant >= 3:
			_lunge_left = lunge_duration * 1.8
			_attack_windup_left = attack_windup * 1.25
			_attack_left = attack_windup * 1.25 + attack_recovery * 1.3
			if _motion != null:
				_motion.play(&"windup", attack_windup * 1.25)


func _attack_motion(delta: float) -> void:
	if _attack_windup_left > 0.0:
		super._attack_motion(delta)
		return
	_lunge_left = maxf(_lunge_left - delta, 0.0)
	if _lunge_left > 0.0:
		velocity.x = _facing * lunge_speed * (1.65 if get_attack_variant() >= 3 else 1.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, lunge_speed * 8.0 * delta)


func _perform_attack() -> void:
	if not _has_valid_target():
		return
	var variant := get_attack_variant()
	var reach := attack_range + (20.0 if variant >= 3 else 10.0)
	if _distance_to_target() > reach:
		return
	var damage := get_attack_damage()
	if variant >= 3:
		damage = maxi(int(roundf(damage * 1.5)), damage + 1)
		_damage_target(damage)
		if is_inside_tree():
			CombatFX.spawn(get_parent(), global_position + Vector2(0, 2), &"shockwave", telegraph_color, _facing, 72)
			CombatFX.spawn(get_parent(), global_position + Vector2(0, -24), &"slash", Color("f2ca75"), _facing, reach + 24)
	else:
		_damage_target(damage)
		if is_inside_tree():
			CombatFX.spawn(get_parent(), global_position + Vector2(0, -24), &"slash", telegraph_color, _facing, reach + 6)
func _finish_attack() -> void:
	super._finish_attack()
	if get_attack_variant() >= 3:
		_attack_cooldown_left *= 1.35
