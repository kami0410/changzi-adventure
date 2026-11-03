class_name LivingBackdrop
extends Node2D

@export var world_width: float = 3840.0
@export var breathing: bool = false
@export var sea: bool = false
var _time := 0.0
var _far: Sprite2D
var _camera: Camera2D
var _motifs: Node2D
var _base_x := 0.0

func _ready() -> void:
	z_index = -8
	_far = get_parent().get_node_or_null("BackgroundArt") as Sprite2D
	_camera = get_viewport().get_camera_2d()
	_base_x = get_parent().global_position.x
	if _far != null:
		_far.scale = Vector2(1.0, 1.0)
		_far.position = Vector2(768, 340)
		_far.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_far.modulate = Color(0.36, 0.48, 0.54) if not breathing else Color(0.36, 0.47, 0.39)
		if sea:
			_far.modulate = Color(0.38, 0.46, 0.66)
	_motifs = Node2D.new()
	add_child(_motifs)
	for i in int(world_width / 420.0) + 1:
		if sea:
			var tower := Polygon2D.new()
			tower.position = Vector2(i * 420 + 210, 560)
			var height := 210.0 + (i % 3) * 68.0
			tower.polygon = PackedVector2Array([Vector2(-28, 0), Vector2(-22, -height), Vector2(-8, -height - 18), Vector2(6, -height), Vector2(24, 0)])
			tower.color = Color(0.035, 0.05, 0.1, 0.65)
			_motifs.add_child(tower)
			continue
		var pillar := Polygon2D.new()
		pillar.position = Vector2(i * 420 + 210, 560)
		pillar.polygon = PackedVector2Array([Vector2(-22, 0), Vector2(-16, -320), Vector2(-30, -324), Vector2(-28, -348), Vector2(28, -348), Vector2(30, -324), Vector2(16, -320), Vector2(22, 0)])
		pillar.color = Color(0.035, 0.065, 0.09, 0.6)
		_motifs.add_child(pillar)
	var dust := CPUParticles2D.new()
	dust.position = Vector2(world_width * 0.5, 320)
	dust.amount = 72
	dust.lifetime = 12.0
	dust.preprocess = 12.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(world_width * 0.5, 300)
	dust.direction = Vector2(-1, -0.3)
	dust.spread = 35.0
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = 10
	dust.initial_velocity_max = 24
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.8
	dust.color = Color(0.5, 0.85, 0.75, 0.4)
	add_child(dust)

func _process(delta: float) -> void:
	_time += delta
	if _camera == null:
		_camera = get_viewport().get_camera_2d()
	if _far != null and _camera != null:
		var center := _camera.get_screen_center_position()
		var in_biome := center.x >= _base_x and center.x <= _base_x + world_width
		_far.visible = in_biome
		visible = in_biome
		if not in_biome:
			return
		var view_width := get_viewport_rect().size.x / _camera.zoom.x
		var left := center.x - view_width * 0.5 - _base_x
		# The far scene fills the view without stretching its aspect ratio.
		var coverage := maxf(view_width / _far.texture.get_width() + 0.14, 1.0)
		_far.scale = Vector2.ONE * coverage
		_far.position.x = center.x - _base_x - (clampf(left, 0, world_width) / world_width - 0.5) * 90
		_motifs.position.x = clampf(left, 0, world_width) * 0.12
	queue_redraw()

func _draw() -> void:
	var ink := Color("6fc7c1") if not breathing else Color("b4cb7e")
	if sea:
		ink = Color("7fa8d8")
	if sea:
		for i in 5:
			var y := 540.0 + i * 7.0 + sin(_time * 0.5 + i) * 4.0
			draw_rect(Rect2(0, y, world_width, 3), Color(0.35, 0.55, 0.8, 0.045))
		for i in 30:
			var glint_x := fposmod(i * 211.0 + _time * (8.0 + i % 3), world_width)
			var glint_y := 500.0 + (i * 37) % 48
			draw_line(Vector2(glint_x, glint_y), Vector2(glint_x + 18, glint_y), Color(0.5, 0.75, 0.95, 0.12), 1.0)
	for i in 24:
		var x := fposmod(i * 173.0 + _time * (6.0 + i % 4), world_width)
		var y := 120.0 + fposmod(i * 67.0, 450.0) + sin(_time * 0.7 + i) * 14.0
		var angle := sin(_time + i) * 0.4
		draw_set_transform(Vector2(x, y), angle)
		draw_rect(Rect2(-6, -2, 12, 4), Color(0.68, 0.74, 0.69, 0.26))
		draw_line(Vector2(-3, -1), Vector2(3, -1), Color(0.1, 0.24, 0.23, 0.4))
	draw_set_transform(Vector2.ZERO)
	for i in 5:
		var y := 498.0 + i * 11.0 + sin(_time * 0.4 + i) * 3
		draw_rect(Rect2(0, y, world_width, 7), Color(ink, 0.025))
	draw_rect(Rect2(0, 560, world_width, 160), Color("08131b"))
	for i in int(world_width / 96.0):
		var x := i * 96.0
		draw_rect(Rect2(x, 560, 94, 4), Color(ink, 0.55))
		draw_rect(Rect2(x + 2, 566, 90, 18), Color(0.11, 0.16, 0.18))
		draw_line(Vector2(x + 4, 586), Vector2(x + 92, 586), Color(0.2, 0.29, 0.29), 1)
		draw_rect(Rect2(x + 8, 590, 82, 130), Color(0.035, 0.055, 0.065))
