class_name EnemyData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var max_health: int = 10
@export var speed: float = 80.0
@export var contact_damage: int = 5
@export var behavior: StringName = &"melee"
@export var loot_table: Resource
