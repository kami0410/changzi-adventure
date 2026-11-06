class_name BigRoomData
extends Resource

## Authored geometry and dressing for one big-map room (chapters 2–4).
##
## Chapter 1 keeps [MDSChapterRoom] and its fixed 1280x720 template; this
## resource is the production-line counterpart for the larger, multi-layer
## rooms the big-map chapters use. MDS stays the authority for the room
## rectangles, camera limits, weather and animated background: a room built by
## [MDSBigRoom] reads those from the world at runtime. [member size] is only the
## fallback used outside an MDS world (unit tests, greybox scenes); when the
## room is loaded by an [MDSWorldGame], the world's local-rect union wins.
##
## Coordinates are room-local pixels, y down, origin at the MDS room origin:
## - [member ground] entries: {x, y, width, height = 64}. `x` is the left edge,
##   `y` the walkable surface, `height` the visual fill below it. Terraces are
##   separate entries at different `y`.
## - [member platforms] entries: {x, y, width}. `x` is the left edge, `y` the
##   walkable surface; every platform is 16 px thick.
## With a [member tile_set] assigned, every surface snaps to the 16 px tile grid
## so the drawn tiles and the collision rectangles share edges.
##
## Vertical authoring follows the existing movement budget: the player's jump
## peaks at ~92.6 px (jump_velocity -500, gravity 1350 in player.gd), so
## [method validate] rejects any surface more than [constant MAX_STEP] above the
## surface it would be climbed from. Horizontal gaps between those surfaces are
## allowed up to [constant MAX_HORIZONTAL_STEP]; the jump reaches ~150 px
## horizontally at an 80 px rise, minus body/landing margins.

const TILE_SIZE := 16
## Peak of the player's jump with the exported defaults in scripts/player/player.gd.
const MAX_JUMP_HEIGHT := 500.0 * 500.0 / (2.0 * 1350.0)
## Authored steps stay below the jump peak so a climb never needs frame-perfect input.
const MAX_STEP := 80.0
## Edge-to-edge horizontal gap accepted between a surface and its climb source.
const MAX_HORIZONTAL_STEP := 120.0
const DEFAULT_GROUND_HEIGHT := 64.0
const PLATFORM_HEIGHT := 16.0

@export var size: Vector2i = Vector2i(1280, 720)
@export var ground: Array[Dictionary] = []
@export var platforms: Array[Dictionary] = []

@export_group("Tile visuals")
## Optional. Without it the room is greyboxed with flat colour rectangles.
@export var tile_set: TileSet
@export var ground_tile: Vector2i = Vector2i(0, 0)
@export var ground_fill_tile: Vector2i = Vector2i(1, 0)
@export var platform_tile: Vector2i = Vector2i(2, 0)
@export var platform_fill_tile: Vector2i = Vector2i(3, 0)
@export var ground_color: Color = Color("183039")
@export var ground_edge_color: Color = Color("74b3a7")
@export var platform_color: Color = Color("183039")
@export var platform_edge_color: Color = Color("74b3a7")

@export_group("Backdrop")
## Per-room override. Empty: the room/area/world `backdrop_image` from the MDS
## world file, so big-map areas own their art instead of a chapter-wide image.
@export_file("*.png", "*.jpg", "*.webp") var backdrop_path: String = ""
## Test/greybox override; wins over [member backdrop_path] and the world.
@export var backdrop_texture: Texture2D
## Integer scale keeps pixel art crisp; the image tiles across the room union.
@export_range(1, 8, 1) var backdrop_scale: int = 1
@export var backdrop_pixel_art: bool = true
@export var backdrop_modulate: Color = Color.WHITE

@export_group("Ambience")
## Light motes drawn only inside the camera window: "none", "motes" or "embers".
@export var ambient_kind: StringName = &"none"
## Transparent: use the MDS area colour, so each area gets its own tint.
@export var ambient_color: Color = Color(0, 0, 0, 0)
@export_range(0.0, 2.0, 0.05) var ambient_density: float = 0.5


## The rectangle the room's geometry is authored against: the MDS union bounds
## when available, else [member size] anchored at (0, 0).
func effective_bounds(world_bounds := Rect2()) -> Rect2:
	if world_bounds.size.x > 0.0 and world_bounds.size.y > 0.0:
		return world_bounds
	return Rect2(Vector2.ZERO, Vector2(maxi(size.x, 1), maxi(size.y, 1)))


## Ground rectangles after tile snapping (no validation errors reported).
func ground_rects(world_bounds := Rect2()) -> Array[Rect2]:
	return _read_surfaces(ground, true, effective_bounds(world_bounds), PackedStringArray())


## Platform rectangles after tile snapping (no validation errors reported).
func platform_rects(world_bounds := Rect2()) -> Array[Rect2]:
	return _read_surfaces(platforms, false, effective_bounds(world_bounds), PackedStringArray())


