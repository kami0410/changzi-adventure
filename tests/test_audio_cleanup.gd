extends RefCounted

## Audio shutdown must release music, voice and every short-lived SFX player
## so the engine exits without audio ObjectDB/resource leaks.

func run(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var audio := AudioManager.new()
	tree.root.add_child(audio)
	audio.play_music("res://assets/audio/music/title.ogg", 0.0)
	t.call(audio._music != null, true, "audio_creates_music_player")
	t.call(audio._music.stream != null, true, "audio_music_has_stream")
	audio.play_sfx(&"hit")
	t.call(audio._sfx_players.size() >= 1, true, "audio_tracks_sfx_player")
	audio.shutdown()
	t.call(audio._sfx_players.is_empty(), true, "audio_clears_sfx_players")
	if audio._music != null:
		t.call(audio._music.stream, null, "audio_clears_music_stream")
	if audio._voice != null:
		t.call(audio._voice.stream, null, "audio_clears_voice_stream")
	tree.root.remove_child(audio)
	audio.free()
