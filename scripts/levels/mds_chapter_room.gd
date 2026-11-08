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
## Wide screens (1.0.1): the view keeps 720 px of height, so a 20:9 phone sees
## ~1600 px across a 1280 px room. Backdrop and ground continue this far past
## each wall (visual only) instead of showing the clear colour.
const SIDE_BLEED := 320.0

enum Kind { COMBAT, REST, BOSS }

## Platform layouts as [centre_x, row_index] pairs (row_index 0 = the lower
## legal row, 1 = the upper). Every upper platform sits within 120 px of a
## lower one, so nothing needs more than the jump budget. The first three are
## the authored patterns; combat rooms in a live run pick any of them (and may
## mirror it) from the run seed, so each run's Chapter 1 plays differently
## while a reload of the same run rebuilds the same room.
const PATTERNS: Array = [
	[[300.0, 0], [980.0, 0]],
	[[460.0, 0], [760.0, 1]],
	[[640.0, 0]],
	[[280.0, 0], [620.0, 1], [960.0, 0]],
	[[380.0, 0], [700.0, 1]],
	[[360.0, 0], [640.0, 1], [920.0, 0]],
	[],
	[[300.0, 0], [580.0, 1], [1000.0, 0]],
]
## Platforms never cover where the player appears: the side-gate arrivals
## (120 px in from each wall, 16 px body radius) and, in rooms with one, the
## vault door. A platform there would spawn the player inside its tiles.
const ARRIVAL_CLEAR: Array = [Vector2(96.0, 160.0), Vector2(1120.0, 1184.0)]
const VAULT_CLEAR := Vector2(860.0, 980.0)
const PLATFORM_HALF := 120.0
## Seed override for tests; 0 reads the live run.
var layout_seed: int = 0

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
var _game_flow: GameFlow = null


func _ready() -> void:
	_game_flow = get_node_or_null("/root/Flow") as GameFlow
	_build_backdrop()
	_build_ground()
	_build_platforms()
	if kind != Kind.REST:
		_build_arena()
	_build_interactables()
	_build_gates()
	_build_dressing()
	if _game_flow != null and not _game_flow.input_device_changed.is_connected(_on_input_device_changed):
		_game_flow.input_device_changed.connect(_on_input_device_changed)
	if _game_flow != null and not _game_flow.keybinds_changed.is_connected(_on_keybinds_changed):
		_game_flow.keybinds_changed.connect(_on_keybinds_changed)
	if room_index == 0 or room_index == 1:
		var save_point := Marker2D.new()
		save_point.name = "SavePoint"
		save_point.position = Vector2(40, FLOOR_Y) if room_index == 0 else Vector2(WIDTH * 0.5, FLOOR_Y)
		save_point.add_to_group(&"save_point")
		add_child(save_point)


## Archive floor props (books, candles, urns...) placed from the room and
## run seed so each Chapter 1 room is dressed differently; purely visual.
func _build_dressing() -> void:
	if chapter_index != 0:
		return
	var active := _active_layout()
	var dressing := RoomDressing.new()
	dressing.name = "Dressing"
	add_child(dressing)
	var run_seed := layout_seed
	if run_seed == 0 and _game_flow != null and _game_flow.current_run != null:
		run_seed = _game_flow.current_run.run_seed
	dressing.chapter = 1
	dressing.room_id = "ch1_%02d_%d" % [room_index, run_seed]
	var surfaces: Array[Rect2] = [Rect2(40, FLOOR_Y, WIDTH - 80, 16)]
	if active != null:
		for platform in _platform_specs(active):
			surfaces.append(Rect2(float(platform[0]) - 110.0, float(platform[1]) * TILE_SIZE, 220.0, 16.0))
	var avoid: Array[Vector2] = [Vector2(120, FLOOR_Y), Vector2(WIDTH - 120, FLOOR_Y)]
	for child in get_children():
		if child is Node2D and child != dressing and not child is TileMapLayer:
			var node := child as Node2D
			if node.name.begins_with("Background"):
				continue
			avoid.append(Vector2(node.position.x, FLOOR_Y))
	dressing.place_props(surfaces, avoid)


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
		theater.name = "TheaterBackdrop"
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
	# Mirrored copies either side, so a wide view never runs off the painting.
	if sprite.texture != null:
		var w := float(sprite.texture.get_width())
		for side in [-1.0, 1.0]:
			var copy := sprite.duplicate() as Sprite2D
			copy.name = "%s_%s" % [layer_name, "L" if side < 0.0 else "R"]
			copy.flip_h = true
			copy.position.x += side * w
			add_child(copy)


