class_name Enemy
extends CharacterBody2D

## 敌人基类：距离触发的 idle / chase / attack 状态机。
## M1 不使用行为树；子类通过覆盖行为钩子做差异（近战、远程、冲锋、飞行、精英）。

signal died(enemy: Enemy)
signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal state_changed(previous: StringName, next: StringName)

const STATE_IDLE: StringName = &"idle"
const STATE_CHASE: StringName = &"chase"
const STATE_ATTACK: StringName = &"attack"
const STATE_DEAD: StringName = &"dead"

@export var data: EnemyData:
	get:
		return _data
	set(value):
		_data = value
		_apply_data()

## 发现目标的距离。
@export var aggro_range: float = 320.0
## 丢失目标的距离，需大于 aggro_range。
@export var deaggro_range: float = 560.0
## 进入攻击状态的距离。
@export var attack_range: float = 44.0
@export var attack_cooldown: float = 1.1
## 攻击前摇；前摇结束时判定命中。
@export var attack_windup: float = 0.35
## 攻击后摇；后摇结束回到 chase/idle。
@export var attack_recovery: float = 0.25
@export var gravity: float = 1200.0
@export var apply_gravity: bool = true
## Ground enemies hop onto the 480/448 px demo platforms; flyers opt out.
@export var can_jump_to_platforms: bool = true
@export var destroy_on_death: bool = true
@export var death_delay: float = 0.35
## 程序动画风格：humanoid / beast / flyer / elite / blob。
@export var actor_style: StringName = &"humanoid"
## 攻击变体数量；子类按 attack_variant 切换招式。
@export var attack_variant_count: int = 1
@export var telegraph_color: Color = Color("f3a57a")
## 可选：由场景自带贴图（召唤物等不会经过 Game._apply_art 的敌人）。
@export var art_texture: Texture2D
@export var art_scale: float = 1.0
@export var art_tint: Color = Color.WHITE
@export var art_offset_y: float = 16.0

var health: int = 0
var max_health: int = 10
var state: StringName = STATE_IDLE
var target: Node2D = null
var dead: bool = false
## 移动速度倍率；减速状态生效时小于 1.0。
var speed_multiplier: float = 1.0
var sprite_visual: Sprite2D = null
var sprite_base_modulate: Color = Color.WHITE
## True when a CreatureArt child plays drawn action strips (death included),
## so the generic dark-red collapse is skipped.
var frame_animated: bool = false

var _data: EnemyData = null
var _attack_cooldown_left: float = 0.0
var _attack_left: float = 0.0
var _attack_windup_left: float = 0.0
var _attack_landed: bool = false
var _facing: float = 1.0
var _flash_left: float = 0.0
var _slow_left: float = 0.0
var _motion: ActorMotion
var _attack_variant: int = 0
var _knockback_left: float = 0.0
var _number_fx: CombatFX
var _number_fx_at: int = 0
var _stun_left: float = 0.0
var _jump_cooldown_left: float = 0.0
## Roaming (0.15): wander around `home` while idle; 0 keeps the old stand-still.
var patrol_radius: float = 0.0
## Only notice targets within this height difference (INF = any).
var aggro_vertical: float = INF
var home: Vector2 = Vector2.INF
var _patrol_dir: float = 1.0
var _patrol_wait: float = 0.0


func _process(_delta: float) -> void:
	if sprite_visual == null or not is_instance_valid(sprite_visual):
		return
	if _motion == null:
		_motion = ActorMotion.new()
		add_child(_motion)
		_motion.bind(sprite_visual)
		_motion.set_style(_style_from_name())
		_motion.accent = telegraph_color
		if health_bar != null:
			health_bar.position.y = PixelSprite.art_top(sprite_visual) - 12.0
			health_bar.size = Vector2(70, 6)
			health_bar.position.x = -35
			health_bar.add_theme_stylebox_override("background", preload("res://resources/ui/bar_background.tres"))
			health_bar.add_theme_stylebox_override("fill", preload("res://resources/ui/bar_health.tres"))
	_motion.direction = _facing
	if not is_on_floor() and apply_gravity:
		_motion.gait = &"jump" if velocity.y < 0.0 else &"fall"
	elif state == STATE_CHASE or absf(velocity.x) > 15.0 or absf(velocity.y) > 20.0:
		_motion.gait = &"run"
	else:
		_motion.gait = &"idle"
	if health_bar != null:
		health_bar.visible = not dead and (health < max_health or state != STATE_IDLE)

@onready var body_visual: Polygon2D = get_node_or_null("Body") as Polygon2D
@onready var health_bar: ProgressBar = get_node_or_null("HealthBar") as ProgressBar


func _init() -> void:
	health = max_health


