class_name Player
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal attack_requested
signal weapon_changed(slot: int)
signal damaged(amount: int)
signal hit_landed
## A hit landed inside the roll's invulnerable window (once per roll).
signal perfect_dodged

@export var move_speed: float = 300.0
@export var jump_velocity: float = -500.0
@export var gravity: float = 1350.0
## Ground roll: a low, fast tumble that starts quick and eases out.
@export var dodge_speed: float = 560.0
@export var dodge_duration: float = 0.36
## Cooldown counts from the start of the roll.
@export var dodge_cooldown: float = 0.52
## Invulnerable part of the roll; the last few frames are a vulnerable recovery.
@export var roll_iframes: float = 0.3
## Capsule height while rolling (standing is 76): projectiles aimed at the
## chest pass over a rolling player.
@export var roll_height: float = 40.0
## One short air dash per airtime instead of a roll.
@export var air_dash_speed: float = 540.0
@export var air_dash_duration: float = 0.18
## A dodge pressed this early (mid-swing, just before landing) still fires.
@export var dodge_buffer: float = 0.16
## Attacking at the end of a roll (or just after) turns the next swing into
## the heavy finisher.
@export var roll_strike_window: float = 0.22
@export var coyote_time: float = 0.1
@export var jump_buffer: float = 0.12
@export var max_health: int = 100
@export var invulnerability_time: float = 0.6
@export var starter_weapon: WeaponData
const RUN_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/player/frames/run_0.png"),
	preload("res://assets/sprites/player/frames/run_1.png"),
	preload("res://assets/sprites/player/frames/run_2.png"),
	preload("res://assets/sprites/player/frames/run_3.png"),
]
const JUMP_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/player/frames/jump_0.png"),
	preload("res://assets/sprites/player/frames/jump_1.png"),
	preload("res://assets/sprites/player/frames/jump_2.png"),
]
const ATTACK_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/player/frames/attack_0.png"),
	preload("res://assets/sprites/player/frames/attack_1.png"),
	preload("res://assets/sprites/player/frames/attack_2.png"),
]
const CAST_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/player/frames/cast_0.png"),
	preload("res://assets/sprites/player/frames/cast_1.png"),
]
const HURT_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/player/frames/hurt_0.png"),
	preload("res://assets/sprites/player/frames/hurt_1.png"),
]
const DODGE_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/player/frames/dodge_0.png"),
	preload("res://assets/sprites/player/frames/dodge_1.png"),
]
## The tucked jump pose doubles as the roll ball; ActorMotion spins it.
const ROLL_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/player/frames/jump_1.png"),
]
## Run cycle speed; four poses at 12 fps complete a stride in 0.33 s.
const RUN_FPS := 12.0
## Whole-number display scale keeps pixel art crisp (see docs/memory/decisions/2026-11-02-art-spec.md).
@export var sprite_scale: float = 1.0
## How far the camera leans toward the facing direction. Single-screen rooms
## set this to 0 so the whole frame does not slide when the player turns.
@export var camera_look_ahead: float = 32.0
## Extra room under the floor when the camera sits on a room's bottom limit,
## so the bottom HUD strip does not cover the ground. game.gd turns it on in
## the big-map rooms, which draw extra ground below their floor for it.
var hud_bottom_pad: float = 0.0
var _hud_pad := 0.0
## Multiplier applied to every incoming hit; game.gd raises it with corruption.
var damage_taken_multiplier: float = 1.0
## Multiplier applied to every weapon hit; game.gd sets it from run authorities.
var damage_dealt_multiplier: float = 1.0

## Local y of the player's feet: the bottom of the collision capsule.
const FOOT_Y := 16.0
## Melee swing sprite per weapon (assets/vfx); unlisted melee weapons use the
## light slash, and every finisher uses the heavy one unless listed here.
const SWING_FX := {
	&"archive_hammer": [&"smash", &"smash"],
	&"ink_axe": [&"smash", &"smash"],
	&"blood_vein_whip": [&"whip", &"whip"],
	&"chain_blade": [&"flurry", &"slash_heavy"],
	&"breath_cleaver": [&"slash_heavy", &"slash_heavy"],
}
const HEAVY_WEAPONS: Array[StringName] = [&"archive_hammer", &"ink_axe", &"breath_cleaver"]
var _last_swing_heavy := false
var _fall_peak := 0.0

