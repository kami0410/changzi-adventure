class_name CodexUI
extends Control

signal phrase_equip_requested(slot: int, phrase: ResolvedPhrase)
signal close_requested

const COLOR_BONE := UIPalette.INK
const COLOR_CYAN := UIPalette.VERDIGRIS
const COLOR_DIM := UIPalette.INK_FAINT
const COLOR_LOCKED := UIPalette.ABYSS
const COLOR_BLOOD := UIPalette.CINNABAR

const WORD_CARD_LOCKED: StyleBox = preload("res://resources/ui/word_card_locked.tres")
const WORD_CARD_DECODED: StyleBox = preload("res://resources/ui/word_card_decoded.tres")
const WORD_CARD_SELECTED: StyleBox = preload("res://resources/ui/card_selected.tres")
const COMBO_CARD: StyleBox = preload("res://resources/ui/combo_card.tres")
const EFFECT_LABELS := {
	&"damage": "伤害", &"heal": "治疗", &"slow": "减速", &"lifesteal": "吸血", &"area": "范围增幅",
	&"ink_gain": "回墨", &"duration": "持续", &"projectile": "弹道", &"summon": "召唤", &"shield": "护盾",
	&"move_speed": "移速增幅", &"projectiles": "弹幕", &"pulses": "连发", &"spread": "扇面",
	&"burn": "灼烧", &"chain": "连锁", &"knockback": "击退", &"homing": "追踪", &"pierce": "贯穿",
	&"explosion": "爆裂", &"stun": "定身", &"pull": "吸入",
}

var _words_title: Label = null
var _word_grid: GridContainer = null
var _combos_title: Label = null
var _combos_list: VBoxContainer = null
var _forge_label: Label = null

var _resolver: PhraseResolver = null
var _run: RunState = null
var _discovered: Array[ResolvedPhrase] = []
var _persistent_signatures: Array[String] = []
var _word_lines: Array[String] = []
var _combo_lines: Array[String] = []
var _nodes_ready: bool = false

var _selected_words: Array[WordData] = []
var _last_forge_phrase: ResolvedPhrase = null
var _forge_status: Label = null
var _equip_buttons: Array[Button] = []
var _free_text: LineEdit = null
var _ai_button: Button = null
var _ai_status: Label = null


func _ready() -> void:
	_ensure_nodes()
	refresh()
	var header := find_child("Header", true, false)
	var close_button := Button.new()
	close_button.text = "返回 [C / Esc]"
	close_button.pressed.connect(func(): close_requested.emit())
	header.add_child(close_button)
	var ai := get_node_or_null("/root/AI") as AIService
	if ai != null:
		ai.intent_ready.connect(_on_ai_intent)
		ai.intent_failed.connect(_on_ai_failed)
		ai.status_changed.connect(func(text: String):
			if _ai_status != null:
				_ai_status.text = text
		)


func bind(resolver: PhraseResolver, run: RunState) -> void:
	if _run != null and _run.inventory.changed.is_connected(_on_inventory_changed):
		_run.inventory.changed.disconnect(_on_inventory_changed)
	_resolver = resolver
	_run = run
	_sync_inventory_signal()
	refresh()


func set_discovered(phrases: Array[ResolvedPhrase]) -> void:
	_discovered = phrases.duplicate()
	refresh()


## Combo signatures saved on Profile; reconstructed from ContentLibrary so a
## fresh run can still show what the player discovered before.
func set_persistent_discovered(signatures: Array[String]) -> void:
	_persistent_signatures = signatures.duplicate()
	refresh()


func refresh() -> void:
	_ensure_nodes()
	if _word_grid == null:
		return
	_sync_inventory_signal()
	_refresh_words()
	_refresh_combos()


