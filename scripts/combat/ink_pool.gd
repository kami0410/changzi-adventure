class_name InkPool
extends Node2D

## Lingering ink puddle left by a large bomb. Deals small ticks and reads as
## an area-denial warning rather than instant punishment.

var damage := 4
var radius := 70.0
var lifetime := 4.0
var _time := 0.0
var _tick_left := 0.0


static func create(host: Node, at: Vector2, amount: int, size: float, duration: float) -> InkPool:
	var pool := InkPool.new()
	pool.damage = amount
	pool.radius = size
	pool.lifetime = duration
	host.add_child(pool)
	pool.global_position = at
	return pool


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 3
	add_to_group("hostile_hazards")


func _physics_process(delta: float) -> void:
	_time += delta
	_tick_left = maxf(_tick_left - delta, 0.0)
	if _time >= lifetime:
		queue_free()
		return
	if _tick_left <= 0.0:
		for node in get_tree().get_nodes_in_group("player"):
			var player := node as Node2D
			if player != null and player.global_position.distance_to(global_position) <= radius:
				player.take_damage(maxi(damage / 3, 1), global_position)
				_tick_left = 0.55
				break
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - clampf(_time / lifetime, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(0.02, 0.06, 0.06, 0.4 * fade))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 28, Color("8fceb0", 0.45 * fade), 2.0)
	for index in 9:
		var angle := index * TAU / 9.0 + _time * 0.7
		var point := Vector2.from_angle(angle) * radius * (0.3 + 0.55 * fposmod(index * 0.3, 1.0))
		draw_circle(point, 2.5 * fade, Color("8fceb0", 0.4 * fade))
