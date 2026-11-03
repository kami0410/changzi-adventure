class_name MemoryShop
extends Area2D

## A small in-run stall. The player spends pages (残页) on healing, a relic or a
## new word. It is intentionally not a full merchant scene: one readable choice
## point per chapter, no menu maze.

const TEXTURE := preload("res://assets/sprites/props/shop.png")

@export var shop_id: StringName = &""
@export var interaction_radius: float = 115.0
var _time := 0.0
var _near := false

@onready var prompt: Label = get_node_or_null("Prompt") as Label

func _ready() -> void:
	add_to_group("memory_shops")
	if prompt != null:
		prompt.hide()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func is_player_near(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius

func set_player_near(near: bool) -> void:
	_near = near
	if prompt != null:
		prompt.visible = near

func _draw() -> void:
	draw_texture(TEXTURE, Vector2(-48, -96))
	if _near:
		var glow := Color("d8b178")
		var radius := 54.0 + sin(_time * 3.0) * 4.0
		for index in 24:
			var angle := index * TAU / 24.0
			draw_rect(Rect2(cos(angle) * radius - 1.0, -50.0 + sin(angle) * radius - 1.0, 2.0, 2.0), Color(glow, 0.55))