func show_forge_preview(words: Array[WordData]) -> void:
	_ensure_nodes()
	if _forge_label == null:
		return
	_last_forge_phrase = null
	if _resolver == null:
		_forge_label.text = "造句台尚未就绪。"
		_update_forge_actions()
		return
	var error := _resolver.validation_error(words)
	if error != &"":
		_forge_label.text = "言出法随：任选 1–4 个词，或直接输入一句话。%s" % ("" if words.is_empty() else "（%s）" % _error_label(error))
		_update_forge_actions()
		return
	var phrase := _resolver.resolve(words)
	if phrase == null:
		_forge_label.text = "这句话暂时无法凝成法术。"
		_update_forge_actions()
		return
	_last_forge_phrase = phrase
	_display_forge_phrase(phrase)
	_update_forge_actions()


func _display_forge_phrase(phrase: ResolvedPhrase) -> void:
	var line := "言灵：%s   墨耗 %d   冷却 %.1f 秒   污染 +%d" % [
		phrase.from_text if phrase.from_text != "" else phrase.display_name,
		phrase.ink_cost,
		phrase.cooldown,
		phrase.corruption_gain,
	]
	if phrase.word_count > 0:
		line += "   %d 个词，稳定 %d%%" % [phrase.word_count, int(round(phrase.stability * 100.0))]
	if phrase.unstable:
		line += "   [不稳定]"
	var effects: Array[String] = []
	for key in phrase.components:
		if EFFECT_LABELS.has(key):
			var value := float(phrase.components[key]) * (3.0 if key == &"damage" else 1.0)
			effects.append("%s %s" % [EFFECT_LABELS[key], _short_number(value)])
	var volley := int(phrase.components.get(&"projectiles", 0.0)) * maxi(int(phrase.spell.get(&"pulses", 1)), 1)
	if volley >= 2 and phrase.spell.get(&"shape", &"") in [&"missile", &"flame", &"blade", &"blood", &"void", &"vortex", &"ward", &"quake", &"domain", &"sentinel"]:
		var per := SpellContext.share_for(float(phrase.components.get(&"damage", 0.0)) * 3.0, volley, bool(phrase.spell.get(&"per_hit", false)))
		effects.append("每发 %s × %d" % [_short_number(per), volley])
	var explanation := SpellSynthesizer.explain(phrase)
	if not explanation.is_empty():
		var read_line := "识别：%s" % explanation.get("matched", "")
		if explanation.get("concepts", "") != "":
			read_line += "   借用未收录：%s（污染 +2/个，稳定度下降）" % explanation["concepts"]
		if explanation.get("intent", "") != "":
			read_line += "   意图：%s" % explanation["intent"]
		line += "\n" + read_line
	_forge_label.text = line + "\n" + SpellStyle.label(phrase.spell) + "\n" + "、".join(effects)


static func _short_number(value: float) -> String:
	if absf(value) >= 10000.0:
		return "%.3g" % value
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.1f" % value


func _on_ai_requested() -> void:
	var text := _free_text.text.strip_edges() if _free_text != null else ""
	if text.is_empty():
		_ai_status.text = "先说一句话。"
		return
	_on_free_text_submitted(text)
	var ai := get_node_or_null("/root/AI") as AIService
	if ai == null or not ai.is_configured():
		_ai_status.text = "AI 未配置，这句话按离线推演。要配置，按 F10 打开设置里的“AI 言灵”。"
		return
	if _ai_button != null:
		_ai_button.disabled = true
	_ai_status.text = "AI 正在读这句话…"
	ai.request_intent(text)


