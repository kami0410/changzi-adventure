class_name MDSBigRoom
extends Node2D

## Production-line builder for the big-map rooms of chapters 2–4.
##
## Chapter 1 keeps [MDSChapterRoom] and its fixed 1280x720 template untouched.
## This node is data-driven ([BigRoomData]) and places itself inside whatever
## rectangle union MDS loads, so one scene can cover a 2560x1440 hall, an
## L-shaped 3840x1440 zone or any other world-authored size. MDS still owns the
## room rectangles, camera limits, weather and animated background; this builder
## only reads them and adds the geometry, tiled static backdrop, optional
## camera-culled ambience and (from the world file) the room's gates.
##
## The room scene root is expected to be this node: it finds its
## [MDSWorldGame] through [method get_parent]. Room-local coordinates match
## MDS's local rects (origin at the room origin), so gate positions in the world
## file and authored ground lines share one space.

## Name of the [GateVisual] child added to every gate. Authored scenes may put
## their own marker with this name on a gate to override the generated one.
const GATE_VISUAL_NAME := "GateVisual"

## Room-local union of the MDS room rectangles (or the data fallback size).
var room_bounds := Rect2()
## Last validation report from [BigRoomData.validate]; empty when buildable.
var validation_errors := PackedStringArray()
## Effective rectangles actually built, after tile snapping.
var built_ground_surfaces: Array[Rect2] = []
var built_platform_surfaces: Array[Rect2] = []
## Backdrop sprites, in row-major order; together they cover [member room_bounds].
var backdrop_tiles: Array[Sprite2D] = []
## Resolved room/area/world look, for debugging and tests.
var area_info: Dictionary = {}

@export var data: BigRoomData
## Optional resource path used when [member data] is not assigned in the scene.
@export_file("*.tres") var data_path: String = ""
## Generate the gates the world file defines for this room. Authored gates with
## the same name win, so scenes can still override a door's prompt or visuals.
@export var auto_gates: bool = true
## Fall plane published as room metadata, in px below the union's bottom edge.
## Chapter plans still take precedence in game.gd's fall resolver.
@export var fall_margin: float = 200.0

var _generated: Array[Node] = []


func _ready() -> void:
	if data == null and not data_path.is_empty():
		data = load(data_path) as BigRoomData
	build()


## (Re)builds every generated node. Safe to call again after changing
## [member data]; authored children (arenas, chests, gates) are kept.
func build() -> void:
	_clear_generated()
	_resolve_room_bounds()
	# Authored props (moving platforms, elevators) run `_ready` before their
	# parent, so hand them the resolved union once it exists.
	_notify_child_bounds()
	area_info = _resolve_area_info()
	if data == null:
		return
	validation_errors = data.validate(room_bounds)
	for issue in validation_errors:
		push_warning("MDSBigRoom '%s': %s" % [String(name), issue])
	_build_backdrop()
	_build_ground()
	_build_platforms()
	_notify_child_surfaces()
	_build_ambient()
	_build_gates()
	_publish_fall_plane()


## Rect covered by the tiled backdrop, in room-local px, clipped to the room.
## Empty without a texture. Mirrored rows may extend past the top edge (the
## bottom row is anchored at the floor), so the clip reports the usable cover.
func backdrop_rect_local() -> Rect2:
	var covered := Rect2()
	var first := true
	for tile in backdrop_tiles:
		if not is_instance_valid(tile) or tile.texture == null:
			continue
		var half := Vector2(tile.texture.get_width(), tile.texture.get_height()) * tile.scale * 0.5
		var rect := Rect2(tile.position - half, half * 2.0)
		covered = rect if first else covered.merge(rect)
		first = false
	if first:
		return covered
	return covered.intersection(room_bounds)


func _clear_generated() -> void:
	for node in _generated:
		if not is_instance_valid(node):
			continue
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.free()
	_generated.clear()
	backdrop_tiles.clear()
	built_ground_surfaces.clear()
	built_platform_surfaces.clear()
	validation_errors = PackedStringArray()
	area_info = {}


func _track(node: Node) -> void:
	_generated.append(node)


