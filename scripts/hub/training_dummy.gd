class_name TrainingDummy
extends Area2D

## Hub training stele: a damage sponge for the first free-form spell. It never
## dies; the HUD number and hit signal are the tutorial feedback.

signal hit(amount: int)

const TEXTURE = preload("res://assets/sprites/props/training_dummy.png")
const FONT = preload("res://assets/fonts/fusion-pixel-12px-monospaced-zh_hans.ttf.woff2")

var max_health := 99999
var health := 99999
var _prompt: Label
var _game_flow: GameFlow


func _ready() -> void:
	z_index = 2
	collision_layer = 0
	collision_mask = 0
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -36)
	add_child(sprite)
	_prompt = Label.new()
	_prompt.position = Vector2(-70, -92)
	_prompt.size = Vector2(140, 20)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_override("font", FONT)
	_prompt.add_theme_font_size_override("font_size", 12)
	_prompt.add_theme_color_override("font_color", Color("e6c87a"))
	add_child(_prompt)
	# Resolved from the tree so a `-s` test runner can precompile this script
	# before the Flow autoload is registered.
	_game_flow = get_node_or_null("/root/Flow") as GameFlow
	if _game_flow != null and not _game_flow.input_device_changed.is_connected(_on_input_device_changed):
		_game_flow.input_device_changed.connect(_on_input_device_changed)
	if _game_flow != null and not _game_flow.keybinds_changed.is_connected(_on_keybinds_changed):
		_game_flow.keybinds_changed.connect(_on_keybinds_changed)
	_refresh_prompt()


func _refresh_prompt() -> void:
	if _prompt == null:
		return
	var key := _game_flow.prompt_label(&"interact") if _game_flow != null else "E"
	_prompt.text = "训练碑 · 按 %s 试放" % key


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_prompt()


func _on_keybinds_changed() -> void:
	_refresh_prompt()


func take_damage(amount: int, _from: Vector2 = Vector2.ZERO) -> void:
	if amount <= 0:
		return
	health = maxi(health - amount, 1)
	hit.emit(amount)
	if is_inside_tree():
		CombatFX.spawn(get_parent(), global_position + Vector2(0, -54), &"number", Color("f1ddae"), 1.0, 30, amount)
