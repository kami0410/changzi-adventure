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
const HUD_THEME := preload("res://resources/ui/hud_theme.tres")

## Emitted when a called elevator stops at either end (0 = home, 1 = far).
signal arrived(stop: int)

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
@export_group("Call mode")
## Called elevator: rests at a stop until the player calls it from a panel at
## either end, or presses interact while riding. The auto loop above is only
## used when this is off (ferries, decorative lifts).
@export var call_mode: bool = false
@export var call_speed: float = 320.0
@export var call_accel: float = 700.0
## How close (px, horizontal) the player must be to a call panel.
@export var panel_radius: float = 80.0
## Panel offset: negative x puts it left of the car, positive x right of it.
@export var panel_offset: Vector2 = Vector2(-36, 0)

## Chapter terrain atlas for non-elevator platforms (set by MDSBigRoom).
var tile_texture: Texture2D

## Travel after clamping to [member room_bounds].
var effective_travel := Vector2.ZERO
var travel_clamped := false
var bounds_resolved := false
## True when the authored home rectangle itself is outside the union.
var outside_bounds := false

var _home := Vector2.ZERO
var _time := 0.0
var _shape: CollisionShape2D
## Call mode state: route progress 0..1, the stop it is heading for, speed.
var progress := 0.0
var target_stop := 0
var _call_velocity := 0.0
var _rider := false
var _near_stop := -1
var _prompt: Label
var _panel_prompts: Array[Label] = []
## Local x of each stop's call panel; NAN = no floor beside that stop.
var _panel_x: Array[float] = [NAN, NAN]
var _surfaces_known := false


func _init() -> void:
	sync_to_physics = true


func _ready() -> void:
	build()


func _physics_process(delta: float) -> void:
	if not bounds_resolved:
		resolve_bounds()
	_time += delta
	if call_mode:
		step_called(delta)
		queue_redraw()
		return
	position = position_at_time(_time)


## True while a called elevator is travelling.
func is_moving() -> bool:
	return call_mode and not is_equal_approx(progress, float(target_stop))


## Sends a called elevator to [param stop] (0 = home, 1 = far end). Returns
## false when it is already resting there.
func call_to(stop: int) -> bool:
	stop = clampi(stop, 0, 1)
	if target_stop == stop and is_equal_approx(progress, float(stop)):
		return false
	if target_stop != stop:
		_call_velocity = 0.0
	target_stop = stop
	_play_sfx(&"elevator_call")
	return true


## Global feet position of a stop's call panel.
func panel_position(stop: int) -> Vector2:
	var parent_xform := (get_parent() as Node2D).global_transform if get_parent() is Node2D else Transform2D.IDENTITY
	return parent_xform * panel_local(stop)


## Panel feet position in the parent's space.
func panel_local(stop: int) -> Vector2:
	stop = clampi(stop, 0, 1)
	var at := _home + effective_travel * float(stop)
	if _surfaces_known and not is_nan(_panel_x[stop]):
		return at + Vector2(_panel_x[stop], panel_offset.y)
	return at + _panel_local_offset()


func _panel_local_offset() -> Vector2:
	if panel_offset.x >= 0.0:
		return Vector2(maxf(size.x, 1.0) + panel_offset.x, panel_offset.y)
	return panel_offset


## True when [param stop] has a call panel. Without surface data (unit tests,
## greybox) both stops get the authored offset.
func has_panel(stop: int) -> bool:
	if not _surfaces_known:
		return true
	return not is_nan(_panel_x[clampi(stop, 0, 1)])


