class_name BigRoomAmbient
extends Node2D

## Light ambience for a big-map room, drawn only inside the camera window
## (plus a small margin). A 3840 px room therefore pays for about one screen of
## motes, not for the whole union. The tint normally comes from the MDS area
## colour, so each area reads differently without a chapter-wide hardcode.

const MARGIN := 64.0
const MAX_MOTES := 160
const REFERENCE_AREA := 1280.0 * 720.0

## "motes" drifts sideways; "embers" rises. Unknown kinds draw as motes.
@export var kind: StringName = &"motes"
## Room-local rectangle the ambience is confined to.
@export var bounds: Rect2 = Rect2(0, 0, 1280, 720)
@export var tint: Color = Color("9fbfb9")
@export_range(0.0, 2.0, 0.05) var density: float = 0.5

var _time := 0.0


func _ready() -> void:
	z_index = -8


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Camera-visible part of [member bounds], in this node's local coordinates.
## Empty when the camera is outside the room. Without a camera (heads/tests) the
## whole bounds is used.
func view_window() -> Rect2:
	if not is_inside_tree():
		return bounds
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return bounds
	var view_size := get_viewport_rect().size / camera.zoom
	var center := camera.get_screen_center_position() - global_position
	var view := Rect2(center - view_size * 0.5, view_size)
	var window := view.intersection(bounds)
	if window.size.x <= 0.0 or window.size.y <= 0.0:
		return Rect2()
	# Keep the margin inside the room so the ambience never draws into the
	# union's empty margin or another area's space.
	return window.grow(MARGIN).intersection(bounds)


## Motes drawn this frame: density scaled by the visible share of a 720p screen.
func mote_count() -> int:
	var window := view_window()
	if window.size.x <= 0.0 or window.size.y <= 0.0:
		return 0
	var share := (window.size.x * window.size.y) / REFERENCE_AREA
	return clampi(int(round(64.0 * maxf(density, 0.0) * share)), 0, MAX_MOTES)


func _draw() -> void:
	var window := view_window()
	if window.size.x <= 0.0 or window.size.y <= 0.0:
		return
	for index in mote_count():
		var x := window.position.x + fposmod(
			float(index) * 173.0 + _time * (6.0 + float(index % 5)), window.size.x)
		var y := 0.0
		if kind == &"embers":
			y = window.position.y + window.size.y - fposmod(
				float(index) * 97.0 + _time * (18.0 + float(index % 4)), window.size.y)
		else:
			y = window.position.y + fposmod(float(index) * 67.0, window.size.y) \
				+ sin(_time * 0.7 + float(index)) * 14.0
		var alpha := tint.a * (0.35 + 0.65 * absf(sin(_time * 0.9 + float(index) * 1.7)))
		draw_rect(Rect2(x, y, 3.0, 2.0), Color(tint, alpha))