func _on_ai_intent(sentence: String, intent: Dictionary) -> void:
	if _ai_button != null:
		_ai_button.disabled = false
	if _run == null:
		return
	if _free_text != null and _free_text.text.strip_edges() != sentence:
		_ai_status.text = "AI 返回了上一句的结果，已忽略。"
		return
	var phrase := SpellSynthesizer.compile_intent(sentence, intent, _run.inventory.words)
	if phrase == null:
		_ai_status.text = "AI 意图未通过本地校验，已保留离线推演。"
		return
	_selected_words.clear()
	_refresh_words()
	_last_forge_phrase = phrase
	_display_forge_phrase(phrase)
	_update_forge_actions()
	var shape_name: String = SpellStyle.NAMES.get(StringName(intent.get("shape", "")), String(intent.get("shape", "")))
	var abyss := "。AI 没读懂，深渊补完了后半句：很强，污染极高" if bool(phrase.synthesis.get(&"abyssal", false)) else ""
	_ai_status.text = "AI 解读为“%s”（%s），把握 %d%%%s" % [String(intent.get("name", "")), shape_name, int(round(float(intent.get("confidence", 1.0)) * 100.0)), abyss]


func _on_ai_failed(_sentence: String, error: String) -> void:
	if _ai_button != null:
		_ai_button.disabled = false
	_ai_status.text = "AI 没有回应（%s），保留离线推演的结果。" % error


func _on_free_text_submitted(text: String) -> void:
	if _run == null:
		return
	var phrase := SpellSynthesizer.synthesize(text, _run.inventory.words)
	if phrase == null:
		_forge_label.text = "至少说出一个字。"
		_last_forge_phrase = null
		_update_forge_actions()
		return
	_selected_words.clear()
	_refresh_words()
	_last_forge_phrase = phrase
	_display_forge_phrase(phrase)
	_update_forge_actions()


func get_word_lines() -> Array[String]:
	_ensure_nodes()
	return _word_lines.duplicate()


func get_combo_lines() -> Array[String]:
	_ensure_nodes()
	return _combo_lines.duplicate()


func get_forge_text() -> String:
	_ensure_nodes()
	return _forge_label.text if _forge_label != null else ""


func get_word_card_count() -> int:
	_ensure_nodes()
	if _word_grid == null:
		return 0
	var count := 0
	for child in _word_grid.get_children():
		if child is PanelContainer:
			count += 1
	return count


func get_combo_card_count() -> int:
	_ensure_nodes()
	if _combos_list == null:
		return 0
	var count := 0
	for child in _combos_list.get_children():
		if child is PanelContainer:
			count += 1
	return count


func _ensure_nodes() -> void:
	if _nodes_ready:
		return
	_nodes_ready = true
	_words_title = find_child("WordsTitle", true, false) as Label
	_word_grid = find_child("WordGrid", true, false) as GridContainer
	_combos_title = find_child("CombosTitle", true, false) as Label
	_combos_list = find_child("CombosList", true, false) as VBoxContainer
	_forge_label = find_child("ForgePreview", true, false) as Label
	_build_forge_actions()


func _refresh_words() -> void:
	if _word_grid == null:
		return
	_word_lines.clear()
	_clear(_word_grid)

	var words: Array[WordData] = []
	if _run != null:
		words = _run.inventory.words
	if _words_title != null:
		_words_title.text = "词表（%d / %d）" % [words.size(), ContentLibrary.WORDS.size()]
	if words.is_empty():
		var empty := Label.new()
		empty.text = "尚未收集任何词。"
		empty.add_theme_color_override("font_color", COLOR_DIM)
		empty.add_theme_font_size_override("font_size", 12)
		_word_grid.add_child(empty)
		return

	for word in words:
		if word == null:
			continue
		_word_lines.append(_word_line(word))
		_word_grid.add_child(_make_word_card(word))


func _refresh_combos() -> void:
	if _combos_list == null:
		return
	_combo_lines.clear()
	_clear(_combos_list)
	var combos: Array[ResolvedPhrase] = []
	var seen: Dictionary = {}
	for phrase in _discovered:
		if phrase == null:
			continue
		combos.append(phrase)
		seen[phrase.signature] = true
	for signature in _persistent_signatures:
		if signature.is_empty() or seen.has(signature):
			continue
		var phrase := _phrase_for_signature(signature)
		if phrase != null:
			combos.append(phrase)
			seen[signature] = true
	if _combos_title != null:
		_combos_title.text = "已发现组合（本局 %d / 全部 %d）" % [_discovered.size(), combos.size()]
	if combos.is_empty():
		var empty := Label.new()
		empty.text = "尚未发现组合。在造句台组合 2–3 个词后，配方会记录在这里。"
		empty.add_theme_color_override("font_color", COLOR_DIM)
		empty.add_theme_font_size_override("font_size", 12)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_combos_list.add_child(empty)
		return

	for phrase in combos:
		_combo_lines.append(_combo_line(phrase))
		_combos_list.add_child(_make_combo_card(phrase))


