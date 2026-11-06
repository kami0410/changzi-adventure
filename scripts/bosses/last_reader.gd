class_name LastReader
extends InkArchivist

## Chapter 3 boss: 最后的读者 — the child who has read every ending
## (story bible: 用镜面弹幕和「读页」封印昌子的短语). The chapter plan points
## its `boss_scene` at this scene, so the generic boss flow (spawn, boss bar,
## phase banner copy, authority pick, outro) is reused unchanged.
##
## Unique mechanic, authored only for this boss:
##   * 镜面弹幕 — a symmetric fan of mirror bolts aimed at the player. The fan
##     gains two more bolts and a wider arc as the reader turns to the endings
##     he has already read (phases 2–3).
##   * 读页 — from phase 2 the reader reads a page aloud: a ground warning
##     marks the spot and one of the player's phrase slots goes mute for a
##     short window.
##   * 空白页 — in phase 3 the blank last page turns periodically. While the
##     blank page is open the reader is exposed (bonus damage); while the book
##     is closed he is armored. This is the phase-3 burst window.
##
## Numbers are the adopted reading of the story bible and the Chapter 3 phase
## copy (no authored values exist in the plan); tests lock them.

signal blank_page_changed(exposed: bool)
signal phrase_sealed(slot: int)

const MIRROR_BOLTS_PER_PHASE: Array[int] = [3, 5, 7]
const MIRROR_SPREAD_PER_PHASE: Array[float] = [0.28, 0.40, 0.52]
const MIRROR_BOLT_DAMAGE_SCALE := 0.7
const MIRROR_BOLT_SPEED := 270.0
const READ_PAGE_DAMAGE_SCALE := 0.8
const READ_PAGE_SEAL_TIME := 3.0
const BLANK_PAGE_CYCLE := 11.0
const BLANK_PAGE_OPEN_TIME := 4.5
const BLANK_PAGE_OPEN_MULT := 1.5
const BLANK_PAGE_CLOSED_MULT := 0.6

const READER_TINT := Color.WHITE
const BLANK_PAGE_OPEN_TINT := Color("fff2c4")
const BLANK_PAGE_CLOSED_TINT := Color("8fa3b8")

var blank_page_open := false
var blank_page_left := 0.0
var last_sealed_slot: int = -1

var _visual_state_applied := false


func _ready() -> void:
	super._ready()
	_apply_state_tint()


func _process(delta: float) -> void:
	super._process(delta)
	if dead or get_parent() == null:
		return
	# Game._apply_art() attaches the chapter sprite after _ready(). Re-apply the
	# state tint once the sprite exists so the first phase reads correctly.
	if not _visual_state_applied and sprite_visual != null \
			and is_instance_valid(sprite_visual):
		_visual_state_applied = true
		_apply_state_tint()
	if phase >= 3:
		_tick_blank_page(delta)


func check_phase() -> void:
	var before := phase
	super.check_phase()
	if phase != before:
		_on_phase_started(phase)


func _on_phase_started(next: int) -> void:
	if next >= 3:
		_set_blank_page(true, BLANK_PAGE_OPEN_TIME)
	else:
		_set_blank_page(false, 0.0)
	_apply_state_tint()


func _tick_blank_page(delta: float) -> void:
	blank_page_left -= delta
	if blank_page_left > 0.0:
		return
	if blank_page_open:
		_set_blank_page(false, BLANK_PAGE_CYCLE - BLANK_PAGE_OPEN_TIME)
	else:
		_set_blank_page(true, BLANK_PAGE_OPEN_TIME)


func _set_blank_page(open: bool, duration: float) -> void:
	blank_page_open = open
	blank_page_left = maxf(duration, 0.0)
	blank_page_changed.emit(open)
	_apply_state_tint()


## Damage taken now. Phases 1–2 read normally; phase 3 alternates the blank-page
## burst window (open = exposed, closed = armored).
func damage_multiplier() -> float:
	if phase >= 3:
		return BLANK_PAGE_OPEN_MULT if blank_page_open else BLANK_PAGE_CLOSED_MULT
	return 1.0


func take_damage(amount: int) -> void:
	if amount <= 0 or dead:
		return
	var adjusted := maxi(1, int(round(float(amount) * damage_multiplier())))
	super.take_damage(adjusted)


func is_blank_page_open() -> bool:
	return blank_page_open


func get_mirror_bolt_count() -> int:
	return MIRROR_BOLTS_PER_PHASE[clampi(phase - 1, 0, MIRROR_BOLTS_PER_PHASE.size() - 1)]


func get_mirror_spread() -> float:
	return MIRROR_SPREAD_PER_PHASE[
		clampi(phase - 1, 0, MIRROR_SPREAD_PER_PHASE.size() - 1)]


func _perform_attack() -> void:
	attack_cycle += 1
	match phase:
		1:
			if attack_cycle % 2 == 0:
				_mirror_fan()
			else:
				_page_wave()
		2:
			if attack_cycle % 3 == 0:
				_read_page()
			elif attack_cycle % 2 == 0:
				_mirror_fan()
			else:
				_page_wave()
		_:
			match attack_cycle % 4:
				0:
					_rewrite()
				1:
					_read_page()
				2:
					_mirror_fan()
				_:
					_ink_rain()


## 镜面弹幕: a symmetric fan centred on the player. Later phases widen the arc
## and add two more bolts, so the same tell reads as a stronger barrage.
func _mirror_fan() -> void:
	if get_parent() == null or not _has_valid_target():
		return
	var origin := global_position + Vector2(0, -30)
	var base := origin.direction_to(target.global_position)
	var count := get_mirror_bolt_count()
	var spread := get_mirror_spread()
	var damage := maxi(int(get_attack_damage() * MIRROR_BOLT_DAMAGE_SCALE), 1)
	for index in count:
		var ratio := 0.0
		if count > 1:
			ratio = (float(index) / float(count - 1)) * 2.0 - 1.0
		HostileBolt.launch(get_parent(), origin, base.rotated(ratio * spread),
			damage, MIRROR_BOLT_SPEED)
	CombatFX.spawn(get_parent(), origin, &"cast", Color("a8e3d0"), 1.0, 90)


## 读页: the reader reads a page aloud, marking the player's spot and muting one
## phrase slot. Which slot alternates with the attack cycle.
func _read_page() -> void:
	if get_parent() == null or not _has_valid_target():
		return
	InkWarning.create(get_parent(),
		Vector2(target.global_position.x, global_position.y + 20),
		maxi(int(get_attack_damage() * READ_PAGE_DAMAGE_SCALE), 1))
	if target.has_method("disable_phrase_slot"):
		var slot := attack_cycle % 2
		last_sealed_slot = slot
		target.call("disable_phrase_slot", slot, READ_PAGE_SEAL_TIME)
		phrase_sealed.emit(slot)


func _apply_state_tint() -> void:
	var tint := READER_TINT
	if phase >= 3:
		tint = BLANK_PAGE_OPEN_TINT if blank_page_open else BLANK_PAGE_CLOSED_TINT
	sprite_base_modulate = tint
	if sprite_visual != null and is_instance_valid(sprite_visual):
		sprite_visual.modulate = tint


func _die() -> void:
	blank_page_open = false
	blank_page_left = 0.0
	super._die()
