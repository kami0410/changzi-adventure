class_name MovingPlatform
extends AnimatableBody2D

## Elevator / moving platform for the big-map chapters (2–4).
##
## [member travel] is the offset from the authored position, so the same node
## covers a vertical elevator (0, -160), a horizontal ferry (240, 0) or a
## diagonal lift. [member speed] is px/s and the platform pauses at both ends.
## It is an [AnimatableBody2D] with `sync_to_physics`, so a player standing on
## it is carried by the existing CharacterBody2D platform logic without a new
## controller.
##
## The travelled rectangle is clamped to the room union [MDSBigRoom] resolves
## from MDS (which is also what the camera limits use). An authored platform can
## never leave the playfield even if its travel is set too far.
##
## Authored as a direct child of an [MDSBigRoom]. The node origin is the
## top-left corner of the walkable surface.

const GROUP := &"moving_platforms"

@export var size: Vector2 = Vector2(128, 16)
## Offset from the authored position to the far end of the route.
@export var travel: Vector2 = Vector2(0, -160)
@export var speed: float = 80.0
@export var pause_time: float = 0.6
@export var start_delay: float = 0.0
## Back-and-forth (true) or a one-way loop that snaps back (false).
@export var ping_pong: bool = true
## Explicit room union for standalone tests; empty uses the ancestor MDSBigRoom.
@export var room_bounds: Rect2 = Rect2()
@export var color: Color = Color("183039")
@export var edge_color: Color = Color("74b3a7")

## Travel after clamping to [member room_bounds].
var effective_travel := Vector2.ZERO
var travel_clamped := false
var bounds_resolved := false
## True when the authored home rectangle itself is outside the union.
var outside_bounds := false

var _home := Vector2.ZERO
var _time := 0.0
var _shape: CollisionShape2D


func _init() -> void:
	sync_to_physics = true


func _ready() -> void:
	build()


func _physics_process(delta: float) -> void:
	if not bounds_resolved:
		resolve_bounds()
	_time += delta
	position = position_at_time(_time)


## Builds the collision shape and resolves the route. Safe to call before the
## node enters the tree.
func build() -> void:
	if not is_in_group(GROUP):
		add_to_group(GROUP)
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
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
	_home = position
	resolve_bounds()
	queue_redraw()


## Called by [MDSBigRoom] once it has resolved the room union, so children that
## ran `_ready` before their parent still get the exact bounds.
func set_room_bounds(bounds: Rect2) -> void:
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return
	room_bounds = bounds
	bounds_resolved = true
	_clamp_travel()


## Resolves bounds from an explicit override, the ancestor [MDSBigRoom] or the
## ancestor [MDSWorldGame] (in that order).
func resolve_bounds() -> void:
	if room_bounds.size.x > 0.0 and room_bounds.size.y > 0.0:
		bounds_resolved = true
		_clamp_travel()
		return
	var node := get_parent()
	while node != null:
		if node is MDSBigRoom and (node as MDSBigRoom).room_bounds.size.x > 0.0:
			set_room_bounds((node as MDSBigRoom).room_bounds)
			return
		node = node.get_parent()
	# Outside an MDS room (unit tests, greybox scenes): keep the authored
	# travel unclamped rather than blocking the platform.
	bounds_resolved = false
	travel_clamped = false
	outside_bounds = false
	effective_travel = travel


## Restarts the route from the authored end after [param delay] seconds.
func restart(delay: float = 0.0) -> void:
	_time = 0.0
	start_delay = maxf(delay, 0.0)
	position = _home


## Re-reads the authored position. Call after moving the node in tests.
func recapture_home() -> void:
	_home = position
	if room_bounds.size.x > 0.0 and room_bounds.size.y > 0.0:
		bounds_resolved = true
	_clamp_travel()
	queue_redraw()


## Position for [param t] seconds into the loop. Public for deterministic tests.
func position_at_time(t: float) -> Vector2:
	return _home + effective_travel * progress_at(t)


## Normalised route progress (0 at the authored end, 1 at [member travel]).
func progress_at(t: float) -> float:
	var distance := effective_travel.length()
	if distance <= 0.01:
		return 0.0
	var leg := distance / maxf(speed, 1.0)
	if leg <= 0.0:
		return 0.0
	var pause := maxf(pause_time, 0.0)
	var local := maxf(t - start_delay, 0.0)
	var phase := 0.0
	if ping_pong:
		phase = fmod(local, 2.0 * (leg + pause))
		if phase <= pause:
			return 0.0
		if phase <= pause + leg:
			return _smoothstep((phase - pause) / leg)
		if phase <= 2.0 * pause + leg:
			return 1.0
		return 1.0 - _smoothstep((phase - 2.0 * pause - leg) / leg)
	phase = fmod(local, leg + pause)
	if phase <= pause:
		return 0.0
	return _smoothstep((phase - pause) / leg)


func collision_shape() -> CollisionShape2D:
	return _shape


## Current world-space rectangle, for bounds assertions.
func platform_rect() -> Rect2:
	return Rect2(position, Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0)))


func _clamp_travel() -> void:
	if room_bounds.size.x <= 0.0 or room_bounds.size.y <= 0.0:
		effective_travel = travel
		travel_clamped = false
		outside_bounds = false
		return
	var min_x := room_bounds.position.x - _home.x
	var max_x := room_bounds.end.x - (_home.x + maxf(size.x, 1.0))
	var min_y := room_bounds.position.y - _home.y
	var max_y := room_bounds.end.y - (_home.y + maxf(size.y, 1.0))
	if min_x > 0.0 or max_x < 0.0 or min_y > 0.0 or max_y < 0.0:
		# The authored home rectangle itself is not fully inside the union:
		# stay put so the platform can never sit outside the camera limits.
		outside_bounds = true
		travel_clamped = true
		effective_travel = Vector2.ZERO
		return
	outside_bounds = false
	var clamped := Vector2(clampf(travel.x, min_x, max_x), clampf(travel.y, min_y, max_y))
	travel_clamped = not clamped.is_equal_approx(travel)
	effective_travel = clamped


func _smoothstep(value: float) -> float:
	var x := clampf(value, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0)))
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, minf(4.0, rect.size.y))), edge_color)
	# End markers make the route readable while authoring; both stay inside the
	# clamped travel, so the marker cannot point outside the room.
	var near := rect.get_center()
	var far := near + effective_travel
	draw_circle(near, 2.0, Color(edge_color, 0.7))
	draw_circle(far, 2.0, Color(edge_color, 0.7))
	draw_line(near, far, Color(edge_color, 0.22), 1.0)
