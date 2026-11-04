extends RefCounted

## Profile v2: old v1 saves keep their progress, new keys get defaults, and
## saves are written atomically with a backup.

const PATH := "user://test_profile_v2.cfg"


func run(t: Callable) -> void:
	_cleanup()
	_test_v1_migration(t)
	_cleanup()
	_test_discovered_phrase_migration(t)
	_cleanup()
	_test_v2_roundtrip(t)
	_test_atomic_backup(t)
	_cleanup()
	_test_backup_fallback(t)
	_cleanup()
	_test_malformed_fields(t)
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
	t.call(profile.master_volume, 1.0, "v1_master_volume_defaults_1")
	profile.free()


## v1 stored discovered combos as display meanings, which cannot be mapped to
## the current word-id signatures without guessing. The migration keeps those
## raw strings in a legacy bucket (data preserved, never shown or used) and
## only lets current "id1,id2|count" signatures reach the Codex.
func _test_discovered_phrase_migration(t: Callable) -> void:
	# A pure v1 save keeps all raw strings and activates none of them.
	var old_only := ConfigFile.new()
	old_only.set_value("meta", "version", 1)
	old_only.set_value("progress", "discovered_phrases", ["呓·火", "雷·霜·冠"])
	old_only.save(PATH)
	var v1_profile := Profile.new()
	t.call(v1_profile.load_profile(PATH), true, "v1_phrases_profile_loads")
	t.call(v1_profile.discovered_phrases, [], "v1_phrases_not_active")
	t.call(v1_profile.legacy_discovered_phrases, ["呓·火", "雷·霜·冠"], "v1_phrases_kept_verbatim")
	v1_profile.save_profile(PATH)
	var migrated := ConfigFile.new()
	t.call(migrated.load(PATH), OK, "v1_phrases_resave_loads")
	t.call(migrated.get_value("progress", "discovered_phrases", []), [], "v1_phrases_active_key_cleared")
	t.call(
		migrated.get_value("progress", "legacy_discovered_phrases", []),
		["呓·火", "雷·霜·冠"],
		"v1_phrases_written_to_legacy_key",
	)
	v1_profile.free()
	_cleanup()

	# Mixed saves: valid word-id signatures stay active, meaning-based ones
	# move to legacy storage without being duplicated.
	var mixed := ConfigFile.new()
	mixed.set_value("meta", "version", 2)
	mixed.set_value(
		"progress",
		"discovered_phrases",
		["gr,grguan|2", "火·雷", "ranshao,yan|2", "gr,grguan|2"],
	)
	mixed.save(PATH)
	var mixed_profile := Profile.new()
	t.call(mixed_profile.load_profile(PATH), true, "mixed_phrases_loads")
	t.call(
		mixed_profile.discovered_phrases,
		["gr,grguan|2", "ranshao,yan|2"],
		"mixed_phrases_only_current_format_active",
	)
	t.call(mixed_profile.legacy_discovered_phrases, ["火·雷"], "mixed_phrases_legacy_kept")
	t.call(mixed_profile.discover_phrase("火·雷"), false, "legacy_signature_not_discoverable")
	t.call(mixed_profile.discover_phrase("xue,yan|2"), true, "current_signature_discoverable")
	t.call(mixed_profile.discover_phrase("xue,yan|2"), false, "current_signature_deduplicates")
	mixed_profile.save_profile(PATH)
	mixed_profile.free()

	# Loading an already migrated save is idempotent: no reclassification of
	# the legacy bucket, no duplicates after another save/load cycle.
	var reloaded := Profile.new()
	t.call(reloaded.load_profile(PATH), true, "migrated_phrases_reload")
	t.call(
		reloaded.discovered_phrases,
		["gr,grguan|2", "ranshao,yan|2", "xue,yan|2"],
		"migrated_phrases_stable",
	)
	t.call(reloaded.legacy_discovered_phrases, ["火·雷"], "migrated_legacy_stable")
	reloaded.save_profile(PATH)
	reloaded.free()
	var again := Profile.new()
	t.call(again.load_profile(PATH), true, "migrated_phrases_second_reload")
	t.call(
		again.discovered_phrases,
		["gr,grguan|2", "ranshao,yan|2", "xue,yan|2"],
		"migrated_phrases_no_duplicates",
	)
	t.call(again.legacy_discovered_phrases, ["火·雷"], "migrated_legacy_no_duplicates")
	again.free()


func _test_v2_roundtrip(t: Callable) -> void:
	var profile := Profile.new()
	profile.memory_fragments = 42
	profile.decode_word(&"xue")
	profile.tutorial_done = true
	profile.demo_cleared = true
	profile.text_scale = 20
	profile.master_volume = 0.42
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
	t.call(loaded.master_volume, 0.42, "v2_master_volume_persists")
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


