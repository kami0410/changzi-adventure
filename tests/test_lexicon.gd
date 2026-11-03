extends RefCounted

## 0.8 lexicon: 95 words, every word shippable, every new mechanic reachable
## from words alone, and the free-form AI concepts all backed by a real word.

const NEW_MECHANICS: Array[StringName] = [&"homing", &"pierce", &"explosion", &"stun", &"pull", &"knockback", &"projectiles", &"chain", &"pulses", &"duration", &"burn", &"purify"]
const FONT_PATH := "res://assets/fonts/fusion-pixel-12px-monospaced-zh_hans.ttf.woff2"


func run(t: Callable) -> void:
	var words: Array[WordData] = []
	for entry in ContentLibrary.WORDS:
		words.append(entry as WordData)
	t.call(words.size(), 95, "lexicon_has_95_words")
	t.call(words.size() >= 80 and words.size() <= 100, true, "lexicon_in_target_range")
	var ids: Dictionary = {}
	var meanings: Dictionary = {}
	var tags_seen: Dictionary = {}
	var mechanics_seen: Dictionary = {}
	for word in words:
		ids[word.id] = true
		meanings[word.meaning] = true
		for tag in word.tags:
			tags_seen[tag] = true
		for key in word.components:
			mechanics_seen[key] = true
			t.call(is_finite(float(word.components[key])) and float(word.components[key]) > 0.0, true, "lexicon_component_positive_%s_%s" % [word.id, key])
		t.call(word.description.length() >= 6, true, "lexicon_has_story_%s" % word.id)
	t.call(ids.size(), words.size(), "lexicon_ids_unique")
	t.call(meanings.size(), words.size(), "lexicon_meanings_unique")
	for key in NEW_MECHANICS:
		t.call(mechanics_seen.has(key), true, "lexicon_word_grants_%s" % key)
	# Every concept the AI prompt allows should exist as a real word tag, so
	# AI intents can match owned words instead of always borrowing echoes.
	var missing: Array[String] = []
	for tag in SpellSynthesizer.TAG_MEANING.keys():
		if tag in [&"scale", &"multi", &"reverse", &"final", &"first", &"nameless"]:
			continue
		if not tags_seen.has(tag):
			missing.append(String(tag))
	t.call(", ".join(missing), "", "lexicon_covers_ai_concepts")
	_test_font_coverage(t, words)
	_test_shapes_from_words(t, words)


func _test_font_coverage(t: Callable, words: Array[WordData]) -> void:
	var font := load(FONT_PATH) as FontFile
	t.call(font != null, true, "lexicon_font_loads")
	if font == null:
		return
	# Glyphs are the word's icon and must be pixel-font crisp. Meanings may
	# still use a few CJK characters the font lacks (tracked by
	# tools/font_coverage.py); those fall back to the system font.
	var missing := ""
	for word in words:
		for text: String in [word.glyph]:
			for index in text.length():
				var code: int = text.unicode_at(index)
				if not font.has_char(code) and not missing.contains(char(code)):
					missing += char(code)
	t.call(missing, "", "lexicon_glyphs_render_in_pixel_font")


func _test_shapes_from_words(t: Callable, words: Array[WordData]) -> void:
	var by_id: Dictionary = {}
	for word in words:
		by_id[word.id] = word
	var resolver := PhraseResolver.new()
	var cases := [
		[[&"yu", &"zhuilie"], &"missile", "lexicon_feather_hunt_is_homing_volley"],
		[[&"shan", &"zhentui"], &"quake", "lexicon_mountain_shock_is_quake"],
		[[&"xing", &"zhuiluo"], &"meteor", "lexicon_star_fall_is_meteor"],
		[[&"guan", &"zhixu"], &"domain", "lexicon_crown_order_is_domain"],
		[[&"yanjing", &"guanchuan"], &"beam", "lexicon_eye_pierce_is_beam"],
		[[&"men", &"tansuo"], &"vortex", "lexicon_door_collapse_is_vortex"],
	]
	for case in cases:
		var parts: Array[WordData] = []
		for id in case[0]:
			if by_id.has(id):
				parts.append(by_id[id])
		var phrase := resolver.resolve(parts)
		t.call(phrase != null and phrase.spell.get(&"shape", &"") == case[1], true, case[2])
	var homing_phrase := resolver.resolve([by_id[&"ya"], by_id[&"wanqian"]] as Array[WordData])
	t.call(float(homing_phrase.components.get(&"projectiles", 0.0)) >= 8.0, true, "lexicon_crows_and_myriad_stack_projectiles")
