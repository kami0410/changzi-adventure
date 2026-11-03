class_name Weapon
extends Node2D

signal hit(target: Node)

@export var data: WeaponData
@export var attack_direction: Vector2 = Vector2.RIGHT

var cooldown_left: float = 0.0
## 连段/蓄力倍率；Player 每次攻击后重置，避免永久放大。
var damage_multiplier: float = 1.0


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)


func can_attack() -> bool:
	return data != null and cooldown_left <= 0.0


func try_attack() -> bool:
	if not can_attack():
		return false
	cooldown_left = maxf(data.attack_cooldown, 0.0)
	_perform_attack()
	return true


func apply_hit(target: Node) -> void:
	if data == null or target == null or not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return
	var damage := maxi(int(roundf(data.damage * damage_multiplier * special_damage_multiplier())), 1)
	target.call("take_damage", damage)
	if is_inside_tree():
		var audio := get_node_or_null("/root/Audio")
		if audio != null and audio.has_method("play_sfx"):
			audio.call("play_sfx", &"hit")
	hit.emit(target)


## Extra multiplier from a weapon's special identity; subclasses override.
func special_damage_multiplier() -> float:
	return 1.0


func _perform_attack() -> void:
	pass
