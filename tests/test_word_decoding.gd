extends RefCounted

## Decoding is cross-run Profile state. Per-run copies read it; the shared
## WordData .tres must never be mutated (no save-slot bleed).

const LEI_PATH := "res://resources/words/lei.tres"
const TEST_PATH := "user://test_word_decoding.cfg"


func run(t: Callable) -> void:
	_test_defaults(t)
	_test_runtime_copy(t)
	_test_resolver_unstable(t)
	_test_starting_fragments(t)
	_test_save_load(t)
	_test_v1_migration(t)


func _cleanup() -> void:
	var absolute := ProjectSettings.globalize_path(TEST_PATH)
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(absolute)


func _test_defaults(t: Callable) -> void:
	var profile := Profile.new()
	t.call(profile.is_word_decoded(&"posui"), true, "starter_word_decoded_by_default")
	t.call(profile.is_word_decoded(&"lei"), false, "non_starter_word_undecoded_by_default")
	profile.free()


func _test_runtime_copy(t: Callable) -> void:
	var profile := Profile.new()
	var source := load(LEI_PATH) as WordData
	var shared_decoded := source.decoded
	var copy := WordRuntime.for_run(source, profile)
	t.call(copy != source, true, "runtime_word_is_a_copy")
	t.call(copy.decoded, false, "undecoded_word_copy_is_locked")
	t.call(source.decoded, shared_decoded, "shared_resource_not_mutated")

	t.call(profile.decode_word(&"lei"), true, "decode_word_succeeds")
	t.call(profile.is_word_decoded(&"lei"), true, "profile_records_decoding")
	t.call(profile.is_word_unlocked(&"lei"), true, "decoding_implies_owned")
	t.call(profile.decode_word(&"lei"), false, "decode_word_is_idempotent")
	var decoded_copy := WordRuntime.for_run(source, profile)
	t.call(decoded_copy.decoded, true, "decoded_word_copy_is_readable")
	t.call(source.decoded, shared_decoded, "shared_resource_still_not_mutated")
	profile.free()


func _test_resolver_unstable(t: Callable) -> void:
	var profile := Profile.new()
	var word := WordRuntime.for_run(load(LEI_PATH) as WordData, profile)
	var words: Array[WordData] = [word]
	var phrase := PhraseResolver.new().resolve(words)
	t.call(phrase != null, true, "undecoded_word_still_resolves")
	t.call(phrase.unstable, true, "undecoded_word_phrase_is_unstable")
	t.call(phrase.corruption_gain >= 3, true, "undecoded_word_adds_corruption")
	t.call(phrase.display_name, word.glyph, "undecoded_name_uses_glyph")
	profile.free()


func _test_starting_fragments(t: Callable) -> void:
	var words := RunLoot.starting_words(Profile.new())
	var decoded := 0
	var locked := 0
	for word in words:
		if word.decoded:
			decoded += 1
		else:
			locked += 1
	t.call(decoded, 6, "six_words_start_decoded")
	t.call(locked, 12, "twelve_fragment_words_start_locked")
	t.call(words.size(), 18, "starting_pool_is_six_plus_twelve")


func _test_save_load(t: Callable) -> void:
	_cleanup()
	var profile := Profile.new()
	profile.decode_word(&"lei")
	profile.unlock_word(&"fengbao")
	profile.save_profile(TEST_PATH)
	t.call(FileAccess.file_exists(TEST_PATH), true, "profile_saves_decoded_words")
	var loaded := Profile.new()
	t.call(loaded.load_profile(TEST_PATH), true, "profile_loads_decoded_words")
	t.call(loaded.is_word_decoded(&"lei"), true, "decoded_word_persists")
	t.call(loaded.is_word_unlocked(&"fengbao"), true, "owned_word_persists")
	profile.free()
	loaded.free()
	_cleanup()


func _test_v1_migration(t: Callable) -> void:
	_cleanup()
	var config := ConfigFile.new()
	config.set_value("meta", "version", 1)
	config.set_value("progress", "unlocked_words", [&"lei"])
	config.save(TEST_PATH)
	var profile := Profile.new()
	t.call(profile.load_profile(TEST_PATH), true, "v1_profile_loads")
	t.call(profile.is_word_decoded(&"posui"), true, "v1_gets_default_decoded_words")
	t.call(profile.is_word_decoded(&"lei"), false, "v1_owned_word_stays_locked")
	t.call(profile.is_word_unlocked(&"lei"), true, "v1_owned_word_is_preserved")
	profile.free()
	_cleanup()
