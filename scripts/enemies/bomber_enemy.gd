class_name BomberEnemy
extends Enemy

## 墨囊投手：保持中距离，向玩家脚下抛出会延迟爆炸的墨囊。
## 变体：单发 / 双发夹击 / 大墨囊留下污染池。

@export var throw_range: float = 380.0
@export var keep_distance: float = 170.0
@export var bomb_radius: float = 74.0
@export var arc_time: float = 0.85


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
	if distance <= throw_range:
		velocity.x = move_toward(velocity.x, 0.0, get_move_speed() * 5.0)
		if _attack_cooldown_left <= 0.0:
			change_state(STATE_ATTACK)
		return
	_move_toward_target(get_move_speed())


func _perform_attack() -> void:
	if not _has_valid_target() or not is_inside_tree():
		return
	var variant := get_attack_variant()
	var target_point := target.global_position
	var damage := maxi(int(roundf(get_attack_damage() * 0.9)), 1)
	if variant <= 1:
		InkBomb.launch(get_parent(), global_position + Vector2(0, -42), target_point, damage, bomb_radius, arc_time)
		CombatFX.spawn(get_parent(), global_position + Vector2(0, -44), &"cast", Color("8fcbb0"), _facing, 34)
	elif variant == 2:
		for offset in [-58.0, 58.0]:
			InkBomb.launch(get_parent(), global_position + Vector2(0, -42), target_point + Vector2(offset, 0), damage, bomb_radius, arc_time)
		CombatFX.spawn(get_parent(), global_position + Vector2(0, -44), &"cast", Color("d8b36a"), _facing, 54)
	else:
		InkBomb.launch(get_parent(), global_position + Vector2(0, -48), target_point, maxi(int(roundf(damage * 1.5)), damage + 1), bomb_radius * 1.5, arc_time * 1.15, true)
		CombatFX.spawn(get_parent(), global_position + Vector2(0, -50), &"cast", Color("b58be8"), _facing, 76)


func _finish_attack() -> void:
	super._finish_attack()
	if get_attack_variant() == 3:
		_attack_cooldown_left *= 1.5
