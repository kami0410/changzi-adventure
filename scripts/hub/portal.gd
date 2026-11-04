class_name HubPortal
extends Area2D

signal activated

@export var interaction_radius: float = 110.0

@onready var prompt_label: Label = get_node_or_null("Prompt") as Label

var _game_flow: GameFlow


func _ready() -> void:
	set_player_near(false)
	_game_flow = get_node_or_null("/root/Flow") as GameFlow
	if _game_flow != null and not _game_flow.input_device_changed.is_connected(_on_input_device_changed):
		_game_flow.input_device_changed.connect(_on_input_device_changed)
	if _game_flow != null and not _game_flow.keybinds_changed.is_connected(_on_keybinds_changed):
		_game_flow.keybinds_changed.connect(_on_keybinds_changed)
	_refresh_prompt()
	var glow := get_node_or_null("Glow") as Polygon2D
	if glow != null:
		var tween := create_tween().set_loops()
		tween.tween_property(glow, "modulate:a", 0.45, 1.4).set_trans(Tween.TRANS_SINE)
		tween.tween_property(glow, "modulate:a", 1.0, 1.4).set_trans(Tween.TRANS_SINE)


func _refresh_prompt() -> void:
	if prompt_label == null:
		return
	var key := _game_flow.prompt_label(&"interact") if _game_flow != null else "E"
	prompt_label.text = "按 %s 出发" % key


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_prompt()


func _on_keybinds_changed() -> void:
	_refresh_prompt()


func is_player_near(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius


func set_player_near(near: bool) -> void:
	if prompt_label != null:
		prompt_label.visible = near


func activate() -> void:
	activated.emit()
