class_name CollapsingPlatform
extends StaticBody2D

## GDD Chapter 2 mechanic: a platform that warns, then falls away.
##
## Standing on it starts a readable warning (colour shift + shake), then the
## collision is switched off, the platform drops out of view and it restores
## after [member respawn_time]. game.gd also resets every platform in the
## `collapsing_platforms` group when the fall guard or a death would send the
## player back to a checkpoint, so a checkpoint cannot strand the player over a
## hole that is still marked as collapsing.
##
## Like [OneWayPlatform], the node origin is the top-left corner of the
## walkable surface and it is authored as a child of an [MDSBigRoom].

signal collapsed(platform: CollapsingPlatform)
signal restored(platform: CollapsingPlatform)

const GROUP := &"collapsing_platforms"

enum State { IDLE, WARNING, FALLING, GONE }

@export var size: Vector2 = Vector2(128, 16)
@export var warn_time: float = 0.6
@export var fall_time: float = 0.35
## Time the platform stays gone; the player is expected to have moved on.
@export var respawn_time: float = 2.5
## How far the visual drops while it falls.
@export var fall_depth: float = 160.0
@export var color: Color = Color("183039")
@export var edge_color: Color = Color("74b3a7")
@export var warning_color: Color = Color("d8765a")
## Chapter terrain atlas; set by MDSBigRoom so the plank matches the tiles.
var tile_texture: Texture2D

var state: State = State.IDLE

var _timer := 0.0
var _progress := 0.0
var _warning_t := 0.0
var _elapsed := 0.0
var _solid := true
var _standing := 0
var _visual_offset := Vector2.ZERO
var _shape: CollisionShape2D
var _stand_area: Area2D


func _ready() -> void:
	build()


## Builds the collision body, the stand detector and the visual state. Safe to
## call before the node enters the tree for unit tests.
func build() -> void:
	if not is_in_group(GROUP):
		add_to_group(GROUP)
	collision_layer = 1
	collision_mask = 0
	if _shape == null:
		_shape = get_node_or_null("Shape") as CollisionShape2D
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = "Shape"
		add_child(_shape)
	var box := RectangleShape2D.new()
	box.size = Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
	_shape.shape = box
	_shape.position = box.size * 0.5
	# Jump-through like every other ledge (1.0.1): bodies pass from below, so
	# an enemy walking under a low ledge is never wedged against it.
	_shape.one_way_collision = true
	_shape.one_way_collision_margin = 2.0
	if _stand_area == null:
		_stand_area = get_node_or_null("StandArea") as Area2D
	if _stand_area == null:
		_stand_area = Area2D.new()
		_stand_area.name = "StandArea"
		_stand_area.collision_layer = 0
		_stand_area.collision_mask = 1
		add_child(_stand_area)
	if _stand_area.get_child_count() == 0:
		var stand_shape := CollisionShape2D.new()
		stand_shape.name = "Shape"
		var stand_box := RectangleShape2D.new()
		# Sits just above the top face so only a body standing on the platform
		# overlaps it. Enemies are on layer 2 and never trigger the warning.
		stand_box.size = Vector2(box.size.x, 16.0)
		stand_shape.shape = stand_box
		stand_shape.position = Vector2(box.size.x * 0.5, -6.0)
		_stand_area.add_child(stand_shape)
	if not _stand_area.body_entered.is_connected(_on_body_entered):
		_stand_area.body_entered.connect(_on_body_entered)
	if not _stand_area.body_exited.is_connected(_on_body_exited):
		_stand_area.body_exited.connect(_on_body_exited)
	_apply_collision()
	queue_redraw()


func _physics_process(delta: float) -> void:
	advance(delta)


