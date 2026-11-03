extends RefCounted


func run(t: Callable) -> void:
	var resolver := PhraseResolver.new()

	var life := _make_word(&"gr", WordData.GrammarRole.NOUN, [&"life"], 1, true)
	life.components[&"heal"] = 3.0
	var archive := _make_word(&"grguan", WordData.GrammarRole.VERB, [&"archive"], 2, true)
	archive.components[&"damage"] = 2.0
	var abyss := _make_word(&"chinao", WordData.GrammarRole.MODIFIER, [&"abyss"], 3, true)
	var corruption := _make_word(&"grlufai", WordData.GrammarRole.MODIFIER, [&"corruption"], 2, true)
	var authority := _make_word(&"zhiguan", WordData.GrammarRole.VERB, [&"authority"], 2, true)
	var time := _make_word(&"guanzilu", WordData.GrammarRole.NOUN, [&"time"], 2, true)

	var single := resolver.resolve([life] as Array[WordData])
	t.call(single != null, true, "single_word_is_valid")
	t.call(single.word_count, 1, "single_word_count")
	t.call(single.spell.get(&"shape", &""), &"ward", "single_life_becomes_ward")

	var any_order: Array[WordData] = [archive, life]
	var order_a := resolver.resolve(any_order)
	var order_b := resolver.resolve([life, archive] as Array[WordData])
	t.call(order_a != null and order_b != null, true, "word_order_no_longer_restricts_grammar")
	t.call(order_a.components.get(&"lifesteal", 0.0) > 0.0, true, "life_archive_resonance")
	t.call(order_b.display_name, "gr·grguan", "order_is_preserved_in_name")

	var passive: Array[WordData] = [abyss, life]
	var passive_phrase := resolver.resolve(passive)
	t.call(passive_phrase != null, true, "any_two_words_are_valid")
	t.call(passive_phrase.unstable, true, "life_abyss_unstable")
	t.call(passive_phrase.corruption_gain >= 6, true, "life_abyss_corruption")

	var triple: Array[WordData] = [time, archive, life]
	var triple_phrase := resolver.resolve(triple)
	t.call(triple_phrase != null, true, "three_word_valid")
	t.call(triple_phrase.ink_cost > 6 + (2 + 2 + 1) * 3, true, "ink_cost_from_power_and_complexity")
	t.call(triple_phrase.cooldown > 1.6, true, "cooldown_from_power")

	var four: Array[WordData] = [time, archive, life, abyss]
	t.call(resolver.resolve(four) != null, true, "four_word_valid")
	var five: Array[WordData] = [time, archive, life, abyss, corruption]
	t.call(resolver.validation_error(five), &"too_many", "five_words_too_many")

	var duplicate: Array[WordData] = [life, life]
	var duplicated := resolver.resolve(duplicate)
	t.call(duplicated != null, true, "duplicate_words_allowed")
	t.call(duplicated.word_count, 2, "duplicate_word_count")
	t.call(duplicated.corruption_gain > 0, true, "duplicate_has_cost")
	var duplicated_heal: float = duplicated.components.get(&"heal", 0.0)
	t.call(duplicated_heal > 4.0 and duplicated_heal < 5.0, true, "duplicate_diminishing")

	var purify := _make_word(&"jinghua", WordData.GrammarRole.VERB, [&"holy", &"life", &"purify"], 2, true)
	purify.components[&"purify"] = 4.0
	var purify_phrase := resolver.resolve([purify] as Array[WordData])
	t.call(purify_phrase.components.get(&"purify", 0.0) >= 6.0, true, "purify_word_cleanses")
	t.call(purify_phrase.corruption_gain, 0, "purify_word_adds_no_corruption")
	var water := _make_word(&"shui", WordData.GrammarRole.NOUN, [&"water"], 1, true)
	var wash_phrase := resolver.resolve([purify, water] as Array[WordData])
	t.call(wash_phrase.components.get(&"purify", 0.0) > purify_phrase.components.get(&"purify", 0.0), true, "purify_water_resonance")

	var corrupted: Array[WordData] = [corruption, authority, life]
	var corrupted_phrase := resolver.resolve(corrupted)
	t.call(corrupted_phrase != null, true, "corruption_authority_valid")
	t.call(corrupted_phrase.components.get(&"damage", 0.0) >= 4.0, true, "corruption_authority_damage")

	var undecoded := _make_word(&"unknown", WordData.GrammarRole.MODIFIER, [&"void"], 1, false)
	var risky: Array[WordData] = [undecoded, life]
	var risky_phrase := resolver.resolve(risky)
	t.call(risky_phrase != null, true, "undecoded_can_resolve")
	t.call(risky_phrase.unstable, true, "undecoded_unstable")
	t.call(risky_phrase.corruption_gain >= 3, true, "undecoded_corruption")
	t.call(risky_phrase.display_name.contains("✶"), true, "undecoded_uses_glyph")

	t.call(resolver.validation_error([]), &"too_few", "error_too_few")
	t.call(resolver.validation_error([life, null] as Array[WordData]), &"null_word", "error_null_word")
	t.call(resolver.resolve([]), null, "invalid_resolve_null")


func _make_word(id: StringName, role: WordData.GrammarRole, tags: Array[StringName], power: int, decoded: bool) -> WordData:
	var word := WordData.new()
	word.id = id
	word.glyph = "✶"
	word.meaning = String(id)
	word.grammar_role = role
	word.tags = tags
	word.power = power
	word.decoded = decoded
	return word
