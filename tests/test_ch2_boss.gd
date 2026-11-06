extends RefCounted

## Chapter 2 boss (肺钟守卫): the chapter plan owns its scene, the generic boss
## flow is reused, and the unique breath/pendulum/nail mechanics are authored
## only on this subclass. Chapter 1's InkArchivistCh1 stays untouched.

const PLAN_PATH := "res://resources/chapters/chapter_2_demo.tres"
const CH1_PLAN_PATH := "res://resources/chapters/chapter_1_demo.tres"
const SCENE_PATH := "res://scenes/bosses/lung_bell_guardian.tscn"
const CH1_SCENE_PATH := "res://scenes/bosses/ink_archivist_ch1.tscn"


class DummyTarget extends Node2D:
	var damage_taken := 0
	var hits := 0

	func take_damage(amount: int, _source: Vector2 = Vector2.INF) -> void:
		damage_taken += amount
		hits += 1


func run(t: Callable) -> void:
	_test_plan_routing(t)
	_test_breath_cycle(t)
	_test_attacks(t)
	_test_nail_window(t)
	_test_chapter_one_isolated(t)
	_test_death_clears_waves(t)


func _spawn() -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	var parent := Node2D.new()
	tree.root.add_child(parent)
	var boss := (load(SCENE_PATH) as PackedScene).instantiate() as LungBellGuardian
	parent.add_child(boss)
	var data := EnemyData.new()
	data.id = &"lung_bell_guardian"
	data.max_health = 360
	data.contact_damage = 14
	data.speed = 75.0
	boss.data = data
	return [tree, parent, boss]


func _despawn(tree: SceneTree, parent: Node2D) -> void:
	tree.root.remove_child(parent)
	parent.free()


func _test_plan_routing(t: Callable) -> void:
	var plan := load(PLAN_PATH) as ChapterPlanData
	t.call(plan != null, true, "ch2_boss_plan_loads")
	if plan != null:
		t.call(plan.boss_scene != null, true, "ch2_plan_owns_boss_scene")
		if plan.boss_scene != null:
			t.call(plan.boss_scene.resource_path, SCENE_PATH,
				"ch2_plan_boss_scene_path")
	# The campaign table keeps its data-only boss fields; the plan alone routes
	# the unique scene, so no Chapter 1 branch can pick it up.
	var chapter := CampaignData.chapter(1)
	t.call(chapter.get("boss_scene", null) == null, true,
		"ch2_campaign_has_no_boss_scene")
	t.call(int(chapter.get("boss_hp", 0)), 360, "ch2_boss_hp")
	t.call(int(chapter.get("boss_damage", 0)), 14, "ch2_boss_damage")
	t.call(float(chapter.get("boss_speed", 0.0)), 75.0, "ch2_boss_speed")

	var scene := load(SCENE_PATH) as PackedScene
	t.call(scene != null, true, "ch2_boss_scene_loads")
	if scene != null:
		var boss := scene.instantiate()
		t.call(boss is LungBellGuardian, true, "ch2_boss_scene_uses_lung_guardian")
		t.call(boss is InkArchivist, true, "ch2_boss_reuses_ink_archivist_flow")
		t.call(boss is InkArchivistCh1, false, "ch2_boss_is_not_chapter_1_boss")
		boss.free()

	var ch1_chapter := CampaignData.chapter(0)
	t.call(String(ch1_chapter.get("boss_scene", null).resource_path), CH1_SCENE_PATH,
		"ch1_campaign_boss_scene_unchanged")
	var ch1_plan := load(CH1_PLAN_PATH) as ChapterPlanData
	t.call(ch1_plan != null and ch1_plan.boss_scene != null
		and ch1_plan.boss_scene.resource_path == CH1_SCENE_PATH, true,
		"ch1_plan_boss_scene_unchanged")


