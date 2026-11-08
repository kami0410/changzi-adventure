class_name FlyerEnemy
extends Enemy

## 飞行敌人（悬吊书吏）：不受重力，悬浮在目标上方，前摇后俯冲攻击。

@export var hover_height: float = 52.0
@export var dive_speed: float = 360.0
@export var dive_duration: float = 0.3
@export var dive_hit_range: float = 30.0
@export var bob_amplitude: float = 6.0
@export var bob_speed: float = 3.0

var _bob_time: float = 0.0
var _dive_direction: Vector2 = Vector2.DOWN
var _dive_hit: bool = false
var _diving: bool = false
var _feathers_fired: bool = false


func _ready() -> void:
	apply_gravity = false
	attack_variant_count = 3
	super._ready()


func _idle_behavior(delta: float) -> void:
	_bob_time += delta * bob_speed
	var drift := 0.0
	if patrol_radius > 0.0:
		if home == Vector2.INF:
			home = global_position
		var goal_x := home.x + sin(_bob_time * 0.35) * patrol_radius
		drift = clampf(goal_x - global_position.x, -1.0, 1.0) * get_move_speed() * 0.35
		if absf(drift) > 4.0:
			_face_direction(drift)
	velocity = Vector2(drift, sin(_bob_time) * bob_amplitude)
	if _has_valid_target() and _in_aggro_range():
		change_state(STATE_CHASE)


func _chase_behavior(_delta: float) -> void:
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
	var goal := target.global_position + Vector2(0.0, -hover_height)
	var direction := global_position.direction_to(goal)
	if direction.length_squared() > 0.0:
		velocity = direction * get_move_speed()
		_face_direction(direction.x)


func _on_state_entered(previous: StringName, next: StringName) -> void:
	super._on_state_entered(previous, next)
	if next == STATE_ATTACK:
		_diving = false
		_dive_hit = false
		_feathers_fired = false
		if get_attack_variant() == 2 and _motion != null:
			_motion.play(&"cast", attack_windup)


func _attack_behavior(delta: float) -> void:
	if not _has_valid_target():
		_finish_attack()
		return
	var variant := get_attack_variant()
	if _attack_windup_left > 0.0:
		_attack_windup_left = maxf(_attack_windup_left - delta, 0.0)
		velocity = Vector2.ZERO
		if variant == 2:
			_face_direction(target.global_position.x - global_position.x)
		return
	if variant == 2:
		if not _feathers_fired:
			_feathers_fired = true
			_fire_feathers()
		_finish_attack()
		return
	if not _diving:
		_diving = true
		_dive_hit = false
		_dive_direction = global_position.direction_to(target.global_position)
		_attack_left = dive_duration * (0.72 if variant >= 3 else 1.0)
		CombatFX.spawn(get_parent(), global_position, &"telegraph", telegraph_color, _facing, 46)
	var dive_multiplier := 1.55 if variant >= 3 else 1.0
	_attack_left = maxf(_attack_left - delta, 0.0)
	velocity = _dive_direction * dive_speed * dive_multiplier
	if not _dive_hit and _distance_to_target() <= dive_hit_range:
		_dive_hit = true
		_damage_target(get_attack_damage() if variant < 3 else maxi(int(roundf(get_attack_damage() * 1.35)), get_attack_damage() + 1))
		if variant >= 3:
			CombatFX.spawn(get_parent(), global_position, &"shockwave", telegraph_color, _facing, 56)
	if _attack_left <= 0.0 or _dive_hit:
		_finish_attack()


func _fire_feathers() -> void:
	if not is_inside_tree():
		return
	var origin := global_position + Vector2(0, 10)
	var base_heading := origin.direction_to(target.global_position + Vector2(0, -24))
	for index in 3:
		var offset := lerpf(-0.34, 0.34, float(index) / 2.0)
		var bolt := HostileBolt.launch(get_parent(), origin, base_heading.rotated(offset), maxi(int(roundf(get_attack_damage() * 0.8)), 1), 225)
		bolt.tint = Color("c9a3b8")
	CombatFX.spawn(get_parent(), origin, &"cast", Color("c9a3b8"), _facing, 46)
