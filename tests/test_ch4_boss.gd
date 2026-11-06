extends RefCounted

## Chapter 4 boss (笑面史官): the chapter plan owns its scene (pass 57), the
## generic boss flow is reused, and the existing SmilingArchivist mechanics are
## locked as-is — phase 1 page wave, phase 2 mirror fan every third beat, phase 3
## rewrite → mirror fan → ink rain → page wave. No dedicated mechanic extension
## (delete-word / copy-weapon / stage traps) lands here, Chapters 1–3 keep their
## routes, and the plan is still not routed into game.gd (slot 3 stays empty).
##
## The unit-loop nodes are not inside the SceneTree yet (the runner asserts in
## `_initialize`), and SmilingArchivist's mirror fan / ink rain only spawn while
## in-tree. The beat table is therefore locked with a recording subclass, the
## page-wave damage and rewrite seal against the real script, and the spawned
## bolt/warning numbers on the live boss in integration_playability.

const PLAN_PATH := "res://resources/chapters/chapter_4_demo.tres"
const SCENE_PATH := "res://scenes/bosses/smiling_archivist.tscn"
const CH1_PLAN_PATH := "res://resources/chapters/chapter_1_demo.tres"
const CH2_PLAN_PATH := "res://resources/chapters/chapter_2_demo.tres"
const CH3_PLAN_PATH := "res://resources/chapters/chapter_3_demo.tres"
const CH1_SCENE_PATH := "res://scenes/bosses/ink_archivist_ch1.tscn"
const CH2_SCENE_PATH := "res://scenes/bosses/lung_bell_guardian.tscn"
const CH3_SCENE_PATH := "res://scenes/bosses/last_reader.tscn"
const GAME_SCRIPT_PATH := "res://scripts/game.gd"

## Chapter 4 campaign stats and the inherited rewrite seal window.
const BOSS_HP := 520
const BOSS_DAMAGE := 18
const BOSS_SPEED := 92.0
const REWRITE_SEAL_DURATION := 3.0


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


## Records which beat `_perform_attack` picks without needing to be in-tree.
class TrackingSmiling extends SmilingArchivist:
	var beats: Array[String] = []

	func _page_wave() -> void:
		beats.append("page")

	func _mirror_fan() -> void:
		beats.append("mirror")

	func _ink_rain() -> void:
		beats.append("rain")

	func _rewrite() -> void:
		beats.append("rewrite")


func run(t: Callable) -> void:
	_test_plan_and_scene(t)
	_test_campaign_data(t)
	_test_phase_mapping(t)
	_test_real_page_wave_and_rewrite(t)
	_test_spawn_height(t)
	_test_boss_copy_tables(t)
	_test_other_chapters_isolated(t)
	_test_routing_locked(t)


func _spawn(scene_script: Script = null) -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	var parent := Node2D.new()
	tree.root.add_child(parent)
	var boss: SmilingArchivist
	if scene_script != null:
		boss = scene_script.new() as SmilingArchivist
	else:
		boss = (load(SCENE_PATH) as PackedScene).instantiate() as SmilingArchivist
	parent.add_child(boss)
	var data := EnemyData.new()
	data.id = &"smiling_archivist"
	data.max_health = BOSS_HP
	data.contact_damage = BOSS_DAMAGE
	data.speed = BOSS_SPEED
	boss.data = data
	boss.attack_range = 200.0
	var dummy := DummyTarget.new()
	parent.add_child(dummy)
	dummy.global_position = boss.global_position + Vector2(220, 0)
	boss.target = dummy
	return [tree, parent, boss, dummy]


func _despawn(tree: SceneTree, parent: Node2D) -> void:
	tree.root.remove_child(parent)
	parent.free()


