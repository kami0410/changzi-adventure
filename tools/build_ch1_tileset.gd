extends SceneTree

## Rebuilds resources/tiles/ch1_tiles.tres from assets/tiles/ch1/tiles.png.
## Run: godot --headless --path . --script tools/build_ch1_tileset.gd

const TEXTURE := "res://assets/tiles/ch1/tiles.png"
const OUT := "res://resources/tiles/ch1_tiles.tres"
const TILE_SIZE := Vector2i(16, 16)
const TILE_COUNT := 4


func _initialize() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = TILE_SIZE
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)

	var source := TileSetAtlasSource.new()
	source.texture = load(TEXTURE)
	source.texture_region_size = TILE_SIZE
	# The source must belong to the TileSet before tile data can see the
	# physics layer configured above.
	tile_set.add_source(source, 0)
	for column in TILE_COUNT:
		var coords := Vector2i(column, 0)
		source.create_tile(coords)
		var data := source.get_tile_data(coords, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, PackedVector2Array([
			Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8),
		]))

	var directory := DirAccess.open("res://resources")
	if directory != null and not directory.dir_exists("tiles"):
		directory.make_dir("tiles")
	var error := ResourceSaver.save(tile_set, OUT)
	print("CH1 TILESET ", "saved" if error == OK else "error %d" % error)
	quit(0 if error == OK else 1)
