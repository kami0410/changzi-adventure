class_name InkArchivist
extends Enemy

signal phase_changed(phase: int)

@export var phase: int = 1

var attack_cycle: int = 0


func take_damage(amount: int) -> void:
	super.take_damage(amount)
	check_phase()


func check_phase() -> void:
	if dead:
		return
	var ratio := float(health) / float(max_health) if max_health > 0 else 0.0
	var next_phase := 1
	if ratio <= 0.33:
		next_phase = 3
	elif ratio <= 0.66:
		next_phase = 2
	if next_phase == phase:
		return
	phase = next_phase
	attack_cooldown = maxf(0.75, 1.6 - phase * 0.2)
	if is_inside_tree():
		CombatFX.spawn(get_parent(), global_position + Vector2(0, -70), &"cast", Color("f19c9f"), 1.0, 180)
	phase_changed.emit(phase)


func _perform_attack() -> void:
	attack_cycle += 1
	match phase:
		1:
			_page_wave()
		2:
			if attack_cycle % 3 == 0:
				_ink_rain()
			else:
				_page_wave()
		3:
			match attack_cycle % 3:
				0:
					_rewrite()
				1:
					_ink_rain()
				_:
					_page_wave()


func _page_wave() -> void:
	if not _has_valid_target():
		return
	if not is_inside_tree():
		if _distance_to_target() <= attack_range + 140.0:
			_damage_target(get_attack_damage())
		return
	var origin := global_position + Vector2(0, -22)
	var heading := Vector2(signf(target.global_position.x - global_position.x), 0)
	HostileBolt.launch(get_parent(), origin, heading, get_attack_damage(), 300)
	if phase >= 2:
		HostileBolt.launch(get_parent(), origin + Vector2(0, -60), heading, get_attack_damage(), 245)


func _ink_rain() -> void:
	if not _has_valid_target():
		return
	if not is_inside_tree():
		return
	for x_offset in [-110, 0, 110]:
		InkWarning.create(get_parent(), Vector2(target.global_position.x + x_offset, global_position.y), maxi(int(get_attack_damage() * 0.75), 1))


func _rewrite() -> void:
	if not _has_valid_target():
		return
	if target.has_method("disable_phrase_slot"):
		target.call("disable_phrase_slot", attack_cycle % 2)
