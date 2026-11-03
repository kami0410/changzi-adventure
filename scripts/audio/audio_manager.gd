class_name AudioManager
extends Node

## Music, voice and SFX share the autoload so tracks survive scene changes.
## Music is an original procedural score; voice is a local SAPI prototype.

var _music: AudioStreamPlayer
var _voice: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_tween: Tween
var _duck_tween: Tween
var _current_music := ""
var _ducked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Headless launch checks have no audio device; creating players there only
	# produces cleanup warnings. Anything that actually asks for sound calls
	# _ensure_players() on demand.
	if DisplayServer.get_name() != "headless":
		_ensure_players()


func _ensure_players() -> void:
	_ensure_buses()
	if _music == null:
		_music = AudioStreamPlayer.new()
		_music.name = "MusicPlayer"
		_music.bus = "Music"
		add_child(_music)
	if _voice == null:
		_voice = AudioStreamPlayer.new()
		_voice.name = "VoicePlayer"
		_voice.bus = "Voice"
		add_child(_voice)
		_voice.finished.connect(_restore_music)


func play_sfx(id: StringName, bus: StringName = &"SFX") -> void:
	var path := "res://assets/audio/%s.wav" % id
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/sfx/%s.wav" % id
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/%s.ogg" % id
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = String(bus)
	add_child(player)
	_sfx_players.append(player)
	player.finished.connect(func() -> void:
		_sfx_players.erase(player)
		player.queue_free()
	)
	player.play()


func _ensure_buses() -> void:
	if AudioServer.get_bus_index("Voice") < 0:
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, "Voice")
		AudioServer.set_bus_send(index, "Master")
		AudioServer.set_bus_volume_db(index, -2.0)
	if AudioServer.get_bus_effect_count(0) == 0 and ClassDB.class_exists("AudioEffectHardLimiter"):
		var limiter := AudioEffectHardLimiter.new()
		limiter.ceiling_db = -0.3
		AudioServer.add_bus_effect(0, limiter)


func play_music(path: String, fade: float = 1.0) -> void:
	_ensure_players()
	if path == _current_music and _music != null and _music.playing:
		return
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size() / 2
	_current_music = path
	if _music == null:
		return
	if _music.playing and fade > 0.0:
		_music_tween = create_tween()
		_music_tween.tween_property(_music, "volume_db", -40.0, fade * 0.35)
		await _music_tween.finished
	_music.stream = stream
	_music.volume_db = -30.0 if fade > 0.0 else -6.0
	_music.play()
	if fade > 0.0:
		_music_tween = create_tween()
		_music_tween.tween_property(_music, "volume_db", -6.0, fade * 0.65)


func stop_music(fade: float = 0.6) -> void:
	_current_music = ""
	if _music == null or not _music.playing:
		return
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", -40.0, fade)
	_music_tween.tween_callback(_music.stop)


func play_voice(id: String) -> void:
	_ensure_players()
	var path := "res://assets/audio/voice/zh_cn/%s.ogg" % id
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/voice/zh_cn/%s.wav" % id
	if not ResourceLoader.exists(path) or _voice == null:
		return
	_voice.stream = load(path)
	_voice.volume_db = -1.0
	_voice.play()
	_duck_music()


func stop_voice() -> void:
	if _voice != null and _voice.playing:
		_voice.stop()
	_restore_music()


func _duck_music() -> void:
	if _ducked:
		return
	_ducked = true
	var index := AudioServer.get_bus_index("Music")
	if index >= 0:
		AudioServer.set_bus_volume_db(index, -14.0)


func _restore_music() -> void:
	if not _ducked:
		return
	_ducked = false
	var index := AudioServer.get_bus_index("Music")
	if index < 0:
		return
	_duck_tween = create_tween()
	_duck_tween.tween_method(func(value: float): AudioServer.set_bus_volume_db(index, value), -14.0, -6.0, 0.45)


func set_music_layer(layer: int) -> void:
	# Reserved for adaptive layers; the score switches tracks per chapter.
	pass


## Stop and release every player/tween, including short-lived SFX players.
## Public so exit tests can prove the cleanup without quitting the engine.
func shutdown() -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	for player in _sfx_players:
		_release_player(player)
	_sfx_players.clear()
	_release_player(_music)
	_release_player(_voice)
	_music = null
	_voice = null


func _release_player(player: AudioStreamPlayer) -> void:
	if player == null or not is_instance_valid(player):
		return
	player.stop()
	player.stream = null
	var parent := player.get_parent()
	if parent != null:
		parent.remove_child(player)
	player.free()


func _exit_tree() -> void:
	shutdown()
