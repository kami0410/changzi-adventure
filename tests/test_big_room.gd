extends RefCounted

## Big-map room production line: reachability validation, variable-size
## geometry, tiled backdrops and the guarantee that Chapter 1 keeps its own
## MDSChapterRoom builder.

const CH1_ROOM := "res://scenes/mds/ch1_01.tscn"
const CH1_TILES := "res://resources/tiles/ch1_tiles.tres"


func run(t: Callable) -> void:
	_test_jump_budget(t)
	_test_validation(t)
	_test_snapping(t)
	_test_builder_geometry(t)
	_test_tiled_geometry(t)
	_test_backdrop_tiling(t)
	_test_backdrop_mirror_seams(t)
	_test_ambient(t)
	_test_gate_visuals(t)
	_test_chapter_one_unchanged(t)


func _test_jump_budget(t: Callable) -> void:
	var player := Player.new()
	t.call(is_equal_approx(player.jump_velocity, -500.0), true, "big_room_player_jump_velocity")
	t.call(is_equal_approx(player.gravity, 1350.0), true, "big_room_player_gravity")
	var peak := player.jump_velocity * player.jump_velocity / (2.0 * player.gravity)
	t.call(is_equal_approx(BigRoomData.MAX_JUMP_HEIGHT, peak), true,
		"big_room_jump_height_matches_player")
	t.call(BigRoomData.MAX_STEP < BigRoomData.MAX_JUMP_HEIGHT, true,
		"big_room_step_has_headroom")
	player.free()


func _test_validation(t: Callable) -> void:
	var data := BigRoomData.new()
	data.size = Vector2i(2560, 1440)
	data.ground = [
		{"x": 0.0, "y": 1360.0, "width": 2560.0, "height": 80.0},
		{"x": 0.0, "y": 1280.0, "width": 1280.0, "height": 80.0},
	]
	data.platforms = [
		{"x": 200.0, "y": 1200.0, "width": 400.0},
		{"x": 700.0, "y": 1120.0, "width": 400.0},
		{"x": 1200.0, "y": 1040.0, "width": 400.0},
	]
	t.call(data.validate(), PackedStringArray(), "big_room_valid_layout_passes")

	var step := BigRoomData.new()
	step.size = Vector2i(1280, 720)
	step.ground = [{"x": 0.0, "y": 640.0, "width": 1280.0, "height": 64.0}]
	step.platforms = [{"x": 200.0, "y": 560.0, "width": 400.0}]
	t.call(step.validate(), PackedStringArray(), "big_room_step_80_passes")

	step.platforms = [{"x": 200.0, "y": 556.0, "width": 400.0}]
	var too_high := step.validate()
	t.call(too_high.size(), 1, "big_room_step_over_80_fails")
	if not too_high.is_empty():
		t.call(String(too_high[0]).contains("84 px"), true, "big_room_step_reports_rise")

	step.ground = [{"x": 0.0, "y": 640.0, "width": 400.0, "height": 64.0}]
	step.platforms = [{"x": 1000.0, "y": 560.0, "width": 200.0}]
	var floating := step.validate()
	t.call(floating.size(), 1, "big_room_floating_platform_fails")
	if not floating.is_empty():
		t.call(String(floating[0]).contains("no surface below"), true,
			"big_room_floating_platform_reported")

	step.platforms = [{"x": 600.0, "y": 560.0, "width": 400.0}]
	step.ground = [{"x": 0.0, "y": 640.0, "width": 480.0, "height": 64.0}]
	t.call(step.validate(), PackedStringArray(), "big_room_horizontal_reach_120_passes")
	step.ground = [{"x": 0.0, "y": 640.0, "width": 479.0, "height": 64.0}]
	t.call(step.validate().size(), 1, "big_room_horizontal_reach_over_120_fails")

	var outside := BigRoomData.new()
	outside.size = Vector2i(1280, 720)
	outside.ground = [{"x": 0.0, "y": 640.0, "width": 1280.0, "height": 64.0}]
	outside.platforms = [{"x": 1200.0, "y": 560.0, "width": 400.0}]
	var outside_errors := outside.validate()
	t.call(outside_errors.size(), 1, "big_room_out_of_bounds_fails")
	if not outside_errors.is_empty():
		t.call(String(outside_errors[0]).contains("leaves the room bounds"), true,
			"big_room_out_of_bounds_reported")

	var malformed := BigRoomData.new()
	malformed.size = Vector2i(1280, 720)
	malformed.ground = [{"x": 10.0}]
	malformed.platforms = [{"x": 200.0, "y": 560.0, "width": -40.0}]
	t.call(malformed.validate().size(), 2, "big_room_malformed_entries_fail")

	var empty := BigRoomData.new()
	empty.size = Vector2i.ZERO
	t.call(empty.validate().size(), 1, "big_room_zero_size_fails")

	# The MDS world bounds stand in for size outside a world (and win when a
	# room's rectangles differ from the authored fallback size).
	var roomy := BigRoomData.new()
	roomy.size = Vector2i(1280, 720)
	roomy.ground = [{"x": 0.0, "y": 2000.0, "width": 3840.0, "height": 160.0}]
	t.call(roomy.validate(Rect2(0, 0, 3840, 2160)), PackedStringArray(),
		"big_room_world_bounds_override_size")


