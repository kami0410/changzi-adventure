class_name ActorMotion
extends Node2D

## Procedural motion for single-texture pixel-art actors.
## The source sprite is hidden and redrawn whole, transformed around its feet:
## spring squash & stretch, lean, bob, anticipation, recoil and death collapse,
## plus drawn secondary motion (tails, wings, tendrils, cast orbits). The sprite
## is never cut into pieces, and the pixel shader keeps texels even at any
## scale or angle, so the art stays crisp. The feet stay on the shadow.

enum Style { HUMANOID, BEAST, FLYER, ELITE, BLOB }

var sprite: Sprite2D
var style: Style = Style.HUMANOID
var gait: StringName = &"idle"
var direction := 1.0
var accent := Color("9fe8dc")

var _time := 0.0
var _action: StringName = &""
var _action_left := 0.0
var _action_duration := 0.25
var _base_scale := Vector2.ONE
var _base_offset := Vector2.ZERO
## Width of the first (idle) texture. Frame sets with a sword or a wide lunge
## must not stretch the contact shadow every time the pose changes.
var _shadow_width := 0.0
var _death_finished := false

var _squash := Vector2.ONE
var _squash_velocity := Vector2.ZERO
var _lean := 0.0
var _lean_velocity := 0.0
var _bob := 0.0
var _bob_velocity := 0.0
var _tail := 0.0
var _tail_velocity := 0.0
var _stride := 0.0
var _step_phase := 0.0
var _last_run_phase := 0.0
var _land_pulse := 0.0
var _cast_orbit := 0.0


func bind(visual: Sprite2D, has_legs: bool = true) -> void:
	sprite = visual
	style = Style.HUMANOID if has_legs else Style.BEAST
	_base_scale = sprite.scale
	_base_offset = sprite.offset
	_shadow_width = float(PixelSprite.opaque_rect(sprite.texture).size.x) if sprite.texture != null else 0.0
	sprite.visible = false
	PixelSprite.apply_material(self)


func set_style(next_style: Style) -> void:
	style = next_style


## The action currently being played, or &"" when the spring has settled.
func current_action() -> StringName:
	return _action if _action_left > 0.0 else &""


## How far the current action has played, 0 at the start and 1 at the end.
func action_progress() -> float:
	if _action_left <= 0.0:
		return 1.0
	return clampf(1.0 - _action_left / _action_duration, 0.0, 1.0)


func play(action: StringName, duration: float = 0.25) -> void:
	_action = action
	_death_finished = false
	_action_duration = maxf(duration, 0.01)
	_action_left = _action_duration
	if action == &"land":
		_land_pulse = 1.0
		_squash = Vector2(1.18, 0.82)
		_squash_velocity = Vector2.ZERO
	elif action == &"attack":
		_squash = Vector2(1.08, 0.94)
	elif action == &"hit":
		_squash = Vector2(1.14, 0.88)
		_lean_velocity += -direction * 2.2


func _process(delta: float) -> void:
	_time += delta
	_action_left = maxf(_action_left - delta, 0.0)
	if _action == &"death" and _action_left <= 0:
		_death_finished = true
	_update_springs(delta)
	queue_redraw()


