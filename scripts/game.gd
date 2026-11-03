extends Node2D

const ENEMY_SCENES: Dictionary = {
	&"ink_hound": preload("res://scenes/enemies/ink_hound.tscn"),
	&"scribe_bug": preload("res://scenes/enemies/scribe_bug.tscn"),
	&"blank_man": preload("res://scenes/enemies/blank_man.tscn"),
	&"hanging_scribe": preload("res://scenes/enemies/hanging_scribe.tscn"),
	&"echo_enemy": preload("res://scenes/enemies/echo_enemy.tscn"),
	&"typo_beast": preload("res://scenes/enemies/typo_beast.tscn"),
	&"breath_hound": preload("res://scenes/enemies/breath_hound.tscn"),
	&"lung_moth": preload("res://scenes/enemies/lung_moth.tscn"),
	&"rust_whisperer": preload("res://scenes/enemies/rust_whisperer.tscn"),
	&"collapse_husk": preload("res://scenes/enemies/collapse_husk.tscn"),
	&"mask_enemy": preload("res://scenes/enemies/hanging_scribe.tscn"),
	&"seat_husk": preload("res://scenes/enemies/collapse_husk.tscn"),
	&"ink_bomber": preload("res://scenes/enemies/ink_bomber.tscn"),
	&"choir_summoner": preload("res://scenes/enemies/choir_summoner.tscn"),
	&"mirror_sniper": preload("res://scenes/enemies/mirror_sniper.tscn"),
	&"page_swarm": preload("res://scenes/enemies/page_swarm.tscn"),
}
const BOSS_SCENE = preload("res://scenes/bosses/ink_archivist.tscn")
const SMILING_SCENE = preload("res://scenes/bosses/smiling_archivist.tscn")
const READER_SCENE = preload("res://scenes/bosses/last_reader.tscn")
const PICKUP_SCENE = preload("res://scenes/combat/pickup.tscn")
const MDS_CHAPTER_SCENES: Array[PackedScene] = [
	preload("res://scenes/mds/chapter_1_world.tscn"),
	preload("res://scenes/mds/chapter_2_world.tscn"),
	preload("res://scenes/mds/chapter_3_world.tscn"),
	preload("res://scenes/mds/chapter_4_world.tscn"),
]
const MDS_WORLD_FILES: Array[String] = [
	"res://scenes/mds/chapter_1.mdsworld.json",
	"res://scenes/mds/chapter_2.mdsworld.json",
	"res://scenes/mds/chapter_3.mdsworld.json",
	"res://scenes/mds/chapter_4.mdsworld.json",
]
## A weapon never vanishes: equipping swaps with the held one and drops it.
const WEAPON_DROP_CHANCE := 0.04
const BOSS_DATA = preload("res://resources/bosses/ink_archivist.tres")
const ENEMY_ART: Dictionary = {
	&"ink_hound": preload("res://assets/sprites/enemies/ink_hound.png"),
	&"scribe_bug": preload("res://assets/sprites/enemies/scribe_bug.png"),
	&"blank_man": preload("res://assets/sprites/enemies/blank_man.png"),
	&"hanging_scribe": preload("res://assets/sprites/enemies/hanging_scribe.png"),
	&"echo_enemy": preload("res://assets/sprites/enemies/echo_enemy.png"),
	&"typo_beast": preload("res://assets/sprites/enemies/typo_beast.png"),
	&"mask_enemy": preload("res://assets/sprites/enemies/mask_enemy.png"),
	&"seat_husk": preload("res://assets/sprites/enemies/seat_husk.png"),
	&"ink_bomber": preload("res://assets/sprites/enemies/ink_bomber.png"),
	&"choir_summoner": preload("res://assets/sprites/enemies/choir_summoner.png"),
	&"mirror_sniper": preload("res://assets/sprites/enemies/mirror_sniper.png"),
	&"page_swarm": preload("res://assets/sprites/enemies/page_swarm.png"),
}
const ENEMY_ART_FALLBACK: Dictionary = {&"breath_hound": &"ink_hound", &"lung_moth": &"hanging_scribe", &"rust_whisperer": &"scribe_bug", &"collapse_husk": &"blank_man"}
const ENEMY_ANIM_STYLE: Dictionary = {
	&"ink_hound": &"beast", &"breath_hound": &"beast", &"scribe_bug": &"beast",
	&"lung_moth": &"flyer", &"hanging_scribe": &"flyer", &"page_swarm": &"flyer",
	&"collapse_husk": &"elite", &"typo_beast": &"elite",
	&"ink_bomber": &"humanoid", &"choir_summoner": &"humanoid", &"mirror_sniper": &"humanoid",
}
## Whole-number display scales only (docs/memory/decisions/2026-11-02-art-spec.md).
## An enemy that must look bigger needs bigger art, not a fractional scale.
const ENEMY_ART_SCALE: Dictionary = {}
const SECOND_WEAPON = preload("res://resources/weapons/ink_bolt_gun.tres")
const AUTHORITY = preload("res://resources/authorities/revive.tres")
const CHAPTER_WIDTH := 12000.0
## Local y of an enemy's feet: the bottom of its collision capsule, on the floor.
const ENEMY_FOOT_Y := 16.0
const ROOM_WAVES: Array = [
	[[&"ink_bomber", &"scribe_bug"], [&"page_swarm", &"ink_hound"], [&"blank_man", &"typo_beast"], [&"ink_bomber", &"ink_hound"], [&"choir_summoner", &"scribe_bug"], [&"typo_beast", &"ink_bomber"]],
	[[&"choir_summoner", &"page_swarm"], [&"rust_whisperer", &"collapse_husk"], [&"lung_moth", &"breath_hound"], [&"ink_bomber", &"blank_man"], [&"breath_hound", &"rust_whisperer"], [&"page_swarm", &"collapse_husk"]],
	[[&"mirror_sniper", &"hanging_scribe"], [&"rust_whisperer", &"lung_moth"], [&"echo_enemy", &"collapse_husk"], [&"mirror_sniper", &"typo_beast"], [&"hanging_scribe", &"page_swarm"], [&"echo_enemy", &"mirror_sniper"]],
	[[&"mask_enemy", &"seat_husk"], [&"choir_summoner", &"page_swarm"], [&"seat_husk", &"mirror_sniper"], [&"mask_enemy", &"typo_beast"], [&"ink_bomber", &"mask_enemy"], [&"mirror_sniper", &"page_swarm"]],
]

@onready var player: Player = $Player
@onready var level: Node2D = $Level
@onready var level2: Node2D = $Level2
@onready var level3: Node2D = $Level3
@onready var level4: Node2D = $Level4
@onready var hud: HUD = $HUD
@onready var inventory_ui: InventoryUI = $UI/Inventory
@onready var codex_ui: CodexUI = $UI/Codex
@onready var settings_menu: SettingsMenu = $UI/Settings
@onready var ending_screen: EndingScreen = $UI/Ending
@onready var pause_menu: PauseMenu = $PauseMenu

