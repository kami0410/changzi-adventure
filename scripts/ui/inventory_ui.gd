class_name InventoryUI
extends Control

signal close_requested

const COLOR_BONE := UIPalette.INK
const COLOR_CYAN := UIPalette.VERDIGRIS
const COLOR_DIM := UIPalette.INK_FAINT
const COLOR_LOCKED := UIPalette.ABYSS
const COLOR_BLOOD := UIPalette.CINNABAR

const SLOT_STYLES := {
	&"common": preload("res://resources/ui/card_common.tres"),
	&"rare": preload("res://resources/ui/card_rare.tres"),
	&"epic": preload("res://resources/ui/card_epic.tres"),
	&"legendary": preload("res://resources/ui/card_legendary.tres"),
	&"corrupt": preload("res://resources/ui/card_corrupt.tres"),
	&"hover": preload("res://resources/ui/card_hover.tres"),
	&"selected": preload("res://resources/ui/card_selected.tres"),
}
const WORD_CARD_LOCKED: StyleBox = preload("res://resources/ui/word_card_locked.tres")
const WORD_CARD_DECODED: StyleBox = preload("res://resources/ui/word_card_decoded.tres")

var _weapon_card_1: PanelContainer = null
var _weapon_card_2: PanelContainer = null
var _phrase_card_1: PanelContainer = null
var _phrase_card_2: PanelContainer = null
var _weapon_name_1: Label = null
var _weapon_name_2: Label = null
var _weapon_tags_1: Label = null
var _weapon_tags_2: Label = null
var _phrase_name_1: Label = null
var _phrase_name_2: Label = null
var _phrase_tags_1: Label = null
var _phrase_tags_2: Label = null
var _words_title: Label = null
var _word_grid: GridContainer = null
var _relics_title: Label = null
var _relics_label: Label = null
var _corruption_label: Label = null
var _close_button: Button = null
var _close_hint_label: Label = null

var _inventory: Inventory = null
var _run_seed: int = 0
var _hovered_weapon_slot: int = -1
var _hovered_phrase_slot: int = -1
var _selected_weapon_slot: int = 0
var _selected_phrase_slot: int = 0
var _nodes_ready: bool = false
## Cards are kept between refreshes and updated in place. Rebuilding the whole
## grid on every Inventory.changed cost ~13 ms per card in a 40+ word run.
var _word_cards: Dictionary = {}
var _word_empty: Label = null


func _ready() -> void:
	_ensure_nodes()
	_refresh()
	var header := find_child("Header", true, false)
	_close_button = Button.new()
	_close_button.pressed.connect(func(): close_requested.emit())
	header.add_child(_close_button)
	_refresh_close_hint()
	var flow := _flow_node()
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)
	if flow != null and not flow.keybinds_changed.is_connected(_refresh_close_hint):
		flow.keybinds_changed.connect(_refresh_close_hint)


func bind(inventory: Inventory, run_seed: int = 0) -> void:
	if _inventory != null and _inventory.changed.is_connected(_on_inventory_changed):
		_inventory.changed.disconnect(_on_inventory_changed)
	if _inventory != inventory:
		_clear_word_cards()
	_inventory = inventory
	_run_seed = run_seed
	if _inventory != null and not _inventory.changed.is_connected(_on_inventory_changed):
		_inventory.changed.connect(_on_inventory_changed)
	_refresh()


func equip_weapon(slot: int, weapon: WeaponData) -> bool:
	if _inventory == null:
		return false
	var equipped := _inventory.equip_weapon(slot, weapon)
	if equipped:
		_selected_weapon_slot = slot
		_refresh()
	return equipped


func equip_phrase(slot: int, phrase: ResolvedPhrase) -> bool:
	if _inventory == null:
		return false
	var equipped := _inventory.equip_phrase(slot, phrase)
	if equipped:
		_selected_phrase_slot = slot
		_refresh()
	return equipped


func select_weapon_slot(slot: int) -> void:
	if slot < 0 or slot >= Inventory.MAX_WEAPONS:
		return
	_selected_weapon_slot = slot
	_refresh_slot_styles()