var health: int = 0
var is_dodging: bool = false
var facing: Vector2 = Vector2.RIGHT
var disabled_phrase_slots: Array[bool] = [false, false]
var weapons: Array[Weapon] = [null, null]
var active_weapon_slot: int = 0
var _dodge_left := 0.0
var _dodge_cooldown_left := 0.0
var _dodge_buffer_left := 0.0
var _roll_iframes_left := 0.0
var _roll_strike_left := 0.0
var _roll_dir := 1.0
var _roll_total := 0.36
var _air_dash_used := false
var _perfect_used := false
## "roll" on the ground, "air" for the air dash, empty when not dodging.
var dodge_kind: StringName = &""
var _capsule: CapsuleShape2D
var _collision: CollisionShape2D
const STAND_HEIGHT := 76.0
var _invulnerable_left := 0.0
var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _motion: ActorMotion
var _ribbon: ScarfRibbon
var _combo_index := 0
var _combo_window_left := 0.0
var _attack_lunge_left := 0.0
var _step_timer := 0.0
var _shake := 0.0
var _shake_time := 0.0
var _look_ahead := Vector2.ZERO
var _camera: Camera2D
var shield: int = 0
var _shield_left := 0.0
var _haste_left := 0.0
var _haste := 1.0
var _idle_texture: Texture2D
var _frame_clock := 0.0
var _frame_anim: StringName = &""
## One-way platforms open for this long after down+jump, so the player clears
## the top face before the collision exception is released.
const DROP_THROUGH_TIME := 0.3
var _drop_left := 0.0
var _drop_body: PhysicsBody2D

func grant_shield(amount: int, duration: float) -> void:
	shield = maxi(shield, amount)
	_shield_left = maxf(_shield_left, duration)
	_effect(&"cast", Color("8bbfe5"), 60)

func grant_haste(multiplier: float, duration: float) -> void:
	_haste = maxf(_haste, multiplier)
	_haste_left = maxf(_haste_left, duration)

@onready var body_visual: Polygon2D = get_node_or_null("Body") as Polygon2D
@onready var sprite_visual: Sprite2D = get_node_or_null("Sprite") as Sprite2D
@onready var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D

func _init() -> void:
	health = max_health

func _ready() -> void:
	add_to_group("player")
	health = max_health
	health_changed.emit(health, max_health)
	_camera = get_node_or_null("Camera2D") as Camera2D
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		var capsule := CapsuleShape2D.new()
		capsule.radius = 16
		capsule.height = STAND_HEIGHT
		collision.shape = capsule
		collision.position.y = -22
		_capsule = capsule
		_collision = collision
	if sprite_visual != null:
		# Feet on the capsule bottom (local y 16), crisp at any scale.
		_idle_texture = sprite_visual.texture
		PixelSprite.setup(sprite_visual, sprite_visual.texture, sprite_scale, FOOT_Y)
		_ribbon = ScarfRibbon.new()
		add_child(_ribbon)
		_ribbon.z_index = -1
		_motion = ActorMotion.new()
		add_child(_motion)
		_motion.bind(sprite_visual)
		_motion.set_style(ActorMotion.Style.HUMANOID)
		_motion.accent = Color("8fe8dc")
	if starter_weapon == null:
		starter_weapon = preload("res://resources/weapons/broken_page_sword.tres")
	equip_weapon(0, starter_weapon)
	attack_requested.connect(_on_attack_requested)

