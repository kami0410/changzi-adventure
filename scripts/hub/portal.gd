class_name HubPortal
extends Area2D

signal activated

@export var interaction_radius: float = 110.0

@onready var prompt_label: Label = get_node_or_null("Prompt") as Label


func _ready() -> void:
	set_player_near(false)
	var glow := get_node_or_null("Glow") as Polygon2D
	if glow != null:
		var tween := create_tween().set_loops()
		tween.tween_property(glow, "modulate:a", 0.45, 1.4).set_trans(Tween.TRANS_SINE)
		tween.tween_property(glow, "modulate:a", 1.0, 1.4).set_trans(Tween.TRANS_SINE)


func is_player_near(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius


func set_player_near(near: bool) -> void:
	if prompt_label != null:
		prompt_label.visible = near


func activate() -> void:
	activated.emit()