func _test_snapping(t: Callable) -> void:
	var data := BigRoomData.new()
	data.size = Vector2i(1280, 720)
	data.ground = [{"x": 10.0, "y": 647.0, "width": 100.0, "height": 30.0}]
	t.call(data.ground_rects()[0], Rect2(10, 647, 100, 30),
		"big_room_float_geometry_without_tiles")

	data.tile_set = load(CH1_TILES) as TileSet
	t.call(data.ground_rects()[0], Rect2(0, 640, 112, 32),
		"big_room_ground_snaps_to_tile_grid")
	data.platforms = [{"x": 30.0, "y": 100.0, "width": 50.0}]
	t.call(data.platform_rects()[0], Rect2(16, 96, 64, 16),
		"big_room_platform_snaps_to_tile_grid")


func _test_builder_geometry(t: Callable) -> void:
	var data := BigRoomData.new()
	data.size = Vector2i(1600, 900)
	data.ground = [
		{"x": 0.0, "y": 800.0, "width": 1600.0, "height": 100.0},
		{"x": 0.0, "y": 720.0, "width": 800.0, "height": 80.0},
	]
	data.platforms = [
		{"x": 800.0, "y": 640.0, "width": 400.0},
		{"x": 200.0, "y": 640.0, "width": 400.0},
	]
	var room := MDSBigRoom.new()
	room.name = "BigRoomFixture"
	room.data = data
	room.build()

	t.call(room.room_bounds, Rect2(0, 0, 1600, 900), "big_room_fallback_size")
	t.call(room.validation_errors, PackedStringArray(), "big_room_builder_layout_valid")
	t.call(room.built_ground_surfaces.size(), 2, "big_room_two_ground_layers")
	t.call(room.built_platform_surfaces.size(), 2, "big_room_two_platforms")
	t.call(room.area_info.get("source", ""), "data", "big_room_area_falls_back_to_data")
	t.call(float(room.get_meta(&"fall_below_bounds", -1.0)), 200.0,
		"big_room_publishes_fall_plane")

	var ground_bodies := room.get_node_or_null("GroundCollision")
	t.call(ground_bodies.get_child_count() if ground_bodies != null else -1, 2,
		"big_room_ground_collision_bodies")
	if ground_bodies != null and ground_bodies.get_child_count() == 2:
		var body := ground_bodies.get_child(0) as StaticBody2D
		t.call(body.position, Vector2(0, 800), "big_room_ground_body_position")
		var shape := body.get_child(0) as CollisionShape2D
		var box := shape.shape as RectangleShape2D
		t.call(box.size, Vector2(1600, 100), "big_room_ground_body_size")
		t.call(body.collision_layer, 1, "big_room_ground_collision_layer")

	var platform_bodies := room.get_node_or_null("PlatformCollision")
	t.call(platform_bodies.get_child_count() if platform_bodies != null else -1, 2,
		"big_room_platform_collision_bodies")
	if platform_bodies != null and platform_bodies.get_child_count() == 2:
		var body := platform_bodies.get_child(0) as StaticBody2D
		var shape := body.get_child(0) as CollisionShape2D
		var box := shape.shape as RectangleShape2D
		t.call(box.size, Vector2(400, 16), "big_room_platform_body_size")

	var ground_visual := room.get_node_or_null("GroundVisual") as Node2D
	t.call(ground_visual.get_child_count() if ground_visual != null else -1, 4,
		"big_room_ground_greybox_visuals")
	var tile_layers := room.find_children("*", "TileMapLayer", true, false)
	t.call(tile_layers.size(), 0, "big_room_no_tile_layers_without_tileset")

	# Authored moving platforms run _ready before their room builder; the
	# builder still hands them the resolved union so travel is clamped.
	var notified := MovingPlatform.new()
	notified.position = Vector2(1200, 800)
	notified.size = Vector2(120, 16)
	notified.travel = Vector2(0, -900)
	room.add_child(notified)
	room.build()
	t.call(notified.bounds_resolved, true, "big_room_notifies_moving_platform_bounds")
	notified.build()
	t.call(notified.room_bounds, Rect2(0, 0, 1600, 900),
		"big_room_moving_platform_receives_union")
	t.call(notified.travel_clamped, true, "big_room_moving_platform_travel_clamped")
	t.call(notified.effective_travel, Vector2(0, -800),
		"big_room_moving_platform_effective_travel")
	room.remove_child(notified)
	notified.free()
	room.free()


