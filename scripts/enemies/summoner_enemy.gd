class_name SummonerEnemy
extends Enemy

## 合唱召引者：躲在后排，用歌声把残页缝成小怪；第三段唱词会治疗自己。
## 召唤物走 ArenaRoom.spawn_enemy，清场判定仍然可靠。

@export var minion_scene: PackedScene = preload("res://scenes/enemies/summoned_page.tscn")
@export var cast_range: float = 520.0
@export var keep_distance: float = 240.0
@export var max_minions: int = 3


func _ready() -> void:
	attack_variant_count = 3
	super._ready()


func _chase_behavior(_delta: float) -> void:
	if not _has_valid_target():
		change_state(STATE_IDLE)
		return
	var distance := _distance_to_target()
	if distance > deaggro_range:
		change_state(STATE_IDLE)
		return
	if distance < keep_distance:
		var retreat_x := global_position.x - target.global_position.x
		velocity.x = signf(retreat_x) * get_move_speed()
		_face_direction(-retreat_x)
		return
	_face_direction(target.global_position.x - global_position.x)
	if distance <= cast_range:
		velocity.x = move_toward(velocity.x, 0.0, get_move_speed() * 4.0)
		if _attack_cooldown_left <= 0.0:
			change_state(STATE_ATTACK)
		return
	_move_toward_target(get_move_speed())


func _perform_attack() -> void:
	if not is_inside_tree():
		return
	var variant := get_attack_variant()
	if variant >= 3:
		health = mini(health + maxi(int(roundf(max_health * 0.08)), 2), max_health)
		health_changed.emit(health, max_health)
		_sync_health_bar()
		CombatFX.spawn(get_parent(), global_position + Vector2(0, -24), &"heal", Color("a8e6b0"), _facing, 54)
	var wanted := 1 if variant <= 1 else 2
	if variant >= 3:
		wanted = 1
	for index in wanted:
		if _summoned_count() >= max_minions:
			break
		_summon_one(index, variant)


func _summon_one(index: int, variant: int) -> void:
	if minion_scene == null:
		return
	var offset := Vector2((index * 2 - 1) * 42.0, 0)
	var spawn_position := global_position + offset
	var minion: Node2D = null
	var room := _find_room()
	if room != null and get_parent() != null:
		minion = room.spawn_enemy(minion_scene, get_parent().to_local(spawn_position)) as Node2D
	else:
		minion = minion_scene.instantiate() as Node2D
		if minion != null:
			get_parent().add_child(minion)
			minion.position = get_parent().to_local(spawn_position)
	if minion == null:
		return
	var summoned := minion as Enemy
	if summoned != null:
		summoned.set_meta(&"summoned", true)
		if _has_valid_target():
			summoned.set_target(target)
		summoned.aggro_range = 680.0
		summoned.deaggro_range = 1100.0
		if variant >= 2:
			summoned.health = maxi(int(roundf(summoned.health * 0.75)), 1)
	if is_inside_tree():
		CombatFX.spawn(get_parent(), spawn_position + Vector2(0, -18), &"cast", Color("c9b3e8"), _facing, 42)


func _summoned_count() -> int:
	if get_parent() == null:
		return 0
	var count := 0
	for child in get_parent().get_children():
		if child is Enemy and child != self and child.has_meta(&"summoned"):
			count += 1
	return count


func _find_room() -> ArenaRoom:
	var node := get_parent()
	while node != null:
		if node is ArenaRoom:
			return node as ArenaRoom
		node = node.get_parent()
	return null


func _finish_attack() -> void:
	super._finish_attack()
	_attack_cooldown_left *= 1.25
