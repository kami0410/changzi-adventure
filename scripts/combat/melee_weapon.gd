class_name MeleeWeapon
extends Weapon

const HITBOX_SCENE: PackedScene = preload("res://scenes/combat/hitbox.tscn")

@export var hitbox_duration: float = 0.12
@export var hitbox_height: float = 40.0

var _swing_targets: Dictionary = {}
var _swing_index := 0


func _perform_attack() -> void:
	if data == null or not is_inside_tree():
		return
	_swing_index += 1

	var hitbox := HITBOX_SCENE.instantiate() as Area2D
	if hitbox == null:
		return

	var direction := attack_direction
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	direction = direction.normalized()

	_swing_targets.clear()
	hitbox.position = direction * (data.attack_range * 0.5)
	_resize_hitbox(hitbox, direction)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	add_child(hitbox)
	get_tree().create_timer(hitbox_duration, false).timeout.connect(hitbox.queue_free)


func _resize_hitbox(hitbox: Area2D, direction: Vector2) -> void:
	var shape_node := hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var length := maxf(data.attack_range, 24.0)
	var shape := RectangleShape2D.new()
	if absf(direction.x) >= absf(direction.y):
		shape.size = Vector2(length, hitbox_height)
	else:
		shape.size = Vector2(hitbox_height, length)
	shape_node.shape = shape


func _on_hitbox_body_entered(body: Node) -> void:
	_try_swing_hit(body)


func _on_hitbox_area_entered(area: Area2D) -> void:
	_try_swing_hit(area)
	_try_swing_hit(area.get_parent())


func special_damage_multiplier() -> float:
	var special := data.special_id if data != null else &""
	return WeaponSpecial.damage_multiplier(special, _swing_index)


func apply_hit(target: Node) -> void:
	super.apply_hit(target)
	if data != null:
		WeaponSpecial.on_hit(data.special_id, self, target)


func _try_swing_hit(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		return
	if _swing_targets.has(target):
		return
	if not target.has_method("take_damage"):
		return
	_swing_targets[target] = true
	apply_hit(target)