func _test_tiled_geometry(t: Callable) -> void:
	var data := BigRoomData.new()
	data.size = Vector2i(1280, 720)
	data.tile_set = load(CH1_TILES) as TileSet
	data.ground = [{"x": 0.0, "y": 640.0, "width": 480.0, "height": 32.0}]
	data.platforms = [{"x": 0.0, "y": 560.0, "width": 160.0}]
	var room := MDSBigRoom.new()
	room.data = data
	room.build()
	t.call(room.validation_errors, PackedStringArray(), "big_room_tiled_layout_valid")
	var ground_tiles := room.get_node_or_null("GroundTiles") as TileMapLayer
	var ground_fill := room.get_node_or_null("GroundFill") as TileMapLayer
	var platform_tiles := room.get_node_or_null("PlatformTiles") as TileMapLayer
	var platform_fill := room.get_node_or_null("PlatformFill") as TileMapLayer
	t.call(ground_tiles != null and ground_fill != null, true, "big_room_ground_tile_layers")
	t.call(platform_tiles != null and platform_fill != null, true,
		"big_room_platform_tile_layers")
	if ground_tiles != null and ground_fill != null:
		t.call(ground_tiles.collision_enabled, false, "big_room_ground_tiles_have_no_collision")
		t.call(ground_tiles.get_used_cells().size(), 30, "big_room_ground_surface_cells")
		t.call(ground_fill.get_used_cells().size(), 30, "big_room_ground_fill_cells")
		t.call(ground_fill.collision_enabled, false, "big_room_ground_fill_has_no_collision")
	if platform_tiles != null and platform_fill != null:
		t.call(platform_tiles.get_used_cells().size(), 10, "big_room_platform_surface_cells")
		t.call(platform_fill.get_used_cells().size(), 10, "big_room_platform_fill_cells")
	t.call(room.get_node_or_null("GroundCollision") != null, true,
		"big_room_tiled_ground_has_rect_collision")
	t.call(room.get_node_or_null("PlatformCollision") != null, true,
		"big_room_tiled_platform_has_rect_collision")
	t.call(room.get_node_or_null("GroundVisual"), null, "big_room_tiled_ground_has_no_greybox")
	room.free()


