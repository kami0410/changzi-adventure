class_name WeaponData
extends Resource

enum Kind { MELEE, RANGED }

@export var id: StringName = &""
@export var display_name: String = ""
@export var kind: Kind = Kind.MELEE
@export var damage: int = 10
@export var attack_cooldown: float = 0.4
@export var attack_range: float = 64.0
@export var projectile_speed: float = 600.0
## Behaviour identity for the demo: page_ripple / chain_pull / ink_break /
## ink_pierce / echo_shot / talisman_mark. Empty means no special.
@export var special_id: StringName = &""
@export var tags: Array[StringName] = []
@export var icon: Texture2D
