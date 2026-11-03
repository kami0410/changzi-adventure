extends Node2D

## One spike room, built in code so the three room scenes stay tiny: floor,
## ArenaRoom (doors + enemy tracking), MDS gates at both ends, and either an
## enemy wave, a treasure chest or the boss. The world file places rooms side
## by side; every room spans 0..1280 x 0..720 in its own coordinates.

const ROOM_SCENE := preload("res://scenes/levels/room.tscn")
const HOUND := preload("res://scenes/enemies/ink_hound.tscn")
const BLANK := preload("res://scenes/enemies/blank_man.tscn")
const BOSS := preload("res://scenes/bosses/ink_archivist.tscn")
const HOUND_ART := preload("res://assets/sprites/enemies/ink_hound.png")
const BLANK_ART := preload("res://assets/sprites/enemies/blank_man.png")
const BOSS_ART := preload("res://assets/sprites/bosses/ink_archivist.png")
const WIDTH := 1280.0
const FLOOR_Y := 560.0

@export_enum("battle", "chest", "boss") var kind := "battle"
@export var has_left_gate := true
@export var has_right_gate := true

var arena: ArenaRoom


func _ready() -> void:
	_build_floor()
	arena = ROOM_SCENE.instantiate() as ArenaRoom
	arena.name = "Arena"
	arena.position = Vector2(WIDTH * 0.5, FLOOR_Y - 280.0)
	add_child(arena)
	match kind:
		"battle":
			_spawn(HOUND, HOUND_ART, Vector2(140, 250), 1.05)
			_spawn(BLANK, BLANK_ART, Vector2(300, 250), 1.05)
		"chest":
			var chest := TreasureChest.new()
			chest.position = Vector2(WIDTH * 0.5, FLOOR_Y - 4.0)
			add_child(chest)
		"boss":
			_spawn(BOSS, BOSS_ART, Vector2(220, 250), 0.82, &"elite")
	if has_left_gate:
		_add_gate("left1", Vector2(8, FLOOR_Y - 90))
	if has_right_gate:
		_add_gate("right1", Vector2(WIDTH - 8, FLOOR_Y - 90))


func _build_floor() -> void:
	var ground := StaticBody2D.new()
	ground.name = "Ground"
	ground.position = Vector2(WIDTH * 0.5, FLOOR_Y + 40.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH, 80)
	shape.shape = rect
	ground.add_child(shape)
	var visual := ColorRect.new()
	visual.color = Color(0.07, 0.1, 0.13)
	visual.offset_left = -WIDTH * 0.5
	visual.offset_right = WIDTH * 0.5
	visual.offset_top = -40.0
	visual.offset_bottom = 120.0
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.add_child(visual)
	var lip := ColorRect.new()
	lip.color = Color(0.2, 0.62, 0.6, 0.8)
	lip.offset_left = -WIDTH * 0.5
	lip.offset_right = WIDTH * 0.5
	lip.offset_top = -40.0
	lip.offset_bottom = -36.0
	lip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.add_child(lip)
	add_child(ground)


func _spawn(scene: PackedScene, art: Texture2D, offset: Vector2, art_scale: float, style: StringName = &"") -> void:
	var enemy := arena.spawn_enemy(scene, offset) as Enemy
	if enemy == null:
		return
	if style != &"":
		enemy.actor_style = style
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = art
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * art_scale
	sprite.offset = Vector2(0, 16.0 - art.get_height() * 0.5 * art_scale)
	enemy.add_child(sprite)
	enemy.sprite_visual = sprite
	for node_name in ["Body", "Eye"]:
		var node := enemy.get_node_or_null(node_name)
		if node != null:
			node.hide()
	enemy.aggro_range = 600.0
	enemy.deaggro_range = 1100.0


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
