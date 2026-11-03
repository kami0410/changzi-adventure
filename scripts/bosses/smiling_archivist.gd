class_name SmilingArchivist
extends InkArchivist

## Final boss. Keeps the archivist's page wave and rewrite, but adds a mirror
## fan that punishes standing still and fills the arena with readable bolts.

func _perform_attack() -> void:
	attack_cycle += 1
	match phase:
		1:
			_page_wave()
		2:
			if attack_cycle % 3 == 0:
				_mirror_fan()
			else:
				_page_wave()
		_:
			match attack_cycle % 4:
				0:
					_rewrite()
				1:
					_mirror_fan()
				2:
					_ink_rain()
				_:
					_page_wave()

func _mirror_fan() -> void:
	if not is_inside_tree() or not _has_valid_target():
		return
	var origin := global_position + Vector2(0, -36)
	var base := origin.direction_to(target.global_position)
	for offset in [-0.34, 0.0, 0.34]:
		HostileBolt.launch(get_parent(), origin, base.rotated(offset), maxi(int(get_attack_damage() * 0.7), 1), 280)
	if is_inside_tree():
		CombatFX.spawn(get_parent(), origin, &"cast", Color("f4b0b7"), 1.0, 100)
