class_name RoomDressing
extends Node2D

## Visual dressing that gives every big-map region its own look (0.14).
##
## - Parallax: the painted backdrop holder drifts at [constant BACKDROP_FACTOR]
##   of the camera and a mid-ground band (cut from another painting) at
##   [constant MID_FACTOR], so the room reads in depth instead of as a flat
##   wall. Extra mirrored tiles around the backdrop keep the edges covered.
## - Props: chapter floor props placed from the room id seed on ground and
##   platform surfaces, clear of gates and interactables; some glow/flicker
##   and kelp sways.
## Purely visual: no collision, no input, no save state.

const BACKDROP_FACTOR := Vector2(0.3, 0.55)
const MID_FACTOR := Vector2(0.62, 0.8)
const MID_Z := -16
const PROP_Z := -3
const PROP_SIZE := 64
## Atlas slot -> glow colour for props that emit light, per chapter.
const GLOWS := {
	1: {1: Color(1.0, 0.75, 0.4)},
	2: {4: Color(1.0, 0.7, 0.35)},
	3: {3: Color(0.4, 1.0, 0.9), 4: Color(0.5, 1.0, 0.85)},
	4: {0: Color(1.0, 0.8, 0.5)},
}
## Atlas slots that sway (kelp).
const SWAY := {2: [5], 3: [2]}

var chapter := 0
var room_id := ""
var backdrop_holder: Node2D
var mid_holder: Node2D
var props: Array[Sprite2D] = []
var _bounds := Rect2()
var _tile_size := Vector2.ZERO
var _glows: Array[Sprite2D] = []
var _sway: Array[Sprite2D] = []
var _time := 0.0

static var _glow_texture: Texture2D


## Chapter number (1–4) and region id from a BigRoomData path such as
## res://resources/rooms/ch3_bigmap/ch3_well.tres.
static func parse_room(path: String) -> Dictionary:
	var file := path.get_file().get_basename()
	if file.length() < 3 or not file.begins_with("ch") or not file.substr(2, 1).is_valid_int():
		return {}
	return {"chapter": int(file.substr(2, 1)), "room": file}


func setup(room_bounds: Rect2, backdrop: Node2D, tile_size: Vector2, info: Dictionary) -> void:
	_bounds = room_bounds
	backdrop_holder = backdrop
	_tile_size = tile_size
	chapter = int(info.get("chapter", 0))
	room_id = String(info.get("room", ""))
	if backdrop_holder != null and _tile_size.x > 0.0:
		_add_backdrop_margin()
	if chapter >= 2:
		_build_mid_layer()
		_build_shaft_walls()


## Extra mirrored tiles on both sides and one row below the backdrop grid, so
## the parallax offset never shows the clear colour. Kept out of the room's
## `backdrop_tiles` list, which describes the authored cover.
func _add_backdrop_margin() -> void:
	var tiles: Array[Sprite2D] = []
	for child in backdrop_holder.get_children():
		if child is Sprite2D:
			tiles.append(child)
	if tiles.is_empty():
		return
	var min_x := INF
	var max_x := -INF
	var max_y := -INF
	for tile in tiles:
		min_x = minf(min_x, tile.position.x)
		max_x = maxf(max_x, tile.position.x)
		max_y = maxf(max_y, tile.position.y)
	var extra: Array[Sprite2D] = []
	for tile in tiles:
		if is_equal_approx(tile.position.x, min_x):
			extra.append(_clone(tile, Vector2(-_tile_size.x, 0), true, false))
		if is_equal_approx(tile.position.x, max_x):
			extra.append(_clone(tile, Vector2(_tile_size.x, 0), true, false))
	for tile in tiles + extra:
		if is_equal_approx(tile.position.y, max_y):
			backdrop_holder.add_child(_clone(tile, Vector2(0, _tile_size.y), false, true))
	for tile in extra:
		backdrop_holder.add_child(tile)


func _clone(tile: Sprite2D, shift: Vector2, mirror_h: bool, mirror_v: bool) -> Sprite2D:
	var copy := Sprite2D.new()
	copy.name = "%s_margin" % tile.name
	copy.texture = tile.texture
	copy.scale = tile.scale
	copy.position = tile.position + shift
	copy.flip_h = tile.flip_h != mirror_h
	copy.flip_v = tile.flip_v != mirror_v
	copy.z_index = tile.z_index
	copy.modulate = tile.modulate
	copy.texture_filter = tile.texture_filter
	copy.set_meta(&"backdrop_margin", true)
	return copy


