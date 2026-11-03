class_name MeteorStrike
extends Node2D

## A star that falls onto a marked spot. A pulsing ground ring warns first,
## then the star drops in a streak and bursts on impact, damaging everything
## inside the ring (and splashing further with the phrase's explosion).

const FALL_HEIGHT := 520.0

var ctx: SpellContext
var damage := 10.0
var radius := 70.0
var warn := 0.45
var fall := 0.22
var size := 1.0

var _time := 0.0
var _landed := false
var _after := 0.0


static func drop(host: Node, context: SpellContext, ground: Vector2, amount: float, blast_radius: float, delay: float = 0.0, scale_factor: float = 1.0) -> MeteorStrike:
	var meteor := MeteorStrike.new()
	meteor.ctx = context
	meteor.damage = amount
	meteor.radius = blast_radius
	meteor.warn = 0.45 + delay
	meteor.size = scale_factor
	meteor.process_mode = Node.PROCESS_MODE_PAUSABLE
	meteor.z_index = 8
	host.add_child(meteor)
	meteor.global_position = ground
	return meteor


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	_time += delta
	if not _landed and _time >= warn + fall:
		_landed = true
		_impact()
	if _landed:
		_after += delta
		if _after >= 0.35:
			queue_free()
	if is_inside_tree():
		queue_redraw()


func has_landed() -> bool:
	return _landed


func _impact() -> void:
	for target in ctx.targets():
		var center: Vector2 = target["center"]
		var reach := radius + (target["half"] as Vector2).x
		if absf(center.x - global_position.x) <= reach and center.y >= global_position.y - radius * 2.2:
			ctx.strike(target, damage, global_position)
	# Every star draws its own flash; the heavier layered burst is budgeted.
	if ctx.can_draw() and ctx.blast_fx_allowed():
		CombatFX.spawn(ctx.fx_host, global_position + Vector2(0, -6), &"bomb", ctx.color, 1.0, radius)
		CombatFX.spawn(ctx.fx_host, global_position, &"shockwave", ctx.secondary, 1.0, radius * 0.9)
	ctx.impact(0.55)


func _draw() -> void:
	if ctx == null:
		return
	var tint := ctx.color
	if not _landed:
		var charge := clampf(_time / warn, 0.0, 1.0)
		var pulse := 0.5 + 0.5 * sin(_time * 26.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(tint, 0.25 + 0.35 * pulse), 3.0)
		draw_arc(Vector2.ZERO, radius * charge, 0, TAU, 28, Color(ctx.secondary, 0.5), 2.0)
		draw_set_transform(Vector2.ZERO)
		if _time >= warn:
			var t := clampf((_time - warn) / fall, 0.0, 1.0)
			var head := Vector2(-90.0 * (1.0 - t), -FALL_HEIGHT * (1.0 - t))
			var tail := head + Vector2(-60.0, -150.0) * (0.6 + 0.4 * (1.0 - t))
			draw_line(tail, head, Color(tint, 0.35), 18.0 * size)
			draw_line(tail.lerp(head, 0.4), head, Color(ctx.secondary, 0.8), 6.0 * size)
			draw_circle(head, 12.0 * size, Color(1.0, 0.97, 0.88, 0.95))
			draw_circle(head, 20.0 * size, Color(tint, 0.4))
		return
	var fade := 1.0 - clampf(_after / 0.35, 0.0, 1.0)
	draw_circle(Vector2(0, -8), radius * (0.4 + _after * 2.0), Color(1.0, 0.95, 0.8, 0.35 * fade))
	for spark in 10:
		var angle := -PI + spark * PI / 9.0
		var dist := radius * (0.3 + _after * 3.2)
		draw_line(Vector2.ZERO, Vector2.from_angle(angle) * dist, Color(tint, 0.7 * fade), 2.0)