var run_state: RunState
var resolver := PhraseResolver.new()
var phrase_caster := PhraseCaster.new()
var relic_effects := RelicEffects.new()
var _chapters: Array[Dictionary] = []
var _chapter := 0
var _chapter_plan: ChapterPlanData = null
var _event_room_id := ""
var _rooms: Array[ArenaRoom] = []
var _steles: Array[MemoryStele] = []
var _chests: Array[TreasureChest] = []
var _kills := 0
var _finished := false
var _ending_pending := false
var _example_phrases: Array[ResolvedPhrase] = []
var _boss: InkArchivist
var _boss_bar_visible := false
var _authority := AuthorityController.new()
var _authority_choice: AuthorityChoiceUI
var _cleared_in_chapter := 0
var _help_ui: HelpUI
var _reward_ui: RewardChoice
var _reward_options: Array[Dictionary] = []
var _reward_room: ArenaRoom
var _overlay: Control
var _last_checkpoint := Vector2(120, 530)
var _story: StoryOverlay
var _shop_ui: RunShopUI
var _shops: Array[MemoryShop] = []
var _shop_cache: Dictionary = {}
var _active_shop: MemoryShop
var _mercy := 0
var _records := 0
var _burned_final := false
var _screen_fx: ScreenFX
var _hit_stop: HitStop
var _boss_entrance_started := false
var _frenzy_active := false
var _frenzy_left := 0.0
var _frenzy_last_seconds := -1
var _frenzy_saved_max_health := 0
var _frenzy_saved_health := 0
var _frenzy_cap := 0
var _mds_active := false
var _mds_world: MDSWorldGame
var _mds_boss_arena: ArenaRoom
var _mds_cleared_rooms: Dictionary = {}
var _discovered_vaults: Dictionary = {}
var _map_overlay: MapOverlay
var _archive_damage_multiplier := 1.0
const BOSS_MUSIC := "res://assets/audio/music/boss.ogg"
const CORRUPTION_FRENZY_SECONDS := 30.0
const CORRUPTION_FRENZY_HEALTH_RATIO := 0.4

func _ready() -> void:
	get_tree().paused = false
	run_state = Flow.start_run(randi())
	_authority = AuthorityController.new()
	run_state.corruption_gain_multiplier = Difficulty.corruption_multiplier(Flow.difficulty)
	_apply_archive_upgrades()
	_apply_npc_blessings()
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	player.weapon_changed.connect(hud.set_active_weapon)
	_populate_starter_inventory()
	_apply_stored_relics()
	relic_effects.run = run_state
	relic_effects.player = player
	hud.bind_run_state(run_state)
	run_state.corruption_tier_changed.connect(_on_corruption_tier_changed)
	_apply_corruption_penalties()
	hud.set_region("墨雨档案馆")
	hud.set_progress(0, 7)
	hud.set_objective("找回失踪名册的第一页")
	inventory_ui.bind(run_state.inventory)
	codex_ui.bind(resolver, run_state)
	codex_ui.set_discovered(_example_phrases)
	if Flow.profile != null:
		codex_ui.set_persistent_discovered(Flow.profile.discovered_phrases)
	codex_ui.phrase_equip_requested.connect(_on_codex_equip)
	inventory_ui.close_requested.connect(_close_overlay)
	codex_ui.close_requested.connect(_close_overlay)
	settings_menu.closed.connect(_close_overlay)
	_help_ui = HelpUI.new()
	$UI.add_child(_help_ui)
	_help_ui.closed.connect(_close_overlay)
	pause_menu.managed = true
	(pause_menu.find_child("QuitButton", true, false) as Button).text = "返回档案馆"
	pause_menu.pause_requested.connect(_toggle_pause)
	_setup_phrase_caster()
	_setup_campaign()
	_reward_ui = RewardChoice.new()
	$UI.add_child(_reward_ui)
	_reward_ui.chosen.connect(_on_reward_chosen)
	_reward_ui.reroll_requested.connect(_on_rewrite_requested)
	_story = StoryOverlay.new()
	$UI.add_child(_story)
	_authority_choice = AuthorityChoiceUI.new()
	$UI.add_child(_authority_choice)
	_map_overlay = MapOverlay.new()
	$UI.add_child(_map_overlay)
	_shop_ui = RunShopUI.new()
	$UI.add_child(_shop_ui)
	_shop_ui.buy.connect(_on_shop_buy)
	_shop_ui.closed.connect(_on_shop_closed)
	_screen_fx = ScreenFX.new()
	add_child(_screen_fx)
	_hit_stop = HitStop.new()
	add_child(_hit_stop)
	player.damaged.connect(_on_player_damaged)
	player.hit_landed.connect(_on_melee_hit)
	phrase_caster.cast_succeeded.connect(_on_cast_succeeded)
	for biome in [level, level2, level3]:
		var backdrop := LivingBackdrop.new()
		backdrop.breathing = biome == level2
		backdrop.sea = biome == level3
		backdrop.world_width = CHAPTER_WIDTH
		biome.add_child(backdrop)
	for biome in [level, level2, level3, level4]:
		biome.get_node("Ground/Visual").visible = false
		for platform in biome.get_children():
			if platform is StaticBody2D and String(platform.name).begins_with("Platform"):
				StylePlatform.apply(platform)
	_start_chapter.call_deferred(0)

## HUD hides under any modal page so the page is the only thing to read.
func _sync_hud_visibility() -> void:
	var modal := _overlay != null or pause_menu.is_open() or _story.is_open() 		or (_reward_ui != null and _reward_ui.visible) or (_shop_ui != null and _shop_ui.visible) 		or (_map_overlay != null and _map_overlay.is_open()) or ending_screen.visible
	hud.visible = not modal


func _process(delta: float) -> void:
	_sync_hud_visibility()
	if Input.is_action_just_pressed("restart") and _finished:
		_return_to_hub()
		return
	if _finished or _ending_pending or get_tree().paused:
		return
	_update_corruption_frenzy(delta)
	_update_room_locks()
	_update_boss_bar()
	_update_stele_prompts()
	relic_effects.tick(delta, get_tree().get_nodes_in_group("enemies"))
	phrase_caster.cooldown_scale = relic_effects.cooldown_scale()
	phrase_caster.damage_scale = 3.0 * relic_effects.damage_scale() * _archive_damage_multiplier
	phrase_caster.tick(delta)
	if Input.is_action_just_pressed("cast_1"):
		_try_cast(0)
	if Input.is_action_just_pressed("cast_2"):
		_try_cast(1)
	if Input.is_action_just_pressed("interact"):
		if not _try_open_shop() and not _try_open_chest() and not _try_pickup_nearest():
			_claim_nearest_stele()
	if not _mds_active:
		var left := _chapter_level().position.x
		player.position.x = clampf(player.position.x, left + 30.0, left + CHAPTER_WIDTH - 30.0)
	if player.position.y > 850:
		player.position = _last_checkpoint
		player.velocity = Vector2.ZERO
		player.take_damage(15)

func _input(event: InputEvent) -> void:
	if _finished or _ending_pending:
		return
	if _map_overlay != null and _map_overlay.is_open():
		if event.is_action_pressed("map") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			_map_overlay.close()
			get_viewport().set_input_as_handled()
		return
	if _reward_ui != null and _reward_ui.visible:
		return
	if _shop_ui != null and _shop_ui.visible:
		return
	if _story != null and _story.is_open():
		return
	if event.is_action_pressed("pause"):
		if _overlay != null:
			_close_overlay()
		else:
			_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("map"):
		if _mds_active and _map_overlay != null:
			_map_overlay.open()
			get_viewport().set_input_as_handled()
		else:
			hud.show_message("这一章还没有地图")
		return
	if event.is_action_pressed("inventory"):
		_toggle_overlay(inventory_ui)
	elif event.is_action_pressed("codex"):
		_toggle_overlay(codex_ui)
	elif event.is_action_pressed("settings"):
		_toggle_overlay(settings_menu)
	elif event.is_action_pressed("help"):
		_toggle_overlay(_help_ui)
	else:
		return
	get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	var audio := get_node_or_null("/root/Audio") as AudioManager
	if audio != null:
		audio.shutdown()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree():
		if not _ended() and not get_tree().paused and pause_menu != null:
			pause_menu.open_pause()


