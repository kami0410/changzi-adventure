class_name Pickup
extends Area2D

signal collected(kind: StringName, resource: Resource)

@export var kind: StringName = &"word"
@export var resource: Resource
@export var label_text: String = ""

var _collected := false
var _player_near := false
## Resolved from the tree instead of the `Flow` global so scripts precompiled
## by a `-s` test runner do not depend on autoload registration order.
var _game_flow: GameFlow

@onready var label: Label = get_node_or_null("Label") as Label
@onready var visual: Polygon2D = get_node_or_null("Visual") as Polygon2D


func _ready() -> void:
	add_to_group(&"pickups")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_game_flow = get_node_or_null("/root/Flow") as GameFlow
	if _game_flow != null and not _game_flow.input_device_changed.is_connected(_on_input_device_changed):
		_game_flow.input_device_changed.connect(_on_input_device_changed)
	if _game_flow != null and not _game_flow.keybinds_changed.is_connected(_on_keybinds_changed):
		_game_flow.keybinds_changed.connect(_on_keybinds_changed)
	_refresh_label()
	if visual != null:
		visual.color = _kind_color()
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 6.0, 0.7).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y, 0.7).set_trans(Tween.TRANS_SINE)


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_label()


func _on_keybinds_changed() -> void:
	_refresh_label()


func _on_body_entered(body: Node) -> void:
	if _collected or body == null or not body.is_in_group("player"):
		return
	_player_near = true
	_refresh_label()


func _on_body_exited(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	_player_near = false
	_refresh_label()


## Walk-up pickups are collected with E, never by touching them: a dropped
## weapon must not swap itself while the player is walking past.
func can_collect() -> bool:
	return not _collected and _player_near


func try_collect() -> bool:
	if not can_collect():
		return false
	_collected = true
	collected.emit(kind, resource)
	queue_free()
	return true


func _refresh_label() -> void:
	if label == null:
		return
	if _player_near:
		var action := _game_flow.prompt_label(&"interact") if _game_flow != null else "E"
		label.text = "%s 拾取 · %s" % [action, label_text]
	else:
		label.text = label_text


func _kind_color() -> Color:
	match kind:
		&"weapon":
			return Color(0.92, 0.36, 0.3, 1.0)
		&"relic":
			return Color(0.66, 0.46, 0.92, 1.0)
		_:
			return Color(0.3, 0.86, 0.76, 1.0)