func _physics_process(delta: float) -> void:
	_dodge_left = maxf(_dodge_left - delta, 0.0)
	_dodge_cooldown_left = maxf(_dodge_cooldown_left - delta, 0.0)
	_dodge_buffer_left = maxf(_dodge_buffer_left - delta, 0.0)
	_roll_iframes_left = maxf(_roll_iframes_left - delta, 0.0)
	_roll_strike_left = maxf(_roll_strike_left - delta, 0.0)
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)
	_shield_left = maxf(_shield_left - delta, 0.0)
	_haste_left = maxf(_haste_left - delta, 0.0)
	_combo_window_left = maxf(_combo_window_left - delta, 0.0)
	_attack_lunge_left = maxf(_attack_lunge_left - delta, 0.0)
	_step_timer = maxf(_step_timer - delta, 0.0)
	_update_drop_through(delta)
	if _combo_window_left <= 0.0:
		_combo_index = 0
	if _shield_left <= 0:
		shield = 0
	if _haste_left <= 0:
		_haste = 1.0
	if health <= 0:
		return
	var was_dodging := is_dodging
	is_dodging = _dodge_left > 0.0
	if was_dodging and not is_dodging:
		_end_dodge()
	set_collision_mask_value(2, not is_dodging)
	var grounded := is_on_floor()
	if grounded:
		_air_dash_used = false
	_coyote_left = coyote_time if grounded else maxf(_coyote_left - delta, 0.0)
	_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)
	if not grounded and dodge_kind != &"air":
		velocity.y += gravity * delta
	var direction := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(direction) and not is_dodging:
		facing = Vector2(signf(direction), 0.0)
		if body_visual != null:
			body_visual.scale.x = facing.x
	# Down + jump drops through a one-way platform. This uses the two actions
	# the player already has (no new button) and leaves a normal jump on solid
	# ground untouched, so Chapter 1 keeps its current feel.
	var jump_pressed := Input.is_action_just_pressed("jump")
	var drop_platform: PhysicsBody2D = null
	if jump_pressed and grounded and _drop_left <= 0.0 \
			and Input.is_action_pressed("move_down"):
		drop_platform = _one_way_platform_below()
	if jump_pressed and drop_platform != null and not is_dodging:
		_begin_drop_through(drop_platform)
	elif jump_pressed:
		_jump_buffer_left = jump_buffer
		if _motion != null and grounded:
			_motion.play(&"windup", 0.08)
	if _jump_buffer_left > 0 and _coyote_left > 0 and not is_dodging:
		velocity.y = jump_velocity
		_jump_buffer_left = 0.0
		_coyote_left = 0.0
		_play_sfx(&"jump")
		_effect(&"dust", Color("9fbfb9"), 26)
	if Input.is_action_just_released("jump") and velocity.y < -150:
		velocity.y *= 0.5
	if Input.is_action_just_pressed("dodge"):
		_dodge_buffer_left = dodge_buffer
	if _dodge_buffer_left > 0.0 and start_dodge(direction):
		_dodge_buffer_left = 0.0
	if is_dodging:
		velocity.x = _roll_dir * _dodge_velocity()
		if dodge_kind == &"air":
			velocity.y = 0.0
	elif _attack_lunge_left > 0.0:
		velocity.x = facing.x * (240.0 if _combo_index >= 3 else 135.0)
	else:
		velocity.x = move_toward(velocity.x, direction * move_speed * _haste, 2400.0 * delta)
	var fall_speed := velocity.y
	move_and_slide()
	if not grounded:
		_fall_peak = maxf(_fall_peak, fall_speed)
	if not grounded and is_on_floor():
		if _fall_peak > 820.0 and is_inside_tree():
			VFX.spawn(get_parent(), &"land_heavy", global_position + Vector2(0, FOOT_Y))
		_fall_peak = 0.0
		if _motion != null:
			_motion.play(&"land", 0.15)
		_effect(&"dust", Color("9fbfb9"), 22)
		CombatFX.spawn(get_parent(), global_position + Vector2(0, 4), &"ring", Color("9fbfb9"), facing.x, 38)
	if grounded and absf(velocity.x) > 80.0 and _step_timer <= 0.0:
		_step_timer = 0.24
		_effect(&"dust", Color("7fa9a4"), 14)
	if Input.is_action_pressed("attack"):
		if not is_dodging:
			attack_requested.emit()
		elif _dodge_left <= _roll_total * 0.4:
			# Pressed in the roll's tail: cut the recovery and strike.
			_end_dodge()
			attack_requested.emit()
	if Input.is_action_just_pressed("weapon_1"):
		switch_weapon(0)
	elif Input.is_action_just_pressed("weapon_2"):
		switch_weapon(1)
	if _motion != null:
		_motion.direction = facing.x
		_motion.gait = &"run" if absf(velocity.x) > 20 else &"idle"
		if not is_on_floor():
			_motion.gait = &"jump" if velocity.y < 0 else &"fall"
		_motion.modulate.a = 0.55 + 0.45 * absf(sin(_invulnerable_left * 35.0)) if _invulnerable_left > 0 and not is_dodging else 1.0
	if _ribbon != null:
		_ribbon.direction = facing.x
		_ribbon.flow = clampf(absf(velocity.x) / move_speed, 0.0, 1.6)
	_update_frames(delta)
	_update_camera(delta)