func _resolve_room_bounds() -> void:
	var fallback := Rect2(Vector2.ZERO, Vector2(1280, 720))
	if data != null:
		fallback = Rect2(Vector2.ZERO,
			Vector2(maxi(data.size.x, 1), maxi(data.size.y, 1)))
	room_bounds = fallback
	var game := get_parent() as MDSWorldGame
	if game == null or game.world == null or game.current_room.is_empty():
		return
	var rects := game.world.get_local_rects(game.current_room)
	if rects.is_empty():
		return
	var merged := rects[0]
	for index in range(1, rects.size()):
		merged = merged.merge(rects[index])
	room_bounds = merged


## Static backdrop comes from the room scene first, then the MDS room, area and
## world (`backdrop_image`), so each big-map area owns its own art. Weather,
## animated background and parallax are read from MDS and stay area-scoped.
func _resolve_area_info() -> Dictionary:
	var info := {
		"room": "",
		"area": "",
		"source": "data",
		"backdrop_image": "",
		"backdrop_source": "none",
		"weather": "",
		"background": "",
		"parallax": "",
		"color": Color.WHITE,
	}
	if data != null:
		if data.backdrop_texture != null:
			info.backdrop_source = "texture"
		elif not data.backdrop_path.is_empty():
			info.backdrop_image = data.backdrop_path
			info.backdrop_source = "data"
	var game := get_parent() as MDSWorldGame
	if game == null or game.world == null or game.current_room.is_empty():
		return info
	var world := game.world
	var room_id := game.current_room
	var area := world.get_room_area(room_id)
	info.room = room_id
	info.area = area
	info.source = "world"
	if not area.is_empty():
		info.color = world.get_area_color(area)
	info.weather = MDSEnvironment.spec_for_room(world, room_id)
	info.background = MDSEnvironment.background_for_room(world, room_id)
	info.parallax = MDSEnvironment.parallax_for_room(world, room_id)
	if info.backdrop_source == "texture":
		return info
	var lookups: Array = [
		["room", str(world.get_room_value(room_id, "backdrop_image", ""))],
		["area", str(world.get_areas().get(area, {}).get("backdrop_image", ""))],
		["world", str(world.get_setting("backdrop_image", ""))],
	]
	for lookup in lookups:
		var path := String(lookup[1]).strip_edges()
		if not path.is_empty():
			info.backdrop_image = path
			info.backdrop_source = String(lookup[0])
			break
	return info


func _build_backdrop() -> void:
	var texture: Texture2D = null
	if data != null:
		texture = data.backdrop_texture
	if texture == null:
		var path := String(area_info.get("backdrop_image", ""))
		if not path.is_empty() and ResourceLoader.exists(path):
			texture = load(path) as Texture2D
	if texture == null:
		return
	var tile_scale := maxi(1, data.backdrop_scale if data != null else 1)
	var tile_size := Vector2(texture.get_width(), texture.get_height()) * tile_scale
	if tile_size.x <= 0.0 or tile_size.y <= 0.0:
		return
	var columns := maxi(1, int(ceilf(room_bounds.size.x / tile_size.x)))
	var rows := maxi(1, int(ceilf(room_bounds.size.y / tile_size.y)))
	var holder := Node2D.new()
	holder.name = "Backdrop"
	add_child(holder)
	_track(holder)
	var pixel_art := data == null or data.backdrop_pixel_art
	var modulate := data.backdrop_modulate if data != null else Color.WHITE
	for row in rows:
		# Anchor the grid at the room's floor: the bottom row puts the painting's
		# own floor line on the room bottom, where the playable ground is, and
		# only the rows above it are clipped. Rows above the floor row are
		# mirrored so two vertically adjacent tiles always share their edge row
		# instead of butting a sky against a foreground floor. The paintings are
		# not vertically tileable and the big-map rooms are 1440/2160 px tall
		# (not a multiple of the 864 px art), so without this a floor strip was
		# repeated mid-air and the seam cut across the entry and boss framings.
		var from_bottom := rows - 1 - row
		var tile_top := room_bounds.end.y - float(from_bottom + 1) * tile_size.y
		for column in columns:
			var tile := Sprite2D.new()
			tile.name = "Tile_%d_%d" % [column, row]
			tile.texture = texture
			tile.centered = true
			tile.scale = Vector2.ONE * tile_scale
			tile.position = Vector2(
				room_bounds.position.x + (column + 0.5) * tile_size.x,
				tile_top + tile_size.y * 0.5)
			tile.flip_v = (from_bottom % 2) == 1
			tile.z_index = -20
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST \
				if pixel_art else CanvasItem.TEXTURE_FILTER_LINEAR
			tile.modulate = modulate * backdrop_depth_tint(from_bottom)
			holder.add_child(tile)
			backdrop_tiles.append(tile)