func _test_plan_and_scene(t: Callable) -> void:
	var plan := load(PLAN_PATH) as ChapterPlanData
	t.call(plan != null, true, "ch4_boss_plan_loads")
	if plan != null:
		t.call(plan.big_map, true, "ch4_boss_plan_is_big_map")
		t.call(plan.boss_scene != null, true, "ch4_plan_owns_boss_scene")
		if plan.boss_scene != null:
			t.call(plan.boss_scene.resource_path, SCENE_PATH, "ch4_plan_boss_scene_path")
		t.call(String(plan.room("ch4_boss").get("note", "")).contains("boss_scene"), true,
			"ch4_boss_region_note_mentions_routing")

	var scene := load(SCENE_PATH) as PackedScene
	t.call(scene != null, true, "ch4_boss_scene_loads")
	if scene != null:
		var boss := scene.instantiate() as InkArchivist
		t.call(boss is SmilingArchivist, true, "ch4_boss_scene_uses_smiling_archivist")
		t.call(boss is InkArchivist, true, "ch4_boss_reuses_ink_archivist_flow")
		t.call(boss is InkArchivistCh1, false, "ch4_boss_is_not_chapter_1_boss")
		t.call(boss is LungBellGuardian, false, "ch4_boss_is_not_chapter_2_boss")
		t.call(boss is LastReader, false, "ch4_boss_is_not_chapter_3_boss")
		t.call(boss.has_method("is_blank_page_open"), false,
			"ch4_boss_has_no_chapter_3_blank_page_window")
		boss.free()


## The campaign table keeps its data-only boss fields; the plan alone routes the
## scene, so no Chapter 1/2/3 branch can pick it up.
func _test_campaign_data(t: Callable) -> void:
	var chapter := CampaignData.chapter(3)
	t.call(String(chapter.get("id", "")), "smiling_theater", "ch4_boss_campaign_id")
	t.call(String(chapter.get("boss_name", "")), "笑面史官", "ch4_boss_name")
	t.call(int(chapter.get("boss_hp", 0)), BOSS_HP, "ch4_boss_hp_unchanged")
	t.call(int(chapter.get("boss_damage", 0)), BOSS_DAMAGE, "ch4_boss_damage_unchanged")
	t.call(float(chapter.get("boss_speed", 0.0)), BOSS_SPEED, "ch4_boss_speed_unchanged")
	t.call(String(chapter.get("boss_script", "")) == "smiling", true,
		"ch4_boss_script_unchanged")
	t.call(ResourceLoader.exists(String(chapter.get("boss_texture", ""))), true,
		"ch4_boss_texture_exists")
	t.call(String(chapter.get("boss_texture", "")),
		"res://assets/sprites/bosses/smiling_archivist.png", "ch4_boss_texture_unchanged")
	t.call(chapter.has("boss_scene"), false, "ch4_campaign_has_no_boss_scene")

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
	var ch3_plan := load(CH3_PLAN_PATH) as ChapterPlanData
	t.call(ch3_plan != null and ch3_plan.boss_scene != null
		and ch3_plan.boss_scene.resource_path == CH3_SCENE_PATH, true,
		"ch3_plan_boss_scene_unchanged")


## SmilingArchivist's full beat table, one lap per phase. `_perform_attack` bumps
## the cycle before the match, so the cycles below are the post-bump values.
func _test_phase_mapping(t: Callable) -> void:
	var spawned := _spawn(TrackingSmiling)
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: TrackingSmiling = spawned[2]

	boss.phase = 1
	boss.attack_cycle = 0
	for _beat in 3:
		boss._perform_attack()
	t.call(boss.beats, ["page", "page", "page"], "ch4_phase_1_is_all_page_wave")

	boss.phase = 2
	boss.attack_cycle = 0
	boss.beats.clear()
	for _beat in 6:
		boss._perform_attack()
	t.call(boss.beats, ["page", "page", "mirror", "page", "page", "mirror"],
		"ch4_phase_2_fans_every_third_beat")

	boss.phase = 3
	boss.attack_cycle = 0
	boss.beats.clear()
	for _beat in 8:
		boss._perform_attack()
	t.call(boss.beats,
		["mirror", "rain", "page", "rewrite", "mirror", "rain", "page", "rewrite"],
		"ch4_phase_3_four_beat_rotation")
	_despawn(tree, parent)


