class_name RangedWeapon
extends Weapon

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/projectile.tscn")

@export var muzzle_offset: float = 20.0
@export var target: Node2D


func _perform_attack() -> void:
	if data == null or not is_inside_tree():
		return

	var direction := attack_direction
	if target != null and is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	direction = direction.normalized()

	var host: Node = get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		host = self
	var count := WeaponSpecial.projectile_count(data.special_id)
	for index in count:
		var spread := 0.0
		if count > 1:
			spread = deg_to_rad((float(index) - float(count - 1) * 0.5) * 8.0)
		_spawn_projectile(host, direction.rotated(spread), 0.6 if count > 1 else 1.0)


func _spawn_projectile(host: Node, direction: Vector2, damage_scale: float) -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as Projectile
	if projectile == null:
		return
	projectile.damage = maxi(int(round(
		float(data.damage) * damage_scale * damage_dealt_multiplier)), 1)
	projectile.speed = data.projectile_speed
	projectile.direction = direction
	projectile.pierce = WeaponSpecial.projectile_pierce(data.special_id)
	if data.projectile_speed > 0.0:
		projectile.lifetime = maxf(data.attack_range / data.projectile_speed, 0.05)
	var special := data.special_id
	projectile.hit.connect(func(victim: Node) -> void:
		WeaponSpecial.on_hit(special, self, victim)
		hit.emit(victim)
	)
	host.add_child(projectile)
	projectile.global_position = global_position + direction * muzzle_offset