## [MDSBigRoom] hands over every walkable surface; each stop gets a panel on
## the nearest floor that is level with it and touches the shaft.
func set_surfaces(surfaces: Array[Rect2]) -> void:
	_surfaces_known = true
	var car := maxf(size.x, 1.0)
	for stop in 2:
		_panel_x[stop] = NAN
		var at := _home + effective_travel * float(stop)
		var best := INF
		for rect in surfaces:
			if absf(rect.position.y - at.y) > 8.0:
				continue
			# Left side: the surface reaches the shaft's left edge.
			if rect.position.x < at.x - 20.0 and rect.end.x >= at.x - 24.0:
				var x := clampf(at.x - 36.0, rect.position.x + 12.0, rect.end.x - 12.0)
				if absf(x - at.x) < best:
					best = absf(x - at.x)
					_panel_x[stop] = x - at.x
			# Right side.
			if rect.end.x > at.x + car + 20.0 and rect.position.x <= at.x + car + 24.0:
				var x := clampf(at.x + car + 36.0, rect.position.x + 12.0, rect.end.x - 12.0)
				if absf(x - (at.x + car)) < best:
					best = absf(x - (at.x + car))
					_panel_x[stop] = x - at.x
	if _prompt != null:
		_refresh_prompts()
	queue_redraw()


## True when a player whose feet are at [param feet] (global) stands on top.
func is_rider(feet: Vector2) -> bool:
	var origin := global_position if is_inside_tree() else position
	var rect := Rect2(origin, Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0)))
	return feet.x >= rect.position.x - 6.0 and feet.x <= rect.end.x + 6.0 \
			and absf(feet.y - rect.position.y) <= 14.0


## Which panel the player can use (-1 for none).
func stop_near(feet: Vector2) -> int:
	for stop in 2:
		if not has_panel(stop):
			continue
		var panel := panel_position(stop) if is_inside_tree() else panel_local(stop)
		if absf(feet.x - panel.x) <= panel_radius and absf(feet.y - panel.y) <= 48.0:
			return stop
	return -1


## Interact pressed: a rider sends it to the other end, a player at a panel
## calls it to that stop. Returns true when the press was used.
func try_interact(feet: Vector2) -> bool:
	if not call_mode or effective_travel.length() <= 0.01:
		return false
	if is_rider(feet):
		if is_moving():
			call_to(1 - target_stop)
		else:
			call_to(0 if progress >= 0.5 else 1)
		return true
	var stop := stop_near(feet)
	if stop < 0:
		return false
	if not call_to(stop):
		_play_sfx(&"ui_click")
	return true


## game.gd feeds the player's feet every frame so prompts follow the player.
func update_player(feet: Vector2) -> void:
	if not call_mode:
		return
	_rider = is_rider(feet)
	_near_stop = -1 if _rider else stop_near(feet)
	_refresh_prompts()


## Advances a called elevator. Public so tests can step it deterministically.
func step_called(delta: float) -> void:
	var distance := effective_travel.length()
	if distance <= 0.01:
		progress = 0.0
		position = _home
		return
	var goal := float(target_stop)
	var remaining := absf(goal - progress) * distance
	if remaining <= 0.5:
		if not is_equal_approx(progress, goal):
			progress = goal
			_call_velocity = 0.0
			_play_sfx(&"elevator_call")
			arrived.emit(target_stop)
		position = _home + effective_travel * progress
		return
	# Accelerate from rest, cruise, then brake so the stop lands softly.
	var desired := minf(call_speed, sqrt(2.0 * call_accel * remaining) + 24.0)
	_call_velocity = move_toward(_call_velocity, desired, call_accel * delta)
	var step := minf(_call_velocity * delta, remaining) / distance
	progress = move_toward(progress, goal, step)
	position = _home + effective_travel * progress


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
	if call_mode:
		_build_prompts()
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
	progress = 0.0
	target_stop = 0
	_call_velocity = 0.0
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


func _build_prompts() -> void:
	if _prompt != null:
		return
	_prompt = _make_label("Prompt")
	add_child(_prompt)
	for stop in 2:
		var label := _make_label("PanelPrompt%d" % stop)
		# Panels stay put while the car moves, so their prompts ignore the
		# platform transform.
		label.top_level = true
		add_child(label)
		_panel_prompts.append(label)
	_refresh_prompts()


