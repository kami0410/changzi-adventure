class_name GroundWave
extends Node2D

## Fissure / shockwave that races along the floor. Every enemy it passes takes
## one hit, is thrown upward and pushed along the wave's direction. Draws a
## jagged crack with flying rock chips behind the moving front.

var ctx: SpellContext
var direction := 1.0
var speed := 760.0
var reach := 420.0
var damage := 8.0
var height := 72.0
var size := 1.0
var delay := 0.0

var _travelled := 0.0
var _hit: Dictionary = {}
var _cracks: PackedVector2Array = PackedVector2Array()
var _fade := 0.0
var _done := false


static func launch(host: Node, context: SpellContext, at: Vector2, facing: float, length: float, amount: float, scale_factor: float = 1.0) -> GroundWave:
	var wave := GroundWave.new()
	wave.ctx = context
	wave.direction = 1.0 if facing >= 0.0 else -1.0
	wave.reach = maxf(length, 60.0)
	wave.damage = amount
	wave.size = scale_factor
	wave.height = 72.0 * scale_factor
	wave.process_mode = Node.PROCESS_MODE_PAUSABLE
	wave.z_index = 7
	host.add_child(wave)
	wave.global_position = at
	return wave


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	if delay > 0.0:
		delay -= delta
		return
	if _done:
		_fade += delta * 2.2
		if _fade >= 1.0:
			queue_free()
		if is_inside_tree():
			queue_redraw()
		return
	var previous := _travelled
	_travelled = minf(_travelled + speed * delta, reach)
	var spacing := 26.0
	var mark := floorf(previous / spacing) + 1.0
	while mark * spacing <= _travelled:
		_cracks.append(Vector2(mark * spacing * direction, -sin(mark * 2.7) * 7.0 - 2.0))
		mark += 1.0
	var front := global_position + Vector2(_travelled * direction, 0)
	for target in ctx.targets():
		var id := SpellTargets.id_of(target)
		if id == 0 or _hit.has(id):
			continue
		var center: Vector2 = target["center"]
		var half: Vector2 = target["half"]
		var along := (center.x - global_position.x) * direction
		if along < -half.x or along > _travelled + half.x:
			continue
		if center.y + half.y < global_position.y - height or center.y - half.y > global_position.y + 24.0:
			continue
		_hit[id] = true
		ctx.strike(target, damage, front - Vector2(direction * 40.0, 0))
		var entry = target.get("enemy")
		if SpellTargets.alive(entry):
			(entry as Enemy).apply_knockback(Vector2(direction * 160.0, -330.0), 0.32)
		if ctx.can_draw() and ctx.fx_allowed():
			CombatFX.spawn(ctx.fx_host, Vector2(center.x, global_position.y - 8.0), &"shockwave", ctx.color, direction, 46.0 * size)
		ctx.impact(0.22)
	if _travelled >= reach:
		_done = true
	if is_inside_tree():
		queue_redraw()


func is_finished() -> bool:
	return _done


func _draw() -> void:
	if ctx == null:
		return
	var alpha := 1.0 - _fade
	var tint := Color(ctx.color, 0.85 * alpha)
	var last := Vector2.ZERO
	for point in _cracks:
		draw_line(last, point, Color(0.05, 0.03, 0.02, 0.85 * alpha), 6.0 * size)
		draw_line(last, point, tint, 2.0 * size)
		last = point
	for index in range(0, _cracks.size(), 2):
		var crack := _cracks[index]
		var spike := 10.0 + float(index % 5) * 6.0
		draw_line(crack, crack + Vector2(direction * 4.0, -spike * size * alpha), Color(ctx.secondary, 0.6 * alpha), 3.0)
	if not _done:
		var front := Vector2(_travelled * direction, 0)
		var lift := height * 0.65
		# Jagged rock shards bursting up at the wave front, dark outline first.
		for shard in 4:
			var back := Vector2(-direction * (6.0 + shard * 13.0) * size, 0.0)
			var tall := lift * (1.0 - shard * 0.2) * (0.85 + 0.15 * sin(_travelled * 0.05 + shard))
			var base_w := (9.0 - shard) * size
			var points := PackedVector2Array([
				front + back + Vector2(-base_w, 2),
				front + back + Vector2(direction * 2.0 * size, -tall),
				front + back + Vector2(base_w, 2),
			])
			draw_colored_polygon(points, Color(0.06, 0.04, 0.03, 0.9))
			var inner := PackedVector2Array([
				points[0].lerp(points[1], 0.15) + Vector2(1.5, 0),
				points[1] + Vector2(0, 3),
				points[2].lerp(points[1], 0.15) - Vector2(1.5, 0),
			])
			draw_colored_polygon(inner, Color(ctx.color.darkened(0.15 + shard * 0.1), 0.95))
			draw_line(points[1], points[1].lerp(points[2], 0.4), Color(ctx.secondary, 0.8), 1.5)
		for puff in 4:
			var dust := front + Vector2(-direction * (10.0 + puff * 16.0), -6.0 - puff * 5.0)
			draw_circle(dust, (5.0 + puff * 2.5) * size, Color(0.62, 0.55, 0.45, 0.22))
		for chip in 5:
			var arc := Vector2(-direction * (8.0 + chip * 9.0), -lift * (0.55 + 0.14 * chip))
			draw_rect(Rect2(front + arc, Vector2(4, 4) * size), Color(ctx.secondary, 0.75))
