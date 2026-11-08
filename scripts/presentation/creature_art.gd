class_name CreatureArt
extends Node

## Frame-animated art for the 0.15 creature enemies. The loops come from the
## pixelfx critters (tools/export_vfx.mjs, `creature_*` sheets in assets/vfx),
## recoloured to the chapter moods. A CreatureArt child swaps the enemy's
## Sprite2D texture every frame; ActorMotion keeps drawing it (bob, squash,
## hit flash), so the creature behaves like any other enemy sprite.

## enemy id -> [sheet id, integer display scale]
const SPECS := {
	&"watcher_eye": [&"creature_eye", 2],
	&"ink_wisp": [&"creature_wisp", 2],
	&"skull_lantern": [&"creature_skull", 1],
	&"abyss_jelly": [&"creature_jelly", 1],
	&"name_snake": [&"creature_snake", 2],
	&"echo_bat": [&"creature_bat", 2],
}

static var _frames: Dictionary = {}

var sprite: Sprite2D
var frames: Array[Texture2D] = []
var fps := 15.0
var _time := 0.0


static func has(enemy_id: StringName) -> bool:
	return SPECS.has(enemy_id)


static func display_scale(enemy_id: StringName) -> float:
	return float((SPECS.get(enemy_id, [&"", 1]) as Array)[1])


static func sheet_for(enemy_id: StringName) -> StringName:
	return StringName((SPECS.get(enemy_id, [&"", 1]) as Array)[0])


## Shared frame list for a sheet; every frame gets the union opaque rect.
static func frames_for(sheet_id: StringName) -> Array[Texture2D]:
	var key := String(sheet_id)
	if _frames.has(key):
		return _frames[key]
	var out: Array[Texture2D] = []
	var info := VFX.spec(sheet_id)
	if info.is_empty():
		return out
	var texture := load(VFX.DIR + key + ".png") as Texture2D
	if texture == null:
		return out
	var size: Array = info.get("frame_size", [1, 1])
	var w := int(size[0])
	var h := int(size[1])
	var columns := maxi(int(info.get("columns", 1)), 1)
	var count := int(info.get("frames", 1))
	var image := texture.get_image()
	if image != null and image.is_compressed():
		image.decompress()
	var union := Rect2i()
	for i in count:
		var region := Rect2i((i % columns) * w, (i / columns) * h, w, h)
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(region)
		out.append(atlas)
		if image != null:
			var used := image.get_region(region).get_used_rect()
			if used.size.x > 0:
				union = used if union.size.x == 0 else union.merge(used)
	if union.size.x == 0:
		union = Rect2i(0, 0, w, h)
	for frame in out:
		PixelSprite.set_opaque_rect(frame, union)
	_frames[key] = out
	return out


static func frame_rate(sheet_id: StringName) -> float:
	return float(VFX.spec(sheet_id).get("fps", 15))


func _process(delta: float) -> void:
	if sprite == null or not is_instance_valid(sprite) or frames.is_empty():
		return
	_time += delta
	var index := int(_time * fps) % frames.size()
	if sprite.texture != frames[index]:
		sprite.texture = frames[index]