func _toggle_pause() -> void:
	if _finished or _ending_pending or (_reward_ui != null and _reward_ui.visible):
		return
	pause_menu.toggle()

func _toggle_overlay(overlay: Control) -> void:
	if _overlay == overlay:
		_close_overlay()
		return
	if pause_menu.is_open():
		pause_menu.toggle()
	if _overlay != null:
		_overlay.hide()
	_overlay = overlay
	_overlay.show()
	get_tree().paused = true
	var first := _overlay.find_children("*", "Button", true, false)
	if not first.is_empty():
		(first[0] as Button).grab_focus()

func _close_overlay() -> void:
	if _overlay != null:
		_overlay.hide()
		_overlay = null
	get_tree().paused = _finished or (_reward_ui != null and _reward_ui.visible)

func _setup_phrase_caster() -> void:
	phrase_caster.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(phrase_caster)
	phrase_caster.bind_run_state(run_state)
	phrase_caster.set_player(player)
	phrase_caster.set_enemy_root(self)
	phrase_caster.status_changed.connect(hud.set_phrase_status)
	phrase_caster.impact_requested.connect(_on_spell_impact)
	phrase_caster.purified.connect(_on_phrase_purified)
	for index in 2:
		_set_phrase_identity(index, run_state.inventory.phrases[index])
		phrase_caster.equip_phrase(index, run_state.inventory.phrases[index])

func _set_phrase_identity(slot: int, phrase: ResolvedPhrase) -> void:
	if phrase == null:
		return
	var spell := phrase.spell
	var name: String = SpellStyle.NAMES.get(spell.get(&"shape", &"blade"), "墨刃")
	var color: Color = spell.get(&"color", Color("79e8d5"))
	hud.set_phrase_identity(slot, name, color)

func _apply_archive_upgrades() -> void:
	if Flow.profile == null or run_state == null or player == null:
		return
	var vitality := Flow.profile.archive_level(&"vitality")
	var ink := Flow.profile.archive_level(&"ink")
	var damage := Flow.profile.archive_level(&"damage")
	var ward := Flow.profile.archive_level(&"ward")
	if vitality > 0:
		player.max_health += vitality * 10
		player.health = player.max_health
		run_state.max_health = player.max_health
		run_state.health = player.health
	if ink > 0:
		run_state.max_ink += ink * 5
		run_state.ink = run_state.max_ink
	_archive_damage_multiplier = 1.0 + damage * 0.04
	run_state.corruption_gain_multiplier = (
		Difficulty.corruption_multiplier(Flow.difficulty) / (1.0 + ward * 0.02)
	)


func _apply_npc_blessings() -> void:
	if Flow.profile == null or run_state == null:
		return
	# Map pages and starting corruption are next-run-only; consuming them here
	# prevents the permanent stacking that made NPC farming break the run.
	var pending := Flow.profile.consume_pending_run_bonuses()
	if Flow.auto_save:
		Flow.save_profile()
	var start_pages := mini(int(round(float(pending.get("start_pages", 0.0)))), 20)
	if start_pages > 0:
		run_state.add_pages(start_pages)
	var start_corruption := mini(int(round(float(pending.get("start_corruption", 0.0)))), 6)
	if start_corruption > 0:
		run_state.add_corruption(start_corruption)


## Relics bought from 咕噜 travel into the next run, then leave the stall.
func _apply_stored_relics() -> void:
	if Flow.profile == null or run_state == null:
		return
	var ids := Flow.profile.consume_stored_relics()
	if ids.is_empty():
		return
	var names: Array[String] = []
	for id in ids:
		var relic := ContentLibrary.relic_by_id(id)
		if relic != null and run_state.inventory.add_relic(relic):
			run_state.add_corruption(relic.corruption)
			names.append(relic.display_name)
	if not names.is_empty():
		hud.show_message("咕噜的存货：" + " · ".join(names))
	if Flow.auto_save:
		Flow.save_profile()


func _populate_starter_inventory() -> void:
	for word in RunLoot.starting_words(Flow.profile):
		run_state.inventory.add_word(word)
	var by_id: Dictionary = {}
	for word in run_state.inventory.words:
		by_id[word.id] = word
	for ids in [[&"ranshao", &"yan"], [&"grguan", &"gr"]]:
		var words: Array[WordData] = []
		for id in ids:
			words.append(by_id[id])
		var phrase := resolver.resolve(words)
		_example_phrases.append(phrase)
		run_state.inventory.equip_phrase(_example_phrases.size() - 1, phrase)
	_equip_weapon(0, RunLoot.weapon_for_run(player.starter_weapon, Flow.profile))
	_equip_weapon(1, RunLoot.weapon_for_run(SECOND_WEAPON, Flow.profile))

func _equip_weapon(slot: int, weapon: WeaponData) -> void:
	player.equip_weapon(slot, weapon)
	run_state.inventory.equip_weapon(slot, weapon)


## Equip into the active slot without deleting the previous weapon: it drops
## behind the player and can be picked back up, so a bad reward decision never
## costs a good weapon.
func _acquire_weapon(weapon: WeaponData, announce: bool = false) -> void:
	if weapon == null:
		return
	var slot := player.active_weapon_slot
	var previous: WeaponData = null
	if slot >= 0 and slot < run_state.inventory.weapons.size():
		previous = run_state.inventory.weapons[slot]
	_equip_weapon(slot, weapon)
	_update_hud()
	if previous != null and previous != weapon:
		var drop_at := player.global_position - Vector2(player.facing.x * 90.0, 0.0)
		_drop_weapon(previous, drop_at)
		if announce:
			hud.show_message("拾取 %s · %s 掉在身后" % [weapon.display_name, previous.display_name])
	elif announce:
		hud.show_message("拾取：%s" % weapon.display_name)


func _drop_weapon(weapon: WeaponData, at: Vector2) -> void:
	if weapon == null or not is_inside_tree():
		return
	var pickup := PICKUP_SCENE.instantiate() as Pickup
	pickup.kind = &"weapon"
	pickup.resource = weapon
	pickup.label_text = weapon.display_name
	pickup.process_mode = Node.PROCESS_MODE_PAUSABLE
	# Position before adding: Pickup starts its bobbing tween in _ready from the
	# position it has then. Main sits at the origin, so world == local here.
	pickup.position = at
	add_child(pickup)
	pickup.collected.connect(_on_pickup_collected)


func _on_pickup_collected(kind: StringName, resource: Resource) -> void:
	match kind:
		&"weapon":
			_acquire_weapon(resource as WeaponData, true)
		&"relic":
			var relic := resource as RelicData
			if relic != null and run_state.inventory.add_relic(relic):
				run_state.add_corruption(relic.corruption)
				hud.show_message("拾取遗物：%s" % relic.display_name)
		&"word":
			var word := _acquire_word(resource as WordData)
			if word != null:
				hud.show_message("拾取新词：%s" % RunLoot.word_label(word))
		_:
			pass
	_update_hud()

func _setup_campaign() -> void:
	var levels: Array[Node2D] = [level, level2, level3, level4]
	for index in CampaignData.chapter_count():
		var chapter_level := levels[index]
		chapter_level.position = Vector2(index * CHAPTER_WIDTH, 0)
		# Every chapter now runs on its own MDS world; the old continuous levels
		# stay in the scene only as dormant fallbacks and must not collide.
		chapter_level.visible = false
		chapter_level.process_mode = Node.PROCESS_MODE_DISABLED
		_chapters.append({
			"level": chapter_level,
			"rooms": [],
			"boss": null,
			"chapter": CampaignData.chapter(index),
			"mds": true,
		})


