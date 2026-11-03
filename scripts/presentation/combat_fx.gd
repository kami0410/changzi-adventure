class_name CombatFX
extends Node2D

## The generic attack telegraph is a circle; other attacks use line/ground.
const TELEGRAPH_SHAPE := DangerShape.CIRCLE

## Layered, readable one-shot combat effects. Everything is drawn from a small
## number of primitives so the game keeps its hand-inked silhouette language.

var kind: StringName = &"hit"
var tint := Color("70e1d0")
var direction := 1.0
var radius := 55.0
var duration := 0.28
var elapsed := 0.0
var amount := 0
const FONT = preload("res://assets/fonts/fusion-pixel-12px-monospaced-zh_hans.ttf.woff2")


static func spawn(host: Node, at: Vector2, type: StringName, color: Color = Color("70e1d0"), facing: float = 1.0, size: float = 55.0, value: int = 0) -> CombatFX:
	var effect := CombatFX.new()
	effect.kind = type
	effect.tint = color
	effect.direction = facing
	effect.radius = size
	effect.amount = value
	effect.duration = _duration_for(type)
	effect.process_mode = Node.PROCESS_MODE_PAUSABLE
	host.add_child(effect)
	effect.global_position = at
	return effect


static func _duration_for(type: StringName) -> float:
	match type:
		&"death", &"bomb":
			return 0.9
		&"number", &"heal":
			return 0.7
		&"dust", &"shockwave":
			return 0.5
		&"ring", &"telegraph":
			return 0.42
		&"beam_impact":
			return 0.36
		_:
			return 0.3


func _ready() -> void:
	z_index = 8


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var p := clampf(elapsed / duration, 0.0, 1.0)
	var fade := 1.0 - p
	var color := Color(tint, fade)
	match kind:
		&"slash":
			_draw_slash(p, fade, color)
		&"cast":
			_draw_cast(p, fade, color)
		&"number":
			_draw_number(p, fade, color)
		&"death":
			_draw_death(p, fade, color)
		&"telegraph":
			_draw_telegraph(p, fade, color)
		&"ring":
			_draw_ring(p, fade, color)
		&"dust":
			_draw_dust(p, fade, color)
		&"heal":
			_draw_heal(p, fade, color)
		&"shockwave":
			_draw_shockwave(p, fade, color)
		&"bomb":
			_draw_bomb(p, fade, color)
		&"beam_impact":
			_draw_beam_impact(p, fade, color)
		_:
			_draw_hit(p, fade, color)


func _draw_slash(p: float, fade: float, color: Color) -> void:
	var facing := 1.0 if direction >= 0.0 else -1.0
	var sweep := -1.25 + p * 2.25
	draw_set_transform(Vector2.ZERO, 0.0 if facing > 0.0 else PI)
	for index in 3:
		var arc_phase := clampf(p * 2.4 - index * 0.28, 0.0, 1.0)
		if arc_phase <= 0.0:
			continue
		var start := sweep - 0.95 + index * 0.12
		var end := sweep + 0.7 + index * 0.1
		draw_arc(Vector2.ZERO, radius * (0.72 + index * 0.09), start, end, 22, Color(tint, 0.85 * fade * (1.0 - index * 0.2)), 8.0 - index * 1.8)
		draw_arc(Vector2.ZERO, radius * (0.72 + index * 0.09) - 7.0, start, end, 22, Color(1.0, 0.98, 0.9, 0.55 * fade), 2.0)
	for index in 9:
		var angle := sweep + (index - 4) * 0.1
		var start := Vector2.from_angle(angle) * radius * 0.6
		var end := start + Vector2.from_angle(angle + 0.25) * (18.0 + index * 2.0) * fade
		draw_line(start, end, Color(1.0, 0.93, 0.74, 0.7 * fade), 2.0)
	for index in 6:
		var spark_angle := sweep + (index - 2.5) * 0.16
		var spark := Vector2.from_angle(spark_angle) * radius * (0.72 + p * 0.35)
		draw_circle(spark, 2.6 * fade, Color(1.0, 0.85, 0.55, 0.8 * fade))
	draw_set_transform(Vector2.ZERO)


func _draw_hit(p: float, fade: float, color: Color) -> void:
	draw_circle(Vector2.ZERO, 7.0 + p * 11.0, Color(1.0, 0.97, 0.86, 0.75 * fade))
	draw_arc(Vector2.ZERO, radius * (0.18 + p * 0.75), 0, TAU, 28, color, 3.0)
	draw_arc(Vector2.ZERO, radius * (0.28 + p * 0.55), 0, TAU, 20, Color(tint.lightened(0.4), 0.45 * fade), 1.5)
	for index in 12:
		var angle := index * TAU / 12.0 + index * 0.27
		var start := Vector2.from_angle(angle) * (6.0 + p * radius * 0.2)
		var travel := 16.0 + (index % 4) * 9.0
		var end := start + Vector2.from_angle(angle) * travel * p
		end.y += p * p * 24.0
		draw_line(start, end, Color(tint.lerp(Color.WHITE, 0.4), 0.85 * fade), 2.6 - (index % 3) * 0.5)
	for index in 5:
		var angle := -PI * 0.8 + index * 0.35
		var drop := Vector2.from_angle(angle) * radius * (0.35 + p * 0.7)
		drop.y += p * p * 30.0
		draw_circle(drop, 2.2 * fade, Color(0.04, 0.07, 0.09, 0.8 * fade))


