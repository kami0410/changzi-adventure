class_name ScarfRibbon
extends Node2D

## Verlet-ish scarf/coattail. It lives in the player's local space and trails
## behind movement, giving the silhouette a second, softer motion layer.

const SEGMENTS := 9
const SEGMENT_LENGTH := 9.5

var direction := 1.0
var flow := 0.0
var tint := Color("7ed9cd")

var _points: Array[Vector2] = []
var _previous: Array[Vector2] = []
var _time := 0.0


func _ready() -> void:
	z_index = -1
	_points.resize(SEGMENTS)
	_previous.resize(SEGMENTS)
	for index in SEGMENTS:
		var point := Vector2(-index * SEGMENT_LENGTH, -58.0 + index * 2.2)
		_points[index] = point
		_previous[index] = point


func _process(delta: float) -> void:
	_time += delta
	var parent := get_parent() as CharacterBody2D
	var velocity := Vector2.ZERO
	var facing: float = 1.0
	if parent != null:
		velocity = parent.velocity
		facing = parent.facing.x
	direction = facing
	var anchor := Vector2(-facing * 12.0, -58.0)
	_points[0] = anchor
	_previous[0] = anchor
	for index in range(1, SEGMENTS):
		var current := _points[index]
		var previous := _previous[index]
		var velocity_point := (current - previous) * 0.86
		var target := _points[index - 1] + Vector2(-facing * SEGMENT_LENGTH, 2.4 + sin(_time * 3.0 + index * 0.7) * 0.9)
		var pull := (target - current) * (0.32 if index < 3 else 0.16)
		var drag := Vector2(-velocity.x * 0.0016 * (1.0 + flow), -velocity.y * 0.0012)
		var wind := Vector2(-facing * (1.2 + flow * 2.5), sin(_time * 2.0 + index) * 0.45)
		previous = current
		current += velocity_point + pull + drag + wind * delta * 60.0
		_points[index] = current
		_previous[index] = previous
	# Keep the chain from stretching.
	for index in range(1, SEGMENTS):
		var delta_vec := _points[index] - _points[index - 1]
		if delta_vec.length() > SEGMENT_LENGTH:
			_points[index] = _points[index - 1] + delta_vec.normalized() * SEGMENT_LENGTH
	queue_redraw()


func _draw() -> void:
	if _points.size() < SEGMENTS:
		return
	for index in range(SEGMENTS - 1):
		var a := _points[index]
		var b := _points[index + 1]
		var width_a := lerpf(7.5, 1.4, float(index) / SEGMENTS)
		var width_b := lerpf(7.5, 1.4, float(index + 1) / SEGMENTS)
		var normal := (b - a).normalized().orthogonal()
		var color := Color(tint, 0.86 - float(index) * 0.075)
		draw_colored_polygon(
			PackedVector2Array([a - normal * width_a, b - normal * width_b, b + normal * width_b, a + normal * width_a]),
			color
		)
		if index < SEGMENTS - 2:
			draw_line(a, b, Color(1.0, 0.95, 0.8, 0.22), 1.0)
	draw_circle(_points[SEGMENTS - 1], 2.2, Color(tint, 0.9))
