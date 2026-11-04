extends RefCounted

## Mid-run checkpoint format: atomic writes, backup recovery, safe rejection of
## corrupt files, and word/phrase serialization that survives wild words.

const PATH := "user://test_run_save.cfg"


func run(t: Callable) -> void:
	_cleanup()
	_test_missing(t)
	_test_roundtrip(t)
	_test_corrupt(t)
	_test_unknown_version(t)
	_test_malformed_shape(t)
	_test_backup_recovery(t)
	_test_backup_promotion(t)
	_test_word_phrase_roundtrip(t)
	_test_synthesized_phrase_roundtrip(t)
	_test_content_lookups(t)
	_cleanup()


func _cleanup() -> void:
	RunSave.clear(PATH)


func _sample_data(room: String = "ch1_03") -> Dictionary:
	return {
		"version": RunSave.SAVE_VERSION,
		"run": {
			"seed": 12345,
			"difficulty": 1,
			"chapter": 0,
			"room": room,
			"health": 73,
			"max_health": 130,
			"pages": 21,
		},
		"progress": {"cleared_in_chapter": 2, "cleared_rooms": ["ch1_01"], "vaults": []},
		"inventory": {"words": [], "weapons": [null, null], "relics": [], "phrases": [{}, {}]},
		"authority": {},
		"world": {"boss_defeated": false},
		"mds": {"room": room, "position": [512.0, 530.0], "visited": ["ch1_01", room]},
	}


func _test_missing(t: Callable) -> void:
	t.call(RunSave.has_save(PATH), false, "run_save_missing_has_save")
	t.call(RunSave.read(PATH).is_empty(), true, "run_save_missing_reads_empty")


func _test_roundtrip(t: Callable) -> void:
	var source := _sample_data()
	t.call(RunSave.write(source, PATH), true, "run_save_writes")
	t.call(FileAccess.file_exists(PATH), true, "run_save_file_exists")
	t.call(RunSave.has_save(PATH), true, "run_save_has_save")
	var loaded := RunSave.read(PATH)
	t.call(loaded.is_empty(), false, "run_save_reads")
	t.call(int(loaded.get("version", 0)), RunSave.SAVE_VERSION, "run_save_version")
	var run: Dictionary = loaded.get("run", {})
	t.call(int(run.get("seed", 0)), 12345, "run_save_seed")
	t.call(String(run.get("room", "")), "ch1_03", "run_save_room")
	t.call(int(run.get("health", 0)), 73, "run_save_health")
	var mds: Dictionary = loaded.get("mds", {})
	t.call(String(mds.get("room", "")), "ch1_03", "run_save_mds_room")
	RunSave.clear(PATH)
	t.call(RunSave.has_save(PATH), false, "run_save_clear")


func _test_corrupt(t: Callable) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("this is not a checkpoint")
	file.close()
	var loaded := RunSave.read(PATH)
	t.call(loaded.is_empty(), true, "run_save_corrupt_rejected")
	t.call(FileAccess.file_exists(PATH), false, "run_save_corrupt_removed")


func _test_unknown_version(t: Callable) -> void:
	var data := _sample_data()
	data["version"] = 999
	RunSave.write(data, PATH)
	t.call(RunSave.read(PATH).is_empty(), true, "run_save_unknown_version_rejected")
	t.call(FileAccess.file_exists(PATH), false, "run_save_unknown_version_removed")


func _test_malformed_shape(t: Callable) -> void:
	var cases := [
		{"progress": "garbage"},
		{"world": 5},
		{"authority": [1, 2]},
		{"mds": "nope"},
		{"run": {"room": "ch1_03", "health": []}},
		{"inventory": {"words": [], "weapons": [], "relics": [], "phrases": "bad"}},
		{"mds": {"room": "ch1_03", "position": [512.0]}},
		{"mds": {"room": "ch1_03", "areas": []}},
		{"authority": {"id": "archive", "archive_used": "yes"}},
	]
	for index in cases.size():
		_cleanup()
		var data := _sample_data()
		var patch: Dictionary = cases[index]
		for key in patch:
			data[key] = patch[key]
		RunSave.write(data, PATH)
		t.call(RunSave.read(PATH).is_empty(), true, "run_save_malformed_rejected_%d" % index)
		t.call(FileAccess.file_exists(PATH), false, "run_save_malformed_removed_%d" % index)

	# Optional sections may be absent; only their types are enforced.
	_cleanup()
	RunSave.write({"version": RunSave.SAVE_VERSION, "run": {"room": "ch1_01"}, "inventory": {}}, PATH)
	t.call(RunSave.read(PATH).is_empty(), false, "run_save_minimal_shape_accepted")
	_cleanup()

	# A checkpoint written before 归档 existed has no archive_used key; it must
	# still load and default the flag to false instead of being discarded.
	var legacy_authority := _sample_data()
	legacy_authority["authority"] = {
		"id": "archive",
		"revive_used": false,
		"rewrite_used": false,
	}
	RunSave.write(legacy_authority, PATH)
	var legacy_loaded := RunSave.read(PATH)
	t.call(legacy_loaded.is_empty(), false, "run_save_legacy_authority_accepted")
	t.call(bool(legacy_loaded.get("authority", {}).get("archive_used", false)), false,
		"run_save_legacy_archive_defaults_false")
	_cleanup()


