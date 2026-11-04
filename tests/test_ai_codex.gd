extends RefCounted

## AI is a preview enhancer in the Codex, not a second cast: a reply replaces
## the offline preview, a stale reply is ignored, and a failure leaves the
## offline phrase untouched. Nothing is equipped automatically either way.


func run(t: Callable) -> void:
	var scene = load("res://scenes/ui/codex.tscn")
	t.call(scene != null, true, "ai_codex_scene_loads")
	if scene == null:
		return

	var modifier := WordData.new()
	modifier.id = &"ai_test_flame"
	modifier.glyph = "焰"
	modifier.meaning = "测试火焰"
	modifier.grammar_role = WordData.GrammarRole.MODIFIER
	modifier.power = 1
	modifier.decoded = true
	modifier.tags = [&"flame"]
	modifier.components[&"damage"] = 2.0

	var noun := WordData.new()
	noun.id = &"ai_test_noun"
	noun.glyph = "刃"
	noun.meaning = "测试魔刃"
	noun.grammar_role = WordData.GrammarRole.NOUN
	noun.power = 1
	noun.decoded = true
	noun.tags = [&"flame"]
	noun.components[&"damage"] = 2.0

	var run_state := RunState.new()
	run_state.reset_for_new_run(3)
	run_state.inventory.add_word(modifier)
	run_state.inventory.add_word(noun)

	var codex = scene.instantiate()
	codex.bind(PhraseResolver.new(), run_state)
	var sentence := "测试火焰与测试魔刃"
	codex._free_text.text = sentence
	codex._on_free_text_submitted(sentence)
	var offline: ResolvedPhrase = codex._last_forge_phrase
	t.call(offline != null, true, "ai_codex_offline_preview_exists")

	var equips := 0
	codex.phrase_equip_requested.connect(func(_slot, _phrase): equips += 1)
	var intent := {
		"name": "AI 雷火",
		"shape": "flame",
		"tags": ["flame"],
		"confidence": 0.9,
		"components": {"damage": 7},
	}
	codex._on_ai_intent(sentence, intent)
	var ai_phrase: ResolvedPhrase = codex._last_forge_phrase
	t.call(ai_phrase != null and ai_phrase != offline, true, "ai_codex_replaces_offline_preview")
	if ai_phrase != null:
		t.call(ai_phrase.display_name, "AI 雷火", "ai_codex_uses_ai_name")
		t.call(float(ai_phrase.components.get(&"damage", 0.0)), 7.0, "ai_codex_applies_intent_once")
	t.call(equips, 0, "ai_codex_does_not_auto_equip")

	# A reply for an older sentence must not overwrite the current preview.
	codex._free_text.text = "另一句话"
	codex._on_ai_intent(sentence, intent)
	t.call(codex._last_forge_phrase, ai_phrase, "ai_codex_stale_reply_ignored")
	t.call(codex._ai_status.text.contains("上一句"), true, "ai_codex_stale_status")

	# Failure is silent for gameplay: the offline/AI preview remains usable.
	var before_failure: ResolvedPhrase = codex._last_forge_phrase
	codex._on_ai_failed("另一句话", "超时")
	t.call(codex._last_forge_phrase, before_failure, "ai_codex_failure_keeps_preview")
	t.call(codex._ai_status.text.contains("保留离线推演"), true, "ai_codex_failure_status")

	# An intent that fails local compilation also leaves the preview alone.
	codex._free_text.text = sentence
	codex._on_ai_intent(sentence, {"name": "坏意图", "tags": []})
	t.call(codex._last_forge_phrase, before_failure, "ai_codex_invalid_intent_keeps_preview")
	t.call(codex._ai_status.text.contains("本地校验"), true, "ai_codex_invalid_intent_status")

	codex.free()
