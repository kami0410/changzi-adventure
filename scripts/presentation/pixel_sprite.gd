class_name PixelSprite
extends RefCounted

## Grounding and crisp rendering for single-texture pixel-art actors.
## Sprite2D.offset is in texture pixels (applied before scale), so a foot
## height in local pixels must be divided by the scale. The opaque bounds are
## measured once per texture so the lowest opaque row lands on the floor.

const PIXEL_SHADER: Shader = preload("res://resources/shaders/pixel_smooth.gdshader")
## Same threshold as the asset pipeline; Image.get_used_rect() counts faint halos.
const ALPHA_THRESHOLD := 24

static var _rects: Dictionary = {}
static var _material: ShaderMaterial
static var _role_materials: Dictionary = {}
## 1.1 readability: who an actor is decides how its silhouette is traced —
## [outline colour, outline strength, lit-rim colour, lit-rim strength].
const ROLE_LOOKS := {
	&"player": [Color("bff3ea"), 0.62, Color("eafffb"), 0.9],
	&"enemy": [Color("e08a63"), 0.45, Color("ffc79e"), 0.75],
	&"boss": [Color("f0a04e"), 0.6, Color("ffe0a8"), 0.85],
}


## Pins the opaque bounds used for [param texture]. Animated actors give every
## frame the union of all frames, so grounding and centring do not jitter as
## the silhouette changes.
static func set_opaque_rect(texture: Texture2D, rect: Rect2i) -> void:
	if texture == null:
		return
	var key := texture.resource_path if texture.resource_path != "" else str(texture.get_instance_id())
	_rects[key] = rect


## Opaque bounds of the texture in texel coordinates (cached per texture).
static func opaque_rect(texture: Texture2D) -> Rect2i:
	if texture == null:
		return Rect2i()
	var key := texture.resource_path if texture.resource_path != "" else str(texture.get_instance_id())
	if _rects.has(key):
		return _rects[key]
	var size := Vector2i(texture.get_size())
	var rect := Rect2i(Vector2i.ZERO, size)
	var image := texture.get_image()
	if image != null and not image.is_empty():
		if image.is_compressed():
			image.decompress()
		var top := -1
		var bottom := -1
		var left := size.x
		var right := -1
		for y in image.get_height():
			for x in image.get_width():
				if image.get_pixel(x, y).a8 > ALPHA_THRESHOLD:
					if top < 0:
						top = y
					bottom = y
					left = mini(left, x)
					right = maxi(right, x)
		if bottom >= 0:
			rect = Rect2i(left, top, right - left + 1, bottom - top + 1)
	_rects[key] = rect
	return rect


## Sprite offset that centres the opaque art horizontally and puts its lowest
## opaque row at local `foot_y` (in the sprite's parent space).
static func ground_offset(texture: Texture2D, scale: float, foot_y: float = 0.0) -> Vector2:
	if texture == null or scale <= 0.0:
		return Vector2.ZERO
	var rect := opaque_rect(texture)
	var size := texture.get_size()
	# Whole texels only: a half-texel offset would put every texel between two
	# screen pixels and blur the art at 1x.
	var centre_x := roundf(float(rect.position.x) + float(rect.size.x) * 0.5 - size.x * 0.5)
	return Vector2(-centre_x, roundf(foot_y / scale + size.y * 0.5 - float(rect.end.y)))


## Local y (parent space) of the art's highest opaque pixel.
static func art_top(sprite: Sprite2D) -> float:
	if sprite == null or sprite.texture == null:
		return 0.0
	var rect := opaque_rect(sprite.texture)
	return (sprite.offset.y - sprite.texture.get_size().y * 0.5 + float(rect.position.y)) * sprite.scale.y


## Local y (parent space) just below the art's lowest opaque pixel.
static func art_bottom(sprite: Sprite2D) -> float:
	if sprite == null or sprite.texture == null:
		return 0.0
	var rect := opaque_rect(sprite.texture)
	return (sprite.offset.y - sprite.texture.get_size().y * 0.5 + float(rect.end.y)) * sprite.scale.y


## Opaque art height after scaling.
static func art_height(sprite: Sprite2D) -> float:
	if sprite == null or sprite.texture == null:
		return 0.0
	return float(opaque_rect(sprite.texture).size.y) * absf(sprite.scale.y)


## Shared material for crisp sampling at fractional scales and rotations.
static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = PIXEL_SHADER
	return _material


## Same crisp sampling, with the silhouette traced for [param role]
## (&"player", &"enemy", &"boss"). Unknown roles keep the shared material.
static func apply_role(item: CanvasItem, role: StringName) -> void:
	if item == null or not ROLE_LOOKS.has(role):
		return
	if not _role_materials.has(role):
		var look: Array = ROLE_LOOKS[role]
		var made := ShaderMaterial.new()
		made.shader = PIXEL_SHADER
		made.set_shader_parameter(&"outline_color", look[0])
		made.set_shader_parameter(&"outline_strength", float(look[1]))
		made.set_shader_parameter(&"rim_color", look[2])
		made.set_shader_parameter(&"rim_strength", float(look[3]))
		made.set_shader_parameter(&"edge_pixels", 1.25)
		_role_materials[role] = made
	item.material = _role_materials[role]
	item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


static func apply_material(item: CanvasItem) -> void:
	item.material = material()
	item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


## Configures a Sprite2D for an actor: crisp sampling and feet on `foot_y`.
static func setup(sprite: Sprite2D, texture: Texture2D, scale: float, foot_y: float) -> void:
	sprite.texture = texture
	sprite.centered = true
	sprite.scale = Vector2.ONE * scale
	sprite.offset = ground_offset(texture, scale, foot_y)
	apply_material(sprite)