func _populate_room(room: ArenaRoom, ids: Array, wave_ids: Array = []) -> void:
	_spawn_group(room, ids, -140.0)
	if not wave_ids.is_empty():
		room.queue_wave(func(): _spawn_group(room, wave_ids, -110.0))


func _spawn_group(room: ArenaRoom, ids: Array, start_offset: float) -> void:
	var offset := start_offset
	for id in ids:
		if not ENEMY_SCENES.has(id):
			continue
		var enemy := room.spawn_enemy(ENEMY_SCENES[id], Vector2(offset, 250)) as Enemy
		if enemy == null:
			continue
		var art_id: StringName = ENEMY_ART_FALLBACK.get(id, id)
		var tint := Color("c8e1cd") if ENEMY_ART_FALLBACK.has(id) else Color.WHITE
		_apply_art(enemy, ENEMY_ART[art_id], float(ENEMY_ART_SCALE.get(id, 1.0)), tint)
		var health_scale := Difficulty.enemy_health(Flow.difficulty)
		if not is_equal_approx(health_scale, 1.0):
			var scaled := enemy.data.duplicate() as EnemyData
			scaled.max_health = maxi(int(round(scaled.max_health * health_scale)), 1)
			enemy.data = scaled
		enemy.deaggro_range = 1150
		enemy.aggro_range = 600
		enemy.set_target(player)
		enemy.died.connect(_on_enemy_died)
		enemy.damaged.connect(relic_effects.on_damage)
		offset += 150

func _spawn_boss(room: ArenaRoom, chapter: Dictionary, chapter_index: int) -> InkArchivist:
	var scene: PackedScene = BOSS_SCENE
	var chapter_scene: PackedScene = chapter.get("boss_scene", null)
	if chapter_scene != null:
		scene = chapter_scene
	elif _chapter_plan != null and _chapter_plan.boss_scene != null:
		scene = _chapter_plan.boss_scene
	elif chapter["boss_script"] == &"smiling":
		scene = SMILING_SCENE
	elif chapter["boss_script"] == &"reader":
		scene = READER_SCENE
	var boss := room.spawn_enemy(scene, Vector2(110, 250)) as InkArchivist
	if boss == null:
		return null
	var stats := BOSS_DATA.duplicate() as EnemyData
	var health_scale := Difficulty.enemy_health(Flow.difficulty)
	stats.max_health = maxi(int(round(chapter["boss_hp"] * health_scale)), 1)
	stats.contact_damage = int(chapter["boss_damage"])
	stats.speed = chapter["boss_speed"]
	boss.data = stats
	boss.attack_range = 200.0
	boss.aggro_range = 700.0
	boss.deaggro_range = 1200.0
	boss.attack_windup = 0.7
	var texture: Texture2D = load(chapter["boss_texture"])
	_apply_art(boss, texture, chapter["boss_scale"], chapter["boss_tint"], &"elite")
	boss.died.connect(_on_boss_died.bind(chapter_index))
	boss.health_changed.connect(hud.update_boss)
	boss.damaged.connect(relic_effects.on_damage)
	boss.phase_changed.connect(func(phase: int): _on_boss_phase(chapter, phase))
	return boss

func _apply_art(enemy: Enemy, texture: Texture2D, art_scale: float, tint: Color, style: StringName = &"") -> void:
	if style != &"":
		enemy.actor_style = style
	elif enemy.data != null:
		enemy.actor_style = ENEMY_ANIM_STYLE.get(enemy.data.id, &"humanoid")
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	PixelSprite.setup(sprite, texture, art_scale, ENEMY_FOOT_Y)
	sprite.modulate = tint
	enemy.add_child(sprite)
	enemy.sprite_visual = sprite
	enemy.sprite_base_modulate = tint
	var visual_height := PixelSprite.art_height(sprite)
	var collider := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider != null:
		var shape := CapsuleShape2D.new()
		shape.radius = clampf(visual_height * 0.18, 16.0, 34.0)
		shape.height = clampf(visual_height * 0.75, 60.0, 210.0)
		collider.shape = shape
		collider.position.y = ENEMY_FOOT_Y - shape.height * 0.5
	for node_name in ["Body", "Eye"]:
		var node := enemy.get_node_or_null(node_name)
		if node != null:
			node.hide()

func _start_chapter(index: int) -> void:
	_chapter = clampi(index, 0, CampaignData.chapter_count() - 1)
	await _start_mds_chapter(_chapter)


func _start_mds_chapter(index: int) -> void:
	var chapter_index := clampi(index, 0, CampaignData.chapter_count() - 1)
	_teardown_mds()
	_chapter = chapter_index
	var chapter := CampaignData.chapter(chapter_index)
	_chapter_plan = null
	_event_room_id = ""
	if chapter_index == 0:
		_chapter_plan = load("res://resources/chapters/chapter_1_demo.tres") as ChapterPlanData
	_mds_active = true
	_rooms.clear()
	_boss = null
	_mds_boss_arena = null
	_mds_cleared_rooms.clear()
	_discovered_vaults.clear()
	_cleared_in_chapter = 0
	_boss_bar_visible = false
	_boss_entrance_started = false
	_steles.clear()
	_shops.clear()
	_chests.clear()
	_shop_cache.clear()
	for hazard in get_tree().get_nodes_in_group("hostile_hazards"):
		hazard.queue_free()
	hud.set_region("%s · %s" % [chapter["region"], Difficulty.display_name(Flow.difficulty)])
	hud.set_progress(0, 7)
	hud.set_objective(chapter["objective"])
	hud.hide_boss()
	Audio.play_music(chapter["music"], 1.2)
	_screen_fx.flash(Color("79d8c8", 0.12), 0.35)
	_ending_pending = true
	_story.open_story("第 %d 章  /  %s" % [chapter["number"], chapter["subtitle"]], chapter["title"], chapter["intro"], chapter["voice_intro"])
	await _story.story_finished
	if not is_inside_tree():
		return
	_ending_pending = false
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	var world := MDS_CHAPTER_SCENES[chapter_index].instantiate() as MDSWorldGame
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.player = player
	world.camera = camera
	world.world_file = MDS_WORLD_FILES[chapter_index]
	world.starting_room = "ch%d_01" % (chapter_index + 1)
	if _map_overlay != null:
		_map_overlay.set_world(MDS_WORLD_FILES[chapter_index])
		world.map_view = _map_overlay.map_view
	world.room_loaded.connect(_on_mds_room_loaded)
	add_child(world)
	_mds_world = world
	hud.show_message("目标：%s。按 H 看操作说明。" % String(chapter["objective"]))


func _teardown_mds() -> void:
	if _map_overlay != null and _map_overlay.is_open():
		_map_overlay.close()
	if _mds_world != null and is_instance_valid(_mds_world):
		_mds_world.queue_free()
	_mds_world = null
	_mds_active = false
	_mds_boss_arena = null
	_mds_cleared_rooms.clear()
	_discovered_vaults.clear()
	_rooms.clear()


