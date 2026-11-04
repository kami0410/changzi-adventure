extends RefCounted

## 吞噬 / 归档 authorities: conditional boss offers, the run-long devour damage
## rule, the death-time archive pick, and Profile carry-over across runs.

const ARCHIVE_PATH := "res://resources/authorities/archive.tres"
const DEVOUR_PATH := "res://resources/authorities/devour.tres"
const REVIVE_PATH := "res://resources/authorities/revive.tres"
const REWRITE_PATH := "res://resources/authorities/rewrite.tres"
const PROFILE_PATH := "user://test_archive_authority_profile.cfg"


func run(t: Callable) -> void:
	_cleanup()
	_test_resource_metadata(t)
	_test_unlock_met(t)
	_test_build_pool(t)
	_test_devour_multiplier(t)
	_test_controller_usage(t)
	_test_profile_archive_roundtrip(t)
	_test_profile_old_save_compat(t)
	_test_archive_choice_ui(t)
	_test_authority_choice_grid(t)
	_cleanup()


func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = PROFILE_PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _make_run(seed_value: int = 1) -> RunState:
	var run := RunState.new()
	run.reset_for_new_run(seed_value)
	return run


func _base_pool() -> Array[AuthorityData]:
	var result: Array[AuthorityData] = []
	result.append(load(REVIVE_PATH) as AuthorityData)
	result.append(load(REWRITE_PATH) as AuthorityData)
	return result


func _ids(pool: Array[AuthorityData]) -> Array[String]:
	var result: Array[String] = []
	for authority in pool:
		result.append(String(authority.id) if authority != null else "<null>")
	return result


func _test_resource_metadata(t: Callable) -> void:
	var devour := load(DEVOUR_PATH) as AuthorityData
	var archive := load(ARCHIVE_PATH) as AuthorityData
	t.call(devour != null, true, "devour_loads")
	t.call(archive != null, true, "archive_loads")
	if devour != null:
		t.call(devour.effect_id, &"devour", "devour_effect_id")
		t.call(devour.unlock_condition, &"corruption", "devour_unlock_condition")
		t.call(devour.unlock_threshold, 40, "devour_unlock_threshold")
		t.call(devour.description.contains("污染 ≥ 40"), true, "devour_description_states_unlock")
	if archive != null:
		t.call(archive.effect_id, &"archive", "archive_effect_id")
		t.call(archive.unlock_condition, &"records", "archive_unlock_condition")
		t.call(archive.unlock_threshold, 2, "archive_unlock_threshold")
		t.call(archive.description.contains("本局记录 ≥ 2"), true, "archive_description_states_unlock")
	var revive := load(REVIVE_PATH) as AuthorityData
	var rewrite := load(REWRITE_PATH) as AuthorityData
	t.call(revive != null and revive.unlock_condition == &"", true, "revive_has_no_condition")
	t.call(rewrite != null and rewrite.unlock_condition == &"", true, "rewrite_has_no_condition")


func _test_unlock_met(t: Callable) -> void:
	var run := _make_run()
	var profile := Profile.new()
	var devour := load(DEVOUR_PATH) as AuthorityData
	var archive := load(ARCHIVE_PATH) as AuthorityData

	t.call(AuthorityController.unlock_met(devour, run, profile, 0), false,
		"devour_locked_at_zero")
	run.corruption = 39
	t.call(AuthorityController.unlock_met(devour, run, profile, 0), false,
		"devour_locked_at_39")
	run.corruption = 40
	t.call(AuthorityController.unlock_met(devour, run, profile, 0), true,
		"devour_unlocked_at_40")
	t.call(AuthorityController.unlock_met(archive, run, profile, 1), false,
		"archive_locked_at_one_record")
	t.call(AuthorityController.unlock_met(archive, run, profile, 2), true,
		"archive_unlocked_at_two_records")

	var profile_rule := AuthorityData.new()
	profile_rule.id = &"test_profile_rule"
	profile_rule.unlock_condition = &"profile_records"
	profile_rule.unlock_threshold = 3
	profile.records_found = 2
	t.call(AuthorityController.unlock_met(profile_rule, run, profile, 0), false,
		"profile_rule_locked")
	profile.records_found = 3
	t.call(AuthorityController.unlock_met(profile_rule, run, profile, 0), true,
		"profile_rule_unlocked")
	t.call(AuthorityController.unlock_met(profile_rule, null, null, 0), false,
		"profile_rule_null_profile_safe")

	var unknown := AuthorityData.new()
	unknown.id = &"test_unknown"
	unknown.unlock_condition = &"mystery"
	unknown.unlock_threshold = 1
	t.call(AuthorityController.unlock_met(unknown, run, profile, 99), false,
		"unknown_condition_locked")
	t.call(AuthorityController.unlock_met(null, run, profile, 99), false,
		"null_authority_locked")
	var unconditional := AuthorityData.new()
	unconditional.id = &"test_unconditional"
	t.call(AuthorityController.unlock_met(unconditional, run, profile, 99), false,
		"empty_condition_never_unlocks")

	profile.free()


