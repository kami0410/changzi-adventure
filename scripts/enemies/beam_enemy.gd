class_name BeamEnemy
extends Enemy

## 镜面狙手：远距离锁定，先用细线预警，再发射可跳跃躲避的贯穿光束。
## 变体 1 单发；变体 2 双线夹击；变体 3 三线扇射。

@export var beam_range: float = 760.0
@export var keep_distance: float = 300.0
@export var beam_width: float = 26.0
@export var warning_time: float = 0.78
@export var beam_color: Color = Color("b7e6f2")


func _ready() -> void:
	attack_variant_count = 3
	super._ready()


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
	if distance <= beam_range:
		velocity.x = move_toward(velocity.x, 0.0, get_move_speed() * 5.0)
		if _attack_cooldown_left <= 0.0:
			change_state(STATE_ATTACK)
		return
	_move_toward_target(get_move_speed())


func _on_state_entered(previous: StringName, next: StringName) -> void:
	super._on_state_entered(previous, next)
	if next == STATE_ATTACK:
		var variant := get_attack_variant()
		_attack_windup_left = warning_time * (1.15 if variant >= 3 else 1.0)
		_attack_left = _attack_windup_left + 0.32
		if _motion != null:
			_motion.play(&"cast", _attack_windup_left)


func _perform_attack() -> void:
	if not _has_valid_target() or not is_inside_tree():
		return
	var origin := global_position + Vector2(0, -28)
	var base_direction := origin.direction_to(target.global_position + Vector2(0, -22))
	var variant := get_attack_variant()
	var beams := 1
	if variant == 2:
		beams = 2
	elif variant >= 3:
		beams = 3
	for index in beams:
		var offset := 0.0
		if beams > 1:
			offset = lerpf(-0.16, 0.16, float(index) / float(beams - 1))
		var beam := HostileBeam.launch(
			get_parent(),
			origin,
			base_direction.rotated(offset),
			beam_range,
			beam_width if variant < 3 else beam_width * 0.8,
			warning_time,
			get_attack_damage() if variant < 3 else maxi(int(roundf(get_attack_damage() * 0.8)), 1)
		)
		beam.tint = beam_color
	CombatFX.spawn(get_parent(), origin, &"cast", beam_color, _facing, 62)


func _finish_attack() -> void:
	super._finish_attack()
	_attack_cooldown_left *= 1.35
