class_name VFX
extends AnimatedSprite2D

## Sprite-sheet combat effects exported from pixelfx (tools/export_vfx.mjs,
## assets/vfx/vfx_manifest.json). One call plays an effect at a world point;
## non-looping effects free themselves, looping ones can follow a target for a
## while (status effects). Purely visual: no collision, no gameplay state.
##
## Effects are authored facing right; `flip` mirrors them around their pivot.
## They are pixel art at 1x, drawn with nearest filtering above the actors.

const MANIFEST := "res://assets/vfx/vfx_manifest.json"
const DIR := "res://assets/vfx/"
## Hard cap on live effects, so a 96-bolt volley cannot flood the scene.
const MAX_LIVE := 48
const Z := 6

static var _specs: Dictionary = {}
static var _frames: Dictionary = {}
static var _loaded := false
static var _live := 0

var follow: Node2D
var follow_offset := Vector2.ZERO
var life := -1.0


static func spec(id: StringName) -> Dictionary:
	_load_manifest()
	return _specs.get(String(id), {})


static func has(id: StringName) -> bool:
	return not spec(id).is_empty()


## Plays [param id] at [param at] (global). Returns the node, or null when the
## effect is unknown, the host is gone or the live cap is reached.
static func spawn(host: Node, id: StringName, at: Vector2, flip := false, scale_factor := 1.0,
		tint := Color.WHITE) -> VFX:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return null
	if _live >= MAX_LIVE:
		return null
	var frames := _sprite_frames(id)
	if frames == null:
		return null
	var info := spec(id)
	var fx := VFX.new()
	fx.sprite_frames = frames
	fx.animation = &"default"
	fx.centered = false
	var size: Array = info.get("frame_size", [0, 0])
	var pivot: Array = info.get("pivot", [0, 0])
	fx.offset = Vector2(-float(pivot[0]), -float(pivot[1]))
	fx.flip_h = flip
	if flip:
		# flip_h mirrors the texture inside its rect; move the rect so the
		# pivot stays on the same pixel.
		fx.offset.x = -(float(size[0]) - float(pivot[0]))
	fx.scale = Vector2.ONE * scale_factor
	fx.modulate = tint
	fx.z_index = Z
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	host.add_child(fx)
	fx.global_position = at.round()
	fx.play(&"default")
	return fx


## Plays a looping effect that follows [param target] for [param seconds].
static func attach(target: Node2D, id: StringName, seconds: float, offset := Vector2.ZERO) -> VFX:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return null
	# One instance per effect per target: refresh it instead of stacking.
	var key := StringName("vfx_" + String(id))
	var existing: Variant = target.get_meta(key, null)
	if existing is VFX and is_instance_valid(existing):
		(existing as VFX).life = maxf((existing as VFX).life, seconds)
		return existing
	var host := target.get_parent()
	var fx := spawn(host, id, target.global_position + offset)
	if fx == null:
		return null
	fx.follow = target
	fx.follow_offset = offset
	fx.life = seconds
	target.set_meta(key, fx)
	return fx


func _enter_tree() -> void:
	_live += 1


func _exit_tree() -> void:
	_live = maxi(_live - 1, 0)


func _ready() -> void:
	animation_finished.connect(_on_finished)


func _process(delta: float) -> void:
	if follow != null:
		if not is_instance_valid(follow) or (follow is Enemy and (follow as Enemy).dead):
			queue_free()
			return
		global_position = (follow.global_position + follow_offset).round()
	if life >= 0.0:
		life -= delta
		if life <= 0.0:
			queue_free()


func _on_finished() -> void:
	if life < 0.0:
		queue_free()


static func _load_manifest() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(MANIFEST):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if data is Dictionary:
		_specs = (data as Dictionary).get("effects", {})


static func _sprite_frames(id: StringName) -> SpriteFrames:
	var key := String(id)
	if _frames.has(key):
		return _frames[key]
	var info := spec(id)
	if info.is_empty():
		return null
	var texture := load(DIR + key + ".png") as Texture2D
	if texture == null:
		return null
	var frames := SpriteFrames.new()
	frames.set_animation_speed(&"default", float(info.get("fps", 30)))
	frames.set_animation_loop(&"default", bool(info.get("loop", false)))
	var size: Array = info.get("frame_size", [1, 1])
	var columns := maxi(int(info.get("columns", 1)), 1)
	for i in int(info.get("frames", 1)):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2((i % columns) * float(size[0]), (i / columns) * float(size[1]),
			float(size[0]), float(size[1]))
		frames.add_frame(&"default", atlas)
	_frames[key] = frames
	return frames