func _test_build_pool(t: Callable) -> void:
	var run := _make_run()
	var profile := Profile.new()
	var base := _base_pool()

	run.corruption = 0
	var plain := AuthorityController.build_pool(base, run, profile, 0)
	t.call(_ids(plain), ["revive", "rewrite"], "pool_base_only")

	run.corruption = 40
	var devour_pool := AuthorityController.build_pool(base, run, profile, 0)
	t.call(_ids(devour_pool), ["revive", "rewrite", "devour"], "pool_adds_devour")
	t.call(devour_pool[0] == base[0] and devour_pool[1] == base[1], true,
		"pool_keeps_authored_order")

	var archive_pool := AuthorityController.build_pool(base, run, profile, 2)
	t.call(_ids(archive_pool), ["revive", "rewrite", "archive", "devour"],
		"pool_adds_archive_and_devour")
	t.call(archive_pool.size(), 4, "pool_four_options")

	run.corruption = 100
	var both := AuthorityController.build_pool(base, run, profile, 2)
	t.call(both.size(), 4, "pool_never_duplicates")

	var archive_base: Array[AuthorityData] = [load(ARCHIVE_PATH) as AuthorityData]
	var no_duplicate := AuthorityController.build_pool(archive_base, run, profile, 2)
	t.call(_ids(no_duplicate), ["archive", "devour"], "pool_skips_authored_duplicate")

	var empty_base: Array[AuthorityData] = []
	run.corruption = 0
	t.call(AuthorityController.build_pool(empty_base, run, profile, 0).size(), 0,
		"pool_empty_when_no_condition_met")

	# Null entries in an authored pool are dropped instead of crashing the pick.
	var with_null: Array[AuthorityData] = [null, load(REVIVE_PATH) as AuthorityData]
	var cleaned := AuthorityController.build_pool(with_null, run, profile, 0)
	t.call(_ids(cleaned), ["revive"], "pool_drops_null_entries")
	t.call(AuthorityController.build_pool(base, null, profile, 0).size(), 2,
		"pool_null_run_keeps_base")

	profile.free()


func _test_devour_multiplier(t: Callable) -> void:
	var run := _make_run()
	var controller := AuthorityController.new()
	t.call(controller.damage_multiplier(run), 1.0, "no_authority_multiplier_one")
	t.call(controller.damage_multiplier(null), 1.0, "null_run_multiplier_one")

	var devour := load(DEVOUR_PATH) as AuthorityData
	controller.apply(devour, run)
	for pair in [[0, 1.0], [39, 1.234], [40, 1.24], [100, 1.6]]:
		run.corruption = int(pair[0])
		t.call(is_equal_approx(controller.damage_multiplier(run), float(pair[1])), true,
			"devour_multiplier_at_%d" % int(pair[0]))
	run.corruption = 150
	t.call(is_equal_approx(controller.damage_multiplier(run), 1.6), true,
		"devour_multiplier_clamps_high")
	run.corruption = -20
	t.call(is_equal_approx(controller.damage_multiplier(run), 1.0), true,
		"devour_multiplier_clamps_low")

	# The multiplier is live: purifying corruption lowers the bonus.
	run.corruption = 100
	var before := controller.damage_multiplier(run)
	run.add_corruption(-60)
	t.call(controller.damage_multiplier(run) < before, true,
		"devour_multiplier_follows_corruption")



