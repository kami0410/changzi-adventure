class_name NPC
extends Area2D

signal interacted(npc: Node)

@export var npc_id: StringName = &""
@export var display_name: String = ""
@export var dialogue: DialogueData
@export var accent_color: Color = Color(0.36, 0.72, 0.68, 1.0)
@export var interaction_radius: float = 84.0
## Whole-number display scale keeps pixel art crisp (see docs/memory/decisions/2026-11-02-art-spec.md).
@export var sprite_scale: float = 1.0

var dialogue_index: int = 0

@onready var body_visual: Polygon2D = get_node_or_null("Body") as Polygon2D
@onready var head_visual: Polygon2D = get_node_or_null("Head") as Polygon2D
@onready var name_label: Label = get_node_or_null("NameLabel") as Label
@onready var prompt_label: Label = get_node_or_null("Prompt") as Label


func _ready() -> void:
	_apply_visuals()
	set_player_near(false)


func interact() -> String:
	var line := ""
	if dialogue != null:
		line = dialogue.line_at(dialogue_index)
		if dialogue.lines.is_empty():
			dialogue_index = 0
		else:
			dialogue_index = posmod(dialogue_index + 1, dialogue.lines.size())
	interacted.emit(self)
	return line


func get_speaker() -> String:
	if display_name != "":
		return display_name
	if dialogue != null and dialogue.speaker != "":
		return dialogue.speaker
	return String(npc_id)


func get_lines() -> Array[String]:
	var result: Array[String] = []
	if dialogue != null:
		for line in dialogue.lines:
			result.append(line)
	return result


func is_player_near(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius


func set_player_near(near: bool) -> void:
	if prompt_label != null:
		prompt_label.visible = near


func _apply_visuals() -> void:
	var art_id := String(npc_id)
	if art_id == "guru":
		art_id = "gulu"
	var sprite_path := "res://assets/sprites/npcs/%s.png" % art_id
	if ResourceLoader.exists(sprite_path):
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		PixelSprite.setup(sprite, load(sprite_path), sprite_scale, 0.0)
		add_child(sprite)
		var motion := ActorMotion.new()
		add_child(motion)
		motion.bind(sprite)
		var top := PixelSprite.art_top(sprite)
		if name_label != null:
			name_label.position.y = top - 30.0
		if prompt_label != null:
			prompt_label.position.y = top - 56.0
		if body_visual != null:
			body_visual.visible = false
		if head_visual != null:
			head_visual.visible = false
	else:
		if body_visual != null:
			body_visual.color = accent_color
		if head_visual != null:
			head_visual.color = accent_color.lightened(0.28)
	if name_label != null:
		name_label.text = get_speaker()
