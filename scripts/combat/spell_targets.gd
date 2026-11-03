class_name SpellTargets
extends RefCounted

## Cheap, physics-free hit tests for player spells. Each target is a Dictionary
## {enemy, center, half}: the enemy's collision capsule as a box, or a
## body-sized box above its feet. The live list is gathered once per rendered
## frame and skips enemies in rooms the player has not entered, so volleys of
## dozens of bolts stay cheap at 120 FPS and never hit through locked doors.
## Read "enemy" untyped and check alive() first: a cached entry may have been
## freed, and assigning a freed object to a typed variable is an error.

const FALLBACK_OFFSET := Vector2(0, -28)
const FALLBACK_EXTENTS := Vector2(18, 30)

static var _cache_frame := -1
static var _cache: Array[Dictionary] = []


static func describe_enemy(enemy: Enemy) -> Dictionary:
	var center := enemy.global_position + FALLBACK_OFFSET
	var half := FALLBACK_EXTENTS
	var collider := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider != null:
		center = enemy.global_position + collider.position
		var shape := collider.shape
		if shape is CapsuleShape2D:
			half = Vector2((shape as CapsuleShape2D).radius, (shape as CapsuleShape2D).height * 0.5)
		elif shape is CircleShape2D:
			half = Vector2.ONE * (shape as CircleShape2D).radius
		elif shape is RectangleShape2D:
			half = (shape as RectangleShape2D).size * 0.5
	return {"enemy": enemy, "center": center, "half": half}


## A living enemy that is part of the active fight. Enemies under a disabled
## room node cannot process and must not be hit from afar.
static func alive(entry: Variant) -> bool:
	if entry == null or not is_instance_valid(entry) or not entry is Enemy:
		return false
	var enemy := entry as Enemy
	if enemy.is_dead():
		return false
	return not enemy.is_inside_tree() or enemy.can_process()


## Targets for an explicit list (tests, scripted fights). Computed fresh.
static func describe(list: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in list:
		if alive(entry):
			result.append(describe_enemy(entry as Enemy))
	return result


## Targets for every active enemy in the tree, cached per rendered frame.
static func active(tree: SceneTree) -> Array[Dictionary]:
	if tree == null:
		return []
	var frame := Engine.get_process_frames()
	if frame != _cache_frame:
		_cache_frame = frame
		_cache = describe(tree.get_nodes_in_group(&"enemies"))
	return _cache


static func overlaps(target: Dictionary, point: Vector2, radius: float) -> bool:
	var center: Vector2 = target["center"]
	var half: Vector2 = target["half"]
	return absf(point.x - center.x) <= half.x + radius and absf(point.y - center.y) <= half.y + radius


## Nearest living target to a point within max_distance, skipping instance ids in exclude.
static func nearest(targets: Array[Dictionary], point: Vector2, max_distance: float, exclude: Dictionary = {}) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := max_distance
	for target in targets:
		var entry = target.get("enemy")
		if not alive(entry) or exclude.has((entry as Enemy).get_instance_id()):
			continue
		var distance := (target["center"] as Vector2).distance_to(point)
		if distance < best_distance:
			best = target
			best_distance = distance
	return best


## Instance id of a live target's enemy, or 0.
static func id_of(target: Dictionary) -> int:
	var entry = target.get("enemy")
	return (entry as Enemy).get_instance_id() if alive(entry) else 0


## Deals damage and reports how much health it actually removed.
static func damage(enemy: Enemy, amount: float) -> int:
	if amount <= 0.0 or not alive(enemy):
		return 0
	var before := enemy.health
	enemy.take_damage(maxi(int(roundf(minf(amount, 1.0e9))), 1))
	return maxi(before - enemy.health, 0)
