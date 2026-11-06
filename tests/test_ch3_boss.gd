extends RefCounted

## Chapter 3 boss (最后的读者): the chapter plan owns its scene, the generic
## boss flow is reused, and the mirror barrage / read-page seal / blank-page
## burst window are authored only on this subclass. Chapters 1–2 stay untouched,
## and the plan is still not routed into game.gd (slot 2 stays empty).

const PLAN_PATH := "res://resources/chapters/chapter_3_demo.tres"
const SCENE_PATH := "res://scenes/bosses/last_reader.tscn"
const CH1_PLAN_PATH := "res://resources/chapters/chapter_1_demo.tres"
const CH2_PLAN_PATH := "res://resources/chapters/chapter_2_demo.tres"
const CH1_SCENE_PATH := "res://scenes/bosses/ink_archivist_ch1.tscn"
const CH2_SCENE_PATH := "res://scenes/bosses/lung_bell_guardian.tscn"
const GAME_SCRIPT_PATH := "res://scripts/game.gd"


class DummyTarget extends Node2D:
	var damage_taken := 0
	var sealed_slot := -1
	var sealed_duration := -1.0

	func take_damage(amount: int, _source: Vector2 = Vector2.INF) -> void:
		damage_taken += amount

	func disable_phrase_slot(slot: int, duration: float = 3.0) -> bool:
		sealed_slot = slot
		sealed_duration = duration
		return true


func run(t: Callable) -> void:
	_test_plan_and_scene(t)
	_test_campaign_data(t)
	_test_mirror_fan(t)
	_test_read_page(t)
	_test_phase_rotation(t)
	_test_blank_page_window(t)
	_test_spawn_height(t)
	_test_death_closes_blank_page(t)
	_test_other_chapters_isolated(t)


func _spawn() -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	var parent := Node2D.new()
	tree.root.add_child(parent)
	var boss := (load(SCENE_PATH) as PackedScene).instantiate() as LastReader
	parent.add_child(boss)
	var data := EnemyData.new()
	data.id = &"last_reader"
	data.max_health = 380
	data.contact_damage = 15
	data.speed = 78.0
	boss.data = data
	var dummy := DummyTarget.new()
	parent.add_child(dummy)
	dummy.global_position = boss.global_position + Vector2(200, 0)
	boss.target = dummy
	return [tree, parent, boss, dummy]


func _despawn(tree: SceneTree, parent: Node2D) -> void:
	tree.root.remove_child(parent)
	parent.free()


func _test_plan_and_scene(t: Callable) -> void:
	var plan := load(PLAN_PATH) as ChapterPlanData
	t.call(plan != null, true, "ch3_boss_plan_loads")
	if plan != null:
		t.call(plan.boss_scene != null, true, "ch3_plan_owns_boss_scene")
		if plan.boss_scene != null:
			t.call(plan.boss_scene.resource_path, SCENE_PATH, "ch3_plan_boss_scene_path")
		t.call(String(plan.room("ch3_boss").get("note", "")).contains("boss_scene"), true,
			"ch3_boss_region_note_mentions_routing")

	var scene := load(SCENE_PATH) as PackedScene
	t.call(scene != null, true, "ch3_boss_scene_loads")
	if scene != null:
		var boss := scene.instantiate()
		t.call(boss is LastReader, true, "ch3_boss_scene_uses_last_reader")
		t.call(boss is InkArchivist, true, "ch3_boss_reuses_ink_archivist_flow")
		t.call(boss is InkArchivistCh1, false, "ch3_boss_is_not_chapter_1_boss")
		t.call(boss is LungBellGuardian, false, "ch3_boss_is_not_chapter_2_boss")
		boss.free()