## The painted backdrops are as bright and busy as the foreground, so the
## player and platforms got lost in them. Every row is pushed back (dimmer,
## slightly cooler), and the mirrored rows above the floor row fade further
## toward darkness, so a tall shaft reads as depth instead of a reflection.
const BACKDROP_DEPTH := Color(0.7, 0.72, 0.8, 1.0)
const BACKDROP_ROW_FADE := 0.62
const BACKDROP_MIN_FADE := 0.28


static func backdrop_depth_tint(from_bottom: int) -> Color:
	var fade := maxf(pow(BACKDROP_ROW_FADE, float(maxi(from_bottom, 0))), BACKDROP_MIN_FADE)
	return Color(BACKDROP_DEPTH.r * fade, BACKDROP_DEPTH.g * fade, BACKDROP_DEPTH.b * fade, 1.0)


## Visual-only ground rows drawn under a floor that sits on the room bottom.
const UNDERFLOOR_ROWS := 8


func _build_ground() -> void:
	if data == null:
		return
	built_ground_surfaces = data.ground_rects(room_bounds)
	if built_ground_surfaces.is_empty():
		return
	if data.tile_set != null:
		var fill := _make_tile_layer("GroundFill")
		var tiles := _make_tile_layer("GroundTiles")
		for rect in built_ground_surfaces:
			var row := int(roundf(rect.position.y / BigRoomData.TILE_SIZE))
			var first := int(floorf(rect.position.x / BigRoomData.TILE_SIZE))
			var last := int(ceilf(rect.end.x / BigRoomData.TILE_SIZE)) - 1
			var rows := maxi(1, int(roundf(rect.size.y / BigRoomData.TILE_SIZE)))
			# Ground on the room's bottom edge continues below it (visual only):
			# the camera may look past the floor to clear the bottom HUD.
			if rect.end.y >= room_bounds.end.y - 1.0:
				rows += UNDERFLOOR_ROWS
			for column in range(first, last + 1):
				tiles.set_cell(Vector2i(column, row), 0, TileVariants.pick(data.tile_set, data.ground_tile, column, row))
				for extra in range(1, rows):
					fill.set_cell(Vector2i(column, row + extra), 0,
						TileVariants.fill(data.tile_set, data.ground_fill_tile, extra))
	else:
		var visual := Node2D.new()
		visual.name = "GroundVisual"
		add_child(visual)
		_track(visual)
		for rect in built_ground_surfaces:
			_add_rect_visual(visual, rect, data.ground_color, data.ground_edge_color)
	_add_collision("GroundCollision", "Ground", built_ground_surfaces)


func _build_platforms() -> void:
	if data == null:
		return
	built_platform_surfaces = data.platform_rects(room_bounds)
	if built_platform_surfaces.is_empty():
		return
	if data.tile_set != null:
		var fill := _make_tile_layer("PlatformFill")
		var tiles := _make_tile_layer("PlatformTiles")
		for rect in built_platform_surfaces:
			var row := int(roundf(rect.position.y / BigRoomData.TILE_SIZE))
			var first := int(floorf(rect.position.x / BigRoomData.TILE_SIZE))
			var last := int(ceilf(rect.end.x / BigRoomData.TILE_SIZE)) - 1
			for column in range(first, last + 1):
				tiles.set_cell(Vector2i(column, row), 0, TileVariants.pick(data.tile_set, data.platform_tile, column, row))
				fill.set_cell(Vector2i(column, row + 1), 0,
					TileVariants.pick(data.tile_set, data.platform_fill_tile, column + 7, row))
	else:
		var visual := Node2D.new()
		visual.name = "PlatformVisual"
		add_child(visual)
		_track(visual)
		for rect in built_platform_surfaces:
			_add_rect_visual(visual, rect, data.platform_color, data.platform_edge_color)
	_add_collision("PlatformCollision", "Platform", built_platform_surfaces)


