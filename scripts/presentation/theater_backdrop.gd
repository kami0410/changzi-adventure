class_name TheaterBackdrop
extends Node2D

## The fourth chapter's stage. Drawn procedurally because Magpie image credits
## were exhausted; the archive texture underneath supplies the walls while this
## adds curtains, seats, paper audience, footlights and a moving spotlight.

@export var world_width: float = 8400.0
@export var generated_art: bool = false
var _time := 0.0
var _camera: Camera2D
var _base_x := 0.0

func _ready() -> void:
	z_index = -9
	_camera = get_viewport().get_camera_2d()
	_base_x = get_parent().global_position.x
	var far := get_parent().get_node_or_null("BackgroundArt") as Sprite2D
	if far != null:
		far.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		far.modulate = Color(0.78, 0.74, 0.76) if generated_art else Color(0.55, 0.28, 0.33)
	_far = far

var _far: Sprite2D

func _process(delta: float) -> void:
	_time += delta
	# The level is moved to its chapter slot after this node's _ready, so the
	# offset must be read live (it was stuck at 0 and the stage drew off-screen).
	_base_x = get_parent().global_position.x
	if _camera == null:
		_camera = get_viewport().get_camera_2d()
	if _far != null and _camera != null:
		var view_width := get_viewport_rect().size.x / _camera.zoom.x
		var center_x := _camera.get_screen_center_position().x - _base_x
		# Only while the camera is on this chapter's stage: the far art must not
		# follow the camera into the other chapters (it covered them in 0.8).
		var on_stage := center_x >= -view_width * 0.5 and center_x <= world_width + view_width * 0.5
		_far.visible = on_stage
		visible = on_stage
		if not on_stage:
			return
		var coverage := maxf(view_width / _far.texture.get_width() + 0.16, 1.0)
		_far.scale = Vector2.ONE * coverage
		# Follow the camera across the whole 12000 px stage.
		var left := clampf(center_x - view_width * 0.5, 0.0, world_width)
		_far.position = Vector2(center_x - (left / maxf(world_width, 1.0) - 0.5) * 90.0, 340.0)
	queue_redraw()

