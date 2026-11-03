extends Node2D

var _time := 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var glow := 0.35 + 0.15 * sin(_time * 1.7)
	draw_circle(Vector2(0, -8), 26.0, Color(0.43, 0.87, 0.78, 0.07 * glow))
	draw_circle(Vector2(0, -8), 7.0, Color(0.55, 0.95, 0.84, glow))
	draw_line(Vector2(0, 0), Vector2(0, -2), Color(0.1, 0.2, 0.22), 2.0)