func _test_backdrop_tiling(t: Callable) -> void:
	var data := BigRoomData.new()
	data.size = Vector2i(1600, 900)
	data.backdrop_texture = _texture(400, 300)
	var room := MDSBigRoom.new()
	room.data = data
	room.build()
	t.call(room.backdrop_tiles.size(), 12, "big_room_backdrop_tiles_cover_1600x900")
	t.call(room.backdrop_rect_local(), Rect2(0, 0, 1600, 900),
		"big_room_backdrop_rect_covers_room")
	t.call(room.backdrop_tiles[0].position, Vector2(200, 150),
		"big_room_backdrop_first_tile_centered")
	t.call(room.backdrop_tiles[11].position, Vector2(1400, 750),
		"big_room_backdrop_last_tile_centered")
	t.call(room.backdrop_tiles[0].texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST,
		"big_room_backdrop_keeps_pixel_filter")

	data.backdrop_scale = 2
	room.build()
	t.call(room.backdrop_tiles.size(), 4, "big_room_scaled_backdrop_tiles")
	# Scaled tiles overflow above the room now that the grid is floor-anchored
	# and mirrored; `backdrop_rect_local()` reports the clipped usable cover.
	t.call(room.backdrop_rect_local(), Rect2(0, 0, 1600, 900),
		"big_room_scaled_backdrop_covers_room")
	t.call(room.backdrop_tiles[3].position.y, 600,
		"big_room_scaled_backdrop_bottom_row_at_floor")
	t.call(room.backdrop_tiles[0].position.y - 300 < 0.0, true,
		"big_room_scaled_backdrop_overflows_above")

	data.backdrop_scale = 1
	data.backdrop_pixel_art = false
	room.build()
	t.call(room.backdrop_tiles[0].texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR,
		"big_room_painted_backdrop_uses_linear_filter")
	room.free()


## The big-map paintings are not vertically tileable (sky at the top, floor at
## the bottom). Rooms are 1440/2160 px tall against 864 px art, so the grid is
## anchored at the room floor and every row above it is mirrored: adjacent
## tiles share their edge row instead of butting a floor strip against a sky.
func _test_backdrop_mirror_seams(t: Callable) -> void:
	var image := Image.create(8, 6, false, Image.FORMAT_RGBA8)
	image.fill(Color("334455"))
	for x in 8:
		image.set_pixel(x, 0, Color("ff2200"))
		image.set_pixel(x, 5, Color("0033ff"))
	var data := BigRoomData.new()
	data.size = Vector2i(16, 15)
	data.backdrop_texture = ImageTexture.create_from_image(image)
	var room := MDSBigRoom.new()
	room.data = data
	room.build()
	t.call(room.backdrop_tiles.size(), 6, "big_room_mirror_backdrop_tiles")
	if room.backdrop_tiles.size() != 6:
		room.free()
		return

	var tiles := room.backdrop_tiles
	# Row 2 (bottom, indices 4-5) is the painting's own composition anchored at
	# the floor; rows 1 and 0 above it are flipped so the seams match.
	t.call(tiles[4].position, Vector2(4, 12), "big_room_backdrop_bottom_row_anchored")
	t.call(tiles[4].flip_v, false, "big_room_backdrop_bottom_row_upright")
	t.call(tiles[4].position.y + 3.0, room.room_bounds.end.y,
		"big_room_backdrop_floor_edge_on_room_floor")
	t.call(tiles[2].flip_v, true, "big_room_backdrop_middle_row_mirrored")
	t.call(tiles[0].flip_v, false, "big_room_backdrop_top_row_upright")
	t.call(tiles[0].position.y - 3.0 < room.room_bounds.position.y, true,
		"big_room_backdrop_top_row_clipped_above_room")
	t.call(room.backdrop_rect_local(), Rect2(0, 0, 16, 15),
		"big_room_backdrop_rect_clipped_to_room")

	# Real continuity: for every vertical neighbour pair, the row the upper tile
	# draws at its bottom edge must equal the row the lower one draws at its top.
	for column in 2:
		for row in 2:
			var upper := tiles[row * 2 + column]
			var lower := tiles[(row + 1) * 2 + column]
			var upper_bottom := _edge_color(upper, true)
			var lower_top := _edge_color(lower, false)
			t.call(upper_bottom, lower_top,
				"big_room_backdrop_seam_row_%d_%d" % [column, row])
			# Sanity: the seams really are the sky/floor boundary, so the test
			# would fail if the rows simply repeated without mirroring.
			t.call(upper_bottom != _edge_color(upper, false) \
				or lower_top != _edge_color(lower, true), true,
				"big_room_backdrop_seam_is_an_edge_%d_%d" % [column, row])
	room.free()