func _update_springs(delta: float) -> void:
	# A long frame (texture upload, room load, alt-tab) used to make the
	# explicit springs explode. Clamp the step and the results.
	delta = minf(delta, 1.0 / 30.0)
	var action_progress := 1.0 - _action_left / _action_duration if _action_left > 0.0 else 1.0
	var run_speed := 15.0 if gait == &"run" else 1.0
	_step_phase += delta * run_speed * (1.0 if gait == &"run" else 0.0)
	_stride = sin(_step_phase) if gait == &"run" else 0.0

	var squash_target := Vector2.ONE
	var lean_target := direction * (0.075 if gait == &"run" else 0.0)
	var bob_target := sin(_time * 2.1) * 0.7
	var tail_target := sin(_time * 2.6) * 0.12
	match gait:
		&"run":
			squash_target = Vector2(1.0 + absf(_stride) * 0.035, 1.0 - absf(_stride) * 0.025)
			bob_target = -absf(_stride) * 3.4
			tail_target = -direction * (0.26 + _stride * 0.12)
		&"jump":
			squash_target = Vector2(0.93, 1.07)
			bob_target = 1.0
			tail_target = direction * 0.2
		&"fall":
			squash_target = Vector2(1.045, 0.965)
			bob_target = -0.5
			tail_target = -direction * 0.16

	if _action_left > 0.0:
		var p := clampf(action_progress, 0.0, 1.0)
		match _action:
			&"windup":
				squash_target = Vector2(1.07, 0.9)
				lean_target = -direction * (0.12 + sin(p * PI) * 0.05)
				bob_target = -2.0
				tail_target = -direction * 0.32
			&"attack":
				var swing := sin(p * PI)
				squash_target = Vector2(1.06 - swing * 0.04, 0.94 + swing * 0.06)
				lean_target = direction * (0.08 + swing * 0.28)
				bob_target = -swing * 4.0
				tail_target = direction * 0.45
			&"slam":
				squash_target = Vector2(1.02 + sin(p * PI) * 0.16, 0.92 - sin(p * PI) * 0.12)
				lean_target = direction * 0.12
				bob_target = sin(p * PI) * 5.0
			&"cast":
				squash_target = Vector2(0.98, 1.04)
				lean_target = -direction * 0.16
				bob_target = -sin(p * PI) * 7.0
				tail_target = direction * 0.24
			&"hit":
				squash_target = Vector2(1.13, 0.88)
				lean_target = -direction * (0.22 + (1.0 - p) * 0.18)
				bob_target = -1.0
				tail_target = -direction * 0.4
			&"land":
				squash_target = Vector2(1.0 + (1.0 - p) * 0.16, 1.0 - (1.0 - p) * 0.15)
				bob_target = (1.0 - p) * 3.0
			&"roll":
				squash_target = Vector2(0.94, 0.9)
				lean_target = 0.0
				bob_target = 0.0
				tail_target = -direction * 0.5
			&"dodge":
				squash_target = Vector2(1.18, 0.82)
				lean_target = direction * p * TAU
				bob_target = -4.0
			&"death":
				squash_target = Vector2(1.0 + p * 0.15, 1.0 - p * 0.55)
				lean_target = direction * p * 1.35
				bob_target = p * 8.0
				tail_target = direction * p * 0.8

	# Critically-damped-ish springs: fast anticipation, soft settle.
	_squash = _spring_vec2(_squash, squash_target, _squash_velocity, delta, 150.0, 18.0)
	_squash = Vector2(clampf(_squash.x, 0.4, 2.0), clampf(_squash.y, 0.4, 2.0))
	_squash_velocity = _last_spring_velocity
	_lean = clampf(_spring_float(_lean, lean_target, _lean_velocity, delta, 170.0, 19.0), -1.2, 1.2)
	_lean_velocity = _last_spring_float_velocity
	_bob = clampf(_spring_float(_bob, bob_target, _bob_velocity, delta, 140.0, 17.0), -12.0, 12.0)
	_bob_velocity = _last_spring_float_velocity
	_tail = clampf(_spring_float(_tail, tail_target, _tail_velocity, delta, 90.0, 12.0), -1.5, 1.5)
	_tail_velocity = _last_spring_float_velocity
	_land_pulse = maxf(_land_pulse - delta * 4.0, 0.0)
	_cast_orbit += delta * (7.0 if _action == &"cast" else 2.0)


var _last_spring_velocity := Vector2.ZERO
var _last_spring_float_velocity := 0.0


func _spring_vec2(current: Vector2, target: Vector2, velocity: Vector2, delta: float, stiffness: float, damping: float) -> Vector2:
	var force := (target - current) * stiffness - velocity * damping
	velocity += force * delta
	_last_spring_velocity = velocity
	return current + velocity * delta