## The world reports each room after the player has been placed; from then on
## game.gd owns the enemies, rewards and boss, exactly as it did for linear rooms.
func _on_mds_room_loaded(room_id: String) -> void:
	if not _mds_active or _mds_world == null:
		return
	var room_node := _mds_world.room_node
	if room_node == null:
		return
	_rooms.clear()
	_boss = null
	_mds_boss_arena = null
	_steles.clear()
	_shops.clear()
	_chests.clear()
	for node in room_node.find_children("*", "", true, false):
		if node is MemoryStele:
			_steles.append(node)
		elif node is MemoryShop:
			_shops.append(node)
		elif node is TreasureChest:
			_chests.append(node)
	_boss_bar_visible = false
	_boss_entrance_started = false
	var chapter := CampaignData.chapter(_chapter)
	var arena := room_node.get_node_or_null("Arena") as ArenaRoom
	var room_index := _mds_room_index(room_id)
	var plan_room := _plan_room(room_id)
	var room_type := String(plan_room.get("type", ""))
	if arena != null:
		arena.cleared.connect(_on_room_cleared.bind(arena, _chapter))
		arena.get_node("Enemies").process_mode = Node.PROCESS_MODE_DISABLED
		if room_type == "event":
			if _mds_cleared_rooms.has(room_id):
				hud.set_objective("事件已经读过")
			else:
				hud.set_objective("事件 · 读或不读")
				# room_loaded fires before the camera fade finishes; opening a
				# paused modal inside that await would stall the transition.
				_open_ch1_event_after_transition.call_deferred(room_id)
		elif room_index == 7 or room_type == "boss":
			_mds_boss_arena = arena
			_rooms.append(arena)
			_boss = _spawn_boss(arena, chapter, _chapter)
			hud.set_objective("击败 %s" % chapter["boss_name"])
		elif room_index >= 0 and room_index < 6 and not _mds_cleared_rooms.has(room_id):
			_rooms.append(arena)
			if _chapter_plan != null:
				var wave: Array = plan_room.get("wave", [])
				var first_count := mini(2, wave.size())
				_populate_room(arena, wave.slice(0, first_count), wave.slice(first_count))
			else:
				# Chapters 2–4 keep the authored first group + ROOM_WAVES wave.
				_populate_room(arena, chapter["rooms"][room_index], ROOM_WAVES[_chapter][room_index])
			hud.set_objective("肃清此房间 · 敌人 %d" % arena.enemy_count())
		else:
			hud.set_objective("此房间已肃清")
	else:
		var is_vault := room_id.ends_with("_vault")
		hud.set_objective("搜查隐藏书库" if is_vault else "休整，或继续前进")
		if is_vault and not _discovered_vaults.has(room_id):
			_discovered_vaults[room_id] = true
			hud.show_message("发现隐藏书库 · 搜查宝箱与残碑")
			CombatFX.spawn(player.get_parent(), player.global_position, &"ring", Color("e6c87a"), 1.0, 130.0)
			var audio := get_node_or_null("/root/Audio")
			if audio != null:
				audio.call("play_sfx", &"pickup")
	_last_checkpoint = player.global_position
	hud.set_progress(_cleared_in_chapter, 7)
	hud.hide_boss()


func _plan_room(room_id: String) -> Dictionary:
	if _chapter_plan == null:
		return {}
	return _chapter_plan.room(room_id)


func _open_ch1_event_after_transition(room_id: String) -> void:
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree() or _finished or _ending_pending:
		return
	_open_ch1_event(room_id)


## Chapter 1 event room: no forced fight; reading the forbidden page grants a
## word at a corruption cost, taking the pages is the safe economic choice.
func _open_ch1_event(room_id: String) -> void:
	if _event_room_id == room_id or _finished or _ending_pending:
		return
	_event_room_id = room_id
	_story.open_choice("事件 · 禁文", "一页禁文在墨雨中发光。", "读它，还是把残页带走？", [
		{"label": "读禁文", "note": "获得一个词，污染 +8"},
		{"label": "拿残页", "note": "残页 +12"},
	])
	var picked: int = await _story.choice_made
	if picked == 0:
		run_state.add_corruption(8)
		_grant_event_word()
		hud.show_message("禁文入脑 · 获得一个词，污染 +8")
	else:
		run_state.add_pages(12)
		hud.show_message("带走残页 · 残页 +12")
	_mds_cleared_rooms[room_id] = true
	_cleared_in_chapter += 1
	hud.set_progress(_cleared_in_chapter, 7)


func _grant_event_word() -> void:
	var pool: Array[WordData] = []
	for word in RunLoot.demo_word_pool():
		if not run_state.inventory.has_word(word.id):
			pool.append(word)
	if pool.is_empty():
		run_state.add_pages(6)
		return
	var picked := pool[run_state.rng.randi_range(0, pool.size() - 1)]
	_acquire_word(picked)


func _acquire_word(source: WordData) -> WordData:
	if source == null:
		return null
	var word := WordRuntime.for_run(source, Flow.profile)
	run_state.inventory.add_word(word)
	if Flow.profile != null:
		Flow.profile.unlock_word(word.id)
	return word


func _mds_room_index(room_id: String) -> int:
	if room_id.ends_with("_boss"):
		return 7
	if room_id.ends_with("_rest"):
		return 6
	if room_id.ends_with("_vault"):
		return 8
	var suffix := room_id.get_slice("_", 1)
	if suffix.is_valid_int():
		return int(suffix) - 1
	return -1


func _is_boss_room(room: ArenaRoom) -> bool:
	if room == null:
		return false
	if _mds_active:
		return room == _mds_boss_arena
	return not _rooms.is_empty() and room == _rooms.back()


func _chapter_level() -> Node2D:
	return _chapters[_chapter]["level"] as Node2D

func _update_room_locks() -> void:
	for room in _rooms:
		if room.is_locked() or room.is_cleared():
			continue
		if room.contains_entry(player.global_position):
			room.get_node("Enemies").process_mode = Node.PROCESS_MODE_PAUSABLE
			for enemy in room.get_node("Enemies").get_children():
				if enemy is Enemy:
					enemy.set_target(player)
			room.lock_until_cleared()
			var chapter := CampaignData.chapter(_chapter)
			hud.set_objective("击败 %s" % chapter["boss_name"] if _is_boss_room(room) else "肃清此房间 · 敌人 %d" % room.enemy_count())
			_last_checkpoint = player.global_position if _mds_active else Vector2(room.global_position.x - 450, 530)
			if _is_boss_room(room):
				_boss_entrance()

func _boss_entrance() -> void:
	if _boss_entrance_started:
		return
	_boss_entrance_started = true
	if not _mds_active:
		ChapterAtmosphere.start_boss_background(_rooms.back())
	Audio.play_music(BOSS_MUSIC, 0.7)
	_screen_fx.flash(Color("e0b06a", 0.22), 0.3)
	_screen_fx.letterbox(54.0, 0.35)
	await get_tree().create_timer(1.25, false).timeout
	if is_inside_tree():
		_screen_fx.letterbox(0.0, 0.5)


func _on_room_cleared(room: ArenaRoom, chapter_index: int) -> void:
	if chapter_index != _chapter or _ending_pending or _finished:
		return
	if _is_boss_room(room):
		return
	for hazard in get_tree().get_nodes_in_group("hostile_hazards"):
		hazard.queue_free()
	_cleared_in_chapter += 1
	if _mds_active and _mds_world != null:
		_mds_cleared_rooms[_mds_world.current_room] = true
	run_state.add_pages(maxi(1, int(round((4 + Flow.difficulty * 2) * Difficulty.reward_multiplier(Flow.difficulty)))))
	hud.set_progress(_cleared_in_chapter, 7)
	relic_effects.on_room_cleared()
	if _cleared_in_chapter >= 6:
		hud.set_objective("前往章节尽头 · 击败 " + String(CampaignData.chapter(_chapter)["boss_name"]))
	_update_hud()
	_reward_room = room
	if String(_current_plan_room().get("type", "")) == "elite":
		_reward_options = RunLoot.elite_choices(run_state, _chapter * 6 + _cleared_in_chapter, Flow.profile, _chapter)
	else:
		_reward_options = RunLoot.choices(run_state, _chapter * 6 + _cleared_in_chapter, Flow.profile, _chapter)
	_open_reward.call_deferred()