## Steps the warning/fall/respawn state. Public so unit tests can drive it
## deterministically without a physics server.
func advance(delta: float) -> void:
	_elapsed += delta
	match state:
		State.WARNING:
			_timer -= delta
			_warning_t = clampf(1.0 - _timer / maxf(warn_time, 0.001), 0.0, 1.0)
			_visual_offset = Vector2(sin(_elapsed * 62.0) * 3.0 * (0.35 + _warning_t), 0.0)
			queue_redraw()
			if _timer <= 0.0:
				_start_fall()
		State.FALLING:
			_timer -= delta
			_progress = clampf(1.0 - _timer / maxf(fall_time, 0.001), 0.0, 1.0)
			_visual_offset = Vector2(0.0, fall_depth * _progress)
			queue_redraw()
			if _timer <= 0.0:
				_start_gone()
		State.GONE:
			_timer -= delta
			if _timer <= 0.0:
				reset_now()


## Called when a player body starts or stops standing on the platform.
func notify_player_standing(standing: bool) -> void:
	if standing and state == State.IDLE:
		_start_warning()


## Restores the platform immediately. Used by the death/fall respawn path and
## by room reloads.
func reset_now() -> void:
	state = State.IDLE
	_timer = 0.0
	_progress = 0.0
	_warning_t = 0.0
	_visual_offset = Vector2.ZERO
	_solid = true
	visible = true
	_apply_collision()
	queue_redraw()
	restored.emit(self)


func is_solid() -> bool:
	return _solid


func is_warning() -> bool:
	return state == State.WARNING


func has_collapsed() -> bool:
	return state == State.FALLING or state == State.GONE


func warning_progress() -> float:
	return _warning_t


func visual_offset() -> Vector2:
	return _visual_offset


func collision_shape() -> CollisionShape2D:
	return _shape


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	_standing += 1
	notify_player_standing(true)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	_standing = maxi(_standing - 1, 0)
	notify_player_standing(false)


func _start_warning() -> void:
	state = State.WARNING
	_timer = maxf(warn_time, 0.001)
	_warning_t = 0.0
	_elapsed = 0.0


func _start_fall() -> void:
	state = State.FALLING
	_timer = maxf(fall_time, 0.001)
	_progress = 0.0
	_warning_t = 1.0
	_solid = false
	_apply_collision()
	collapsed.emit(self)


func _start_gone() -> void:
	state = State.GONE
	_timer = maxf(respawn_time, 0.001)
	visible = false
	queue_redraw()


func _apply_collision() -> void:
	if _shape == null:
		return
	if is_inside_tree():
		_shape.set_deferred(&"disabled", not _solid)
	else:
		_shape.disabled = not _solid


func _draw() -> void:
	var body := Color(color).lerp(warning_color, _warning_t) if state == State.WARNING else color
	var alpha := 1.0
	if state == State.FALLING:
		alpha = clampf(1.0 - _progress * 0.85, 0.0, 1.0)
	body.a *= alpha
	var rect := Rect2(_visual_offset, Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0)))
	if tile_texture != null:
		# Rotten planks: the chapter tile, slightly warm, reddening as it warns.
		var tint := Color(1.0, 0.86, 0.72, alpha)
		if state == State.WARNING:
			tint = tint.lerp(Color(1.6, 0.8, 0.6, alpha), _warning_t)
		TileVariants.draw_platform_strip(self, tile_texture, Rect2(Vector2.ZERO, rect.size), tint, _visual_offset)
	else:
		draw_rect(rect, body)
		var edge := Color(edge_color, alpha)
		if state == State.WARNING:
			edge = Color(warning_color.lightened(0.25), alpha)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, minf(4.0, rect.size.y))), edge)
	if state != State.WARNING:
		return
	# Crack marks grow with the warning so the collapse is readable even
	# without colour.
	var cracks := 1 + int(_warning_t * 3.0)
	for index in cracks:
		var x := rect.position.x + rect.size.x * (0.2 + 0.22 * index)
		draw_line(Vector2(x, rect.position.y + 2.0), Vector2(x + 6.0, rect.end.y - 2.0),
			Color(0.12, 0.1, 0.09, 0.7 * alpha), 1.0)
