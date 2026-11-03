class_name SpellBolt
extends Node2D

## A player spell projectile with no physics body: it moves itself and tests
## the SpellContext's cached targets every frame, so a 96-bolt volley costs a
## few thousand cheap box checks. Supports launch delay, homing (optionally
## pinned to an assigned target so a volley spreads over a crowd), piercing,
## chaining between targets, splash explosions and an ink trail.

var ctx: SpellContext
var direction := Vector2.RIGHT
var speed := 620.0
var damage := 6.0
var lifetime := 1.6
var radius := 8.0
var homing := 0.0
var pierce := 0
var chain_left := 0
var delay := 0.0
var size := 1.0
var falloff := 0.85
## World position. Kept separately so bolts work outside the scene tree too.
var at := Vector2.ZERO
## Homing bolts launch outward first and only collide once armed.
var arm := 0.0

var _hit: Dictionary = {}
var _trail: PackedVector2Array = PackedVector2Array()
var _time := 0.0
var _seek: Dictionary = {}
var _seek_timer := 0.0
var _done := false
## A bolt fired at an assigned target ignores everything else until that
## target dies, so a homing volley visibly spreads over the crowd.
var _locked := false


static func fire(host: Node, context: SpellContext, at: Vector2, heading: Vector2, amount: float, options: Dictionary = {}) -> SpellBolt:
	var bolt := create(context, heading, amount, options)
	bolt.process_mode = Node.PROCESS_MODE_PAUSABLE
	bolt.add_to_group(&"spell_bolts")
	host.add_child(bolt)
	bolt.global_position = at
	bolt.at = at
	return bolt


## A configured bolt that is not in the tree yet (fire() adds it; tests and
## the headless caster step it by hand).
static func create(context: SpellContext, heading: Vector2, amount: float, options: Dictionary = {}) -> SpellBolt:
	var bolt := SpellBolt.new()
	bolt.ctx = context
	bolt.direction = heading.normalized() if heading.length_squared() > 0.0 else Vector2.RIGHT
	bolt.damage = amount
	bolt.speed = float(options.get("speed", 620.0))
	bolt.lifetime = float(options.get("lifetime", 1.6))
	bolt.homing = float(options.get("homing", context.homing))
	bolt.pierce = int(options.get("pierce", context.pierce))
	bolt.chain_left = int(options.get("chain", 0))
	bolt.delay = float(options.get("delay", 0.0))
	bolt.size = float(options.get("size", context.vfx_scale))
	bolt.radius = 8.0 * bolt.size
	bolt.arm = float(options.get("arm", 0.12 if bolt.homing > 0.0 else 0.0))
	bolt.z_index = 9
	bolt.visible = bolt.delay <= 0.0
	var seek = options.get("seek", {})
	if seek is Dictionary and not (seek as Dictionary).is_empty():
		bolt._seek = seek
		bolt._locked = bolt.homing > 0.0
	return bolt


func _physics_process(delta: float) -> void:
	step(delta)


## Advances the bolt; public so tests can drive it without a running tree.
func step(delta: float) -> void:
	if _done:
		return
	if delay > 0.0:
		delay -= delta
		visible = delay <= 0.0
		return
	_time += delta
	lifetime -= delta
	if lifetime <= 0.0:
		_finish()
		return
	if homing > 0.0:
		_steer(delta)
	var start := at
	at += direction * speed * delta
	if is_inside_tree():
		global_position = at
	_trail.append(start)
	var cap := ctx.trail if ctx != null else 6
	while _trail.size() > cap:
		_trail.remove_at(0)
	if _time >= arm:
		_check_hits(start)
	if is_inside_tree():
		queue_redraw()


func is_done() -> bool:
	return _done


func _steer(delta: float) -> void:
	_seek_timer -= delta
	var id := SpellTargets.id_of(_seek) if not _seek.is_empty() else 0
	if id == 0 or _hit.has(id):
		# Assigned target gone or already struck: take the nearest fresh one.
		if _seek_timer > 0.0:
			return
		_seek_timer = 0.12
		_seek = SpellTargets.nearest(ctx.targets(), at, 900.0, _hit)
		id = SpellTargets.id_of(_seek) if not _seek.is_empty() else 0
		if id == 0:
			return
	var aim: Vector2 = SpellTargets.describe_enemy(_seek["enemy"] as Enemy)["center"]
	var wanted := at.direction_to(aim)
	var turn := clampf(homing * 7.0 * delta, 0.0, 1.0)
	direction = direction.slerp(wanted, turn).normalized()


func _check_hits(from: Vector2) -> void:
	if ctx == null:
		return
	# Sample the segment so fast bolts cannot skip a thin target.
	var length := from.distance_to(at)
	var samples := maxi(1, int(ceil(length / maxf(radius, 6.0))))
	var lock_id := 0
	if _locked:
		lock_id = SpellTargets.id_of(_seek)
		if lock_id == 0 or _hit.has(lock_id):
			_locked = false
			lock_id = 0
	for target in ctx.targets():
		var id := SpellTargets.id_of(target)
		if id == 0 or _hit.has(id) or (lock_id != 0 and id != lock_id):
			continue
		var touched := false
		for index in samples:
			var point := from.lerp(at, float(index + 1) / float(samples))
			if SpellTargets.overlaps(target, point, radius):
				touched = true
				break
		if not touched:
			continue
		_hit[id] = true
		ctx.strike(target, damage, at)
		if ctx.can_draw() and ctx.fx_allowed():
			CombatFX.spawn(ctx.fx_host, at, &"hit", ctx.color, direction.x, 26.0 * size)
		ctx.impact(0.12)
		if chain_left > 0:
			_jump_from(target)
			return
		if pierce <= 0:
			_finish()
			return
		pierce -= 1
		damage *= falloff


func _jump_from(target: Dictionary) -> void:
	chain_left -= 1
	var next := SpellTargets.nearest(ctx.targets(), target["center"], 260.0, _hit)
	if next.is_empty():
		_finish()
		return
	at = target["center"]
	if is_inside_tree():
		global_position = at
	direction = at.direction_to(next["center"])
	_seek = next
	damage *= 0.8
	lifetime = maxf(lifetime, 0.5)
	_trail.clear()


func _finish() -> void:
	_done = true
	set_physics_process(false)
	if is_inside_tree():
		queue_free()


func _draw() -> void:
	if not visible or ctx == null:
		return
	var tint := ctx.color
	if _trail.size() >= 2:
		var local := PackedVector2Array()
		for point in _trail:
			local.append(to_local(point))
		local.append(Vector2.ZERO)
		draw_polyline(local, Color(tint, 0.3), radius * 1.1)
		draw_polyline(local, Color(tint, 0.7), maxf(radius * 0.35, 1.0))
	draw_circle(Vector2.ZERO, radius * 1.6, Color(tint, 0.18))
	var nose := direction * (9.0 * size)
	var side := direction.orthogonal() * (5.0 * size)
	draw_colored_polygon(PackedVector2Array([nose, side - direction * 3.0 * size, -direction * 6.0 * size, -side - direction * 3.0 * size]), tint)
	draw_circle(Vector2.ZERO, 2.5 * size, ctx.secondary)
	if homing > 0.0:
		draw_arc(Vector2.ZERO, radius + 3.0 + sin(_time * 18.0) * 1.5, 0, TAU, 12, Color(ctx.secondary, 0.4), 1.0)
