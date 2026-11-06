class_name ArenaRoom
extends Node2D

## 一间战斗房：锁门后生成/清空敌人，清怪后开门并发出 cleared。
## 敌人只按 PackedScene + tree_exited 追踪，不依赖敌人模块的具体类。

signal cleared

const DOORS_NODE: String = "Doors"
const ENEMIES_NODE: String = "Enemies"

@export var room_id: StringName = &""
## Optional stable id for the encounter's one-shot clear record. Empty: game.gd
## derives `room_id/NodeName`, so a room can hold several named arenas.
@export var encounter_id: StringName = &""
@export var entry_half_width: float = 530.0


func contains_entry(world_position: Vector2) -> bool:
	var local := to_local(world_position)
	return absf(local.x) < entry_half_width and local.y > -260.0 and local.y < 300.0

var _locked: bool = false
var _cleared: bool = false
var _emitted_cleared: bool = false
var _tracked_enemies: Dictionary = {}
var _wave_queue: Array[Callable] = []
var _suppress_events: bool = false


func queue_wave(callback: Callable) -> void:
	if callback.is_valid():
		_wave_queue.append(callback)


func _ready() -> void:
	var doors := get_node_or_null(DOORS_NODE)
	if doors != null:
		for door in doors.get_children():
			var visual := Node2D.new()
			visual.set_script(preload("res://scripts/presentation/ink_gate.gd"))
			door.add_child(visual)


func _exit_tree() -> void:
	_suppress_events = true


## 关门并进入战斗状态。若此时房内没有敌人，则视为已经清空。
func lock_until_cleared() -> void:
	if _suppress_events:
		return
	_locked = true
	_cleared = false
	_emitted_cleared = false
	_set_doors_locked(true)
	if _tracked_enemies.is_empty():
		_finish_room()


func is_locked() -> bool:
	return _locked


func is_cleared() -> bool:
	return _cleared


func enemy_count() -> int:
	return _tracked_enemies.size()


## 在房间内生成一个敌人；敌人在场景树中消失时自动计入清怪进度。
func spawn_enemy(enemy_scene: PackedScene, position: Vector2) -> Node2D:
	if enemy_scene == null or _suppress_events:
		return null
	var enemy := enemy_scene.instantiate()
	if enemy == null:
		return null
	if not enemy is Node2D:
		push_error("ArenaRoom.spawn_enemy: scene root must be a Node2D")
		enemy.free()
		return null

	var enemy_node := enemy as Node2D
	enemy_node.position = position
	var instance_id := enemy.get_instance_id()
	_tracked_enemies[instance_id] = true
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(instance_id), CONNECT_ONE_SHOT)
	_get_or_create_enemies_root().add_child(enemy_node)
	return enemy_node


func _on_enemy_tree_exited(instance_id: int) -> void:
	if _suppress_events:
		return
	if not _tracked_enemies.erase(instance_id):
		return
	if _locked and _tracked_enemies.is_empty():
		if not _wave_queue.is_empty():
			var next: Callable = _wave_queue.pop_front()
			next.call()
			if not _tracked_enemies.is_empty():
				return
		_finish_room()


func _finish_room() -> void:
	_locked = false
	_cleared = true
	_set_doors_locked(false)
	if _emitted_cleared:
		return
	_emitted_cleared = true
	cleared.emit()


func _set_doors_locked(locked: bool) -> void:
	var doors := get_node_or_null(DOORS_NODE)
	if doors == null:
		return
	doors.visible = locked
	for child in doors.get_children():
		if child is CollisionObject2D:
			var body := child as CollisionObject2D
			if is_inside_tree():
				body.set_deferred(&"collision_layer", 1 if locked else 0)
			else:
				body.collision_layer = 1 if locked else 0


func _get_or_create_enemies_root() -> Node2D:
	var node := get_node_or_null(ENEMIES_NODE) as Node2D
	if node != null:
		return node
	node = Node2D.new()
	node.name = ENEMIES_NODE
	add_child(node)
	return node
