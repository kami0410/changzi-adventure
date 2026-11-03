extends RefCounted


func run(t: Callable) -> void:
	var scene = load("res://scenes/ui/codex.tscn")
	t.call(scene != null, true, "codex_forge_scene_loads")
	if scene == null:
		return

	var modifier := WordData.new()
	modifier.id = &"test_mod"
	modifier.glyph = "◇"
	modifier.meaning = "测试修饰"
	modifier.grammar_role = WordData.GrammarRole.MODIFIER
	modifier.power = 1
	modifier.decoded = true
	modifier.tags = [&"test"]
	modifier.components[&"damage"] = 2.0

	var noun := WordData.new()
	noun.id = &"test_noun"
	noun.glyph = "●"
	noun.meaning = "测试名词"
	noun.grammar_role = WordData.GrammarRole.NOUN
	noun.power = 1
	noun.decoded = true
	noun.tags = [&"test"]
	noun.components[&"heal"] = 2.0

	var run := RunState.new()
	run.reset_for_new_run(1)
	run.inventory.add_word(modifier)
	run.inventory.add_word(noun)

	var codex = scene.instantiate()
	codex.bind(PhraseResolver.new(), run)
	t.call(codex.get_word_card_count(), 2, "codex_forge_word_cards")

	codex._toggle_word(modifier)
	codex._toggle_word(noun)
	t.call(codex.get_forge_text().contains("言灵"), true, "codex_forge_valid_preview")

	codex._on_free_text_submitted("测试修饰与测试名词")
	t.call(codex.get_forge_text().contains("言灵"), true, "codex_free_text_preview")
	t.call(codex._last_forge_phrase != null, true, "codex_free_text_phrase")

	var received: Array = []
	codex.phrase_equip_requested.connect(func(slot, phrase): received.append([slot, phrase]))
	codex._request_equip(0)
	t.call(received.size(), 1, "codex_forge_equip_signal")
	t.call(received[0][0], 0, "codex_forge_slot")
	t.call(received[0][1] != null, true, "codex_forge_phrase")

	codex.free()