func _spring_float(current: float, target: float, velocity: float, delta: float, stiffness: float, damping: float) -> float:
	var force := (target - current) * stiffness - velocity * damping
	velocity += force * delta
	_last_spring_float_velocity = velocity
	return current + velocity * delta


func _draw() -> void:
	if _death_finished or sprite == null or not is_instance_valid(sprite) or sprite.texture == null:
		return
	var texture := sprite.texture
	var size := texture.get_size()
	var opaque := PixelSprite.opaque_rect(texture)
	# Centre the opaque art on the feet. Frame sets pack poses of different
	# widths into one canvas, so the sprite offset (computed for the idle
	# texture) cannot be trusted to centre a swapped frame.
	var top_left := Vector2(-(float(opaque.position.x) + float(opaque.size.x) * 0.5), sprite.offset.y - size.y * 0.5)
	var foot_texel := top_left.y + float(opaque.end.y)
	var feet := sprite.position + Vector2(0, foot_texel * _base_scale.y)
	var scale := Vector2(direction, 1.0) * _base_scale * _squash
	var color := sprite.modulate
	color.a *= modulate.a
	if _action_left > 0.0:
		var p := clampf(1.0 - _action_left / _action_duration, 0.0, 1.0)
		if _action == &"hit":
			color = color.lerp(Color(2.0, 1.45, 1.3, color.a), (1.0 - p) * 0.8)
		elif _action == &"windup":
			color = color.lerp(Color(1.9, 0.72, 0.35, color.a), 0.35 + 0.2 * sin(_time * 24.0))
		elif _action == &"cast":
			color = color.lerp(Color(1.6, 2.0, 1.8, color.a), 0.35 * (1.0 - p))

	# Grounded actors only rise (bob up), never sink below the floor.
	var lift := _bob if style == Style.FLYER else minf(_bob, 0.0)
	var height := float(opaque.size.y) * _base_scale.y
	var body_width := _shadow_width if _shadow_width > 0.0 else float(opaque.size.x)
	_draw_shadow(feet, body_width * absf(_base_scale.x), lift)
	match style:
		Style.HUMANOID:
			_draw_humanoid(texture, top_left, foot_texel, feet, lift, scale, height, color)
		Style.FLYER:
			_draw_flyer(texture, top_left, foot_texel, feet, lift, scale, height, color)
		Style.ELITE:
			_draw_elite(texture, top_left, foot_texel, feet, lift, scale, height, color)
		Style.BLOB:
			_draw_blob(texture, top_left, foot_texel, feet, lift, scale, height, color)
		_:
			_draw_beast(texture, top_left, foot_texel, feet, lift, scale, height, color)

	_draw_action_extras(feet + Vector2(0, lift), height * _squash.y, color)
	draw_set_transform(Vector2.ZERO)


func _draw_shadow(feet: Vector2, width: float, lift: float) -> void:
	var base_alpha := 0.32
	var radius_x := width * 0.42
	if style == Style.FLYER:
		base_alpha = 0.16
	# Rising shrinks and fades the shadow; it never leaves the floor.
	var away := clampf(-lift / 60.0, 0.0, 1.0)
	base_alpha *= (1.0 - away * 0.6) * clampf(1.0 - _land_pulse * 0.2, 0.1, 1.0)
	radius_x *= (1.0 - away * 0.35) * (1.0 + _land_pulse * 0.15)
	_draw_ellipse(feet + Vector2(0, -1.0), Vector2(radius_x, 4.0 + _land_pulse * 2.0), Color(0.01, 0.02, 0.025, base_alpha))


