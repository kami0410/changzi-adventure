extends RefCounted


func run(t: Callable) -> void:
	var word := WordData.new()
	word.id = &"gr"
	word.grammar_role = WordData.GrammarRole.NOUN
	word.tags = [&"life"]
	word.power = 2
	word.components[&"heal"] = 4.0
	t.call(word.tags.has(&"life"), true, "word_tags")
	t.call(word.grammar_role, WordData.GrammarRole.NOUN, "word_role")
	t.call(word.components[&"heal"], 4.0, "word_components")

	var phrase := PhraseData.new()
	phrase.word_ids = [&"grguan", &"gr"]
	t.call(phrase.word_ids.size(), 2, "phrase_word_count")

	var weapon := WeaponData.new()
	t.call(weapon.kind, WeaponData.Kind.MELEE, "weapon_default_kind")

	var table := DropTable.new()
	var entry := DropEntry.new()
	entry.id = &"word_gr"
	entry.weight = 1.0
	table.entries.append(entry)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	t.call(table.roll(rng), &"word_gr", "drop_table_single")

	var resolved := ResolvedPhrase.new()
	resolved.display_name = "记录生命"
	resolved.words.append(word)
	resolved.components[&"heal"] = 4.0
	t.call(resolved.display_name, "记录生命", "resolved_phrase_name")
	t.call(resolved.words.size(), 1, "resolved_phrase_words")