func _build_mid_layer() -> void:
	var variant := "a" if absi(hash(room_id)) % 2 == 0 else "b"
	var path := "res://assets/backgrounds/layers/ch%d_mid_%s.png" % [chapter, variant]
	if not ResourceLoader.exists(path):
		return
	var texture := load(path) as Texture2D
	if texture == null:
		return
	mid_holder = Node2D.new()
	mid_holder.name = "MidLayer"
	add_child(mid_holder)
	var size := Vector2(texture.get_width(), texture.get_height())
	var flip := absi(hash(room_id + "flip")) % 2 == 1
	var start := _bounds.position.x - size.x
	var count := int(ceilf((_bounds.size.x + size.x * 2.0) / size.x))
	for i in count:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.position = Vector2(start + i * size.x, _bounds.end.y - size.y + 40.0)
		sprite.flip_h = flip != (i % 2 == 1)
		sprite.z_index = MID_Z
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		mid_holder.add_child(sprite)
		# Tall shafts also hang the band from the ceiling, so the upper part of
		# the climb has structure instead of an empty haze.
		if _bounds.size.y > 1500.0:
			var hanging := sprite.duplicate() as Sprite2D
			hanging.flip_v = true
			hanging.flip_h = not sprite.flip_h
			hanging.position = Vector2(sprite.position.x + size.x * 0.37, _bounds.position.y - 40.0)
			hanging.modulate = Color(0.8, 0.8, 0.85)
			mid_holder.add_child(hanging)


## Distant masonry walls down both sides of a tall shaft, textured with the
## chapter's deep fill tile and pushed back (dark, parallax with the mid
## layer), so a climb always has structure beside it.
func _build_shaft_walls() -> void:
	# Only the vertical-shaft regions; tall boss/elite arenas keep the open
	# painting behind the fight.
	if _bounds.size.y <= 1500.0 or mid_holder == null or not room_id.ends_with("_well"):
		return
	var atlas_path := "res://assets/tiles/ch%d/tiles.png" % chapter
	if not ResourceLoader.exists(atlas_path):
		return
	var atlas := load(atlas_path) as Texture2D
	if atlas == null:
		return
	var image := atlas.get_image()
	if image == null:
		return
	var tile := ImageTexture.create_from_image(image.get_region(Rect2i(16, 0, 16, 16)))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("shaft|" + room_id)
	_add_shaft_pillars(tile, rng)
	for side in [-1.0, 1.0]:
		var points := PackedVector2Array()
		var outer := _bounds.position.x - 400.0 if side < 0 else _bounds.end.x + 400.0
		var top := _bounds.position.y - 200.0
		var bottom := _bounds.end.y + 200.0
		points.append(Vector2(outer, top))
		var y := top
		while y < bottom:
			var depth := rng.randf_range(160.0, 380.0)
			var edge := _bounds.position.x + depth if side < 0 else _bounds.end.x - depth
			points.append(Vector2(edge, y))
			y += rng.randf_range(90.0, 220.0)
			points.append(Vector2(edge, y))
		points.append(Vector2(outer, bottom))
		var wall := Polygon2D.new()
		wall.polygon = points
		wall.texture = tile
		wall.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wall.texture_scale = Vector2(0.5, 0.5)
		wall.color = Color(0.78, 0.8, 0.86)
		wall.z_index = MID_Z - 1
		mid_holder.add_child(wall)
		# A pale rim along the inner edge catches the shaft's light.
		var rim := Line2D.new()
		for i in range(1, points.size() - 1):
			rim.add_point(points[i])
		rim.width = 2.0
		rim.default_color = Color(0.75, 0.85, 0.85, 0.3)
		rim.z_index = MID_Z - 1
		mid_holder.add_child(rim)


## Background pillars and cross beams through the full shaft height.
func _add_shaft_pillars(tile: Texture2D, rng: RandomNumberGenerator) -> void:
	var x := _bounds.position.x + rng.randf_range(420.0, 640.0)
	var pillars: Array[float] = []
	while x < _bounds.end.x - 380.0:
		var w := rng.randf_range(70.0, 130.0)
		var pillar := Polygon2D.new()
		pillar.polygon = PackedVector2Array([
			Vector2(x, _bounds.position.y - 200.0), Vector2(x + w, _bounds.position.y - 200.0),
			Vector2(x + w, _bounds.end.y + 200.0), Vector2(x, _bounds.end.y + 200.0)])
		pillar.texture = tile
		pillar.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		pillar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pillar.texture_scale = Vector2(0.5, 0.5)
		pillar.color = Color(0.5, 0.52, 0.58)
		pillar.z_index = MID_Z - 2
		mid_holder.add_child(pillar)
		pillars.append(x + w * 0.5)
		x += w + rng.randf_range(520.0, 900.0)
	var y := _bounds.position.y + rng.randf_range(200.0, 400.0)
	while y < _bounds.end.y - 500.0:
		var beam := Polygon2D.new()
		var h := rng.randf_range(26.0, 44.0)
		beam.polygon = PackedVector2Array([
			Vector2(_bounds.position.x - 200.0, y), Vector2(_bounds.end.x + 200.0, y),
			Vector2(_bounds.end.x + 200.0, y + h), Vector2(_bounds.position.x - 200.0, y + h)])
		beam.texture = tile
		beam.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		beam.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		beam.texture_scale = Vector2(0.5, 0.5)
		beam.color = Color(0.42, 0.44, 0.5)
		beam.z_index = MID_Z - 2
		mid_holder.add_child(beam)
		y += rng.randf_range(420.0, 640.0)


