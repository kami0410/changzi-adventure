class_name LastReader
extends InkArchivist

## 第三章 Boss「最后的读者」：把玩家自己的倒影当作攻击。
## 用现有回声精灵做视觉，行为上以“读页”封印短语、镜像弹幕和落墨为主。

func _perform_attack() -> void:
	attack_cycle += 1
	match phase:
		1:
			_page_wave()
		2:
			if attack_cycle % 3 == 0:
				_read_page()
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

func _mirror_fan() -> void:
	if not is_inside_tree() or not _has_valid_target():
		return
	var origin := global_position + Vector2(0, -30)
	var base := origin.direction_to(target.global_position)
	for offset in [-0.28, 0.0, 0.28]:
		HostileBolt.launch(get_parent(), origin, base.rotated(offset), maxi(int(get_attack_damage() * 0.7), 1), 270)
	if is_inside_tree():
		CombatFX.spawn(get_parent(), origin, &"cast", Color("a8e3d0"), 1.0, 90)

func _read_page() -> void:
	if not is_inside_tree() or not _has_valid_target():
		return
	InkWarning.create(get_parent(), Vector2(target.global_position.x, global_position.y + 20), maxi(int(get_attack_damage() * 0.8), 1))
	if target.has_method("disable_phrase_slot"):
		target.call("disable_phrase_slot", attack_cycle % 2)