## The inherited page wave deals the contact damage out-of-tree, and the rewrite
## beat seals the first phrase slot (a multiple of four is always even).
func _test_real_page_wave_and_rewrite(t: Callable) -> void:
	var spawned := _spawn()
	var tree: SceneTree = spawned[0]
	var parent: Node2D = spawned[1]
	var boss: SmilingArchivist = spawned[2]
	var dummy: DummyTarget = spawned[3]

	boss.phase = 1
	boss.attack_cycle = 0
	boss._perform_attack()
	t.call(dummy.damage_taken, BOSS_DAMAGE, "ch4_page_wave_deals_contact_damage")
	boss.phase = 2
	boss.attack_cycle = 0
	boss._perform_attack()
	t.call(dummy.damage_taken, BOSS_DAMAGE * 2,
		"ch4_page_wave_damage_unchanged_in_phase_2")

	boss.phase = 3
	boss.attack_cycle = 3
	dummy.sealed_slot = -1
	dummy.sealed_duration = -1.0
	boss._perform_attack()
	t.call(dummy.sealed_slot, 0, "ch4_phase_3_rewrite_seals_slot_zero")
	t.call(dummy.sealed_duration, REWRITE_SEAL_DURATION,
		"ch4_phase_3_rewrite_seal_duration")
	boss.attack_cycle = 7
	dummy.sealed_slot = -1
	boss._perform_attack()
	t.call(dummy.sealed_slot, 0, "ch4_phase_3_rewrite_slot_stays_zero")
	_despawn(tree, parent)


func _test_spawn_height(t: Callable) -> void:
	var plan := load(PLAN_PATH) as ChapterPlanData
	t.call(plan != null and plan.big_map, true, "ch4_spawn_plan_is_big_map")
	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	t.call(game_script != null, true, "ch4_spawn_game_script_loads")
	if game_script == null:
		return
	var game = game_script.new()
	game._chapter_plan = plan
	# Big-map arenas are anchored on the walkable surface; the legacy +250
	# offset would bury the boss underground.
	t.call(is_equal_approx(game._enemy_spawn_y(), -18.0), true,
		"ch4_boss_spawns_above_ground")
	game._chapter_plan = null
	t.call(is_equal_approx(game._enemy_spawn_y(), 250.0), true,
		"legacy_spawn_offset_unchanged")
	# See test_ch3_content: release the PhraseCaster the script owns.
	var caster: PhraseCaster = game.phrase_caster
	game.phrase_caster = null
	caster.free()
	game.free()


## Entrance/phase copy selects on the chapter index key, so Chapter 4 never
## falls back to the Chapter 1/2/3 tables, and phase 1/out-of-range stay silent.
func _test_boss_copy_tables(t: Callable) -> void:
	var entrance_lines := BossEntranceData.variants(3)
	t.call(entrance_lines.size() >= 8, true, "ch4_boss_entrance_copy_authored")
	var entrance := BossEntranceData.pick(4242, 3)
	t.call(entrance != "", true, "ch4_boss_entrance_pick_non_empty")
	t.call(entrance_lines.has(entrance), true, "ch4_boss_entrance_pick_authored_line")
	for chapter_index in 3:
		t.call(entrance != BossEntranceData.pick(4242, chapter_index), true,
			"ch4_boss_entrance_not_chapter_%d" % (chapter_index + 1))

	for phase in [2, 3]:
		var lines := BossPhaseData.variants(phase, 3)
		t.call(lines.size() >= 8, true, "ch4_boss_phase_%d_copy_authored" % phase)
		var flavor := BossPhaseData.pick(4242, phase, 3)
		t.call(flavor != "", true, "ch4_boss_phase_%d_pick_non_empty" % phase)
		t.call(lines.has(flavor), true,
			"ch4_boss_phase_%d_pick_authored_line" % phase)
		for chapter_index in 3:
			t.call(flavor != BossPhaseData.pick(4242, phase, chapter_index), true,
				"ch4_boss_phase_%d_not_chapter_%d" % [phase, chapter_index + 1])
	t.call(BossPhaseData.variants(1, 3).is_empty(), true,
		"ch4_boss_phase_1_has_no_flavor")
	t.call(BossPhaseData.variants(2, 4).is_empty(), true,
		"boss_phase_out_of_range_still_silent")