func _active_layout() -> RoomLayoutData:
	if layout != null and layout.tile_set != null:
		return layout
	if chapter_index == 0:
		return load(DEFAULT_CH1_LAYOUT) as RoomLayoutData
	return null


func _build_ground() -> void:
	var active := _active_layout()
	if active != null:
		var columns := int(WIDTH / TILE_SIZE)
		var bottom_row := int(720.0 / TILE_SIZE)
		# Only the surface row needs physics. Painting the nine rows below it on
		# a collisionless layer removes ~720 useless colliders per room; the
		# player can never reach anything below the floor tile.
		var fill := TileMapLayer.new()
		fill.name = "GroundFill"
		fill.tile_set = active.tile_set
		fill.collision_enabled = false
		var tiles := TileMapLayer.new()
		tiles.name = "Ground"
		tiles.tile_set = active.tile_set
		for column in columns:
			for row in range(active.floor_row + 1, bottom_row):
				fill.set_cell(Vector2i(column, row), 0,
					TileVariants.fill(active.tile_set, GROUND_FILL_TILE, row - active.floor_row))
			tiles.set_cell(Vector2i(column, active.floor_row), 0,
				TileVariants.pick(active.tile_set, GROUND_TOP_TILE, column, active.floor_row))
		# Visual ground past both walls for wide screens (no collision).
		var bleed := int(SIDE_BLEED / TILE_SIZE)
		for column in range(-bleed, columns + bleed):
			if column >= 0 and column < columns:
				continue
			fill.set_cell(Vector2i(column, active.floor_row), 0,
				TileVariants.pick(active.tile_set, GROUND_TOP_TILE, column, active.floor_row))
			for row in range(active.floor_row + 1, bottom_row):
				fill.set_cell(Vector2i(column, row), 0,
					TileVariants.fill(active.tile_set, GROUND_FILL_TILE, row - active.floor_row))
		add_child(fill)
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
		var fill := TileMapLayer.new()
		fill.name = "PlatformsFill"
		fill.tile_set = active.tile_set
		fill.collision_enabled = false
		var tiles := TileMapLayer.new()
		tiles.name = "Platforms"
		tiles.tile_set = active.tile_set
		for platform in _platform_specs(active):
			var start_column := int(round((float(platform[0]) - 120.0) / TILE_SIZE))
			var row: int = platform[1]
			for column in range(start_column, start_column + 15):
				tiles.set_cell(Vector2i(column, row), 0,
					TileVariants.pick(active.tile_set, PLATFORM_TOP_TILE, column, row))
				fill.set_cell(Vector2i(column, row + 1), 0,
					TileVariants.pick(active.tile_set, PLATFORM_FILL_TILE, column + 7, row))
		add_child(fill)
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
	var choice := effective_pattern()
	var specs: Array = []
	for entry in PATTERNS[choice.x]:
		var x: float = entry[0]
		if choice.y == 1:
			x = WIDTH - x
		specs.append([x, first if int(entry[1]) == 0 else second])
	return specs