func _current_plan_room() -> Dictionary:
	if not _mds_active or _mds_world == null:
		return {}
	return _plan_room(_mds_world.current_room)


func _open_reward() -> void:
	if _finished or _ending_pending:
		return
	_close_overlay()
	get_tree().paused = true
	_reward_ui.open_choices(_reward_options)
	_reward_ui.set_reroll_available(_authority.can_rewrite())

func _on_reward_chosen(index: int) -> void:
	if index < 0 or index >= _reward_options.size():
		return
	var choice := _reward_options[index]
	_apply_reward(choice)
	_reward_options.clear()
	_reward_ui.hide()
	get_tree().paused = false
	hud.show_message("获得：" + String(choice["title"]))
	_reward_room = null

func _apply_reward(choice: Dictionary) -> void:
	match choice["kind"]:
		&"relic":
			var relic := choice["resource"] as RelicData
			if run_state.inventory.add_relic(relic):
				run_state.add_corruption(relic.corruption)
		&"word":
			var word := _acquire_word(choice["resource"] as WordData)
			if relic_effects.has(&"decode_bonus"):
				run_state.restore_ink(12)
		&"weapon":
			_acquire_weapon(choice["resource"] as WeaponData)
		&"vitality":
			player.max_health += 15
			player.heal(15)
		&"rest":
			player.heal(35)
			run_state.restore_ink(45)
			run_state.add_corruption(-12)

func _try_cast(slot: int) -> void:
	if phrase_caster.cast(slot):
		Audio.play_sfx(&"attack")
	elif player.disabled_phrase_slots[slot]:
		hud.show_message("这条短语暂时被封印")
	elif phrase_caster.get_cooldown_left(slot) > 0:
		hud.show_message("短语正在冷却")
	else:
		hud.show_message("墨量不足 · 击杀或等待回墨")

func _on_codex_equip(slot: int, phrase: ResolvedPhrase) -> void:
	if phrase == null:
		return
	phrase_caster.equip_phrase(slot, phrase)
	run_state.inventory.equip_phrase(slot, phrase)
	_set_phrase_identity(slot, phrase)
	if not _example_phrases.has(phrase):
		_example_phrases.append(phrase)
		codex_ui.set_discovered(_example_phrases)
	_discover_phrase(phrase)
	hud.show_message("已装备：%s · %s" % [phrase.display_name, SpellStyle.NAMES.get(phrase.spell.get(&"shape", &"blade"), "墨刃")])


## Persist real word combos (synthetic wild words are ephemeral).
func _discover_phrase(phrase: ResolvedPhrase) -> void:
	if phrase == null or Flow.profile == null:
		return
	for word in phrase.words:
		if word == null or String(word.id).begins_with("__"):
			return
	if Flow.profile.discover_phrase(phrase.signature):
		codex_ui.set_persistent_discovered(Flow.profile.discovered_phrases)

func _on_boss_phase(chapter: Dictionary, phase: int) -> void:
	hud.show_message("%s · 第 %d 阶段" % [chapter["boss_name"], phase])
	_screen_fx.flash(Color("d96a7a", 0.2), 0.22)
	_hit_stop.freeze(0.07, 0.08)
	Audio.play_voice("boss_%s_phase%d" % [chapter["boss_voice"], phase])


func _on_melee_hit() -> void:
	if _hit_stop != null:
		_hit_stop.freeze(0.035, 0.3)


## Spell hits and blasts: trauma accumulates on the camera; only heavy impacts
## (or phrases that ask for it) freeze time, and at most once per short window.
var _spell_freeze_cooldown := 0.0
var _shake_frame := -1
var _shake_this_frame := 0.0

func _on_spell_impact(strength: float, freeze: float) -> void:
	# Many simultaneous hits (a 96-bolt volley) share one frame's shake budget.
	var frame := Engine.get_process_frames()
	if frame != _shake_frame:
		_shake_frame = frame
		_shake_this_frame = 0.0
	var add := minf(minf(strength, 1.0) * 0.45, maxf(0.3 - _shake_this_frame, 0.0))
	_shake_this_frame += add
	player.add_shake(add)
	var now := Time.get_ticks_msec() / 1000.0
	if now < _spell_freeze_cooldown or _hit_stop == null:
		return
	var duration := freeze if freeze > 0.0 else (0.05 if strength >= 0.5 else 0.0)
	if duration > 0.0:
		_spell_freeze_cooldown = now + 0.25
		_hit_stop.freeze(duration, 0.12)


func _on_player_damaged(_amount: int) -> void:
	if _screen_fx != null:
		_screen_fx.flash(Color(0.75, 0.12, 0.18, 0.2), 0.12)


func _apply_corruption_penalties() -> void:
	if player != null and run_state != null:
		player.damage_taken_multiplier = (
			Difficulty.enemy_damage(Flow.difficulty)
			* run_state.corruption_damage_taken_multiplier()
		)


## Each pollution threshold is announced and felt: the enemy hits harder and
## every phrase costs more ink. 100 does not end the run by itself: it forces a
## 30-second frenzy with a much smaller health pool, then recovery.
func _on_corruption_tier_changed(tier: int) -> void:
	_apply_corruption_penalties()
	if _finished or _ending_pending:
		return
	if tier >= 4:
		_start_corruption_frenzy()
		return
	if _frenzy_active:
		return
	if tier <= 0:
		hud.show_message("污染退去 · 喉咙里的低语暂时安静")
		return
	hud.show_message(run_state.corruption_tier_warning())
	if _screen_fx != null:
		_screen_fx.flash(Color(0.60, 0.32, 0.82, 0.24), 0.3)
	if player != null:
		player.add_shake(0.28)


func _start_corruption_frenzy() -> void:
	if _frenzy_active or _finished or _ending_pending or player == null:
		return
	_frenzy_active = true
	_frenzy_left = CORRUPTION_FRENZY_SECONDS
	_frenzy_last_seconds = -1
	_frenzy_saved_max_health = player.max_health
	_frenzy_saved_health = player.health
	var frenzy_max := maxi(20, int(round(float(player.max_health) * CORRUPTION_FRENZY_HEALTH_RATIO)))
	_frenzy_cap = frenzy_max
	player.max_health = frenzy_max
	player.health = maxi(1, mini(player.health, int(round(float(frenzy_max) * 0.75))))
	player.health_changed.emit(player.health, player.max_health)
	player.add_shake(0.5)
	hud.show_message("污染 100 · 发狂：生命被压到 %d，撑过 %d 秒" % [
		player.health,
		int(CORRUPTION_FRENZY_SECONDS),
	])
	hud.set_frenzy(int(CORRUPTION_FRENZY_SECONDS))
	if _screen_fx != null:
		_screen_fx.flash(Color(0.42, 0.16, 0.62, 0.5), 0.7)
	if _hit_stop != null:
		_hit_stop.freeze(0.15, 0.18)


func _update_corruption_frenzy(delta: float) -> void:
	if not _frenzy_active:
		return
	_frenzy_left = maxf(_frenzy_left - delta, 0.0)
	var seconds := int(ceilf(_frenzy_left))
	if seconds != _frenzy_last_seconds:
		_frenzy_last_seconds = seconds
		hud.set_frenzy(seconds)
	if _frenzy_left <= 0.0:
		_end_corruption_frenzy()