## The campaign table keeps its data-only boss fields; the plan alone routes the
## unique scene, so no Chapter 1/2 branch can pick it up.
func _test_campaign_data(t: Callable) -> void:
	var chapter := CampaignData.chapter(2)
	t.call(String(chapter.get("id", "")), "lightless_sea", "ch3_boss_campaign_id")
	t.call(String(chapter.get("boss_name", "")), "最后的读者", "ch3_boss_name")
	t.call(int(chapter.get("boss_hp", 0)), 380, "ch3_boss_hp_unchanged")
	t.call(int(chapter.get("boss_damage", 0)), 15, "ch3_boss_damage_unchanged")
	t.call(float(chapter.get("boss_speed", 0.0)), 78.0, "ch3_boss_speed_unchanged")
	t.call(String(chapter.get("boss_script", "")) == "reader", true,
		"ch3_boss_script_unchanged")
	t.call(ResourceLoader.exists(String(chapter.get("boss_texture", ""))), true,
		"ch3_boss_texture_exists")
	t.call(String(chapter.get("boss_texture", "")),
		"res://assets/sprites/bosses/last_reader.png", "ch3_boss_texture_unchanged")
	t.call(chapter.get("boss_scene", null) == null, true,
		"ch3_campaign_has_no_boss_scene")

	var ch1_chapter := CampaignData.chapter(0)
	t.call(String(ch1_chapter.get("boss_scene", null).resource_path), CH1_SCENE_PATH,
		"ch1_campaign_boss_scene_unchanged")
	var ch1_plan := load(CH1_PLAN_PATH) as ChapterPlanData
	t.call(ch1_plan != null and ch1_plan.boss_scene != null
		and ch1_plan.boss_scene.resource_path == CH1_SCENE_PATH, true,
		"ch1_plan_boss_scene_unchanged")
	var ch2_plan := load(CH2_PLAN_PATH) as ChapterPlanData
	t.call(ch2_plan != null and ch2_plan.boss_scene != null
		and ch2_plan.boss_scene.resource_path == CH2_SCENE_PATH, true,
		"ch2_plan_boss_scene_unchanged")


func _test_mirror_fan(t: Callable) -> void:
	var spawned := _spawn()
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: LastReader = spawned[2]
	var damage := maxi(int(15 * LastReader.MIRROR_BOLT_DAMAGE_SCALE), 1)

	for phase in [1, 2, 3]:
		boss.phase = phase
		# Cycle 1 + the ++ in _perform_attack lands on 2: the even beat is the
		# mirror fan in phases 1–2; phase 3's 2 % 4 beat is the fan as well.
		boss.attack_cycle = 1
		var before := _children_of_type(parent, "HostileBolt").size()
		boss._perform_attack()
		var bolts := _children_of_type(parent, "HostileBolt")
		var expected: int = LastReader.MIRROR_BOLTS_PER_PHASE[phase - 1]
		t.call(bolts.size() - before, expected, "ch3_mirror_fan_count_phase_%d" % phase)
		var headings: Dictionary = {}
		for index in range(before, bolts.size()):
			headings[snappedf((bolts[index] as HostileBolt).direction.angle(), 0.001)] = true
			t.call((bolts[index] as HostileBolt).damage, damage,
				"ch3_mirror_fan_damage_phase_%d" % phase)
		t.call(headings.size(), expected, "ch3_mirror_fan_spread_phase_%d" % phase)
		t.call(is_equal_approx(boss.get_mirror_spread(),
			LastReader.MIRROR_SPREAD_PER_PHASE[phase - 1]), true,
			"ch3_mirror_spread_phase_%d" % phase)
	_despawn(tree, parent)


func _test_read_page(t: Callable) -> void:
	var spawned := _spawn()
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: LastReader = spawned[2]
	var dummy: DummyTarget = spawned[3]
	boss.phase = 2
	boss.attack_cycle = 2
	var warnings_before := _children_of_type(parent, "InkWarning").size()
	boss._perform_attack()
	t.call(dummy.sealed_slot, 1, "ch3_read_page_seals_alternating_slot")
	t.call(dummy.sealed_duration, LastReader.READ_PAGE_SEAL_TIME,
		"ch3_read_page_seal_duration")
	t.call(boss.last_sealed_slot, 1, "ch3_read_page_reports_sealed_slot")
	var warnings := _children_of_type(parent, "InkWarning")
	t.call(warnings.size() - warnings_before, 1, "ch3_read_page_warns_once")
	if warnings.size() > warnings_before:
		t.call((warnings[warnings.size() - 1] as InkWarning).damage,
			maxi(int(15 * LastReader.READ_PAGE_DAMAGE_SCALE), 1),
			"ch3_read_page_warning_damage")
	_despawn(tree, parent)


