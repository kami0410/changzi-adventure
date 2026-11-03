class_name MDSChapterRoom
extends Node2D

## One room of the MDS chapter-1 pilot. Geometry, gates and set dressing live
## here; game.gd still owns enemy waves, rewards, boss data and run state, so
## the MDS world only replaces the level's transport layer.
##
## Every room is 1280x720 with origin at its top-left. The ArenaRoom sits at
## (640, 280) so its built-in doors close at x=20/1260, just inside the gates.

const ARENA_SCENE := preload("res://scenes/levels/room.tscn")
const STELE_SCENE := preload("res://scenes/levels/memory_stele.tscn")
const SHOP_SCENE := preload("res://scenes/levels/memory_shop.tscn")
const BACKGROUNDS := {
	0: "res://assets/backgrounds/ink_archive.png",
	1: "res://assets/backgrounds/breathing_ruins.png",
	2: "res://assets/backgrounds/lightless_sea.png",
	3: "res://assets/backgrounds/smiling_theater.png",
}
## Chapter 1 demo uses the two-layer pixel archive; chapters 2–4 keep the
## original paintings until they get the same treatment.
const PIXEL_BACKGROUND_FAR := "res://assets/backgrounds/pixel/ink_archive_far.png"
const PIXEL_BACKGROUND_MID := "res://assets/backgrounds/pixel/ink_archive_mid.png"
const WIDTH := 1280.0
const FLOOR_Y := 560.0
const TILE_SIZE := 16
const GROUND_TOP_TILE := Vector2i(0, 0)
const GROUND_FILL_TILE := Vector2i(1, 0)
const PLATFORM_TOP_TILE := Vector2i(2, 0)
const PLATFORM_FILL_TILE := Vector2i(3, 0)
const DEFAULT_CH1_LAYOUT := "res://resources/rooms/ch1_layout.tres"

enum Kind { COMBAT, REST, BOSS }

@export var kind: Kind = Kind.COMBAT
@export var chapter_index: int = 0
@export var room_index: int = 0
@export var platform_pattern: int = 0
@export var layout: RoomLayoutData
@export var has_chest: bool = false
@export var has_stele: bool = false
@export var has_shop: bool = false
@export var has_left_gate: bool = true
@export var has_right_gate: bool = true
## Optional interact doors for the hidden vault and the rest-room shortcut.
@export var has_vault_gate: bool = false
@export var has_shortcut_gate: bool = false

var arena: ArenaRoom


func _ready() -> void:
	_build_backdrop()
	_build_ground()
	_build_platforms()
	if kind != Kind.REST:
		_build_arena()
	_build_interactables()
	_build_gates()
	if room_index == 0 or room_index == 1:
		var save_point := Marker2D.new()
		save_point.name = "SavePoint"
		save_point.position = Vector2(40, FLOOR_Y) if room_index == 0 else Vector2(WIDTH * 0.5, FLOOR_Y)
		save_point.add_to_group(&"save_point")
		add_child(save_point)


func _build_backdrop() -> void:
	if chapter_index == 0:
		_add_pixel_layer("BackgroundFar", PIXEL_BACKGROUND_FAR, -12)
		_add_pixel_layer("BackgroundMid", PIXEL_BACKGROUND_MID, -9)
	else:
		var art := Sprite2D.new()
		art.name = "BackgroundArt"
		var path: String = BACKGROUNDS.get(clampi(chapter_index, 0, 3), BACKGROUNDS[0])
		art.texture = load(path)
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		art.position = Vector2(WIDTH * 0.5, 360)
		art.z_index = -10
		add_child(art)
	if chapter_index == 3:
		var theater := TheaterBackdrop.new()
		theater.world_width = WIDTH
		theater.generated_art = true
		add_child(theater)
		return
	if chapter_index == 0:
		# Demo chapter: the pixel layers already carry the archive atmosphere;
		# skip the smooth vector pillars/dust of the painting-era backdrop.
		return
	var backdrop := LivingBackdrop.new()
	backdrop.world_width = WIDTH
	backdrop.breathing = chapter_index == 1
	backdrop.sea = chapter_index == 2
	add_child(backdrop)


