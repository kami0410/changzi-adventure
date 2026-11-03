class_name SpellBeam
extends Node2D

## A piercing ray: each pulse damages every target inside a long thin box
## along `heading`, then the light lingers and narrows. Extra pulses re-fire
## along the same line, so "连续" beams hit again. Fanned beams just use
## different headings.

var ctx: SpellContext
var heading := Vector2.RIGHT
var length := 640.0
var width := 26.0
var damage := 10.0
var pulses := 1
var interval := 0.12
var delay := 0.0
var size := 1.0

var _elapsed := 0.0
var _fired := 0
var _next := 0.0
var _impact_points: PackedVector2Array = PackedVector2Array()


static func fire(host: Node, context: SpellContext, at: Vector2, direction: Vector2, reach: float, amount: float, count: int = 1, scale_factor: float = 1.0, start_delay: float = 0.0) -> SpellBeam:
	var beam := SpellBeam.new()
	beam.ctx = context
	beam.heading = direction.normalized() if direction.length_squared() > 0.0 else Vector2.RIGHT
	beam.length = maxf(reach, 80.0)
	beam.damage = amount
	beam.pulses = maxi(count, 1)
	beam.size = scale_factor
	beam.width = 26.0 * scale_factor
	beam.delay = start_delay
	beam.process_mode = Node.PROCESS_MODE_PAUSABLE
	beam.z_index = 9
	host.add_child(beam)
	beam.global_position = at
	return beam


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	if delay > 0.0:
		delay -= delta
		return
	if _fired < pulses and _elapsed >= _next:
		_fired += 1
		_next = _elapsed + interval
		_sweep()
	_elapsed += delta
	if _fired >= pulses and _elapsed >= _next + 0.3:
		queue_free()
	if is_inside_tree():
		queue_redraw()


func pulses_fired() -> int:
	return _fired


func _sweep() -> void:
	_impact_points.clear()
	var across := heading.orthogonal()
	for target in ctx.targets():
		var offset: Vector2 = (target["center"] as Vector2) - global_position
		var half: Vector2 = target["half"]
		# Project the target's box onto the beam axis and its normal.
		var along_reach := absf(heading.x) * half.x + absf(heading.y) * half.y
		var across_reach := absf(across.x) * half.x + absf(across.y) * half.y
		var along := offset.dot(heading)
		if along < -along_reach or along > length + along_reach:
			continue
		if absf(offset.dot(across)) > across_reach + width * 0.5:
			continue
		ctx.strike(target, damage, global_position)
		_impact_points.append(offset)
		if ctx.can_draw() and ctx.fx_allowed():
			CombatFX.spawn(ctx.fx_host, target["center"], &"beam_impact", ctx.color, signf(heading.x), 40.0)
	ctx.impact(0.18 + 0.04 * _impact_points.size())


func _draw() -> void:
	if ctx == null or delay > 0.0:
		return
	var since := _elapsed - (_next - interval)
	var fade := clampf(1.0 - since / 0.3, 0.0, 1.0)
	var end := heading * length
	var core := width * (0.35 + 0.65 * fade)
	draw_line(Vector2.ZERO, end, Color(ctx.color, 0.22 * fade), core * 2.2)
	draw_line(Vector2.ZERO, end, Color(ctx.color, 0.75 * fade), core)
	draw_line(Vector2.ZERO, end, Color(1.0, 0.98, 0.92, 0.9 * fade), maxf(core * 0.3, 1.0))
	draw_circle(Vector2.ZERO, core * 0.9, Color(ctx.secondary, 0.8 * fade))
	var across := heading.orthogonal() * core * 0.6
	for index in 8:
		var start := heading * fposmod(index * 83.0 + _elapsed * 900.0, length)
		draw_line(start - across, start - across + heading * 26.0, Color(1, 1, 1, 0.35 * fade), 1.0)
	for point in _impact_points:
		draw_circle(point, 14.0 * fade * size, Color(ctx.secondary, 0.6 * fade))