## Draws the whole sprite with its feet pinned to `feet` (+ `lift`), scaled by
## `scale` (squash included) and rotated by `angle` around the feet.
func _draw_body(texture: Texture2D, top_left: Vector2, foot_texel: float, feet: Vector2, lift: float, scale: Vector2, angle: float, color: Color) -> void:
	draw_set_transform(_snap(feet + Vector2(0, lift)), angle, scale)
	draw_texture_rect(texture, Rect2(top_left - Vector2(0, foot_texel), texture.get_size()), false, color)
	draw_set_transform(Vector2.ZERO)


func _draw_humanoid(texture: Texture2D, top_left: Vector2, foot_texel: float, feet: Vector2, lift: float, scale: Vector2, height: float, color: Color) -> void:
	if _action_left > 0.0 and _action == &"roll":
		_draw_roll(texture, top_left, foot_texel, feet, scale, height, color)
		return
	# A run reads through bob, lean and stride squash; legs are not cut out.
	_draw_body(texture, top_left, foot_texel, feet, lift, scale, _lean * 0.5 + _stride * 0.025, color)
	if gait == &"run" and absf(_stride) > 0.6:
		var dust := feet + Vector2(-direction * 10.0, -2.0)
		draw_circle(dust, 2.0 + absf(_stride), Color(0.6, 0.7, 0.66, 0.18 * color.a))


## Ground roll: the tucked pose spins one full turn around its own centre,
## which sits low so the ball stays on the floor line. Eased so most of the
## turn happens early, matching the roll's speed curve.
func _draw_roll(texture: Texture2D, top_left: Vector2, foot_texel: float, feet: Vector2, scale: Vector2, height: float, color: Color) -> void:
	var p := clampf(1.0 - _action_left / _action_duration, 0.0, 1.0)
	var turn := 1.0 - pow(1.0 - p, 1.8)
	var ball := height * 0.36
	var pivot := feet + Vector2(0, -ball)
	var angle := direction * turn * TAU
	var local_pivot := Vector2(0, -ball / maxf(absf(scale.y), 0.001))
	draw_set_transform(_snap(pivot), angle, scale)
	draw_texture_rect(texture, Rect2(top_left - Vector2(0, foot_texel) - local_pivot, texture.get_size()), false, color)
	draw_set_transform(Vector2.ZERO)
	# Speed arc trailing the ball.
	var trail := Color(accent, color.a * 0.45 * (1.0 - p))
	draw_arc(pivot, ball + 6.0, -direction * PI * 0.5, -direction * PI * 0.5 - direction * PI * 0.9, 12, trail, 3.0)


func _draw_beast(texture: Texture2D, top_left: Vector2, foot_texel: float, feet: Vector2, lift: float, scale: Vector2, height: float, color: Color) -> void:
	var rear := feet + Vector2(-direction * absf(scale.x) * 30.0, lift - height * 0.45)
	var tail_mid := rear + Vector2(-direction * 22.0, -8.0 + sin(_time * 3.0) * 4.0)
	var tail_end := tail_mid + Vector2(-direction * 20.0, 7.0 + sin(_time * 2.3) * 7.0)
	draw_line(rear, tail_mid, Color(0.02, 0.03, 0.04, color.a * 0.75), 6.0)
	draw_line(tail_mid, tail_end, Color(accent.darkened(0.35), color.a * 0.55), 3.0)
	draw_circle(tail_end, 3.0, Color(accent, color.a * 0.7))
	_draw_body(texture, top_left, foot_texel, feet, lift, scale, _lean * 0.6 + _stride * 0.03, color)


