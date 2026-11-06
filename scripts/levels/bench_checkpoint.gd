class_name BenchCheckpoint
extends Node2D

## Mid-area checkpoint bench for the big-map chapters (2–4).
##
## Interacting records a fall-back point and writes the normal run save, so a
## long run through one big room can be resumed (or recovered from a fall)
## without walking back to the room entrance. Chapter 1 keeps its existing
## "checkpoint on room entry" behaviour untouched; there are no benches in the
## demo rooms.
##
## The bench adds no save key of its own: game.gd stores the same player
## position it always stores, and [method respawn_position] is only used for
## the in-memory fall guard. That keeps old checkpoints readable and the file
## format unchanged.
##
## [member position] is the bench's ground anchor (its feet line), matching the
## room-local coordinates of [MDSBigRoom] and [BigRoomData].

signal activated(bench: BenchCheckpoint)

const GROUP := &"bench_checkpoints"
const HUD_THEME := preload("res://resources/ui/hud_theme.tres")
const MESSAGE := "检查点已记录 · 长椅"

@export var interact_radius: float = 96.0
## Player position restored by the fall guard: the bench anchor minus the
## player's feet offset (Player.FOOT_Y is 16), so the player stands on the same
## floor line. Kept as a literal to avoid loading Player while parsing a prop.
@export var respawn_offset: Vector2 = Vector2(0, -16.0)
@export var prompt_text: String = "按 E 记录检查点"

var use_count: int = 0
var _time := 0.0
var _near := false
var _prompt: Label


func _ready() -> void:
	build()


## Builds the prompt and registers the bench. Public so unit tests can inspect
## the prop without relying on _ready during SceneTree initialization.
func build() -> void:
	if not is_in_group(GROUP):
		add_to_group(GROUP)
	_build_prompt()
	var flow := _flow()
	if flow != null:
		if not flow.input_device_changed.is_connected(_on_input_device_changed):
			flow.input_device_changed.connect(_on_input_device_changed)
		if not flow.keybinds_changed.is_connected(_on_keybinds_changed):
			flow.keybinds_changed.connect(_on_keybinds_changed)
	_refresh_prompt()


func _process(delta: float) -> void:
	_time += delta
	if _near:
		queue_redraw()


## Global fall-back position for the in-memory checkpoint.
func respawn_position() -> Vector2:
	return global_position + respawn_offset


func can_use(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interact_radius


## Called by game.gd after the checkpoint/run save has been written.
func activate() -> void:
	use_count += 1
	activated.emit(self)
	queue_redraw()


## Drives the interaction prompt; game.gd refreshes it each frame.
func set_player_near(near: bool) -> void:
	if _near == near:
		return
	_near = near
	if _prompt != null:
		_prompt.visible = near
	queue_redraw()


func is_player_near() -> bool:
	return _near


func prompt_label() -> Label:
	return _prompt


func _build_prompt() -> void:
	if _prompt != null:
		return
	_prompt = Label.new()
	_prompt.name = "Prompt"
	_prompt.visible = false
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.theme = HUD_THEME
	_prompt.add_theme_color_override("font_color", Color("e6c87a"))
	_prompt.add_theme_font_size_override("font_size", 12)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.offset_left = -96.0
	_prompt.offset_top = -76.0
	_prompt.offset_right = 96.0
	_prompt.offset_bottom = -50.0
	_prompt.text = prompt_text
	add_child(_prompt)


func _flow() -> GameFlow:
	# Absolute paths need an active SceneTree; unit tests build props before
	# the runner's tree is fully active.
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/Flow") as GameFlow


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_prompt()


func _on_keybinds_changed() -> void:
	_refresh_prompt()


func _refresh_prompt() -> void:
	if _prompt == null:
		return
	var flow := _flow()
	var action := flow.prompt_label(&"interact") if flow != null else "E"
	_prompt.text = prompt_text.replace("按 E", "按 %s" % action)


func _draw() -> void:
	var glow := 0.5 + sin(_time * 2.2) * 0.12 if _near else 0.0
	if _near:
		draw_circle(Vector2(0, -14), 26.0 + sin(_time * 2.2) * 2.0,
			Color(0.9, 0.78, 0.42, glow * 0.25))
	var wood := Color("5a4433")
	var edge := Color("e6c87a") if use_count > 0 else Color("74b3a7")
	# Seat, legs and backrest: a readable greybox bench that needs no new art.
	draw_rect(Rect2(-30, -18, 60, 6), wood)
	draw_rect(Rect2(-30, -18, 60, 2), edge)
	draw_rect(Rect2(-26, -12, 5, 12), wood.darkened(0.2))
	draw_rect(Rect2(21, -12, 5, 12), wood.darkened(0.2))
	draw_rect(Rect2(-30, -40, 6, 22), wood)
	draw_rect(Rect2(24, -40, 6, 22), wood)
	draw_rect(Rect2(-30, -40, 60, 4), wood.lightened(0.08))
	if use_count > 0:
		draw_circle(Vector2(0, -46), 3.0, Color(0.95, 0.83, 0.5, 0.9))