func _add_pixel_layer(layer_name: String, path: String, depth: int) -> void:
	var sprite := Sprite2D.new()
	sprite.name = layer_name
	sprite.texture = load(path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(WIDTH * 0.5, 360)
	sprite.z_index = depth
	add_child(sprite)


func _active_layout() -> RoomLayoutData:
	if layout != null and layout.tile_set != null:
		return layout
	if chapter_index == 0:
		return load(DEFAULT_CH1_LAYOUT) as RoomLayoutData
	return null


func _build_ground() -> void:
	var active := _active_layout()
	if active != null:
		var tiles := TileMapLayer.new()
		tiles.name = "Ground"
		tiles.tile_set = active.tile_set
		var columns := int(WIDTH / TILE_SIZE)
		var bottom_row := int(720.0 / TILE_SIZE)
		for column in columns:
			for row in range(active.floor_row, bottom_row):
				tiles.set_cell(Vector2i(column, row), 0, GROUND_FILL_TILE)
			tiles.set_cell(Vector2i(column, active.floor_row), 0, GROUND_TOP_TILE)
		add_child(tiles)
		return
	var ground := StaticBody2D.new()
	ground.name = "Ground"
	ground.position = Vector2(WIDTH * 0.5, FLOOR_Y + 40.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH, 80)
	shape.shape = rect
	ground.add_child(shape)
	add_child(ground)


func _build_platforms() -> void:
	var active := _active_layout()
	if active != null:
		var tiles := TileMapLayer.new()
		tiles.name = "Platforms"
		tiles.tile_set = active.tile_set
		for platform in _platform_specs(active):
			var start_column := int(round((float(platform[0]) - 120.0) / TILE_SIZE))
			var row: int = platform[1]
			for column in range(start_column, start_column + 15):
				tiles.set_cell(Vector2i(column, row), 0, PLATFORM_TOP_TILE)
				tiles.set_cell(Vector2i(column, row + 1), 0, PLATFORM_FILL_TILE)
		add_child(tiles)
		return
	var positions: Array[Vector2] = []
	match platform_pattern % 3:
		0:
			positions = [Vector2(300, 450), Vector2(980, 450)]
		1:
			positions = [Vector2(420, 420), Vector2(860, 335)]
		_:
			positions = [Vector2(640, 440)]
	for position in positions:
		_add_platform(position)


func _platform_specs(active: RoomLayoutData) -> Array:
	var first: int = active.platform_rows[0] if active.platform_rows.size() > 0 else 30
	var second: int = active.platform_rows[1] if active.platform_rows.size() > 1 else first
	match platform_pattern % 3:
		0:
			return [[300.0, first], [980.0, first]]
		1:
			return [[420.0, first], [860.0, second]]
		_:
			return [[640.0, first]]


func _add_platform(at: Vector2) -> void:
	var platform := StaticBody2D.new()
	platform.name = "Platform"
	platform.position = at
	var visual := ColorRect.new()
	visual.name = "Visual"
	visual.offset_left = -120.0
	visual.offset_top = -12.0
	visual.offset_right = 120.0
	visual.offset_bottom = 12.0
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	platform.add_child(visual)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(240, 24)
	shape.shape = rect
	platform.add_child(shape)
	add_child(platform)
	StylePlatform.apply(platform)


func _build_arena() -> void:
	arena = ARENA_SCENE.instantiate() as ArenaRoom
	arena.name = "Arena"
	arena.position = Vector2(WIDTH * 0.5, 280)
	add_child(arena)


func _build_interactables() -> void:
	if has_chest:
		var chest := TreasureChest.new()
		chest.name = "Chest"
		var chest_x := WIDTH * 0.32 if kind == Kind.REST and has_vault_gate else WIDTH * 0.5
		chest.position = Vector2(chest_x, FLOOR_Y - 8.0)
		add_child(chest)
	if has_stele:
		var stele := STELE_SCENE.instantiate() as MemoryStele
		stele.name = "Stele"
		stele.stele_id = StringName("ch%d_rest_stele" % (chapter_index + 1))
		stele.position = Vector2(920, FLOOR_Y)
		add_child(stele)
	if has_shop:
		var shop := SHOP_SCENE.instantiate() as MemoryShop
		shop.name = "Shop"
		shop.shop_id = StringName("ch%d_rest_shop" % (chapter_index + 1))
		shop.position = Vector2(360, FLOOR_Y)
		add_child(shop)


func _build_gates() -> void:
	if has_left_gate:
		_add_gate("left1", Vector2(8, FLOOR_Y - 90.0))
	if has_right_gate:
		_add_gate("right1", Vector2(WIDTH - 8, FLOOR_Y - 90.0))
	if has_vault_gate:
		var vault_prompt := "按 E 返回主路" if kind == Kind.REST else "按 E 进入隐藏书库"
		var vault_x := WIDTH * 0.5 if kind == Kind.REST else WIDTH * 0.72
		_add_doors("door1", Vector2(vault_x, FLOOR_Y - 60.0), vault_prompt, ChapterDoor.Kind.VAULT)
	if has_shortcut_gate:
		_add_doors("door2", Vector2(WIDTH * 0.86, FLOOR_Y - 60.0), "按 E 走捷径回到长廊", ChapterDoor.Kind.SHORTCUT)


func _add_gate(gate_name: String, at: Vector2) -> void:
	var gate := MDSGate.new()
	gate.name = gate_name
	gate.position = at
	gate.collision_layer = 0
	gate.collision_mask = 1
	gate.spawn_offset = 120.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 200)
	shape.shape = rect
	gate.add_child(shape)
	add_child(gate)


func _add_doors(gate_name: String, at: Vector2, prompt: String, door_kind: ChapterDoor.Kind) -> void:
	var gate := MDSGate.new()
	gate.name = gate_name
	gate.position = at
	gate.collision_layer = 0
	gate.collision_mask = 1
	gate.mode = MDSGate.Mode.INTERACT
	gate.interact_action = &"interact"
	gate.prompt = prompt
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36, 120)
	shape.shape = rect
	gate.add_child(shape)
	add_child(gate)
	var marker := ChapterDoor.new()
	marker.position = at
	marker.kind = door_kind
	marker.caption = prompt.trim_prefix("按 E ")
	marker.accent = Color("e6c87a") if door_kind == ChapterDoor.Kind.VAULT else Color("69e0d2")
	add_child(marker)
