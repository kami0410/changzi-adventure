class_name HostileBeam
extends Node2D

## A telegraphed line attack. The warning is long enough to react to; the
## actual beam is a short, bright flash rather than a lingering unfair hitbox.

var direction := Vector2.RIGHT
var length := 640.0
var width := 26.0
var delay := 0.72
var damage := 12
var tint := Color("b7e6f2")
var _time := 0.0
var _fired := false


static func launch(host: Node, origin: Vector2, heading: Vector2, beam_length: float, beam_width: float, warning_time: float, amount: int) -> HostileBeam:
	var beam := HostileBeam.new()
	beam.direction = heading.normalized()
	beam.length = beam_length
	beam.width = beam_width
	beam.delay = maxf(warning_time, 0.2)
	beam.damage = amount
	host.add_child(beam)
	beam.global_position = origin
	beam.rotation = beam.direction.angle()
	return beam


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 6
	add_to_group("hostile_hazards")


func _physics_process(delta: float) -> void:
	_time += delta
	if not _fired and _time >= delay:
		_fired = true
		_strike()
	if _time >= delay + 0.32:
		queue_free()
	queue_redraw()


func _strike() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Node2D
		if player == null:
			continue
		var offset := player.global_position + Vector2(0, -18) - global_position
		var along := offset.dot(direction)
		var perpendicular := absf(offset.cross(direction))
		if along >= -12.0 and along <= length + width && perpendicular <= width * 0.5 + 12.0:
			player.take_damage(damage, global_position)
	if is_inside_tree():
		CombatFX.spawn(get_parent(), global_position + direction * length * 0.35, &"beam_impact", tint, 1.0, 70)
		CombatFX.spawn(get_parent(), global_position + direction * length * 0.82, &"beam_impact", tint, 1.0, 54)


func _draw() -> void:
	var charge := clampf(_time / delay, 0.0, 1.0)
	var visible_length := length * charge
	# Targeting filament.
	draw_line(Vector2.ZERO, Vector2(visible_length, 0), Color(tint, 0.24 + charge * 0.35), 1.0 + charge * 1.5)
	for index in 12:
		var x := length * float(index) / 12.0
		if x > visible_length:
			break
		draw_line(Vector2(x, -5), Vector2(x, 5), Color(tint, 0.25 + charge * 0.4), 1.0)
	draw_circle(Vector2.ZERO, 4.0 + charge * 4.0, Color(tint, 0.6))
	if not _fired:
		draw_line(Vector2.ZERO, Vector2(visible_length, 0), Color(1, 1, 1, 0.18 * charge), 1.0)
		return
	var flash := clampf(1.0 - (_time - delay) / 0.32, 0.0, 1.0)
	draw_line(Vector2.ZERO, Vector2(length, 0), Color(tint, 0.45 * flash), width * 1.8)
	draw_line(Vector2.ZERO, Vector2(length, 0), Color(tint.lightened(0.35), 0.85 * flash), width)
	draw_line(Vector2.ZERO, Vector2(length, 0), Color(1, 1, 1, 0.95 * flash), maxf(width * 0.22, 2.0))
	for index in 7:
		var x := fposmod(index * length / 7.0 + _time * 900.0, length)
		draw_circle(Vector2(x, sin(index * 2.1 + _time * 30.0) * width * 0.5), 2.5 * flash, Color(1, 1, 1, 0.7 * flash))
