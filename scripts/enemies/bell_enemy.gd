class_name BellEnemy
extends MeleeEnemy

## 锈钟兵：钟头的佝偻士兵，挥动挂满小铃的钟杖。第三击「鸣钟」不看朝向：
## 举杖蓄力后整圈震荡，背后也打得到，看到举杖就翻滚出圈或拉开距离。

@export var toll_radius: float = 118.0
@export var toll_tint: Color = Color("c9a66b")


func _perform_attack() -> void:
	if get_attack_variant() < 3:
		super._perform_attack()
		return
	if is_inside_tree():
		VFX.spawn(get_parent(), &"smash", global_position + Vector2(0, -6), _facing < 0.0, 1.1)
		CombatFX.spawn(get_parent(), global_position + Vector2(0, -20), &"shockwave", toll_tint, _facing, toll_radius)
		var audio := get_node_or_null("/root/Audio")
		if audio != null:
			audio.call("play_sfx", &"bell_toll")
	if _has_valid_target() and _distance_to_target() <= toll_radius:
		_damage_target(maxi(int(roundf(get_attack_damage() * 1.4)), get_attack_damage() + 1))
