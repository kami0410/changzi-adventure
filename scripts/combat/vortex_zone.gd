class_name VortexZone
extends Node2D

## Time-abyss trap: a visible, persistent field that slows and damages whatever
## stays inside. It is placed by the "time / abyss" style of phrase.

var radius: float = 170.0
var damage: int = 4
var lifetime: float = 4.0
var elapsed: float = 0.0
var tick: float = 0.0
var tint := Color("8f8be8")
var enemies: Array[Enemy] = []

static func create(host: Node, at: Vector2, size: float, amount: int, duration: float) -> VortexZone:
	var zone := VortexZone.new()
	zone.radius = size
	zone.damage = maxi(amount, 1)
	zone.lifetime = duration
	host.add_child(zone)
	zone.global_position = at
	return zone

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 3
	add_to_group("hostile_hazards")

func _process(delta: float) -> void:
	elapsed += delta
	tick -= delta
	if elapsed >= lifetime:
		queue_free()
		return
	if tick <= 0.0:
		tick = 0.6
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy is Enemy and not enemy.dead and global_position.distance_to(enemy.global_position) <= radius:
				enemy.take_damage(damage)
	queue_redraw()

func _draw() -> void:
	var fade := clampf(1.0 - elapsed / lifetime, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(tint, 0.09 * fade))
	for i in 3:
		var offset := fmod(elapsed * 40.0 + i * 28.0, radius)
		draw_arc(Vector2.ZERO, maxf(radius - offset, 4.0), 0, TAU, 48, Color(tint, 0.35 * fade), 2.0)
	for i in 10:
		var angle := i * TAU / 10.0 + elapsed * 1.2
		var point := Vector2.from_angle(angle) * radius * (0.25 + 0.55 * fposmod(i + elapsed, 1.0))
		draw_circle(point, 3.0, Color(tint, 0.6 * fade))
