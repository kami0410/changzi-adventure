class_name CreatureArt
extends Node

## Frame-animated art for the creature enemies (1.0 art pack, tools/import_art_pack.py).
## Every creature has six action strips — idle, move, windup, attack, hurt and
## death — in assets/sprites/creatures/<id>/, described by creatures.json.
## A CreatureArt child picks the strip from its enemy's state each frame and
## swaps the Sprite2D texture; ActorMotion keeps drawing it (bob, squash, hit
## flash), so the creature behaves like any other enemy sprite.

const DIR := "res://assets/sprites/creatures/"
const MANIFEST := DIR + "creatures.json"
## Integer display scale; the wisp was drawn on a 64 px cell and reads too
## small next to the hero at 1x.
const SCALES := {&"ink_wisp": 2}
const LOOPING: Array[StringName] = [&"idle", &"move", &"windup"]
const HURT_TIME := 0.16

static var _manifest: Dictionary = {}
static var _cache: Dictionary = {}

var sprite: Sprite2D
var enemy: Enemy
var creature_id: StringName = &""
var anims: Dictionary = {}
var current: StringName = &""
var _time := 0.0
var _hurt_left := 0.0


static func manifest() -> Dictionary:
	if _manifest.is_empty() and FileAccess.file_exists(MANIFEST):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if parsed is Dictionary:
			_manifest = parsed
	return _manifest


static func has(enemy_id: StringName) -> bool:
	return manifest().has(String(enemy_id))


static func display_scale(enemy_id: StringName) -> float:
	return float(SCALES.get(enemy_id, 1))


## {anim: {"frames": Array[Texture2D], "fps": float}} for one creature. Every
## frame shares the creature's union opaque rect, so the feet and the health
## bar stay put while the pose changes.
static func animations_for(enemy_id: StringName) -> Dictionary:
	var key := String(enemy_id)
	if _cache.has(key):
		return _cache[key]
	var out := {}
	var info: Dictionary = manifest().get(key, {})
	if info.is_empty():
		return out
	var size: Array = info.get("frame_size", [96, 96])
	var w := int(size[0])
	var h := int(size[1])
	var r: Array = info.get("opaque_rect", [0, 0, w, h])
	var rect := Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
	var defs: Dictionary = info.get("anims", {})
	for anim_name in defs:
		var texture := load(DIR + key + "/" + String(anim_name) + ".png") as Texture2D
		if texture == null:
			continue
		var def: Dictionary = defs[anim_name]
		var list: Array[Texture2D] = []
		for i in int(def.get("frames", 1)):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * w, 0, w, h)
			PixelSprite.set_opaque_rect(atlas, rect)
			list.append(atlas)
		out[StringName(anim_name)] = {"frames": list, "fps": float(def.get("fps", 10))}
	_cache[key] = out
	return out


static func first_frame(enemy_id: StringName) -> Texture2D:
	var all := animations_for(enemy_id)
	if not all.has(&"idle"):
		return null
	var frames: Array = all[&"idle"]["frames"]
	return frames[0] if not frames.is_empty() else null


## Seconds the death strip needs, so the body is not freed mid-animation.
static func death_length(enemy_id: StringName) -> float:
	var all := animations_for(enemy_id)
	if not all.has(&"death"):
		return 0.0
	var def: Dictionary = all[&"death"]
	return float((def["frames"] as Array).size()) / maxf(float(def["fps"]), 1.0)


func bind(target: Enemy, id: StringName, visual: Sprite2D) -> void:
	enemy = target
	creature_id = id
	sprite = visual
	anims = animations_for(id)
	if enemy != null and not enemy.damaged.is_connected(_on_damaged):
		enemy.damaged.connect(_on_damaged)


func _on_damaged(_amount: int) -> void:
	_hurt_left = HURT_TIME


## The strip the enemy's state calls for right now.
func pick() -> StringName:
	if enemy == null or not is_instance_valid(enemy):
		return &"idle"
	if enemy.dead:
		return &"death"
	if enemy.state == Enemy.STATE_ATTACK:
		return enemy.creature_phase()
	if _hurt_left > 0.0:
		return &"hurt"
	if enemy.state == Enemy.STATE_CHASE or absf(enemy.velocity.x) > 15.0 or (not enemy.apply_gravity and enemy.velocity.length() > 25.0):
		return &"move"
	return &"idle"


func _process(delta: float) -> void:
	if sprite == null or not is_instance_valid(sprite) or anims.is_empty():
		return
	_hurt_left = maxf(_hurt_left - delta, 0.0)
	var next := pick()
	if not anims.has(next):
		next = &"idle"
	if next != current:
		current = next
		_time = 0.0
	_time += delta
	var def: Dictionary = anims[current]
	var frames: Array = def["frames"]
	var index := int(_time * float(def["fps"]))
	if current in LOOPING:
		index %= frames.size()
	else:
		index = mini(index, frames.size() - 1)
	var texture: Texture2D = frames[index]
	if sprite.texture != texture:
		sprite.texture = texture
	if current == &"death":
		# The strip already shows the body breaking apart; fade it out instead
		# of the generic dark-red death tint.
		var fade := clampf(1.0 - (_time - 0.3) / 0.4, 0.0, 1.0)
		sprite.modulate = Color(1, 1, 1, fade)
