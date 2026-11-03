extends SceneTree

## Opens every UI screen once and saves a 1280x720 capture of each, for UI review.
## Godot --path . --resolution 1280x720 --script tests/capture_ui.gd -- --out-dir=res://artifacts/ui

var _dir := "res://artifacts/ui"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			_dir = argument.trim_prefix("--out-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	var flow := root.get_node("Flow") as GameFlow
	flow.auto_save = false
	flow.title_shown_this_session = false

	var hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await create_timer(0.6).timeout
	var title: TitleScreen = null
	for child in hub.get_children():
		if child is TitleScreen:
			title = child
	await _capture("01_title")
	if title != null:
		title._start()
	await create_timer(0.4).timeout
	await _capture("02_hub_dialogue")
	if hub.dialogue_ui != null and hub.dialogue_ui.is_open():
		hub.dialogue_ui.close()
	await create_timer(0.2).timeout
	await _capture("03_hub")
	hub.open_npc_inspiration(&"ayan")
	await create_timer(0.3).timeout
	await _capture("04_npc_inspire")
	if hub.npc_inspire_ui != null and hub.npc_inspire_ui.is_open():
		hub.npc_inspire_ui.close()
	await create_timer(0.2).timeout
	if hub.shop_ui != null:
		hub.shop_ui.open()
		await create_timer(0.2).timeout
		await _capture("05_hub_shop")
		hub.shop_ui.close()
	await create_timer(0.2).timeout
	hub.perform_npc_function(&"luchen", &"archive")
	await create_timer(0.2).timeout
	await _capture("05b_archive")
	if hub.archive_ui != null:
		hub.archive_ui.close()
	await create_timer(0.2).timeout
	var ai_ui := AISettingsUI.new()
	ModalLayer.host(hub).add_child(ai_ui)
	ai_ui.open()
	await create_timer(0.2).timeout
	await _capture("06_ai_settings")
	ai_ui.queue_free()
	paused = false
	root.remove_child(hub)
	hub.free()

	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.6).timeout
	await _capture("07_story_intro")
	scene._story.close()
	await create_timer(0.4).timeout
	await _capture("08_hud")
	scene._toggle_overlay(scene.inventory_ui)
	await create_timer(0.2).timeout
	await _capture("09_inventory")
	scene._close_overlay()
	scene._toggle_overlay(scene.codex_ui)
	await create_timer(0.1).timeout
	if scene.codex_ui._free_text != null:
		scene.codex_ui._free_text.text = "一百颗追踪的火星爆炸"
		scene.codex_ui._on_free_text_submitted("一百颗追踪的火星爆炸")
	await create_timer(0.2).timeout
	await _capture("10_codex")
	scene._close_overlay()
	scene._toggle_overlay(scene.settings_menu)
	await create_timer(0.2).timeout
	await _capture("11_settings")
	scene._close_overlay()
	scene._toggle_overlay(scene._help_ui)
	await create_timer(0.2).timeout
	await _capture("12_help")
	scene._close_overlay()
	scene._toggle_pause()
	await create_timer(0.2).timeout
	await _capture("13_pause")
	scene._toggle_pause()
	await create_timer(0.2).timeout
	scene.player.global_position = Vector2(900, 530)
	await process_frame
	if scene._try_open_shop():
		await create_timer(0.2).timeout
		await _capture("14_run_shop")
		scene._shop_ui.close_shop()
	await create_timer(0.2).timeout
	var room: ArenaRoom = scene._rooms[0]
	scene.player.global_position = room.global_position + Vector2(-480, 250)
	scene._update_room_locks()
	await create_timer(0.3).timeout
	scene.hud.show_boss("墨骸史官", 60, 100)
	scene.hud.show_message("获得：新词 · 追猎")
	await create_timer(0.2).timeout
	await _capture("15_hud_combat")
	scene.hud.hide_boss()
	for enemy in room.get_node("Enemies").get_children():
		if enemy is Enemy:
			enemy.take_damage(100000)
	await create_timer(0.8).timeout
	await _capture("16_reward")
	if scene._reward_ui.visible:
		scene._reward_ui._choose(0)
	await create_timer(0.2).timeout
	var chapter := CampaignData.chapter(0)
	scene._story.open_choice("留下你的选择", chapter["choice"]["title"], chapter["choice"]["body"], chapter["choice"]["options"])
	await create_timer(0.3).timeout
	await _capture("17_choice")
	scene._story._choose(0)
	await create_timer(0.2).timeout
	scene.ending_screen.show_campaign_ending(true, 30, CampaignData.ending_for(true, 20, 3, false), 4, 37)
	await create_timer(0.4).timeout
	await _capture("18_ending")
	quit()


func _capture(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_dir.path_join(file + ".png"))
	print("CAPTURE ", file)