## Swap the single texture for the frame set generated for that state.
## ActorMotion still owns squash/lean/bob, so the frames only supply the pose.
## One-shot actions pick their frame from the action's progress so the pose
## stays in sync with the hit; the run cycle advances on its own clock.
func _update_frames(delta: float) -> void:
	if sprite_visual == null or _idle_texture == null:
		return
	var action: StringName = _motion.current_action() if _motion != null else &""
	if action == &"hit":
		_frame_anim = &"hit"
		_set_frame(HURT_FRAMES[0])
		return
	if action == &"roll":
		_frame_anim = &"roll"
		_set_frame(_progress_frame(ROLL_FRAMES))
		return
	if action == &"dodge":
		_frame_anim = &"dodge"
		_set_frame(_progress_frame(DODGE_FRAMES))
		return
	if action in [&"attack", &"slam"]:
		_frame_anim = &"attack"
		_set_frame(_progress_frame(ATTACK_FRAMES))
		return
	if action == &"cast":
		_frame_anim = &"cast"
		_set_frame(_progress_frame(CAST_FRAMES))
		return
	if action in [&"windup", &"land"]:
		_frame_anim = &"jump"
		_set_frame(JUMP_FRAMES[0])
		return
	if not is_on_floor():
		_frame_anim = &"jump"
		_set_frame(JUMP_FRAMES[1] if velocity.y < 0.0 else JUMP_FRAMES[2])
		return
	if absf(velocity.x) > 20.0:
		if _frame_anim != &"run":
			_frame_anim = &"run"
			_frame_clock = 0.0
		_frame_clock += delta
		var index := int(floor(_frame_clock * RUN_FPS)) % RUN_FRAMES.size()
		_set_frame(RUN_FRAMES[index])
		return
	_frame_anim = &"idle"
	_set_frame(_idle_texture)


func _progress_frame(frames: Array[Texture2D]) -> Texture2D:
	var progress := _motion.action_progress() if _motion != null else 1.0
	return frames[clampi(int(progress * frames.size()), 0, frames.size() - 1)]


func _set_frame(texture: Texture2D) -> void:
	if sprite_visual != null and sprite_visual.texture != texture:
		sprite_visual.texture = texture


## Starts a roll (on the ground) or an air dash. [param direction] is the
## held move axis; zero rolls toward the facing side, so the player can roll
## back out of a fight. Returns false when the dodge is not available yet.
func start_dodge(direction: float = 0.0) -> bool:
	if is_dodging or _dodge_cooldown_left > 0 or health <= 0:
		return false
	var grounded := is_on_floor() or _coyote_left > 0.0 or not is_inside_tree()
	if not grounded and _air_dash_used:
		return false
	_roll_dir = signf(direction) if not is_zero_approx(direction) else facing.x
	facing = Vector2(_roll_dir, 0.0)
	is_dodging = true
	_perfect_used = false
	set_collision_mask_value(2, false)
	_dodge_cooldown_left = dodge_cooldown
	_attack_lunge_left = 0.0
	if grounded:
		dodge_kind = &"roll"
		_roll_total = dodge_duration
		_set_roll_shape(true)
	else:
		dodge_kind = &"air"
		_roll_total = air_dash_duration
		_air_dash_used = true
	_dodge_left = _roll_total
	var iframes := roll_iframes if dodge_kind == &"roll" else air_dash_duration
	_roll_iframes_left = iframes
	_invulnerable_left = maxf(_invulnerable_left, iframes)
	velocity = Vector2(_roll_dir * _dodge_velocity(), 0.0 if dodge_kind == &"air" else velocity.y)
	if _motion != null:
		_motion.direction = _roll_dir
		_motion.play(&"roll" if dodge_kind == &"roll" else &"dodge", _roll_total)
	_effect(&"dust", Color("70d8cc"), 40)
	_play_sfx(&"dodge")
	_dodge_trail()
	return true


## Horizontal speed at the current point of the dodge: fast out of the gate,
## easing into a short recovery so the roll reads as weight, not a teleport.
func _dodge_velocity() -> float:
	if dodge_kind == &"air":
		return air_dash_speed
	var p := 1.0 - _dodge_left / maxf(_roll_total, 0.001)
	return dodge_speed * lerpf(1.2, 0.45, clampf(p, 0.0, 1.0))


