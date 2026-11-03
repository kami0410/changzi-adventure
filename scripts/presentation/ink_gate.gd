extends Node2D

var _time := 0.0
func _ready() -> void:
	get_parent().get_node("Visual").hide()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	queue_redraw()

func _draw() -> void:
	var intensity := 0.45 + 0.15 * sin(_time * 4.0)
	draw_rect(Rect2(-10, -260, 20, 520), Color(0.4, 0.13, 0.24, 0.18))
	for i in 3:
		var points := PackedVector2Array()
		for y in range(-260, 261, 16):
			points.append(Vector2(sin(y * 0.04 + _time * 3.0 + i * 2.0) * 7, y))
		draw_polyline(points, Color(0.85, 0.32, 0.4, intensity), 2.0)
	for i in 12:
		var y := fposmod(i * 44 - _time * 28, 520) - 260
		draw_rect(Rect2(-3, y, 6, 6), Color(1.0, 0.65, 0.55, 0.65))
