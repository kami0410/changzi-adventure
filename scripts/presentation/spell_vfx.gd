class_name SpellVFX
extends Node2D

## One-shot, readable spell silhouette. Each shape is drawn procedurally so the
## same damage reads as flame, lightning, a devouring beam, a time trap, a ward,
## a summoned echo or a void collapse.

var shape: StringName = &"blade"
var tint: Color = Color("ff9c63")
var direction := 1.0
var radius := 160.0
var duration := 0.55
var elapsed := 0.0
var chain_points: PackedVector2Array = PackedVector2Array()

static func spawn(host: Node, at: Vector2, spell_shape: StringName, color: Color, facing: float, size: float, points: PackedVector2Array = PackedVector2Array()) -> SpellVFX:
	var fx := SpellVFX.new()
	fx.shape = spell_shape
	fx.tint = color
	fx.direction = facing
	fx.radius = size
	fx.chain_points = points
	fx.duration = 0.8 if spell_shape in [&"vortex", &"void", &"ward"] else 0.5
	fx.process_mode = Node.PROCESS_MODE_PAUSABLE
	fx.z_index = 9
	host.add_child(fx)
	fx.global_position = at
	return fx

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var p := clampf(elapsed / duration, 0.0, 1.0)
	var fade := 1.0 - p
	# Shared ink halo: every spell reads as the same language, even when the
	# silhouette is different.
	draw_circle(Vector2.ZERO, radius * (0.32 + p * 0.75), Color(tint, 0.07 * fade))
	draw_arc(Vector2.ZERO, radius * (0.2 + p * 0.9), -elapsed * 1.8, -elapsed * 1.8 + TAU * 0.62, 32, Color(tint, 0.22 * fade), 2.0)
	for index in 8:
		var angle := index * TAU / 8.0 + elapsed * 2.4
		var point := Vector2.from_angle(angle) * radius * (0.3 + p * 0.6)
		draw_circle(point, 2.2 * fade, Color(tint.lightened(0.35), 0.5 * fade))
	match shape:
		&"flame": _draw_flame(p, fade)
		&"blood": _draw_blood(p, fade)
		&"chain": _draw_chain(p, fade)
		&"vortex": _draw_vortex(p, fade)
		&"ward": _draw_ward(p, fade)
		&"sentinel": _draw_sentinel(p, fade)
		&"void": _draw_void(p, fade)
		&"missile", &"beam", &"quake", &"meteor", &"domain": _draw_sigil(p, fade)
		_: _draw_blade(p, fade)
	_draw_speed_lines(p, fade)


func _draw_speed_lines(p: float, fade: float) -> void:
	for index in 7:
		var y := (index - 3) * radius * 0.12
		var length := radius * (0.25 + 0.35 * fposmod(index * 0.23 + p, 1.0))
		var start := Vector2(direction * radius * 0.2, y)
		draw_line(start, start + Vector2(direction * length, y * 0.12), Color(1.0, 0.95, 0.82, 0.18 * fade), 1.0)

func _draw_flame(p: float, fade: float) -> void:
	var reach := radius * (0.35 + p * 1.1)
	for i in 9:
		var angle := (i - 4) * 0.13 * direction
		var tip := Vector2(direction * cos(angle), sin(angle)) * reach * (0.7 + 0.3 * sin(i * 1.7 + elapsed * 18.0))
		var side := Vector2(-direction * sin(angle), cos(angle)) * (12.0 + i % 3 * 4.0)
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, tip + side, tip - side]), Color(tint, 0.3 * fade))
	for i in 6:
		var angle := (i - 2.5) * 0.16 * direction
		var tip := Vector2(direction * cos(angle), sin(angle)) * reach * 0.78
		draw_line(Vector2.ZERO, tip, Color(1.0, 0.86, 0.6, 0.82 * fade), 4.0)
	for i in 10:
		var ember := Vector2(direction * reach * (0.45 + 0.5 * fposmod(i * 0.17 + p, 1.0)), sin(i * 2.3 + elapsed * 14.0) * 28.0)
		draw_circle(ember, 3.0 + i % 3, Color(1.0, 0.62, 0.32, 0.7 * fade))
	draw_circle(Vector2(direction * 16, -4), 20.0 * fade, Color(1.0, 0.92, 0.7, 0.7 * fade))

func _draw_blood(p: float, fade: float) -> void:
	var end := Vector2(direction * radius, 0)
	draw_line(Vector2.ZERO, end, Color(tint, 0.55 * fade), 6.0)
	draw_line(Vector2.ZERO, end, Color(1.0, 0.8, 0.85, 0.85 * fade), 2.0)
	for i in 7:
		var t := fposmod(i / 7.0 + p, 1.0)
		var point := end * t + Vector2(0, sin(i * 2.1 + elapsed * 9.0) * 10.0)
		draw_circle(point, 4.0 * fade, Color(tint, 0.8 * fade))

