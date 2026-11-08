class_name KamikazeEnemy
extends FlyerEnemy

## 墨火：漂浮的鬼火，锁定后加速扑向玩家，贴身后闪烁蓄力并自爆。
## 爆炸前有明显的闪烁与扩张警示圈，翻滚或拉开距离即可躲开；自爆也会伤到附近敌人。

@export var rush_speed: float = 300.0
@export var fuse_time: float = 0.55
@export var blast_radius: float = 96.0
@export var blast_tint: Color = Color("8fe8dc")

var _fuse_left := -1.0


func _chase_behavior(_delta: float) -> void:
	if not _has_valid_target():
		change_state(STATE_IDLE)
		return
	var distance := _distance_to_target()
	if distance > deaggro_range:
		change_state(STATE_IDLE)
		return
	if distance <= attack_range:
		change_state(STATE_ATTACK)
		return
	var goal := target.global_position + Vector2(0, -30)
	var to_goal := global_position.direction_to(goal)
	velocity = velocity.lerp(to_goal * rush_speed * speed_multiplier, 0.08)
	_face_direction(to_goal.x)


func _on_state_entered(previous: StringName, next: StringName) -> void:
	super._on_state_entered(previous, next)
	if next == STATE_ATTACK:
		_fuse_left = fuse_time
		if is_inside_tree():
			CombatFX.spawn(get_parent(), global_position, &"telegraph", blast_tint, _facing, blast_radius)


func _attack_behavior(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	_fuse_left -= delta
	if sprite_visual != null and is_instance_valid(sprite_visual):
		var blink := 1.0 + 1.2 * absf(sin(_fuse_left * 30.0))
		sprite_visual.modulate = sprite_base_modulate * Color(blink, blink, blink, 1.0)
	if _fuse_left <= 0.0:
		_explode()


func _explode() -> void:
	if dead:
		return
	if is_inside_tree():
		VFX.spawn(get_parent(), &"mana_burst", global_position + Vector2(0, 20), false, 0.8)
		var audio := get_node_or_null("/root/Audio")
		if audio != null:
			audio.call("play_sfx", &"wisp_blast")
		CombatFX.spawn(get_parent(), global_position, &"shockwave", blast_tint, _facing, blast_radius)
		if _has_valid_target() and _distance_to_target() <= blast_radius:
			_damage_target(maxi(int(roundf(get_attack_damage() * 1.6)), 1))
		for node in get_tree().get_nodes_in_group("enemies"):
			if node != self and node is Enemy and not (node as Enemy).dead \
					and (node as Enemy).global_position.distance_to(global_position) <= blast_radius:
				(node as Enemy).take_damage(maxi(get_attack_damage(), 1))
	take_damage(health)


func creature_phase() -> StringName:
	return &"windup"
