class_name PageThrowerEnemy
extends RangedEnemy

## 溺亡书记：抱着泡烂的书页，后撤到中距离后把湿页扇形甩出。
## 普通一扇 3 页，每第 3 次蓄力更久、甩出 5 页，页面飞得慢，可以从缝里穿过去。

@export var page_speed: float = 210.0
@export var fan_spread: float = 0.5


func _perform_attack() -> void:
	if _has_shot or not _has_valid_target():
		return
	_has_shot = true
	if not is_inside_tree():
		_damage_target(get_attack_damage())
		return
	var heavy := get_attack_variant() >= maxi(charged_every, 1)
	var origin := global_position + Vector2(_facing * 18.0, -40)
	var heading := origin.direction_to(target.global_position + Vector2(0, -24))
	var count := 5 if heavy else 3
	var spread := fan_spread * (1.3 if heavy else 1.0)
	for i in count:
		var angle := lerpf(-spread, spread, float(i) / float(count - 1))
		var bolt := HostileBolt.launch(get_parent(), origin, heading.rotated(angle),
			maxi(int(roundf(get_attack_damage() * 0.75)), 1), page_speed)
		bolt.tint = tracer_color
	CombatFX.spawn(get_parent(), origin, &"cast", tracer_color, _facing, 36)
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.call("play_sfx", &"page_fan")
