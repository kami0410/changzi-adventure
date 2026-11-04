extends RefCounted

const WORD_CARD_LOCKED: StyleBox = preload("res://resources/ui/word_card_locked.tres")
const WORD_CARD_DECODED: StyleBox = preload("res://resources/ui/word_card_decoded.tres")
const COMBO_CARD: StyleBox = preload("res://resources/ui/combo_card.tres")


func run(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var codex := preload("res://scenes/ui/codex.tscn").instantiate() as CodexUI
	tree.root.add_child(codex)
	_assert_fits_viewport(t, codex.find_child("Panel", true, false), "codex_panel")

	var resolver := PhraseResolver.new()
	var run_state := RunState.new()
	run_state.reset_for_new_run(11)

	var sealed := _make_word(&"grguan", "✶", "记录", WordData.GrammarRole.VERB, [&"archive"], false)
	var known := _make_word(&"gr", "ᚷ", "生命", WordData.GrammarRole.NOUN, [&"life"], true)
	run_state.inventory.add_word(sealed)
	run_state.inventory.add_word(known)

	codex.bind(resolver, run_state)
	# No discovered combos yet: the page shows the run-seed empty-state line.
	var combos_list := codex.find_child("CombosList", true, false) as VBoxContainer
	var empty_combo := combos_list.get_child(0) as Label
	t.call(empty_combo != null, true, "codex_empty_combo_label")
	t.call(empty_combo != null and empty_combo.text
		== EmptyStateData.pick(&"codex_combos", run_state.run_seed), true,
		"codex_empty_combo_copy")
	var word_lines := codex.get_word_lines()
	t.call(word_lines.size(), 2, "codex_word_count")
	t.call(codex.get_word_card_count(), 2, "codex_word_card_count")
	t.call(word_lines[0].contains("✶"), true, "codex_undecoded_shows_glyph")
	t.call(word_lines[0].contains("记录"), false, "codex_undecoded_hides_meaning")
	t.call(word_lines[1].contains("生命"), true, "codex_decoded_shows_meaning")
	t.call(word_lines[1].contains("ᚷ"), false, "codex_decoded_hides_glyph")

	var grid := codex.find_child("WordGrid", true, false) as GridContainer
	var locked_card := grid.get_child(0) as PanelContainer
	var decoded_card := grid.get_child(1) as PanelContainer
	t.call(locked_card.get_theme_stylebox("panel"), WORD_CARD_LOCKED, "codex_locked_card_style")
	t.call(decoded_card.get_theme_stylebox("panel"), WORD_CARD_DECODED, "codex_decoded_card_style")
	# Cards are filled after entering the tree (cheap text shaping); the real
	# labels must still show the word once the refresh returns.
	t.call((locked_card.get_meta(&"word_glyph") as Label).text, "✶",
		"codex_card_glyph_text")
	t.call((locked_card.get_meta(&"word_meaning") as Label).text, "未解码",
		"codex_card_locked_meaning_text")
	t.call((locked_card.get_meta(&"word_meta") as Label).text != "", true,
		"codex_card_meta_text")
	t.call((decoded_card.get_meta(&"word_meaning") as Label).text, "生命",
		"codex_card_decoded_meaning_text")
	t.call((decoded_card.get_meta(&"word_button") as Button).text, "选择",
		"codex_card_button_text")

	# Refreshing an unchanged inventory must reuse the cards, not rebuild them.
	codex.refresh()
	t.call(codex.get_word_card_count(), 2, "codex_refresh_no_duplicate")
	t.call(grid.get_child(0), locked_card, "codex_card_reused")

	sealed.decoded = true
	codex.refresh()
	t.call(codex.get_word_lines()[0].contains("记录"), true, "codex_refresh_after_decode")
	t.call((grid.get_child(0) as PanelContainer).get_theme_stylebox("panel"), WORD_CARD_DECODED, "codex_decoded_after_refresh")
	t.call(grid.get_child(0), locked_card, "codex_card_updated_in_place")
	t.call((locked_card.get_meta(&"word_meaning") as Label).text, "记录",
		"codex_card_meaning_updated_in_place")

	var forge_words: Array[WordData] = [sealed, known]
	var phrase := resolver.resolve(forge_words)
	t.call(phrase != null, true, "codex_phrase_resolved")
	t.call(phrase.display_name, "记录·生命", "codex_phrase_name")

	var discovered: Array[ResolvedPhrase] = [phrase]
	codex.set_discovered(discovered)
	t.call(codex.get_combo_lines().size(), 1, "codex_combo_count")
	t.call(codex.get_combo_card_count(), 1, "codex_combo_card_count")
	t.call(codex.get_combo_lines()[0].contains(phrase.display_name), true, "codex_combo_line")
	var combo_card := codex.find_child("CombosList", true, false).get_child(0) as PanelContainer
	t.call(combo_card.get_theme_stylebox("panel"), COMBO_CARD, "codex_combo_card_style")

	var extra := _make_word(&"guanzilu", "⌛", "时间", WordData.GrammarRole.MODIFIER, [&"time"], false)
	run_state.inventory.add_word(extra)
	t.call(codex.get_word_lines().size(), 3, "codex_inventory_signal_refresh")
	t.call(codex.get_word_card_count(), 3, "codex_inventory_card_refresh")

	codex.show_forge_preview(forge_words)
	t.call(codex.get_forge_text().contains(phrase.display_name), true, "codex_forge_preview")
	t.call(codex.get_forge_text().contains("墨耗"), true, "codex_forge_cost")

	var empty_words: Array[WordData] = []
	codex.show_forge_preview(empty_words)
	t.call(codex.get_forge_text().contains("言出法随"), true, "codex_forge_empty_hint")

	tree.root.remove_child(codex)
	codex.free()


func _make_word(
	id: StringName,
	glyph: String,
	meaning: String,
	role: WordData.GrammarRole,
	tags: Array[StringName],
	decoded: bool
) -> WordData:
	var word := WordData.new()
	word.id = id
	word.glyph = glyph
	word.meaning = meaning
	word.grammar_role = role
	word.tags = tags
	word.decoded = decoded
	return word


func _assert_fits_viewport(t: Callable, control: Control, prefix: String) -> void:
	var minimum := control.get_combined_minimum_size()
	t.call(minimum.x > 0.0 and minimum.x <= 1280.0, true, prefix + "_width")
	t.call(minimum.y > 0.0 and minimum.y <= 720.0, true, prefix + "_height")
