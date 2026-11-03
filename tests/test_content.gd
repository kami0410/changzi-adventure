extends RefCounted


func run(t: Callable) -> void:
	var words := _load_all("res://resources/words")
	var phrases := _load_all("res://resources/phrases")
	t.call(words.size(), 95, "word_count")
	t.call(phrases.size(), 16, "phrase_count")

	var roles := [0, 0, 0]
	var word_ids: Dictionary = {}
	for word in words:
		t.call(word is WordData, true, "word_type")
		t.call(word.meaning.is_empty(), false, "word_meaning")
		roles[word.grammar_role] += 1
		word_ids[word.id] = true
	t.call(roles[0], 39, "noun_count")
	t.call(roles[1], 29, "verb_count")
	t.call(roles[2], 27, "modifier_count")

	for phrase in phrases:
		t.call(phrase is PhraseData, true, "phrase_type")
		t.call(phrase.word_ids.size() >= 2 and phrase.word_ids.size() <= 3, true, "phrase_word_count")
		for word_id in phrase.word_ids:
			t.call(word_ids.has(word_id), true, "phrase_word_exists")


func _load_all(path: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if file_name.ends_with(".tres"):
			var resource = load(path + "/" + file_name)
			if resource != null:
				result.append(resource)
	return result