func _test_controller_usage(t: Callable) -> void:
	var run := _make_run()
	var controller := AuthorityController.new()
	var devour := load(DEVOUR_PATH) as AuthorityData
	controller.apply(devour, run)
	t.call(controller.effect_id(), &"devour", "controller_effect_id")
	t.call(controller.can_use(), true, "devour_can_use_passive")
	t.call(controller.can_archive(), false, "devour_cannot_archive")
	t.call(controller.consume_archive(), false, "devour_consume_archive_false")
	t.call(controller.can_use(), true, "devour_stays_available")

	var archive := load(ARCHIVE_PATH) as AuthorityData
	controller.apply(archive, run)
	t.call(controller.effect_id(), &"archive", "controller_archive_effect_id")
	t.call(controller.can_use(), true, "archive_can_use_before_death")
	t.call(controller.consume_archive(), true, "archive_consume_once")
	t.call(controller.can_use(), false, "archive_spent_after_death")
	t.call(controller.consume_archive(), false, "archive_cannot_consume_twice")

	var empty := AuthorityController.new()
	t.call(empty.effect_id(), &"", "controller_no_effect_id")
	t.call(empty.can_use(), false, "controller_no_authority_cannot_use")
	t.call(empty.damage_multiplier(run), 1.0, "controller_no_authority_damage")


func _test_profile_archive_roundtrip(t: Callable) -> void:
	var profile := Profile.new()
	t.call(profile.archived_item.is_empty(), true, "archive_profile_starts_empty")
	t.call(profile.store_archived_item(&"weapon", &"ink_axe"), true, "archive_store_weapon")
	t.call(_is_archived(profile, "weapon", "ink_axe"), true, "archive_store_weapon_shape")
	t.call(profile.store_archived_item(&"relic", &"ink_heart"), true, "archive_store_relic")
	t.call(profile.store_archived_item(&"word", &"xue"), false, "archive_rejects_word")
	t.call(profile.store_archived_item(&"weapon", &""), false, "archive_rejects_empty_id")
	t.call(_is_archived(profile, "relic", "ink_heart"), true, "archive_invalid_store_keeps_value")

	profile.save_profile(PROFILE_PATH)
	t.call(FileAccess.file_exists(PROFILE_PATH), true, "archive_profile_saves")
	var loaded := Profile.new()
	t.call(loaded.load_profile(PROFILE_PATH), true, "archive_profile_loads")
	t.call(_is_archived(loaded, "relic", "ink_heart"), true, "archive_profile_roundtrip")
	var consumed := loaded.consume_archived_item()
	t.call(String(consumed.get("kind", "")), "relic", "archive_consume_kind")
	t.call(String(consumed.get("id", "")), "ink_heart", "archive_consume_id")
	t.call(loaded.archived_item.is_empty(), true, "archive_consume_clears")
	t.call(loaded.consume_archived_item().is_empty(), true, "archive_consume_only_once")
	loaded.save_profile(PROFILE_PATH)
	var reloaded := Profile.new()
	t.call(reloaded.load_profile(PROFILE_PATH), true, "archive_cleared_profile_loads")
	t.call(reloaded.archived_item.is_empty(), true, "archive_cleared_stays_cleared")

	profile.free()
	loaded.free()
	reloaded.free()


func _test_profile_old_save_compat(t: Callable) -> void:
	# A v2 profile written before 归档 existed has no key at all.
	var old := ConfigFile.new()
	old.set_value("meta", "version", 2)
	old.set_value("progress", "memory_fragments", 12)
	old.save(PROFILE_PATH)
	var profile := Profile.new()
	t.call(profile.load_profile(PROFILE_PATH), true, "archive_old_profile_loads")
	t.call(profile.archived_item.is_empty(), true, "archive_old_profile_defaults_empty")
	t.call(profile.memory_fragments, 12, "archive_old_profile_keeps_progress")
	profile.free()
	_cleanup()

	# Malformed payloads must not wedge the slot or abort the rest of the load.
	var malformed := ConfigFile.new()
	malformed.set_value("meta", "version", 2)
	malformed.set_value("progress", "archived_item", {"kind": 5, "id": ["ink_heart"]})
	malformed.set_value("progress", "memory_fragments", 9)
	malformed.save(PROFILE_PATH)
	var bad := Profile.new()
	t.call(bad.load_profile(PROFILE_PATH), true, "archive_malformed_profile_loads")
	t.call(bad.archived_item.is_empty(), true, "archive_malformed_cleared")
	t.call(bad.memory_fragments, 9, "archive_malformed_keeps_progress")
	bad.free()
	_cleanup()

	var partial := ConfigFile.new()
	partial.set_value("meta", "version", 2)
	partial.set_value("progress", "archived_item", {"kind": "weapon"})
	partial.save(PROFILE_PATH)
	var missing_id := Profile.new()
	t.call(missing_id.load_profile(PROFILE_PATH), true, "archive_partial_profile_loads")
	t.call(missing_id.archived_item.is_empty(), true, "archive_partial_cleared")
	missing_id.free()


