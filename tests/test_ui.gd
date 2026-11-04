extends RefCounted

const SLOT_LEGENDARY: StyleBox = preload("res://resources/ui/slot_legendary.tres")
const SLOT_SELECTED: StyleBox = preload("res://resources/ui/card_selected.tres")
const WORD_CARD_DECODED: StyleBox = preload("res://resources/ui/word_card_decoded.tres")


func run(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.paused = false

	_test_hud(t, tree)
	_test_inventory(t, tree)
	_test_pause(t, tree)

	tree.paused = false


func _test_hud(t: Callable, tree: SceneTree) -> void:
	var hud := preload("res://scenes/ui/hud.tscn").instantiate() as HUD
	tree.root.add_child(hud)
	_assert_fits_viewport(t, hud.find_child("TopLeft", true, false), "hud_top_left")
	_assert_fits_viewport(t, hud.find_child("BottomSlots", true, false), "hud_slots")
	_assert_fits_viewport(t, hud.find_child("BossPanel", true, false), "hud_boss")

	var run_state := RunState.new()
	run_state.reset_for_new_run(7)
	hud.bind_run_state(run_state)

	t.call(hud.get_health_text(), "HP 100/100", "hud_health_initial")
	t.call(hud.get_ink_text(), "墨量 100/100", "hud_ink_initial")
	t.call(hud.get_corruption_text(), "污染 0/100 · 平静", "hud_corruption_initial")
	t.call(hud.health_bar.value, 100.0, "hud_health_bar_initial")
	t.call(hud.ink_bar.value, 100.0, "hud_ink_bar_initial")
	t.call(hud.corruption_bar.value, 0.0, "hud_corruption_bar_initial")

	run_state.take_damage(25)
	t.call(hud.get_health_text(), "HP 75/100", "hud_health_signal")
	t.call(hud.health_bar.value, 75.0, "hud_health_bar_signal")
	run_state.spend_ink(30)
	t.call(hud.get_ink_text(), "墨量 70/100", "hud_ink_signal")
	t.call(hud.ink_bar.value, 70.0, "hud_ink_bar_signal")
	run_state.add_corruption(25)
	t.call(hud.get_corruption_text(), "污染 25/100 · 低语", "hud_corruption_signal")
	t.call(hud.corruption_bar.value, 25.0, "hud_corruption_bar_signal")

	var weapon := WeaponData.new()
	weapon.id = &"page_sword"
	weapon.display_name = "断页剑"
	run_state.inventory.equip_weapon(0, weapon)
	t.call(hud.get_weapons_text().contains("断页剑"), true, "hud_weapon_slot_1")

	var legendary := WeaponData.new()
	legendary.id = &"ink_staff"
	legendary.display_name = "墨骸法杖"
	legendary.tags = [&"legendary"]
	run_state.inventory.equip_weapon(1, legendary)
	t.call(hud.get_weapons_text().contains("墨骸法杖"), true, "hud_weapon_slot_2")
	var weapon_style := hud.find_child("WeaponCard2", true, false) as PanelContainer
	t.call(weapon_style.get_theme_stylebox("panel"), SLOT_LEGENDARY, "hud_rarity_border")

	var phrase := ResolvedPhrase.new()
	phrase.display_name = "记录生命"
	phrase.ink_cost = 20
	run_state.inventory.equip_phrase(1, phrase)
	t.call(hud.get_phrases_text().contains("记录生命"), true, "hud_phrase_slot")

	hud.show_message("墨雨将至")
	t.call(hud.get_message_text(), "墨雨将至", "hud_message")

	hud.set_region("呼吸废墟")
	t.call(hud.get_region_text(), "呼吸废墟", "hud_region")

	t.call(hud.is_boss_visible(), false, "hud_boss_hidden_initially")
	hud.show_boss("墨骸史官", 60, 100)
	t.call(hud.is_boss_visible(), true, "hud_boss_visible")
	t.call(hud.get_boss_name_text(), "墨骸史官", "hud_boss_name")
	t.call(hud.get_boss_health(), 60, "hud_boss_health")
	hud.update_boss(20, 100)
	t.call(hud.get_boss_health(), 20, "hud_boss_health_update")
	hud.hide_boss()
	t.call(hud.is_boss_visible(), false, "hud_boss_hidden")

	tree.root.remove_child(hud)
	hud.free()


func _test_inventory(t: Callable, tree: SceneTree) -> void:
	var ui := preload("res://scenes/ui/inventory_ui.tscn").instantiate() as InventoryUI
	tree.root.add_child(ui)
	_assert_fits_viewport(t, ui.find_child("Panel", true, false), "inventory_panel")

	var inventory := Inventory.new()
	# Bind carries the run seed into the page's empty-state copy; an empty
	# inventory shows the seeded word line, not the build-time default.
	ui.bind(inventory, 12345)
	t.call(ui.get_words_text(), EmptyStateData.pick(&"inventory_words", 12345),
		"inventory_ui_empty_words_copy")
	var no_relics: Array[RelicData] = []
	t.call(ui._build_relics_text(no_relics),
		EmptyStateData.pick(&"inventory_relics", 12345),
		"inventory_ui_empty_relics_copy")

	var weapon := WeaponData.new()
	weapon.display_name = "墨弹枪"
	weapon.tags = [&"rare"]
	t.call(ui.equip_weapon(0, weapon), true, "inventory_ui_equip")
	t.call(inventory.weapons[0], weapon, "inventory_ui_calls_inventory")
	t.call(ui.get_weapon_slot_text(0).contains("墨弹枪"), true, "inventory_ui_weapon_label")
	t.call(ui.get_weapon_slot_text(0).contains("1:"), true, "inventory_ui_weapon_index")
	t.call(ui.equip_weapon(2, weapon), false, "inventory_ui_invalid_slot")
	t.call(ui.equip_weapon(0, null), false, "inventory_ui_null_weapon")

	var phrase := ResolvedPhrase.new()
	phrase.display_name = "时间深渊"
	phrase.ink_cost = 18
	phrase.tags = [&"time", &"abyss"]
	t.call(ui.equip_phrase(1, phrase), true, "inventory_ui_equip_phrase")
	t.call(ui.get_phrase_slot_text(1).contains("时间深渊"), true, "inventory_ui_phrase_label")

	var word := WordData.new()
	word.glyph = "✶"
	word.meaning = "记录"
	word.decoded = false
	inventory.add_word(word)
	t.call(ui.get_words_text().contains("✶"), true, "inventory_ui_word_glyph")
	t.call(ui.get_word_card_count(), 1, "inventory_ui_word_card")

	# A refresh must reuse existing cards; decoding updates the kept card.
	var word_card := ui._word_grid.get_child(0) as PanelContainer
	# Cards are filled after entering the tree (cheap text shaping); the real
	# labels must still show the word once the refresh returns.
	t.call((word_card.get_meta(&"word_glyph") as Label).text, "✶",
		"inventory_ui_card_glyph_text")
	t.call((word_card.get_meta(&"word_name") as Label).text, "未解码",
		"inventory_ui_card_locked_name_text")
	t.call((word_card.get_meta(&"word_tags") as Label).text != "", true,
		"inventory_ui_card_tags_text")
	ui.refresh()
	t.call(ui.get_word_card_count(), 1, "inventory_ui_refresh_no_duplicate")
	t.call(ui._word_grid.get_child(0), word_card, "inventory_ui_card_reused")
	word.decoded = true
	ui.refresh()
	t.call(word_card.get_theme_stylebox("panel"), WORD_CARD_DECODED,
		"inventory_ui_card_decoded_in_place")
	t.call((word_card.get_meta(&"word_name") as Label).text, "记录",
		"inventory_ui_card_name_updated_in_place")

	t.call(ui.get_selected_weapon_slot(), 0, "inventory_ui_default_selection")
	ui.select_weapon_slot(1)
	t.call(ui.get_selected_weapon_slot(), 1, "inventory_ui_select_weapon")
	var selected_card := ui.find_child("WeaponSlotCard2", true, false) as PanelContainer
	t.call(selected_card.get_theme_stylebox("panel"), SLOT_SELECTED, "inventory_ui_selected_style")

	t.call(ui.get_corruption_text().contains("0"), true, "inventory_ui_corruption")

	tree.root.remove_child(ui)
	ui.free()


func _test_pause(t: Callable, tree: SceneTree) -> void:
	var menu := preload("res://scenes/ui/pause_menu.tscn").instantiate() as PauseMenu
	tree.root.add_child(menu)
	_assert_fits_viewport(t, menu.find_child("Panel", true, false), "pause_panel")

	t.call(menu.process_mode, Node.PROCESS_MODE_ALWAYS, "pause_process_mode")
	t.call(menu.is_open(), false, "pause_closed_initially")
	t.call(tree.paused, false, "pause_tree_initially")

	menu.toggle()
	t.call(tree.paused, true, "pause_toggle_on")
	t.call(menu.is_open(), true, "pause_open_after_toggle")

	menu.toggle()
	t.call(tree.paused, false, "pause_toggle_off")
	t.call(menu.is_open(), false, "pause_closed_after_toggle")

	tree.paused = false
	tree.root.remove_child(menu)
	menu.free()


func _assert_fits_viewport(t: Callable, control: Control, prefix: String) -> void:
	var minimum := control.get_combined_minimum_size()
	t.call(minimum.x > 0.0 and minimum.x <= 1280.0, true, prefix + "_width")
	t.call(minimum.y > 0.0 and minimum.y <= 720.0, true, prefix + "_height")
