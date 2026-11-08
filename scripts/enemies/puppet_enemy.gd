class_name PuppetEnemy
extends Enemy

## 提线笑偶：被看不见的线吊着走。蓄力时屈膝，随后被猛地提起、扑向玩家
## 落点并砸地：落点一圈震荡 + 向两侧弹出两片面具碎片。起跳时落点已定，
## 看到它屈膝就横向翻滚。

@export var leap_height: float = 520.0
## Safety timeout for the leap if it never lands (pushed off a ledge).
@export var leap_time: float = 1.2
@export var slam_radius: float = 86.0
@export var shard_speed: float = 260.0
@export var shard_tint: Color = Color("e8dcc4")

var _leaping := false
var _airborne := false
var _slammed := false


func _on_state_entered(previous: StringName, next: StringName) -> void:
	super._on_state_entered(previous, next)
	if next == STATE_ATTACK:
		_leaping = false
		_airborne = false
		_slammed = false
		_attack_left = attack_windup + leap_time + attack_recovery + 0.4


func _attack_behavior(delta: float) -> void:
	_attack_windup_left = maxf(_attack_windup_left - delta, 0.0)
	_attack_left = maxf(_attack_left - delta, 0.0)
	if _attack_windup_left > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		return
	if not _leaping:
		_leaping = true
		var dx := 0.0
		if _has_valid_target():
			dx = clampf(target.global_position.x - global_position.x, -320.0, 320.0)
			_face_direction(dx)
		var airtime := 2.0 * leap_height / maxf(gravity, 1.0)
		velocity = Vector2(dx / airtime, -leap_height)
		return
	if not is_on_floor():
		_airborne = true
	elif _airborne and not _slammed:
		_slammed = true
		velocity.x = 0.0
		_slam()
	if _slammed:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		_attack_left = minf(_attack_left, attack_recovery)
	if _attack_left <= 0.0:
		_finish_attack()


func _slam() -> void:
	if not is_inside_tree():
		return
	VFX.spawn(get_parent(), &"land_heavy", global_position, false, 1.0)
	CombatFX.spawn(get_parent(), global_position + Vector2(0, -6), &"shockwave", telegraph_color, _facing, slam_radius)
	if _has_valid_target() and _distance_to_target() <= slam_radius:
		_damage_target(get_attack_damage())
	for side in [-1.0, 1.0]:
		var bolt := HostileBolt.launch(get_parent(), global_position + Vector2(side * 16.0, -14),
			Vector2(side, -0.12).normalized(), maxi(int(roundf(get_attack_damage() * 0.6)), 1), shard_speed)
		bolt.tint = shard_tint
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.call("play_sfx", &"puppet_slam")


func creature_phase() -> StringName:
	return &"windup" if _attack_windup_left > 0.0 else &"attack"
