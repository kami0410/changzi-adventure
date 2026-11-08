class_name RoomVariety
extends RefCounted

## Per-run extra traversal platforms for the big-map regions (0.14).
##
## Chapters 2–4 reuse the same authored geometry for most region types, so
## every chapter played like the same map. On top of the authored layout each
## run adds a few seeded platforms per region, in the chapter's own mechanic:
## Chapter 2 one-way stone ledges, Chapter 3 rotten planks that collapse,
## Chapter 4 stage rigs that slide sideways. Every extra platform is optional
## (the authored route still works without it), reachable from a surface below
## within the jump budget, keeps head room, and stays clear of gates, lift
## shafts and interactables. Same run + region = same layout on reload.

const MIN_COUNT := 3
const MAX_COUNT := 6
const ATTEMPTS := 70
## Rise from the supporting surface. Since 1.0.1 the hero has a double jump
## (reach ~185 px), so the extra ledges sit high enough for a walker to pass
## under them (clearance >= 96 px below a 16 px ledge) instead of 48-80 px.
const RISE_MIN := 112.0
const RISE_MAX := 144.0
const MAX_GAP := 104.0
const HEADROOM := 104.0
const BELOW_CLEAR := 56.0
const EDGE_MARGIN := 64.0
const TOP_MARGIN := 176.0
const AVOID_RADIUS := Vector2(150.0, 170.0)
const SHAFT_HALF := 140.0
const MOVE_TRAVEL := Vector2(120.0, 200.0)


## Picks the extra platforms. Pure: returns specs, never touches the scene.
## Each spec: {kind: &"one_way"|&"collapse"|&"moving", rect: Rect2, travel: float}.
static func plan(chapter: int, seed_key: String, bounds: Rect2, surfaces: Array[Rect2],
		avoid: Array[Vector2], shafts: Array[float]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if chapter < 2 or surfaces.is_empty():
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("variety|" + seed_key)
	var target := rng.randi_range(MIN_COUNT, MAX_COUNT)
	var all: Array[Rect2] = surfaces.duplicate()
	# Only static surfaces can be jumped from; a moving rig's sweep still
	# counts for clearance.
	var bases: Array[Rect2] = surfaces.duplicate()
	for attempt in ATTEMPTS:
		if out.size() >= target:
			break
		var base: Rect2 = bases[rng.randi_range(0, bases.size() - 1)]
		var width := float(rng.randi_range(7, 11) * 16)
		var kind := _kind_for(chapter, rng)
		var travel := 0.0
		if kind == &"moving":
			travel = snappedf(rng.randf_range(MOVE_TRAVEL.x, MOVE_TRAVEL.y), 16.0) * (1.0 if rng.randf() < 0.5 else -1.0)
		var x := snappedf(rng.randf_range(base.position.x - MAX_GAP - width * 0.5,
			base.end.x + MAX_GAP - width * 0.5), 16.0)
		var y := snappedf(base.position.y - rng.randf_range(RISE_MIN, RISE_MAX), 16.0)
		if base.position.y - y > RISE_MAX + 0.1 or base.position.y - y < RISE_MIN - 0.1:
			continue
		var rect := Rect2(x, y, width, 16.0)
		var swept := rect.merge(Rect2(rect.position + Vector2(travel, 0), rect.size))
		if not _fits(swept, bounds, all, avoid, shafts):
			continue
		if not _reachable(rect, base):
			continue
		out.append({"kind": kind, "rect": rect, "travel": travel})
		all.append(swept)
		if kind != &"moving":
			bases.append(rect)
	return out


static func _kind_for(chapter: int, rng: RandomNumberGenerator) -> StringName:
	match chapter:
		3:
			return &"collapse" if rng.randf() < 0.45 else &"one_way"
		4:
			return &"moving" if rng.randf() < 0.45 else &"one_way"
	return &"one_way"


static func _reachable(rect: Rect2, base: Rect2) -> bool:
	var gap := maxf(maxf(base.position.x - rect.end.x, rect.position.x - base.end.x), 0.0)
	return gap <= MAX_GAP


static func _fits(rect: Rect2, bounds: Rect2, surfaces: Array[Rect2], avoid: Array[Vector2],
		shafts: Array[float]) -> bool:
	if rect.position.x < bounds.position.x + EDGE_MARGIN or rect.end.x > bounds.end.x - EDGE_MARGIN:
		return false
	if rect.position.y < bounds.position.y + TOP_MARGIN or rect.end.y > bounds.end.y - 32.0:
		return false
	for other in surfaces:
		var overlap_x := rect.position.x < other.end.x + 32.0 and rect.end.x > other.position.x - 32.0
		if not overlap_x:
			continue
		if other.position.y <= rect.position.y:
			# Something above: keep head room for standing on the new platform.
			if rect.position.y - other.position.y < HEADROOM:
				return false
		elif other.position.y - rect.position.y < BELOW_CLEAR:
			return false
	for point in avoid:
		var nearest := Vector2(clampf(point.x, rect.position.x, rect.end.x),
			clampf(point.y, rect.position.y, rect.end.y))
		if absf(nearest.x - point.x) < AVOID_RADIUS.x and absf(nearest.y - point.y) < AVOID_RADIUS.y:
			return false
	for shaft_x in shafts:
		if rect.end.x > shaft_x - SHAFT_HALF and rect.position.x < shaft_x + SHAFT_HALF:
			return false
	return true


## Builds the nodes for [param specs] under [param room].
static func build(room: Node2D, specs: Array[Dictionary], tile_texture: Texture2D) -> Array[Node2D]:
	var nodes: Array[Node2D] = []
	var index := 0
	for spec in specs:
		var rect: Rect2 = spec["rect"]
		var node: Node2D
		match StringName(spec["kind"]):
			&"collapse":
				var plank := CollapsingPlatform.new()
				plank.size = rect.size
				node = plank
			&"moving":
				var rig := MovingPlatform.new()
				rig.size = rect.size
				rig.travel = Vector2(float(spec["travel"]), 0.0)
				rig.speed = 70.0
				rig.pause_time = 0.8
				node = rig
			_:
				var ledge := OneWayPlatform.new()
				ledge.size = rect.size
				node = ledge
		node.name = "Variety%d" % index
		node.position = rect.position
		node.set_meta(&"run_variety", true)
		if tile_texture != null and &"tile_texture" in node:
			node.set(&"tile_texture", tile_texture)
		room.add_child(node)
		nodes.append(node)
		index += 1
	return nodes