func select_phrase_slot(slot: int) -> void:
	if slot < 0 or slot >= Inventory.MAX_PHRASES:
		return
	_selected_phrase_slot = slot
	_refresh_slot_styles()


func get_selected_weapon_slot() -> int:
	return _selected_weapon_slot


func get_selected_phrase_slot() -> int:
	return _selected_phrase_slot


func refresh() -> void:
	_refresh()


func get_weapon_slot_text(slot: int) -> String:
	var weapon := _weapon_at(slot)
	return "%d: %s" % [slot + 1, _weapon_name(weapon)]


func get_phrase_slot_text(slot: int) -> String:
	var phrase := _phrase_at(slot)
	return "%d: %s" % [slot + 1, _phrase_name(phrase)]


func get_words_text() -> String:
	_ensure_nodes()
	return _build_words_text()


func get_word_card_count() -> int:
	_ensure_nodes()
	if _word_grid == null:
		return 0
	var count := 0
	for child in _word_grid.get_children():
		if child is PanelContainer:
			count += 1
	return count


func get_relics_text() -> String:
	_ensure_nodes()
	return _relics_label.text if _relics_label != null else ""


func get_corruption_text() -> String:
	_ensure_nodes()
	return _corruption_label.text if _corruption_label != null else ""


func _ensure_nodes() -> void:
	if _nodes_ready:
		return
	_nodes_ready = true
	_weapon_card_1 = find_child("WeaponSlotCard1", true, false) as PanelContainer
	_weapon_card_2 = find_child("WeaponSlotCard2", true, false) as PanelContainer
	_phrase_card_1 = find_child("PhraseSlotCard1", true, false) as PanelContainer
	_phrase_card_2 = find_child("PhraseSlotCard2", true, false) as PanelContainer
	_weapon_name_1 = find_child("WeaponSlotName1", true, false) as Label
	_weapon_name_2 = find_child("WeaponSlotName2", true, false) as Label
	_weapon_tags_1 = find_child("WeaponSlotTags1", true, false) as Label
	_weapon_tags_2 = find_child("WeaponSlotTags2", true, false) as Label
	_phrase_name_1 = find_child("PhraseSlotName1", true, false) as Label
	_phrase_name_2 = find_child("PhraseSlotName2", true, false) as Label
	_phrase_tags_1 = find_child("PhraseSlotTags1", true, false) as Label
	_phrase_tags_2 = find_child("PhraseSlotTags2", true, false) as Label
	_words_title = find_child("WordsTitle", true, false) as Label
	_word_grid = find_child("WordGrid", true, false) as GridContainer
	_relics_title = find_child("RelicsTitle", true, false) as Label
	_relics_label = find_child("Relics", true, false) as Label
	_corruption_label = find_child("Corruption", true, false) as Label
	var footer := find_child("Footer", true, false)
	if footer != null:
		_close_hint_label = footer.get_node_or_null("Hint") as Label

	_setup_slot(_weapon_card_1, 0, true)
	_setup_slot(_weapon_card_2, 1, true)
	_setup_slot(_phrase_card_1, 0, false)
	_setup_slot(_phrase_card_2, 1, false)


func _refresh() -> void:
	_ensure_nodes()
	if _weapon_name_1 == null:
		return

	var weapons: Array[WeaponData] = []
	var phrases: Array[ResolvedPhrase] = []
	if _inventory != null:
		weapons = _inventory.weapons
		phrases = _inventory.phrases

	var weapon_0: WeaponData = weapons[0] if weapons.size() > 0 else null
	var weapon_1: WeaponData = weapons[1] if weapons.size() > 1 else null
	var phrase_0: ResolvedPhrase = phrases[0] if phrases.size() > 0 else null
	var phrase_1: ResolvedPhrase = phrases[1] if phrases.size() > 1 else null

	_weapon_name_1.text = _weapon_name(weapon_0)
	_weapon_name_2.text = _weapon_name(weapon_1)
	_phrase_name_1.text = _phrase_name(phrase_0)
	_phrase_name_2.text = _phrase_name(phrase_1)
	_weapon_tags_1.text = _weapon_tags(weapon_0)
	_weapon_tags_2.text = _weapon_tags(weapon_1)
	_phrase_tags_1.text = _phrase_tags(phrase_0)
	_phrase_tags_2.text = _phrase_tags(phrase_1)

	var words: Array[WordData] = []
	var relics: Array[RelicData] = []
	if _inventory != null:
		words = _inventory.words
		relics = _inventory.relics
	_words_title.text = "词（%d）" % words.size()
	_relics_title.text = "遗物（%d）" % relics.size()
	_relics_label.text = _build_relics_text(relics)
	var corruption := _inventory.total_corruption() if _inventory != null else 0
	_corruption_label.text = "总污染：%d" % corruption
	_corruption_label.add_theme_color_override("font_color", COLOR_BLOOD if corruption > 0 else COLOR_DIM)
	_rebuild_word_cards(words)
	_refresh_slot_styles()


