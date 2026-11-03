class_name InkBomb
extends Node2D

## Arcing ink bomb. It telegraphs the landing point, explodes on impact and
## optionally leaves a damaging ink pool for a few seconds.

var start := Vector2.ZERO
var target := Vector2.ZERO
var damage := 8
var blast_radius := 68.0
var flight_time := 0.85
var leaves_pool := false
var tint := Color("9de0c1")
var _time := 0.0
var _landed := false


static func launch(host: Node, from: Vector2, to: Vector2, amount: int, radius: float, time: float, pool: bool = false) -> InkBomb:
	var bomb := InkBomb.new()
	bomb.start = from
	bomb.target = to
	bomb.damage = amount
	bomb.blast_radius = radius
	bomb.flight_time = maxf(time, 0.2)
	bomb.leaves_pool = pool
	host.add_child(bomb)
	bomb.global_position = from
	return bomb


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 7
	add_to_group("hostile_hazards")


func _physics_process(delta: float) -> void:
	_time += delta
	if _landed:
		return
	var p := clampf(_time / flight_time, 0.0, 1.0)
	var flat := start.lerp(target, p)
	flat.y -= sin(p * PI) * 92.0
	global_position = flat
	if p >= 1.0:
		_explode()
	queue_redraw()


func _explode() -> void:
	_landed = true
	global_position = target
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Node2D
		if player != null and player.global_position.distance_to(target) <= blast_radius:
			player.take_damage(damage, target)
	if is_inside_tree():
		CombatFX.spawn(get_parent(), target, &"bomb", tint, 1.0, blast_radius)
		if leaves_pool:
			InkPool.create(get_parent(), target, maxi(damage / 2, 1), blast_radius * 1.15, 4.5)
	queue_free()


func _draw() -> void:
	var orb := 7.0 + sin(_time * 18.0) * 1.2
	draw_circle(Vector2.ZERO, orb + 5.0, Color(tint, 0.16))
	draw_circle(Vector2.ZERO, orb, Color(0.04, 0.08, 0.08, 0.95))
	draw_arc(Vector2.ZERO, orb + 2.5, 0, TAU, 18, Color(tint, 0.8), 1.5)
	draw_line(Vector2(-orb, -orb), Vector2(-orb - 7.0, -orb - 8.0), Color("f1d28a"), 2.0)
	draw_circle(Vector2(-orb - 7.0, -orb - 8.0), 2.4, Color("ffe7a6"))
	# Landing marker.
	var marker := to_local(target)
	draw_set_transform(Vector2.ZERO)
	draw_arc(marker, 9.0 + sin(_time * 8.0) * 2.0, 0, TAU, 18, Color(tint, 0.5), 1.5)
	draw_line(marker + Vector2(-6, 0), marker + Vector2(6, 0), Color(tint, 0.5), 1.0)
