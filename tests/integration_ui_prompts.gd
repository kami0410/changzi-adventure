extends SceneTree

## World-space interaction hints must follow the device in the player's hands,
## including a controller connected after the room was loaded. Runs deferred so
## the autoloads (Flow bindings) and the scene tree are fully ready.

var failures: int = 0
var assertions: int = 0
var flow: GameFlow


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("UI PROMPT FAIL: " + label)


func _initialize() -> void:
	_run.call_deferred()


func _set_gamepad(value: bool) -> void:
	flow.using_gamepad = value
	flow.input_device_changed.emit(value)


## Real events so the flow's own device tracker (not the test) picks the mode.
func _tap_button(button: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = button
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


func _tap_key(keycode: int) -> void:
	var down := InputEventKey.new()
	down.physical_keycode = keycode
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventKey.new()
	up.physical_keycode = keycode
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


func _test_modal_close_prompts() -> void:
	# Every modal page must name the back button the player actually has.
	await _tap_button(JOY_BUTTON_B)
	check(flow.using_gamepad, "close_hint_pad_detected")
	check(flow.close_prompt() == "B", "close_prompt_pad_is_b")
	check(flow.close_prompt("Tab / Esc") == "B", "close_prompt_pad_ignores_keyboard_alts")

	var offers: Array[Dictionary] = [{"title": "甲", "cost": 1, "description": "", "bought": false}]
	var shop = load("res://scripts/ui/run_shop_ui.gd").new()
	root.add_child(shop)
	shop.open_shop(offers, 5)
	check(shop._close_button.text == "离开交易所 [B]", "close_hint_shop_pad")
	shop.close_shop()
	await _tap_key(KEY_ESCAPE)
	check(not flow.using_gamepad, "close_hint_keyboard_detected")
	check(flow.close_prompt() == "Esc", "close_prompt_keyboard_is_esc")
	check(flow.close_prompt("Tab / Esc") == "Tab / Esc", "close_prompt_keyboard_keeps_alts")
	shop.open_shop(offers, 5)
	check(shop._close_button.text == "离开交易所 [Esc]", "close_hint_shop_keyboard")
	shop.close_shop()
	shop.free()

	var archive_profile := Profile.new()
	var archive = load("res://scripts/ui/archive_ui.gd").new()
	root.add_child(archive)
	archive.bind(archive_profile)
	await _tap_button(JOY_BUTTON_B)
	archive.open()
	check(archive._close_button.text == "合上档案  [B]", "close_hint_archive_pad")
	archive.close()
	await _tap_key(KEY_ESCAPE)
	archive.open()
	check(archive._close_button.text == "合上档案  [Esc]", "close_hint_archive_keyboard")
	archive.close()
	archive.free()
	archive_profile.free()

	var codex = load("res://scenes/ui/codex.tscn").instantiate()
	root.add_child(codex)
	await _tap_button(JOY_BUTTON_B)
	check(codex._close_button.text == "返回 [B]", "close_hint_codex_pad")
	await _tap_key(KEY_ESCAPE)
	check(codex._close_button.text == "返回 [C / Esc]", "close_hint_codex_keyboard")
	codex.free()

	var inventory = load("res://scenes/ui/inventory_ui.tscn").instantiate()
	root.add_child(inventory)
	await _tap_button(JOY_BUTTON_B)
	check(inventory._close_button.text == "返回 [B]", "close_hint_inventory_pad")
	check(inventory._close_hint_label.text == "B 关闭", "close_hint_inventory_footer_pad")
	await _tap_key(KEY_ESCAPE)
	check(inventory._close_button.text == "返回 [Tab / Esc]", "close_hint_inventory_keyboard")
	check(inventory._close_hint_label.text == "Tab / Esc 关闭", "close_hint_inventory_footer_keyboard")
	inventory.free()

	var help = load("res://scripts/ui/help_ui.gd").new()
	root.add_child(help)
	await _tap_button(JOY_BUTTON_B)
	help.open()
	check(help._close_button.text == "继续冒险  [B]", "close_hint_help_pad")
	help.close()
	await _tap_key(KEY_ESCAPE)
	help.open()
	check(help._close_button.text == "继续冒险  [Esc]", "close_hint_help_keyboard")
	help.close()
	help.free()

	# The keybind page is rebuilt per open, so check both devices on fresh pages.
	await _tap_key(KEY_ESCAPE)
	var keybind_keys = load("res://scripts/ui/keybind_ui.gd").new()
	root.add_child(keybind_keys)
	keybind_keys.open()
	check(keybind_keys._close_button.text == "返回  [Esc]", "close_hint_keybind_keyboard")
	check(keybind_keys._hint.text.contains("Esc"), "close_hint_keybind_hint_keyboard")
	keybind_keys.close()
	await process_frame
	await _tap_button(JOY_BUTTON_B)
	var keybind_pad = load("res://scripts/ui/keybind_ui.gd").new()
	root.add_child(keybind_pad)
	keybind_pad.open()
	check(keybind_pad._close_button.text == "返回  [B]", "close_hint_keybind_pad")
	check(not keybind_pad._hint.text.contains("Esc"), "close_hint_keybind_hint_pad")
	keybind_pad.close()
	await process_frame

	var map_pad = load("res://scripts/ui/map_overlay.gd").new()
	root.add_child(map_pad)
	await _tap_button(JOY_BUTTON_B)
	map_pad.open()
	check(map_pad._hint.text.contains("B 关闭"), "close_hint_map_pad_hint")
	check(map_pad._close_button.text == "继续探索  [B]", "close_hint_map_pad_button")
	map_pad.close()
	await _tap_key(KEY_ESCAPE)
	map_pad.open()
	check(map_pad._hint.text.contains("Esc 关闭"), "close_hint_map_keyboard_hint")
	check(map_pad._close_button.text == "继续探索  [Esc]", "close_hint_map_keyboard_button")
	map_pad.close()
	map_pad.free()

	var settings = load("res://scenes/ui/settings_menu.tscn").instantiate()
	root.add_child(settings)
	await _tap_button(JOY_BUTTON_B)
	settings.open()
	check(settings.hint_label.text.contains("Back") and settings.hint_label.text.contains("B"), "close_hint_settings_pad")
	settings.close()
	await _tap_key(KEY_ESCAPE)
	settings.open()
	check(settings.hint_label.text.contains("F10") and settings.hint_label.text.contains("Esc"), "close_hint_settings_keyboard")
	settings.close()
	settings.free()
	await process_frame


## Prompts that are built once (room gates, tutorial copy, pause footer,
## ending copy, story copy, codex equip buttons) must still follow a device
## switch while they are on screen.
func _test_prompts_built_once() -> void:
	var keyboard := GameFlow.key_label(&"interact")
	var gamepad := GameFlow.joypad_label(&"interact")

	_set_gamepad(false)
	var room = load("res://scenes/mds/ch1_rest.tscn").instantiate()
	root.add_child(room)
	await process_frame
	var gate := room.get_node_or_null("door2") as MDSGate
	check(gate != null, "built_once_room_gate_exists")
	if gate != null:
		var player := Node2D.new()
		player.add_to_group("player")
		root.add_child(player)
		gate._on_body_entered(player)
		var gate_label := gate.get("_prompt") as Label
		check(gate.prompt.contains(keyboard), "built_once_gate_keyboard")
		check(gate_label != null and gate_label.text.contains(keyboard), "built_once_gate_label_keyboard")
		_set_gamepad(true)
		check(gate.prompt.contains(gamepad), "built_once_gate_follows_pad")
		gate_label = gate.get("_prompt") as Label
		check(gate_label != null and gate_label.text.contains(gamepad), "built_once_gate_label_follows_pad")
		gate._on_body_exited(player)
		root.remove_child(player)
		player.free()
	root.remove_child(room)
	room.free()
	await process_frame

	var original_profile: Profile = flow.profile
	var tutorial_profile := Profile.new()
	flow.profile = tutorial_profile
	var auto_save := flow.auto_save
	flow.auto_save = false
	_set_gamepad(false)
	var tutorial := TutorialFlow.new()
	root.add_child(tutorial)
	tutorial.start_if_needed()
	check(tutorial.get_hint().contains("按 C"), "built_once_tutorial_keyboard")
	tutorial.on_codex_opened()
	check(tutorial.get_hint().contains("[Q]"), "built_once_tutorial_step2_keyboard")
	tutorial.on_phrase_equipped()
	check(tutorial.get_hint().contains("按 %s" % keyboard), "built_once_tutorial_step3_keyboard")
	_set_gamepad(true)
	check(tutorial.get_hint().contains(gamepad), "built_once_tutorial_step3_follows_pad")
	tutorial.on_codex_opened()
	check(tutorial.get_hint().contains(GameFlow.joypad_label(&"cast_1")), "built_once_tutorial_step2_follows_pad")
	_set_gamepad(false)
	check(tutorial.get_hint().contains("[Q]"), "built_once_tutorial_step2_returns_keyboard")
	tutorial.on_training_hit()
	root.remove_child(tutorial)
	tutorial.free()
	flow.auto_save = auto_save
	flow.profile = original_profile
	tutorial_profile.free()
	await process_frame

	_set_gamepad(false)
	var pause = load("res://scenes/ui/pause_menu.tscn").instantiate()
	root.add_child(pause)
	await process_frame
	pause.open_pause()
	var footer := pause.find_child("Footer", true, false) as Label
	check(footer != null and footer.text.contains("P"), "built_once_pause_footer_keyboard")
	_set_gamepad(true)
	check(footer != null and footer.text.contains("Start"), "built_once_pause_footer_follows_pad")
	pause.toggle()
	root.remove_child(pause)
	pause.free()
	await process_frame

	_set_gamepad(false)
	var ending = load("res://scenes/ui/ending_screen.tscn").instantiate()
	root.add_child(ending)
	await process_frame
	var ending_hint := ending.find_child("Hint", true, false) as Label
	var ending_button := ending.get_node("Center/Panel/Margin/VBox").get_child(-1) as Button
	check(ending_hint != null and ending_hint.text.contains("R"), "built_once_ending_keyboard")
	check(ending_button != null and ending_button.text.contains("R"), "built_once_ending_button_keyboard")
	_set_gamepad(true)
	check(ending_hint != null and ending_hint.text.contains("Start"), "built_once_ending_follows_pad")
	check(ending_button != null and ending_button.text.contains("Start"), "built_once_ending_button_follows_pad")
	_set_gamepad(false)
	check(ending_hint.text.contains("R"), "built_once_ending_returns_keyboard")
	root.remove_child(ending)
	ending.free()
	await process_frame

	_set_gamepad(false)
	var story := StoryOverlay.new()
	root.add_child(story)
	await process_frame
	story.open_story("测试", "标题", ["正文"])
	var story_hint: Label = null
	for node in story.find_children("*", "Label", true, false):
		var label := node as Label
		if label != null and label.text.contains("确认"):
			story_hint = label
	check(GameFlow.key_label(&"ui_accept") == "Enter", "built_once_ui_accept_label")
	check(story._continue.text.contains("E"), "built_once_story_continue_keyboard")
	check(story_hint != null and story_hint.text.contains("Enter"), "built_once_story_hint_keyboard")
	_set_gamepad(true)
	check(story._continue.text.contains("Y"), "built_once_story_continue_follows_pad")
	check(story_hint != null and story_hint.text.contains("A 确认"), "built_once_story_hint_follows_pad")
	story.close()
	root.remove_child(story)
	story.free()
	await process_frame

	# A resumed run skips the intro story, so the event/choice page can be the
	# first thing the overlay shows. Build it after a real pad press: the choice
	# page must still say "A 确认" rather than the build-time "Enter 确认".
	await _tap_button(JOY_BUTTON_A)
	check(flow.using_gamepad, "story_choice_pad_device_tracked")
	var choice_story := StoryOverlay.new()
	root.add_child(choice_story)
	await process_frame
	choice_story.open_choice("测试", "标题", "正文", [{"label": "甲", "note": ""}])
	check(choice_story._hint.text.contains("A 确认"), "built_once_story_choice_follows_pad")
	choice_story.close()
	root.remove_child(choice_story)
	choice_story.free()
	await process_frame
	await _tap_key(KEY_A)
	_set_gamepad(false)

	var codex = load("res://scenes/ui/codex.tscn").instantiate()
	root.add_child(codex)
	await process_frame
	check(codex._equip_buttons.size() == 2, "built_once_codex_equip_buttons")
	if codex._equip_buttons.size() == 2:
		check(codex._equip_buttons[0].text.contains("Q"), "built_once_codex_equip_keyboard")
		_set_gamepad(true)
		check(codex._equip_buttons[0].text.contains("LT"), "built_once_codex_equip_pad_slot1")
		check(codex._equip_buttons[1].text.contains("RT"), "built_once_codex_equip_pad_slot2")
		_set_gamepad(false)
		check(codex._equip_buttons[0].text.contains("Q"), "built_once_codex_equip_returns_keyboard")
		if codex._free_text != null:
			codex._free_text.text = "让雷落在火里"
			codex._on_ai_requested()
			check(codex._ai_status.text.contains("F10"), "built_once_codex_ai_hint_keyboard")
			_set_gamepad(true)
			codex._on_ai_requested()
			check(codex._ai_status.text.contains("Back"), "built_once_codex_ai_hint_follows_pad")
	root.remove_child(codex)
	codex.free()
	_set_gamepad(false)
	await process_frame

	# A dialogue page can stay open across a device switch as well.
	var dialogue = load("res://scenes/ui/dialogue_ui.tscn").instantiate()
	root.add_child(dialogue)
	await process_frame
	dialogue.open_dialogue("陆沉", ["第一行", "第二行"])
	check(dialogue._continue_button.text.contains("E"), "built_once_dialogue_keyboard")
	check(dialogue._inspire_button.text.contains("Y"), "built_once_dialogue_inspire_keyboard")
	_set_gamepad(true)
	check(dialogue._continue_button.text.contains("Y"), "built_once_dialogue_follows_pad")
	_set_gamepad(false)
	dialogue.close()
	root.remove_child(dialogue)
	dialogue.free()
	await process_frame


## Rebinding a key must refresh labels that were rendered before the change:
## the HUD control strip, world pickups and room doors all cached them.
func _test_keybind_prompts() -> void:
	var temp_profile := "user://test_ui_prompts_keybinds.cfg"
	var saved_path := flow.profile_path
	var saved_keybinds: Dictionary = flow.profile.keybinds.duplicate()
	var saved_joybinds: Dictionary = flow.profile.joybinds.duplicate()
	flow.profile_path = temp_profile
	flow.auto_save = false

	_set_gamepad(false)
	var hud = load("res://scenes/ui/hud.tscn").instantiate()
	root.add_child(hud)
	await process_frame
	var hint := hud.find_child("ControlsHint", true, false) as Label
	check(hint != null and hint.text.contains("J 攻击"), "keybind_hud_starts_keyboard")
	flow.set_keybind(&"attack", KEY_K)
	check(hint != null and hint.text.contains("K 攻击"), "keybind_hud_follows_keyboard")
	flow.set_joypad_bind(&"jump", JOY_BUTTON_Y)
	_set_gamepad(true)
	check(hint != null and hint.text.contains("Y 跳跃"), "keybind_hud_follows_pad")
	root.remove_child(hud)
	hud.free()
	await process_frame

	_set_gamepad(false)
	var room = load("res://scenes/mds/ch1_rest.tscn").instantiate()
	root.add_child(room)
	await process_frame
	var gate := room.get_node_or_null("door2") as MDSGate
	check(gate != null and gate.prompt.contains("E"), "keybind_gate_starts_keyboard")
	var pickup = load("res://scenes/combat/pickup.tscn").instantiate()
	pickup.label_text = "残页"
	root.add_child(pickup)
	var player := Node.new()
	root.add_child(player)
	player.add_to_group("player")
	pickup._on_body_entered(player)
	check(pickup.label.text.contains("E 拾取"), "keybind_pickup_starts_keyboard")
	flow.set_keybind(&"interact", KEY_R)
	check(pickup.label.text.contains("R 拾取"), "keybind_pickup_follows_keyboard")
	check(gate != null and gate.prompt.contains("R"), "keybind_gate_follows_keyboard")
	pickup._on_body_exited(player)
	root.remove_child(pickup)
	pickup.free()
	root.remove_child(player)
	player.free()
	root.remove_child(room)
	room.free()
	await process_frame

	# The settings page stays open underneath its keybind subpage, so its own
	# "按 X 关闭" hint must follow a rebind too.
	_set_gamepad(false)
	var settings = load("res://scenes/ui/settings_menu.tscn").instantiate()
	root.add_child(settings)
	await process_frame
	settings.open()
	check(settings.hint_label.text.contains("F10"), "keybind_settings_hint_starts_keyboard")
	flow.set_keybind(&"settings", KEY_K)
	check(settings.hint_label.text.contains("K"), "keybind_settings_hint_follows_rebind")
	check(not settings.hint_label.text.contains("F10"), "keybind_settings_hint_drops_old_key")
	flow.set_keybind(&"settings", KEY_F10)
	settings.close()
	root.remove_child(settings)
	settings.free()
	await process_frame

	# The title confirmation page must name the device in the player's hands.
	_set_gamepad(false)
	var confirm := ConfirmPanel.new()
	root.add_child(confirm)
	confirm.open("清除当前进度并重新开始？", "确认", "取消", null)
	var confirm_hint: Label = null
	for node in confirm.find_children("*", "Label", true, false):
		var label := node as Label
		if label != null and label.text.contains("确认"):
			confirm_hint = label
	check(confirm_hint != null and confirm_hint.text == "Enter 确认 · Esc 取消", "keybind_confirm_hint_keyboard")
	await _tap_button(JOY_BUTTON_B)
	check(confirm_hint != null and confirm_hint.text == "A 确认 · B 取消", "keybind_confirm_hint_follows_pad")
	confirm.cancel()
	root.remove_child(confirm)
	confirm.free()
	await _tap_key(KEY_ESCAPE)
	await process_frame

	# Codex and inventory can also be closed with their own action key, so the
	# keyboard alternative must show the rebound key instead of C / Tab.
	var codex = load("res://scenes/ui/codex.tscn").instantiate()
	root.add_child(codex)
	await process_frame
	check(codex._close_button.text == "返回 [C / Esc]", "keybind_codex_hint_default")
	flow.set_keybind(&"codex", KEY_G)
	check(codex._close_button.text == "返回 [G / Esc]", "keybind_codex_hint_follows_rebind")
	flow.set_keybind(&"codex", KEY_C)

	# The AI-unconfigured status names the settings key; it must follow a
	# rebind and the controller's Back binding instead of freezing F10.
	var ai := root.get_node_or_null("AI") as AIService
	var saved_ai_config: Dictionary = ai.config.duplicate(true) if ai != null else {}
	if ai != null:
		ai.config["enabled"] = false
	codex._free_text.text = "让时间停下来"
	codex._on_ai_requested()
	check(codex._ai_status.text.contains("F10"), "keybind_codex_ai_hint_keyboard")
	flow.set_keybind(&"settings", KEY_K)
	check(codex._ai_status.text.contains("K") and not codex._ai_status.text.contains("F10"),
		"keybind_codex_ai_hint_follows_rebind")
	flow.set_keybind(&"settings", KEY_F10)
	await _tap_button(JOY_BUTTON_BACK)
	check(codex._ai_status.text.contains("Back"), "keybind_codex_ai_hint_follows_pad")
	if ai != null:
		ai.config = saved_ai_config
	await _tap_key(KEY_ESCAPE)
	root.remove_child(codex)
	codex.free()
	await process_frame

	var inventory = load("res://scenes/ui/inventory_ui.tscn").instantiate()
	root.add_child(inventory)
	await process_frame
	check(inventory._close_button.text == "返回 [Tab / Esc]", "keybind_inventory_hint_default")
	check(inventory._close_hint_label.text == "Tab / Esc 关闭", "keybind_inventory_footer_default")
	flow.set_keybind(&"inventory", KEY_I)
	check(inventory._close_button.text == "返回 [I / Esc]", "keybind_inventory_hint_follows_rebind")
	check(inventory._close_hint_label.text == "I / Esc 关闭", "keybind_inventory_footer_follows_rebind")
	flow.set_keybind(&"inventory", KEY_TAB)
	root.remove_child(inventory)
	inventory.free()
	await process_frame

	# The Hub dialogue tip used to bake the npc_inspire key into its last line;
	# it now points at the button, which already follows device and rebinds.
	flow.set_keybind(&"npc_inspire", KEY_U)
	_set_gamepad(false)
	flow.title_shown_this_session = true
	var hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub)
	await process_frame
	var luchen: NPC = null
	for candidate in hub.get_npcs():
		if candidate.npc_id == &"luchen":
			luchen = candidate
	check(luchen != null, "keybind_hub_luchen_exists")
	if luchen != null:
		hub.talk_to_npc(luchen)
		await process_frame
		var lines: Array[String] = hub.dialogue_ui._lines
		var tip := lines[lines.size() - 1] if not lines.is_empty() else ""
		check(tip == "也可以选「言灵对话」，对 TA 说一句只属于你的话。", "keybind_dialogue_tip_neutral")
		await _tap_button(JOY_BUTTON_B)
		await process_frame
		if not lines.is_empty():
			check(lines[lines.size() - 1] == tip, "keybind_dialogue_tip_stable_across_device")
		hub.dialogue_ui.close()

	# The Hub's top-left objective line names the movement and interact keys,
	# so it must follow both a rebind and a controller switch.
	await _tap_key(KEY_ESCAPE)
	flow.set_keybind(&"interact", KEY_E)
	var hub_hint := hub.get_node_or_null("Overlay/TopLeft/Margin/VBox/Hint") as Label
	check(hub_hint != null, "keybind_hub_hint_exists")
	if hub_hint != null:
		check(hub_hint.text == "目标：追回失踪名册的三页 · %s / %s 移动 · E 交互" % [
			flow.prompt_label(&"move_left"), flow.prompt_label(&"move_right")],
			"keybind_hub_hint_keyboard")
		flow.set_keybind(&"interact", KEY_R)
		check(hub_hint.text.contains("R 交互"), "keybind_hub_hint_follows_rebind")
		await _tap_button(JOY_BUTTON_A)
		check(hub_hint.text.contains("左摇杆 移动") and hub_hint.text.contains("Y 交互"),
			"keybind_hub_hint_follows_pad")
		await _tap_key(KEY_ESCAPE)
		flow.set_keybind(&"interact", KEY_E)
	root.remove_child(hub)
	hub.free()
	await process_frame
	flow.set_keybind(&"npc_inspire", KEY_Y)
	_set_gamepad(false)

	flow.profile.keybinds = saved_keybinds
	flow.profile.joybinds = saved_joybinds
	flow.apply_keybinds(flow.profile)
	flow.profile_path = saved_path
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = temp_profile + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_set_gamepad(false)