func _phrase_for_signature(signature: String) -> ResolvedPhrase:
	if _resolver == null:
		return null
	var ids := signature.get_slice("|", 0).split(",", false)
	if ids.is_empty():
		return null
	var words: Array[WordData] = []
	for id in ids:
		var source := _find_word(StringName(id))
		if source == null:
			return null
		var profile := Flow.profile if Flow != null else null
		words.append(WordRuntime.for_run(source, profile))
	if words.size() != ids.size():
		return null
	return _resolver.resolve(words)


func _find_word(word_id: StringName) -> WordData:
	for entry in ContentLibrary.WORDS:
		var word := entry as WordData
		if word != null and word.id == word_id:
			return word
	return null


func _make_word_card(word: WordData) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 142)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	if _selected_words.has(word):
		card.add_theme_stylebox_override("panel", WORD_CARD_SELECTED)
	else:
		card.add_theme_stylebox_override("panel", WORD_CARD_DECODED if word.decoded else WORD_CARD_LOCKED)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	card.add_child(box)

	var glyph := Label.new()
	glyph.text = word.glyph if word.glyph != "" else "？？？"
	glyph.add_theme_font_size_override("font_size", 24)
	glyph.add_theme_color_override("font_color", COLOR_CYAN if word.decoded else COLOR_LOCKED)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(glyph)

	var meaning := Label.new()
	meaning.text = word.meaning if word.decoded else "未解码"
	meaning.add_theme_font_size_override("font_size", 12)
	meaning.add_theme_color_override("font_color", COLOR_BONE if word.decoded else COLOR_DIM)
	meaning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meaning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(meaning)

	var meta := Label.new()
	meta.text = _word_meta(word)
	meta.add_theme_font_size_override("font_size", 12)
	meta.add_theme_color_override("font_color", COLOR_DIM)
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(meta)

	var select_button := Button.new()
	select_button.text = "取消选择" if _selected_words.has(word) else "选择"
	select_button.focus_mode = Control.FOCUS_ALL
	select_button.add_theme_font_size_override("font_size", 12)
	select_button.set_meta("word_id", word.id)
	select_button.pressed.connect(_toggle_word.bind(word))
	box.add_child(select_button)

	return card


func _make_combo_card(phrase: ResolvedPhrase) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 66)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_theme_stylebox_override("panel", COMBO_CARD)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	card.add_child(box)

	var name_label := Label.new()
	var source := phrase.display_name
	if phrase.from_text != "":
		source = phrase.from_text
	name_label.text = source + "  〔%s〕" % SpellStyle.NAMES.get(phrase.spell.get(&"shape", &"blade"), "墨刃")
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", COLOR_BLOOD if phrase.unstable else COLOR_BONE)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name_label)

	var stats := Label.new()
	stats.text = _combo_stats(phrase)
	stats.add_theme_font_size_override("font_size", 12)
	stats.add_theme_color_override("font_color", COLOR_DIM)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(stats)

	if phrase.unstable:
		var badge := Label.new()
		badge.text = "！不稳定组合"
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", COLOR_BLOOD)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(badge)

	return card


func _word_line(word: WordData) -> String:
	if word.decoded:
		return "%s（%s）" % [word.meaning, _role_label(word.grammar_role)]
	var glyph := word.glyph if word.glyph != "" else "？？？"
	return "%s（未解码）" % glyph