func _make_tile_layer(layer_name: String) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = data.tile_set
	# Collision is a handful of rectangle bodies instead of one collider per
	# tile, so a big room stays cheap and its edges are exact.
	layer.collision_enabled = false
	add_child(layer)
	_track(layer)
	return layer


func _add_rect_visual(holder: Node2D, rect: Rect2, color: Color, edge_color: Color) -> void:
	var body := ColorRect.new()
	body.position = rect.position
	body.size = rect.size
	body.color = color
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(body)
	var edge := ColorRect.new()
	edge.position = rect.position
	edge.size = Vector2(rect.size.x, minf(4.0, rect.size.y))
	edge.color = edge_color
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(edge)


func _add_collision(holder_name: String, prefix: String, rects: Array[Rect2]) -> void:
	var holder := Node2D.new()
	holder.name = holder_name
	add_child(holder)
	_track(holder)
	for index in rects.size():
		var rect := rects[index]
		var body := StaticBody2D.new()
		body.name = "%s%d" % [prefix, index]
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = rect.position
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.size * 0.5
		body.add_child(shape)
		holder.add_child(body)


func _build_ambient() -> void:
	if data == null:
		return
	var kind := String(data.ambient_kind)
	if kind.is_empty() or kind == "none":
		return
	var tint := data.ambient_color
	if tint.a <= 0.0:
		var area_color: Color = area_info.get("color", Color("9fbfb9"))
		tint = area_color
		tint.a = 0.55
	var ambient := BigRoomAmbient.new()
	ambient.name = "Ambient"
	ambient.kind = StringName(kind)
	ambient.bounds = room_bounds
	ambient.tint = tint
	ambient.density = data.ambient_density
	add_child(ambient)
	_track(ambient)


## Gates come from the world file, which already owns the connections. Room
## scenes may still author a gate with the same name to override it.
func _build_gates() -> void:
	var game := get_parent() as MDSWorldGame
	if game == null or game.world == null or game.current_room.is_empty():
		return
	var world := game.world
	var room_id := game.current_room
	if auto_gates:
		for key in world.get_gates(room_id).keys():
			var gate_name := String(key)
			if gate_name.is_empty() or MDSGate.find_gate(self, gate_name) != null:
				continue
			var node_name := gate_name.validate_node_name()
			if node_name.is_empty():
				continue
			var side := world.get_gate_side(room_id, gate_name)
			var gate := MDSGate.new()
			gate.name = node_name
			gate.gate_name = gate_name
			gate.room_id = room_id
			gate.world_file = game.world_file
			gate.position = world.get_gate_local_pos(room_id, gate_name)
			gate.collision_layer = 0
			gate.collision_mask = 1
			if side == "door":
				gate.mode = MDSGate.Mode.INTERACT
				gate.interact_action = &"interact"
				gate.prompt = "按 %s 进入" % _interact_key()
			var shape := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size = _gate_shape_size(side)
			shape.shape = box
			gate.add_child(shape)
			add_child(gate)
			_track(gate)
			# A gate with world-authored `requires` gets the existing conditional
			# barrier for free; shortcuts need no bespoke script.
			var requires: Variant = world.get_gate(room_id, gate_name).get("requires", [])
			if requires is Array and not (requires as Array).is_empty():
				_add_gate_barrier(gate, gate_name, requires as Array, side)
	_add_gate_visuals(world, room_id)