func _test_breath_cycle(t: Callable) -> void:
	var spawned := _spawn()
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: LungBellGuardian = spawned[2]
	boss.max_health = 100
	boss.health = 100
	boss.phase = 1
	t.call(boss.is_inhaling(), true, "ch2_boss_starts_inhaling")
	t.call(boss.damage_multiplier(), LungBellGuardian.INHALE_DAMAGE_MULT,
		"ch2_boss_inhale_halves_damage")

	boss.health = 100
	boss.take_damage(10)
	t.call(boss.health, 95, "ch2_boss_inhale_reduces_damage")

	boss.health = 100
	boss.breath = LungBellGuardian.Breath.EXHALE
	boss.take_damage(10)
	t.call(boss.health, 85, "ch2_boss_exhale_increases_damage")
	t.call(boss.damage_multiplier(), LungBellGuardian.EXHALE_DAMAGE_MULT,
		"ch2_boss_exhale_multiplier")

	boss.breath = LungBellGuardian.Breath.INHALE
	boss.breath_left = 0.01
	boss._process(0.02)
	t.call(boss.is_inhaling(), false, "ch2_boss_breath_flips_to_exhale")
	t.call(boss.get_breath_wave_count(), 1, "ch2_boss_exhale_spawns_wave")
	t.call(boss.damage_multiplier(), LungBellGuardian.EXHALE_DAMAGE_MULT,
		"ch2_boss_exhale_window_after_tick")

	boss.breath_left = 0.01
	boss._process(0.02)
	t.call(boss.is_inhaling(), true, "ch2_boss_breath_flips_back")
	t.call(boss.damage_multiplier(), LungBellGuardian.INHALE_DAMAGE_MULT,
		"ch2_boss_inhale_window_after_tick")

	# Phase 2 enters on the inhale beat and breathes faster, not on a new table.
	boss.health = 60
	boss.check_phase()
	t.call(boss.phase, 2, "ch2_boss_enters_phase_2")
	t.call(boss.is_inhaling(), true, "ch2_boss_phase_2_starts_on_inhale")
	t.call(boss.is_nail_open(), false, "ch2_nail_stays_closed_before_phase_3")

	# The exhale wave owns the authored reach and damage; the real player hit is
	# driven by the in-tree integration suite.
	var wave = boss._breath_waves[0]
	t.call(wave.max_radius, LungBellGuardian.BREATH_WAVE_RADIUS,
		"ch2_breath_wave_reach")
	t.call(wave.damage,
		maxi(int(round(float(boss.get_attack_damage())
			* LungBellGuardian.BREATH_WAVE_DAMAGE_SCALE)), 1),
		"ch2_breath_wave_damage")
	_despawn(tree, parent)


func _test_attacks(t: Callable) -> void:
	var spawned := _spawn()
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: LungBellGuardian = spawned[2]
	var dummy := DummyTarget.new()
	parent.add_child(dummy)
	dummy.global_position = boss.global_position + Vector2(200, 0)
	boss.target = dummy

	boss.phase = 1
	boss.attack_cycle = 0
	var bolts_before := _count_type(parent, "HostileBolt")
	boss._perform_attack()
	var bolts := _children_of_type(parent, "HostileBolt")
	t.call(bolts.size(), bolts_before + 2, "ch2_pendulum_sweep_spawns_two_bolts")
	var forward := false
	var backward := false
	for bolt in bolts:
		if bolt.direction.x > 0.0:
			forward = true
		elif bolt.direction.x < 0.0:
			backward = true
	t.call(forward and backward, true, "ch2_pendulum_sweeps_both_directions")

	boss.attack_cycle = 1
	boss._perform_attack()
	var bombs := _children_of_type(parent, "InkBomb")
	t.call(bombs.size(), 1, "ch2_breath_bomb_spawns")
	if bombs.size() == 1:
		t.call(bombs[0].leaves_pool, true, "ch2_breath_bomb_leaves_pool")

	boss.phase = 2
	boss.attack_cycle = 2
	var waves_before := boss.get_breath_wave_count()
	boss._perform_attack()
	t.call(boss.get_breath_wave_count(), waves_before + 1, "ch2_bell_toll_spawns_wave")
	if boss.get_breath_wave_count() > waves_before:
		var toll = boss._breath_waves[boss._breath_waves.size() - 1]
		t.call(toll.max_radius, LungBellGuardian.BELL_RADIUS, "ch2_bell_toll_reach")

	dummy.queue_free()
	_despawn(tree, parent)