func _test_other_chapters_isolated(t: Callable) -> void:
	var ch1 := (load(CH1_SCENE_PATH) as PackedScene).instantiate() as InkArchivist
	t.call(ch1 is InkArchivistCh1, true, "ch1_boss_scene_still_ch1")
	t.call(ch1 is SmilingArchivist, false, "ch1_boss_is_not_smiling_archivist")
	ch1.free()

	var ch2 := (load(CH2_SCENE_PATH) as PackedScene).instantiate() as InkArchivist
	t.call(ch2 is LungBellGuardian, true, "ch2_boss_scene_still_lung_guardian")
	t.call(ch2 is SmilingArchivist, false, "ch2_boss_is_not_smiling_archivist")
	ch2.free()

	var ch3 := (load(CH3_SCENE_PATH) as PackedScene).instantiate() as InkArchivist
	t.call(ch3 is LastReader, true, "ch3_boss_scene_still_last_reader")
	t.call(ch3 is SmilingArchivist, false, "ch3_boss_is_not_smiling_archivist")
	ch3.free()


## The plan is routed to its boss scene, but the plan itself is still not wired
## into game.gd: slot 3 stays empty, the legacy Chapter 4 world is still used,
## and the plan's clear target/waves/authority pool are unchanged.
func _test_routing_locked(t: Callable) -> void:
	var game_script := load(GAME_SCRIPT_PATH) as GDScript
	t.call(game_script != null, true, "ch4_boss_game_script_loads")
	if game_script != null:
		var constants: Dictionary = game_script.get_script_constant_map()
		var plan_paths: Array = constants.get("CHAPTER_PLAN_PATHS", [])
		var world_files: Array = constants.get("MDS_WORLD_FILES", [])
		if plan_paths.size() == 4:
			t.call(String(plan_paths[3]), "", "ch4_boss_pass_keeps_plan_slot_empty")
			t.call(String(plan_paths[2]), "", "ch3_plan_slot_still_empty")
		if world_files.size() == 4:
			t.call(String(world_files[3]).ends_with("chapter_4.mdsworld.json"), true,
				"ch4_boss_pass_keeps_legacy_world")
			t.call(String(world_files[2]).ends_with("chapter_3.mdsworld.json"), true,
				"ch3_world_unchanged")
	var game_source := FileAccess.get_file_as_string(GAME_SCRIPT_PATH)
	t.call(game_source.contains("chapter_4_bigmap"), false,
		"ch4_region_world_not_routed")
	t.call(game_source.contains("ch4_shortcut"), false,
		"ch4_game_grants_no_shortcut")
	t.call(FileAccess.file_exists("res://scenes/mds/chapter_4.mdsworld.json"), true,
		"ch4_old_world_still_present")
	t.call(FileAccess.file_exists("res://scenes/mds/chapter_4_world.tscn"), true,
		"ch4_old_world_scene_still_present")
	var plan := load(PLAN_PATH) as ChapterPlanData
	if plan != null:
		t.call(plan.clear_target(), 7, "ch4_clear_target_still_seven")
		t.call(plan.encounter_ids().size(), 7, "ch4_encounters_unchanged")
		t.call(plan.content_pending, false, "ch4_waves_still_wired")
		t.call(plan.wave_for("ch4_branch_a", "ch4_branch_a/Arena").size(), 2,
			"ch4_wave_table_unchanged")
		t.call(plan.authority_pool.size(), 2, "ch4_base_authority_pool_unchanged")
		var pool_ids: Array[StringName] = []
		for authority in plan.authority_pool:
			pool_ids.append(authority.id)
		t.call(pool_ids.has(&"revive") and pool_ids.has(&"rewrite"), true,
			"ch4_authority_pool_ids_unchanged")
