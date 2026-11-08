class_name AudioManager
extends Node

## Music, voice and SFX share the autoload so tracks survive scene changes.
## Music is an original procedural score; voice is a local SAPI prototype.

var _music: AudioStreamPlayer
## Adaptive combat stem (<track>_combat.ogg): same tempo and length as the
## track, started in sync and faded in by set_music_layer(1) during fights.
var _combat: AudioStreamPlayer
var _combat_tween: Tween
var _music_layer := 0
const COMBAT_ON_DB := -7.0
const COMBAT_OFF_DB := -60.0
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
	if _combat == null:
		_combat = AudioStreamPlayer.new()
		_combat.name = "CombatLayer"
		_combat.bus = "Music"
		_combat.volume_db = COMBAT_OFF_DB
		add_child(_combat)
	if _voice == null:
		_voice = AudioStreamPlayer.new()
		_voice.name = "VoicePlayer"
		_voice.bus = "Voice"
		add_child(_voice)
		_voice.finished.connect(_restore_music)


const SFX_PITCH_JITTER := 0.07


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
	# Small random pitch per play so repeated hits and steps do not sound
	# machine-identical (UI clicks stay exact).
	if not String(id).begins_with("ui_"):
		player.pitch_scale = randf_range(1.0 - SFX_PITCH_JITTER, 1.0 + SFX_PITCH_JITTER)
	add_child(player)
	_sfx_players.append(player)
	player.finished.connect(func() -> void:
		_sfx_players.erase(player)
		player.queue_free()
	)
	# Headless unit tests build an AudioManager before root enters the tree;
	# playing a stream there is an engine error, not a product failure.
	if is_inside_tree():
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
	_start_combat_layer(path)
	if is_inside_tree():
		_music.play()
		if _combat != null and _combat.stream != null:
			_combat.play()
	if fade > 0.0:
		_music_tween = create_tween()
		_music_tween.tween_property(_music, "volume_db", -6.0, fade * 0.65)


## The track's combat stem, if one exists; it plays silently until a fight.
static func combat_stem_path(path: String) -> String:
	return path.get_basename() + "_combat." + path.get_extension()


func has_combat_layer() -> bool:
	return _combat != null and _combat.stream != null


func music_layer() -> int:
	return _music_layer


func _start_combat_layer(path: String) -> void:
	if _combat == null:
		return
	_combat.stop()
	_combat.stream = null
	_music_layer = 0
	_combat.volume_db = COMBAT_OFF_DB
	var stem := combat_stem_path(path)
	if not ResourceLoader.exists(stem):
		return
	var stream := load(stem) as AudioStream
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_combat.stream = stream


func stop_music(fade: float = 0.6) -> void:
	_current_music = ""
	set_music_layer(0)
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


## 0 = exploration, 1 = combat: fades the chapter's combat stem in or out.
func set_music_layer(layer: int) -> void:
	layer = clampi(layer, 0, 1)
	if layer == _music_layer:
		return
	_music_layer = layer
	if _combat == null or _combat.stream == null:
		return
	if _combat_tween != null and _combat_tween.is_valid():
		_combat_tween.kill()
	_combat_tween = create_tween()
	_combat_tween.tween_property(_combat, "volume_db", COMBAT_ON_DB if layer == 1 else COMBAT_OFF_DB, 0.8 if layer == 1 else 2.4)


## Stop and release every player/tween, including short-lived SFX players.
## Public so exit tests can prove the cleanup without quitting the engine.
## `settle_msec` keeps the players alive after stop() so the mixing thread can
## drop its playback references before the streams are freed; freeing an Ogg
## stream while a mix is in flight leaks the playback objects at engine exit.
func shutdown(settle_msec: int = 0) -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	if _combat_tween != null and _combat_tween.is_valid():
		_combat_tween.kill()
	_stop_player(_music)
	_stop_player(_combat)
	_stop_player(_voice)
	for player in _sfx_players:
		_stop_player(player)
	if settle_msec > 0:
		OS.delay_msec(settle_msec)
	for player in _sfx_players:
		_release_player(player)
	_sfx_players.clear()
	_release_player(_music)
	_release_player(_combat)
	_release_player(_voice)
	_combat = null
	_music = null
	_voice = null


func _stop_player(player: AudioStreamPlayer) -> void:
	if player != null and is_instance_valid(player):
		player.stop()


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
	# Gameplay scenes intentionally leave audio alone (see game.gd): the
	# autoload owns the music and stops it here, once, at engine teardown.
	shutdown(100)
