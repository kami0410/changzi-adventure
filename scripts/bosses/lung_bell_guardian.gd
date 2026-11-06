class_name LungBellGuardian
extends InkArchivist

## Chapter 2 boss: 肺钟守卫 — the city's heartbeat, a bell wrapped in lungs
## (story bible: 钟摆与肺叶组成的巨物，攻击有清晰前摇). The chapter plan points
## its `boss_scene` at this scene, so the generic boss flow (spawn, boss bar,
## phase banner copy, authority pick, outro) is reused unchanged.
##
## Unique mechanic, authored only for this boss:
##   * 呼吸循环 — inhale halves incoming damage; exhale raises it and releases a
##     fog ring. The player reads the state from the sprite tint and the wave.
##   * 钟摆 — the basic attack swings one bolt forward and one back, so the
##     pendulum reads as a sweep instead of a single page wave.
##   * 钉子 — from phase 3 A-Yan's nail is exposed periodically. While it glows
##     the guardian takes bonus damage; while the bell chamber closes it takes
##     reduced damage. This is the phase-3 burst window.
##
## Numbers are the adopted reading of the story bible and the Chapter 2 phase
## copy (no authored values exist in the plan); tests lock them.

signal breath_changed(inhaling: bool)
signal nail_exposed_changed(exposed: bool)

enum Breath {
	INHALE,
	EXHALE,
}

const INHALE_TIME := 2.4
const EXHALE_TIME := 1.4
const INHALE_DAMAGE_MULT := 0.5
const EXHALE_DAMAGE_MULT := 1.5
const BREATH_WAVE_RADIUS := 560.0
const BREATH_WAVE_SPEED := 720.0
const BREATH_WAVE_DAMAGE_SCALE := 0.8
const BREATH_POOL_DAMAGE_SCALE := 0.35
const BREATH_POOL_RADIUS := 70.0
const BREATH_POOL_LIFETIME := 4.0
const NAIL_CYCLE := 12.0
const NAIL_EXPOSED_TIME := 5.0
const NAIL_ARMOR_MULT := 0.6
const NAIL_DAMAGE_MULT := 1.5
const SWEEP_DAMAGE_SCALE := 0.7
const SWEEP_BACK_SCALE := 0.75
const BOMB_DAMAGE_SCALE := 0.8
const BELL_DAMAGE_SCALE := 0.9
const BELL_RADIUS := 620.0
const BELL_SPEED := 760.0

const INHALE_TINT := Color("9fd8cc")
const EXHALE_TINT := Color("f2d7a0")
const NAIL_OPEN_TINT := Color("ffd86e")
const NAIL_CLOSED_TINT := Color("8f9aa8")

var breath: int = Breath.INHALE
var breath_left := INHALE_TIME
var nail_open := false
var nail_left := 0.0

var _breath_waves: Array[Node2D] = []
var _visual_state_applied := false


## A fog/stone ring that expands from the guardian. It damages the player once
## when the band crosses them; standing in the eye or outside its reach is safe.
class BreathWave extends Node2D:
	var radius := 80.0
	var max_radius := 560.0
	var speed := 720.0
	var damage := 10
	var tint := Color("9fd8cc")
	var _hit := false

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		z_index = 6
		add_to_group("hostile_hazards")

	func _physics_process(delta: float) -> void:
		radius = minf(radius + speed * delta, max_radius)
		if not _hit and is_inside_tree():
			for node in get_tree().get_nodes_in_group("player"):
				var player := node as Node2D
				if player == null:
					continue
				if absf(player.global_position.distance_to(global_position) - radius) <= 26.0:
					player.take_damage(damage, global_position)
					_hit = true
					break
		if radius >= max_radius:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(tint, 0.18), 12.0)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(tint, 0.55), 4.0)


func _ready() -> void:
	super._ready()
	_apply_state_tint()


func _process(delta: float) -> void:
	super._process(delta)
	if dead or get_parent() == null:
		return
	# Game._apply_art() attaches the chapter sprite after _ready(). Re-apply the
	# breath tint once the sprite exists so the first cycle reads correctly.
	if not _visual_state_applied and sprite_visual != null \
			and is_instance_valid(sprite_visual):
		_visual_state_applied = true
		_apply_state_tint()
	_tick_breath(delta)
	if phase >= 3:
		_tick_nail(delta)


func check_phase() -> void:
	var before := phase
	super.check_phase()
	if phase != before:
		_on_phase_started(phase)


func _on_phase_started(next: int) -> void:
	breath = Breath.INHALE
	breath_left = INHALE_TIME * _phase_pace()
	if next >= 3:
		_set_nail_open(true, NAIL_EXPOSED_TIME)
	else:
		_set_nail_open(false, 0.0)
	_apply_state_tint()


## Later phases breathe faster; phase 1 keeps the authored 2.4 / 1.4 rhythm.
func _phase_pace() -> float:
	return maxf(0.7, 1.0 - 0.15 * float(phase - 1))


func _tick_breath(delta: float) -> void:
	breath_left -= delta
	if breath_left > 0.0:
		return
	if breath == Breath.INHALE:
		breath = Breath.EXHALE
		breath_left = EXHALE_TIME
		_on_exhale()
	else:
		breath = Breath.INHALE
		breath_left = INHALE_TIME * _phase_pace()
		_on_inhale()
	breath_changed.emit(breath == Breath.INHALE)
	_apply_state_tint()