func _word_meta(word: WordData) -> String:
	if not word.decoded:
		return "符文仍在沉睡 · " + _vague_hint(word)
	var effects: Array[String] = []
	for key in word.components:
		if EFFECT_LABELS.has(key) and not effects.has(EFFECT_LABELS[key]):
			effects.append(EFFECT_LABELS[key])
	var profile := Flow.profile if Flow != null else null
	if profile != null:
		var mastery := profile.word_mastery_level(word.id)
		if mastery > 0:
			effects.append("熟练 Lv.%d" % mastery)
	if effects.is_empty():
		return "改变短语的写法"
	return "、".join(effects)
	var parts: Array[String] = [_role_label(word.grammar_role)]
	for tag in word.tags:
		parts.append("#" + String(tag))
	return "、".join(parts)


func _combo_line(phrase: ResolvedPhrase) -> String:
	var line := phrase.display_name
	line += "，墨耗 %d" % phrase.ink_cost
	line += "，冷却 %.1f 秒" % phrase.cooldown
	if phrase.corruption_gain > 0:
		line += "，污染 +%d" % phrase.corruption_gain
	if phrase.unstable:
		line += "，不稳定"
	return line


func _combo_stats(phrase: ResolvedPhrase) -> String:
	var parts: Array[String] = [
		"墨耗 %d" % phrase.ink_cost,
		"冷却 %.1f 秒" % phrase.cooldown,
	]
	if phrase.corruption_gain > 0:
		parts.append("污染 +%d" % phrase.corruption_gain)
	return "、".join(parts)


## Undecoded words hint at one theme without revealing the meaning.
func _vague_hint(word: WordData) -> String:
	for tag in word.tags:
		var meaning: String = SpellSynthesizer.TAG_MEANING.get(tag, "")
		if meaning != "":
			return "与「%s」有关" % meaning
	return "尚不可读"


func _role_label(role: WordData.GrammarRole) -> String:
	match role:
		WordData.GrammarRole.NOUN:
			return "名词"
		WordData.GrammarRole.VERB:
			return "动词"
		_:
			return "修饰词"


func _error_label(error: StringName) -> String:
	match error:
		&"too_few":
			return "至少需要 1 个词"
		&"too_many":
			return "最多 4 个词"
		&"null_word":
			return "包含空词"
		_:
			return String(error)


func _sync_inventory_signal() -> void:
	if _run == null:
		return
	if not _run.inventory.changed.is_connected(_on_inventory_changed):
		_run.inventory.changed.connect(_on_inventory_changed)


