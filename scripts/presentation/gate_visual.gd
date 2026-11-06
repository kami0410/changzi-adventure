class_name GateVisual
extends Node2D

## The visible half of a big-map [MDSGate] (the gates [MDSBigRoom] generates
## from the world file, plus authored gates such as the shortcut arrival).
##
## It reuses [ChapterDoor]'s visual language instead of inventing new art: the
## same [code]door.png[/code] recess, accent frame, drifting ink motes and a
## HUD-theme caption in the accent colour. [MDSGate] keeps owning collision,
## prompt, transition and blocked state; this node adds no collision, signal or
## input and never moves the gate.
##
## Side follows the world file:
## - left/right: a standing door whose bottom rests [member floor_offset] below
##   the gate (the authoring convention puts side gates 90 px above the floor).
## - top/bot: the same texture laid on its side as a ceiling/floor hatch, kept
##   inside the room so the opening reads as a vertical passage.
## The caption says where the gate leads; a gate with no outbound transition is
## an arrival point and says so ("来路") instead of showing a direction arrow.

const TEXTURE := preload("res://assets/sprites/props/door.png")
const HUD_THEME: Theme = preload("res://resources/ui/hud_theme.tres")
const WIDTH := 48.0
const HEIGHT := 96.0
## Half of the rotated hatch's short side.
const HATCH_HALF := 24.0
const CAPTION_WIDTH := 200.0
const CAPTION_HEIGHT := 22.0
const CAPTION_ARROW := "前往 "
const CAPTION_ARRIVAL := "来路"

@export var side: String = "right"
@export var caption: String = ""
@export var accent: Color = Color("69e0d2")
## Left/right gates: distance from the gate centre down to the floor line.
@export var floor_offset: float = 90.0
## True when the gate only receives players (no outbound transition).
@export var arrival: bool = false
## Optional marker-local rect the caption's top-left must stay inside (the
## room inset by the caption size). [MDSBigRoom] fills it so a ceiling/floor
## hatch next to a wall pulls its label into the room too, not just side
## doors. Empty keeps the caption where the side rules put it.
@export var caption_area: Rect2 = Rect2()

var _time := 0.0
var _caption: Label


func _ready() -> void:
	build()


## Public so [MDSBigRoom] and tests can configure a marker without waiting for
## the node to enter the tree. Safe to call again after changing exports.
func build() -> void:
	# Behind the player and an [MDSGateBarrier] (both z 0), in front of the
	# backdrop and ambience: the doorway is part of the wall, not the actor.
	z_index = -1
	if _caption == null:
		_caption = Label.new()
		_caption.name = "Caption"
		_caption.theme = HUD_THEME
		_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_caption.add_theme_font_size_override("font_size", 12)
		_caption.add_theme_color_override("font_outline_color", Color(0.051, 0.071, 0.094))
		_caption.add_theme_constant_override("outline_size", 4)
		_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_caption)
	_caption.add_theme_color_override("font_color", accent)
	_caption.text = caption

	_caption.size = Vector2(CAPTION_WIDTH, CAPTION_HEIGHT)
	_caption.position = Vector2(_caption_x(), _caption_y())
	queue_redraw()


func caption_text() -> String:
	return _caption.text if _caption != null else ""


func caption_label() -> Label:
	return _caption


## Edge gates sit exactly on the wall, so the door and its caption are pushed
## into the room: otherwise half of the doorway would be outside the camera's
## room bounds and never visible.
func _caption_x() -> float:
	var x := -CAPTION_WIDTH * 0.5
	match side:
		"right":
			x = -CAPTION_WIDTH
		"left":
			x = 0.0
	if caption_area.size.x > 0.0:
		x = clampf(x, caption_area.position.x, caption_area.end.x)
	return x