## Everything [MDSBigRoom] cannot build safely: malformed entries, geometry
## outside the room union, and vertical steps beyond the jump budget. Empty
## means the room can be built.
func validate(world_bounds := Rect2()) -> PackedStringArray:
	var errors := PackedStringArray()
	var has_world := world_bounds.size.x > 0.0 and world_bounds.size.y > 0.0
	if not has_world and (size.x <= 0 or size.y <= 0):
		errors.append("room size must be positive")
	var bounds := effective_bounds(world_bounds)
	var surfaces: Array[Rect2] = []
	surfaces.append_array(_read_surfaces(ground, true, bounds, errors))
	surfaces.append_array(_read_surfaces(platforms, false, bounds, errors))
	for index in surfaces.size():
		var support := _support_index(surfaces, index)
		if support >= 0:
			var rise := surfaces[support].position.y - surfaces[index].position.y
			if rise > MAX_STEP + 0.01:
				errors.append("surface %d at y=%.0f is %.0f px above its support at y=%.0f (max %.0f)"
					% [index, surfaces[index].position.y, rise,
						surfaces[support].position.y, MAX_STEP])
		elif not _is_lowest(surfaces, index):
			errors.append("surface %d at y=%.0f has no surface below it to climb from"
				% [index, surfaces[index].position.y])
	return errors


func _read_surfaces(entries: Array[Dictionary], is_ground: bool, bounds: Rect2,
		errors: PackedStringArray) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var prefix := "ground" if is_ground else "platform"
	for index in entries.size():
		var entry: Dictionary = entries[index]
		var label := "%s[%d]" % [prefix, index]
		var x := _number(entry.get("x", null))
		var y := _number(entry.get("y", null))
		var width := _number(entry.get("width", null))
		if is_nan(x) or is_nan(y) or is_nan(width):
			errors.append("%s needs numeric x, y and width" % label)
			continue
		if width <= 0.0:
			errors.append("%s has a non-positive width" % label)
			continue
		# Ground carries its fill height; platforms are always one tile thick so
		# the drawn top row and the collision rectangle cannot drift apart.
		var height := PLATFORM_HEIGHT
		if is_ground:
			height = _number(entry.get("height", DEFAULT_GROUND_HEIGHT))
		if is_nan(height) or height <= 0.0:
			errors.append("%s has a non-positive height" % label)
			continue
		var rect := _snap_rect(Rect2(x, y, width, height))
		if not _inside(rect, bounds):
			errors.append("%s at (%.0f, %.0f), %s leaves the room bounds %s"
				% [label, x, y, rect.size, bounds])
		out.append(rect)
	return out


func _snap_rect(rect: Rect2) -> Rect2:
	if tile_set == null:
		return rect
	var left := floorf(rect.position.x / TILE_SIZE) * TILE_SIZE
	var right := ceilf(rect.end.x / TILE_SIZE) * TILE_SIZE
	var top := roundf(rect.position.y / TILE_SIZE) * TILE_SIZE
	var rows := maxi(1, int(ceilf(rect.size.y / TILE_SIZE)))
	return Rect2(left, top, maxf(TILE_SIZE, right - left), rows * TILE_SIZE)


func _inside(rect: Rect2, bounds: Rect2) -> bool:
	return rect.position.x >= bounds.position.x - 0.5 \
		and rect.position.y >= bounds.position.y - 0.5 \
		and rect.end.x <= bounds.end.x + 0.5 \
		and rect.end.y <= bounds.end.y + 0.5


## Index of the closest surface below [param index] that it can be climbed from,
## or -1. "Below" is a larger y; the climb source is the highest such surface
## whose x span overlaps or is within [constant MAX_HORIZONTAL_STEP].
func _support_index(surfaces: Array[Rect2], index: int) -> int:
	var best := -1
	var best_y := INF
	for other in surfaces.size():
		if other == index:
			continue
		var candidate := surfaces[other]
		if candidate.position.y <= surfaces[index].position.y + 0.01:
			continue
		if not _within_horizontal_reach(surfaces[index], candidate):
			continue
		if candidate.position.y < best_y:
			best_y = candidate.position.y
			best = other
	return best


func _within_horizontal_reach(surface: Rect2, support: Rect2) -> bool:
	var gap := maxf(support.position.x - surface.end.x, surface.position.x - support.end.x)
	return gap <= MAX_HORIZONTAL_STEP + 0.01


func _is_lowest(surfaces: Array[Rect2], index: int) -> bool:
	for other in surfaces.size():
		if other != index and surfaces[other].position.y > surfaces[index].position.y + 0.01:
			return false
	return true


static func _number(value: Variant) -> float:
	if value is int or value is float:
		return float(value)
	return NAN