func _rebuild_word_cards(words: Array[WordData]) -> void:
	if _word_grid == null:
		return
	var present: Dictionary = {}
	for word in words:
		if word != null:
			present[word.id] = true
	for key in _word_cards.keys():
		if present.has(key):
			continue
		var stale: PanelContainer = _word_cards[key]
		_word_cards.erase(key)
		if is_instance_valid(stale):
			if stale.get_parent() != null:
				stale.get_parent().remove_child(stale)
			if stale.is_inside_tree():
				stale.queue_free()
			else:
				stale.free()

	if words.is_empty():
		if _word_empty == null:
			_word_empty = Label.new()
			_word_empty.text = EmptyStateData.pick(&"inventory_words", _run_seed)
			_word_empty.add_theme_color_override("font_color", COLOR_DIM)
			_word_empty.add_theme_font_size_override("font_size", 12)
		if _word_empty.get_parent() == null:
			_word_grid.add_child(_word_empty)
		return
	if _word_empty != null:
		if _word_empty.get_parent() != null:
			_word_empty.get_parent().remove_child(_word_empty)
		_word_empty.queue_free()
		_word_empty = null

	for word in words:
		if word == null:
			continue
		var entry: Variant = _word_cards.get(word.id)
		if entry == null:
			var card := _make_word_card(word)
			_word_cards[word.id] = card
			_word_grid.add_child(card)
			# Text is assigned only after the card is in the tree; shaping text
			# during ENTER_TREE costs ~10 ms per card, the assignment after is
			# near-free.
			_fill_word_card_text(card, word)
		else:
			_update_word_card(entry as PanelContainer, word)


## Remove every cached word card, e.g. when binding a different inventory.
func _clear_word_cards() -> void:
	for entry in _word_cards.values():
		var card := entry as PanelContainer
		if not is_instance_valid(card):
			continue
		if card.get_parent() != null:
			card.get_parent().remove_child(card)
		if card.is_inside_tree():
			card.queue_free()
		else:
			card.free()
	_word_cards.clear()


func _update_word_card(card: PanelContainer, word: WordData) -> void:
	if card == null:
		return
	if bool(card.get_meta(&"rendered_decoded")) != word.decoded:
		card.add_theme_stylebox_override("panel",
			WORD_CARD_DECODED if word.decoded else WORD_CARD_LOCKED)
		var glyph := card.get_meta(&"word_glyph") as Label
		if glyph != null:
			glyph.add_theme_color_override("font_color", COLOR_CYAN if word.decoded else COLOR_LOCKED)
		var name_label := card.get_meta(&"word_name") as Label
		if name_label != null:
			name_label.add_theme_color_override("font_color", COLOR_BONE if word.decoded else COLOR_DIM)
		card.set_meta(&"rendered_decoded", word.decoded)
	var name_text := word.meaning if word.decoded else "未解码"
	var name_label_ref := card.get_meta(&"word_name") as Label
	if name_label_ref != null and name_label_ref.text != name_text:
		name_label_ref.text = name_text
	var tags_text := _word_tags(word)
	var tags_ref := card.get_meta(&"word_tags") as Label
	if tags_ref != null and tags_ref.text != tags_text:
		tags_ref.text = tags_text


