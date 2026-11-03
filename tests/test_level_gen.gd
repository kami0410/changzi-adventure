extends RefCounted

const ROOM_SCENE_PATH := "res://scenes/levels/room.tscn"
const BIOME_SCENE_PATHS := [
	"res://scenes/levels/biome_1.tscn",
	"res://scenes/levels/biome_2.tscn",
]


func run(t: Callable) -> void:
	_test_seed_determinism(t)
	_test_seed_variation(t)
	_test_layout_shape(t)
	_test_room_combat_lock(t)
	_test_biome_scenes(t)


func _test_seed_determinism(t: Callable) -> void:
	var assembler := BiomeAssembler.new()
	var first := assembler.generate(4242, &"ink_archive", 7)
	var second := assembler.generate(4242, &"ink_archive", 7)

	t.call(first.chunks, second.chunks, "same_seed_same_chunks")
	t.call(first.branch_index, second.branch_index, "same_seed_same_branch")
	t.call(first.boss_chunk, second.boss_chunk, "same_seed_same_boss")

	var ruins_a := assembler.generate(4242, &"breathing_ruins", 7)
	var ruins_b := assembler.generate(4242, &"breathing_ruins", 7)
	t.call(ruins_a.chunks, ruins_b.chunks, "same_seed_same_chunks_second_biome")
	t.call(ruins_a.branch_index, ruins_b.branch_index, "same_seed_same_branch_second_biome")


func _test_seed_variation(t: Callable) -> void:
	var assembler := BiomeAssembler.new()
	var first := assembler.generate(4242, &"ink_archive", 7)
	var other := assembler.generate(9001, &"ink_archive", 7)

	t.call(other.chunks != first.chunks, true, "different_seed_different_chunks")

	var ink := assembler.generate(1337, &"ink_archive", 6)
	var ruins := assembler.generate(1337, &"breathing_ruins", 6)
	t.call(ink.chunks != ruins.chunks, true, "different_biome_different_chunks")


func _test_layout_shape(t: Callable) -> void:
	var assembler := BiomeAssembler.new()
	var layout := assembler.generate(77, &"breathing_ruins", 6)

	t.call(layout.chunks.size(), 6, "layout_length_matches_chunk_count")
	t.call(layout.branch_index >= 0, true, "branch_index_not_negative")
	t.call(layout.branch_index < layout.chunks.size(), true, "branch_index_in_range")
	t.call(layout.branch_index < layout.chunks.size() - 1, true, "branch_index_before_boss")
	t.call(layout.boss_chunk != &"", true, "boss_chunk_not_empty")
	t.call(layout.chunks[layout.chunks.size() - 1], layout.boss_chunk, "boss_chunk_at_end")

	var all_chunks_named := true
	for chunk in layout.chunks:
		if chunk == &"":
			all_chunks_named = false
	t.call(all_chunks_named, true, "all_chunks_named")

	var single := assembler.generate(5, &"ink_archive", 1)
	t.call(single.chunks.size(), 1, "single_chunk_layout_length")
	t.call(single.branch_index, 0, "single_chunk_branch_index")
	t.call(single.boss_chunk, single.chunks[0], "single_chunk_is_boss")
	t.call(single.boss_chunk != &"", true, "single_chunk_boss_not_empty")


func _test_room_combat_lock(t: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		t.call(false, true, "room_test_requires_scene_tree")
		return

	var room_scene := load(ROOM_SCENE_PATH) as PackedScene
	t.call(room_scene != null, true, "room_scene_loads")
	if room_scene == null:
		return

	var room := room_scene.instantiate() as ArenaRoom
	t.call(room != null, true, "room_scene_root_uses_room_script")
	if room == null:
		return

	room.room_id = &"test_room"
	tree.root.add_child(room)

	var cleared_calls: Array[int] = []
	room.cleared.connect(func() -> void: cleared_calls.append(1))

	var doors := room.get_node_or_null("Doors") as Node2D
	t.call(doors != null, true, "room_scene_has_doors")
	var enemies := room.get_node_or_null("Enemies") as Node2D
	t.call(enemies != null, true, "room_scene_has_enemy_container")
	if doors == null or enemies == null:
		room.free()
		return

	t.call(room.is_locked(), false, "room_starts_unlocked")
	t.call(room.is_cleared(), false, "room_starts_not_cleared")
	t.call(doors.visible, false, "doors_start_open")

	var enemy_scene := _make_enemy_scene(t)
	room.spawn_enemy(enemy_scene, Vector2(120.0, 240.0))
	room.spawn_enemy(enemy_scene, Vector2(400.0, 240.0))
	t.call(room.enemy_count(), 2, "room_spawns_two_enemies")
	t.call(enemies.get_child_count(), 2, "enemy_scene_instances_added")
	t.call((enemies.get_child(0) as Node2D).position, Vector2(120.0, 240.0), "enemy_position")

	room.lock_until_cleared()
	t.call(room.is_locked(), true, "room_locks")
	t.call(room.is_cleared(), false, "locked_room_not_cleared")
	t.call(doors.visible, true, "doors_close")

	_despawn_enemy(enemies.get_child(0) as Node)
	t.call(room.enemy_count(), 1, "room_tracks_enemy_removal")
	t.call(room.is_locked(), true, "room_stays_locked_with_one_enemy")
	t.call(cleared_calls.size(), 0, "room_not_cleared_with_one_enemy")

	_despawn_enemy(enemies.get_child(0) as Node)
	t.call(room.enemy_count(), 0, "room_all_enemies_gone")
	t.call(room.is_locked(), false, "room_unlocks_after_clear")
	t.call(room.is_cleared(), true, "room_is_cleared")
	t.call(doors.visible, false, "doors_reopen_after_clear")
	t.call(cleared_calls.size(), 1, "room_emits_cleared_once")

	room.free()


func _test_biome_scenes(t: Callable) -> void:
	for path in BIOME_SCENE_PATHS:
		var scene := load(path) as PackedScene
		t.call(scene != null, true, "biome_scene_loads:" + path)
		if scene == null:
			continue
		var instance := scene.instantiate()
		t.call(instance is Node2D, true, "biome_scene_root_is_node_2d:" + path)
		t.call(_count_rooms(instance) > 0, true, "biome_scene_contains_room:" + path)
		instance.free()


func _make_enemy_scene(t: Callable) -> PackedScene:
	var enemy := Node2D.new()
	enemy.name = "TestEnemy"
	var scene := PackedScene.new()
	t.call(scene.pack(enemy), OK, "test_enemy_scene_packs")
	enemy.free()
	return scene


## 测试 runner 在 SceneTree._initialize 中同步执行，此时节点尚未真正进入场景树，
## free() 不会触发引擎的 tree_exited；这里手动发出同一个信号来模拟敌人死亡/移除。
func _despawn_enemy(enemy: Node) -> void:
	enemy.tree_exited.emit()
	enemy.free()


func _count_rooms(node: Node) -> int:
	var count := 1 if node is ArenaRoom else 0
	for child in node.get_children():
		count += _count_rooms(child)
	return count
