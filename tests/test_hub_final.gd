extends RefCounted

const HUB_SCENE: PackedScene = preload("res://scenes/hub/hub.tscn")
const DIALOGUE_SCENE: PackedScene = preload("res://scenes/ui/dialogue_ui.tscn")
const SHOP_SCENE: PackedScene = preload("res://scenes/hub/shop_ui.tscn")
const SWORD_ID: StringName = &"broken_page_sword"


func run(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.paused = false

	var hub := HUB_SCENE.instantiate() as Hub
	tree.root.add_child(hub)
	hub.ensure_ready()
	_test_scene(t, hub)
	_test_npcs(t, hub)
	_test_dialogue(t, tree)
	_test_luchen(t, hub)
	_test_ayan(t, hub)
	_test_shop(t, hub)
	_test_shop_ui(t, tree, hub)
	_test_guru(t, hub)
	_test_archive(t, hub)
	_test_portal(t, hub)
	_test_layout(t, hub)
	tree.root.remove_child(hub)
	hub.free()
	tree.paused = false


func _test_scene(t: Callable, hub: Hub) -> void:
	t.call(hub != null, true, "hub_scene_loads")
	t.call(hub.player != null, true, "hub_has_player")
	t.call(hub.player.get_node_or_null("Camera2D") != null, true, "hub_has_camera")
	t.call(hub.portal != null, true, "hub_has_portal")
	t.call(hub.dialogue_ui != null, true, "hub_has_dialogue_ui")
	t.call(hub.shop_ui != null, true, "hub_has_shop_ui")
	t.call(hub.profile != null, true, "hub_has_profile")
	t.call(hub.shop != null, true, "hub_has_shop")
	t.call(hub.profile.memory_fragments, 30, "hub_demo_fragments")


func _test_npcs(t: Callable, hub: Hub) -> void:
	var npcs := hub.get_npcs()
	t.call(npcs.size(), 5, "hub_npc_count")
	t.call(hub.get_npc(&"luchen") != null, true, "hub_npc_luchen")
	t.call(hub.get_npc(&"ayan") != null, true, "hub_npc_ayan")
	t.call(hub.get_npc(&"guru") != null, true, "hub_npc_guru")
	t.call(hub.get_npc(&"wenjin") != null, true, "hub_npc_wenjin")
	t.call(hub.get_npc(&"baiyu") != null, true, "hub_npc_baiyu")
	t.call(hub.get_npc(&"luchen").display_name, "陆沉", "hub_npc_luchen_name")
	t.call(hub.get_npc(&"ayan").display_name, "阿砚", "hub_npc_ayan_name")
	t.call(hub.get_npc(&"guru").display_name, "咕噜", "hub_npc_guru_name")
	t.call(hub.get_npc(&"wenjin").display_name, "闻烬", "hub_npc_wenjin_name")
	t.call(hub.get_npc(&"baiyu").display_name, "白榆", "hub_npc_baiyu_name")
	t.call(hub.get_npc(&"missing"), null, "hub_npc_missing")
	for npc in npcs:
		t.call(npc.dialogue != null, true, "hub_npc_dialogue_" + String(npc.npc_id))


func _test_dialogue(t: Callable, tree: SceneTree) -> void:
	var data := DialogueData.new()
	data.speaker = "陆沉"
	data.lines = ["一", "二", "三"]
	t.call(data.line_at(0), "一", "dialogue_line_0")
	t.call(data.line_at(3), "一", "dialogue_wrap")
	t.call(data.line_at(-1), "三", "dialogue_negative_wrap")
	t.call(data.line_count(), 3, "dialogue_line_count")

	var npc := NPC.new()
	npc.dialogue = data
	t.call(npc.interact(), "一", "npc_dialogue_0")
	t.call(npc.interact(), "二", "npc_dialogue_1")
	t.call(npc.interact(), "三", "npc_dialogue_2")
	t.call(npc.interact(), "一", "npc_dialogue_wrap")
	npc.free()

	var ui := DIALOGUE_SCENE.instantiate() as DialogueUI
	tree.root.add_child(ui)
	var panel := ui.find_child("Panel", true, false) as Control
	var portrait := ui.find_child("Portrait", true, false) as TextureRect
	var inspire := ui.find_child("InspireButton", true, false) as Button
	t.call(panel != null and portrait != null and inspire != null, true, "dialogue_portrait_and_button_exist")
	t.call(panel.is_ancestor_of(inspire), true, "dialogue_inspire_button_inside_panel")
	var finished := [0]
	var closed := [0]
	ui.finished.connect(func(): finished[0] += 1)
	ui.closed.connect(func(): closed[0] += 1)

	ui.open_dialogue("陆沉", ["第一句", "第二句"])
	t.call(portrait.texture != null, true, "dialogue_portrait_texture")
	t.call(ui.is_open(), true, "dialogue_ui_opens")
	t.call(ui.get_speaker_text(), "陆沉", "dialogue_ui_speaker")
	t.call(ui.get_line_text(), "第一句", "dialogue_ui_first_line")
	t.call(ui.get_progress_text(), "1 / 2", "dialogue_ui_progress")
	ui.advance()
	t.call(ui.get_line_text(), "第二句", "dialogue_ui_advance")
	ui.advance()
	t.call(ui.is_open(), false, "dialogue_ui_closes_after_last")
	t.call(finished[0], 1, "dialogue_ui_finished_once")
	t.call(closed[0], 1, "dialogue_ui_closed_once")

	ui.open_dialogue("阿砚", ["只有一句"])
	ui.close()
	t.call(ui.is_open(), false, "dialogue_ui_manual_close")
	t.call(finished[0], 1, "dialogue_ui_no_finish_on_manual_close")
	t.call(closed[0], 2, "dialogue_ui_closed_twice")

	tree.root.remove_child(ui)
	ui.free()


func _test_luchen(t: Callable, hub: Hub) -> void:
	var word := hub.get_word(&"grguan")
	t.call(word != null, true, "hub_word_lookup")
	var decoded_before := hub.profile.decoded_words.size()
	var message := hub.decode_word()
	t.call(String(message).contains("我替你解开"), true, "luchen_decodes_word")
	t.call(hub.profile.decoded_words.size(), decoded_before + 1, "luchen_records_one_decode")
	var decoded_id: StringName = hub.profile.decoded_words.back()
	var decoded_word := hub.get_word(decoded_id)
	t.call(decoded_word != null and decoded_word.decoded, true, "luchen_sets_hub_copy_decoded")
	t.call(hub.profile.is_word_unlocked(decoded_id), true, "luchen_unlocks_word")
	for index in 20:
		hub.decode_word()
	t.call(String(hub.decode_word()).contains("没有需要解读"), true, "luchen_reports_no_fragments")

	hub.talk_to_npc(hub.get_npc(&"luchen"))
	t.call(hub.dialogue_ui.is_open(), true, "luchen_dialogue_opens")
	t.call(hub.dialogue_ui.get_speaker_text(), "陆沉", "luchen_dialogue_speaker")
	t.call(hub.player.is_physics_processing(), false, "hub_freezes_player_in_dialogue")
	hub.dialogue_ui.close()
	t.call(hub.dialogue_ui.is_open(), false, "luchen_dialogue_closes")
	t.call(hub.player.is_physics_processing(), true, "hub_unfreezes_player_after_dialogue")


func _test_ayan(t: Callable, hub: Hub) -> void:
	hub.profile.memory_fragments = 100
	var level_before := hub.profile.weapon_base_level(SWORD_ID)
	var result := hub.upgrade_sword_base()
	t.call(bool(result.get("success", false)), true, "ayan_upgrade_success")
	t.call(hub.profile.weapon_base_level(SWORD_ID), level_before + 1, "ayan_level_up")
	t.call(int(result.get("cost", -1)), 10 + level_before * 10, "ayan_upgrade_cost")
	t.call(hub.profile.memory_fragments, 100 - int(result.get("cost", 0)), "ayan_fragments_spent")
	t.call(String(result.get("message", "")).contains("Lv."), true, "ayan_success_message")

	hub.profile.memory_fragments = 0
	var failed := hub.upgrade_sword_base()
	t.call(bool(failed.get("success", true)), false, "ayan_upgrade_fails")
	t.call(String(failed.get("message", "")).contains("不足"), true, "ayan_failure_message")
	t.call(hub.profile.memory_fragments, 0, "ayan_failure_no_charge")


func _test_shop(t: Callable, hub: Hub) -> void:
	t.call(hub.shop.stock.size(), 18, "shop_stock_size")
	hub.profile.memory_fragments = 60
	var entry := hub.shop.get_entry(&"xidi")
	t.call(entry.is_empty(), false, "shop_has_xidi")
	var cost := int(entry.get("cost", 0))
	t.call(cost > 0, true, "shop_price_positive")
	t.call(hub.buy_from_shop(&"jilu"), false, "shop_rejects_owned_starter")
	t.call(hub.buy_from_shop(&"xidi"), true, "shop_buy_succeeds")
	t.call(hub.profile.memory_fragments, 60 - cost, "shop_deducts_fragments")
	t.call(hub.profile.is_word_unlocked(&"xidi"), true, "shop_unlocks_word")
	t.call(hub.buy_from_shop(&"xidi"), false, "shop_rejects_owned")
	t.call(hub.buy_from_shop(&"missing"), false, "shop_rejects_missing")
	hub.profile.memory_fragments = maxi(cost - 1, 0)
	t.call(hub.buy_from_shop(&"quanbing"), false, "shop_rejects_insufficient")
	hub.profile.memory_fragments = 100
	t.call(hub.buy_from_shop(&"abyssal_bell"), true, "shop_buys_relic_for_next_run")
	t.call(hub.profile.stored_relics.has(&"abyssal_bell"), true, "shop_stores_relic")
	t.call(hub.buy_from_shop(&"abyssal_bell"), false, "shop_rejects_owned_relic")
	t.call(hub.profile.consume_stored_relics().size(), 1, "stored_relic_consumed_once")
	t.call(hub.profile.stored_relics.is_empty(), true, "stored_relic_cleared")


func _test_shop_ui(t: Callable, tree: SceneTree, hub: Hub) -> void:
	var ui := SHOP_SCENE.instantiate() as ShopUI
	tree.root.add_child(ui)
	ui.bind(hub.shop, hub.profile)
	hub.profile.memory_fragments = 100
	ui.open()
	t.call(ui.is_open(), true, "shop_ui_opens")
	t.call(ui.buy(&"quanbing"), true, "shop_ui_buys")
	t.call(hub.profile.memory_fragments, 82, "shop_ui_deducts")
	t.call(ui.get_message_text().contains("买下"), true, "shop_ui_success_message")
	t.call(ui.buy(&"missing"), false, "shop_ui_missing")
	t.call(ui.get_message_text().contains("没有"), true, "shop_ui_missing_message")
	ui.close()
	t.call(ui.is_open(), false, "shop_ui_closes")
	tree.root.remove_child(ui)
	ui.free()


func _test_guru(t: Callable, hub: Hub) -> void:
	hub.talk_to_npc(hub.get_npc(&"guru"))
	t.call(hub.dialogue_ui.is_open(), true, "guru_dialogue_opens")
	t.call(hub.shop_ui.is_open(), false, "guru_shop_waits_for_dialogue")
	var guard := 0
	while hub.dialogue_ui.is_open() and guard < 10:
		hub.dialogue_ui.advance()
		guard += 1
	t.call(hub.dialogue_ui.is_open(), false, "guru_dialogue_finishes")
	t.call(hub.shop_ui.is_open(), true, "guru_opens_shop")
	hub.shop_ui.close()
	t.call(hub.shop_ui.is_open(), false, "guru_shop_closes")
	t.call(hub.player.is_physics_processing(), true, "guru_unfreezes_player")


func _test_archive(t: Callable, hub: Hub) -> void:
	t.call(hub.archive_ui != null, true, "hub_has_archive_ui")
	hub.profile.memory_fragments = 1000
	hub.perform_npc_function(&"luchen", &"archive")
	t.call(hub.archive_ui.is_open(), true, "archive_opens_from_luchen")
	hub.archive_ui.close()
	hub.archive_ui.bind(hub.profile)
	hub.archive_ui.open()
	t.call(hub.archive_ui.is_open(), true, "archive_ui_opens")
	var before := hub.profile.archive_level(&"vitality")
	var cost := ArchiveData.cost(&"vitality", before)
	hub.archive_ui._buy(ArchiveData.track(&"vitality"))
	t.call(hub.profile.archive_level(&"vitality"), before + 1, "archive_ui_buys_level")
	t.call(hub.profile.memory_fragments, 1000 - cost, "archive_ui_deducts")
	hub.archive_ui.close()
	t.call(hub.archive_ui.is_open(), false, "archive_ui_closes")


func _test_portal(t: Callable, hub: Hub) -> void:
	var emissions := [0]
	var callback := func(): emissions[0] += 1
	hub.run_requested.connect(callback)
	hub.portal.activate()
	t.call(emissions[0], 1, "portal_emits_run_requested")
	hub.request_run()
	t.call(emissions[0], 2, "hub_request_run_emits")
	hub.run_requested.disconnect(callback)


func _test_layout(t: Callable, hub: Hub) -> void:
	var dialogue_panel := hub.dialogue_ui.find_child("Panel", true, false) as Control
	var shop_panel := hub.shop_ui.find_child("Panel", true, false) as Control
	var dialogue_size := dialogue_panel.get_combined_minimum_size()
	var shop_size := shop_panel.get_combined_minimum_size()
	t.call(dialogue_size.x > 0.0 and dialogue_size.x <= 1280.0, true, "dialogue_panel_width")
	t.call(dialogue_size.y > 0.0 and dialogue_size.y <= 720.0, true, "dialogue_panel_height")
	t.call(shop_size.x > 0.0 and shop_size.x <= 1280.0, true, "shop_panel_width")
	t.call(shop_size.y > 0.0 and shop_size.y <= 720.0, true, "shop_panel_height")
	t.call(hub.fragment_label != null, true, "hub_fragment_label")
	# A single-screen hub must not slide the whole frame when the player turns.
	t.call(is_zero_approx(hub.player.camera_look_ahead), true, "hub_camera_look_ahead_off")
