class_name MusicPlayer
extends AudioStreamPlayer


func _ready() -> void:
	var wav := stream as AudioStreamWAV
	if wav != null:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	play()