func _draw_telegraph(p: float, fade: float, color: Color) -> void:
	var pulse := 0.5 + 0.5 * sin(elapsed * 34.0)
	var ring_radius := radius * (0.4 + p * 0.5)
	draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 24, Color(tint, (0.3 + pulse * 0.35) * fade), 2.0)
	draw_arc(Vector2.ZERO, ring_radius * 0.72, -p * TAU, -p * TAU + TAU * 0.7, 20, Color(1.0, 0.9, 0.65, 0.6 * fade), 1.5)
	for index in 4:
		var angle := index * TAU / 4.0 + elapsed * 1.4
		var point := Vector2.from_angle(angle) * ring_radius
		draw_rect(Rect2(point - Vector2(3, 3), Vector2(6, 6)), Color(tint.lightened(0.35), 0.8 * fade))
	draw_line(Vector2(-radius * 0.8, 5), Vector2(radius * 0.8, 5), Color(tint, 0.35 * fade), 1.0)


func _draw_ring(p: float, fade: float, color: Color) -> void:
	draw_arc(Vector2.ZERO, 8.0 + radius * p, 0, TAU, 36, Color(tint, 0.75 * fade), 4.0 * fade + 1.0)
	draw_arc(Vector2.ZERO, (8.0 + radius * p) * 0.72, 0, TAU, 28, Color(1, 1, 1, 0.35 * fade), 1.0)


func _draw_cast(p: float, fade: float, color: Color) -> void:
	var ring := radius * (0.25 + p * 0.75)
	draw_arc(Vector2.ZERO, ring, 0, TAU, 40, Color(tint, 0.55 * fade), 2.5)
	draw_arc(Vector2.ZERO, ring * 0.78, -elapsed * 3.0, -elapsed * 3.0 + TAU * 0.72, 24, Color(1, 1, 1, 0.3 * fade), 1.5)
	for index in 12:
		var angle := index * TAU / 12.0 + elapsed * 2.8
		var point := Vector2.from_angle(angle) * ring * (0.35 + 0.55 * fposmod(index * 0.17 + p, 1.0))
		draw_rect(Rect2(point - Vector2(2.5, 2.5), Vector2(5, 5)), Color(tint.lightened(0.45), 0.8 * fade))
	for index in 3:
		var y := -10.0 - index * 13.0 - p * 16.0
		draw_line(Vector2(-10 + index * 3, y), Vector2(10 - index * 2, y), Color(tint, 0.3 * fade), 1.0)