## Places floor props on [param surfaces] (room-local rects; y = walkable
## top). [param avoid] are room-local points props must keep clear of.
func place_props(surfaces: Array[Rect2], avoid: Array[Vector2]) -> void:
	if chapter < 1 or chapter > 4:
		return
	var path := "res://assets/sprites/props/dressing_ch%d.png" % chapter
	if not ResourceLoader.exists(path):
		return
	var atlas := load(path) as Texture2D
	if atlas == null:
		return
	var slots := int(atlas.get_width() / PROP_SIZE)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("dressing|" + room_id)
	for rect in surfaces:
		var x := rect.position.x + rng.randf_range(20.0, 120.0)
		while x < rect.end.x - 24.0:
			var spot := Vector2(x, rect.position.y)
			if _clear(spot, avoid) and rng.randf() < 0.7:
				_add_prop(atlas, rng.randi_range(0, slots - 1), spot, rng)
			x += rng.randf_range(110.0, 260.0)


func _clear(spot: Vector2, avoid: Array[Vector2]) -> bool:
	for point in avoid:
		if absf(point.x - spot.x) < 90.0 and absf(point.y - spot.y) < 140.0:
			return false
	return true


func _add_prop(atlas: Texture2D, slot: int, spot: Vector2, rng: RandomNumberGenerator) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Prop%d" % props.size()
	sprite.texture = atlas
	sprite.region_enabled = true
	sprite.region_rect = Rect2(slot * PROP_SIZE, 0, PROP_SIZE, PROP_SIZE)
	sprite.centered = false
	# Origin at the feet so sway pivots on the floor.
	sprite.offset = Vector2(-PROP_SIZE * 0.5, -PROP_SIZE)
	sprite.position = spot.round()
	sprite.flip_h = rng.randf() < 0.5
	sprite.z_index = PROP_Z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Props sit a little back from the action: slightly darker than actors.
	sprite.modulate = Color(0.82, 0.82, 0.86)
	add_child(sprite)
	props.append(sprite)
	var glow_color: Variant = (GLOWS.get(chapter, {}) as Dictionary).get(slot, null)
	if glow_color is Color:
		var glow := Sprite2D.new()
		glow.texture = _glow()
		glow.position = spot + Vector2(0, -PROP_SIZE * 0.55)
		glow.modulate = Color(glow_color, 0.55)
		glow.scale = Vector2.ONE * 1.6
		glow.z_index = PROP_Z + 1
		var additive := CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = additive
		glow.set_meta(&"phase", rng.randf() * TAU)
		add_child(glow)
		_glows.append(glow)
		if chapter == 3:
			# The Lightless Sea is dark (MDS darkness); lanterns and anemones
			# push a little real light back into it.
			var light := PointLight2D.new()
			light.texture = MDSWorldGame.radial_light_texture()
			light.texture_scale = 1.4
			light.color = glow_color
			light.energy = 0.9
			light.position = glow.position
			add_child(light)
	if (SWAY.get(chapter, []) as Array).has(slot):
		sprite.set_meta(&"phase", rng.randf() * TAU)
		_sway.append(sprite)


static func _glow() -> Texture2D:
	if _glow_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 0.9))
		gradient.set_color(1, Color(1, 1, 1, 0))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(0.5, 0.0)
		texture.width = 96
		texture.height = 96
		_glow_texture = texture
	return _glow_texture


func _process(delta: float) -> void:
	_time += delta
	_update_parallax()
	for glow in _glows:
		var phase: float = glow.get_meta(&"phase", 0.0)
		glow.modulate.a = 0.42 + 0.13 * sin(_time * 7.0 + phase) + 0.05 * sin(_time * 17.0 + phase)
	for sprite in _sway:
		var phase: float = sprite.get_meta(&"phase", 0.0)
		sprite.rotation = sin(_time * 1.3 + phase) * 0.06


## Offset of the camera centre from the room centre, in room space.
func camera_delta() -> Vector2:
	if not is_inside_tree():
		return Vector2.ZERO
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return Vector2.ZERO
	var parent := get_parent() as Node2D
	var center_local := parent.to_local(camera.get_screen_center_position()) if parent != null \
		else camera.get_screen_center_position()
	return center_local - _bounds.get_center()


func _update_parallax() -> void:
	var delta := camera_delta()
	if backdrop_holder != null and is_instance_valid(backdrop_holder):
		var shift := delta * (Vector2.ONE - BACKDROP_FACTOR)
		if _tile_size.x > 0.0:
			shift = shift.clamp(-_tile_size * 0.95, _tile_size * 0.95)
		backdrop_holder.position = shift.round()
	if mid_holder != null:
		var mid_shift := delta * (Vector2.ONE - MID_FACTOR)
		mid_shift.y = maxf(mid_shift.y, -60.0)
		mid_holder.position = mid_shift.round()