## Colour drawn at a tile's top or bottom edge, honouring `flip_v`.
func _edge_color(tile: Sprite2D, bottom: bool) -> Color:
	var image := tile.texture.get_image()
	var row := image.get_height() - 1 if bottom else 0
	if tile.flip_v:
		row = 0 if bottom else image.get_height() - 1
	return image.get_pixel(0, row)


func _test_ambient(t: Callable) -> void:
	var data := BigRoomData.new()
	data.size = Vector2i(1600, 900)
	data.ambient_kind = &"motes"
	var room := MDSBigRoom.new()
	room.data = data
	room.build()
	var ambient := room.get_node_or_null("Ambient") as BigRoomAmbient
	t.call(ambient != null, true, "big_room_ambient_built")
	if ambient != null:
		t.call(ambient.kind, &"motes", "big_room_ambient_kind")
		t.call(ambient.bounds, Rect2(0, 0, 1600, 900), "big_room_ambient_bounds")
		t.call(ambient.mote_count() > 0, true, "big_room_ambient_has_motes")
	room.free()

	data.ambient_kind = &"none"
	var plain := MDSBigRoom.new()
	plain.data = data
	plain.build()
	t.call(plain.get_node_or_null("Ambient"), null, "big_room_ambient_off_by_default")
	plain.free()


func _test_gate_visuals(t: Callable) -> void:
	# The visible half of a big-map gate reuses ChapterDoor's language: the
	# door texture, accent frame, caption label and motes. It adds no collision
	# and sits behind actors so the player and a locked barrier stay legible.
	var visual := GateVisual.new()
	visual.side = "right"
	visual.caption = GateVisual.CAPTION_ARROW + "呼吸废墟 · 肺钟枢纽"
	visual.floor_offset = 90.0
	visual.build()
	t.call(visual.z_index, -1, "gate_visual_behind_actors")
	t.call(visual.caption_text(), "前往 呼吸废墟 · 肺钟枢纽", "gate_visual_caption")
	t.call(visual.caption_label() != null, true, "gate_visual_caption_label")
	t.call(visual.caption_label().position.y,
		visual.floor_offset - GateVisual.HEIGHT - 34.0,
		"gate_visual_caption_above_door")
	t.call(visual.caption_label().position.x, -GateVisual.CAPTION_WIDTH,
		"gate_visual_right_caption_inside_room")
	t.call(visual.find_children("*", "CollisionObject2D", true, false).is_empty(), true,
		"gate_visual_no_collision")
	t.call(visual.get_class(), "Node2D", "gate_visual_not_a_body")
	visual.free()

	var hatch := GateVisual.new()
	hatch.side = "top"
	hatch.caption = GateVisual.CAPTION_ARROW + "入口"
	hatch.build()
	t.call(hatch.caption_label().position.y, GateVisual.HATCH_HALF * 2.0 + 6.0,
		"gate_visual_top_caption_below_hatch")
	hatch.free()

	var arrival := GateVisual.new()
	arrival.side = "left"
	arrival.caption = GateVisual.CAPTION_ARRIVAL
	arrival.arrival = true
	arrival.build()
	t.call(arrival.caption_text(), "来路", "gate_visual_arrival_copy")
	t.call(arrival.arrival, true, "gate_visual_arrival_flag")
	t.call(arrival.caption_label().position.x, 0.0,
		"gate_visual_left_caption_inside_room")
	arrival.free()

	var mid := GateVisual.new()
	mid.side = "door"
	mid.build()
	t.call(mid.caption_label().position.x, -GateVisual.CAPTION_WIDTH * 0.5,
		"gate_visual_door_caption_centred")
	mid.free()

	# A ceiling hatch next to a wall pulls its caption into the room. Without
	# the inset the Chapter 3 well's top gate (x = 80) hangs its 200 px label
	# 20 px past the left camera limit; side doors already unroll inward.
	var inset := GateVisual.new()
	inset.side = "top"
	inset.caption = GateVisual.CAPTION_ARROW + "无光海 · 深渊裂口"
	inset.caption_area = Rect2(Vector2(-80, -8), Vector2(2360, 1410))
	inset.build()
	t.call(inset.caption_label().position.x, -80.0,
		"gate_visual_hatch_caption_inset")
	t.call(inset.caption_label().position.y, GateVisual.HATCH_HALF * 2.0 + 6.0,
		"gate_visual_hatch_caption_height_kept")
	inset.free()

	# Generated markers are named so an authored gate can override them.
	t.call(MDSBigRoom.GATE_VISUAL_NAME, "GateVisual", "gate_visual_node_name")

	# Side doors meet the real surface under the gate: the entry shortcut
	# arrival stands on the first step (16 px below), side gates stand 90 px
	# above the ground, and floor gates keep a zero offset for the hatch.
	var room := MDSBigRoom.new()
	room.built_ground_surfaces.append(Rect2(0, 1424, 2560, 16))
	room.built_platform_surfaces.append(Rect2(320, 1344, 320, 16))
	var gate := MDSGate.new()
	gate.position = Vector2(512, 1328)
	t.call(room._gate_floor_offset(gate, "door"), 16.0,
		"gate_visual_door_floor_on_step")
	gate.position = Vector2(1600, 1334)
	t.call(room._gate_floor_offset(gate, "door"), 90.0,
		"gate_visual_door_floor_on_ground")
	t.call(room._gate_floor_offset(gate, "bot"), 0.0,
		"gate_visual_floor_hatch_offset")
	gate.free()
	room.free()