## Where the caption sits relative to the gate. Top passages open in the
## ceiling, so their caption goes below the hatch where the player can see it.
func _caption_y() -> float:
	var y := floor_offset - HEIGHT - 34.0
	match side:
		"top":
			y = HATCH_HALF * 2.0 + 6.0
		"bot":
			y = -HATCH_HALF * 2.0 - 32.0
	if caption_area.size.y > 0.0:
		y = clampf(y, caption_area.position.y, caption_area.end.y)
	return y


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var pulse := 0.55 + 0.15 * sin(_time * 2.2)
	match side:
		"top":
			_draw_hatch(1.0, pulse)
		"bot":
			_draw_hatch(-1.0, pulse)
		_:
			_draw_door(pulse)


## Left/right gates are set into the wall: the door's outer edge sits on the
## gate and the 48 px width extends into the room, so the whole doorway stays
## inside the room bounds. Mid-room doors (the shortcut) stay centred.
func _door_left() -> float:
	match side:
		"right":
			return -WIDTH
		"left":
			return 0.0
	return -WIDTH * 0.5


func _draw_door(pulse: float) -> void:
	var bottom := floor_offset
	var top := bottom - HEIGHT
	var left := _door_left()
	var half := WIDTH * 0.5
	draw_texture(TEXTURE, Vector2(left, top))
	# The same accent frame as ChapterDoor marks the interactable edge.
	var frame := Color(accent, pulse * 0.65)
	draw_rect(Rect2(left, top, 1.0, HEIGHT), frame)
	draw_rect(Rect2(left + WIDTH - 1.0, top, 1.0, HEIGHT), frame)
	draw_rect(Rect2(left, top, WIDTH, 1.0), frame)
	draw_rect(Rect2(left, bottom - 2.0, WIDTH, 2.0), Color(accent, pulse * 0.28))
	for index in 6:
		var travel := fposmod(_time * 18.0 + index * 21.0, HEIGHT)
		var x := left + half + sin(_time * 1.4 + index * 2.3) * half * 0.55
		draw_rect(Rect2(x - 1.0, bottom - 6.0 - travel - 1.0, 2.0, 2.0),
			Color(accent, 0.18 + 0.16 * pulse))
	if not arrival:
		_draw_arrow(Vector2(left + half, top + HEIGHT * 0.58), pulse)


## A vertical passage drawn as the same door texture on its side, kept inside
## the room: top hatches hang down from the ceiling, floor hatches sit on the
## floor line. [param direction] is +1 for top and -1 for bot.
func _draw_hatch(direction: float, pulse: float) -> void:
	var center := Vector2(0.0, direction * HATCH_HALF)
	draw_set_transform(center, PI * 0.5, Vector2.ONE)
	draw_texture(TEXTURE, Vector2(-WIDTH * 0.5, -HEIGHT * 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var rect := Rect2(center - Vector2(HEIGHT * 0.5, HATCH_HALF),
		Vector2(HEIGHT, HATCH_HALF * 2.0))
	draw_rect(rect, Color(accent, pulse * 0.65), false, 1.0)
	for index in 6:
		var travel := fposmod(_time * 18.0 + index * 19.0, 64.0)
		var x := sin(_time * 1.3 + index * 2.1) * HEIGHT * 0.35
		var y := center.y + HATCH_HALF - travel
		draw_rect(Rect2(x - 1.0, y - 1.0, 2.0, 2.0),
			Color(accent, 0.18 + 0.16 * pulse))
	if not arrival:
		_draw_arrow(center, pulse)


## Pixel chevron pointing out of the gate, towards the room it leads to.
func _draw_arrow(at: Vector2, pulse: float) -> void:
	var direction: Vector2 = {
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT,
		"top": Vector2.UP,
		"bot": Vector2.DOWN,
	}.get(side, Vector2.ZERO)
	if direction == Vector2.ZERO:
		return
	var color := Color(accent, 0.55 + 0.2 * pulse)
	var tip := at + direction * 9.0
	draw_line(at - direction * 5.0, tip, color, 2.0)
	var wing := direction.orthogonal() * 5.0
	draw_line(tip, tip - direction * 6.0 + wing, color, 2.0)
	draw_line(tip, tip - direction * 6.0 - wing, color, 2.0)