## (pattern index, mirrored 0/1). Authored pattern unless this is a combat
## room in a live run, where the run seed and room index pick it.
func effective_pattern() -> Vector2i:
	var run_seed := layout_seed
	if run_seed == 0 and _game_flow != null and _game_flow.current_run != null:
		run_seed = _game_flow.current_run.run_seed
	if run_seed == 0 or kind != Kind.COMBAT or chapter_index != 0:
		return Vector2i(platform_pattern % 3, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("ch1_layout|%d|%d" % [run_seed, room_index])
	var allowed: Array[Vector2i] = []
	for index in PATTERNS.size():
		for mirrored in 2:
			if pattern_allowed(index, mirrored == 1):
				allowed.append(Vector2i(index, mirrored))
	if allowed.is_empty():
		return Vector2i(platform_pattern % 3, 0)
	return allowed[rng.randi_range(0, allowed.size() - 1)]


## False when a platform of the pattern would cover an arrival point (or the
## vault door in rooms that have one).
func pattern_allowed(index: int, mirrored: bool) -> bool:
	var clear: Array = ARRIVAL_CLEAR.duplicate()
	if has_vault_gate:
		clear.append(VAULT_CLEAR)
	for entry in PATTERNS[index]:
		var x: float = entry[0]
		if mirrored:
			x = WIDTH - x
		for span in clear:
			var zone: Vector2 = span
			if x + PLATFORM_HALF > zone.x and x - PLATFORM_HALF < zone.y:
				return false
	return true


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
	var interact_key := _game_flow.prompt_label(&"interact") if _game_flow != null else "E"
	var prefix := "按 %s " % interact_key
	if has_left_gate:
		_add_gate("left1", Vector2(8, FLOOR_Y - 90.0))
	if has_right_gate:
		_add_gate("right1", Vector2(WIDTH - 8, FLOOR_Y - 90.0))
	if has_vault_gate:
		var vault_prompt := prefix + ("返回主路" if kind == Kind.REST else "进入隐藏书库")
		var vault_x := WIDTH * 0.5 if kind == Kind.REST else WIDTH * 0.72
		_add_doors("door1", Vector2(vault_x, FLOOR_Y - 60.0), vault_prompt, prefix, ChapterDoor.Kind.VAULT)
	if has_shortcut_gate:
		_add_doors("door2", Vector2(WIDTH * 0.86, FLOOR_Y - 60.0), prefix + "走捷径回到长廊", prefix, ChapterDoor.Kind.SHORTCUT)


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


func _add_doors(gate_name: String, at: Vector2, prompt: String, prompt_prefix: String, door_kind: ChapterDoor.Kind) -> void:
	var gate := MDSGate.new()
	gate.name = gate_name
	gate.position = at
	gate.collision_layer = 0
	gate.collision_mask = 1
	gate.mode = MDSGate.Mode.INTERACT
	gate.interact_action = &"interact"
	gate.prompt = prompt
	var suffix := prompt.trim_prefix(prompt_prefix)
	# The room is built once per load; keep the copy around so a controller
	# plugged in mid-room can re-render the same door with the new key.
	gate.set_meta(&"prompt_suffix", suffix)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36, 120)
	shape.shape = rect
	gate.add_child(shape)
	add_child(gate)
	var marker := ChapterDoor.new()
	marker.position = at
	marker.kind = door_kind
	marker.caption = suffix
	marker.accent = Color("e6c87a") if door_kind == ChapterDoor.Kind.VAULT else Color("69e0d2")
	add_child(marker)


## Door prompts are plain strings on the MDS gate and are copied into a label
## when the player steps in. Refresh both when the device changes mid-room.
func _refresh_gate_prompts() -> void:
	var prefix := "按 %s " % (_game_flow.prompt_label(&"interact") if _game_flow != null else "E")
	for gate in find_children("*", "MDSGate", true, false):
		var suffix := String(gate.get_meta(&"prompt_suffix", ""))
		if suffix.is_empty():
			continue
		gate.prompt = prefix + suffix
		var label := gate.get("_prompt") as Label
		if label != null:
			gate._show_prompt(label.visible)


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_gate_prompts()


func _on_keybinds_changed() -> void:
	_refresh_gate_prompts()
