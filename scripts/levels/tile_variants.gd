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
