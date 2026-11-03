extends RefCounted

## Chapter 1 demo rooms must use reachable platform rows and a real TileMapLayer
## visual instead of the old 450/420/335 px ColorRect platforms.

const ROOM_SCENE := "res://scenes/mds/ch1_01.tscn"
const LAYOUT_PATH := "res://resources/rooms/ch1_layout.tres"


func run(t: Callable) -> void:
	_test_layout_resource(t)
	_test_room_geometry(t)
	_test_enemy_jump(t)


func _test_layout_resource(t: Callable) -> void:
	var layout := load(LAYOUT_PATH) as RoomLayoutData
	t.call(layout != null, true, "ch1_layout_resource_loads")
	if layout == null:
		return
	t.call(layout.floor_row, 35, "ch1_floor_row_is_35")
	var expected_rows: Array[int] = [30, 28]
	t.call(layout.platform_rows, expected_rows, "ch1_platform_rows_are_30_and_28")
	t.call(layout.tile_set != null, true, "ch1_layout_has_tileset")


func _test_room_geometry(t: Callable) -> void:
	var room := (load(ROOM_SCENE) as PackedScene).instantiate() as MDSChapterRoom
	t.call(room != null, true, "ch1_01_instantiates")
	if room == null:
		return
	room._build_ground()
	room._build_platforms()

	var ground := room.get_node_or_null("Ground") as TileMapLayer
	var platforms := room.get_node_or_null("Platforms") as TileMapLayer
	t.call(ground != null, true, "ch1_ground_is_tilemap_layer")
	t.call(platforms != null, true, "ch1_platforms_are_tilemap_layer")
	var color_rects := room.find_children("*", "ColorRect", true, false)
	t.call(color_rects.size(), 0, "ch1_room_has_no_colorrect")

	if ground != null:
		var top_row := 999
		for cell in ground.get_used_cells():
			top_row = mini(top_row, cell.y)
		t.call(top_row, 35, "ch1_ground_surface_row_35")
	if platforms != null:
		var top_row := 999
		for cell in platforms.get_used_cells():
			top_row = mini(top_row, cell.y)
		t.call(top_row, 30, "ch1_first_platform_surface_row_30")
		var first_surface_y := 30 * 16
		var jump_height := 500.0 * 500.0 / (2.0 * 1350.0)
		t.call(560 - first_surface_y <= jump_height, true, "ch1_first_platform_is_reachable")
	room.free()


func _test_enemy_jump(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var enemy := Enemy.new()
	var target := Node2D.new()
	tree.root.add_child(enemy)
	tree.root.add_child(target)
	enemy.target = target

	target.global_position = Vector2(60, -80)
	t.call(enemy.try_jump_toward_target(false), true, "enemy_jumps_to_low_platform")
	t.call(enemy.velocity.y, -500.0, "enemy_jump_velocity")

	target.global_position = Vector2(60, -200)
	enemy.velocity = Vector2.ZERO
	enemy._jump_cooldown_left = 0.0
	t.call(enemy.try_jump_toward_target(false), false, "enemy_ignores_high_platform")

	target.global_position = Vector2(300, -80)
	enemy.velocity = Vector2.ZERO
	enemy._jump_cooldown_left = 0.0
	t.call(enemy.try_jump_toward_target(false), false, "enemy_ignores_distant_platform")

	enemy.free()
	target.free()