func _run() -> void:
	await process_frame
	flow = root.get_node("Flow") as GameFlow
	var keyboard := GameFlow.key_label(&"interact")
	var gamepad := GameFlow.joypad_label(&"interact")
	check(keyboard == "E", "prompt_default_keyboard_is_e")
	check(gamepad == "Y", "prompt_default_gamepad_is_y")

	var pickup = load("res://scenes/combat/pickup.tscn").instantiate()
	pickup.label_text = "残页"
	root.add_child(pickup)
	var player := Node.new()
	root.add_child(player)
	player.add_to_group("player")

	_set_gamepad(false)
	pickup._on_body_entered(player)
	check(pickup.label.text == "%s 拾取 · 残页" % keyboard, "prompt_pickup_keyboard")
	_set_gamepad(true)
	check(pickup.label.text == "%s 拾取 · 残页" % gamepad, "prompt_pickup_gamepad_follows_switch")
	pickup._on_body_exited(player)
	check(pickup.label.text == "残页", "prompt_pickup_hides_action_when_far")
	_set_gamepad(false)
	pickup.free()
	player.free()

	var chest = load("res://scripts/levels/treasure_chest.gd").new()
	root.add_child(chest)
	_set_gamepad(false)
	check(chest.prompt_text() == "%s  开启" % keyboard, "prompt_chest_keyboard")
	_set_gamepad(true)
	check(chest.prompt_text() == "%s  开启" % gamepad, "prompt_chest_gamepad")
	_set_gamepad(false)
	chest.free()

	var stele = load("res://scenes/levels/memory_stele.tscn").instantiate()
	root.add_child(stele)
	_set_gamepad(false)
	check(stele.prompt.text == "按 %s 读取残碑" % keyboard, "prompt_stele_keyboard")
	_set_gamepad(true)
	check(stele.prompt.text == "按 %s 读取残碑" % gamepad, "prompt_stele_gamepad_follows_switch")
	_set_gamepad(false)
	stele.free()

	var shop = load("res://scenes/levels/memory_shop.tscn").instantiate()
	root.add_child(shop)
	_set_gamepad(false)
	check(shop.prompt.text == "按 %s 用残页换物" % keyboard, "prompt_shop_keyboard")
	_set_gamepad(true)
	check(shop.prompt.text == "按 %s 用残页换物" % gamepad, "prompt_shop_gamepad_follows_switch")
	_set_gamepad(false)
	check(shop.prompt.text == "按 %s 用残页换物" % keyboard, "prompt_shop_returns_to_keyboard")
	shop.free()

	# Hub prompts must also follow a device switch while the Hub is open.
	flow.title_shown_this_session = true
	var hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub)
	await process_frame
	var talkable = null
	for candidate in hub.get_npcs():
		if candidate.prompt_label != null:
			talkable = candidate
			break
	check(talkable != null, "prompt_hub_has_npc_prompt")
	if talkable != null:
		_set_gamepad(false)
		check(talkable.prompt_label.text == "按 %s 交谈" % keyboard, "prompt_hub_npc_keyboard")
		_set_gamepad(true)
		check(talkable.prompt_label.text == "按 %s 交谈" % gamepad, "prompt_hub_npc_gamepad")
		_set_gamepad(false)
		check(talkable.prompt_label.text == "按 %s 交谈" % keyboard, "prompt_hub_npc_returns")
	check(hub.portal != null and hub.portal.prompt_label != null, "prompt_hub_has_portal")
	if hub.portal != null and hub.portal.prompt_label != null:
		_set_gamepad(true)
		check(hub.portal.prompt_label.text == "按 %s 出发" % gamepad, "prompt_hub_portal_gamepad")
		_set_gamepad(false)
		check(hub.portal.prompt_label.text == "按 %s 出发" % keyboard, "prompt_hub_portal_keyboard")
	check(hub.training_dummy != null and hub.training_dummy._prompt != null, "prompt_hub_has_dummy")
	if hub.training_dummy != null and hub.training_dummy._prompt != null:
		_set_gamepad(true)
		check(hub.training_dummy._prompt.text == "训练碑 · 按 %s 试放" % gamepad, "prompt_hub_dummy_gamepad")
		_set_gamepad(false)
		check(hub.training_dummy._prompt.text == "训练碑 · 按 %s 试放" % keyboard, "prompt_hub_dummy_keyboard")
	hub.free()
	await process_frame

	await _test_modal_close_prompts()
	await _test_prompts_built_once()
	await _test_keybind_prompts()

	await process_frame
	print("UI PROMPTS INTEGRATION: %d checks, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
