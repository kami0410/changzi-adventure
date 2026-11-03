class_name Damageable
extends Node

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 10

var health: int = 0
var _dead := false


func _init() -> void:
	health = max_health


func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)


func take_damage(amount: int) -> void:
	if amount <= 0 or _dead:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		_dead = true
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0 or _dead:
		return
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)
