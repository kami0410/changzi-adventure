class_name TrainingDummy
extends Area2D

## Hub training stele: a damage sponge for the first free-form spell. It never
## dies; the HUD number and hit signal are the tutorial feedback.

signal hit(amount: int)

const TEXTURE = preload("res://assets/sprites/props/training_dummy.png")
const FONT = preload("res://assets/fonts/fusion-pixel-12px-monospaced-zh_hans.ttf.woff2")

var max_health := 99999
var health := 99999


func _ready() -> void:
	z_index = 2
	collision_layer = 0
	collision_mask = 0
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -36)
	add_child(sprite)
	var prompt := Label.new()
	prompt.text = "训练碑 · 按 E 试放"
	prompt.position = Vector2(-70, -92)
	prompt.size = Vector2(140, 20)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_override("font", FONT)
	prompt.add_theme_font_size_override("font_size", 12)
	prompt.add_theme_color_override("font_color", Color("e6c87a"))
	add_child(prompt)


func take_damage(amount: int, _from: Vector2 = Vector2.ZERO) -> void:
	if amount <= 0:
		return
	health = maxi(health - amount, 1)
	hit.emit(amount)
	if is_inside_tree():
		CombatFX.spawn(get_parent(), global_position + Vector2(0, -54), &"number", Color("f1ddae"), 1.0, 30, amount)