func _make_label(label_name: String) -> Label:
	var label := Label.new()
	label.name = label_name
	label.visible = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme = HUD_THEME
	label.add_theme_color_override("font_color", Color("e6c87a"))
	label.add_theme_font_size_override("font_size", 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(200, 24)
	return label


func prompt_label() -> Label:
	return _prompt


func panel_prompt(stop: int) -> Label:
	return _panel_prompts[stop] if stop >= 0 and stop < _panel_prompts.size() else null


func _key() -> String:
	if not is_inside_tree():
		return "E"
	var flow := get_node_or_null("/root/Flow") as GameFlow
	return flow.prompt_label(&"interact") if flow != null else "E"


func _refresh_prompts() -> void:
	if _prompt == null:
		return
	var key := _key()
	var far_is_up := effective_travel.y < 0.0
	_prompt.visible = _rider
	if _rider:
		var heading_far := (progress < 0.5) if not is_moving() else (target_stop == 0)
		var up := heading_far == far_is_up
		_prompt.text = "按 %s %s" % [key, "上升" if up else "下降"]
		_prompt.position = Vector2(maxf(size.x, 1.0) * 0.5 - 100.0, -100.0)
	for stop in _panel_prompts.size():
		var label := _panel_prompts[stop]
		label.visible = _near_stop == stop
		if not label.visible:
			continue
		var here := is_equal_approx(progress, float(stop)) and target_stop == stop
		if here:
			label.text = "电梯已到达"
		elif is_moving() and target_stop == stop:
			label.text = "电梯运行中…"
		else:
			label.text = "按 %s 召唤电梯" % key
		var anchor := panel_position(stop) if is_inside_tree() else panel_local(stop)
		label.global_position = anchor + Vector2(-100.0, -96.0)


func _play_sfx(id: StringName) -> void:
	if not is_inside_tree():
		return
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.call("play_sfx", id)


func _smoothstep(value: float) -> float:
	var x := clampf(value, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0)))
	if call_mode:
		_draw_elevator(rect)
		return
	if tile_texture != null:
		TileVariants.draw_platform_strip(self, tile_texture, rect, Color(1.0, 0.95, 0.85))
		# Rig hangers up to the fly loft so the slide reads as stage machinery.
		draw_line(Vector2(8, 0), Vector2(8, -400), Color(0.6, 0.5, 0.4, 0.35), 1.0)
		draw_line(Vector2(rect.size.x - 8, 0), Vector2(rect.size.x - 8, -400), Color(0.6, 0.5, 0.4, 0.35), 1.0)
		return
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, minf(4.0, rect.size.y))), edge_color)
	# End markers make the route readable while authoring; both stay inside the
	# clamped travel, so the marker cannot point outside the room.
	var near := rect.get_center()
	var far := near + effective_travel
	draw_circle(near, 2.0, Color(edge_color, 0.7))
	draw_circle(far, 2.0, Color(edge_color, 0.7))
	draw_line(near, far, Color(edge_color, 0.22), 1.0)


## Called elevator art (art pack): iron guide rails and cable up the shaft,
## the wrought-iron cage car and a brass call panel at both stops (red lamp
## idle, gold while the car is coming). Drawn in the car's local space, so the
## fixed parts subtract the car's current offset.
const LIFT_CAR := preload("res://assets/sprites/props/lift_car.png")
const LIFT_RAIL := preload("res://assets/sprites/props/lift_rail.png")
const LIFT_PANEL_IDLE := preload("res://assets/sprites/props/lift_panel_idle.png")
const LIFT_PANEL_ACTIVE := preload("res://assets/sprites/props/lift_panel_active.png")
## Width of the car art's end caps; the middle stretch repeats.
const CAR_CAP := 40.0