func _test_phase_rotation(t: Callable) -> void:
	var spawned := _spawn()
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: LastReader = spawned[2]
	var dummy: DummyTarget = spawned[3]

	# Phase 1 alternates the inherited page wave (odd) with the mirror fan
	# (even). The page wave itself only spawns inside the tree, so the unit
	# fixture checks that the odd beat does not fire the owned fan; the live
	# page wave is asserted by the playability integration.
	boss.phase = 1
	boss.attack_cycle = 0
	var before := _children_of_type(parent, "HostileBolt").size()
	boss._perform_attack()
	t.call(boss.attack_cycle, 1, "ch3_phase_1_cycle_advances")
	t.call(_children_of_type(parent, "HostileBolt").size() - before, 0,
		"ch3_phase_1_odd_beat_is_not_the_mirror_fan")
	boss.attack_cycle = 1
	before = _children_of_type(parent, "HostileBolt").size()
	boss._perform_attack()
	t.call(_children_of_type(parent, "HostileBolt").size() - before,
		LastReader.MIRROR_BOLTS_PER_PHASE[0], "ch3_phase_1_even_beat_is_mirror_fan")

	# Phase 2 adds the read-page seal on every third beat.
	boss.phase = 2
	boss.attack_cycle = 2
	dummy.sealed_slot = -1
	boss._perform_attack()
	t.call(dummy.sealed_slot, 1, "ch3_phase_2_third_beat_reads_page")

	# Phase 3 keeps its four-beat rotation. _perform_attack bumps the cycle
	# before the match, so cycle 4 is the rewrite beat (0), 5 the read beat
	# (1), 6 the mirror beat (2) and 7 the ink-rain beat (3).
	boss.phase = 3
	boss.attack_cycle = 3
	dummy.sealed_slot = -1
	boss._perform_attack()
	t.call(dummy.sealed_slot, 0, "ch3_phase_3_rewrite_seals_a_slot")
	boss.attack_cycle = 0
	dummy.sealed_slot = -1
	var warnings_before := _children_of_type(parent, "InkWarning").size()
	boss._perform_attack()
	t.call(dummy.sealed_slot, 1, "ch3_phase_3_read_page_seals_the_other_slot")
	t.call(_children_of_type(parent, "InkWarning").size() - warnings_before, 1,
		"ch3_phase_3_read_page_warns")
	boss.attack_cycle = 1
	before = _children_of_type(parent, "HostileBolt").size()
	boss._perform_attack()
	t.call(_children_of_type(parent, "HostileBolt").size() - before,
		LastReader.MIRROR_BOLTS_PER_PHASE[2], "ch3_phase_3_mirror_beat")
	# The ink-rain beat is inherited and only spawns inside the tree; here the
	# observable proof is that it is neither the fan nor a seal. The live ink
	# rain is asserted by the playability integration.
	boss.attack_cycle = 2
	before = _children_of_type(parent, "HostileBolt").size()
	dummy.sealed_slot = -1
	boss._perform_attack()
	t.call(boss.attack_cycle, 3, "ch3_phase_3_ink_rain_cycle")
	t.call(_children_of_type(parent, "HostileBolt").size() - before, 0,
		"ch3_phase_3_ink_rain_is_not_the_mirror_fan")
	t.call(dummy.sealed_slot, -1, "ch3_phase_3_ink_rain_is_not_a_seal")
	_despawn(tree, parent)


func _test_blank_page_window(t: Callable) -> void:
	var spawned := _spawn()
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: LastReader = spawned[2]
	var states: Array = []
	boss.blank_page_changed.connect(func(exposed: bool): states.append(exposed))
	boss.max_health = 100
	boss.health = 100
	boss.phase = 1
	t.call(boss.is_blank_page_open(), false, "ch3_blank_page_starts_closed")
	t.call(boss.damage_multiplier(), 1.0, "ch3_no_damage_window_before_phase_3")

	# Damage during the exposure window is amplified; the same hit while the
	# book is closed is reduced. Both windows stay inside the phase-3 band.
	boss.health = 32
	boss.check_phase()
	t.call(boss.phase, 3, "ch3_boss_enters_phase_3")
	t.call(boss.is_blank_page_open(), true, "ch3_blank_page_opens_on_phase_3")
	t.call(boss.damage_multiplier(), LastReader.BLANK_PAGE_OPEN_MULT,
		"ch3_blank_page_open_multiplier")
	t.call(states, [true], "ch3_blank_page_signal_on_open")
	boss.take_damage(10)
	t.call(boss.health, 17, "ch3_blank_page_open_amplifies_damage")
	t.call(boss.phase, 3, "ch3_blank_page_hit_keeps_phase_3")

	boss._process(LastReader.BLANK_PAGE_OPEN_TIME + 0.01)
	t.call(boss.is_blank_page_open(), false, "ch3_blank_page_closes_after_window")
	t.call(boss.damage_multiplier(), LastReader.BLANK_PAGE_CLOSED_MULT,
		"ch3_blank_page_closed_multiplier")
	t.call(states, [true, false], "ch3_blank_page_signal_on_close")
	boss.take_damage(10)
	t.call(boss.health, 11, "ch3_blank_page_closed_reduces_damage")

	boss._process(LastReader.BLANK_PAGE_CYCLE - LastReader.BLANK_PAGE_OPEN_TIME)
	t.call(boss.is_blank_page_open(), true, "ch3_blank_page_reopens")
	t.call(boss.damage_multiplier(), LastReader.BLANK_PAGE_OPEN_MULT,
		"ch3_blank_page_reopened_multiplier")
	_despawn(tree, parent)


