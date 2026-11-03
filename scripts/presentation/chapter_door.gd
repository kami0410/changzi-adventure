class_name ChapterDoor
extends Node2D

## The visible half of an interact gate: a recessed ink doorway with a slow
## pulse, drifting motes and a glyph that tells a hidden vault from a shortcut.
## The MDSGate at the same position owns collision, prompt and transition.

enum Kind { VAULT, SHORTCUT }

@export var kind: Kind = Kind.VAULT
@export var accent: Color = Color("69e0d2")
@export var caption: String = ""

const HUD_THEME: Theme = preload("res://resources/ui/hud_theme.tres")
const TEXTURE := preload("res://assets/sprites/props/door.png")
const WIDTH := 48.0
const HEIGHT := 96.0
## Floor is 60 px below the marker's origin (the door's gate sits at FLOOR_Y - 60).
const FLOOR := 60.0

var _time := 0.0


func _ready() -> void:
	z_index = 3
	var label := Label.new()
	label.text = caption
	label.position = Vector2(-100.0, FLOOR - HEIGHT - 34.0)
	label.size = Vector2(200.0, 22.0)
	label.theme = HUD_THEME
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", accent)
	label.add_theme_color_override("font_outline_color", Color(0.051, 0.071, 0.094))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var top := FLOOR - HEIGHT
	var half := WIDTH * 0.5
	var pulse := 0.55 + 0.15 * sin(_time * 2.2)
	draw_texture(TEXTURE, Vector2(-half, top))
	# Accent frame marks the interactable edge.
	var frame := Color(accent, pulse * 0.65)
	draw_rect(Rect2(-half, top, 1.0, HEIGHT), frame)
	draw_rect(Rect2(half - 1.0, top, 1.0, HEIGHT), frame)
	draw_rect(Rect2(-half, top, WIDTH, 1.0), frame)
	draw_rect(Rect2(-half, FLOOR - 2.0, WIDTH, 2.0), Color(accent, pulse * 0.28))
	if kind == Kind.VAULT:
		_draw_book(Vector2(0.0, top + 40.0))
	else:
		_draw_shortcut(Vector2(0.0, top + 40.0))
	# Motes drift up through the doorway (2 px blocks, no smooth circles).
	for index in 6:
		var travel := fposmod(_time * 18.0 + index * 21.0, HEIGHT)
		var x := sin(_time * 1.4 + index * 2.3) * half * 0.55
		draw_rect(Rect2(x - 1.0, FLOOR - 6.0 - travel - 1.0, 2.0, 2.0), Color(accent, 0.18 + 0.16 * pulse))


func _draw_book(center: Vector2) -> void:
	var ink := Color(0.88, 0.97, 0.92, 0.9)
	var glow := Color(accent, 0.55 + 0.15 * sin(_time * 3.0))
	draw_rect(Rect2(center + Vector2(-10, -7), Vector2(20, 14)), Color(0.03, 0.06, 0.07, 0.9))
	draw_line(center + Vector2(-10, -7), center + Vector2(-10, 7), ink, 1.0)
	draw_line(center + Vector2(10, -7), center + Vector2(10, 7), ink, 1.0)
	draw_line(center + Vector2(-10, 7), center + Vector2(10, 7), ink, 1.0)
	draw_line(center + Vector2(0, -6), center + Vector2(0, 6), glow, 1.0)
	for row in 3:
		var y := -3.0 + row * 4.0
		draw_line(center + Vector2(-7, y), center + Vector2(-2, y), Color(ink, 0.55), 1.0)
		draw_line(center + Vector2(2, y), center + Vector2(7, y), Color(ink, 0.55), 1.0)
	# A slow spark marks a secret.
	var spark := center + Vector2(12, -13)
	var twinkle := 0.4 + 0.4 * absf(sin(_time * 2.4))
	draw_line(spark + Vector2(-3, 0), spark + Vector2(3, 0), Color(1.0, 0.86, 0.55, twinkle), 1.0)
	draw_line(spark + Vector2(0, -3), spark + Vector2(0, 3), Color(1.0, 0.86, 0.55, twinkle), 1.0)


func _draw_shortcut(center: Vector2) -> void:
	var ink := Color(accent, 0.85)
	var shift := sin(_time * 2.4) * 2.0
	for index in 2:
		var x := center.x - 8.0 + index * 10.0 + shift
		draw_line(Vector2(x, center.y - 8.0), Vector2(x + 8.0, center.y), ink, 2.0)
		draw_line(Vector2(x + 8.0, center.y), Vector2(x, center.y + 8.0), ink, 2.0)
	draw_line(center + Vector2(-12, 14), center + Vector2(12, 14), Color(accent, 0.35), 1.0)