func _is_archived(profile: Profile, kind: String, id: String) -> bool:
	return String(profile.archived_item.get("kind", "")) == kind \
		and String(profile.archived_item.get("id", "")) == id


func _test_archive_choice_ui(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.paused = false
	var ui := ArchiveChoiceUI.new()
	tree.root.add_child(ui)
	var picked: Array[int] = []
	ui.chosen.connect(func(index: int): picked.append(index))
	var options: Array[Dictionary] = [
		{"kind": &"weapon", "id": &"ink_axe", "name": "墨斧", "desc": "武器 · 伤害 18"},
		{"kind": &"relic", "id": &"ink_heart", "name": "墨心", "desc": "遗物 · 每秒回墨"},
	]
	ui.open(options)
	t.call(ui.visible, true, "archive_ui_opens")
	t.call(ui.is_open(), true, "archive_ui_reports_open")
	t.call(ui.get_option_count(), 2, "archive_ui_option_count")
	t.call(ui.get_option_text(0).contains("墨斧"), true, "archive_ui_first_option_text")
	t.call(ui.get_option_text(1).contains("墨心"), true, "archive_ui_second_option_text")
	t.call(tree.paused, true, "archive_ui_pauses")
	# Focus is asserted by the integration suites: nodes added during
	# SceneTree._initialize are not inside the tree yet, so grab_focus is a
	# no-op here even though the same per-open path works in a live scene.
	t.call(ui._buttons.size(), 2, "archive_ui_buttons_match_options")
	ui._choose(1)
	t.call(picked, [1], "archive_ui_emits_choice")
	t.call(ui.visible, false, "archive_ui_closes")
	t.call(ui.is_open(), false, "archive_ui_reports_closed")
	t.call(tree.paused, false, "archive_ui_restores_pause")

	ui.open(options)
	t.call(tree.paused, true, "archive_ui_reopens_paused")
	ui._choose(-1)
	t.call(picked, [1, -1], "archive_ui_skip_emits_minus_one")
	t.call(not ui.is_open(), true, "archive_ui_skip_closes")
	t.call(tree.paused, false, "archive_ui_skip_unpauses")

	tree.root.remove_child(ui)
	ui.free()
	tree.paused = false


func _test_authority_choice_grid(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.paused = false
	var ui := AuthorityChoiceUI.new()
	tree.root.add_child(ui)
	var picked: Array[int] = []
	ui.chosen.connect(func(index: int): picked.append(index))
	var options: Array[AuthorityData] = [
		load(REVIVE_PATH) as AuthorityData,
		load(REWRITE_PATH) as AuthorityData,
		load(ARCHIVE_PATH) as AuthorityData,
		load(DEVOUR_PATH) as AuthorityData,
	]
	ui.open(options)
	t.call(ui.get_button_count(), 4, "authority_grid_four_options")
	t.call(ui._row.columns, 2, "authority_grid_two_columns")
	t.call(ui._buttons[2].text.contains("归档"), true, "authority_grid_archive_text")
	t.call(ui._buttons[3].text.contains("吞噬"), true, "authority_grid_devour_text")
	t.call(tree.paused, true, "authority_grid_pauses")
	ui._choose(3)
	t.call(picked, [3], "authority_grid_last_option_picks")
	t.call(tree.paused, false, "authority_grid_unpauses")
	tree.root.remove_child(ui)
	ui.free()
	tree.paused = false
