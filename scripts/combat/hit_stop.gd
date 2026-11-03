class_name HitStop
extends Node

var _frozen := false


func freeze(duration: float, time_scale_value: float = 0.05) -> void:
	if _frozen:
		return
	begin(time_scale_value)
	await get_tree().create_timer(duration, true, false, true).timeout
	end()


func begin(time_scale_value: float = 0.05) -> void:
	Engine.time_scale = time_scale_value
	_frozen = true


func end() -> void:
	Engine.time_scale = 1.0
	_frozen = false


func is_frozen() -> bool:
	return _frozen