func _end_dodge() -> void:
	if dodge_kind == &"roll":
		_roll_strike_left = roll_strike_window
		_set_roll_shape(false)
		_effect(&"dust", Color("9fbfb9"), 18)
	elif dodge_kind == &"air":
		# Keep a little momentum out of the dash instead of stopping dead.
		velocity.x = _roll_dir * move_speed
	if _motion != null and _motion.current_action() in [&"roll", &"dodge"]:
		_motion.play(&"land", 0.1)
	dodge_kind = &""
	is_dodging = false
	_dodge_left = 0.0
	_roll_iframes_left = 0.0


## Shrinks the capsule to [member roll_height] keeping the feet on the floor.
func _set_roll_shape(rolling: bool) -> void:
	if _capsule == null or _collision == null:
		return
	var height := roll_height if rolling else STAND_HEIGHT
	_capsule.height = height
	_collision.position.y = FOOT_Y - height * 0.5


## Ends a roll/air dash immediately (fall recovery, cutscenes).
func cancel_dodge() -> void:
	if not is_dodging:
		return
	# Drop only the invulnerability the roll granted; a longer window (a
	# recent hit, a revive, a cutscene guard) stays.
	if _invulnerable_left <= _roll_iframes_left + 0.001:
		_invulnerable_left = 0.0
	_end_dodge()


## True while the roll's invulnerable window is open.
func is_rolling_invulnerable() -> bool:
	return is_dodging and _roll_iframes_left > 0.0


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


func play_cast_pose() -> void:
	if _motion != null and health > 0:
		_motion.play(&"cast", 0.38)
	spawn_afterimage()


func spawn_afterimage() -> void:
	if not is_inside_tree() or sprite_visual == null or not is_instance_valid(sprite_visual):
		return
	var ghost := Sprite2D.new()
	ghost.texture = sprite_visual.texture
	PixelSprite.apply_material(ghost)
	ghost.scale = sprite_visual.scale
	# Action frames use wider canvases than the idle sprite; ground each one.
	ghost.offset = PixelSprite.ground_offset(ghost.texture, ghost.scale.x, FOOT_Y)
	# The source Sprite2D is never flipped: ActorMotion mirrors it while drawing.
	ghost.flip_h = facing.x < 0.0
	ghost.modulate = Color(0.35, 0.9, 0.85, 0.58)
	ghost.z_index = 1
	get_parent().add_child(ghost)
	ghost.global_position = global_position
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ghost.queue_free)


func _dodge_trail() -> void:
	if not is_inside_tree():
		return
	for i in 4:
		await get_tree().create_timer(0.04, false).timeout
		if not is_inside_tree():
			return
		spawn_afterimage()

func _play_sfx(id: StringName) -> void:
	if not is_inside_tree():
		return
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.call("play_sfx", id)

func equip_weapon(slot: int, data: WeaponData) -> bool:
	if slot < 0 or slot >= weapons.size() or data == null:
		return false
	if weapons[slot] != null:
		remove_child(weapons[slot])
		weapons[slot].free()
	var weapon: Weapon = RangedWeapon.new() if data.kind == WeaponData.Kind.RANGED else MeleeWeapon.new()
	weapon.name = "Weapon%d" % slot
	weapon.data = data
	weapon.position = Vector2(0, -24)
	weapon.attack_direction = facing
	add_child(weapon)
	weapons[slot] = weapon
	weapon.hit.connect(_on_weapon_hit)
	weapon_changed.emit(active_weapon_slot)
	return true

func switch_weapon(slot: int) -> bool:
	if slot < 0 or slot >= weapons.size() or weapons[slot] == null:
		return false
	if active_weapon_slot != slot:
		active_weapon_slot = slot
		weapon_changed.emit(slot)
	return true

