class_name Pickup
extends Area2D

signal collected(kind: StringName, resource: Resource)

@export var kind: StringName = &"word"
@export var resource: Resource
@export var label_text: String = ""

var _collected := false
var _player_near := false

@onready var label: Label = get_node_or_null("Label") as Label
@onready var visual: Polygon2D = get_node_or_null("Visual") as Polygon2D


func _ready() -> void:
	add_to_group(&"pickups")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if label != null:
		label.text = label_text
	if visual != null:
		visual.color = _kind_color()
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 6.0, 0.7).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y, 0.7).set_trans(Tween.TRANS_SINE)


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
	label.text = ("E 拾取 · " + label_text) if _player_near else label_text


func _kind_color() -> Color:
	match kind:
		&"weapon":
			return Color(0.92, 0.36, 0.3, 1.0)
		&"relic":
			return Color(0.66, 0.46, 0.92, 1.0)
		_:
			return Color(0.3, 0.86, 0.76, 1.0)