func _make_word_card(word: WordData) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(148, 96)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_theme_stylebox_override("panel", WORD_CARD_DECODED if word.decoded else WORD_CARD_LOCKED)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	card.add_child(box)

	var glyph := Label.new()
	glyph.text = ""
	glyph.add_theme_font_size_override("font_size", 24)
	glyph.add_theme_color_override("font_color", COLOR_CYAN if word.decoded else COLOR_LOCKED)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(glyph)

	var name_label := Label.new()
	name_label.text = ""
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", COLOR_BONE if word.decoded else COLOR_DIM)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name_label)

	var tags := Label.new()
	tags.text = ""
	tags.add_theme_font_size_override("font_size", 12)
	tags.add_theme_color_override("font_color", COLOR_DIM)
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tags.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tags)

	# Cached so a kept card can be updated without rebuilding the grid.
	card.set_meta(&"word_glyph", glyph)
	card.set_meta(&"word_name", name_label)
	card.set_meta(&"word_tags", tags)
	card.set_meta(&"rendered_decoded", word.decoded)

	return card


## Fills the card after it enters the tree; see the note in _rebuild_word_cards.
func _fill_word_card_text(card: PanelContainer, word: WordData) -> void:
	var glyph := card.get_meta(&"word_glyph") as Label
	if glyph != null:
		glyph.text = word.glyph if word.glyph != "" else "？？？"
	var name_label := card.get_meta(&"word_name") as Label
	if name_label != null:
		name_label.text = word.meaning if word.decoded else "未解码"
	var tags := card.get_meta(&"word_tags") as Label
	if tags != null:
		tags.text = _word_tags(word)


func _refresh_slot_styles() -> void:
	_ensure_nodes()
	_apply_slot_style(_weapon_card_1, 0, true)
	_apply_slot_style(_weapon_card_2, 1, true)
	_apply_slot_style(_phrase_card_1, 0, false)
	_apply_slot_style(_phrase_card_2, 1, false)


func _apply_slot_style(card: PanelContainer, slot: int, is_weapon: bool) -> void:
	if card == null:
		return
	var hovered := (_hovered_weapon_slot == slot) if is_weapon else (_hovered_phrase_slot == slot)
	var selected := (_selected_weapon_slot == slot) if is_weapon else (_selected_phrase_slot == slot)
	var rarity := &"common"
	if is_weapon:
		rarity = _weapon_rarity(_weapon_at(slot))
	else:
		rarity = _phrase_rarity(_phrase_at(slot))

	var style: StyleBox = SLOT_STYLES.get(rarity, SLOT_STYLES[&"common"])
	if hovered:
		style = SLOT_STYLES[&"hover"]
	if selected:
		style = SLOT_STYLES[&"selected"]
	card.add_theme_stylebox_override("panel", style)


func _setup_slot(card: PanelContainer, slot: int, is_weapon: bool) -> void:
	if card == null:
		return
	if not card.mouse_entered.is_connected(_on_slot_mouse_entered.bind(slot, is_weapon)):
		card.mouse_entered.connect(_on_slot_mouse_entered.bind(slot, is_weapon))
	if not card.mouse_exited.is_connected(_on_slot_mouse_exited.bind(slot, is_weapon)):
		card.mouse_exited.connect(_on_slot_mouse_exited.bind(slot, is_weapon))
	if not card.gui_input.is_connected(_on_slot_gui_input.bind(slot, is_weapon)):
		card.gui_input.connect(_on_slot_gui_input.bind(slot, is_weapon))


func _on_slot_mouse_entered(slot: int, is_weapon: bool) -> void:
	if is_weapon:
		_hovered_weapon_slot = slot
	else:
		_hovered_phrase_slot = slot
	_refresh_slot_styles()


func _on_slot_mouse_exited(slot: int, is_weapon: bool) -> void:
	if is_weapon and _hovered_weapon_slot == slot:
		_hovered_weapon_slot = -1
	elif not is_weapon and _hovered_phrase_slot == slot:
		_hovered_phrase_slot = -1
	_refresh_slot_styles()


