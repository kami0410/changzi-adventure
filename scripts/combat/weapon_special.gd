class_name WeaponSpecial
extends RefCounted

## The six demo weapons differ by behaviour, not only numbers. Pure helpers so
## tests can prove each special without spawning a full swing or projectile.

static func damage_multiplier(special_id: StringName, combo_index: int) -> float:
	if special_id == &"page_ripple" and combo_index % 3 == 0:
		return 1.5
	return 1.0


static func projectile_count(special_id: StringName) -> int:
	return 3 if special_id == &"echo_shot" else 1


static func projectile_pierce(special_id: StringName) -> int:
	return 3 if special_id == &"ink_pierce" else 1


static func on_hit(special_id: StringName, attacker: Node2D, target: Node) -> void:
	if target == null or not is_instance_valid(target):
		return
	match special_id:
		&"chain_pull":
			if target.has_method("apply_knockback"):
				var direction := Vector2.ZERO
				if attacker != null and is_instance_valid(attacker):
					direction = attacker.global_position - (target as Node2D).global_position
				target.call("apply_knockback", direction.normalized() * 260.0, 0.18)
		&"ink_break":
			if target.has_method("apply_stun"):
				target.call("apply_stun", 0.35)
		&"talisman_mark":
			if target.has_method("apply_slow"):
				target.call("apply_slow", 0.6, 2.0)
			if target.has_method("set_meta"):
				target.set_meta(&"talisman_mark", 2.0)
