extends RefCounted

## Discovered phrases are cross-run Profile state keyed by a stable word-id
## signature, and the Codex can show them again in a fresh run.

const PATH := "user://test_phrase_persistence.cfg"


func run(t: Callable) -> void:
	_test_stable_signature(t)
	_test_profile_persistence(t)
	_test_codex_persistent(t)


func _words() -> Array[WordData]:
	var result: Array[WordData] = [
		load("res://resources/words/ranshao.tres") as WordData,
		load("res://resources/words/yan.tres") as WordData,
	]
	return result


func _test_stable_signature(t: Callable) -> void:
	var resolver := PhraseResolver.new()
	var words := _words()
	var forward := resolver.resolve(words)
	var reversed_words: Array[WordData] = [words[1], words[0]]
	var reversed := resolver.resolve(reversed_words)
	t.call(forward != null and reversed != null, true, "signature_phrases_resolve")
	if forward == null or reversed == null:
		return
	t.call(forward.signature, reversed.signature, "signature_is_order_independent")
	t.call(forward.signature.ends_with("|2"), true, "signature_contains_word_count")
	t.call(forward.signature.contains("ranshao") and forward.signature.contains("yan"), true, "signature_uses_word_ids")


func _test_profile_persistence(t: Callable) -> void:
	var absolute := ProjectSettings.globalize_path(PATH)
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(absolute)
	var phrase := PhraseResolver.new().resolve(_words())
	var profile := Profile.new()
	t.call(profile.discover_phrase(phrase.signature), true, "discover_phrase_records")
	t.call(profile.discover_phrase(phrase.signature), false, "discover_phrase_deduplicates")
	profile.save_profile(PATH)
	var loaded := Profile.new()
	t.call(loaded.load_profile(PATH), true, "discovered_profile_loads")
	t.call(loaded.discovered_phrases.has(phrase.signature), true, "discovered_phrase_persists")
	profile.free()
	loaded.free()
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(absolute)


func _test_codex_persistent(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var codex := preload("res://scenes/ui/codex.tscn").instantiate() as CodexUI
	tree.root.add_child(codex)
	var resolver := PhraseResolver.new()
	var run_state := RunState.new()
	run_state.reset_for_new_run(3)
	var phrase := resolver.resolve(_words())
	codex.bind(resolver, run_state)
	codex.set_discovered([])
	codex.set_persistent_discovered([phrase.signature])
	codex.refresh()
	var lines := codex.get_combo_lines()
	t.call(lines.size(), 1, "codex_shows_persisted_combo")
	if not lines.is_empty():
		t.call(String(lines[0]).contains(phrase.display_name), true, "codex_persisted_combo_name")
	tree.root.remove_child(codex)
	codex.free()