func _on_slot_gui_input(event: InputEvent, slot: int, is_weapon: bool) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_weapon:
			_selected_weapon_slot = slot
		else:
			_selected_phrase_slot = slot
		_refresh_slot_styles()


func _weapon_at(slot: int) -> WeaponData:
	if _inventory == null or slot < 0 or slot >= _inventory.weapons.size():
		return null
	return _inventory.weapons[slot]


func _phrase_at(slot: int) -> ResolvedPhrase:
	if _inventory == null or slot < 0 or slot >= _inventory.phrases.size():
		return null
	return _inventory.phrases[slot]


func _weapon_name(weapon: WeaponData) -> String:
	if weapon == null:
		return "—"
	if weapon.display_name != "":
		return weapon.display_name
	if weapon.id != &"":
		return String(weapon.id)
	return "—"


func _phrase_name(phrase: ResolvedPhrase) -> String:
	if phrase == null or phrase.display_name == "":
		return "—"
	return phrase.display_name


func _weapon_tags(weapon: WeaponData) -> String:
	if weapon == null:
		return "空槽位"
	var parts: Array[String] = ["伤害 %d，间隔 %.2f 秒" % [weapon.damage, weapon.attack_cooldown]]
	for tag in weapon.tags:
		parts.append("#" + String(tag))
	if parts.is_empty():
		return "无词条"
	return " ".join(parts)


func _phrase_tags(phrase: ResolvedPhrase) -> String:
	if phrase == null:
		return "空槽位"
	var parts: Array[String] = ["墨耗 %d" % phrase.ink_cost]
	if phrase.corruption_gain > 0:
		parts.append("污染 +%d" % phrase.corruption_gain)
	if phrase.unstable:
		parts.append("不稳定")
	return "，".join(parts)


func _word_tags(word: WordData) -> String:
	if not word.decoded:
		return "符文未解"
	var parts: Array[String] = []
	for tag in word.tags:
		var meaning: String = SpellSynthesizer.TAG_MEANING.get(tag, "")
		if meaning != "" and not parts.has(meaning):
			parts.append(meaning)
	if parts.is_empty():
		return "改变短语的写法"
	return "、".join(parts)


func _weapon_rarity(weapon: WeaponData) -> StringName:
	if weapon == null:
		return &"common"
	for tag in weapon.tags:
		match tag:
			&"legendary", &"epic", &"rare", &"corrupt":
				return tag
	return &"common"


func _phrase_rarity(phrase: ResolvedPhrase) -> StringName:
	if phrase == null:
		return &"common"
	if phrase.unstable:
		return &"corrupt"
	if phrase.tags.has(&"authority"):
		return &"legendary"
	if phrase.tags.has(&"abyss") or phrase.tags.has(&"corruption"):
		return &"epic"
	return &"rare"


func _build_words_text() -> String:
	if _inventory == null or _inventory.words.is_empty():
		return EmptyStateData.pick(&"inventory_words", _run_seed)
	var parts: Array[String] = []
	for word in _inventory.words:
		if word == null:
			continue
		if word.decoded:
			parts.append(word.meaning)
		else:
			parts.append("%s（未解码）" % (word.glyph if word.glyph != "" else "？？？"))
	return "  ".join(parts)


func _build_relics_text(relics: Array[RelicData]) -> String:
	if relics.is_empty():
		return EmptyStateData.pick(&"inventory_relics", _run_seed)
	var parts: Array[String] = []
	for relic in relics:
		if relic == null:
			continue
		parts.append("%s：%s" % [relic.display_name, RelicEffects.describe_relic(relic)])
	return "\n".join(parts)


func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


func _refresh_close_hint() -> void:
	var flow := _flow_node()
	var alt := "%s / Esc" % GameFlow.key_label(&"inventory")
	var key := flow.close_prompt(alt) if flow != null else alt
	if _close_button != null:
		_close_button.text = "返回 [%s]" % key
	if _close_hint_label != null:
		_close_hint_label.text = "%s 关闭" % key


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_close_hint()


func _on_inventory_changed() -> void:
	_refresh()
