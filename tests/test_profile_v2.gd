extends RefCounted

## Profile v2: old v1 saves keep their progress, new keys get defaults, and
## saves are written atomically with a backup.

const PATH := "user://test_profile_v2.cfg"


func run(t: Callable) -> void:
	_cleanup()
	_test_v1_migration(t)
	_cleanup()
	_test_v2_roundtrip(t)
	_test_atomic_backup(t)
	_cleanup()
	_test_corrupt_and_unknown_version(t)
	_cleanup()


func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _test_v1_migration(t: Callable) -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 1)
	config.set_value("progress", "memory_fragments", 77)
	config.set_value("progress", "unlocked_words", [&"lei"])
	config.set_value("progress", "endings", ["restored"])
	config.set_value("progress", "archive_levels", {"vitality": 2})
	config.save(PATH)
	var profile := Profile.new()
	t.call(profile.load_profile(PATH), true, "v1_profile_loads")
	t.call(profile.memory_fragments, 77, "v1_fragments_preserved")
	t.call(profile.is_word_unlocked(&"lei"), true, "v1_owned_word_preserved")
	t.call(profile.endings.has("restored"), true, "v1_endings_preserved")
	t.call(profile.archive_level(&"vitality"), 2, "v1_archive_preserved")
	t.call(profile.is_word_decoded(&"posui"), true, "v1_gets_default_decoded")
	t.call(profile.tutorial_done, false, "v1_tutorial_defaults_false")
	t.call(profile.pending_run_bonuses.is_empty(), true, "v1_pending_defaults_empty")
	t.call(profile.demo_cleared, false, "v1_demo_cleared_defaults_false")
	t.call(profile.text_scale, 16, "v1_text_scale_defaults_16")
	profile.free()


func _test_v2_roundtrip(t: Callable) -> void:
	var profile := Profile.new()
	profile.memory_fragments = 42
	profile.decode_word(&"xue")
	profile.tutorial_done = true
	profile.demo_cleared = true
	profile.text_scale = 20
	profile.add_pending_run_bonus(&"start_pages", 8.0)
	profile.add_pending_run_bonus(&"start_corruption", 3.0)
	profile.save_profile(PATH)
	var loaded := Profile.new()
	t.call(loaded.load_profile(PATH), true, "v2_profile_loads")
	t.call(loaded.memory_fragments, 42, "v2_fragments_persist")
	t.call(loaded.is_word_decoded(&"xue"), true, "v2_decoded_persists")
	t.call(loaded.tutorial_done, true, "v2_tutorial_persists")
	t.call(loaded.demo_cleared, true, "v2_demo_cleared_persists")
	t.call(loaded.text_scale, 20, "v2_text_scale_persists")
	t.call(loaded.pending_run_bonuses.get("start_pages", 0.0), 8.0, "v2_pending_persists")
	profile.free()
	loaded.free()


func _test_atomic_backup(t: Callable) -> void:
	var first := Profile.new()
	first.memory_fragments = 1
	first.save_profile(PATH)
	t.call(FileAccess.file_exists(PATH), true, "v2_writes_profile")
	t.call(not FileAccess.file_exists(PATH + ".tmp"), true, "v2_leaves_no_tmp")
	var second := Profile.new()
	second.memory_fragments = 2
	second.save_profile(PATH)
	t.call(FileAccess.file_exists(PATH + ".bak"), true, "v2_keeps_backup")
	t.call(not FileAccess.file_exists(PATH + ".tmp"), true, "v2_second_write_no_tmp")
	var latest := Profile.new()
	latest.load_profile(PATH)
	t.call(latest.memory_fragments, 2, "v2_rename_writes_latest")
	first.free()
	second.free()
	latest.free()


func _test_corrupt_and_unknown_version(t: Callable) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("this is not a config file")
	file.close()
	var corrupt := Profile.new()
	t.call(corrupt.load_profile(PATH), false, "corrupt_profile_fails_cleanly")
	corrupt.free()
	_cleanup()
	var config := ConfigFile.new()
	config.set_value("meta", "version", 99)
	config.set_value("progress", "unlocked_words", [&"guang"])
	config.save(PATH)
	var future := Profile.new()
	t.call(future.load_profile(PATH), true, "unknown_version_still_loads")
	t.call(future.is_word_unlocked(&"guang"), true, "unknown_version_keeps_known_keys")
	future.free()