func _end_corruption_frenzy() -> void:
	_frenzy_active = false
	hud.set_frenzy(0)
	if player != null and _frenzy_saved_max_health > 0:
		# A vitality page picked up mid-frenzy still counts after recovery.
		var gained := maxi(player.max_health - _frenzy_cap, 0)
		player.max_health = _frenzy_saved_max_health + gained
		player.health = mini(player.max_health, maxi(player.health, int(round(float(player.max_health) * 0.5))))
		player.health_changed.emit(player.health, player.max_health)
	# Back to tier 3 so the same 100 value cannot retrigger immediately.
	run_state.set_corruption(mini(run_state.corruption, 90))
	hud.show_message("发狂消退 · 生命上限恢复，污染回落到 %d" % run_state.corruption)


func _on_phrase_purified(amount: int) -> void:
	if amount <= 0:
		return
	hud.show_message("净化：污染 -%d" % amount)
	if _screen_fx != null:
		_screen_fx.flash(Color("9fe8c8", 0.16), 0.22)


func _on_cast_succeeded(slot: int) -> void:
	if slot < 0 or slot >= run_state.inventory.phrases.size():
		return
	var phrase := run_state.inventory.phrases[slot]
	if phrase == null:
		return
	if Flow.profile != null:
		for word in phrase.words:
			if word != null:
				Flow.profile.add_word_mastery(word.id)
	_discover_phrase(phrase)
	if phrase.spell.get(&"shape", &"") == &"void":
		_screen_fx.flash(Color("9b5be0", 0.24), 0.18)
		_hit_stop.freeze(0.04, 0.12)
	elif phrase.spell.get(&"shape", &"") == &"chain":
		_screen_fx.flash(Color("bcdcff", 0.16), 0.12)
	player.play_cast_pose()


func _on_enemy_died(enemy: Node) -> void:
	_kills += 1
	run_state.add_pages(maxi(1, int(round((1 + Flow.difficulty * 0.5) * Difficulty.reward_multiplier(Flow.difficulty)))))
	relic_effects.on_kill()
	_update_hud()
	if enemy is Node2D and run_state.rng.randf() < WEAPON_DROP_CHANCE:
		var base := ContentLibrary.WEAPONS[run_state.rng.randi_range(0, ContentLibrary.WEAPONS.size() - 1)] as WeaponData
		var dropped := RunLoot.weapon_for_run(base, Flow.profile, _chapter * 2 + 1)
		var enemy_position := (enemy as Node2D).global_position
		# Flying enemies die in the air; bring the page down to floor reach.
		var drop_at := Vector2(enemy_position.x, maxf(enemy_position.y, 540.0))
		_drop_weapon(dropped, drop_at)
	for room in _rooms:
		if room.is_locked():
			var alive := 0
			for child in room.get_node("Enemies").get_children():
				if child is Enemy and not child.dead:
					alive += 1
			hud.set_objective("肃清此房间 · 敌人 %d" % alive)

func _on_boss_died(_enemy: Node, chapter_index: int) -> void:
	if chapter_index != _chapter or _ended():
		return
	hud.set_progress(7, 7)
	run_state.add_pages(maxi(1, int(round((8 + Flow.difficulty * 4) * Difficulty.reward_multiplier(Flow.difficulty)))))
	_screen_fx.flash(Color(1.0, 0.9, 0.8, 0.3), 0.4)
	_hit_stop.freeze(0.1, 0.1)
	await _grant_chapter_authority()
	if not is_inside_tree() or _ended():
		return
	_complete_chapter()


func _grant_chapter_authority() -> void:
	if _chapter != 0 or _chapter_plan == null or _chapter_plan.authority_pool.is_empty():
		return
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree() or _ended():
		return
	var options := _chapter_plan.authority_pool
	_authority_choice.open(options)
	var index: int = await _authority_choice.chosen
	if not is_inside_tree():
		return
	var picked := options[clampi(index, 0, options.size() - 1)]
	_authority.apply(picked, run_state)
	hud.set_authority(picked.display_name, true)
	hud.show_message("获得权柄：%s · %s" % [picked.display_name, picked.description])


func _on_rewrite_requested() -> void:
	if not _authority.consume_rewrite():
		return
	var authority_name := run_state.authority.display_name if run_state.authority != null else "改写"
	hud.set_authority(authority_name, false)
	var room_number := _chapter * 6 + _cleared_in_chapter + 1
	if String(_current_plan_room().get("type", "")) == "elite":
		_reward_options = RunLoot.elite_choices(run_state, room_number, Flow.profile, _chapter)
	else:
		_reward_options = RunLoot.choices(run_state, room_number, Flow.profile, _chapter)
	_reward_ui.open_choices(_reward_options)
	_reward_ui.set_reroll_available(false)
	hud.show_message("权柄 · 改写：三选一已重掷")

func _complete_chapter() -> void:
	if _ended():
		return
	_ending_pending = true
	var chapter := CampaignData.chapter(_chapter)
	for hazard in get_tree().get_nodes_in_group("hostile_hazards"):
		hazard.queue_free()
	Audio.play_music(chapter["music"], 1.0)
	_story.open_story("章节完成 · 记忆回收", chapter["title"], chapter["outro"], chapter["voice_outro"])
	await _story.story_finished
	if not is_inside_tree():
		return
	var choice: Dictionary = chapter["choice"]
	_story.open_choice("留下你的选择", choice["title"], choice["body"], choice["options"])
	var picked: int = await _story.choice_made
	if not is_inside_tree():
		return
	_apply_chapter_choice(chapter, picked)
	_ending_pending = false
	# Chapter 1 is the whole demo: stop here instead of walking into Chapter 2.
	if _chapter == 0:
		if Flow.profile != null:
			Flow.profile.demo_cleared = true
		_finish(true)
		return
	if _chapter + 1 < CampaignData.chapter_count():
		_start_chapter(_chapter + 1)
	else:
		_finish(true)

func _apply_chapter_choice(chapter: Dictionary, index: int) -> void:
	var option: Dictionary = chapter["choice"]["options"][index]
	_mercy += int(option.get("mercy", 0))
	if option.has("corruption"):
		run_state.add_corruption(int(option["corruption"]))
	match chapter["id"]:
		&"ink_archive":
			if index == 0:
				player.heal(20)
			else:
				_grant_unowned_relic()
		&"breathing_ruins":
			if index == 0:
				player.grant_shield(24, 999.0)
			else:
				_upgrade_active_weapon()
		&"lightless_sea":
			if index == 0:
				player.heal(20)
			else:
				_grant_unowned_relic()
		&"smiling_theater":
			_burned_final = index == 1
	_run_state_emit()

func _run_state_emit() -> void:
	run_state.health_changed.emit(player.health, player.max_health)

func _grant_unowned_relic() -> void:
	var pool: Array[Resource] = []
	var source: Array[Resource] = ContentLibrary.DEMO_RELICS if _chapter == 0 else ContentLibrary.RELICS
	for relic in source:
		if not run_state.inventory.has_relic(relic.id):
			pool.append(relic)
	if pool.is_empty():
		player.heal(25)
		return
	var relic := pool[randi() % pool.size()] as RelicData
	if run_state.inventory.add_relic(relic):
		run_state.add_corruption(relic.corruption)
		hud.show_message("获得遗物：" + relic.display_name)

func _upgrade_active_weapon() -> void:
	var current := player.weapons[player.active_weapon_slot]
	if current == null or current.data == null:
		return
	var upgraded := current.data.duplicate() as WeaponData
	upgraded.damage += 4
	upgraded.display_name += " · 钟声"
	_equip_weapon(player.active_weapon_slot, upgraded)
	hud.show_message("武器强化：" + upgraded.display_name)