func _on_inhale() -> void:
	if get_parent() == null:
		return
	CombatFX.spawn(get_parent(), global_position + Vector2(0, -40), &"cast", INHALE_TINT, 1.0, 90)


func _on_exhale() -> void:
	if get_parent() == null:
		return
	_spawn_wave(BREATH_WAVE_RADIUS, BREATH_WAVE_SPEED,
		maxi(int(round(get_attack_damage() * BREATH_WAVE_DAMAGE_SCALE)), 1), EXHALE_TINT)
	# From phase 2 the exhaled fog also pools where the player stood, turning
	# the breath into area denial rather than a single ring.
	if phase >= 2 and _has_valid_target():
		InkPool.create(get_parent(), target.global_position,
			maxi(int(round(get_attack_damage() * BREATH_POOL_DAMAGE_SCALE)), 1),
			BREATH_POOL_RADIUS, BREATH_POOL_LIFETIME)


func _tick_nail(delta: float) -> void:
	nail_left -= delta
	if nail_left > 0.0:
		return
	if nail_open:
		_set_nail_open(false, NAIL_CYCLE - NAIL_EXPOSED_TIME)
	else:
		_set_nail_open(true, NAIL_EXPOSED_TIME)


func _set_nail_open(open: bool, duration: float) -> void:
	nail_open = open
	nail_left = maxf(duration, 0.0)
	nail_exposed_changed.emit(open)
	_apply_state_tint()


## Damage taken now. Phase 3 replaces the breath window with the nail window:
## the breath ring keeps running, but the burst window is the exposed nail.
func damage_multiplier() -> float:
	if phase >= 3:
		return NAIL_DAMAGE_MULT if nail_open else NAIL_ARMOR_MULT
	return INHALE_DAMAGE_MULT if breath == Breath.INHALE else EXHALE_DAMAGE_MULT


func take_damage(amount: int) -> void:
	if amount <= 0 or dead:
		return
	var adjusted := maxi(1, int(round(float(amount) * damage_multiplier())))
	super.take_damage(adjusted)


func is_inhaling() -> bool:
	return breath == Breath.INHALE


func is_nail_open() -> bool:
	return nail_open


func get_breath_wave_count() -> int:
	var count := 0
	for wave in _breath_waves:
		if wave != null and is_instance_valid(wave):
			count += 1
	return count


## Basic attack: the pendulum swings toward the player and back behind it.
func _pendulum_sweep() -> void:
	if not _has_valid_target() or get_parent() == null:
		return
	var damage := maxi(int(round(get_attack_damage() * SWEEP_DAMAGE_SCALE)), 1)
	var parent := get_parent()
	var heading := signf(target.global_position.x - global_position.x)
	HostileBolt.launch(parent, global_position + Vector2(0, -30), Vector2(heading, 0),
		damage, 330)
	HostileBolt.launch(parent, global_position + Vector2(0, 20), Vector2(-heading, 0),
		maxi(int(round(float(damage) * SWEEP_BACK_SCALE)), 1), 280)
	CombatFX.spawn(parent, global_position + Vector2(0, -10), &"ring", Color("d8c08a"),
		heading, 110)


## Heavier ranged variant: an arcing breath bomb that leaves a fog pool.
func _breath_bomb() -> void:
	if not _has_valid_target() or get_parent() == null:
		return
	var damage := maxi(int(round(get_attack_damage() * BOMB_DAMAGE_SCALE)), 1)
	InkBomb.launch(get_parent(), global_position + Vector2(0, -24),
		target.global_position, damage, BREATH_POOL_RADIUS, 0.9, true)


## Phase 2+ third attack: a bell toll ring with a finite reach.
func _bell_toll() -> void:
	if get_parent() == null:
		return
	_spawn_wave(BELL_RADIUS, BELL_SPEED,
		maxi(int(round(get_attack_damage() * BELL_DAMAGE_SCALE)), 1), Color("e8c27a"))


func _spawn_wave(max_radius: float, speed: float, damage: int, tint: Color) -> BreathWave:
	var wave := BreathWave.new()
	wave.max_radius = max_radius
	wave.speed = speed
	wave.damage = damage
	wave.tint = tint
	get_parent().add_child(wave)
	wave.global_position = global_position
	_breath_waves.append(wave)
	return wave


func _perform_attack() -> void:
	attack_cycle += 1
	match phase:
		1:
			if attack_cycle % 2 == 0:
				_breath_bomb()
			else:
				_pendulum_sweep()
		2:
			if attack_cycle % 3 == 0:
				_bell_toll()
			elif attack_cycle % 2 == 0:
				_breath_bomb()
			else:
				_pendulum_sweep()
		_:
			if attack_cycle % 2 == 0:
				_bell_toll()
			else:
				_pendulum_sweep()


func _apply_state_tint() -> void:
	var tint := INHALE_TINT
	if phase >= 3:
		tint = NAIL_OPEN_TINT if nail_open else NAIL_CLOSED_TINT
	elif breath == Breath.EXHALE:
		tint = EXHALE_TINT
	else:
		tint = INHALE_TINT
	sprite_base_modulate = tint
	if sprite_visual != null and is_instance_valid(sprite_visual):
		sprite_visual.modulate = tint


func _clear_breath_waves() -> void:
	for wave in _breath_waves:
		if wave != null and is_instance_valid(wave):
			if wave.is_inside_tree():
				wave.queue_free()
			else:
				wave.free()
	_breath_waves.clear()


func _die() -> void:
	_clear_breath_waves()
	nail_open = false
	super._die()
