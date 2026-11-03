class_name RangedEnemy
extends Enemy

## 远程敌人（抄写虫）：保持距离，前摇后向目标射出一道墨线。
## 前摇结束发射可躲避的墨弹。

@export var shoot_range: float = 300.0
@export var keep_distance: float = 170.0
@export var tracer_color: Color = Color(0.72, 0.95, 0.78, 0.9)
@export var burst_count: int = 3
@export var charged_every: int = 3

var _has_shot: bool = false


func _ready() -> void:
	attack_variant_count = maxi(burst_count, 1)
	super._ready()


func _on_state_entered(previous: StringName, next: StringName) -> void:
	super._on_state_entered(previous, next)
	if next == STATE_ATTACK:
		_has_shot = false
		if get_attack_variant() >= maxi(charged_every, 1):
			_attack_windup_left = attack_windup * 1.3
			_attack_left = attack_windup * 1.3 + attack_recovery
			if _motion != null:
				_motion.play(&"cast", attack_windup * 1.3)


func _chase_behavior(_delta: float) -> void:
	if not _has_valid_target():
		change_state(STATE_IDLE)
		return
	var distance := _distance_to_target()
	if distance > deaggro_range:
		change_state(STATE_IDLE)
		return
	if distance < keep_distance:
		var retreat_x := global_position.x - target.global_position.x
		velocity.x = signf(retreat_x) * get_move_speed()
		_face_direction(-retreat_x)
		return
	_face_direction(target.global_position.x - global_position.x)
	if distance <= shoot_range:
		velocity.x = 0.0
		if _attack_cooldown_left <= 0.0:
			change_state(STATE_ATTACK)
		return
	_move_toward_target(get_move_speed())


func _perform_attack() -> void:
	if _has_shot or not _has_valid_target():
		return
	_has_shot = true
	if _distance_to_target() > shoot_range + 24.0:
		return
	var variant := get_attack_variant()
	var origin := global_position + Vector2(0, -30)
	var heading := origin.direction_to(target.global_position + Vector2(0, -24))
	var shots := 1
	if variant >= 2:
		shots = 2
	if variant >= maxi(charged_every, 1):
		shots = 3
	if is_inside_tree():
		for index in shots:
			var offset := 0.0
			if shots > 1:
				offset = lerpf(-0.18, 0.18, float(index) / float(shots - 1))
			var bolt := HostileBolt.launch(get_parent(), origin, heading.rotated(offset), get_attack_damage(), 260 + variant * 18)
			bolt.tint = tracer_color
			if variant >= maxi(charged_every, 1):
				bolt.scale = Vector2(1.45, 1.45)
				bolt.damage = maxi(int(roundf(bolt.damage * 1.35)), bolt.damage + 1)
		CombatFX.spawn(get_parent(), origin, &"beam_impact" if variant >= charged_every else &"cast", tracer_color, _facing, 32)
	else:
		_damage_target(get_attack_damage())


func _finish_attack() -> void:
	super._finish_attack()
	if get_attack_variant() >= maxi(charged_every, 1):
		_attack_cooldown_left *= 1.4