func _on_attack_requested() -> void:
	if health <= 0 or is_dodging:
		return
	var weapon := weapons[active_weapon_slot]
	if weapon == null:
		return
	weapon.attack_direction = facing
	weapon.damage_dealt_multiplier = damage_dealt_multiplier
	if not weapon.try_attack():
		return
	_combo_index = _combo_index + 1 if _combo_window_left > 0.0 else 1
	_combo_index = ((_combo_index - 1) % 3) + 1
	if _roll_strike_left > 0.0:
		# Roll into a strike: the swing out of a roll is always the finisher.
		_combo_index = 3
		_roll_strike_left = 0.0
	_combo_window_left = 0.55
	weapon.damage_multiplier = [1.0, 1.18, 1.55][_combo_index - 1]
	_attack_lunge_left = 0.1 if _combo_index < 3 else 0.16
	_play_sfx(&"attack")
	if _motion != null:
		_motion.play(&"slam" if _combo_index >= 3 else &"attack", minf(weapon.data.attack_cooldown, 0.28))
	if is_inside_tree():
		var slash_color := Color("a5efdd") if _combo_index < 3 else Color("f3cf87")
		var slash_size := minf(weapon.data.attack_range, 95.0) * (1.0 if _combo_index < 3 else 1.35)
		var swing := _swing_fx(weapon, _combo_index >= 3)
		_last_swing_heavy = _combo_index >= 3 or HEAVY_WEAPONS.has(weapon.data.id)
		if swing != &"" and VFX.spawn(get_parent(), swing, global_position + Vector2(0, FOOT_Y), facing.x < 0.0) != null:
			pass
		else:
			CombatFX.spawn(get_parent(), global_position + Vector2(0, -30), &"slash" if weapon is MeleeWeapon else &"cast", slash_color, facing.x, slash_size)
		if _combo_index >= 3:
			CombatFX.spawn(get_parent(), global_position + Vector2(0, -18), &"ring", Color("f3cf87"), facing.x, 54)

## Swing sprite for a melee weapon; ranged weapons keep their own muzzle art.
func _swing_fx(weapon: Weapon, finisher: bool) -> StringName:
	if not weapon is MeleeWeapon or weapon.data == null:
		return &""
	var pair: Array = SWING_FX.get(weapon.data.id, [&"slash_light", &"slash_heavy"])
	return pair[1] if finisher else pair[0]


func _on_weapon_hit(target: Node) -> void:
	_shake = minf(_shake + 0.18, 0.5)
	if target is Node2D and is_inside_tree():
		var at := (target as Node2D).global_position + Vector2(0, -28)
		var id := &"hit_spark"
		if _combo_index >= 3:
			id = &"hit_crit"
		elif _last_swing_heavy:
			id = &"hit_blunt"
		VFX.spawn(get_parent(), id, at, facing.x < 0.0)
	hit_landed.emit()


## Camera trauma from spells and explosions; adds up but never exceeds 1.
func add_shake(amount: float) -> void:
	if amount > 0.0:
		_shake = clampf(_shake + amount, 0.0, 1.0)

func take_damage(amount: int, source_position: Vector2 = Vector2.INF) -> void:
	if amount > 0 and health > 0 and is_rolling_invulnerable() and not _perfect_used:
		_perfect_dodge()
		return
	if amount <= 0 or health <= 0 or is_invulnerable():
		return
	if not is_zero_approx(damage_taken_multiplier - 1.0):
		amount = maxi(int(ceilf(float(amount) * damage_taken_multiplier)), 1)
	if source_position != Vector2.INF and is_inside_tree():
		var push := signf(global_position.x - source_position.x)
		velocity.x = push * 170.0
		velocity.y = minf(velocity.y, -90.0)
	var absorbed := mini(shield, amount)
	shield -= absorbed
	var actual := mini(amount - absorbed, health)
	health -= actual
	_invulnerable_left = invulnerability_time
	_shake = 0.65
	if _motion != null:
		_motion.play(&"hit", 0.2)
	_effect(&"hit", Color("f49287"), 35)
	if actual > 0 and is_inside_tree():
		VFX.spawn(get_parent(), &"hit_player", global_position + Vector2(0, -26))
	_play_sfx(&"hit")
	damaged.emit(actual)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()
		_set_frame(HURT_FRAMES[1])
		if _motion != null:
			_motion.play(&"death", 0.6)

## A hit that the roll slipped through: refund the cooldown, flash gold and
## let game.gd pay out the reward (hit stop + ink).
func _perfect_dodge() -> void:
	_perfect_used = true
	_dodge_cooldown_left = 0.0
	_roll_strike_left = maxf(_roll_strike_left, roll_strike_window + _dodge_left)
	if is_inside_tree():
		CombatFX.spawn(get_parent(), global_position + Vector2(0, -24), &"ring", Color("f3cf87"), facing.x, 64)
		VFX.spawn(get_parent(), &"parry", global_position + Vector2(0, -20), facing.x < 0.0)
		spawn_afterimage()
	_play_sfx(&"perfect_dodge")
	perfect_dodged.emit()


func heal(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	if amount >= 8 and health < max_health and is_inside_tree():
		VFX.spawn(get_parent(), &"heal", global_position + Vector2(0, FOOT_Y))
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)

