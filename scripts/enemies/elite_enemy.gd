class_name EliteEnemy
extends Enemy

## 精英敌人（错字兽）：远距离也会用冲击波起手，近身则重击。
## 每第三次攻击改为范围冲击波，作为“额外攻击”。

@export var slam_range: float = 100.0
@export var shockwave_range: float = 340.0
@export var shockwave_color: Color = Color(0.92, 0.25, 0.32, 0.85)

var _attack_index: int = 0


func _ready() -> void:
	attack_variant_count = 4
	super._ready()


func _chase_behavior(_delta: float) -> void:
	if not _has_valid_target():
		change_state(STATE_IDLE)
		return
	var distance := _distance_to_target()
	if distance > deaggro_range:
		change_state(STATE_IDLE)
		return
	if distance <= shockwave_range:
		if _attack_cooldown_left <= 0.0:
			_face_direction(target.global_position.x - global_position.x)
			change_state(STATE_ATTACK)
			return
		if distance > slam_range:
			_move_toward_target(get_move_speed())
		else:
			velocity.x = 0.0
		return
	_move_toward_target(get_move_speed())


func _perform_attack() -> void:
	if not _has_valid_target():
		return
	_attack_index += 1
	var distance := _distance_to_target()
	var variant := get_attack_variant()
	match variant:
		2:
			if distance <= shockwave_range:
				_damage_target(maxi(int(roundf(get_attack_damage() * 0.65)), 1))
				_spawn_shockwave()
				if _motion != null:
					_motion.play(&"slam", 0.32)
		3:
			# Ink rain: three delayed impacts around the target.
			if is_inside_tree():
				for index in 3:
					var offset := (index - 1) * 68.0
					InkWarning.create(get_parent(), Vector2(target.global_position.x + offset, global_position.y), maxi(int(roundf(get_attack_damage() * 0.7)), 1))
				CombatFX.spawn(get_parent(), global_position + Vector2(0, -40), &"cast", Color("e07a86"), _facing, 100)
		4:
			# Leap slam: close distance, then a heavy ground burst.
			if distance > slam_range:
				velocity.x = signf(target.global_position.x - global_position.x) * 380.0
			_damage_target(maxi(int(roundf(get_attack_damage() * 1.25)), get_attack_damage() + 1))
			_spawn_shockwave()
			if is_inside_tree():
				CombatFX.spawn(get_parent(), global_position + Vector2(0, 2), &"shockwave", Color("f0b06e"), _facing, 130)
		_:
			if distance <= slam_range:
				_damage_target(get_attack_damage())
				if is_inside_tree():
					CombatFX.spawn(get_parent(), global_position + Vector2(0, -20), &"slash", Color("f08a7a"), _facing, slam_range + 18)
			elif distance <= shockwave_range:
				_damage_target(maxi(int(roundf(get_attack_damage() * 0.45)), 1))
				_spawn_shockwave()


func _finish_attack() -> void:
	super._finish_attack()
	if get_attack_variant() == 4:
		_attack_cooldown_left *= 1.35


func _spawn_shockwave() -> void:
	if not is_inside_tree():
		return
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = shockwave_color
	var points := PackedVector2Array()
	var radius := 24.0
	for index in 25:
		var angle := TAU * float(index) / 24.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = points
	add_child(ring)
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector2(6.0, 6.0), 0.28)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.28)
	tween.tween_callback(ring.queue_free)