func _test_chapter_one_unchanged(t: Callable) -> void:
	var room := (load(CH1_ROOM) as PackedScene).instantiate()
	t.call(room is MDSChapterRoom, true, "ch1_room_still_uses_mds_chapter_room")
	t.call(not (room is MDSBigRoom), true, "ch1_room_not_on_big_room_pipeline")
	if room is MDSChapterRoom:
		t.call(MDSChapterRoom.WIDTH, 1280.0, "ch1_room_width_unchanged")
		t.call(MDSChapterRoom.FLOOR_Y, 560.0, "ch1_room_floor_unchanged")
	room.free()
	# Every Chapter 1 room keeps the original builder; the big-map pipeline is
	# opt-in per scene and cannot silently take over the demo.
	var dir := DirAccess.open("res://scenes/mds")
	var scenes: PackedStringArray = dir.get_files() if dir != null else PackedStringArray()
	var ch1_count := 0
	for file_name in scenes:
		if not file_name.begins_with("ch1_") or not file_name.ends_with(".tscn"):
			continue
		ch1_count += 1
		var packed := load("res://scenes/mds/" + file_name) as PackedScene
		var instance := packed.instantiate() if packed != null else null
		t.call(instance is MDSChapterRoom, true, "ch1_scene_%s_old_pipeline" % file_name)
		if instance != null:
			# No Chapter 2 vertical/shortcut props may leak into the demo rooms.
			var props := 0
			for node in instance.find_children("*", "", true, false):
				if node is OneWayPlatform or node is CollapsingPlatform \
						or node is MovingPlatform or node is BenchCheckpoint:
					props += 1
			t.call(props, 0, "ch1_scene_%s_has_no_vertical_props" % file_name)
			# Gate visuals are a big-map presentation child; the demo rooms
			# keep their own ChapterDoor language untouched.
			var gate_visuals := instance.find_children("*", "GateVisual", true, false)
			t.call(gate_visuals.size(), 0,
				"ch1_scene_%s_has_no_gate_visuals" % file_name)
			instance.free()
	t.call(ch1_count, 9, "ch1_has_nine_rooms")


func _texture(width: int, height: int) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color("334455"))
	return ImageTexture.create_from_image(image)