func _draw_chain(p: float, fade: float) -> void:
	var points := chain_points
	if points.is_empty():
		points = PackedVector2Array([Vector2.ZERO, Vector2(direction * radius, 0)])
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		var segments := 6
		var last := a
		for s in range(1, segments + 1):
			var t := float(s) / segments
			var point := a.lerp(b, t)
			if s < segments:
				point += Vector2(0, sin(s * 7.0 + i * 3.0 + elapsed * 40.0) * 14.0) * fade
			draw_line(last, point, Color(tint, 0.22 * fade), 18.0)
			draw_line(last, point, Color(tint, 0.8 * fade), 5.0)
			draw_line(last, point, Color(1, 1, 1, 0.95 * fade), 2.0)
			if s % 2 == 0:
				var fork := point + Vector2(signf(sin(s * 5.0)) * 26.0, 18.0 * signf(cos(s * 3.0)))
				draw_line(point, fork, Color(tint, 0.55 * fade), 2.0)
			last = point
		draw_circle(b, 16.0 * fade, Color(tint, 0.4 * fade))
		draw_circle(b, 7.0 * fade, Color(1, 1, 1, 0.8 * fade))

func _draw_vortex(p: float, fade: float) -> void:
	for i in 4:
		var r := radius * (0.3 + p * 0.9) * (0.6 + i * 0.13)
		draw_arc(Vector2.ZERO, r, elapsed * 2.0 + i, elapsed * 2.0 + i + TAU * 0.75, 40, Color(tint, 0.32 * fade), 3.0)
	for i in 12:
		var angle := i * TAU / 12.0 + elapsed * 1.7
		var point := Vector2.from_angle(angle) * radius * (1.0 - p) * 0.9
		draw_circle(point, 3.0, Color(tint, 0.7 * fade))

func _draw_ward(p: float, fade: float) -> void:
	var r := radius * (0.5 + p * 0.5)
	var points := PackedVector2Array()
	for i in 6:
		points.append(Vector2.from_angle(i * TAU / 6.0 - PI / 6.0) * r)
	points.append(points[0])
	draw_polyline(points, Color(tint, 0.6 * fade), 4.0)
	draw_arc(Vector2.ZERO, r * 0.72, 0, TAU, 40, Color(1, 1, 1, 0.4 * fade), 2.0)

func _draw_sentinel(p: float, fade: float) -> void:
	var r := 22.0
	draw_circle(Vector2.ZERO, r * fade, Color(tint, 0.35 * fade))
	draw_arc(Vector2.ZERO, r + 8.0 * sin(elapsed * 6.0), 0, TAU, 24, Color(tint, 0.7 * fade), 2.0)
	draw_circle(Vector2.ZERO, 7.0, Color(1, 1, 1, 0.8 * fade))
	draw_line(Vector2(-12, 0), Vector2(12, 0), Color(0, 0, 0, 0.7 * fade), 2.0)

func _draw_void(p: float, fade: float) -> void:
	var r := radius * (0.2 + p * 0.9)
	draw_circle(Vector2.ZERO, r, Color(0.06, 0.01, 0.1, 0.55 * fade))
	draw_arc(Vector2.ZERO, r + 8.0, 0, TAU, 48, Color(tint, 0.75 * fade), 4.0)
	for i in 10:
		var angle := i * TAU / 10.0 + elapsed * 3.0
		var inner := Vector2.from_angle(angle) * r * 0.3
		var outer := Vector2.from_angle(angle) * r * (1.1 + 0.2 * sin(i * 2.0))
		draw_line(inner, outer, Color(tint, 0.7 * fade), 3.0)
		draw_circle(outer, 4.0, Color(1, 0.8, 0.95, 0.6 * fade))
	draw_arc(Vector2.ZERO, r * 0.55, 0, TAU, 32, Color(1, 1, 1, 0.5 * fade), 2.0)

func _draw_blade(p: float, fade: float) -> void:
	for i in 3:
		var phase := clampf(p * 3.0 - i, 0.0, 1.0)
		if phase <= 0.0:
			continue
		var start := -1.2 + i * 0.55
		var arc := start + phase * 1.3
		draw_arc(Vector2.ZERO, radius * (0.62 + i * 0.1), start, arc, 18, Color(tint, (1.0 - phase) * 0.9 * fade), 7.0)
		draw_arc(Vector2.ZERO, radius * (0.62 + i * 0.1) - 8.0, start, arc, 18, Color(1, 1, 1, (1.0 - phase) * 0.5 * fade), 3.0)


## Casting sigil for shapes whose payload draws itself (bolts, beams, waves,
## stars, domains): a quick rotating seal at the hand so every cast reads.
func _draw_sigil(p: float, fade: float) -> void:
	var r := 26.0 + p * 30.0
	draw_arc(Vector2.ZERO, r, elapsed * 4.0, elapsed * 4.0 + TAU * 0.8, 24, Color(tint, 0.75 * fade), 3.0)
	draw_arc(Vector2.ZERO, r * 0.62, -elapsed * 6.0, -elapsed * 6.0 + TAU * 0.6, 18, Color(1, 1, 1, 0.5 * fade), 1.5)
	for index in 4:
		var angle := elapsed * 3.0 + index * TAU / 4.0
		var point := Vector2.from_angle(angle) * r
		draw_rect(Rect2(point - Vector2(3, 3), Vector2(6, 6)), Color(tint.lightened(0.4), 0.8 * fade))
