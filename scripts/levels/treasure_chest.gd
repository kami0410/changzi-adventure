class_name TreasureChest
extends Node2D

## One-shot chest placed between combat rooms. It is deliberately a world
## object, not a pickup: opening it gives the reward immediately and leaves a
## visible empty shell so the player can remember the route.

signal opened(chest: TreasureChest)

## Optional stable id for one-shot progress. Empty: game.gd derives
## `room_id/NodeName`, or adds a suffix when a room holds several chests.
@export var content_id: StringName = &""

const FONT = preload("res://assets/fonts/fusion-pixel-12px-monospaced-zh_hans.ttf.woff2")
const TEXTURE := preload("res://assets/sprites/props/chest.png")

var is_open := false
var _near := false
var _time := 0.0
var _open_time := 0.0
## Resolved from the tree so a `-s` test runner can precompile this script
## before the Flow autoload is registered.
var _game_flow: GameFlow


func _ready() -> void:
	z_index = 2
	add_to_group("treasure_chests")
	_game_flow = get_node_or_null("/root/Flow") as GameFlow


func open() -> bool:
	if is_open:
		return false
	is_open = true
	_open_time = 0.0
	opened.emit(self)
	queue_redraw()
	return true


func set_player_near(near: bool) -> void:
	if _near == near:
		return
	_near = near
	queue_redraw()


## Device-aware hint; drawn every frame so a controller connected mid-room
## changes the glyph without extra bookkeeping.
func prompt_text() -> String:
	if _game_flow == null:
		_game_flow = get_node_or_null("/root/Flow") as GameFlow
	var action := _game_flow.prompt_label(&"interact") if _game_flow != null else "E"
	return "%s  开启" % action


func _process(delta: float) -> void:
	_time += delta
	if is_open:
		_open_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	if not is_open:
		var radius := 26.0 + pulse * 3.0
		for index in 16:
			var angle := index * TAU / 16.0
			draw_rect(Rect2(cos(angle) * radius - 1.0, -4.0 + sin(angle) * radius - 1.0, 2.0, 2.0), Color(0.95, 0.76, 0.38, 0.3 + pulse * 0.3))
		draw_texture(TEXTURE, Vector2(-24, -32))
		if _near:
			draw_string(FONT, Vector2(-48, -40), prompt_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f6d98b"))
	else:
		var fade := clampf(1.0 - _open_time / 1.4, 0.0, 1.0)
		draw_texture(TEXTURE, Vector2(-24, -32), Color(0.45, 0.42, 0.45, 1.0))
		for index in 4:
			var angle := _time * 1.6 + index * TAU / 4.0
			draw_rect(Rect2(cos(angle) * 25.0 - 1.0, -30.0 + sin(angle) * 7.0 - 1.0, 2.0, 2.0), Color(1.0, 0.83, 0.45, 0.25 * fade))
