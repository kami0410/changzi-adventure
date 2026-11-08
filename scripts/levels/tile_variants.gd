class_name TileVariants
extends RefCounted

## Terrain atlases keep the base tiles on row 0 and their variants one row
## below (see tools/build_chapter_tiles.py). These helpers pick a variant by
## cell position, so the choice is stable across rebuilds, and fall back to
## the base tile when an atlas has no variant row.


## Base tile or its row-1 variant (about one cell in three).
static func pick(tile_set: TileSet, base: Vector2i, column: int, row: int) -> Vector2i:
	var variant := base + Vector2i(0, 1)
	if not _has(tile_set, variant):
		return base
	var h := absi(hash(Vector2i(column, row))) % 3
	return variant if h == 0 else base


## Ground fill: the base fill right under the surface, the darker deep fill
## from the third row down.
static func fill(tile_set: TileSet, base: Vector2i, depth: int) -> Vector2i:
	var deep := base + Vector2i(0, 1)
	if depth >= 3 and _has(tile_set, deep):
		return deep
	return base


static func _has(tile_set: TileSet, coords: Vector2i) -> bool:
	if tile_set == null or not tile_set.has_source(0):
		return false
	var source := tile_set.get_source(0) as TileSetAtlasSource
	return source != null and source.has_tile(coords)


## Draws a platform as terrain tiles on [param canvas]: the atlas's platform
## top tile across [param rect] (16 px rows) and its hanging underside tile one
## row below. Used by the prop platforms so they match the chapter tiles.
static func draw_platform_strip(canvas: CanvasItem, atlas: Texture2D, rect: Rect2,
		modulate := Color.WHITE, offset := Vector2.ZERO) -> void:
	if atlas == null:
		return
	var columns := maxi(1, int(ceilf(rect.size.x / 16.0)))
	for column in columns:
		var x := rect.position.x + column * 16.0
		var w := minf(16.0, rect.end.x - x)
		var variant := 16.0 if absi(hash(column * 7 + int(rect.position.x))) % 3 == 0 else 0.0
		canvas.draw_texture_rect_region(atlas, Rect2(Vector2(x, rect.position.y) + offset, Vector2(w, 16)),
			Rect2(32, variant, w, 16), modulate)
		canvas.draw_texture_rect_region(atlas, Rect2(Vector2(x, rect.position.y + 16.0) + offset, Vector2(w, 16)),
			Rect2(48, variant, w, 16), modulate)
