extends SceneTree

## Real-controller pass over every remaining modal page. Settings and the
## keybind page already have A/B coverage in integration_gamepad; this suite
## checks map, story, shops, reward, authority, ending, dialogue, the Hub
## archive, the Hub settings subpages and the title new-game confirmation with
## actual joypad events, including pause state and focus hand-off.

var failures: int = 0
var assertions: int = 0

const PROFILE_PATH := "user://test_menus_profile.cfg"
const RUN_PATH := "user://test_menus_run.cfg"


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("MENUS FAIL: " + label)


func _initialize() -> void:
	_run.call_deferred()


func _cleanup_files() -> void:
	RunSave.clear(RUN_PATH)
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = PROFILE_PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _press_button(button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await _settle()


func _release_button(button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = false
	Input.parse_input_event(event)
	await _settle()


func _press_key(keycode: int) -> void:
	var event := InputEventKey.new()
	# Built-in ui_accept/ui_cancel match `keycode`; gameplay actions use the
	# physical key. Set both so one helper works for keyboard and UI paths.
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await _settle()


func _release_key(keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = false
	Input.parse_input_event(event)
	await _settle()


func _free_scene(scene) -> void:
	# A real quit ends the process; in-process scene swaps must not inherit a
	# paused tree or a modal page from the scene being freed.
	paused = false
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	await process_frame
	await process_frame


func _close_story(scene) -> void:
	if scene._story != null and scene._story.is_open():
		scene._story.close()


func _settle() -> void:
	await process_frame
	await process_frame


func _wait_mds(scene, timeout := 8.0) -> bool:
	var left: float = timeout
	while left > 0.0:
		if scene._mds_world != null and not scene._mds_world.changing_room and not scene._mds_world.current_room.is_empty():
			return true
		await create_timer(0.05).timeout
		left -= 0.05
	return false


## Hub personal events (叙事审计 E2). A real Hub conversation must replace the
## regular greeting once the trust tier and the chapter-progress gate line up,
## record itself only after the last line, and never grant a reward. The state
## is restored afterwards so the later trust/forge assertions read as before.
func _test_npc_personal_events(hub) -> void:
	# `hub` stays untyped on purpose: a compile-time `Hub` dependency would load
	# hub.gd (and its CodexUI chain) before the `--script` runner registers the
	# Flow autoload, which fails with "Identifier not found: Flow".
	var profile: Profile = hub.profile
	var events_before: Array[String] = profile.npc_events.duplicate()
	var trust_before: Dictionary = profile.npc_trust.duplicate(true)
	var fragments_before: int = profile.memory_fragments
	var cleared_before: bool = profile.demo_cleared
	var luchen = hub.get_npc(&"luchen")
	var ayan = hub.get_npc(&"ayan")
	var guru = hub.get_npc(&"guru")
	check(luchen != null and ayan != null and guru != null, "npc_event_npcs_present")
	if luchen == null or ayan == null or guru == null:
		return
	var luchen_event_lines: Array = NPCEventData.event_for(&"luchen").get("lines", [])

	# Trust alone is not enough: the chapter must have been finished once.
	profile.demo_cleared = false
	profile.add_npc_trust(&"luchen", 6.0)
	hub.talk_to_npc(luchen)
	await _settle()
	check(hub.dialogue_ui.is_open(), "npc_event_gate_regular_dialogue")
	check(hub.dialogue_ui.get_line_text() != String(luchen_event_lines[0]),
		"npc_event_gate_needs_progress")
	hub.dialogue_ui.close()
	await _settle()
	check(not profile.has_npc_event("luchen_red_folder"), "npc_event_gate_not_recorded")

	profile.demo_cleared = true
	profile.add_npc_trust(&"guru", 2.0)
	profile.add_npc_trust(&"ayan", 12.0)
	var fragments_at_setup: int = profile.memory_fragments
	var luchen_trust: float = profile.npc_trust_value(&"luchen")
	var ayan_trust: float = profile.npc_trust_value(&"ayan")
	var guru_trust: float = profile.npc_trust_value(&"guru")

	# 陆沉: the event replaces the greeting, completes, records once.
	var luchen_lines: Array = luchen_event_lines
	hub.talk_to_npc(luchen)
	await _settle()
	check(hub.dialogue_ui.is_open(), "npc_event_luchen_opens")
	check(hub.dialogue_ui.get_line_text() == String(luchen_lines[0]),
		"npc_event_luchen_starts_at_event")
	check(hub.dialogue_ui._lines.size() == luchen_lines.size(),
		"npc_event_luchen_replaces_regular_lines")
	for i in 32:
		if not hub.dialogue_ui.is_open():
			break
		hub.dialogue_ui.advance()
	await _settle()
	check(not hub.dialogue_ui.is_open(), "npc_event_luchen_completes")
	check(profile.has_npc_event("luchen_red_folder"), "npc_event_luchen_recorded")
	check(profile.memory_fragments == fragments_at_setup, "npc_event_luchen_no_fragments")
	check(is_equal_approx(profile.npc_trust_value(&"luchen"), luchen_trust),
		"npc_event_luchen_no_trust")
	# The next talk is the ordinary conversation again.
	hub.talk_to_npc(luchen)
	await _settle()
	check(hub.dialogue_ui.is_open(), "npc_event_luchen_regular_reopens")
	check(hub.dialogue_ui.get_line_text() == String(
		NPCProfiles.get_profile(&"luchen").get("greeting", "")),
		"npc_event_luchen_regular_greeting")
	check(hub.dialogue_ui._lines.size() > luchen_lines.size(),
		"npc_event_luchen_regular_not_event")
	hub.dialogue_ui.close()
	await _settle()

	# 阿砚: closing before the last line does not consume the event.
	var ayan_event := NPCEventData.event_for(&"ayan")
	var ayan_lines: Array = ayan_event.get("lines", [])
	hub.talk_to_npc(ayan)
	await _settle()
	check(hub.dialogue_ui.is_open(), "npc_event_ayan_opens")
	check(hub.dialogue_ui.get_line_text() == String(ayan_lines[0]),
		"npc_event_ayan_starts_at_event")
	hub.dialogue_ui.close()
	await _settle()
	check(not profile.has_npc_event("ayan_furnace"), "npc_event_ayan_early_close_unseen")
	hub.talk_to_npc(ayan)
	await _settle()
	check(hub.dialogue_ui.is_open(), "npc_event_ayan_retries")
	for i in 32:
		if not hub.dialogue_ui.is_open():
			break
		hub.dialogue_ui.advance()
	await _settle()
	check(profile.has_npc_event("ayan_furnace"), "npc_event_ayan_recorded")
	check(is_equal_approx(profile.npc_trust_value(&"ayan"), ayan_trust),
		"npc_event_ayan_no_trust")

	# 咕噜: the event must not tumble straight into the shop, but the ordinary
	# conversation still opens it exactly as before.
	var guru_event := NPCEventData.event_for(&"guru")
	var guru_lines: Array = guru_event.get("lines", [])
	hub.talk_to_npc(guru)
	await _settle()
	check(hub.dialogue_ui.is_open(), "npc_event_guru_opens")
	check(hub.dialogue_ui.get_line_text() == String(guru_lines[0]),
		"npc_event_guru_starts_at_event")
	for i in 32:
		if not hub.dialogue_ui.is_open():
			break
		hub.dialogue_ui.advance()
	await _settle()
	check(profile.has_npc_event("guru_bottle"), "npc_event_guru_recorded")
	check(not hub.shop_ui.is_open(), "npc_event_guru_no_shop_jump")
	check(is_equal_approx(profile.npc_trust_value(&"guru"), guru_trust),
		"npc_event_guru_no_trust")
	hub.talk_to_npc(guru)
	await _settle()
	check(hub.dialogue_ui.is_open(), "npc_event_guru_regular_reopens")
	for i in 32:
		if not hub.dialogue_ui.is_open():
			break
		hub.dialogue_ui.advance()
	await _settle()
	check(hub.shop_ui.is_open(), "npc_event_guru_regular_still_opens_shop")
	hub.shop_ui.close()
	await _settle()
	check(profile.npc_events.size() == events_before.size() + 3,
		"npc_event_three_flags_once")

	# Restore the numeric/profile state for the later trust checks, but keep the
	# three event ids marked: they are one-shot, so later talks must stay on the
	# regular greeting even if the suite raises trust again.
	profile.npc_trust = trust_before
	profile.memory_fragments = fragments_before
	profile.demo_cleared = cleared_before
	hub.dialogue_ui.close()
	hub.shop_ui.close()
	await _settle()


func _focus_owner() -> Control:
	return root.gui_get_focus_owner()


func _focus_is_reasonable() -> bool:
	var owner := _focus_owner()
	return owner == null or (owner.is_visible_in_tree() and not owner.is_queued_for_deletion())


func _run() -> void:
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.profile_path = PROFILE_PATH
	flow.run_save_path = RUN_PATH
	flow.title_shown_this_session = true
	flow.resume_requested = false
	flow.difficulty = 0
	_cleanup_files()
	await _settle()

	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.4).timeout
	if scene._story != null and scene._story.is_open():
		scene._story.close()
	check(await _wait_mds(scene), "menus_scene_loads")
	paused = false
	# Empty-state copy is authored data keyed by the run seed. The live codex
	# page may already show the run's resolved combos, so assert the seed
	# binding here; the empty grids themselves are covered by the unit tests.
	check(scene.codex_ui._run_seed_value() == scene.run_state.run_seed,
		"empty_state_codex_seed_bound")
	check(scene.inventory_ui._run_seed == scene.run_state.run_seed,
		"empty_state_inventory_bound_seed")
	var no_relics: Array[RelicData] = []
	check(scene.inventory_ui._build_relics_text(no_relics)
		== EmptyStateData.pick(&"inventory_relics", scene.run_state.run_seed),
		"empty_state_relic_copy_uses_run_seed")
	# Seed a real checkpoint for the title "继续本局" entry test at the end.
	flow.auto_save = true
	check(scene.save_run_now(), "menus_resume_seed_checkpoint")
	var resume_save := RunSave.read(RUN_PATH)
	check(not resume_save.is_empty(), "menus_resume_seed_read")
	flow.auto_save = false

	# Map: both B and A close the page and release the pause it owns.
	scene._map_overlay.open()
	await _settle()
	check(paused, "map_open_pauses")
	check(_focus_owner() != null, "map_open_focus")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(not scene._map_overlay.is_open(), "map_b_closes")
	check(not paused, "map_b_unpauses")
	scene._map_overlay.open()
	await _settle()
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(not scene._map_overlay.is_open(), "map_a_activates_close")
	check(not paused, "map_a_unpauses")

	# The map owns its own pause instead of living on the overlay stack. While
	# a modal page is open, M must not open it: closing the map would resume
	# the world underneath the still-visible page.
	scene._toggle_overlay(scene.codex_ui)
	await _settle()
	check(paused and scene.codex_ui.visible, "map_modal_codex_open")
	await _press_key(KEY_M)
	await _release_key(KEY_M)
	check(not scene._map_overlay.is_open(), "map_blocked_above_modal")
	check(paused, "map_blocked_keeps_pause")
	check(scene.codex_ui.visible, "map_blocked_keeps_codex")
	await _press_key(KEY_ESCAPE)
	await _release_key(KEY_ESCAPE)
	check(not scene.codex_ui.visible, "map_modal_escape_closes_codex")
	check(not paused, "map_modal_escape_unpauses")
	# The hotkey still works from normal gameplay.
	await _press_key(KEY_M)
	await _release_key(KEY_M)
	check(scene._map_overlay.is_open(), "map_hotkey_opens")
	check(paused, "map_hotkey_pauses")
	await _press_key(KEY_M)
	await _release_key(KEY_M)
	check(not scene._map_overlay.is_open(), "map_hotkey_closes")
	check(not paused, "map_hotkey_unpauses")
	# The pause key closes the map instead of opening the pause menu on top.
	await _press_key(KEY_M)
	await _release_key(KEY_M)
	await _press_key(KEY_P)
	await _release_key(KEY_P)
	check(not scene._map_overlay.is_open(), "map_pause_key_closes")
	check(not paused, "map_pause_key_unpauses")
	check(not scene.pause_menu.is_open(), "map_pause_key_no_menu")

	# Game pages: each hotkey opens and closes its own overlay with a visible
	# focus target, and swapping pages must not leave the old one running.
	flow.set_keybind(&"inventory", KEY_TAB)
	flow.set_keybind(&"codex", KEY_C)
	flow.set_keybind(&"help", KEY_H)
	flow.set_keybind(&"settings", KEY_F10)
	for entry in [
		[KEY_TAB, scene.inventory_ui, "inventory"],
		[KEY_C, scene.codex_ui, "codex"],
		[KEY_H, scene._help_ui, "help"],
		[KEY_F10, scene.settings_menu, "settings"],
	]:
		await _press_key(entry[0])
		await _release_key(entry[0])
		check(scene._overlay == entry[1] and paused and entry[1].visible,
			"overlay_hotkey_opens_" + entry[2])
		var opened_focus := _focus_owner()
		check(opened_focus != null and opened_focus.is_visible_in_tree(),
			"overlay_hotkey_focus_" + entry[2])
		await _press_key(entry[0])
		await _release_key(entry[0])
		check(scene._overlay == null and not paused and not entry[1].visible,
			"overlay_hotkey_closes_" + entry[2])
		var closed_focus := _focus_owner()
		check(closed_focus == null or closed_focus.is_visible_in_tree(),
			"overlay_hotkey_close_focus_" + entry[2])

	await _press_key(KEY_TAB)
	await _release_key(KEY_TAB)
	await _press_key(KEY_C)
	await _release_key(KEY_C)
	check(scene._overlay == scene.codex_ui and scene.codex_ui.visible and paused,
		"overlay_replace_codex")
	check(not scene.inventory_ui.visible, "overlay_replace_hides_inventory")
	var replaced_focus := _focus_owner()
	check(replaced_focus == null or replaced_focus.is_visible_in_tree(),
		"overlay_replace_focus_visible")
	await _press_key(KEY_C)
	await _release_key(KEY_C)
	check(scene._overlay == null and not paused, "overlay_replace_closes")
	# Help shown by hotkey uses show(), not open(); its internal flag must still
	# follow visibility when another page replaces it.
	await _press_key(KEY_H)
	await _release_key(KEY_H)
	await _press_key(KEY_TAB)
	await _release_key(KEY_TAB)
	check(scene._overlay == scene.inventory_ui and scene.inventory_ui.visible,
		"overlay_help_replace_inventory")
	check(not scene._help_ui.visible and not scene._help_ui._open,
		"overlay_help_state_synced_on_replace")
	await _press_key(KEY_TAB)
	await _release_key(KEY_TAB)
	check(scene._overlay == null and not paused, "overlay_help_replace_closes")

	# Story continue page: A presses the focused button, B backs out.
	scene._story.open_story("probe", "probe", ["第一行"], "")
	await _settle()
	check(paused, "story_open_pauses")
	check(_focus_owner() != null, "story_open_focus")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(not scene._story.is_open(), "story_b_closes")
	check(not paused, "story_b_unpauses")
	scene._story.open_story("probe", "probe", ["第一行"], "")
	await _settle()
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(not scene._story.is_open(), "story_a_continues")
	check(not paused, "story_a_unpauses")

	# Story choice page is a required pick: B must not skip it.
	var story_options: Array[Dictionary] = [
		{"label": "甲", "note": ""}, {"label": "乙", "note": ""},
	]
	var story_picked: Array[int] = []
	scene._story.choice_made.connect(func(index: int): story_picked.append(index))
	scene._story.open_choice("probe", "probe", "选择", story_options)
	await _settle()
	check(paused, "story_choice_pauses")
	check(_focus_owner() != null, "story_choice_focus")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(scene._story.is_open(), "story_choice_b_is_ignored")
	check(paused, "story_choice_keeps_pause")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(story_picked == [0], "story_choice_a_picks")
	check(not paused, "story_choice_a_unpauses")

	# Run shop: B leaves; A buys the focused row.
	var bought: Array[int] = []
	scene._shop_ui.buy.connect(func(index: int): bought.append(index))
	var run_shop_offers: Array[Dictionary] = [
		{"title": "甲", "cost": 1, "description": "", "bought": false},
		{"title": "乙", "cost": 1, "description": "", "bought": false},
	]
	scene._shop_ui.open_shop(run_shop_offers, 5)
	await _settle()
	check(_focus_owner() != null, "run_shop_focus")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(not scene._shop_ui.visible, "run_shop_b_closes")
	var run_shop_one: Array[Dictionary] = [
		{"title": "甲", "cost": 1, "description": "", "bought": false},
	]
	scene._shop_ui.open_shop(run_shop_one, 5)
	await _settle()
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(bought.size() == 1, "run_shop_a_buys")
	scene._shop_ui.close_shop()

	# Opening on an unaffordable first row must land on a pressable row.
	var mixed_offers: Array[Dictionary] = [
		{"title": "贵", "cost": 999, "description": "", "bought": false},
		{"title": "便宜", "cost": 1, "description": "", "bought": false},
	]
	scene._shop_ui.open_shop(mixed_offers, 5)
	await _settle()
	var mixed_focus := _focus_owner() as Button
	check(mixed_focus != null and not mixed_focus.disabled, "run_shop_focus_skips_unaffordable")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(bought == [0, 1], "run_shop_a_buys_affordable_row")
	scene._shop_ui.close_shop()

	# Buying keeps a controller on a pressable row so A twice buys two rows.
	var multi_offers: Array[Dictionary] = [
		{"title": "甲", "cost": 1, "description": "", "bought": false},
		{"title": "乙", "cost": 1, "description": "", "bought": false},
		{"title": "丙", "cost": 1, "description": "", "bought": false},
	]
	scene._shop_ui.open_shop(multi_offers, 999)
	await _settle()
	var mark_bought := func(index: int) -> void: scene._shop_ui.mark_bought(index, 999)
	scene._shop_ui.buy.connect(mark_bought)
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	var after_buy_focus := _focus_owner() as Button
	check(after_buy_focus != null and not after_buy_focus.disabled, "run_shop_focus_after_buy")
	check(scene._shop_ui._error_label.text == "成交。", "run_shop_success_text")
	check(scene._shop_ui._error_label.get_theme_color("font_color") == UIPalette.SEAL_GOLD,
		"run_shop_success_is_not_red")
	scene._shop_ui.show_error("测试")
	check(scene._shop_ui._error_label.get_theme_color("font_color") == UIPalette.CINNABAR,
		"run_shop_error_is_red")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(bought.size() == 4, "run_shop_second_a_buys_next")
	scene._shop_ui.buy.disconnect(mark_bought)
	scene._shop_ui.close_shop()

	# Nothing affordable: focus falls back to the close button, and A leaves.
	var poor_offers: Array[Dictionary] = [
		{"title": "贵", "cost": 99, "description": "", "bought": false},
	]
	scene._shop_ui.open_shop(poor_offers, 0)
	await _settle()
	var close_focus := _focus_owner() as Button
	check(close_focus != null and not close_focus.disabled, "run_shop_focus_falls_back_to_close")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(not scene._shop_ui.visible, "run_shop_a_closes_when_nothing_affordable")

	# Reward pick: A takes the focused card.
	var reward_picked: Array[int] = []
	scene._reward_ui.chosen.connect(func(index: int): reward_picked.append(index))
	var reward_choices: Array[Dictionary] = [
		{"kind": &"relic", "title": "甲", "description": ""},
		{"kind": &"word", "title": "乙", "description": ""},
	]
	scene._reward_ui.open_choices(reward_choices)
	await _settle()
	check(_focus_owner() != null, "reward_focus")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(reward_picked == [0], "reward_a_picks")

	# Real room-clear reward page: game.gd pauses the world and requires a
	# pick. B/Esc must not skip it or stack a pause menu; arrows move focus;
	# confirming hands control back without leaving focus on hidden cards.
	scene._reward_options = RunLoot.choices(scene.run_state, 3, flow.profile, scene._chapter)
	scene._open_reward()
	await _settle()
	check(paused, "reward_real_pauses")
	var real_reward_focus := _focus_owner()
	check(real_reward_focus is Button and real_reward_focus.is_visible_in_tree(),
		"reward_real_focus_visible")
	check(real_reward_focus == scene._reward_ui._cards.get_child(0),
		"reward_real_focus_first")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(scene._reward_ui.visible, "reward_real_b_ignored")
	check(paused, "reward_real_b_keeps_pause")
	await _press_key(KEY_ESCAPE)
	await _release_key(KEY_ESCAPE)
	check(scene._reward_ui.visible, "reward_real_esc_ignored")
	check(paused, "reward_real_esc_keeps_pause")
	check(not scene.pause_menu.is_open(), "reward_real_esc_no_pause_menu")
	await _press_key(KEY_RIGHT)
	await _release_key(KEY_RIGHT)
	check(_focus_owner() == scene._reward_ui._cards.get_child(1),
		"reward_real_arrow_moves_focus")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	await _settle()
	check(not scene._reward_ui.visible, "reward_real_a_picks")
	check(not paused, "reward_real_a_unpauses")
	check(not scene.pause_menu.is_open(), "reward_real_a_no_pause_menu")
	check(_focus_is_reasonable(), "reward_real_a_focus_not_hidden")
	check(scene._reward_options.is_empty(), "reward_real_a_consumes_options")
	check(scene.hud.get_message_text().begins_with("获得："), "reward_real_a_message")
	check(scene.player.is_physics_processing(), "reward_real_player_processing")

	# Authority is required: B/Esc are ignored, A/Enter picks. Both devices
	# must leave the page open and the world paused while it is mandatory.
	var authority_picked: Array[int] = []
	scene._authority_choice.chosen.connect(func(index: int): authority_picked.append(index))
	scene._authority_choice.open(scene._chapter_plan.authority_pool)
	await _settle()
	check(paused, "authority_pauses")
	check(_focus_owner() != null, "authority_focus")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(scene._authority_choice.is_open(), "authority_b_is_ignored")
	check(paused, "authority_keeps_pause")
	await _press_key(KEY_ESCAPE)
	await _release_key(KEY_ESCAPE)
	check(scene._authority_choice.is_open(), "authority_esc_is_ignored")
	check(paused, "authority_esc_keeps_pause")
	check(not scene.pause_menu.is_open(), "authority_esc_no_pause_page")
	await _press_key(KEY_ENTER)
	await _release_key(KEY_ENTER)
	check(authority_picked == [0], "authority_enter_picks")
	check(not paused, "authority_enter_unpauses")
	# Second open exercises the pad confirm path after the keyboard round.
	scene._authority_choice.open(scene._chapter_plan.authority_pool)
	await _settle()
	check(paused, "authority_reopens_paused")
	check(_focus_owner() != null, "authority_reopens_focus")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(scene._authority_choice.is_open(), "authority_reopen_b_ignored")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(authority_picked == [0, 0], "authority_reopen_a_picks")
	check(not paused, "authority_reopen_a_unpauses")

	# Settings owns its subpages: closing one returns focus to its opener, the
	# Settings shortcut closes one level per press, and switching overlays does
	# not leave a subpage floating above the replacement.
	scene.pause_menu.open_pause()
	await _settle()
	var pause_settings_button := scene.pause_menu.find_child("SettingsButton", true, false) as Button
	check(pause_settings_button != null, "close_return_pause_settings_exists")
	if pause_settings_button != null:
		pause_settings_button.grab_focus()
		await _settle()
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		check(scene.settings_menu.visible, "close_return_settings_open")
		var ai_opener: Button = null
		for button in scene.settings_menu.find_children("*", "Button", true, false):
			if String(button.text).contains("AI"):
				ai_opener = button
				break
		check(ai_opener != null, "close_return_ai_button")
		if ai_opener != null:
			ai_opener.grab_focus()
			await _settle()
			await _press_button(JOY_BUTTON_A)
			await _release_button(JOY_BUTTON_A)
			var ai_page: AISettingsUI = scene.settings_menu._ai_page
			check(ai_page != null and ai_page.visible, "close_return_ai_open")
			await _press_button(JOY_BUTTON_B)
			await _release_button(JOY_BUTTON_B)
			check(ai_page == null or not ai_page.visible, "close_return_b_closes_ai")
			check(scene.settings_menu.visible, "close_return_settings_stays")
			check(paused, "close_return_ai_keeps_pause")
			check(_focus_owner() == ai_opener, "close_return_ai_focus")
			# The Settings shortcut closes the subpage first, not the whole page.
			await _press_button(JOY_BUTTON_A)
			await _release_button(JOY_BUTTON_A)
			check(ai_page != null and ai_page.visible, "close_return_ai_reopen")
			await _press_key(KEY_F10)
			await _release_key(KEY_F10)
			check(scene.settings_menu.visible, "close_return_settings_key_keeps_settings")
			check(ai_page == null or not ai_page.visible, "close_return_settings_key_closes_subpage")
			check(paused, "close_return_settings_key_keeps_pause")
			# Another overlay shortcut must take the subpage down with Settings.
			await _press_button(JOY_BUTTON_A)
			await _release_button(JOY_BUTTON_A)
			check(ai_page != null and ai_page.visible, "close_return_ai_reopen_again")
			await _press_key(KEY_C)
			await _release_key(KEY_C)
			check(scene.codex_ui.visible, "close_return_codex_open")
			check(not scene.settings_menu.visible, "close_return_codex_replaces_settings")
			check(ai_page == null or not ai_page.visible, "close_return_no_stranded_subpage")
			await _press_button(JOY_BUTTON_B)
			await _release_button(JOY_BUTTON_B)
			check(not scene.codex_ui.visible, "close_return_codex_b_closes")
			check(not paused, "close_return_codex_b_resumes")

	# Keybind and help subpages share the close-back path but have their own
	# lifecycles, and Help is also the standalone overlay: reopening it with the
	# help shortcut must not leave a visible page whose own close button is dead
	# (its open flag used to stay false after the overlay's show()).
	scene.pause_menu.open_pause()
	await _settle()
	var pause_settings_again := scene.pause_menu.find_child("SettingsButton", true, false) as Button
	check(pause_settings_again != null, "subpage_roundtrip_settings_button")
	if pause_settings_again != null:
		pause_settings_again.grab_focus()
		await _settle()
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		check(scene.settings_menu.visible, "subpage_roundtrip_settings_open")
		for needle in ["键位设置", "操作说明"]:
			var opener: Button = null
			for button in scene.settings_menu.find_children("*", "Button", true, false):
				if String(button.text).contains(needle):
					opener = button
					break
			check(opener != null, "subpage_roundtrip_button_" + needle)
			if opener == null:
				continue
			opener.grab_focus()
			await _settle()
			await _press_button(JOY_BUTTON_A)
			await _release_button(JOY_BUTTON_A)
			check(scene.settings_menu.has_subpage(), "subpage_roundtrip_open_" + needle)
			await _press_button(JOY_BUTTON_B)
			await _release_button(JOY_BUTTON_B)
			check(not scene.settings_menu.has_subpage(), "subpage_roundtrip_closed_" + needle)
			check(scene.settings_menu.visible, "subpage_roundtrip_keeps_settings_" + needle)
			check(paused, "subpage_roundtrip_keeps_pause_" + needle)
			check(_focus_owner() == opener, "subpage_roundtrip_focus_" + needle)
		var help_opener: Button = null
		for button in scene.settings_menu.find_children("*", "Button", true, false):
			if String(button.text).contains("操作说明"):
				help_opener = button
				break
		check(help_opener != null, "help_overlay_opener")
		if help_opener != null:
			help_opener.grab_focus()
			await _settle()
			await _press_button(JOY_BUTTON_A)
			await _release_button(JOY_BUTTON_A)
			check(scene.settings_menu.has_subpage(), "help_overlay_subpage_open")
			await _press_key(KEY_H)
			await _release_key(KEY_H)
			check(scene._help_ui.visible, "help_overlay_visible")
			# The map works in every MDS chapter (1–3 now); the help sheet must
			# not claim it belongs to Chapter 1 alone.
			var map_label := ""
			var map_key := ""
			for row in scene._help_ui._explore_content.get_children():
				if row is HBoxContainer and row.get_child_count() >= 2:
					var name_label := row.get_child(0) as Label
					if name_label != null and name_label.text.begins_with("地图"):
						map_label = name_label.text
						map_key = (row.get_child(1) as Label).text
			check(map_label == "地图", "help_map_label_chapter_neutral")
			check(map_key == GameFlow.input_label(&"map"), "help_map_key_matches_binding")
			check(not scene.settings_menu.visible, "help_overlay_replaces_settings")
			check(paused, "help_overlay_keeps_pause")
			scene._help_ui.close()
			check(not scene._help_ui.visible, "help_overlay_close_works")
			await _settle()
			check(not paused, "help_overlay_close_resumes")

	# Ending screen: its focused button returns to the Hub with A. The page owns
	# the ending state (a real finish sets `_finished`), so B must not open a
	# pause page behind it or drop the button focus. (Start is the pad's
	# `restart` binding and intentionally returns to the Hub.)
	scene._finished = true
	scene.ending_screen.show_campaign_ending(true, 0, {"title": "探针", "body": "探针"}, 0, 0, true, 424242)
	await _settle()
	check(scene.ending_screen._hint != null
		and scene.ending_screen._hint.text == EndingHintData.format_hint(
			EndingHintData.pick(424242, true), flow.prompt_label(&"restart")),
		"ending_hint_matches_run_seed")
	check(scene.ending_screen._hint.text.contains("回到最后的档案馆"),
		"ending_hint_keeps_destination")
	check(scene.ending_screen._hint.text.contains("按 "),
		"ending_hint_keeps_key_prompt")
	check(_focus_owner() != null, "ending_focus")
	check(_focus_owner() == scene.ending_screen._return_button, "ending_focus_return_button")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(scene.ending_screen.visible, "ending_b_keeps_page")
	check(not scene.pause_menu.is_open(), "ending_b_no_pause_page")
	check(_focus_owner() == scene.ending_screen._return_button, "ending_b_keeps_focus")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	await create_timer(0.6).timeout
	var hub = current_scene
	check(hub != null and hub.has_method("talk_to_npc"), "ending_a_returns_to_hub")
	if hub == null or not hub.has_method("talk_to_npc"):
		_cleanup_files()
		print("MENUS INTEGRATION: %d checks, %d failures" % [assertions, failures])
		quit(1)
		return

	# Hub dialogue: focus starts on 继续, A advances, B closes.
	var talkable = null
	for candidate in hub.get_npcs():
		if candidate.npc_id != &"wenjin" and candidate.npc_id != &"baiyu":
			talkable = candidate
			break
	check(talkable != null, "hub_has_talkable_npc")
	if talkable != null:
		hub.talk_to_npc(talkable)
		await _settle()
		check(hub.dialogue_ui.is_open(), "hub_dialogue_open")
		var first_line: String = hub.dialogue_ui.get_line_text()
		check(_focus_owner() != null and String(_focus_owner().name) == "ContinueButton", "hub_dialogue_focus_continue")
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		check(hub.dialogue_ui.is_open(), "hub_dialogue_a_keeps_open")
		check(hub.dialogue_ui.get_line_text() != first_line, "hub_dialogue_a_advances")
		await _press_button(JOY_BUTTON_B)
		await _release_button(JOY_BUTTON_B)
		check(not hub.dialogue_ui.is_open(), "hub_dialogue_b_closes")

	await _test_npc_personal_events(hub)

	# Hub shop: focus lands on the first buyable row, B closes, A buys and
	# keeps focus on the next row so a second A also works.
	var shop_bought: Array[StringName] = []
	hub.shop_ui.purchased.connect(func(id: StringName): shop_bought.append(id))
	hub.profile.memory_fragments = 999
	hub.shop_ui.bind(hub.shop, hub.profile)
	hub.shop_ui.open()
	await _settle()
	check(_focus_owner() != null, "hub_shop_focus")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(not hub.shop_ui.is_open(), "hub_shop_b_closes")
	hub.shop_ui.open()
	await _settle()
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(shop_bought.size() == 1, "hub_shop_a_buys")
	check(_focus_owner() != null, "hub_shop_focus_after_buy")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(shop_bought.size() == 2, "hub_shop_second_a_buys")
	hub.shop_ui.close()

	# Hub archive: focus, B closes, A upgrades.
	var archive_bought: Array[StringName] = []
	hub.archive_ui.purchased.connect(func(id: StringName): archive_bought.append(id))
	# Stand in for whatever the player was focused on before the page opened.
	# The Hub polls actions rather than navigating focus, but every other page
	# hands focus back, and the archive used to leave the viewport with none.
	var archive_opener := Button.new()
	archive_opener.name = "ArchiveOpenerProbe"
	hub.add_child(archive_opener)
	await _settle()
	archive_opener.grab_focus()
	hub.archive_ui.bind(hub.profile)
	hub.archive_ui.open()
	await _settle()
	check(_focus_owner() != null, "hub_archive_focus")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(not hub.archive_ui.is_open(), "hub_archive_b_closes")
	check(_focus_owner() == archive_opener, "hub_archive_close_returns_focus")
	hub.archive_ui.open()
	await _settle()
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(archive_bought.size() == 1, "hub_archive_a_buys")
	hub.archive_ui.close()

	# An early visit with no fragments must focus the close button instead of a
	# disabled upgrade row that swallows A.
	var saved_fragments: int = int(hub.profile.memory_fragments)
	hub.profile.memory_fragments = 0
	hub.archive_ui.bind(hub.profile)
	hub.archive_ui.open()
	await _settle()
	var archive_focus := _focus_owner() as Button
	check(archive_focus != null and not archive_focus.disabled, "hub_archive_focus_skips_unaffordable")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(not hub.archive_ui.is_open(), "hub_archive_a_closes_when_broke")
	hub.profile.memory_fragments = saved_fragments

	# Buying the last affordable archive upgrade disables the focused row; the
	# page must hand focus to another pressable control instead of swallowing A.
	var broke_archive_profile := Profile.new()
	var first_track := StringName(ArchiveData.TRACKS[0].get(&"id", &""))
	broke_archive_profile.memory_fragments = ArchiveData.cost(first_track, 0)
	hub.archive_ui.bind(broke_archive_profile)
	hub.archive_ui.open()
	await _settle()
	var broke_archive_start := _focus_owner() as Button
	check(broke_archive_start != null and not broke_archive_start.disabled, "hub_archive_exhaust_start_pressable")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	var broke_archive_focus := _focus_owner() as Button
	check(broke_archive_focus != null, "hub_archive_exhaust_focus_exists")
	check(broke_archive_focus != null and not broke_archive_focus.disabled, "hub_archive_exhaust_focus_pressable")
	check(broke_archive_focus != null and broke_archive_focus.is_visible_in_tree(), "hub_archive_exhaust_focus_visible")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(not hub.archive_ui.is_open(), "hub_archive_exhaust_a_closes")
	hub.archive_ui.bind(hub.profile)
	broke_archive_profile.free()
	await _settle()

	# A track already at the demo cap must report the cap, not a phantom
	# "记忆碎片不足：需要 X，你只有 Y" with Y > X. The row stops being pressable
	# and focus moves to the close button when every track is maxed.
	var maxed_archive_profile := Profile.new()
	var maxed_track := StringName(ArchiveData.TRACKS[0].get(&"id", &""))
	for entry in ArchiveData.TRACKS:
		maxed_archive_profile.archive_levels[String(entry.get(&"id", &""))] = ArchiveData.MAX_LEVEL
	maxed_archive_profile.memory_fragments = 100000
	hub.archive_ui.bind(maxed_archive_profile)
	hub.archive_ui.open()
	await _settle()
	var maxed_row: Dictionary = hub.archive_ui._rows[maxed_track]
	var maxed_button := maxed_row["button"] as Button
	var maxed_cost_label := maxed_row["cost"] as Label
	check(maxed_button.disabled, "hub_archive_maxed_row_disabled")
	check(maxed_button.text == "已满级", "hub_archive_maxed_row_text")
	check(maxed_cost_label.text.contains("上限"), "hub_archive_maxed_cost_text")
	var maxed_focus := _focus_owner() as Button
	check(maxed_focus != null and not maxed_focus.disabled,
		"hub_archive_maxed_focus_skips_disabled_rows")
	var maxed_fragments := int(maxed_archive_profile.memory_fragments)
	hub.archive_ui._buy(ArchiveData.TRACKS[0])
	check(int(maxed_archive_profile.memory_fragments) == maxed_fragments,
		"hub_archive_maxed_does_not_charge")
	check(maxed_archive_profile.archive_level(maxed_track) == ArchiveData.MAX_LEVEL,
		"hub_archive_maxed_keeps_level")
	check(not hub.archive_ui._status.text.contains("记忆碎片不足"),
		"hub_archive_maxed_no_false_shortage")
	check(hub.archive_ui._status.text.contains("上限"),
		"hub_archive_maxed_status_explains_cap")
	var luchen_archive_desc := ""
	for entry in NPCProfiles.get_profile(&"luchen").get("functions", []):
		if StringName(entry.get("id", &"")) == &"archive":
			luchen_archive_desc = String(entry.get("desc", ""))
	check(luchen_archive_desc.contains("上限"),
		"hub_archive_function_desc_states_cap")
	hub.archive_ui.close()
	hub.archive_ui.bind(hub.profile)
	maxed_archive_profile.free()
	await _settle()

	# Buying the tenth and final level must report the cap, not quote a
	# "next" price the demo can never charge (pass 70).
	var cap_archive_profile := Profile.new()
	var cap_track := StringName(ArchiveData.TRACKS[0].get(&"id", &""))
	cap_archive_profile.archive_levels[String(cap_track)] = ArchiveData.MAX_LEVEL - 1
	cap_archive_profile.memory_fragments = 100000
	hub.archive_ui.bind(cap_archive_profile)
	hub.archive_ui.open()
	await _settle()
	hub.archive_ui._buy(ArchiveData.TRACKS[0])
	check(cap_archive_profile.archive_level(cap_track) == ArchiveData.MAX_LEVEL,
		"hub_archive_final_level_reaches_cap")
	check(hub.archive_ui._status.text.contains("上限"),
		"hub_archive_final_level_status_explains_cap")
	check(not hub.archive_ui._status.text.contains("下次需要"),
		"hub_archive_final_level_no_phantom_next_cost")
	hub.archive_ui.close()
	hub.archive_ui.bind(hub.profile)
	cap_archive_profile.free()
	await _settle()

	# The copy that opens the archive and the service line in 陆沉's dialogue
	# must state the same demo cap the page enforces. The old lines promised
	# "等级没有尽头", which the page itself contradicted.
	var archive_open_message: String = hub.perform_npc_function(&"luchen", &"archive")
	check(archive_open_message.contains("Lv.%d" % ArchiveData.MAX_LEVEL),
		"hub_archive_open_message_states_cap")
	check(not archive_open_message.contains("等级没有尽头"),
		"hub_archive_open_message_no_endless_level_claim")
	check(hub.archive_ui.is_open(), "hub_archive_open_message_opens_page")
	hub.archive_ui.close()
	hub.archive_ui.bind(hub.profile)
	await _settle()
	var saved_cleared: bool = bool(hub.profile.demo_cleared)
	hub.profile.demo_cleared = false
	hub.talk_to_npc(hub.get_npc(&"luchen"))
	await _settle()
	var archive_service_line := ""
	for line in hub.dialogue_ui._lines:
		if line.contains("档案馆升级"):
			archive_service_line = line
	check(archive_service_line.contains("%d 级" % ArchiveData.MAX_LEVEL),
		"hub_archive_service_line_states_cap")
	check(not archive_service_line.contains("没有尽头"),
		"hub_archive_service_line_no_endless_level_claim")
	hub.dialogue_ui.close()
	hub.profile.demo_cleared = saved_cleared
	await _settle()

	# Same edge for the Hub shop: the last affordable purchase must not leave
	# focus on the row it just disabled.
	var broke_shop_profile := Profile.new()
	broke_shop_profile.memory_fragments = hub.shop.price_for(
		StringName(hub.shop.stock[0].get("id", &"")))
	hub.shop_ui.bind(hub.shop, broke_shop_profile)
	hub.shop_ui.open()
	await _settle()
	var broke_shop_start := _focus_owner() as Button
	check(broke_shop_start != null and not broke_shop_start.disabled, "hub_shop_exhaust_start_pressable")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	var broke_shop_focus := _focus_owner() as Button
	check(broke_shop_focus != null, "hub_shop_exhaust_focus_exists")
	check(broke_shop_focus != null and not broke_shop_focus.disabled, "hub_shop_exhaust_focus_pressable")
	check(broke_shop_focus != null and broke_shop_focus.is_visible_in_tree(), "hub_shop_exhaust_focus_visible")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	# Unaffordable Hub rows stay pressable on purpose: A must answer with a
	# message rather than swallow the press. The failure copy is authored and
	# stable per item id; none of the three failure branches may spend anything.
	check(hub.shop_ui.is_open(), "hub_shop_exhaust_a_gives_feedback")
	check(hub.shop_ui.get_message_text().contains("记忆碎片不足"), "hub_shop_exhaust_feedback_text")
	var short_id := &""
	if broke_shop_focus != null:
		short_id = StringName(broke_shop_focus.get_meta(&"shop_item_id", &""))
	var short_cost: int = hub.shop.price_for(short_id)
	var expected_short := ShopFailData.format(
		ShopFailData.pick(&"insufficient", short_id), short_cost,
		broke_shop_profile.memory_fragments)
	check(hub.shop_ui.get_message_text() == expected_short,
		"hub_shop_exhaust_feedback_authored")
	check(expected_short.contains(str(short_cost))
		and expected_short.contains(str(broke_shop_profile.memory_fragments)),
		"hub_shop_exhaust_feedback_keeps_numbers")
	var fail_fragments: int = broke_shop_profile.memory_fragments
	check(not hub.shop_ui.buy(&"jilu"), "hub_shop_owned_buy_rejected")
	check(hub.shop_ui.get_message_text()
		== ShopFailData.format(ShopFailData.pick(&"owned", &"jilu")),
		"hub_shop_owned_feedback_authored")
	check(hub.shop_ui.get_message_text().begins_with("这件货已经在你的手里了。"),
		"hub_shop_owned_feedback_keeps_meaning")
	check(not hub.shop_ui.buy(&"__missing_item__"), "hub_shop_missing_buy_rejected")
	check(hub.shop_ui.get_message_text()
		== ShopFailData.format(ShopFailData.pick(&"missing", &"__missing_item__")),
		"hub_shop_missing_feedback_authored")
	check(hub.shop_ui.get_message_text().begins_with("没有这件货。"),
		"hub_shop_missing_feedback_keeps_meaning")
	check(broke_shop_profile.memory_fragments == fail_fragments,
		"hub_shop_failed_buys_do_not_spend")
	hub.shop_ui.close()
	hub.shop_ui.bind(hub.shop, hub.profile)
	broke_shop_profile.free()
	await _settle()

	# Trust tiers: the dialogue attitude, the AI prompt, the shelf discount and
	# the 托付 forge favour all read the same derived tier, and none of them
	# stack a second benefit on top of an authored blessing.
	var trust_snapshot: Dictionary = hub.profile.npc_trust.duplicate(true)
	var blessing_snapshot: Dictionary = hub.profile.npc_blessings.duplicate(true)
	var fragments_snapshot: int = int(hub.profile.memory_fragments)
	var base_snapshot: Dictionary = hub.profile.weapon_base_levels.duplicate(true)
	var shop_discount_snapshot: float = hub.shop.discount
	hub.profile.add_npc_trust(&"guru", 12.0)
	hub.profile.add_npc_trust(&"ayan", 12.0)
	var guru_npc = hub.get_npc(&"guru")
	hub.talk_to_npc(guru_npc)
	await _settle()
	check(hub.dialogue_ui.is_open(), "hub_trust_dialogue_open")
	check(hub.dialogue_ui._lines.size() >= 2
		and hub.dialogue_ui._lines[1] == NPCProfiles.trust_line(&"guru", 3),
		"hub_trust_dialogue_attitude")
	check(String(hub._npc_prompt_profile(&"guru").get("trust_tier", "")) == "托付",
		"hub_trust_prompt_tier")
	check(String(hub._npc_prompt_profile(&"guru").get("trust_attitude", ""))
		== NPCProfiles.trust_line(&"guru", 3), "hub_trust_prompt_attitude")
	hub.dialogue_ui.close()
	await _settle()

	hub.profile.memory_fragments = 999
	hub.perform_npc_function(&"guru", &"shop")
	await _settle()
	check(is_equal_approx(hub.shop.discount, 0.15), "hub_trust_shop_discount")
	hub.shop_ui.close()
	var forge_level_before: int = hub.profile.weapon_base_level(hub.SWORD_ID)
	var trust_forge: Dictionary = hub.upgrade_sword_base()
	check(bool(trust_forge.get("success", false)), "hub_trust_forge_succeeds")
	check(int(trust_forge.get("cost", -1)) == 0, "hub_trust_forge_is_free")
	check(hub.profile.weapon_base_level(hub.SWORD_ID) == forge_level_before + 1,
		"hub_trust_forge_raises_base")
	check(String(trust_forge.get("message", "")).contains("这次不算钱"),
		"hub_trust_forge_message")
	var second_forge: Dictionary = hub.upgrade_sword_base()
	check(int(second_forge.get("cost", 0)) > 0, "hub_trust_forge_once_per_visit")
	check(not String(second_forge.get("message", "")).contains("这次不算钱"),
		"hub_trust_forge_second_not_free")
	hub.profile.npc_trust = trust_snapshot
	hub.profile.npc_blessings = blessing_snapshot
	hub.profile.memory_fragments = fragments_snapshot
	hub.profile.weapon_base_levels = base_snapshot
	hub.shop.discount = shop_discount_snapshot
	hub._trust_forge_used = false
	hub.shop_ui.bind(hub.shop, hub.profile)
	await _settle()

	# 神铸 charges 25 fragments for one base level plus a capped forge
	# blessing. The line must report the blessing actually added, not always
	# +1 (pass 70).
	var god_fragments: int = int(hub.profile.memory_fragments)
	var god_blessings: Dictionary = hub.profile.npc_blessings.duplicate(true)
	var god_base: Dictionary = hub.profile.weapon_base_levels.duplicate(true)
	hub.profile.memory_fragments = 999
	hub.profile.npc_blessings.erase("ayan")
	var god_base_before: int = hub.profile.weapon_base_level(hub.SWORD_ID)
	var god_message: String = hub.perform_npc_function(&"ayan", &"forge_god")
	check(hub.profile.weapon_base_level(hub.SWORD_ID) == god_base_before + 1,
		"hub_forge_god_raises_base")
	check(is_equal_approx(hub.profile.npc_blessing(&"ayan", "forge_bonus"), 1.0),
		"hub_forge_god_grants_blessing")
	check(god_message.contains("锻造祝福 +1"), "hub_forge_god_message_reports_gain")
	check(int(hub.profile.memory_fragments) == 999 - 25, "hub_forge_god_costs_25")
	# At the cap the blessing cannot grow; the message must say so.
	hub.profile.npc_blessings["ayan"] = {"forge_bonus": NPCProfiles.FORGE_BONUS_TOTAL_CAP}
	var capped_base_before: int = hub.profile.weapon_base_level(hub.SWORD_ID)
	var capped_message: String = hub.perform_npc_function(&"ayan", &"forge_god")
	check(hub.profile.weapon_base_level(hub.SWORD_ID) == capped_base_before + 1,
		"hub_forge_god_capped_still_raises_base")
	check(is_equal_approx(hub.profile.npc_blessing(&"ayan", "forge_bonus"),
		NPCProfiles.FORGE_BONUS_TOTAL_CAP), "hub_forge_god_capped_stays_capped")
	check(capped_message.contains("上限") and not capped_message.contains("锻造祝福 +1"),
		"hub_forge_god_capped_message_is_honest")
	# A partial blessing reports the fraction actually added.
	hub.profile.npc_blessings["ayan"] = {
		"forge_bonus": NPCProfiles.FORGE_BONUS_TOTAL_CAP - 0.5,
	}
	var partial_message: String = hub.perform_npc_function(&"ayan", &"forge_god")
	check(is_equal_approx(hub.profile.npc_blessing(&"ayan", "forge_bonus"),
		NPCProfiles.FORGE_BONUS_TOTAL_CAP), "hub_forge_god_partial_reaches_cap")
	check(partial_message.contains("+0.5"), "hub_forge_god_partial_message_reports_half")
	hub.profile.memory_fragments = god_fragments
	hub.profile.npc_blessings = god_blessings
	hub.profile.weapon_base_levels = god_base
	await _settle()

	# Hub settings (its own ModalLayer + _process path): F10 opens it, every
	# subpage opens with A, closes with B, and returns focus to its opener.
	hub.settings_menu = null
	await _press_key(KEY_F10)
	await _release_key(KEY_F10)
	check(hub.settings_menu != null and hub.settings_menu.visible, "hub_settings_opens_with_key")
	check(not hub.player.is_physics_processing(), "hub_settings_freezes_player")
	var ai_button: Button = null
	var keybind_button: Button = null
	var help_button: Button = null
	for button in hub.settings_menu.find_children("*", "Button", true, false):
		var text := String(button.text)
		if text.contains("AI"):
			ai_button = button
		elif text.contains("键位"):
			keybind_button = button
		elif text.contains("操作说明"):
			help_button = button
	check(ai_button != null and keybind_button != null and help_button != null, "hub_settings_subpage_buttons")
	if ai_button != null:
		ai_button.grab_focus()
		await _settle()
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		check(hub.settings_menu.has_subpage(), "hub_ai_page_opens")
		check(hub.settings_menu._ai_page != null and hub.settings_menu._ai_page.visible, "hub_ai_page_visible")
		await _press_button(JOY_BUTTON_B)
		await _release_button(JOY_BUTTON_B)
		check(hub.settings_menu.visible, "hub_ai_b_keeps_settings")
		check(not hub.settings_menu.has_subpage(), "hub_ai_b_closes_subpage")
		check(_focus_owner() == ai_button, "hub_ai_focus_returns")
	if keybind_button != null:
		keybind_button.grab_focus()
		await _settle()
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		check(hub.settings_menu.has_subpage(), "hub_keybind_opens")
		check(flow.input_capture_active, "hub_keybind_captures")
		await _press_button(JOY_BUTTON_B)
		await _release_button(JOY_BUTTON_B)
		check(hub.settings_menu.visible, "hub_keybind_b_keeps_settings")
		check(not hub.settings_menu.has_subpage(), "hub_keybind_b_closes")
		check(not flow.input_capture_active, "hub_keybind_b_releases_capture")
		check(_focus_owner() == keybind_button, "hub_keybind_focus_returns")
	if help_button != null:
		help_button.grab_focus()
		await _settle()
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		check(hub.help_ui.is_open(), "hub_help_opens")
		await _press_button(JOY_BUTTON_B)
		await _release_button(JOY_BUTTON_B)
		check(hub.settings_menu.visible, "hub_help_b_keeps_settings")
		check(not hub.help_ui.is_open(), "hub_help_b_closes")
		check(_focus_owner() == help_button, "hub_help_focus_returns")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(not hub.settings_menu.visible, "hub_settings_b_closes")
	check(hub.player.is_physics_processing(), "hub_settings_unfreezes_player")

	# Title "new game" confirmation: A opens the page, B cancels and returns
	# focus to the title button, A then confirms and starts a fresh profile.
	paused = false
	var title := TitleScreen.new()
	hub.add_child(title)
	await _settle()
	hub._connect_title_settings()
	# No checkpoint is present (auto-save is off here), so the first frame must
	# stay on the normal journey button. Real keyboard navigation starts from
	# that focus and returns to it.
	var title_start := title.find_child("StartButton", true, false) as Button
	check(title_start != null, "title_start_button")
	check(title_start != null and _focus_owner() == title_start,
		"title_first_focus_no_save")
	await _press_key(KEY_DOWN)
	await _release_key(KEY_DOWN)
	check(_focus_owner() != title_start, "title_no_save_down_moves_focus")
	await _press_key(KEY_UP)
	await _release_key(KEY_UP)
	check(_focus_owner() == title_start, "title_no_save_up_returns_focus")
	await _press_button(JOY_BUTTON_DPAD_DOWN)
	await _release_button(JOY_BUTTON_DPAD_DOWN)
	check(_focus_owner() != title_start, "title_no_save_dpad_moves_focus")
	await _press_button(JOY_BUTTON_DPAD_UP)
	await _release_button(JOY_BUTTON_DPAD_UP)
	check(_focus_owner() == title_start, "title_no_save_dpad_returns_focus")
	# Title settings: closing returns focus to the title's Settings button and
	# unfreezes the Hub, the same close-back contract as the pause menu.
	var title_settings := title.find_child("SettingsButton", true, false) as Button
	check(title_settings != null, "title_has_settings_button")

	# Ending gallery: Profile ids decide the unlock state, locked entries stay
	# placeholders, A opens from the title and B returns focus to its button.
	var title_gallery := title.find_child("EndingGalleryButton", true, false) as Button
	check(title_gallery != null, "title_has_ending_gallery_button")
	var endings_snapshot: Array[String] = hub.profile.endings.duplicate()
	hub.profile.endings.clear()
	hub.profile.record_ending(&"restored")
	if title_gallery != null:
		title_gallery.grab_focus()
		await _settle()
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		var gallery := title.find_child("EndingGallery", true, false) as EndingGalleryUI
		check(gallery != null and gallery.is_open(), "title_gallery_opens")
		check(gallery != null and gallery.get_entry_count() == CampaignData.ending_count(),
			"title_gallery_entries")
		check(gallery != null and gallery.is_unlocked(0) and not gallery.is_unlocked(1),
			"title_gallery_unlock_state")
		check(gallery != null and gallery.get_entry_text(1).contains("尚未记录"),
			"title_gallery_locked_placeholder")
		# Directional input must not walk focus out from under the modal onto
		# the title buttons behind the shade.
		await _press_button(JOY_BUTTON_DPAD_UP)
		await _release_button(JOY_BUTTON_DPAD_UP)
		check(gallery != null and _focus_owner() == gallery._close_button,
			"title_gallery_focus_trapped")
		await _press_button(JOY_BUTTON_B)
		await _release_button(JOY_BUTTON_B)
		check(gallery != null and not gallery.is_open(), "title_gallery_b_closes")
		check(_focus_owner() == title_gallery, "title_gallery_focus_back")
	hub.profile.endings = endings_snapshot

	if title_settings != null:
		title_settings.grab_focus()
		await _settle()
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		check(hub.settings_menu != null and hub.settings_menu.visible, "title_settings_opens")
		await _press_button(JOY_BUTTON_B)
		await _release_button(JOY_BUTTON_B)
		check(not hub.settings_menu.visible, "title_settings_closes")
		check(_focus_owner() == title_settings, "title_settings_focus_back")
		check(hub.player.is_physics_processing(), "title_settings_unfreezes_player")
		# Start also closes the title's settings page (pause action) and leaves
		# focus on the button that opened it.
		title_settings.grab_focus()
		await _settle()
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		check(hub.settings_menu.visible, "title_settings_reopens_for_start")
		await _press_button(JOY_BUTTON_START)
		await _release_button(JOY_BUTTON_START)
		check(not hub.settings_menu.visible, "title_settings_start_closes")
		check(_focus_owner() == title_settings, "title_settings_start_focus_back")
		check(_focus_is_reasonable(), "title_settings_start_focus_visible")
		check(hub.player.is_physics_processing(), "title_settings_start_unfreezes")
		# Keyboard Esc closes it as well, with the same focus hand-back.
		title_settings.grab_focus()
		await _settle()
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		check(hub.settings_menu.visible, "title_settings_reopens_for_esc")
		await _press_key(KEY_ESCAPE)
		await _release_key(KEY_ESCAPE)
		check(not hub.settings_menu.visible, "title_settings_esc_closes")
		check(_focus_owner() == title_settings, "title_settings_esc_focus_back")
		check(hub.player.is_physics_processing(), "title_settings_esc_unfreezes")
		var title_ai_button: Button = null
		title_settings.grab_focus()
		await _settle()
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		for candidate in hub.settings_menu.find_children("*", "Button", true, false):
			if String(candidate.text).contains("AI"):
				title_ai_button = candidate
				break
		check(title_ai_button != null, "title_settings_ai_button")
		if title_ai_button != null:
			title_ai_button.grab_focus()
			await _settle()
			await _press_button(JOY_BUTTON_A)
			await _release_button(JOY_BUTTON_A)
			check(hub.settings_menu.has_subpage(), "title_settings_subpage_opens")
			await _press_button(JOY_BUTTON_START)
			await _release_button(JOY_BUTTON_START)
			check(hub.settings_menu.visible,
				"title_settings_subpage_start_keeps_settings")
			check(not hub.settings_menu.has_subpage(),
				"title_settings_subpage_start_closes")
			check(_focus_owner() == title_ai_button,
				"title_settings_subpage_focus_back")
			await _press_button(JOY_BUTTON_START)
			await _release_button(JOY_BUTTON_START)
			check(not hub.settings_menu.visible,
				"title_settings_second_start_closes")
			check(_focus_owner() == title_settings,
				"title_settings_final_focus_back")
			check(_focus_is_reasonable(), "title_settings_final_focus_visible")
			check(hub.player.is_physics_processing(),
				"title_settings_final_unfreezes")
	# Title "离开档案馆" is a direct quit, by design: only "新游戏（清除进度）"
	# needs a confirmation. Profile and run save are already on disk when the
	# title is usable, so leaving must not touch either file.
	flow.profile.memory_fragments = maxi(flow.profile.memory_fragments, 3)
	flow.save_profile()
	check(FileAccess.file_exists(PROFILE_PATH), "title_leave_profile_on_disk")
	check(RunSave.has_save(RUN_PATH), "title_leave_run_save_on_disk")
	var leave_button: Button = null
	for candidate in title.find_children("*", "Button", true, false):
		var button := candidate as Button
		if button != null and button.text == "离开档案馆":
			leave_button = button
			break
	check(leave_button != null, "title_leave_button_exists")
	check(leave_button != null and leave_button.is_visible_in_tree(),
		"title_leave_button_visible")
	check(leave_button != null and leave_button.focus_mode != Control.FOCUS_NONE,
		"title_leave_button_focusable")
	check(title._confirm_panel == null, "title_leave_no_confirm_upfront")
	if leave_button != null:
		var leave_connections := leave_button.pressed.get_connections()
		check(leave_connections.size() == 1, "title_leave_single_handler")
		var leave_calls: Array[int] = []
		for connection in leave_connections:
			leave_button.pressed.disconnect(connection["callable"])
		var leave_spy := func(): leave_calls.append(1)
		leave_button.pressed.connect(leave_spy)
		leave_button.pressed.emit()
		await _settle()
		check(leave_calls.size() == 1, "title_leave_requests_quit")
		check(title._confirm_panel == null, "title_leave_does_not_confirm")
		check(title.visible, "title_leave_keeps_title_until_quit")
		check(paused, "title_leave_keeps_pause")
		leave_button.pressed.disconnect(leave_spy)
		for connection in leave_connections:
			leave_button.pressed.connect(connection["callable"])
	var leave_profile := Profile.new()
	check(leave_profile.load_profile(PROFILE_PATH), "title_leave_profile_readable")
	check(leave_profile.memory_fragments >= 3, "title_leave_profile_intact")
	leave_profile.free()
	var leave_save := RunSave.read(RUN_PATH)
	check(not leave_save.is_empty(), "title_leave_run_save_intact")

	var new_game_button := title.find_child("NewGameButton", true, false) as Button
	check(new_game_button != null, "title_has_new_game_button")
	if new_game_button != null:
		var new_game_events: Array[int] = []
		title.new_game_requested.connect(func(): new_game_events.append(1))
		new_game_button.grab_focus()
		await _settle()
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		var panel := title.find_child("NewGameConfirm", true, false) as ConfirmPanel
		check(panel != null and panel.is_open(), "title_confirm_opens_with_a")
		check(panel != null and _focus_owner() == panel._ok, "title_confirm_focuses_ok")
		await _press_button(JOY_BUTTON_B)
		await _release_button(JOY_BUTTON_B)
		check(panel != null and not panel.is_open(), "title_confirm_b_cancels")
		check(_focus_owner() == new_game_button, "title_cancel_focus_returns")
		# Start also cancels the title confirmation (the title tree is paused,
		# so this exercises the ALWAYS-mode page path) and returns focus.
		new_game_button.pressed.emit()
		await _settle()
		check(panel != null and panel.is_open(), "title_confirm_start_case_opens")
		await _press_button(JOY_BUTTON_START)
		await _release_button(JOY_BUTTON_START)
		check(panel != null and not panel.is_open(), "title_confirm_start_cancels")
		check(_focus_owner() == new_game_button, "title_confirm_start_focus_returns")
		check(title.visible, "title_confirm_start_keeps_title")
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		check(panel != null and panel.is_open(), "title_confirm_reopens")
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		check(new_game_events.size() == 1, "title_confirm_starts_new_game")
		check(panel != null and not panel.is_open(), "title_confirm_closes_on_ok")
		check(not title.visible, "title_hides_after_confirm")
		check(flow.profile != null and flow.profile.memory_fragments == 0, "title_confirm_resets_profile")
		check(hub.profile == flow.profile, "title_confirm_rebinds_hub")
		check(not paused, "title_confirm_unpauses")

	# Title "继续本局": pressing the button enters the checkpoint, and the first
	# frame of the resumed run must not keep focus on the vanished title button.
	# The new-game confirmation above cleared the seeded checkpoint, so write the
	# captured checkpoint back before the title is rebuilt.
	title.queue_free()
	await _settle()
	paused = false
	flow.auto_save = true
	check(not resume_save.is_empty(), "title_resume_seed_save")
	if not resume_save.is_empty():
		check(RunSave.write(resume_save, RUN_PATH), "title_resume_seed_restored")
	var resume_title := TitleScreen.new()
	hub.add_child(resume_title)
	resume_title.started.connect(hub._on_title_started)
	await _settle()
	var resume_button := resume_title.find_child("ResumeRunButton", true, false) as Button
	check(resume_button != null, "title_resume_button_present")
	# A real checkpoint exists: the first frame starts on "继续本局". Real D-pad
	# navigation leaves and returns to it, then Enter on that initial focus
	# resumes the run (A's existing semantics, no new run and no overwrite).
	check(resume_button != null and _focus_owner() == resume_button,
		"title_first_focus_with_save")
	if resume_button != null:
		await _press_button(JOY_BUTTON_DPAD_DOWN)
		await _release_button(JOY_BUTTON_DPAD_DOWN)
		check(_focus_owner() != resume_button, "title_with_save_dpad_moves_focus")
		await _press_button(JOY_BUTTON_DPAD_UP)
		await _release_button(JOY_BUTTON_DPAD_UP)
		check(_focus_owner() == resume_button, "title_with_save_dpad_returns_focus")
		await _press_key(KEY_DOWN)
		await _release_key(KEY_DOWN)
		check(_focus_owner() != resume_button, "title_with_save_keyboard_moves_focus")
		await _press_key(KEY_UP)
		await _release_key(KEY_UP)
		check(_focus_owner() == resume_button, "title_with_save_keyboard_returns_focus")
		check(_focus_owner() == resume_button, "title_resume_focus")
		await _press_key(KEY_ENTER)
		await _release_key(KEY_ENTER)
	var resumed = null
	for i in 30:
		await process_frame
		if current_scene != null and current_scene != hub:
			resumed = current_scene
			break
	check(resumed != null, "title_resume_enters_game")
	if resumed != null:
		var frame_focus := _focus_owner()
		check(frame_focus == null or frame_focus.is_visible_in_tree(),
			"title_resume_first_frame_focus")
		check(not paused, "title_resume_first_frame_unpaused")
		check(flow.resume_requested == false, "title_resume_request_consumed")
		check(resumed._resume_restored, "title_resume_restored")
		check(await _wait_mds(resumed), "title_resume_mds_loads")
		check(resumed._mds_world.current_room == "ch1_01", "title_resume_room")
		check(resumed.find_children("*", "TitleScreen", true, false).is_empty(),
			"title_resume_no_stale_title")
		await _free_scene(resumed)
		await _settle()

	# Same entry with a real pad A, then use the resumed run for the death page.
	paused = false
	hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await create_timer(0.4).timeout
	var pad_title := TitleScreen.new()
	hub.add_child(pad_title)
	pad_title.started.connect(hub._on_title_started)
	await _settle()
	var pad_resume := pad_title.find_child("ResumeRunButton", true, false) as Button
	check(pad_resume != null, "gamepad_title_resume_present")
	var resumed_pad = null
	if pad_resume != null:
		pad_resume.grab_focus()
		await _settle()
		check(_focus_owner() == pad_resume, "gamepad_title_resume_focus")
		await _press_button(JOY_BUTTON_A)
		await _release_button(JOY_BUTTON_A)
		for i in 30:
			await process_frame
			if current_scene != null and current_scene != hub:
				resumed_pad = current_scene
				break
	check(resumed_pad != null, "gamepad_title_resume_enters_game")
	if resumed_pad != null:
		var pad_frame_focus := _focus_owner()
		check(pad_frame_focus == null or pad_frame_focus.is_visible_in_tree(),
			"gamepad_title_resume_first_frame_focus")
		check(not paused, "gamepad_title_resume_first_frame_unpaused")
		check(await _wait_mds(resumed_pad), "gamepad_title_resume_mds_loads")
		check(resumed_pad._mds_world.current_room == "ch1_01",
			"gamepad_title_resume_room")

		# Death result page: real death, then keyboard/pad focus and close
		# fallback. Unlike the campaign ending, this is the `won=false` path.
		resumed_pad.player.take_damage(9999)
		await create_timer(1.0).timeout
		check(resumed_pad.ending_screen.visible, "death_page_opens")
		check(paused, "death_page_pauses")
		var death_title := resumed_pad.ending_screen.get_node_or_null(
			"Center/Panel/Margin/VBox/Title") as Label
		check(death_title != null and death_title.text == "记录中断",
			"death_page_is_interrupted_ending")
		var defeat_seed: int = resumed_pad.run_state.run_seed
		var defeat_hint := EndingHintData.format_hint(
			EndingHintData.pick(defeat_seed, false), flow.prompt_label(&"restart"))
		check(resumed_pad.ending_screen._hint != null
			and resumed_pad.ending_screen._hint.text == defeat_hint,
			"death_page_hint_matches_run_seed")
		check(resumed_pad.ending_screen._hint.text.contains("回到最后的档案馆"),
			"death_page_hint_keeps_destination")
		check(resumed_pad.ending_screen._return_button != null
			and _focus_owner() == resumed_pad.ending_screen._return_button,
			"death_page_focus")
		await _press_key(KEY_ESCAPE)
		await _release_key(KEY_ESCAPE)
		check(resumed_pad.ending_screen._hint.text == EndingHintData.format_hint(
			EndingHintData.pick(defeat_seed, false), flow.prompt_label(&"restart")),
			"death_page_hint_follows_keyboard_prompt")
		check(resumed_pad.ending_screen.visible, "death_esc_keeps_page")
		check(not resumed_pad.pause_menu.is_open(), "death_esc_no_pause_page")
		check(paused, "death_esc_keeps_pause")
		check(_focus_owner() == resumed_pad.ending_screen._return_button,
			"death_esc_keeps_focus")
		await _press_button(JOY_BUTTON_B)
		await _release_button(JOY_BUTTON_B)
		check(resumed_pad.ending_screen.visible, "death_b_keeps_page")
		check(not resumed_pad.pause_menu.is_open(), "death_b_no_pause_page")
		check(_focus_owner() == resumed_pad.ending_screen._return_button,
			"death_b_keeps_focus")
		check(resumed_pad.ending_screen._hint.text == EndingHintData.format_hint(
			EndingHintData.pick(defeat_seed, false), flow.prompt_label(&"restart")),
			"death_page_hint_follows_pad_prompt")
		await _press_key(KEY_ENTER)
		await _release_key(KEY_ENTER)
		await create_timer(0.8).timeout
		check(current_scene != null and current_scene.has_method("talk_to_npc"),
			"death_enter_returns_to_hub")
		check(not paused, "death_return_unpaused")
		await _free_scene(current_scene)
		await _settle()

	# Chapter completion story page + chapter choice page. The plain story page
	# closes with the real interact key or Start; the required choice ignores
	# Esc/B, keeps focus on the first option, moves with the D-pad and hands
	# focus to the ending screen after confirming. Keyboard run first.
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	paused = false
	var chapter_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(chapter_run)
	current_scene = chapter_run
	await create_timer(0.4).timeout
	_close_story(chapter_run)
	check(await _wait_mds(chapter_run), "chapter_end_scene_boots")
	check(chapter_run._mds_world.current_room == "ch1_01", "chapter_end_first_room")
	chapter_run._complete_chapter.call_deferred()
	await create_timer(0.35).timeout
	check(chapter_run._story.is_open() and not chapter_run._story._choice_mode,
		"chapter_end_story_opens")
	check(paused, "chapter_end_story_pauses")
	check(chapter_run._story._eyebrow.text.contains("章节完成"),
		"chapter_end_story_is_completion")
	check(_focus_owner() == chapter_run._story._continue,
		"chapter_end_story_focus_continue")
	check(_focus_is_reasonable(), "chapter_end_story_focus_visible")
	await _press_key(KEY_E)
	await _release_key(KEY_E)
	await create_timer(0.2).timeout
	check(chapter_run._story.is_open() and chapter_run._story._choice_mode,
		"chapter_end_choice_opens_after_interact")
	check(paused, "chapter_end_choice_pauses")
	var chapter_options: Array = CampaignData.chapter(0)["choice"]["options"]
	check(chapter_run._story._options.get_child_count() == chapter_options.size(),
		"chapter_end_choice_option_count")
	var choice_first := chapter_run._story._options.get_child(0) as Button
	var choice_second := chapter_run._story._options.get_child(1) as Button
	check(choice_first.text == "%s\n%s" % [
		chapter_options[0].get("label", "选择"), chapter_options[0].get("note", "")],
		"chapter_end_choice_first_text")
	check(choice_second.text == "%s\n%s" % [
		chapter_options[1].get("label", "选择"), chapter_options[1].get("note", "")],
		"chapter_end_choice_second_text")
	check(_focus_owner() == choice_first, "chapter_end_choice_focus_first")
	check(_focus_is_reasonable(), "chapter_end_choice_focus_visible")
	await _press_key(KEY_ESCAPE)
	await _release_key(KEY_ESCAPE)
	check(chapter_run._story.is_open() and chapter_run._story._choice_mode,
		"chapter_end_choice_esc_ignored")
	check(paused, "chapter_end_choice_esc_keeps_pause")
	check(not chapter_run.pause_menu.is_open(), "chapter_end_choice_esc_no_pause_menu")
	check(_focus_owner() == choice_first, "chapter_end_choice_esc_keeps_focus")
	await _press_key(KEY_DOWN)
	await _release_key(KEY_DOWN)
	check(_focus_owner() == choice_second, "chapter_end_choice_down_moves_focus")
	await _press_key(KEY_ENTER)
	await _release_key(KEY_ENTER)
	await create_timer(1.2).timeout
	# Chapter 1 now hands off to the Chapter 2 big map: the choice closes and
	# the Chapter 2 intro opens in place of the ending screen.
	check(chapter_run._chapter == 1, "chapter_end_choice_enters_chapter_2")
	check(not chapter_run._finished, "chapter_end_choice_does_not_finish_campaign")
	check(chapter_run._story.is_open() and not chapter_run._story._choice_mode,
		"chapter_end_choice_opens_chapter_2_intro")
	check(chapter_run._story.visible, "chapter_end_chapter_2_intro_visible")
	check(paused, "chapter_end_chapter_2_intro_pauses")
	check(_focus_owner() == chapter_run._story._continue,
		"chapter_end_chapter_2_intro_focus")
	check(_focus_is_reasonable(), "chapter_end_chapter_2_intro_focus_visible")
	# The ending screen is still the campaign-end surface; drive it directly so
	# this suite keeps covering its first-frame focus handoff.
	chapter_run._story.close()
	await create_timer(0.2).timeout
	chapter_run._finish(true)
	await create_timer(1.2).timeout
	check(chapter_run._finished, "chapter_end_ending_after_handoff")
	check(chapter_run.ending_screen.visible, "chapter_end_ending_visible")
	check(paused, "chapter_end_ending_pauses")
	check(_focus_owner() == chapter_run.ending_screen._return_button,
		"chapter_end_ending_focus_return")
	check(_focus_is_reasonable(), "chapter_end_ending_focus_visible")
	await _free_scene(chapter_run)

	# Same pages with a pad: Start closes the completion page, B must not skip
	# the required choice, D-pad moves focus and A confirms.
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	paused = false
	chapter_run = load("res://scenes/main.tscn").instantiate()
	root.add_child(chapter_run)
	current_scene = chapter_run
	await create_timer(0.4).timeout
	_close_story(chapter_run)
	check(await _wait_mds(chapter_run), "chapter_end_pad_scene_boots")
	chapter_run._complete_chapter.call_deferred()
	await create_timer(0.35).timeout
	check(chapter_run._story.is_open() and not chapter_run._story._choice_mode,
		"chapter_end_pad_story_opens")
	check(_focus_owner() == chapter_run._story._continue,
		"chapter_end_pad_story_focus")
	await _press_button(JOY_BUTTON_START)
	await _release_button(JOY_BUTTON_START)
	await create_timer(0.2).timeout
	check(chapter_run._story.is_open() and chapter_run._story._choice_mode,
		"chapter_end_pad_choice_opens")
	check(paused, "chapter_end_pad_choice_pauses")
	var pad_choice_first := chapter_run._story._options.get_child(0) as Button
	var pad_choice_second := chapter_run._story._options.get_child(1) as Button
	check(_focus_owner() == pad_choice_first, "chapter_end_pad_choice_focus_first")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(chapter_run._story.is_open() and chapter_run._story._choice_mode,
		"chapter_end_pad_choice_b_ignored")
	check(paused, "chapter_end_pad_choice_b_keeps_pause")
	check(not chapter_run.pause_menu.is_open(),
		"chapter_end_pad_choice_b_no_pause_menu")
	check(_focus_owner() == pad_choice_first, "chapter_end_pad_choice_b_keeps_focus")
	await _press_button(JOY_BUTTON_DPAD_DOWN)
	await _release_button(JOY_BUTTON_DPAD_DOWN)
	check(_focus_owner() == pad_choice_second, "chapter_end_pad_choice_dpad_focus")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	await create_timer(1.2).timeout
	# Same handoff with a pad: the Chapter 2 intro takes focus, and the
	# campaign-end surface still hands focus to its return button.
	check(chapter_run._chapter == 1, "chapter_end_pad_choice_enters_chapter_2")
	check(not chapter_run._finished, "chapter_end_pad_choice_does_not_finish")
	check(chapter_run._story.is_open() and not chapter_run._story._choice_mode,
		"chapter_end_pad_choice_opens_chapter_2_intro")
	check(paused, "chapter_end_pad_chapter_2_intro_pauses")
	check(_focus_owner() == chapter_run._story._continue,
		"chapter_end_pad_chapter_2_intro_focus")
	chapter_run._story.close()
	await create_timer(0.2).timeout
	chapter_run._finish(true)
	await create_timer(1.2).timeout
	check(chapter_run._finished, "chapter_end_pad_ending_after_handoff")
	check(chapter_run.ending_screen.visible, "chapter_end_pad_ending_visible")
	check(paused, "chapter_end_pad_ending_pauses")
	check(_focus_owner() == chapter_run.ending_screen._return_button,
		"chapter_end_pad_ending_focus_return")
	await _free_scene(chapter_run)

	# Hub training stele: the tutorial banner advances to the stele step without
	# pausing or freezing, never takes focus, and hides when the stele is hit.
	RunSave.clear(RUN_PATH)
	flow.resume_requested = false
	flow.reset_profile()
	flow.auto_save = false
	paused = false
	var stele_hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(stele_hub)
	current_scene = stele_hub
	await create_timer(0.5).timeout
	check(stele_hub.tutorial_flow != null and stele_hub.tutorial_flow.is_active(),
		"stele_tutorial_starts")
	check(stele_hub.tutorial_flow.visible and stele_hub.tutorial_flow._panel.visible,
		"stele_banner_visible")
	check(stele_hub.tutorial_flow.get_hint().contains("第 1 步"), "stele_step1_hint")
	check(not paused, "stele_banner_no_pause")
	check(stele_hub.player.is_physics_processing(), "stele_banner_player_free")
	check(_focus_is_reasonable(), "stele_banner_focus_reasonable")
	stele_hub._open_tutorial_codex()
	await _settle()
	check(paused and stele_hub._tutorial_codex.visible, "stele_codex_opens")
	check(stele_hub.tutorial_flow.get_hint().contains("第 2 步"), "stele_step2_hint")
	check(not stele_hub.player.is_physics_processing(), "stele_codex_freezes_player")
	stele_hub._close_tutorial_codex()
	await _settle()
	check(not paused, "stele_codex_close_unpauses")
	check(stele_hub.player.is_physics_processing(), "stele_codex_close_unfreezes")
	check(_focus_is_reasonable(), "stele_codex_close_focus_reasonable")
	var stele_words: Array[WordData] = []
	for word in stele_hub._tutorial_run.inventory.words:
		if stele_words.size() < 2 and word != null:
			stele_words.append(word)
	var stele_phrase: ResolvedPhrase = PhraseResolver.new().resolve(stele_words)
	check(stele_phrase != null, "stele_phrase_resolves")
	stele_hub._on_tutorial_phrase_equipped(0, stele_phrase)
	await _settle()
	check(stele_hub.tutorial_flow.is_active(), "stele_stays_active_after_equip")
	check(stele_hub.tutorial_flow.get_hint().contains("训练碑"), "stele_step3_hint")
	check(not paused and stele_hub.player.is_physics_processing(),
		"stele_step3_no_pause")
	var stele_health: int = stele_hub.training_dummy.health
	stele_hub.interact_with(stele_hub.training_dummy)
	await _settle()
	check(stele_hub.training_dummy.health < stele_health, "stele_dummy_takes_damage")
	check(stele_hub.training_dummy.health >= 1, "stele_dummy_never_dies")
	check(not stele_hub.tutorial_flow.is_active(), "stele_banner_closes_on_hit")
	check(not stele_hub.tutorial_flow.visible
		and not stele_hub.tutorial_flow._panel.visible, "stele_banner_hidden_on_hit")
	check(not paused, "stele_hit_no_pause")
	check(stele_hub.player.is_physics_processing(), "stele_hit_player_free")
	check(_focus_is_reasonable(), "stele_hit_focus_reasonable")
	check(flow.profile.tutorial_done, "stele_hit_marks_tutorial_done")
	await _free_scene(stele_hub)

	_cleanup_files()
	print("MENUS INTEGRATION: %d checks, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