func _ready() -> void:
	add_to_group("enemies")
	if sprite_visual == null and art_texture != null:
		_attach_scene_art()
	_apply_data()
	health = max_health
	_sync_health_bar()
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node2D
	if _has_valid_target() and _in_aggro_range():
		change_state(STATE_CHASE)


func _physics_process(delta: float) -> void:
	if dead:
		return

	tick_status_effects(delta)
	_tick_flash(delta)
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	_jump_cooldown_left = maxf(_jump_cooldown_left - delta, 0.0)

	if target != null and not is_instance_valid(target):
		target = null
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D

	if apply_gravity and not is_on_floor():
		velocity.y += gravity * delta

	if _stun_left > 0.0:
		# Stunned: frozen in place, no steering and no attacks.
		_stun_left = maxf(_stun_left - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
		if not apply_gravity:
			velocity.y = move_toward(velocity.y, 0.0, 1400.0 * delta)
	elif _knockback_left > 0.0:
		# Knocked back: skip AI steering so the impulse carries the body.
		_knockback_left = maxf(_knockback_left - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		if not apply_gravity:
			velocity.y = move_toward(velocity.y, 0.0, 900.0 * delta)
	else:
		_update_ai(delta)
	move_and_slide()


func set_target(next_target: Node2D) -> void:
	target = next_target
	if dead:
		return
	if not _has_valid_target() or _distance_to_target() > deaggro_range:
		if state != STATE_ATTACK:
			change_state(STATE_IDLE)
		return
	if state == STATE_IDLE and _in_aggro_range():
		change_state(STATE_CHASE)


func change_state(next: StringName) -> void:
	if state == next or state == STATE_DEAD:
		return
	var previous := state
	state = next
	if next == STATE_DEAD:
		velocity = Vector2.ZERO
	_on_state_entered(previous, next)
	state_changed.emit(previous, next)


func take_damage(amount: int) -> void:
	if amount <= 0 or dead:
		return
	var actual := mini(amount, health)
	health = maxi(health - amount, 0)
	_flash_left = 0.12
	if _motion != null:
		_motion.play(&"hit", 0.16)
	if is_inside_tree():
		# Merge rapid hits (volleys, burns) into one rising number per short window.
		var now := Time.get_ticks_msec()
		if _number_fx != null and is_instance_valid(_number_fx) and now - _number_fx_at < 90:
			_number_fx.amount += actual
		else:
			_number_fx = CombatFX.spawn(get_parent(), global_position + Vector2(0, -50), &"number", Color("f1ddae"), 1.0, 30, actual)
			_number_fx_at = now
			CombatFX.spawn(get_parent(), global_position + Vector2(0, -25), &"hit", Color("a6e2d4"), 1.0, 30)
	damaged.emit(actual)
	health_changed.emit(health, max_health)
	_sync_health_bar()
	if health == 0:
		_die()


func get_move_speed() -> float:
	var base_speed := _data.speed if _data != null else 80.0
	return base_speed * speed_multiplier


## 施加减速：multiplier 为速度倍率（0.5 = 半速），duration 为秒。
## 多个减速重叠时取最强倍率，并保留更长的剩余时间。
func apply_slow(multiplier: float, duration: float) -> void:
	if duration <= 0.0:
		return
	var clamped := clampf(multiplier, 0.05, 1.0)
	if _slow_left <= 0.0:
		speed_multiplier = clamped
	else:
		speed_multiplier = minf(speed_multiplier, clamped)
	_slow_left = maxf(_slow_left, duration)


## 同步推进状态计时；_physics_process 会自动调用，测试可手动调用。
func tick_status_effects(delta: float) -> void:
	if _slow_left <= 0.0:
		return
	_slow_left = maxf(_slow_left - delta, 0.0)
	if _slow_left <= 0.0:
		speed_multiplier = 1.0


func is_slowed() -> bool:
	return _slow_left > 0.0


## Spell knockback: an impulse that overrides AI steering for a short time.
## Bosses and other heavy bodies resist it in proportion to their health.
func apply_knockback(impulse: Vector2, duration: float = 0.2) -> void:
	if dead or duration <= 0.0:
		return
	var weight := clampf(float(max_health) / 120.0, 1.0, 4.0)
	velocity = impulse / weight
	_knockback_left = maxf(_knockback_left, duration / weight)


func is_knocked_back() -> bool:
	return _knockback_left > 0.0


## Spell stun: no steering or attacks for the duration; heavy bodies shorten it.
func apply_stun(duration: float) -> void:
	if dead or duration <= 0.0:
		return
	var weight := clampf(float(max_health) / 120.0, 1.0, 4.0)
	_stun_left = maxf(_stun_left, duration / weight)
	if state == STATE_ATTACK:
		_finish_attack()


func is_stunned() -> bool:
	return _stun_left > 0.0


func get_attack_damage() -> int:
	return _data.contact_damage if _data != null else 0


func is_dead() -> bool:
	return dead


## 子类可覆盖的 AI 钩子。
func _idle_behavior(delta: float) -> void:
	if patrol_radius > 0.0 and apply_gravity:
		_patrol(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, get_move_speed() * 4.0 * delta)
	if _has_valid_target() and _in_aggro_range():
		change_state(STATE_CHASE)


## Walks back and forth around `home`, pausing at each end and turning at
## walls and ledges, so a roaming enemy reads as alive before it notices you.
func _patrol(delta: float) -> void:
	if home == Vector2.INF:
		home = global_position
	if _patrol_wait > 0.0:
		_patrol_wait -= delta
		velocity.x = move_toward(velocity.x, 0.0, get_move_speed() * 4.0 * delta)
		return
	var offset := global_position.x - home.x
	var turn := (offset > patrol_radius and _patrol_dir > 0.0) or (offset < -patrol_radius and _patrol_dir < 0.0)
	if is_on_wall() or (is_on_floor() and not _ground_ahead(_patrol_dir)):
		turn = true
	if turn:
		_patrol_dir = -_patrol_dir
		_patrol_wait = randf_range(0.5, 1.4)
		velocity.x = 0.0
		return
	velocity.x = _patrol_dir * get_move_speed() * 0.4
	_face_direction(_patrol_dir)


func _ground_ahead(direction: float) -> bool:
	if not is_inside_tree():
		return true
	var from := global_position + Vector2(direction * 28.0, 0.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 48.0), 1)
	query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _chase_behavior(_delta: float) -> void:
	if not _has_valid_target():
		change_state(STATE_IDLE)
		return
	var distance := _distance_to_target()
	if distance > deaggro_range:
		change_state(STATE_IDLE)
		return
	if distance <= attack_range:
		velocity.x = 0.0
		_face_direction(target.global_position.x - global_position.x)
		if _attack_cooldown_left <= 0.0:
			change_state(STATE_ATTACK)
		return
	try_jump_toward_target()
	_move_toward_target(get_move_speed())


## Hops toward a target standing 60–120 px above and within 140 px sideways.
## The demo's first platform is 80 px up, so grounded enemies can chase there.
## `require_floor` is false in tests, where no physics frame has run yet.
func try_jump_toward_target(require_floor: bool = true) -> bool:
	if dead or not can_jump_to_platforms or not apply_gravity:
		return false
	if require_floor and not is_on_floor():
		return false
	if _jump_cooldown_left > 0.0 or not _has_valid_target():
		return false
	var dx := target.global_position.x - global_position.x
	var dy := global_position.y - target.global_position.y
	if absf(dx) > 140.0 or dy < 60.0 or dy > 120.0:
		return false
	velocity.y = -500.0
	_jump_cooldown_left = 0.8
	_face_direction(dx)
	return true


func _attack_behavior(delta: float) -> void:
	_attack_motion(delta)
	_attack_windup_left = maxf(_attack_windup_left - delta, 0.0)
	_attack_left = maxf(_attack_left - delta, 0.0)
	if not _attack_landed and _attack_windup_left <= 0.0:
		_attack_landed = true
		if _motion != null:
			_motion.play(&"attack", attack_recovery)
		if is_inside_tree():
			CombatFX.spawn(get_parent(), global_position + Vector2(0, -25), &"slash", Color("f7a07e"), _facing, minf(attack_range, 100))
		_perform_attack()
	if _attack_left <= 0.0:
		_finish_attack()


## 攻击期间的水平移动，子类可覆盖（例如近战突进）。
func _attack_motion(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, get_move_speed() * 6.0 * delta)


## 前摇结束时的命中判定，子类可覆盖。
func _perform_attack() -> void:
	if _distance_to_target() <= attack_range + 6.0:
		_damage_target(get_attack_damage())


func _finish_attack() -> void:
	_attack_cooldown_left = attack_cooldown
	if _has_valid_target():
		change_state(STATE_CHASE)
	else:
		change_state(STATE_IDLE)


func _on_state_entered(_previous: StringName, next: StringName) -> void:
	if next == STATE_ATTACK:
		_attack_left = attack_windup + attack_recovery
		_attack_windup_left = attack_windup
		_attack_landed = false
		_attack_variant = (_attack_variant + 1) % maxi(attack_variant_count, 1)
		if _motion != null:
			_motion.play(&"windup", attack_windup)
		_spawn_telegraph()
	elif next == STATE_IDLE:
		velocity.x = 0.0


func _spawn_telegraph() -> void:
	if not is_inside_tree():
		return
	var pulse := CombatFX.spawn(get_parent(), global_position + Vector2(0, 8), &"telegraph", telegraph_color, _facing, maxf(attack_range, 54.0))
	pulse.amount = _attack_variant


## Attack pose for frame-animated creatures: the windup strip until the hit
## lands, then the attack strip. Subclasses with their own timers override it.
func creature_phase() -> StringName:
	return &"windup" if _attack_windup_left > 0.0 else &"attack"


## 当前攻击变体（从 1 开始，每次进入攻击状态递增）。
func get_attack_variant() -> int:
	return _attack_variant + 1


func _style_from_name() -> ActorMotion.Style:
	match actor_style:
		&"beast":
			return ActorMotion.Style.BEAST
		&"flyer":
			return ActorMotion.Style.FLYER
		&"elite":
			return ActorMotion.Style.ELITE
		&"blob":
			return ActorMotion.Style.BLOB
		_:
			return ActorMotion.Style.HUMANOID


func _update_ai(delta: float) -> void:
	match state:
		STATE_IDLE:
			_idle_behavior(delta)
		STATE_CHASE:
			_chase_behavior(delta)
		STATE_ATTACK:
			_attack_behavior(delta)
		_:
			velocity.x = 0.0


func _has_valid_target() -> bool:
	return target != null and is_instance_valid(target)


func _distance_to_target() -> float:
	if not _has_valid_target():
		return INF
	return global_position.distance_to(target.global_position)


func _in_aggro_range() -> bool:
	if _distance_to_target() > aggro_range:
		return false
	return aggro_vertical == INF or absf(target.global_position.y - global_position.y) <= aggro_vertical


func _move_toward_target(speed: float) -> void:
	if not _has_valid_target():
		velocity.x = 0.0
		return
	var dx := target.global_position.x - global_position.x
	if absf(dx) <= 1.0:
		velocity.x = 0.0
		return
	velocity.x = signf(dx) * speed
	_face_direction(dx)


func _face_direction(direction_x: float) -> void:
	if is_zero_approx(direction_x):
		return
	_facing = signf(direction_x)
	if body_visual != null:
		body_visual.scale.x = _facing
	if sprite_visual != null and is_instance_valid(sprite_visual):
		sprite_visual.flip_h = _facing < 0.0


func _damage_target(amount: int) -> void:
	if amount <= 0 or not _has_valid_target():
		return
	if target.has_method("take_damage"):
		target.call("take_damage", amount, global_position)


func _attach_scene_art() -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	PixelSprite.setup(sprite, art_texture, art_scale, art_offset_y)
	sprite.modulate = art_tint
	add_child(sprite)
	sprite_visual = sprite
	sprite_base_modulate = art_tint
	for node_name in ["Body", "Eye", "Outline", "Gap", "Cracks", "Hood", "WingLeft", "WingRight"]:
		var node := get_node_or_null(node_name)
		if node != null:
			node.hide()


func _apply_data() -> void:
	if _data == null:
		return
	max_health = maxi(_data.max_health, 1)
	health = max_health
	if is_node_ready():
		_sync_health_bar()


func _sync_health_bar() -> void:
	if health_bar == null:
		return
	health_bar.max_value = maxi(max_health, 1)
	health_bar.value = health


func _tick_flash(delta: float) -> void:
	if _flash_left <= 0.0:
		return
	_flash_left = maxf(_flash_left - delta, 0.0)
	if body_visual == null:
		return
	if _flash_left > 0.0:
		body_visual.modulate = Color(1.8, 1.8, 1.8, 1.0)
	else:
		body_visual.modulate = Color.WHITE
	if sprite_visual != null and is_instance_valid(sprite_visual):
		if _flash_left > 0.0:
			sprite_visual.modulate = sprite_base_modulate * Color(1.8, 1.8, 1.8, 1.0)
		else:
			sprite_visual.modulate = sprite_base_modulate


func _die() -> void:
	if dead:
		return
	dead = true
	health = 0
	change_state(STATE_DEAD)
	collision_layer = 0
	collision_mask = 0
	if health_bar != null:
		health_bar.visible = false
	if body_visual != null:
		body_visual.modulate = Color(0.35, 0.12, 0.14, 0.8)
	if sprite_visual != null and is_instance_valid(sprite_visual) and not frame_animated:
		sprite_visual.modulate = Color(0.35, 0.12, 0.14, 0.8)
	if _motion != null and not frame_animated:
		_motion.play(&"death", death_delay)
	if is_inside_tree():
		CombatFX.spawn(get_parent(), global_position + Vector2(0, -30), &"death", sprite_base_modulate, _facing, 70)
	died.emit(self)
	if destroy_on_death and is_inside_tree():
		_queue_free_after_delay()


func _queue_free_after_delay() -> void:
	await get_tree().create_timer(death_delay).timeout
	queue_free()