func _clear(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		var deferred := child.is_inside_tree()
		container.remove_child(child)
		if deferred:
			child.queue_free()
		else:
			child.free()


func _toggle_word(word: WordData) -> void:
	if _selected_words.has(word):
		_selected_words.erase(word)
	elif _selected_words.size() < 4:
		_selected_words.append(word)
	if _free_text != null:
		_free_text.text = ""
	_refresh_words()
	show_forge_preview(_selected_words)
	if is_inside_tree() and visible:
		for button in _word_grid.find_children("*", "Button", true, false):
			if button.get_meta("word_id", &"") == word.id:
				button.grab_focus.call_deferred()
				break
	var title := find_child("ForgeTitle", true, false) as Label
	if title != null:
		var selected: Array[String] = []
		for entry in _selected_words:
			selected.append(entry.meaning)
		title.text = " → ".join(selected) if not selected.is_empty() else "按顺序选择：修饰词（可选） → 动词 → 名词"


func _build_forge_actions() -> void:
	if not _equip_buttons.is_empty():
		return
	var forge_panel := find_child("ForgePanel", true, false)
	if forge_panel == null:
		return
	var box := forge_panel.get_node_or_null("VBox")
	if box == null:
		return
	var free_row := HBoxContainer.new()
	free_row.name = "FreeCastRow"
	free_row.add_theme_constant_override("separation", 8)
	var free_label := Label.new()
	free_label.text = "言出法随"
	free_label.add_theme_font_size_override("font_size", 12)
	free_label.add_theme_color_override("font_color", COLOR_CYAN)
	free_row.add_child(free_label)
	_free_text = LineEdit.new()
	_free_text.name = "FreeCastInput"
	_free_text.placeholder_text = "输入一句话，例：让时间在火里停下来"
	_free_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_free_text.custom_minimum_size = Vector2(320, 38)
	_free_text.add_theme_font_size_override("font_size", 12)
	_free_text.text_submitted.connect(_on_free_text_submitted)
	free_row.add_child(_free_text)
	var free_button := Button.new()
	free_button.text = "推演"
	free_button.add_theme_font_size_override("font_size", 12)
	free_button.pressed.connect(func(): _on_free_text_submitted(_free_text.text))
	free_row.add_child(free_button)
	_ai_button = Button.new()
	_ai_button.text = "AI 解读"
	_ai_button.add_theme_font_size_override("font_size", 12)
	_ai_button.tooltip_text = "把当前这句话发送到已配置的 AI 服务，只解析意图；没有配置时使用离线推演"
	_ai_button.pressed.connect(_on_ai_requested)
	free_row.add_child(_ai_button)
	box.add_child(free_row)
	var examples := HBoxContainer.new()
	examples.name = "FreeCastExamples"
	examples.add_theme_constant_override("separation", 6)
	box.add_child(examples)
	for example in ["让雷落在火里", "把记忆烧成回声", "让时间停下来"]:
		var chip := Button.new()
		chip.text = example
		chip.add_theme_font_size_override("font_size", 12)
		chip.focus_mode = Control.FOCUS_ALL
		chip.pressed.connect(func():
			if _free_text != null:
				_free_text.text = example
				_on_free_text_submitted(example)
		)
		examples.add_child(chip)
	_ai_status = Label.new()
	_ai_status.name = "AIStatus"
	_ai_status.add_theme_font_size_override("font_size", 12)
	_ai_status.add_theme_color_override("font_color", UIPalette.INK_SOFT)
	_ai_status.text = "AI 未配置，使用离线推演。"
	box.add_child(_ai_status)
	var actions := HBoxContainer.new()
	actions.name = "ForgeActions"
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	for slot in 2:
		var button := Button.new()
		button.text = "装备到 [%s]" % ("Q" if slot == 0 else "F")
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 12)
		button.disabled = true
		button.pressed.connect(_request_equip.bind(slot))
		actions.add_child(button)
		_equip_buttons.append(button)
	var clear_button := Button.new()
	clear_button.text = "清空选择"
	clear_button.focus_mode = Control.FOCUS_ALL
	clear_button.add_theme_font_size_override("font_size", 12)
	clear_button.pressed.connect(_clear_selection)
	actions.add_child(clear_button)
	_forge_status = Label.new()
	_forge_status.name = "ForgeStatus"
	_forge_status.add_theme_font_size_override("font_size", 12)
	_forge_status.add_theme_color_override("font_color", COLOR_DIM)
	box.add_child(_forge_status)


func _update_forge_actions() -> void:
	for button in _equip_buttons:
		button.disabled = _last_forge_phrase == null
	if _forge_status != null and _last_forge_phrase == null:
		_forge_status.text = ""


func _request_equip(slot: int) -> void:
	if _last_forge_phrase == null:
		return
	phrase_equip_requested.emit(slot, _last_forge_phrase)
	if _forge_status != null:
		_forge_status.text = "已装备到短语 %d：%s" % [slot + 1, _last_forge_phrase.display_name]


func _clear_selection() -> void:
	_selected_words.clear()
	_last_forge_phrase = null
	if _free_text != null:
		_free_text.text = ""
	_refresh_words()
	show_forge_preview(_selected_words)
	var title := find_child("ForgeTitle", true, false) as Label
	if title != null:
		title.text = "造句：选 1–4 个词，或直接写一句话"


func _on_inventory_changed() -> void:
	refresh()