func _draw() -> void:
	var left := 0.0
	var right := world_width
	if _camera != null:
		var view_width := get_viewport_rect().size.x / _camera.zoom.x
		left = clampf(_camera.get_screen_center_position().x - _base_x - view_width * 0.5 - 200.0, 0.0, world_width)
		right = clampf(left + view_width + 400.0, 0.0, world_width)
	if generated_art:
		var generated_center := (left + right) * 0.5 + sin(_time * 0.25) * 120.0
		draw_polygon(PackedVector2Array([Vector2(generated_center - 26, 0), Vector2(generated_center + 26, 0), Vector2(generated_center + 220, 520), Vector2(generated_center - 220, 520)]), PackedColorArray([Color(0.55, 0.85, 0.78, 0.045)]))
		draw_oval(Vector2(generated_center, 522), 240, 34, Color(0.5, 0.9, 0.8, 0.08))
		for i in 30:
			var x := fposmod(i * 211.0 + _time * (8.0 + i % 4), right - left) + left
			var y := 80.0 + fposmod(i * 71.0, 420.0) + sin(_time * 0.8 + i) * 14.0
			draw_rect(Rect2(x, y, 5, 3), Color(0.86, 0.8, 0.68, 0.22))
		return
	# Deep back wall bands.
	draw_rect(Rect2(left, 0, right - left, 560), Color(0.045, 0.025, 0.045, 0.45))
	for i in range(int(left / 360) - 1, int(right / 360) + 2):
		var x := i * 360.0 + 180.0
		draw_rect(Rect2(x - 74, 270, 148, 250), Color(0.055, 0.03, 0.05, 0.32))
		draw_rect(Rect2(x - 68, 278, 136, 236), Color(0.22, 0.05, 0.09, 0.28))
		draw_rect(Rect2(x - 68, 278, 136, 8), Color(0.42, 0.26, 0.14, 0.6))
		draw_line(Vector2(x - 68, 278), Vector2(x, 206), Color(0.42, 0.26, 0.14, 0.5), 3.0)
		draw_line(Vector2(x, 206), Vector2(x + 68, 278), Color(0.42, 0.26, 0.14, 0.5), 3.0)
		for fold in 3:
			var fx := x - 52 + fold * 34.0
			draw_line(Vector2(fx, 286), Vector2(fx + 8, 514), Color(0.34, 0.07, 0.11, 0.35), 2.0)
		draw_circle(Vector2(x, 476), 9.0, Color(0.55, 0.5, 0.44, 0.5))
	# Seats and paper audience.
	for row in 3:
		var y := 414.0 + row * 44.0
		for i in range(int(left / 78) - 1, int(right / 78) + 2):
			var x := i * 78.0 + (row % 2) * 18.0
			if x < left - 80 or x > right + 80:
				continue
			var seat := Color(0.11, 0.045, 0.07, 0.85 - row * 0.16)
			draw_rect(Rect2(x - 24, y, 48, 30), seat)
			draw_rect(Rect2(x - 18, y - 14, 36, 18), seat.lightened(0.05))
			draw_circle(Vector2(x, y - 18), 8.0, Color(0.55, 0.5, 0.44, 0.55 - row * 0.1))
			draw_rect(Rect2(x - 4, y - 19, 2, 2), Color(0.13, 0.05, 0.06, 0.8))
			draw_rect(Rect2(x + 2, y - 19, 2, 2), Color(0.13, 0.05, 0.06, 0.8))
	# Stage lip and footlights.
	draw_rect(Rect2(left, 520, right - left, 16), Color(0.18, 0.07, 0.09, 0.95))
	draw_rect(Rect2(left, 536, right - left, 30), Color(0.07, 0.035, 0.05, 0.95))
	for i in range(int(left / 96) - 1, int(right / 96) + 2):
		var x := i * 96.0 + 24.0
		draw_circle(Vector2(x, 516), 3.0, Color(1.0, 0.72, 0.45, 0.7))
		draw_circle(Vector2(x, 516), 10.0, Color(1.0, 0.55, 0.3, 0.07))
	# Curtains: vertical drapes and a torn valance.
	for i in range(int(left / 720) - 1, int(right / 720) + 2):
		var x := i * 720.0 + 360.0
		draw_polygon(PackedVector2Array([Vector2(x - 150, 0), Vector2(x - 70, 0), Vector2(x - 95, 420), Vector2(x - 150, 420)]), PackedColorArray([Color(0.26, 0.04, 0.08, 0.9)]))
		draw_polygon(PackedVector2Array([Vector2(x + 70, 0), Vector2(x + 150, 0), Vector2(x + 150, 420), Vector2(x + 95, 420)]), PackedColorArray([Color(0.22, 0.03, 0.07, 0.9)]))
		for fold in 4:
			var fx := x - 145 + fold * 18.0
			draw_line(Vector2(fx, 0), Vector2(fx + 12, 420), Color(0.38, 0.08, 0.12, 0.35), 2.0)
	# Spotlight cone and moving dust.
	var center := (left + right) * 0.5 + sin(_time * 0.25) * 120.0
	draw_polygon(PackedVector2Array([Vector2(center - 26, 0), Vector2(center + 26, 0), Vector2(center + 210, 520), Vector2(center - 210, 520)]), PackedColorArray([Color(0.55, 0.85, 0.78, 0.055)]))
	draw_oval(Vector2(center, 522), 230, 34, Color(0.5, 0.9, 0.8, 0.09))
	for i in 26:
		var x := fposmod(i * 211.0 + _time * (9.0 + i % 4), right - left) + left
		var y := 90.0 + fposmod(i * 71.0, 400.0) + sin(_time * 0.8 + i) * 12.0
		draw_rect(Rect2(x, y, 5, 3), Color(0.86, 0.8, 0.68, 0.22))
	# Broken chandelier.
	var chandelier_x := (left + right) * 0.5 + sin(_time * 0.18) * 30.0
	draw_line(Vector2(chandelier_x, 0), Vector2(chandelier_x, 92), Color(0.3, 0.25, 0.18, 0.8), 3.0)
	draw_arc(Vector2(chandelier_x, 112), 62, 0.2, TAU - 0.35, 30, Color(0.44, 0.35, 0.22, 0.8), 5.0)
	for i in 7:
		var angle := 0.35 + i * 0.38
		var p := Vector2(chandelier_x, 112) + Vector2.from_angle(angle) * 62
		draw_line(p, p + Vector2(0, 18), Color(0.4, 0.32, 0.2, 0.7), 2.0)
		draw_circle(p + Vector2(0, 22), 2.5, Color(1.0, 0.8, 0.5, 0.8))

func draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var angle := i * TAU / 32.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)
