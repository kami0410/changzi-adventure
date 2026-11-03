class_name InkWarning
extends Node2D

## Ground-rectangle warning: the shape itself marks the danger.
const SHAPE := DangerShape.GROUND

var damage := 10
var delay := 0.75
var width := 38.0
var _time := 0.0
var _struck := false

static func create(host: Node, point: Vector2, amount: int) -> void:
	var warning := InkWarning.new()
	warning.damage = amount
	host.add_child(warning)
	warning.global_position = point

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("hostile_hazards")
	z_index = 4

func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= delay and not _struck:
		_struck = true
		for target in get_tree().get_nodes_in_group("player"):
			if absf(target.global_position.x - global_position.x) < width and absf(target.global_position.y - global_position.y) < 160:
				target.take_damage(damage)
		CombatFX.spawn(get_parent(), global_position, &"hit", Color("eb8f96"), 1.0, 50)
	if _time > delay + 0.2:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var progress := clampf(_time / delay, 0, 1)
	draw_rect(Rect2(-width, 10, width * 2, 4), Color("f5ab7f"))
	draw_rect(Rect2(-width * progress, 6, width * 2 * progress, 5), Color("fbe5ac"))
	if not _struck:
		draw_line(Vector2.ZERO, Vector2(0, -260), Color(0.9, 0.3, 0.4, 0.18), 2)
	else:
		draw_rect(Rect2(-width * 0.7, -300, width * 1.4, 315), Color(0.8, 0.18, 0.32, 0.55))
