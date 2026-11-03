extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	(root.get_node("Flow") as GameFlow).auto_save = false
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.7).timeout
	await _capture("campaign_intro")
	scene._story.close()
	await create_timer(0.4).timeout
	await _capture("campaign_start")
	scene.player.global_position = Vector2(900, 530)
	await process_frame
	scene._try_open_shop()
	await process_frame
	await _capture("campaign_shop")
	if scene._shop_ui.visible:
		scene._shop_ui.close_shop()
	await create_timer(0.2).timeout
	scene._toggle_overlay(scene.codex_ui)
	await process_frame
	if scene.codex_ui._free_text != null:
		scene.codex_ui._free_text.text = "让雷落在火里"
		scene.codex_ui._on_free_text_submitted("让雷落在火里")
	await process_frame
	await _capture("campaign_freeform")
	scene._close_overlay()
	await create_timer(0.2).timeout
	scene.player.global_position = Vector2(1440, 530)
	(scene.player.get_node("Camera2D") as Camera2D).reset_smoothing()
	await create_timer(0.5).timeout
	scene._update_room_locks()
	await create_timer(0.4).timeout
	await _capture("campaign_combat")
	scene.phrase_caster.cast(0)
	await create_timer(0.14).timeout
	await _capture("campaign_spell_fire")
	var resolver := PhraseResolver.new()
	var words: Dictionary = {}
	for entry in ContentLibrary.WORDS:
		words[entry.id] = entry
	var chain := resolver.resolve([words[&"grguan"], words[&"lei"]] as Array[WordData])
	scene.phrase_caster.equip_phrase(1, chain)
	scene.phrase_caster._cooldowns[1] = 0.0
	scene.phrase_caster.cast(1)
	await create_timer(0.12).timeout
	await _capture("campaign_spell_chain")
	var vortex := resolver.resolve([words[&"jingmo"], words[&"shenyuan"]] as Array[WordData])
	scene.phrase_caster.equip_phrase(1, vortex)
	scene.phrase_caster._cooldowns[1] = 0.0
	scene.phrase_caster.cast(1)
	await create_timer(0.18).timeout
	await _capture("campaign_spell_vortex")
	scene._start_chapter(2)
	await create_timer(0.5).timeout
	await _capture("campaign_sea_intro")
	scene._story.close()
	await create_timer(0.6).timeout
	await _capture("campaign_sea")
	scene.player.global_position = Vector2(12000 + 4480 - 480, 530)
	(scene.player.get_node("Camera2D") as Camera2D).reset_smoothing()
	scene._update_room_locks()
	await create_timer(0.5).timeout
	await _capture("campaign_boss")
	scene._start_chapter(3)
	await create_timer(0.5).timeout
	await _capture("campaign_theater_intro")
	scene._story.close()
	await create_timer(0.5).timeout
	await _capture("campaign_theater")
	scene.player.global_position = Vector2(18000 + 4480 - 480, 530)
	(scene.player.get_node("Camera2D") as Camera2D).reset_smoothing()
	scene._update_room_locks()
	await create_timer(0.5).timeout
	await _capture("campaign_final_boss")
	paused = false
	root.remove_child(scene)
	scene.free()
	var hub = load("res://scenes/hub/hub.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await create_timer(0.6).timeout
	await _capture("campaign_title")
	for child in hub.get_children():
		if child is TitleScreen:
			child._start()
	await create_timer(0.3).timeout
	await _capture("campaign_hub")
	var hub_overlay := hub.get_node_or_null("Overlay") as CanvasLayer
	if hub_overlay != null:
		hub_overlay.visible = false
	if hub.dialogue_ui != null and hub.dialogue_ui.is_open():
		hub.dialogue_ui.close()
	var ai_ui := AISettingsUI.new()
	ModalLayer.host(hub).add_child(ai_ui)
	ai_ui.open()
	await process_frame
	await _capture("campaign_ai_settings")
	quit()

func _capture(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/%s.png" % file)
	print("CAPTURE ", file)