func _draw_flyer(texture: Texture2D, top_left: Vector2, foot_texel: float, feet: Vector2, lift: float, scale: Vector2, height: float, color: Color) -> void:
	var hover := lift + sin(_time * 2.2) * 3.0
	var center := feet + Vector2(0, hover - height * 0.5)
	var flap := sin(_time * 9.0) * 0.5
	for side in [-1.0, 1.0]:
		var wing_color := Color(accent.darkened(0.1), color.a * 0.32)
		var wing := PackedVector2Array([
			center,
			center + Vector2(side * 34.0 * absf(scale.x), -18.0 - flap * 20.0),
			center + Vector2(side * 48.0 * absf(scale.x), 2.0 - flap * 10.0),
			center + Vector2(side * 30.0 * absf(scale.x), 18.0 + flap * 8.0),
		])
		draw_colored_polygon(wing, wing_color)
		draw_line(wing[0], wing[2], Color(color.r * 0.7, color.g * 0.9, color.b * 0.9, color.a * 0.45), 2.0)
	_draw_body(texture, top_left, foot_texel, feet, hover, scale, _lean * 0.5 + sin(_time * 2.2) * 0.02, color)
	if gait == &"run":
		for index in 3:
			var trail := center + Vector2(-direction * (20.0 + index * 14.0), sin(_time * 4.0 + index) * 8.0)
			draw_circle(trail, 2.5 - index * 0.4, Color(accent, color.a * (0.34 - index * 0.08)))


func _draw_elite(texture: Texture2D, top_left: Vector2, foot_texel: float, feet: Vector2, lift: float, scale: Vector2, height: float, color: Color) -> void:
	var center := feet + Vector2(0, lift - height * 0.4)
	for index in 4:
		var side := -1.0 if index % 2 == 0 else 1.0
		var sway := sin(_time * 2.0 + index) * 10.0
		var tip := center + Vector2(side * (30.0 + index * 4.0) * absf(scale.x), height * 0.35 + sway)
		draw_line(center, tip, Color(0.015, 0.025, 0.02, color.a * 0.55), 4.0)
		draw_circle(tip, 3.0, Color(accent.darkened(0.2), color.a * 0.5))
	_draw_body(texture, top_left, foot_texel, feet, lift, scale, _lean * 0.35 + sin(_time * 1.3) * 0.01, color)


func _draw_blob(texture: Texture2D, top_left: Vector2, foot_texel: float, feet: Vector2, lift: float, scale: Vector2, height: float, color: Color) -> void:
	var wobble := Vector2(1.0 + sin(_time * 4.0) * 0.04, 1.0 - sin(_time * 4.0) * 0.035)
	_draw_body(texture, top_left, foot_texel, feet, lift, scale * wobble, _lean * 0.5, color)


func _draw_action_extras(feet: Vector2, height: float, color: Color) -> void:
	var head_top := feet + Vector2(0, -height)
	if _action_left > 0.0 and _action == &"windup":
		var p := 1.0 - _action_left / _action_duration
		draw_line(head_top + Vector2(-7, -6), head_top + Vector2(0, -20 - p * 6.0), Color("f9c778"), 3.0)
		draw_line(head_top + Vector2(0, -20 - p * 6.0), head_top + Vector2(7, -6), Color("f9c778"), 3.0)
	if _action_left > 0.0 and _action == &"cast":
		var center := feet + Vector2(0, -height * 0.5)
		for index in 8:
			var angle := _cast_orbit + index * TAU / 8.0
			var point := center + Vector2.from_angle(angle) * (44.0 + sin(_time * 5.0 + index) * 6.0)
			draw_circle(point, 2.4, Color(accent, color.a * 0.7))
		draw_arc(center, 42.0, 0, TAU, 32, Color(accent, color.a * 0.25), 2.0)
	if _action_left > 0.0 and _action == &"slam":
		var p := 1.0 - _action_left / _action_duration
		draw_arc(feet, 22.0 + p * 90.0, PI, TAU, 24, Color(accent, color.a * (1.0 - p) * 0.7), 4.0)


## Moves a local point onto a whole viewport pixel. Physics positions are
## fractional; drawn there, every texel straddles two pixels and the art goes
## soft. Snapped, the pixel shader samples texel centres exactly at 1x.
func _snap(local: Vector2) -> Vector2:
	if not is_inside_tree():
		return local
	var to_screen := get_global_transform_with_canvas()
	return to_screen.affine_inverse() * (to_screen * local).round()


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 20:
		var angle := TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
