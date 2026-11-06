extends RefCounted

func run(t: Callable) -> void:
	var run := RunState.new()
	run.reset_for_new_run(7)
	t.call(run.pages, 0, "pages_start_at_zero")
	var seen: Array[int] = []
	run.pages_changed.connect(func(value: int): seen.append(value))
	run.add_pages(20)
	t.call(run.pages, 20, "pages_gain")
	t.call(seen.has(20), true, "pages_signal")
	t.call(run.spend_pages(5), true, "pages_spend")
	t.call(run.pages, 15, "pages_after_spend")
	t.call(run.spend_pages(99), false, "pages_cannot_overspend")
	t.call(run.pages, 15, "pages_unchanged_after_fail")

	var profile := Profile.new()
	var offers := RunLoot.shop_offers(run, 1, profile)
	t.call(offers.size(), 3, "shop_has_three_offers")
	t.call(int(offers[0]["cost"]) > 0, true, "shop_offer_has_cost")
	t.call(String(offers[0]["title"]) != "", true, "shop_offer_has_title")
	t.call(String(offers[0]["description"]), "恢复 35 生命与 45 墨量，并净化 12 点污染。",
		"shop_rest_offer_copy")

	var tree := Engine.get_main_loop() as SceneTree
	var ui := RunShopUI.new()
	tree.root.add_child(ui)
	var picked: Array[int] = []
	ui.buy.connect(func(index: int): picked.append(index))
	ui.open_shop(offers, 15)
	t.call(ui._buttons.size(), 3, "shop_ui_buttons")
	ui._buttons[0].pressed.emit()
	t.call(picked, [0], "shop_ui_emits_buy")
	ui.mark_bought(0, 15)
	t.call(ui._buttons[0].disabled, true, "shop_ui_disables_bought")

	# Reopening reuses the card pool (text is assigned after the cards are in
	# the tree; rebuilding them every open cost ~50 ms).
	var first_buttons: Array[Button] = ui._buttons.duplicate()
	ui.close_shop()
	ui.open_shop(offers, 15)
	t.call(ui._buttons.size(), 3, "shop_ui_reopen_buttons")
	t.call(ui._buttons[0], first_buttons[0], "shop_ui_reuses_cards")
	t.call(ui._buttons[2], first_buttons[2], "shop_ui_reuses_all_cards")
	t.call(ui._buttons[0].visible, true, "shop_ui_reused_card_visible")
	t.call(ui._buttons[0].text.contains(String(offers[0]["title"])), true,
		"shop_ui_reused_card_text")
	var short_offers: Array[Dictionary] = [offers[0], offers[1]]
	ui.open_shop(short_offers, 15)
	t.call(ui._buttons.size(), 2, "shop_ui_active_buttons_shrink")
	t.call(ui._pool.size(), 3, "shop_ui_pool_kept")
	t.call(ui._pool[2].visible, false, "shop_ui_extra_card_hidden")
	ui.open_shop(offers, 15)
	t.call(ui._buttons.size(), 3, "shop_ui_active_buttons_grow")
	t.call(ui._buttons[2].visible, true, "shop_ui_extra_card_visible")
	tree.root.remove_child(ui)
	ui.free()
	profile.free()
