extends RefCounted

## The three Codex example sentences must work with no AI configuration at all:
## synthesize, equip and build a cast context from the offline pipeline.

const EXAMPLES: Array[String] = ["让雷落在火里", "把记忆烧成回声", "让时间停下来"]


func run(t: Callable) -> void:
	var original = SpellSynthesizer.remote_provider
	SpellSynthesizer.remote_provider = Callable()
	var profile := Profile.new()
	var known := RunLoot.starting_words(profile)
	var resolver := PhraseResolver.new()
	for text in EXAMPLES:
		var phrase := SpellSynthesizer.synthesize(text, known)
		t.call(phrase != null, true, "offline_synthesize_%s" % text)
		if phrase == null:
			continue
		t.call(phrase.words.size() > 0, true, "offline_words_%s" % text)
		t.call(String(phrase.spell.get(&"shape", &"")) != "", true, "offline_shape_%s" % text)
		t.call(phrase.ink_cost > 0, true, "offline_ink_cost_%s" % text)
		var words: Array[WordData] = []
		for word in phrase.words:
			words.append(word as WordData)
		t.call(resolver.resolve(words) != null, true, "offline_resolve_%s" % text)
		var caster := PhraseCaster.new()
		t.call(caster.equip_phrase(0, phrase), true, "offline_equip_%s" % text)
		t.call(caster._build_context(phrase) != null, true, "offline_cast_context_%s" % text)
		caster.free()

	var invoked := [false]
	SpellSynthesizer.remote_provider = func(_text: String) -> Dictionary:
		invoked[0] = true
		return {}
	var with_ai := SpellSynthesizer.synthesize("让雷落在火里", known)
	t.call(invoked[0], true, "configured_provider_is_consulted")
	t.call(with_ai != null, true, "empty_ai_payload_falls_back_offline")
	SpellSynthesizer.remote_provider = original
	profile.free()