func _draw_number(p: float, fade: float, color: Color) -> void:
	var rise := p * 44.0
	var size := 22 + (8 if amount >= 100 else 0)
	draw_string(FONT, Vector2(-12, -rise), str(amount), HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.02, 0.02, 0.03, 0.4 * fade))
	draw_string(FONT, Vector2(-13, -rise - 2), str(amount), HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_death(p: float, fade: float, color: Color) -> void:
	var burst := radius * (0.3 + p * 1.4)
	draw_circle(Vector2.ZERO, 13.0 + p * 10.0, Color(tint, 0.28 * fade))
	draw_arc(Vector2.ZERO, burst, 0, TAU, 32, Color(tint, 0.45 * fade), 2.0)
	var streaks := PackedVector2Array()
	for index in 18:
		var angle := index * TAU / 18.0 + index * 0.31
		var speed := 30.0 + (index % 5) * 14.0
		var point := Vector2.from_angle(angle) * speed * p
		point.y += p * p * 54.0
		var droplet := (2.0 + (index % 4) * 1.3) * fade
		draw_rect(Rect2(point - Vector2.ONE * droplet, Vector2.ONE * droplet * 2.0), Color(0.03, 0.05, 0.06, 0.85 * fade))
		if index % 3 == 0:
			streaks.append(point)
			streaks.append(point + Vector2.from_angle(angle) * (7.0 * fade))
	if not streaks.is_empty():
		draw_multiline(streaks, Color(tint, 0.55 * fade), 1.0)
	# Paper scraps as rotated quads (no per-scrap transform, so they batch).
	for index in 5:
		var angle := index * TAU / 5.0 + 0.5
		var point := Vector2.from_angle(angle) * (18.0 + p * 70.0)
		point.y -= p * 26.0
		var spin := angle + p * 3.0
		var right := Vector2.from_angle(spin) * 4.0
		var down := Vector2.from_angle(spin + PI * 0.5) * 5.0
		draw_colored_polygon(PackedVector2Array([point - right - down, point + right - down, point + right + down, point - right + down]), Color(0.82, 0.79, 0.68, 0.65 * fade))


func _draw_dust(p: float, fade: float, color: Color) -> void:
	for index in 7:
		var side := -1.0 if index % 2 == 0 else 1.0
		var spread := 8.0 + index * 5.0
		var point := Vector2(side * spread * p, 3.0 - p * (8.0 + index % 3 * 4.0))
		draw_circle(point, (4.0 + index % 3 * 2.0) * fade, Color(0.56, 0.7, 0.66, 0.22 * fade))
	draw_arc(Vector2.ZERO, 14.0 + p * radius * 0.55, PI, TAU, 16, Color(tint, 0.25 * fade), 1.5)


func _draw_heal(p: float, fade: float, color: Color) -> void:
	for index in 8:
		var angle := index * TAU / 8.0 + elapsed * 1.5
		var point := Vector2.from_angle(angle) * (18.0 + index % 3 * 8.0) + Vector2(0, -p * 42.0)
		draw_circle(point, 2.7 * fade, Color(0.7, 1.0, 0.72, 0.7 * fade))
	draw_line(Vector2(0, -12), Vector2(0, -1), Color(0.75, 1.0, 0.75, 0.55 * fade), 2.0)
	draw_line(Vector2(-5, -7), Vector2(5, -7), Color(0.75, 1.0, 0.75, 0.55 * fade), 2.0)


func _draw_shockwave(p: float, fade: float, color: Color) -> void:
	var squash := Vector2(1.0, 0.28)
	var wave := (12.0 + p * radius * 1.7)
	draw_set_transform(Vector2.ZERO, 0.0, squash)
	draw_arc(Vector2.ZERO, wave, 0, TAU, 40, Color(tint, 0.65 * fade), 5.0 * fade + 1.0)
	draw_arc(Vector2.ZERO, wave * 0.72, 0, TAU, 32, Color(1, 0.9, 0.7, 0.3 * fade), 2.0)
	draw_set_transform(Vector2.ZERO)
	for index in 5:
		var crack := Vector2((index - 2) * 13.0, 2.0)
		draw_line(crack, crack + Vector2((index - 2) * 6.0, 16.0 * fade), Color(0.1, 0.08, 0.06, 0.55 * fade), 2.0)


func _draw_bomb(p: float, fade: float, color: Color) -> void:
	# Same primitive types are drawn together so the renderer can batch them.
	draw_circle(Vector2.ZERO, 10.0 + p * 34.0, Color(0.02, 0.01, 0.03, 0.65 * fade))
	var droplets := PackedVector2Array()
	for index in 14:
		var angle := index * TAU / 14.0 + index * 0.4
		var point := Vector2.from_angle(angle) * (12.0 + p * (35.0 + index % 5 * 9.0))
		point.y += p * p * 18.0
		droplets.append(point)
	var streaks := PackedVector2Array()
	for index in 14:
		var angle := index * TAU / 14.0 + index * 0.4
		streaks.append(droplets[index])
		streaks.append(droplets[index] + Vector2.from_angle(angle) * 7.0 * fade)
	draw_multiline(streaks, Color(tint, 0.5 * fade), 1.0)
	for point in droplets:
		draw_rect(Rect2(point - Vector2.ONE * 2.5 * fade, Vector2.ONE * 5.0 * fade), Color(0.06, 0.02, 0.08, 0.8 * fade))
	draw_arc(Vector2.ZERO, 12.0 + p * 54.0, 0, TAU, 30, Color(tint, 0.8 * fade), 4.0 * fade)
	draw_arc(Vector2.ZERO, 8.0 + p * 16.0, 0, TAU, 18, Color(1, 0.9, 1.0, 0.4 * fade), 2.0)


func _draw_beam_impact(p: float, fade: float, color: Color) -> void:
	draw_line(Vector2(0, -160), Vector2(0, 24), Color(tint, 0.5 * fade), 12.0 * fade)
	draw_line(Vector2(0, -120), Vector2(0, 12), Color(1, 0.95, 0.85, 0.55 * fade), 3.0)
	for index in 7:
		var angle := -PI * 0.5 + (index - 3) * 0.3
		var point := Vector2.from_angle(angle) * (22.0 + p * 38.0)
		draw_line(Vector2.ZERO, point, Color(tint, 0.6 * fade), 2.0)
	draw_circle(Vector2.ZERO, 8.0 + p * 16.0, Color(1, 1, 1, 0.35 * fade))