func _update_stele_prompts() -> void:
	for stele in _steles:
		if not is_instance_valid(stele) or stele.is_claimed:
			continue
		stele.set_player_near(player.global_position.distance_to(stele.global_position) < 110.0)
	for shop in _shops:
		if is_instance_valid(shop):
			shop.set_player_near(player.global_position.distance_to(shop.global_position) < 120.0)
	for chest in _chests:
		if is_instance_valid(chest):
			chest.set_player_near(not chest.is_open and player.global_position.distance_to(chest.global_position) < 92.0)


func _try_pickup_nearest() -> bool:
	for node in get_tree().get_nodes_in_group(&"pickups"):
		var pickup := node as Pickup
		if pickup != null and is_instance_valid(pickup) and pickup.can_collect():
			if pickup.try_collect():
				return true
	return false


func _try_open_chest() -> bool:
	for chest in _chests:
		if not is_instance_valid(chest) or chest.is_open:
			continue
		if player.global_position.distance_to(chest.global_position) < 92.0:
			_open_chest(chest)
			return true
	return false


func _open_chest(chest: TreasureChest) -> void:
	if chest == null or not chest.open():
		return
	var reward := RunLoot.chest_loot(run_state, Flow.profile, _chapter)
	var kind := StringName(reward.get("kind", &"pages"))
	match kind:
		&"weapon":
			var weapon := reward.get("resource") as WeaponData
			if weapon != null:
				_acquire_weapon(weapon)
				hud.show_message("宝箱：%s · 旧武器掉在身后" % weapon.display_name)
		&"word":
			var word := _acquire_word(reward.get("resource") as WordData)
			if word != null:
				hud.show_message("宝箱残页：%s" % RunLoot.word_label(word))
		&"relic":
			var relic := reward.get("resource") as RelicData
			if relic != null and run_state.inventory.add_relic(relic):
				run_state.add_corruption(relic.corruption)
				hud.show_message("宝箱遗物：%s" % relic.display_name)
		_:
			run_state.add_pages(12)
			hud.show_message("宝箱：记忆碎片 +12")
	if _screen_fx != null:
		_screen_fx.flash(Color("f0c36c", 0.18), 0.24)
	if is_instance_valid(chest) and is_inside_tree():
		CombatFX.spawn(get_parent(), chest.global_position + Vector2(0, -22), &"cast", Color("f0c36c"), 1.0, 52)
		CombatFX.spawn(get_parent(), chest.global_position + Vector2(0, -16), &"ring", Color("f0c36c"), 1.0, 46)


func _try_open_shop() -> bool:
	for shop in _shops:
		if not is_instance_valid(shop):
			continue
		if player.global_position.distance_to(shop.global_position) < 120.0:
			_open_shop(shop)
			return true
	return false


func _open_shop(shop: MemoryShop) -> void:
	_active_shop = shop
	var key := shop.shop_id
	if not _shop_cache.has(key):
		_shop_cache[key] = RunLoot.shop_offers(run_state, _chapter, Flow.profile)
	_shop_ui.open_shop(_shop_cache[key], run_state.pages)
	get_tree().paused = true


func _on_shop_buy(index: int) -> void:
	if _active_shop == null:
		return
	var offers: Array[Dictionary] = _shop_cache.get(_active_shop.shop_id, [])
	if index < 0 or index >= offers.size():
		return
	var offer := offers[index]
	if bool(offer.get("bought", false)):
		return
	if not run_state.spend_pages(int(offer["cost"])):
		_shop_ui.show_error("残页不足。继续战斗，纸人会记得。")
		return
	_apply_reward(offer)
	_shop_ui.mark_bought(index, run_state.pages)
	_update_hud()


func _on_shop_closed() -> void:
	_active_shop = null
	get_tree().paused = false

func _claim_nearest_stele() -> void:
	for stele in _steles:
		if not is_instance_valid(stele) or stele.is_claimed:
			continue
		if player.global_position.distance_to(stele.global_position) < 110.0:
			var reward := stele.claim()
			if reward.is_empty():
				return
			var duplicate := false
			if reward["kind"] == &"relic" and reward.has("resource"):
				duplicate = run_state.inventory.has_relic((reward["resource"] as RelicData).id)
			elif reward["kind"] == &"word" and reward.has("resource"):
				duplicate = run_state.inventory.has_word((reward["resource"] as WordData).id)
			if duplicate:
				player.heal(25)
				run_state.restore_ink(30)
				hud.show_message("残碑已读过 · 恢复 25 生命与 30 墨量")
			else:
				_records += 1
				_apply_reward(reward)
				hud.show_message("记录 +1 · " + String(reward.get("title", "残碑")))
			return

func _on_player_health_changed(current: int, maximum: int) -> void:
	run_state.health = current
	run_state.max_health = maximum
	run_state.health_changed.emit(current, maximum)

func _on_player_died() -> void:
	if _authority.consume_revive():
		player.revive(50)
		var authority_name := run_state.authority.display_name if run_state.authority != null else "续命"
		hud.set_authority(authority_name, false)
		hud.show_message("续命生效 · 恢复 50 生命")
		return
	if relic_effects.has(&"revive_once") and not relic_effects.revive_used:
		relic_effects.revive_used = true
		player.revive(40)
		hud.show_message("不灭档案替你翻回上一页")
		return
	_screen_fx.flash(Color(0.6, 0.05, 0.08, 0.34), 0.4)
	_hit_stop.freeze(0.12, 0.15)
	_finish(false)

func _ended() -> bool:
	return _finished or _ending_pending

func _finish(won: bool, forced_ending: Dictionary = {}) -> void:
	if _finished or _ending_pending:
		return
	_ending_pending = true
	for hazard in get_tree().get_nodes_in_group("hostile_hazards"):
		hazard.queue_free()
	hud.hide_boss()
	await get_tree().create_timer(0.65, false).timeout
	if not is_inside_tree():
		return
	var ending := forced_ending if not forced_ending.is_empty() else CampaignData.ending_for(won, run_state.corruption, _mercy, _burned_final)
	_finished = true
	Flow.end_run(won)
	Flow.last_ending = ending
	if Flow.profile != null:
		Flow.profile.record_ending(ending["id"])
		Flow.profile.runs_completed += 1
		Flow.profile.records_found += _records
		if won and _chapter == 0:
			Flow.profile.demo_cleared = true
		Flow.save_profile()
	_close_overlay()
	Audio.stop_music(0.6)
	Audio.play_voice("ending_" + String(ending["id"]))
	get_tree().paused = true
	ending_screen.show_campaign_ending(won, Flow.last_reward, ending, _records, _kills, _chapter == 0)

func _return_to_hub() -> void:
	get_tree().paused = false
	Flow.return_to_hub()
	get_tree().change_scene_to_file("res://scenes/hub/hub.tscn")

func _update_boss_bar() -> void:
	if not is_instance_valid(_boss) or _boss.dead or _boss_bar_visible:
		return
	if _rooms.is_empty() or not _is_boss_room(_rooms.back()):
		return
	if not _rooms.back().is_locked():
		return
	var chapter := CampaignData.chapter(_chapter)
	hud.show_boss(chapter["boss_name"], _boss.health, _boss.max_health)
	_boss_bar_visible = true

func _update_hud() -> void:
	hud.set_stats(player.health, player.max_health, 0, _kills, run_state.pages)
	hud.set_active_weapon(player.active_weapon_slot)
