class_name Projectile
extends Area2D

signal hit(target: Node)

@export var speed: float = 600.0
@export var damage: int = 1
@export var direction: Vector2 = Vector2.RIGHT
@export var lifetime: float = 2.0
## Hits before the projectile disappears; demo bolt guns pierce three targets.
@export var pierce: int = 1

var _spent: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _spent:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	global_position += direction.normalized() * speed * delta


func hit_target(target: Node) -> bool:
	if _spent or target == null or not is_instance_valid(target):
		return false
	if not target.has_method("take_damage"):
		return false
	target.call("take_damage", damage)
	hit.emit(target)
	pierce -= 1
	if pierce <= 0:
		_spent = true
		queue_free()
	return true


func is_spent() -> bool:
	return _spent


func _on_body_entered(body: Node) -> void:
	hit_target(body)


func _on_area_entered(area: Area2D) -> void:
	# Hit the area (or its parent) once, never both on a piercing shot.
	if not hit_target(area):
		hit_target(area.get_parent())