func _test_backup_recovery(t: Callable) -> void:
	# First write is the backup once the second write replaces the main file.
	RunSave.write(_sample_data("ch1_02"), PATH)
	RunSave.write(_sample_data("ch1_05"), PATH)
	t.call(FileAccess.file_exists(PATH + ".bak"), true, "run_save_keeps_backup")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	t.call(RunSave.has_save(PATH), true, "run_save_backup_counts_as_save")
	var loaded := RunSave.read(PATH)
	t.call(loaded.is_empty(), false, "run_save_backup_reads")
	var run: Dictionary = loaded.get("run", {})
	t.call(String(run.get("room", "")), "ch1_02", "run_save_backup_contents")

	# A truncated/corrupt main file must recover the backup instead of
	# discarding both copies.
	RunSave.write(_sample_data("ch1_02"), PATH)
	RunSave.write(_sample_data("ch1_05"), PATH)
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("truncated checkpoint")
	file.close()
	var recovered := RunSave.read(PATH)
	t.call(recovered.is_empty(), false, "run_save_corrupt_main_reads_backup")
	var recovered_run: Dictionary = recovered.get("run", {})
	t.call(String(recovered_run.get("room", "")), "ch1_02", "run_save_corrupt_main_backup_contents")
	RunSave.clear(PATH)


func _test_backup_promotion(t: Callable) -> void:
	_cleanup()
	RunSave.write(_sample_data("ch1_02"), PATH)
	RunSave.write(_sample_data("ch1_05"), PATH)
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("truncated checkpoint")
	file.close()
	var recovered := RunSave.read(PATH)
	t.call(String(recovered.get("run", {}).get("room", "")), "ch1_02", "run_save_promotion_reads_backup")
	# The recovered backup must now be the main file, not just an in-memory dict.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".bak"))
	var repaired := RunSave.read(PATH)
	t.call(String(repaired.get("run", {}).get("room", "")), "ch1_02", "run_save_promotes_backup_to_main")

	# The next checkpoint must not copy a corrupt main over the good backup.
	_cleanup()
	RunSave.write(_sample_data("ch1_02"), PATH)
	RunSave.write(_sample_data("ch1_05"), PATH)
	file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("truncated checkpoint")
	file.close()
	RunSave.read(PATH)
	RunSave.write(_sample_data("ch1_06"), PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var after := RunSave.read(PATH)
	t.call(String(after.get("run", {}).get("room", "")), "ch1_02", "run_save_next_write_keeps_valid_backup")
	_cleanup()


func _test_word_phrase_roundtrip(t: Callable) -> void:
	var resolver := PhraseResolver.new()
	var words: Array[WordData] = []
	for id in [&"ranshao", &"yan"]:
		var word := ContentLibrary.word_by_id(id)
		t.call(word != null, true, "run_save_word_%s_exists" % String(id))
		if word != null:
			words.append(WordRuntime.for_run(word, null))
	var phrase := resolver.resolve(words)
	t.call(phrase != null, true, "run_save_phrase_resolves")
	if phrase == null:
		return
	var data := RunSave.phrase_to_dict(phrase)
	var restored := RunSave.phrase_from_dict(data, resolver)
	t.call(restored != null, true, "run_save_phrase_restores")
	if restored != null:
		t.call(restored.signature, phrase.signature, "run_save_phrase_signature")
		t.call(restored.display_name, phrase.display_name, "run_save_phrase_display_name")
		t.call(restored.ink_cost, phrase.ink_cost, "run_save_phrase_ink_cost")
		t.call(restored.words.size(), phrase.words.size(), "run_save_phrase_word_count")


func _test_synthesized_phrase_roundtrip(t: Callable) -> void:
	var resolver := PhraseResolver.new()
	var known: Array[WordData] = []
	for word in ContentLibrary.WORDS:
		known.append(WordRuntime.for_run(word as WordData, null))
	var phrase := SpellSynthesizer.synthesize("把未记载的星火写进梦里", known)
	t.call(phrase != null, true, "run_save_synth_phrase")
	if phrase == null:
		return
	var restored := RunSave.phrase_from_dict(RunSave.phrase_to_dict(phrase), resolver)
	t.call(restored != null, true, "run_save_synth_restores")
	if restored != null:
		t.call(restored.signature, phrase.signature, "run_save_synth_signature")
		t.call(restored.ink_cost, phrase.ink_cost, "run_save_synth_ink_cost")


func _test_content_lookups(t: Callable) -> void:
	t.call(ContentLibrary.word_by_id(&"ranshao") != null, true, "run_save_lookup_word")
	t.call(ContentLibrary.word_by_id(&"missing_word") == null, true, "run_save_lookup_word_missing")
	t.call(ContentLibrary.weapon_by_id(&"broken_page_sword") != null, true, "run_save_lookup_weapon")
	t.call(ContentLibrary.authority_by_id(&"revive") != null, true, "run_save_lookup_authority")
