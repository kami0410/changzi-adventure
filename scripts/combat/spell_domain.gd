class_name SpellDomain
extends Node2D

## A persistent field. As a "domain" it follows the caster and ticks damage on
## everything inside; as a "vortex" it stays put, drags enemies toward its
## centre and slows them. Both read the SpellContext for burn/slow/stun etc.

var ctx: SpellContext
var follow: Node2D
var follow_offset := Vector2(0, -24)
var radius := 170.0
var lifetime := 6.0
var tick := 0.5
var damage := 4.0
var pull := 0.0
var rings := 3
var glyphs := 10
var size := 1.0

var _elapsed := 0.0
var _tick_left := 0.0
var _hit_flash := 0.0
var _ticks := 0
var _touched: Dictionary = {}


static func open(host: Node, context: SpellContext, at: Vector2, area: float, duration: float, amount: float, options: Dictionary = {}) -> SpellDomain:
	var field := SpellDomain.new()
	field.ctx = context
	field.radius = maxf(area, 40.0)
	field.lifetime = maxf(duration, 0.2)
	field.damage = amount
	field.tick = clampf(float(options.get("tick", 0.5)), 0.1, 2.0)
	field.pull = float(options.get("pull", 0.0))
	field.follow = options.get("follow", null)
	field.rings = clampi(int(options.get("rings", context.rings)), 1, 8)
	field.glyphs = clampi(int(options.get("glyphs", context.glyphs)), 4, 32)
	field.size = float(options.get("size", context.vfx_scale))
	field.process_mode = Node.PROCESS_MODE_PAUSABLE
	field.z_index = 3
	field.add_to_group(&"spell_zones")
	host.add_child(field)
	field.global_position = at
	return field


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	_elapsed += delta
	_tick_left -= delta
	_hit_flash = maxf(_hit_flash - delta * 4.0, 0.0)
	if follow != null and is_instance_valid(follow):
		global_position = follow.global_position + follow_offset
	if _elapsed >= lifetime:
		queue_free()
		return
	var targets := ctx.targets()
	if pull > 0.0:
		for target in targets:
			var entry = target.get("enemy")
			if not SpellTargets.alive(entry):
				continue
			var enemy := entry as Enemy
			var offset := global_position - (target["center"] as Vector2)
			var distance := offset.length()
			if distance <= radius and distance > 12.0 and not enemy.is_knocked_back():
				enemy.global_position += offset / distance * minf(pull * 90.0 * delta, distance - 12.0)
	if _tick_left <= 0.0:
		_tick_left = tick
		_ticks += 1
		var any := false
		for target in targets:
			var id := SpellTargets.id_of(target)
			if id == 0:
				continue
			if (target["center"] as Vector2).distance_to(global_position) <= radius + (target["half"] as Vector2).x:
				ctx.strike_field(target, damage, not _touched.has(id))
				_touched[id] = true
				any = true
		if any:
			_hit_flash = 1.0
	if is_inside_tree():
		queue_redraw()


func ticks_done() -> int:
	return _ticks


func _draw() -> void:
	if ctx == null:
		return
	var life := clampf(1.0 - _elapsed / lifetime, 0.0, 1.0)
	var grow := clampf(_elapsed / 0.25, 0.0, 1.0)
	var fade := minf(life * 3.0, 1.0)
	var r := radius * (0.6 + 0.4 * grow)
	var tint := ctx.color
	draw_circle(Vector2.ZERO, r, Color(tint, (0.08 + 0.08 * _hit_flash) * fade))
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(tint, 0.65 * fade), 2.5)
	for ring in rings:
		var phase := fposmod(_elapsed * (0.35 if pull > 0.0 else 0.2) + float(ring) / rings, 1.0)
		var ring_r := r * (1.0 - phase) if pull > 0.0 else r * phase
		draw_arc(Vector2.ZERO, maxf(ring_r, 4.0), 0, TAU, 40, Color(tint, 0.3 * fade), 1.5)
	var spin := _elapsed * (2.2 if pull > 0.0 else 0.8)
	var glyph_color := Color(ctx.secondary, 0.65 * fade)
	var marks := PackedVector2Array()
	for index in glyphs:
		var angle := spin + index * TAU / glyphs
		var point := Vector2.from_angle(angle) * r * 0.86
		var along := Vector2.from_angle(angle) * 5.0 * size
		var across := Vector2.from_angle(angle + PI * 0.5) * 3.0 * size
		draw_colored_polygon(PackedVector2Array([point - along - across, point + along - across, point + along + across, point - along + across]), glyph_color)
		marks.append(point - across * 0.6)
		marks.append(point + across * 0.6)
	draw_multiline(marks, Color(tint.darkened(0.5), 0.8 * fade), 1.0)
	if pull > 0.0:
		for arm in 3:
			var start := spin * 1.4 + arm * TAU / 3.0
			var previous := Vector2.ZERO
			for index in 10:
				var t := float(index + 1) / 10.0
				var point := Vector2.from_angle(start + t * 2.4) * r * t
				draw_line(previous, point, Color(tint, 0.45 * fade * (1.0 - t * 0.5)), 2.0)
				previous = point
