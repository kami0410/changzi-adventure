class_name DepthHaze
extends Node2D

## Depth haze (1.1): a veil between the backdrop and the play plane, following
## the camera. See resources/shaders/depth_haze.gdshader. The run scene owns
## one and retints it per chapter.

const SHADER: Shader = preload("res://resources/shaders/depth_haze.gdshader")
## Behind actors, tiles and pickups (0+); in front of backdrops, mid-ground
## art, props and weather (-3 and below).
const HAZE_Z := -2
## Per chapter: [colour, density]. Tuned against each chapter's backdrop so
## the play plane separates without flattening the painting.
const LOOKS := {
	&"ink_archive": [Color("06141c"), 0.36],
	&"breathing_ruins": [Color("07140f"), 0.38],
	&"lightless_sea": [Color("050a1c"), 0.36],
	&"smiling_theater": [Color("14070c"), 0.32],
}
const DEFAULT_LOOK: Array = [Color("06141c"), 0.34]
const HALF := Vector2(2400.0, 1500.0)

var target: Node2D
var _material: ShaderMaterial
var _camera: Camera2D


func _ready() -> void:
	z_index = HAZE_Z
	z_as_relative = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	material = _material
	set_look(&"")


func set_look(chapter_id: StringName) -> void:
	var look: Array = LOOKS.get(chapter_id, DEFAULT_LOOK)
	if _material == null:
		return
	_material.set_shader_parameter(&"haze_color", look[0])
	_material.set_shader_parameter(&"density", float(look[1]))
	# A phone gets the veil without the wide light pool falloff maths changing
	# anything visible; the pass is one quad either way.
	_material.set_shader_parameter(&"vignette", 0.34 if Perf.low else 0.42)


func _draw() -> void:
	draw_rect(Rect2(-HALF, HALF * 2.0), Color.WHITE)


func _process(_delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_2d()
		if _camera == null:
			return
	global_position = _camera.get_screen_center_position()
	var zoom := _camera.zoom
	var view := get_viewport_rect().size / Vector2(maxf(zoom.x, 0.01), maxf(zoom.y, 0.01))
	_material.set_shader_parameter(&"view_half", view * 0.5)
	if target != null and is_instance_valid(target):
		_material.set_shader_parameter(&"focus", target.global_position - global_position + Vector2(0, -24))
