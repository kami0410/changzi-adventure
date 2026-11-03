extends RefCounted

## The Chapter 1 boss must have authored phases: safe zones in phase 2, a
## sealed phrase slot and a weapon mirror in phase 3, and a scene drop hook.

class DummyTarget extends Node2D:
	var sealed_slot := -1
	var sealed_duration := 0.0
	var weapons: Array = []
	var active_weapon_slot := 0

	func disable_phrase_slot(slot: int, duration: float = 3.0) -> bool:
		sealed_slot = slot
		sealed_duration = duration
		return true


func run(t: Callable) -> void:
	_test_scene(t)
	_test_phases(t)
	_test_seal_and_mirror(t)
	_test_death(t)


func _spawn() -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	var parent := Node2D.new()
	tree.root.add_child(parent)
	var boss := (load("res://scenes/bosses/ink_archivist_ch1.tscn") as PackedScene).instantiate() as InkArchivistCh1
	parent.add_child(boss)
	return [tree, parent, boss]


func _despawn(tree: SceneTree, parent: Node2D) -> void:
	tree.root.remove_child(parent)
	parent.free()


func _test_scene(t: Callable) -> void:
	var chapter := CampaignData.chapter(0)
	t.call(chapter.get("boss_scene", null) != null, true, "campaign_ch1_boss_scene")
	t.call(chapter.get("boss_hp", 0), 280, "campaign_ch1_boss_hp")
	var boss := (load("res://scenes/bosses/ink_archivist_ch1.tscn") as PackedScene).instantiate()
	t.call(boss is InkArchivistCh1, true, "ch1_boss_scene_loads")
	t.call(boss is InkArchivist, true, "ch1_boss_extends_ink_archivist")
	boss.free()


func _test_phases(t: Callable) -> void:
	var spawned := _spawn()
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: InkArchivistCh1 = spawned[2]
	var dummy := DummyTarget.new()
	parent.add_child(dummy)
	boss.target = dummy
	boss.max_health = 100
	boss.health = 60
	boss.phase = 1
	boss.check_phase()
	t.call(boss.phase, 2, "ch1_boss_enters_phase_2")
	t.call(boss.is_storm_active(), true, "ch1_phase_2_starts_storm")
	t.call(boss.get_safe_zone_count(), 3, "ch1_phase_2_has_three_safe_zones")
	boss.health = 20
	boss.check_phase()
	t.call(boss.phase, 3, "ch1_boss_enters_phase_3")
	t.call(boss.is_storm_active(), false, "ch1_phase_3_stops_storm")
	t.call(boss.get_safe_zone_count(), 0, "ch1_phase_3_clears_zones")
	boss.attack_cycle = 1
	boss._process(0.01)
	t.call(boss.health, 20, "ch1_phase_3_process_survives")
	_despawn(tree, parent)


func _test_seal_and_mirror(t: Callable) -> void:
	var spawned := _spawn()
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: InkArchivistCh1 = spawned[2]
	var dummy := DummyTarget.new()
	parent.add_child(dummy)
	boss.target = dummy
	boss.attack_cycle = 2
	t.call(boss._seal_phrase_slot(), 0, "ch1_phase_3_seals_slot")
	t.call(dummy.sealed_slot, 0, "ch1_phase_3_seal_reaches_player")
	t.call(dummy.sealed_duration, 4.0, "ch1_phase_3_seal_duration")

	var ranged := RangedWeapon.new()
	ranged.data = load("res://resources/weapons/ink_bolt_gun.tres") as WeaponData
	dummy.weapons = [ranged]
	t.call(boss._target_weapon_kind(), &"ranged", "ch1_mirror_reads_ranged")
	var melee := MeleeWeapon.new()
	melee.data = load("res://resources/weapons/broken_page_sword.tres") as WeaponData
	dummy.weapons = [melee]
	t.call(boss._target_weapon_kind(), &"melee", "ch1_mirror_reads_melee")

	var before := parent.get_child_count()
	boss._fire_mirror(&"melee")
	t.call(parent.get_child_count() > before, true, "ch1_mirror_melee_spawns_shockwave")
	boss._fire_mirror(&"ranged")
	t.call(parent.get_child_count() > before + 1, true, "ch1_mirror_ranged_spawns_fan")
	ranged.free()
	melee.free()
	_despawn(tree, parent)


func _test_death(t: Callable) -> void:
	var spawned := _spawn()
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: InkArchivistCh1 = spawned[2]
	var died := [false]
	boss.died.connect(func(_enemy: Enemy): died[0] = true)
	boss.max_health = 100
	boss.health = 10
	boss.destroy_on_death = false
	boss.take_damage(999)
	t.call(boss.dead, true, "ch1_boss_dies")
	t.call(died[0], true, "ch1_boss_emits_died")
	t.call(boss.is_storm_active(), false, "ch1_boss_death_stops_storm")
	_despawn(tree, parent)