## The save routine copies the previous profile to `.bak` before renaming the
## new one into place. If the crash happens between those steps, the main file
## is gone and the backup is the only surviving copy; it must load as-is.
func _test_backup_fallback(t: Callable) -> void:
	var first := Profile.new()
	first.memory_fragments = 11
	first.save_profile(PATH)
	var second := Profile.new()
	second.memory_fragments = 22
	second.save_profile(PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	t.call(FileAccess.file_exists(PATH), false, "v2_fallback_main_missing")
	t.call(FileAccess.file_exists(PATH + ".bak"), true, "v2_fallback_backup_present")
	var recovered := Profile.new()
	t.call(recovered.load_profile(PATH), true, "v2_backup_only_loads")
	t.call(recovered.memory_fragments, 11, "v2_backup_only_contents")
	first.free()
	second.free()
	recovered.free()

	# A corrupt/truncated main file takes the same fallback path.
	_cleanup()
	var a := Profile.new()
	a.memory_fragments = 33
	a.save_profile(PATH)
	var b := Profile.new()
	b.memory_fragments = 44
	b.save_profile(PATH)
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("not a config file")
	file.close()
	var fallback := Profile.new()
	t.call(fallback.load_profile(PATH), true, "v2_corrupt_main_uses_backup")
	t.call(fallback.memory_fragments, 33, "v2_corrupt_main_backup_contents")
	# The recovered backup is promoted to the main path so the next save does
	# not copy the corrupt main over the only good copy.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".bak"))
	var promoted := Profile.new()
	t.call(promoted.load_profile(PATH), true, "v2_corrupt_main_promoted")
	t.call(promoted.memory_fragments, 33, "v2_promoted_contents")
	promoted.free()
	a.free()
	b.free()
	fallback.free()

	# With neither file there is nothing to recover, and no error state leaks.
	_cleanup()
	var missing := Profile.new()
	t.call(missing.load_profile(PATH), false, "v2_no_profile_no_backup_fails")
	missing.free()


## A correctly versioned file can still carry wrong-typed fields (hand edit or
## a partial migration). Loading must sanitize them instead of aborting midway
## and leaving the player without their starter words.
func _test_malformed_fields(t: Callable) -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 2)
	config.set_value("progress", "memory_fragments", "lots")
	config.set_value("progress", "unlocked_words", 5)
	config.set_value("progress", "decoded_words", "none")
	config.set_value("progress", "pending_run_bonuses", [1, 2])
	config.set_value("progress", "stored_relics", 7)
	config.set_value("progress", "archived_item", {"kind": "word", "id": "xue"})
	config.set_value("progress", "archive_levels", "nope")
	config.set_value("progress", "word_mastery", {"xue": "ten"})
	config.set_value("progress", "weapon_base_levels", {"broken_page_sword": []})
	config.set_value("progress", "discovered_phrases", [123, "xue,yan|2"])
	config.set_value("progress", "endings", [{}])
	config.set_value("settings", "text_scale", {})
	config.set_value("settings", "shake_scale", "max")
	config.set_value("settings", "master_volume", "loud")
	config.set_value("npc", "blessings", {"ayan": "not a dict"})
	config.set_value("npc", "trust", {"ayan": [1]})
	config.set_value("input", "keybinds", 5)
	config.set_value("input", "joybinds", {"jump": -3, "attack": "x"})
	config.save(PATH)

	var profile := Profile.new()
	t.call(profile.load_profile(PATH), true, "malformed_profile_loads")
	t.call(profile.memory_fragments, 0, "malformed_fragments_default")
	t.call(profile.is_word_unlocked(&"posui"), true, "malformed_defaults_restore_starter_words")
	t.call(profile.is_word_unlocked(&"xue"), true, "malformed_defaults_restore_fragments")
	t.call(profile.is_word_decoded(&"posui"), true, "malformed_decoded_falls_back_to_defaults")
	t.call(profile.pending_run_bonuses.is_empty(), true, "malformed_pending_bonuses_empty")
	t.call(profile.stored_relics.is_empty(), true, "malformed_stored_relics_empty")
	t.call(profile.archived_item.is_empty(), true, "malformed_archived_item_empty")
	t.call(profile.archive_levels.is_empty(), true, "malformed_archive_empty")
	t.call(profile.word_mastery_level(&"xue"), 0, "malformed_mastery_zero")
	t.call(profile.weapon_base_level(&"broken_page_sword"), 0, "malformed_weapon_base_zero")
	t.call(profile.text_scale, 16, "malformed_text_scale_default")
	t.call(profile.shake_scale, 1.0, "malformed_shake_default")
	t.call(profile.master_volume, 1.0, "malformed_master_volume_default")
	t.call(profile.npc_blessings.has("ayan"), false, "malformed_blessings_skipped")
	t.call(profile.npc_trust.has("ayan"), false, "malformed_trust_skipped")
	t.call(profile.keybinds.is_empty(), true, "malformed_keybinds_empty")
	t.call(profile.joybinds.is_empty(), true, "malformed_joybinds_empty")
	t.call(profile.discovered_phrases, ["xue,yan|2"], "malformed_phrases_keep_valid_entries")
	t.call(profile.legacy_discovered_phrases.is_empty(), true, "malformed_phrases_skip_non_strings")
	t.call(profile.endings.is_empty(), true, "malformed_endings_skipped")
	profile.free()

	config.set_value("settings", "master_volume", 3.5)
	config.save(PATH)
	var clamped := Profile.new()
	t.call(clamped.load_profile(PATH), true, "out_of_range_profile_loads")
	t.call(clamped.master_volume, 1.0, "master_volume_clamped_high")
	clamped.free()


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