func _test_nail_window(t: Callable) -> void:
	var spawned := _spawn()
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: LungBellGuardian = spawned[2]
	boss.max_health = 100
	boss.health = 20
	boss.phase = 2
	boss.check_phase()
	t.call(boss.phase, 3, "ch2_boss_enters_phase_3")
	t.call(boss.is_nail_open(), true, "ch2_nail_opens_on_phase_3")
	t.call(boss.damage_multiplier(), LungBellGuardian.NAIL_DAMAGE_MULT,
		"ch2_nail_open_window")
	# Keep health inside the phase-3 band while comparing the two windows, so
	# the base threshold check cannot walk the phase back in this fixture.
	boss.health = 34
	boss.take_damage(10)
	t.call(boss.health, 19, "ch2_nail_open_increases_damage")

	boss._process(LungBellGuardian.NAIL_EXPOSED_TIME)
	t.call(boss.is_nail_open(), false, "ch2_nail_closes_after_window")
	t.call(boss.damage_multiplier(), LungBellGuardian.NAIL_ARMOR_MULT,
		"ch2_nail_closed_window")
	boss.health = 34
	boss.take_damage(10)
	t.call(boss.health, 28, "ch2_nail_closed_reduces_damage")

	boss._process(LungBellGuardian.NAIL_CYCLE - LungBellGuardian.NAIL_EXPOSED_TIME)
	t.call(boss.is_nail_open(), true, "ch2_nail_reopens")
	_despawn(tree, parent)


func _test_chapter_one_isolated(t: Callable) -> void:
	var created := load(CH1_SCENE_PATH) as PackedScene
	t.call(created != null, true, "ch1_boss_scene_still_loads")
	if created == null:
		return
	var ch1 := created.instantiate() as InkArchivist
	t.call(ch1 is InkArchivistCh1, true, "ch1_boss_scene_still_ch1")
	if ch1 == null:
		return
	t.call(ch1 is LungBellGuardian, false, "ch1_boss_is_not_lung_guardian")
	t.call(ch1.has_method("damage_multiplier"), false, "ch1_boss_has_no_breath_multiplier")
	t.call(ch1.has_method("is_nail_open"), false, "ch1_boss_has_no_nail_window")
	ch1.free()


func _test_death_clears_waves(t: Callable) -> void:
	var spawned := _spawn()
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: LungBellGuardian = spawned[2]
	boss.max_health = 100
	boss.health = 10
	boss.destroy_on_death = false
	boss.breath = LungBellGuardian.Breath.INHALE
	boss.breath_left = 0.01
	boss._process(0.02)
	t.call(boss.get_breath_wave_count(), 1, "ch2_death_test_wave_spawned")
	var wave = boss._breath_waves[0]
	boss.take_damage(999)
	t.call(boss.dead, true, "ch2_boss_dies")
	t.call(is_instance_valid(wave), false, "ch2_boss_death_clears_waves")
	t.call(boss.is_nail_open(), false, "ch2_boss_death_closes_nail")
	_despawn(tree, parent)


func _children_of_type(parent: Node, type_name: String) -> Array:
	var out: Array = []
	for child in parent.get_children():
		if child.get_script() == null:
			continue
		var script_path := (child.get_script() as Script).resource_path
		if script_path.get_file().get_basename() == type_name.to_snake_case():
			out.append(child)
	return out


func _count_type(parent: Node, type_name: String) -> int:
	return _children_of_type(parent, type_name).size()
