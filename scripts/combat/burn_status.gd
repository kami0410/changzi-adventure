class_name BurnStatus
extends Node

## Applies damage over time so fire has a distinct effect beyond its initial hit.
## Re-applying refreshes the strongest burn instead of stacking nodes, so a
## volley of burning bolts stays one status per enemy.

var target: Enemy
var damage: int = 3
var ticks: int = 4
var interval: float = 0.6
var elapsed: float = 0.0

static func apply(enemy: Enemy, amount: int, tick_count: int = 4) -> void:
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return
	var existing := enemy.get_node_or_null("BurnStatus") as BurnStatus
	if existing != null and not existing.is_queued_for_deletion():
		existing.damage = maxi(existing.damage, maxi(amount, 1))
		existing.ticks = maxi(existing.ticks, tick_count)
		return
	var burn := BurnStatus.new()
	burn.name = "BurnStatus"
	burn.target = enemy
	burn.damage = maxi(amount, 1)
	burn.ticks = tick_count
	enemy.add_child(burn)

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target) or target.dead:
		queue_free()
		return
	elapsed += delta
	if elapsed < interval:
		return
	elapsed -= interval
	ticks -= 1
	if target.is_inside_tree() and target.get_parent() != null:
		CombatFX.spawn(target.get_parent(), target.global_position + Vector2(randf_range(-10, 10), -42), &"dust", Color("ff9c63"), 1.0, 18)
	target.take_damage(damage)
	if ticks <= 0:
		queue_free()