func revive(amount: int) -> bool:
	if health > 0 or amount <= 0:
		return false
	health = clampi(amount, 1, max_health)
	_invulnerable_left = 1.8
	velocity = Vector2.ZERO
	health_changed.emit(health, max_health)
	_effect(&"cast", Color("f1dc93"), 85)
	return true

func _effect(type: StringName, color: Color, radius: float) -> void:
	if is_inside_tree():
		CombatFX.spawn(get_parent(), global_position, type, color, facing.x, radius)

func _update_camera(delta: float) -> void:
	if _camera == null:
		return
	_shake = maxf(_shake - delta * 2.8, 0.0)
	_shake_time += delta * 40
	# Look-ahead eases toward the facing side and only while actually running.
	# Snapping it on a turn shifted the whole frame 64 px in one frame, which
	# read as the world jumping — worst of all in the single-screen hub.
	var look_target := Vector2.ZERO
	if not is_zero_approx(camera_look_ahead):
		var speed_ratio := clampf(absf(velocity.x) / maxf(move_speed, 1.0), 0.0, 1.0)
		look_target = Vector2(facing.x * camera_look_ahead * speed_ratio, -4.0)
	_look_ahead = _look_ahead.lerp(look_target, 1.0 - exp(-7.0 * delta))
	var shake_scale := 1.0
	var flow := get_node_or_null("/root/Flow") as GameFlow
	if flow != null:
		shake_scale = flow.shake_scale
	var pad_target := 0.0
	if hud_bottom_pad > 0.0 and _camera.limit_bottom < 1000000:
		var view_h := get_viewport_rect().size.y / maxf(_camera.zoom.y, 0.01)
		if _camera.global_position.y + view_h * 0.5 >= float(_camera.limit_bottom) - 4.0:
			pad_target = hud_bottom_pad
	_hud_pad = lerpf(_hud_pad, pad_target, 1.0 - exp(-6.0 * delta))
	_camera.offset = _look_ahead + Vector2(0.0, _hud_pad) \
		+ Vector2(sin(_shake_time * 1.7), cos(_shake_time * 2.3)) * _shake * _shake * 9.0 * shake_scale

## Chapters 2–4 one-way platforms live in this group and let the player drop
## through with down+jump. Chapter 1 has none, so the branch never fires there.
static func is_one_way_platform(body: Object) -> bool:
	return body is Node and (body as Node).is_in_group(&"one_way_platforms")


func _update_drop_through(delta: float) -> void:
	if _drop_left <= 0.0:
		return
	_drop_left = maxf(_drop_left - delta, 0.0)
	if _drop_left <= 0.0:
		_release_drop_through()


## One-way platform directly under the player's feet, if any.
func _one_way_platform_below() -> PhysicsBody2D:
	if not is_inside_tree():
		return null
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24.0, 6.0)
	query.shape = shape
	# A thin band just below the feet: only a platform the player is standing
	# on can be hit.
	query.transform = Transform2D(0.0, global_position + Vector2(0.0, FOOT_Y + 3.0))
	query.collision_mask = 1
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 4):
		var body: Variant = hit.get("collider")
		if body is PhysicsBody2D and is_one_way_platform(body) \
				and (body as Object).has_method(&"allows_drop_through") \
				and bool((body as Object).call(&"allows_drop_through")):
			return body as PhysicsBody2D
	return null


func _begin_drop_through(platform: PhysicsBody2D) -> void:
	_drop_body = platform
	_drop_left = DROP_THROUGH_TIME
	add_collision_exception_with(platform)
	# Consume the jump so the normal jump branch cannot fire on the same press.
	_jump_buffer_left = 0.0
	_coyote_left = 0.0
	velocity.y = maxf(velocity.y, 40.0)


func _release_drop_through() -> void:
	if is_instance_valid(_drop_body):
		remove_collision_exception_with(_drop_body)
	_drop_body = null


func disable_phrase_slot(slot: int, duration: float = 3.0) -> bool:
	if slot < 0 or slot >= disabled_phrase_slots.size():
		return false
	disabled_phrase_slots[slot] = true
	if is_inside_tree():
		_clear_phrase_slot_after(slot, duration)
	return true

func _clear_phrase_slot_after(slot: int, duration: float) -> void:
	await get_tree().create_timer(duration, false).timeout
	disabled_phrase_slots[slot] = false
