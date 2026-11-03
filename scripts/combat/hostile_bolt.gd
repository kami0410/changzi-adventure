class_name HostileBolt
extends Area2D

## Line/arrow warning: direction is readable without colour.
const SHAPE := DangerShape.LINE

var direction := Vector2.LEFT
var speed := 260.0
var damage := 10
var lifetime := 4.0
var tint := Color("f3a57a")
var friendly := false
var _spent := false

static func launch(host: Node, origin: Vector2, heading: Vector2, amount: int, velocity: float = 260.0, is_friendly: bool = false) -> HostileBolt:
	var bolt := HostileBolt.new()
	bolt.direction = heading.normalized()
	bolt.damage = amount
	bolt.speed = velocity
	bolt.friendly = is_friendly
	host.add_child(bolt)
	bolt.global_position = origin
	return bolt

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("hostile_hazards")
	collision_layer = 0
	collision_mask = 2 if friendly else 1
	z_index = 7
	if friendly:
		tint = Color("8fe0c1")
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	collider.shape = shape
	add_child(collider)
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	position += direction * speed * delta
	rotation = direction.angle()
	queue_redraw()

func _on_body(body: Node) -> void:
	if _spent:
		return
	_spent = true
	if friendly:
		if body is Enemy and not body.dead:
			body.take_damage(damage)
	elif body.is_in_group("player"):
		body.take_damage(damage, global_position)
	CombatFX.spawn(get_parent(), global_position, &"hit", tint, 1.0, 24)
	queue_free()

func _draw() -> void:
	draw_line(Vector2(-24, 0), Vector2.ZERO, Color(tint, 0.3), 5)
	draw_polygon(PackedVector2Array([Vector2(10, 0), Vector2(-3, -6), Vector2(-9, 0), Vector2(-3, 6)]), PackedColorArray([tint]))
	draw_line(Vector2(-5, 0), Vector2(6, 0), Color("fff1d0"), 2)