func _draw_elevator(rect: Rect2) -> void:
	var offset := position - _home
	var top_y := -offset.y + minf(effective_travel.y, 0.0)
	var bottom_y := -offset.y + maxf(effective_travel.y, 0.0)
	var w := rect.size.x
	var rail_top := top_y - 72.0
	var rail_bottom := bottom_y + rect.size.y
	for x in [-14.0, w - 2.0]:
		var y := rail_top
		while y < rail_bottom:
			var h := minf(64.0, rail_bottom - y)
			draw_texture_rect_region(LIFT_RAIL, Rect2(Vector2(x, y), Vector2(16, h)), Rect2(0, 0, 16, h), Color(0.85, 0.88, 0.92))
			y += 64.0
	var mid := w * 0.5
	draw_line(Vector2(mid, top_y - 64.0), Vector2(mid, -46.0), Color(0.55, 0.6, 0.55, 0.6), 2.0)
	draw_circle(Vector2(mid, top_y - 68.0), 9.0, Color("1b262a"))
	draw_arc(Vector2(mid, top_y - 68.0), 9.0, 0.0, TAU, 16, Color(edge_color, 0.5), 2.0)
	# The car art's floor is its bottom 16 px; it sits on the collision rect.
	var car_top := rect.size.y - 64.0
	var tex_w := float(LIFT_CAR.get_width())
	draw_texture_rect_region(LIFT_CAR, Rect2(Vector2(0, car_top), Vector2(CAR_CAP, 64)), Rect2(0, 0, CAR_CAP, 64))
	var x := CAR_CAP
	var mid_src := tex_w - CAR_CAP * 2.0
	while x < w - CAR_CAP:
		var seg := minf(mid_src, w - CAR_CAP - x)
		draw_texture_rect_region(LIFT_CAR, Rect2(Vector2(x, car_top), Vector2(seg, 64)), Rect2(CAR_CAP, 0, seg, 64))
		x += seg
	draw_texture_rect_region(LIFT_CAR, Rect2(Vector2(w - CAR_CAP, car_top), Vector2(CAR_CAP, 64)), Rect2(tex_w - CAR_CAP, 0, CAR_CAP, 64))
	var moving := is_moving()
	var lamp := Color("f3cf87") if moving else Color("8fe8a8")
	var pulse := 0.6 + 0.4 * sin(_time * 8.0) if moving else 1.0
	draw_circle(Vector2(mid, car_top + 10.0), 3.0, Color(lamp, pulse))
	draw_circle(Vector2(mid, car_top + 10.0), 9.0, Color(lamp, 0.2 * pulse))
	for stop in 2:
		if has_panel(stop):
			_draw_panel(panel_local(stop) - position, stop)


func _draw_panel(feet: Vector2, stop: int) -> void:
	var here := is_equal_approx(progress, float(stop)) and not is_moving()
	var coming := is_moving() and target_stop == stop
	var art := LIFT_PANEL_ACTIVE if coming else LIFT_PANEL_IDLE
	var glow := 0.75 + 0.25 * sin(_time * 9.0) if coming else 1.0
	draw_texture(art, feet + Vector2(-16, -72), Color(glow, glow, glow))
	var lamp_at := feet + Vector2(0, -60)
	if here:
		draw_circle(lamp_at, 5.0, Color("8fe8a8", 0.85))
	if _near_stop == stop:
		var light := Color("f3cf87") if coming else (Color("8fe8a8") if here else Color("c86b5a"))
		draw_circle(lamp_at, 13.0, Color(light, 0.22))
	# The bottom panel's arrow points up, the top one down.
	var stop_is_top := (stop == 1) == (effective_travel.y < 0.0)
	var dir := 1.0 if stop_is_top else -1.0
	var tip := feet + Vector2(0, -86.0 if not stop_is_top else -78.0)
	tip.y += 0.0
	var a := tip + Vector2(-5, -dir * 6.0)
	var b := tip + Vector2(5, -dir * 6.0)
	draw_colored_polygon(PackedVector2Array([tip, a, b]), Color(edge_color, 0.75))