## Generation above gives every connected gate its trigger; this pass gives the
## same gates a visible doorway. It runs for authored gates too (the shortcut
## arrival), so a big-map room never has an invisible gate. The marker is a
## child of the gate and changes neither its position nor its transition.
func _add_gate_visuals(world: MDSWorld, room_id: String) -> void:
	for child in get_children():
		var gate := child as MDSGate
		if gate == null or gate.get_node_or_null(GATE_VISUAL_NAME) != null:
			continue
		var gate_name := gate.get_gate_name()
		var side := gate.get_side()
		if world.has_gate(room_id, gate_name):
			side = world.get_gate_side(room_id, gate_name)
		var transition := world.get_transition(room_id, gate_name)
		var marker := GateVisual.new()
		marker.name = GATE_VISUAL_NAME
		marker.side = side
		marker.arrival = transition.is_empty()
		marker.caption = _gate_caption(world, transition)
		marker.floor_offset = _gate_floor_offset(gate, side)
		# Keep the caption inside the room. Side doors already unroll inward,
		# but a ceiling/floor hatch next to a wall would otherwise overhang the
		# camera limit; clamp the label into the room inset by its own size.
		marker.caption_area = Rect2(
			room_bounds.position - gate.position,
			room_bounds.size - Vector2(GateVisual.CAPTION_WIDTH, GateVisual.CAPTION_HEIGHT))
		gate.add_child(marker)


## "前往 <room name>" for a connected gate; "来路" for a gate that only
## receives players (the shortcut arrival and the boss entrance).
func _gate_caption(world: MDSWorld, transition: Dictionary) -> String:
	if transition.is_empty():
		return GateVisual.CAPTION_ARRIVAL
	var to_room := String(transition.get("room", ""))
	var to_name := str(world.get_room_value(to_room, "name", ""))
	if to_name.is_empty():
		to_name = to_room
	return GateVisual.CAPTION_ARROW + to_name


## Side gates sit 90 px above their floor by authoring convention; read the
## actual surface under the gate (ground or a step) so the door bottom meets it.
func _gate_floor_offset(gate: MDSGate, side: String) -> float:
	if side == "bot":
		return 0.0
	var surfaces: Array[Rect2] = []
	surfaces.append_array(built_ground_surfaces)
	surfaces.append_array(built_platform_surfaces)
	var best := INF
	for rect in surfaces:
		if gate.position.x < rect.position.x - 1.0 or gate.position.x > rect.end.x + 1.0:
			continue
		if rect.position.y < gate.position.y:
			continue
		best = minf(best, rect.position.y)
	if is_inf(best):
		return 90.0
	return best - gate.position.y


func _gate_shape_size(side: String) -> Vector2:
	match side:
		"top", "bot":
			return Vector2(200, 24)
		"door":
			return Vector2(36, 120)
	return Vector2(24, 200)


## Conditional shortcut gate: [MDSGateBarrier] owns the open state (stored in
## the MDS save), so a shortcut stays open across rooms and saves.
func _add_gate_barrier(gate: MDSGate, gate_name: String, requires: Array, side: String) -> void:
	var node_name := ("Barrier_" + gate_name).validate_node_name()
	if node_name.is_empty() or get_node_or_null(NodePath(node_name)) != null:
		return
	var barrier := MDSGateBarrier.new()
	barrier.name = node_name
	barrier.gate = gate
	barrier.requires = PackedStringArray(requires)
	barrier.position = gate.position
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = _gate_shape_size(side)
	shape.shape = box
	barrier.add_child(shape)
	add_child(barrier)
	_track(barrier)


## Prop children (moving platforms, elevators) receive the room union so their
## travel cannot leave the bounds MDS gives the camera.
func _notify_child_bounds() -> void:
	for child in get_children():
		if child.has_method(&"set_room_bounds"):
			child.call(&"set_room_bounds", room_bounds)


## Called elevators place their call panels next to a real floor at each
## stop, so they get every walkable surface (room-local, like their position).
func _notify_child_surfaces() -> void:
	var surfaces: Array[Rect2] = []
	surfaces.append_array(data.ground_rects(room_bounds))
	surfaces.append_array(data.platform_rects(room_bounds))
	for child in get_children():
		if child.has_method(&"set_surfaces"):
			child.call(&"set_surfaces", surfaces)


func _interact_key() -> String:
	var flow := get_node_or_null("/root/Flow") as GameFlow
	return flow.prompt_label(&"interact") if flow != null else "E"


## `fall_below_bounds` keeps a tall room's lower areas alive: game.gd resolves
## the plane from the room metadata when the chapter plan does not configure one.
func _publish_fall_plane() -> void:
	if has_meta(&"fall_y") or has_meta(&"fall_below_bounds"):
		return
	set_meta(&"fall_below_bounds", maxf(0.0, fall_margin))
