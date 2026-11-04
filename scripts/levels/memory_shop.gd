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
var _game_flow: GameFlow

@onready var prompt: Label = get_node_or_null("Prompt") as Label

func _ready() -> void:
	add_to_group("memory_shops")
	# Resolved from the tree so a `-s` test runner can precompile this script
	# before the Flow autoload is registered.
	_game_flow = get_node_or_null("/root/Flow") as GameFlow
	if _game_flow != null and not _game_flow.input_device_changed.is_connected(_on_input_device_changed):
		_game_flow.input_device_changed.connect(_on_input_device_changed)
	if _game_flow != null and not _game_flow.keybinds_changed.is_connected(_on_keybinds_changed):
		_game_flow.keybinds_changed.connect(_on_keybinds_changed)
	_refresh_prompt()
	if prompt != null:
		prompt.hide()


func _refresh_prompt() -> void:
	if prompt == null:
		return
	var key := _game_flow.prompt_label(&"interact") if _game_flow != null else "E"
	prompt.text = "按 %s 用残页换物" % key


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_prompt()


func _on_keybinds_changed() -> void:
	_refresh_prompt()

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
