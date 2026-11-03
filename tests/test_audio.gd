extends RefCounted


func run(t: Callable) -> void:
	t.call(AudioServer.get_bus_index("Music") >= 0, true, "bus_music")
	t.call(AudioServer.get_bus_index("SFX") >= 0, true, "bus_sfx")
	t.call(AudioServer.get_bus_index("UI") >= 0, true, "bus_ui")
	t.call(ResourceLoader.exists("res://assets/audio/music/title.ogg"), true, "music_asset_loads")
	t.call(ResourceLoader.exists("res://assets/audio/voice/zh_cn/ch1_intro.ogg"), true, "voice_asset_loads")

	var manager := AudioManager.new()
	manager.play_sfx(&"missing")
	t.call(true, true, "audio_missing_safe")
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(manager)
	manager._ensure_players()
	t.call(AudioServer.get_bus_index("Voice") >= 0, true, "bus_voice")
	t.call(manager._music != null, true, "music_player_created")
	t.call(manager._voice != null, true, "voice_player_created")
	t.call(load("res://assets/audio/music/title.ogg") is AudioStreamOggVorbis, true, "music_is_ogg")
	t.call(load("res://assets/audio/voice/zh_cn/ch1_intro.ogg") is AudioStreamOggVorbis, true, "voice_is_ogg")
	tree.root.remove_child(manager)
	manager.free()

	var hit_stop := HitStop.new()
	hit_stop.begin(0.1)
	t.call(Engine.time_scale, 0.1, "hit_stop_begin")
	t.call(hit_stop.is_frozen(), true, "hit_stop_frozen")
	hit_stop.end()
	t.call(Engine.time_scale, 1.0, "hit_stop_end")
	t.call(hit_stop.is_frozen(), false, "hit_stop_unfrozen")
	hit_stop.free()
