extends SceneTree

## Touch controls in the real game (1.0.1): the overlay appears in the Hub and
## in a run, a stick finger and a jump finger work at the same time, menu
## buttons open pages (which hide the overlay), prompts and the HUD switch to
## touch, and the settings can hide the controls.
##   godot --headless --path . -s res://tests/integration_touch.gd

var failures: int = 0
var assertions: int = 0


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("TOUCH FAIL: " + label)


func _initialize() -> void:
	_run.call_deferred()


func _touch(overlay: TouchOverlay, index: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	overlay._input(event)


func _drag(overlay: TouchOverlay, index: int, at: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = at
	overlay._input(event)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _button(overlay: TouchOverlay, action: StringName) -> Dictionary:
	for item in overlay.buttons():
		if item["action"] == action:
			return item
	return {}


func _run() -> void:
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.title_shown_this_session = true
	var overlay := flow.touch_overlay
	check(overlay != null, "overlay_owned_by_flow")
	if overlay == null:
		quit(1)
		return

	# Touch prompts and HUD layout follow the device.
	flow._set_using_touch(true)
	check(flow.using_touch, "touch_mode_on")
	check(flow.prompt_label(&"jump") == "「跳」", "touch_prompt_jump")
	check(flow.close_prompt() == "点按", "touch_close_prompt")

	# Hub: the overlay is there (the old controls only existed inside a run).
	var hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await create_timer(0.6).timeout
	if hub.dialogue_ui != null and hub.dialogue_ui.is_open():
		hub.dialogue_ui.close()
	if hub.tutorial_flow != null:
		hub.tutorial_flow.queue_free()
	await _frames(4)
	check(overlay.is_active(), "overlay_shown_in_hub")
	var hub_player = hub.player
	var hub_x: float = hub_player.global_position.x
	_touch(overlay, 0, Vector2(220, 560), true)
	_drag(overlay, 0, Vector2(300, 560))
	await create_timer(0.6).timeout
	check(hub_player.global_position.x > hub_x + 40.0, "hub_stick_walks")
	_touch(overlay, 0, Vector2(300, 560), false)
	root.remove_child(hub)
	hub.free()
	await process_frame

	# Run.
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.mutators_enabled = false
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.5).timeout
	if scene._story.is_open():
		scene._story.close()
	var left := 8.0
	while left > 0.0 and (scene._mds_world == null or scene._mds_world.changing_room or scene._mds_world.current_room.is_empty()):
		await create_timer(0.05).timeout
		left -= 0.05
	await _frames(6)
	check(overlay.is_active(), "overlay_shown_in_run")
	var hud_slots := scene.hud.find_child("BottomSlots", true, false) as Control
	check(hud_slots != null and is_equal_approx(hud_slots.anchor_top, 0.0), "hud_cards_move_to_top_in_touch")
	var player = scene.player
	player._invulnerable_left = 600.0
	for node in get_nodes_in_group("enemies"):
		node.set_physics_process(false)
	for _settle in 120:
		if player.is_on_floor():
			break
		await physics_frame

	# Multi-touch: hold the stick right with finger 0, jump with finger 1.
	var start: Vector2 = player.global_position
	_touch(overlay, 0, Vector2(200, 560), true)
	_drag(overlay, 0, Vector2(290, 560))
	await _frames(2)
	check(Input.is_action_pressed(&"move_right"), "stick_right_held")
	check(overlay.stick_vector().x > 0.9, "stick_vector_right")
	await _frames(6)
	var jump := _button(overlay, &"jump")
	check(not jump.is_empty(), "jump_button_present")
	_touch(overlay, 1, jump.get("center", Vector2.ZERO), true)
	await _frames(3)
	check(Input.is_action_pressed(&"move_right") and Input.is_action_pressed(&"jump"), "stick_and_jump_together")
	check(player.velocity.y < -100.0 or player.global_position.y < start.y - 4.0, "multitouch_jump_rises")
	await _frames(12)
	check(player.global_position.x > start.x + 20.0, "multitouch_keeps_running")
	# Second press in the air: double jump.
	_touch(overlay, 1, jump.get("center", Vector2.ZERO), false)
	await _frames(1)
	var air_jumps_before: bool = player.can_double_jump()
	_touch(overlay, 1, jump.get("center", Vector2.ZERO), true)
	await _frames(2)
	check(air_jumps_before and not player.can_double_jump(), "touch_double_jump")
	_touch(overlay, 1, jump.get("center", Vector2.ZERO), false)
	_touch(overlay, 0, Vector2(290, 560), false)
	await _frames(2)
	check(not Input.is_action_pressed(&"move_right") and not Input.is_action_pressed(&"jump"), "fingers_up_release")

	# Sliding a finger from attack onto dodge hands the press over.
	var attack := _button(overlay, &"attack")
	var dodge := _button(overlay, &"dodge")
	_touch(overlay, 2, attack.get("center", Vector2.ZERO), true)
	check(overlay.is_held(&"attack"), "attack_held")
	_drag(overlay, 2, dodge.get("center", Vector2.ZERO))
	check(overlay.is_held(&"dodge") and not overlay.is_held(&"attack"), "slide_hands_over")
	_touch(overlay, 2, dodge.get("center", Vector2.ZERO), false)

	# Every button sits inside the screen and clear of the top HUD panels.
	var size := overlay.screen_size()
	for item in overlay.buttons():
		var c: Vector2 = item["center"]
		var r: float = item["radius"]
		check(c.x - r >= 0.0 and c.x + r <= size.x and c.y - r >= 120.0 and c.y + r <= size.y,
			"button_on_screen_%s" % item["action"])

	# A menu button opens its page; the page pauses the run and hides the overlay.
	var bag: Dictionary = overlay.menu_buttons()[0]
	_touch(overlay, 3, (bag["rect"] as Rect2).get_center(), true)
	await create_timer(0.3).timeout
	_touch(overlay, 3, (bag["rect"] as Rect2).get_center(), false)
	check(scene.inventory_ui.visible, "menu_opens_bag")
	await _frames(2)
	check(not overlay.is_active(), "overlay_hides_behind_pages")
	scene._toggle_overlay(scene.inventory_ui)
	await create_timer(0.2).timeout
	await _frames(2)
	check(overlay.is_active(), "overlay_back_after_page")

	# Settings: "never" hides the controls even with a finger on the screen.
	flow.profile.touch_mode = 2
	flow.apply_touch_settings()
	await _frames(2)
	check(not flow.using_touch and not overlay.is_active(), "settings_hide_touch")
	flow.profile.touch_mode = 0
	flow.apply_touch_settings()
	flow._set_using_touch(false)
	await _frames(2)
	check(hud_slots != null and is_equal_approx(hud_slots.anchor_top, 1.0), "hud_cards_return_for_keyboard")

	print("TOUCH INTEGRATION: %d checks, %d failures" % [assertions, failures])
	root.remove_child(scene)
	scene.free()
	quit(1 if failures > 0 else 0)