func _test_spawn_height(t: Callable) -> void:
	var plan := load(PLAN_PATH) as ChapterPlanData
	t.call(plan != null and plan.big_map, true, "ch3_spawn_plan_is_big_map")
	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	t.call(game_script != null, true, "ch3_spawn_game_script_loads")
	if game_script == null:
		return
	var game = game_script.new()
	game._chapter_plan = plan
	# Big-map arenas are anchored on the walkable surface; the legacy +250
	# offset would bury the boss underground.
	t.call(is_equal_approx(game._enemy_spawn_y(), -18.0), true,
		"ch3_boss_spawns_above_ground")
	game._chapter_plan = null
	t.call(is_equal_approx(game._enemy_spawn_y(), 250.0), true,
		"legacy_spawn_offset_unchanged")
	# See test_ch3_content: release the PhraseCaster the script owns.
	var caster: PhraseCaster = game.phrase_caster
	game.phrase_caster = null
	caster.free()
	game.free()


func _test_death_closes_blank_page(t: Callable) -> void:
	var spawned := _spawn()
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: LastReader = spawned[2]
	boss.max_health = 100
	boss.health = 10
	boss.phase = 2
	boss.destroy_on_death = false
	boss.check_phase()
	t.call(boss.is_blank_page_open(), true, "ch3_death_test_blank_page_open")
	boss.take_damage(999)
	t.call(boss.dead, true, "ch3_boss_dies")
	t.call(boss.is_blank_page_open(), false, "ch3_boss_death_closes_blank_page")
	_despawn(tree, parent)


func _test_other_chapters_isolated(t: Callable) -> void:
	var ch1 := (load(CH1_SCENE_PATH) as PackedScene).instantiate() as InkArchivist
	t.call(ch1 is InkArchivistCh1, true, "ch1_boss_scene_still_ch1")
	t.call(ch1 is LastReader, false, "ch1_boss_is_not_last_reader")
	t.call(ch1.has_method("is_blank_page_open"), false,
		"ch1_boss_has_no_blank_page_window")
	ch1.free()

	var ch2 := (load(CH2_SCENE_PATH) as PackedScene).instantiate() as InkArchivist
	t.call(ch2 is LungBellGuardian, true, "ch2_boss_scene_still_lung_guardian")
	t.call(ch2 is LastReader, false, "ch2_boss_is_not_last_reader")
	t.call(ch2.has_method("is_blank_page_open"), false,
		"ch2_boss_has_no_blank_page_window")
	ch2.free()

	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	if game_script != null:
		var plan_paths: Array = game_script.get_script_constant_map().get(
			"CHAPTER_PLAN_PATHS", [])
		if plan_paths.size() == 4:
			t.call(plan_paths[2], "", "ch3_boss_pass_keeps_plan_slot_empty")
			t.call(plan_paths[3], "", "ch3_boss_pass_keeps_ch4_plan_slot_empty")


func _children_of_type(parent: Node, type_name: String) -> Array:
	var out: Array = []
	if parent == null:
		return out
	for child in parent.get_children():
		if child.get_script() == null:
			continue
		var script_path := (child.get_script() as Script).resource_path
		if script_path.get_file().get_basename() == type_name.to_snake_case():
			out.append(child)
	return out
