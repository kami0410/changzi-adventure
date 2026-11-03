class_name Player
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal attack_requested
signal weapon_changed(slot: int)
signal damaged(amount: int)
signal hit_landed

@export var move_speed: float = 300.0
@export var jump_velocity: float = -500.0
@export var gravity: float = 1350.0
@export var dodge_speed: float = 600.0
@export var dodge_duration: float = 0.22
@export var dodge_cooldown: float = 0.58
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
## Run cycle speed; four poses at 12 fps complete a stride in 0.33 s.
const RUN_FPS := 12.0
## Whole-number display scale keeps pixel art crisp (see docs/memory/decisions/2026-11-02-art-spec.md).
@export var sprite_scale: float = 1.0
## How far the camera leans toward the facing direction. Single-screen rooms
## set this to 0 so the whole frame does not slide when the player turns.
@export var camera_look_ahead: float = 32.0
## Multiplier applied to every incoming hit; game.gd raises it with corruption.
var damage_taken_multiplier: float = 1.0

## Local y of the player's feet: the bottom of the collision capsule.
const FOOT_Y := 16.0

var health: int = 0
var is_dodging: bool = false
var facing: Vector2 = Vector2.RIGHT
var disabled_phrase_slots: Array[bool] = [false, false]
var weapons: Array[Weapon] = [null, null]
var active_weapon_slot: int = 0
var _dodge_left := 0.0
var _dodge_cooldown_left := 0.0
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
		capsule.height = 76
		collision.shape = capsule
		collision.position.y = -22
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
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)
	_shield_left = maxf(_shield_left - delta, 0.0)
	_haste_left = maxf(_haste_left - delta, 0.0)
	_combo_window_left = maxf(_combo_window_left - delta, 0.0)
	_attack_lunge_left = maxf(_attack_lunge_left - delta, 0.0)
	_step_timer = maxf(_step_timer - delta, 0.0)
	if _combo_window_left <= 0.0:
		_combo_index = 0
	if _shield_left <= 0:
		shield = 0
	if _haste_left <= 0:
		_haste = 1.0
	if health <= 0:
		return
	is_dodging = _dodge_left > 0.0
	set_collision_mask_value(2, not is_dodging)
	var grounded := is_on_floor()
	_coyote_left = coyote_time if grounded else maxf(_coyote_left - delta, 0.0)
	_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)
	if not grounded:
		velocity.y += gravity * delta
	var direction := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(direction) and not is_dodging:
		facing = Vector2(signf(direction), 0.0)
		if body_visual != null:
			body_visual.scale.x = facing.x
	if Input.is_action_just_pressed("jump"):
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
		start_dodge()
	if is_dodging:
		velocity.x = facing.x * dodge_speed
	elif _attack_lunge_left > 0.0:
		velocity.x = facing.x * (240.0 if _combo_index >= 3 else 135.0)
	else:
		velocity.x = move_toward(velocity.x, direction * move_speed * _haste, 2400.0 * delta)
	move_and_slide()
	if not grounded and is_on_floor():
		if _motion != null:
			_motion.play(&"land", 0.15)
		_effect(&"dust", Color("9fbfb9"), 22)
		CombatFX.spawn(get_parent(), global_position + Vector2(0, 4), &"ring", Color("9fbfb9"), facing.x, 38)
	if grounded and absf(velocity.x) > 80.0 and _step_timer <= 0.0:
		_step_timer = 0.24
		_effect(&"dust", Color("7fa9a4"), 14)
	if Input.is_action_pressed("attack") and not is_dodging:
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


func start_dodge() -> void:
	if is_dodging or _dodge_cooldown_left > 0 or health <= 0:
		return
	is_dodging = true
	set_collision_mask_value(2, false)
	_dodge_left = dodge_duration
	_dodge_cooldown_left = dodge_cooldown
	_invulnerable_left = maxf(_invulnerable_left, dodge_duration)
	velocity = Vector2(facing.x * dodge_speed, 0.0)
	if _motion != null:
		_motion.play(&"dodge", dodge_duration)
	_effect(&"dust", Color("70d8cc"), 40)
	_play_sfx(&"dodge")
	_dodge_trail()

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
	if not weapon.try_attack():
		return
	_combo_index = _combo_index + 1 if _combo_window_left > 0.0 else 1
	_combo_index = ((_combo_index - 1) % 3) + 1
	_combo_window_left = 0.55
	weapon.damage_multiplier = [1.0, 1.18, 1.55][_combo_index - 1]
	_attack_lunge_left = 0.1 if _combo_index < 3 else 0.16
	_play_sfx(&"attack")
	if _motion != null:
		_motion.play(&"slam" if _combo_index >= 3 else &"attack", minf(weapon.data.attack_cooldown, 0.28))
	if is_inside_tree():
		var slash_color := Color("a5efdd") if _combo_index < 3 else Color("f3cf87")
		var slash_size := minf(weapon.data.attack_range, 95.0) * (1.0 if _combo_index < 3 else 1.35)
		CombatFX.spawn(get_parent(), global_position + Vector2(0, -30), &"slash" if weapon is MeleeWeapon else &"cast", slash_color, facing.x, slash_size)
		if _combo_index >= 3:
			CombatFX.spawn(get_parent(), global_position + Vector2(0, -18), &"ring", Color("f3cf87"), facing.x, 54)

func _on_weapon_hit(_target: Node) -> void:
	_shake = minf(_shake + 0.18, 0.5)
	hit_landed.emit()


## Camera trauma from spells and explosions; adds up but never exceeds 1.
func add_shake(amount: float) -> void:
	if amount > 0.0:
		_shake = clampf(_shake + amount, 0.0, 1.0)

func take_damage(amount: int, source_position: Vector2 = Vector2.INF) -> void:
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
	_play_sfx(&"hit")
	damaged.emit(actual)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()
		_set_frame(HURT_FRAMES[1])
		if _motion != null:
			_motion.play(&"death", 0.6)

func heal(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
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
	_camera.offset = _look_ahead + Vector2(sin(_shake_time * 1.7), cos(_shake_time * 2.3)) * _shake * _shake * 9.0 * shake_scale

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
