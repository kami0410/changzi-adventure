class_name InkArchivistCh1
extends InkArchivist

## Chapter 1 demo boss: three authored phases rather than the generic
## InkArchivist skeleton.
##   1 书页潮   — page waves, ink rain every third attack.
##   2 页风暴   — three moving safe zones; pages fall outside them for 6 s.
##   3 封页+镜写 — seals one phrase slot, then mirrors the player's weapon.

const STORM_DURATION := 6.0
const STORM_TICK := 0.8
const SAFE_ZONE_RADIUS := 62.0
const SEAL_INTERVAL := 12.0
const MIRROR_INTERVAL := 16.0
const SEAL_DURATION := 4.0
const MIRROR_WINDUP := 0.9

var _storm_active := false
var _storm_left := 0.0
var _storm_tick_left := 0.0
var _safe_zones: Array[Node2D] = []
var _seal_timer := SEAL_INTERVAL
var _mirror_timer := MIRROR_INTERVAL


class SafeZone extends Node2D:
	var radius := 62.0

	func _ready() -> void:
		z_index = 3

	func _draw() -> void:
		var width := radius * 2.0
		draw_rect(Rect2(-radius, -140.0, width, 140.0), Color(0.35, 0.95, 0.85, 0.08))
		draw_line(Vector2(-radius, -140), Vector2(radius, -140), Color(0.55, 1.0, 0.92, 0.55), 2.0)
		draw_line(Vector2(-radius, -140), Vector2(-radius, 0), Color(0.55, 1.0, 0.92, 0.45), 1.0)
		draw_line(Vector2(radius, -140), Vector2(radius, 0), Color(0.55, 1.0, 0.92, 0.45), 1.0)


func _process(delta: float) -> void:
	super._process(delta)
	if dead or not is_inside_tree():
		return
	if _storm_active:
		_tick_storm(delta)
	if phase == 3:
		_seal_timer -= delta
		_mirror_timer -= delta
		if _seal_timer <= 0.0:
			_seal_timer = SEAL_INTERVAL
			_seal_phrase_slot()
		if _mirror_timer <= 0.0:
			_mirror_timer = MIRROR_INTERVAL
			_mirror_write()


func check_phase() -> void:
	var before := phase
	super.check_phase()
	if phase != before:
		_on_phase_started(phase)


func _on_phase_started(next: int) -> void:
	if next == 2:
		_start_storm()
	elif next == 3:
		_stop_storm()
		_seal_timer = SEAL_INTERVAL
		_mirror_timer = MIRROR_INTERVAL
	else:
		_stop_storm()


func _perform_attack() -> void:
	attack_cycle += 1
	if attack_cycle % 3 == 0:
		_ink_rain()
	else:
		_page_wave()


func _die() -> void:
	_stop_storm()
	super._die()


# --- phase 2: page storm --------------------------------------------------

func _start_storm() -> void:
	if _storm_active or get_parent() == null:
		return
	_storm_active = true
	_storm_left = STORM_DURATION
	_storm_tick_left = 0.0
	_clear_safe_zones()
	var parent := get_parent()
	for index in 3:
		var zone := SafeZone.new()
		zone.radius = SAFE_ZONE_RADIUS
		zone.position = Vector2(240.0 + index * 400.0 + randi_range(-28, 28), 560.0)
		parent.add_child(zone)
		_safe_zones.append(zone)


func _tick_storm(delta: float) -> void:
	_storm_left -= delta
	_storm_tick_left -= delta
	if _storm_tick_left <= 0.0:
		_storm_tick_left = STORM_TICK
		_storm_tick()
	if _storm_left <= 0.0:
		_stop_storm()


func _storm_tick() -> void:
	if not _has_valid_target() or not is_inside_tree():
		return
	var damage := maxi(int(get_attack_damage() * 0.6), 1)
	if not _in_safe_zone(target.global_position):
		InkWarning.create(get_parent(), Vector2(target.global_position.x, 560.0), damage)
	for index in 2:
		var point := Vector2(randf_range(100.0, 1180.0), 560.0)
		if not _in_safe_zone(point):
			InkWarning.create(get_parent(), point, damage)


func _in_safe_zone(point: Vector2) -> bool:
	for zone in _safe_zones:
		if zone != null and is_instance_valid(zone):
			if absf(point.x - zone.global_position.x) < zone.radius and absf(point.y - zone.global_position.y) < 150.0:
				return true
	return false


func _stop_storm() -> void:
	_storm_active = false
	_storm_left = 0.0
	_clear_safe_zones()


func _clear_safe_zones() -> void:
	for zone in _safe_zones:
		if zone != null and is_instance_valid(zone):
			zone.queue_free()
	_safe_zones.clear()


func is_storm_active() -> bool:
	return _storm_active


func get_safe_zone_count() -> int:
	return _safe_zones.size()


# --- phase 3: seal + mirror write -----------------------------------------

func _seal_phrase_slot() -> int:
	if not _has_valid_target():
		return -1
	var slot := attack_cycle % 2
	if target.has_method("disable_phrase_slot"):
		target.call("disable_phrase_slot", slot, SEAL_DURATION)
		if is_inside_tree():
			CombatFX.spawn(get_parent(), target.global_position + Vector2(0, -40), &"cast", Color("b07cf0"), 1.0, 80)
		return slot
	return -1


func _mirror_write() -> void:
	if not _has_valid_target() or not is_inside_tree():
		return
	var kind := _target_weapon_kind()
	await get_tree().create_timer(MIRROR_WINDUP).timeout
	if dead or not is_inside_tree() or not _has_valid_target():
		return
	_fire_mirror(kind)


func _fire_mirror(kind: StringName) -> void:
	var parent := get_parent()
	if parent == null or not _has_valid_target():
		return
	var origin := global_position + Vector2(0, -30)
	var heading := Vector2(signf(target.global_position.x - global_position.x), 0)
	var damage := maxi(int(get_attack_damage() * 0.85), 1)
	if kind == &"ranged":
		for angle in [-0.22, 0.0, 0.22]:
			var bolt := HostileBolt.launch(parent, origin, heading.rotated(angle), damage, 340)
			bolt.tint = Color("d96a7a")
	else:
		var bolt := HostileBolt.launch(parent, origin + Vector2(0, 22), heading, maxi(int(damage * 1.25), 1), 420)
		bolt.tint = Color("d96a7a")
		CombatFX.spawn(parent, global_position + Vector2(0, 8), &"ring", Color("d96a7a"), heading.x, 130)


func _target_weapon_kind() -> StringName:
	if target == null or not is_instance_valid(target):
		return &"melee"
	var weapons_value = target.get("weapons")
	if weapons_value is Array:
		var weapons: Array = weapons_value
		var slot: int = int(target.get("active_weapon_slot")) if target.get("active_weapon_slot") != null else 0
		if slot >= 0 and slot < weapons.size():
			var weapon := weapons[slot] as Weapon
			if weapon != null and weapon.data != null and weapon.data.kind == WeaponData.Kind.RANGED:
				return &"ranged"
	return &"melee"
