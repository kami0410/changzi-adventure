class_name EchoSentinel
extends Node2D

## A summoned echo that floats beside its caster and fires ink bolts at nearby
## enemies. It turns "summon" phrases from a one-shot nuke into a lasting ally.
## With a SpellContext its bolts carry the phrase's statuses and home in.

var lifetime: float = 8.0
var elapsed: float = 0.0
var cooldown: float = 0.0
var damage: float = 6.0
var interval: float = 0.65
var tint := Color("90d6b8")
var ctx: SpellContext
var follow_offset := Vector2.ZERO
var _time := 0.0
var _anchor := Vector2.ZERO


static func create(host: Node, at: Vector2, amount: float, duration: float, context: SpellContext = null, fire_interval: float = 0.65, offset: Vector2 = Vector2.ZERO) -> EchoSentinel:
	var echo := EchoSentinel.new()
	echo.damage = maxf(amount, 1.0)
	echo.lifetime = duration
	echo.ctx = context
	echo.interval = maxf(fire_interval, 0.12)
	echo.follow_offset = offset
	if context != null:
		echo.tint = context.color
	echo.add_to_group(&"spell_zones")
	host.add_child(echo)
	echo.global_position = at
	echo._anchor = at
	return echo


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 6


func _process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	_time += delta
	elapsed += delta
	cooldown = maxf(cooldown - delta, 0.0)
	if elapsed >= lifetime:
		queue_free()
		return
	var owner_body := ctx.player if ctx != null else null
	if owner_body != null and is_instance_valid(owner_body):
		var wanted := owner_body.global_position + Vector2(0, -28) + follow_offset
		_anchor = _anchor.lerp(wanted, clampf(delta * 6.0, 0.0, 1.0))
	global_position = _anchor + Vector2(0, sin(_time * 2.4) * 8.0)
	if cooldown <= 0.0:
		_fire()
	if is_inside_tree():
		queue_redraw()


func _fire() -> void:
	if ctx != null:
		var target := SpellTargets.nearest(ctx.targets(), global_position, 520.0)
		if target.is_empty():
			return
		cooldown = interval
		var heading := global_position.direction_to(target["center"])
		SpellBolt.fire(get_parent(), ctx, global_position, heading, damage, {"speed": 560.0, "lifetime": 1.4, "homing": maxf(ctx.homing, 0.8)})
		return
	if not is_inside_tree():
		return
	var best: Enemy = null
	var best_distance := 520.0
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Enemy and not node.dead:
			var distance := global_position.distance_to(node.global_position)
			if distance < best_distance:
				best = node
				best_distance = distance
	if best != null:
		cooldown = interval
		HostileBolt.launch(get_parent(), global_position, global_position.direction_to(best.global_position + Vector2(0, -28)), int(damage), 520, true)


func _draw() -> void:
	var fade := clampf(1.0 - elapsed / lifetime, 0.0, 1.0)
	fade = minf(fade * 4.0, 1.0)
	draw_circle(Vector2.ZERO, 24.0, Color(tint, 0.18 * fade))
	draw_arc(Vector2.ZERO, 28.0 + sin(_time * 4.0) * 3.0, 0, TAU, 24, Color(tint, 0.7 * fade), 2.0)
	draw_circle(Vector2(0, -3), 8.0, Color(1, 1, 1, 0.75 * fade))
	draw_circle(Vector2(3, -3), 4.0, Color(0.05, 0.1, 0.12, 0.9 * fade))
