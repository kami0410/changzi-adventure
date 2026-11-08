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
	&"watcher_eye": preload("res://scenes/enemies/watcher_eye.tscn"),
	&"ink_wisp": preload("res://scenes/enemies/ink_wisp.tscn"),
	&"skull_lantern": preload("res://scenes/enemies/skull_lantern.tscn"),
	&"abyss_jelly": preload("res://scenes/enemies/abyss_jelly.tscn"),
	&"name_snake": preload("res://scenes/enemies/name_snake.tscn"),
	&"echo_bat": preload("res://scenes/enemies/echo_bat.tscn"),
}
## 0.15 creatures (CreatureArt), not part of the authored waves: each chapter
## mixes its own into ordinary encounters through EncounterVariation.
const CHAPTER_CREATURES: Array = [
	[&"ink_wisp", &"watcher_eye"],
	[&"skull_lantern", &"name_snake", &"ink_wisp"],
	[&"abyss_jelly", &"watcher_eye", &"echo_bat"],
	[&"skull_lantern", &"echo_bat", &"name_snake"],
]
const BOSS_SCENE = preload("res://scenes/bosses/ink_archivist.tscn")
const SMILING_SCENE = preload("res://scenes/bosses/smiling_archivist.tscn")
const READER_SCENE = preload("res://scenes/bosses/last_reader.tscn")
const PICKUP_SCENE = preload("res://scenes/combat/pickup.tscn")
const MDS_CHAPTER_SCENES: Array[PackedScene] = [
	preload("res://scenes/mds/chapter_1_world.tscn"),
	preload("res://scenes/mds/chapter_2_bigmap_world.tscn"),
	preload("res://scenes/mds/chapter_3_bigmap_world.tscn"),
	preload("res://scenes/mds/chapter_4_bigmap_world.tscn"),
]
const MDS_WORLD_FILES: Array[String] = [
	"res://scenes/mds/chapter_1.mdsworld.json",
	"res://scenes/mds/chapter_2_bigmap.mdsworld.json",
	"res://scenes/mds/chapter_3_bigmap.mdsworld.json",
	"res://scenes/mds/chapter_4_bigmap.mdsworld.json",
]
## Chapter plans are data-only for now: Chapter 1 drives its linear rooms and
## Chapters 2–4 drive the big-map regions. Empty entries keep the legacy
## defaults (CampaignData.rooms + ROOM_WAVES) for chapters without a plan.
const CHAPTER_PLAN_PATHS: Array[String] = [
	"res://resources/chapters/chapter_1_demo.tres",
	"res://resources/chapters/chapter_2_demo.tres",
	"res://resources/chapters/chapter_3_demo.tres",
	"res://resources/chapters/chapter_4_demo.tres",
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
	&"breath_hound": preload("res://assets/sprites/enemies/breath_hound.png"),
	&"lung_moth": preload("res://assets/sprites/enemies/lung_moth.png"),
	&"rust_whisperer": preload("res://assets/sprites/enemies/rust_whisperer.png"),
	&"collapse_husk": preload("res://assets/sprites/enemies/collapse_husk.png"),
}
## Empty since pass 78: the four Chapter 2 enemies that used to borrow Chapter 1
## paintings (and Chapter 3 reuses three of them) now own dedicated sprites.
## The table and its tint stay in place so a future enemy without art can fall
## back explicitly instead of rendering nothing.
const ENEMY_ART_FALLBACK: Dictionary = {}
## Tint applied only to Chapter 1 art reused by an enemy without its own
## sprite. Enemies wired into ENEMY_ART render at Color.WHITE.
const ENEMY_FALLBACK_TINT := Color("c8e1cd")
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
## `Time.get_ticks_msec()` of the last `room_loaded`. The MDS fade-in finishes
## after that signal, and a delayed required page must not take the screen while
## the fade still covers it.
var _room_loaded_msec := -100000
var _rooms: Array[ArenaRoom] = []
var _steles: Array[MemoryStele] = []
var _chests: Array[TreasureChest] = []
var _kills := 0
var _finished := false
var _ending_pending := false
## Set the moment a final death is committed, before the archive pick pauses the
## tree. Blocks checkpoints so closing the window mid-pick cannot revive the run.
var _death_committed := false
var _example_phrases: Array[ResolvedPhrase] = []
var _boss: InkArchivist
var _boss_bar_visible := false
var _authority := AuthorityController.new()
var _authority_choice: AuthorityChoiceUI
var _archive_choice: ArchiveChoiceUI
var _cleared_in_chapter := 0
var _help_ui: HelpUI
var _reward_ui: RewardChoice
var _reward_options: Array[Dictionary] = []
## True from the moment a room settles until its reward page is on screen. The
## page can wait out another modal or a transition, and a checkpoint written in
## that window would resume into a cleared room with the unchosen reward gone.
var _reward_pending := false
var _reward_room: ArenaRoom
var _overlay: Control
## Focus owner before the current overlay opened, restored on close when the
## control is still on screen.
var _overlay_return_focus: Control = null
## Settings opened from the pause menu goes back there instead of resuming
## play; remember the page and the pause-menu item that opened it.
var _pause_return_overlay: Control = null
var _pause_return_focus: Control = null
var _last_checkpoint := Vector2(120, 530)
var _story: StoryOverlay
var _shop_ui: RunShopUI
var _shops: Array[MemoryShop] = []
var _shop_cache: Dictionary = {}
var _active_shop: MemoryShop
var _mercy := 0
var _records := 0
var _burned_final := false
## Chapter index whose boss granted the authority currently held. A boss-death
## checkpoint is written before the pick, so on resume an authority inherited
## from an earlier chapter must not suppress this chapter's pick. `-1` means no
## authority has been granted yet.
var _authority_granted_chapter := -1
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
## Room-local y of the current room's fall plane. Authored per room/area from
## the chapter plan (or room metadata); the legacy 850 px rule when unspecified.
var _fall_limit_local := ChapterPlanData.DEFAULT_FALL_Y
## Cleared encounters, keyed by encounter id (`room/Arena`, `room/event`, or an
## authored id), so a big-map room can hold several encounters. The legacy
## dictionaries keep room-key checkpoints written before per-node ids readable.
var _cleared_encounters: Dictionary = {}
var _legacy_cleared_rooms: Dictionary = {}
var _discovered_vaults: Dictionary = {}
## Rest-room arrival flavour is display-only; one greeting per room per launch
## keeps backtracking from replaying the same toast.
var _rest_greeted: Dictionary = {}
## One-shot world pickups are remembered per chest/stele id so resume cannot
## duplicate a reward or reopen a chest, even with several in one room.
## `_legacy_*` holds room-key entries from checkpoints written before ids.
var _claimed_steles: Dictionary = {}
var _legacy_claimed_steles: Dictionary = {}
var _opened_chests: Dictionary = {}
var _legacy_opened_chests: Dictionary = {}
var _boss_defeated := false
var _boss_aftermath_started := false
## Validated checkpoint consumed by this launch; empty on a fresh run.
var _resume_data: Dictionary = {}
var _resume_restored := false
var _map_overlay: MapOverlay
var _archive_damage_multiplier := 1.0
const BOSS_MUSIC := "res://assets/audio/music/boss.ogg"
const CORRUPTION_FRENZY_SECONDS := 30.0
const CORRUPTION_FRENZY_HEALTH_RATIO := 0.4

func _ready() -> void:
	get_tree().paused = false
	var corrupt_resume := _prepare_resume()
	run_state = Flow.start_run(_resume_run_value("seed", 0))
	_authority = AuthorityController.new()
	run_state.corruption_gain_multiplier = Difficulty.corruption_multiplier(Flow.difficulty)
	_apply_archive_upgrades()
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	player.weapon_changed.connect(hud.set_active_weapon)
	if _resume_data.is_empty():
		_apply_npc_blessings()
		_populate_starter_inventory()
		_apply_stored_relics()
		_apply_archived_item()
	elif not _restore_run_save(_resume_data):
		# A structurally valid file can still name resources this build no
		# longer has. Never boot into a half-restored run.
		_resume_data = {}
		_apply_npc_blessings()
		_populate_starter_inventory()
		_apply_stored_relics()
		_apply_archived_item()
	relic_effects.run = run_state
	relic_effects.player = player
	hud.bind_run_state(run_state)
	run_state.corruption_tier_changed.connect(_on_corruption_tier_changed)
	_apply_corruption_penalties()
	_update_hud()
	hud.set_region("墨雨档案馆")
	hud.set_progress(0, _chapter_progress_total())
	hud.set_objective("找回失踪名册的第一页")
	inventory_ui.bind(run_state.inventory, run_state.run_seed)
	var persistent_phrases: Array[String] = []
	if Flow.profile != null:
		persistent_phrases = Flow.profile.discovered_phrases
	codex_ui.bind_state(resolver, run_state, _example_phrases, persistent_phrases)
	codex_ui.phrase_equip_requested.connect(_on_codex_equip)
	# Bind the sender: a page can close as a Settings subpage while another
	# overlay is on top, and that must not tear down the settings page too.
	inventory_ui.close_requested.connect(_close_overlay.bind(inventory_ui))
	codex_ui.close_requested.connect(_close_overlay.bind(codex_ui))
	settings_menu.closed.connect(_close_overlay.bind(settings_menu))
	_help_ui = HelpUI.new()
	$UI.add_child(_help_ui)
	_help_ui.closed.connect(_close_overlay.bind(_help_ui))
	pause_menu.managed = true
	(pause_menu.find_child("QuitButton", true, false) as Button).text = "返回档案馆"
	pause_menu.pause_requested.connect(_toggle_pause)
	pause_menu.settings_requested.connect(_on_pause_settings)
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
	_archive_choice = ArchiveChoiceUI.new()
	$UI.add_child(_archive_choice)
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
	player.perfect_dodged.connect(_on_perfect_dodge)
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
	_start_chapter.call_deferred(_resume_run_value("chapter", 0))
	if corrupt_resume:
		hud.show_message.call_deferred("局内存档损坏，已丢弃；开始新的一局")

## Reads the checkpoint requested by the title screen once. Returns true when a
## save existed but had to be discarded, so the HUD can say so instead of
## silently starting over.
func _prepare_resume() -> bool:
	if Flow == null or not Flow.resume_requested:
		return false
	Flow.resume_requested = false
	var had_save := RunSave.has_save(Flow.run_save_path)
	_resume_data = RunSave.read(Flow.run_save_path)
	if _resume_data.is_empty():
		return had_save
	var run: Dictionary = _resume_data.get("run", {})
	Flow.difficulty = clampi(int(run.get("difficulty", Flow.difficulty)), 0, Difficulty.count() - 1)
	return false


func _resume_run_value(key: String, fallback: int) -> int:
	if _resume_data.is_empty():
		return fallback
	var run: Dictionary = _resume_data.get("run", {})
	return int(run.get(key, fallback))


func _restore_run_save(data: Dictionary) -> bool:
	var run: Dictionary = data.get("run", {})
	var inventory: Dictionary = data.get("inventory", {})
	if run.is_empty() or inventory.is_empty():
		return false
	_resume_restored = true
	run_state.run_seed = int(run.get("seed", run_state.run_seed))
	run_state.rng.seed = run_state.run_seed
	if run.has("rng_state"):
		run_state.rng.state = int(run["rng_state"])
	run_state.pages = maxi(0, int(run.get("pages", 0)))
	run_state.max_ink = maxi(1, int(run.get("max_ink", run_state.max_ink)))
	run_state.ink = clampi(int(run.get("ink", run_state.ink)), 0, run_state.max_ink)
	run_state.set_corruption(int(run.get("corruption", 0)))
	run_state.corruption_gain_multiplier = maxf(float(run.get("corruption_gain_multiplier", 1.0)), 0.01)
	player.max_health = maxi(1, int(run.get("max_health", player.max_health)))
	player.health = clampi(int(run.get("health", player.health)), 0, player.max_health)
	run_state.max_health = player.max_health
	run_state.health = player.health
	player.health_changed.emit(player.health, player.max_health)
	run_state.ink_changed.emit(run_state.ink)
	run_state.pages_changed.emit(run_state.pages)
	_kills = maxi(0, int(run.get("kills", 0)))
	_mercy = int(run.get("mercy", 0))
	_records = maxi(0, int(run.get("records", 0)))
	_burned_final = bool(run.get("burned_final", false))
	_chapter = clampi(int(run.get("chapter", 0)), 0, CampaignData.chapter_count() - 1)
	_restore_room_progress(data)
	_restore_inventory(inventory)
	_restore_example_phrases(data.get("world", {}).get("example_phrases", []))
	_restore_authority(data.get("authority", {}))
	var world: Dictionary = data.get("world", {})
	_restore_shop_cache(world.get("shops", {}))
	_restore_frenzy(world.get("frenzy", {}))
	# The 不朽档案 revive is once per *run*, not once per session. Its spent flag
	# lives on RelicEffects, so a checkpoint taken after the relic already saved
	# the player used to boot with the revive re-armed and it fired a second
	# time. Old checkpoints have no key: false keeps their previous behaviour.
	relic_effects.revive_used = bool(world.get("relic_revive_used", false))
	return true


func _restore_room_progress(data: Dictionary) -> void:
	var progress: Dictionary = data.get("progress", {})
	_cleared_in_chapter = maxi(0, int(progress.get("cleared_in_chapter", 0)))
	_cleared_encounters.clear()
	for id in progress.get("cleared_encounters", []):
		_cleared_encounters[String(id)] = true
	# Older checkpoints only recorded the room id; keep them readable as a
	# room-wide fallback instead of dropping progress or rejecting the file.
	_legacy_cleared_rooms.clear()
	for room_id in progress.get("cleared_rooms", []):
		_legacy_cleared_rooms[String(room_id)] = true
	_discovered_vaults.clear()
	for room_id in progress.get("vaults", []):
		_discovered_vaults[String(room_id)] = true
	var world: Dictionary = data.get("world", {})
	_claimed_steles.clear()
	for id in world.get("claimed_stele_ids", []):
		_claimed_steles[String(id)] = true
	_legacy_claimed_steles.clear()
	for room_id in world.get("claimed_steles", []):
		_legacy_claimed_steles[String(room_id)] = true
	_opened_chests.clear()
	for id in world.get("opened_chest_ids", []):
		_opened_chests[String(id)] = true
	_legacy_opened_chests.clear()
	for room_id in world.get("opened_chests", []):
		_legacy_opened_chests[String(room_id)] = true
	_boss_defeated = bool(world.get("boss_defeated", false))
	_boss_aftermath_started = false


func _restore_inventory(data: Dictionary) -> void:
	for entry in data.get("words", []):
		if not entry is Dictionary:
			continue
		var word := RunSave.word_from_dict(entry)
		if word != null:
			run_state.inventory.add_word(word)
	var phrases: Array = data.get("phrases", [])
	for slot in mini(phrases.size(), Inventory.MAX_PHRASES):
		var phrase := RunSave.phrase_from_dict(phrases[slot], resolver)
		if phrase != null:
			run_state.inventory.equip_phrase(slot, phrase)
	var weapons: Array = data.get("weapons", [])
	for slot in mini(weapons.size(), Inventory.MAX_WEAPONS):
		if not weapons[slot] is Dictionary:
			continue
		var weapon := _weapon_from_save(weapons[slot])
		if weapon != null:
			_equip_weapon(slot, weapon)
	for id in data.get("relics", []):
		var relic := ContentLibrary.relic_by_id(StringName(id))
		if relic != null:
			run_state.inventory.add_relic(relic)


func _weapon_from_save(data: Dictionary) -> WeaponData:
	var base := ContentLibrary.weapon_by_id(StringName(data.get("id", "")))
	if base == null:
		return null
	var weapon := base.duplicate() as WeaponData
	weapon.damage = maxi(1, int(data.get("damage", weapon.damage)))
	var display_name := String(data.get("display_name", ""))
	if not display_name.is_empty():
		weapon.display_name = display_name
	return weapon


func _restore_example_phrases(entries: Array) -> void:
	_example_phrases.clear()
	for entry in entries:
		if not entry is Dictionary:
			continue
		var phrase := RunSave.phrase_from_dict(entry, resolver)
		if phrase != null:
			_example_phrases.append(phrase)


func _restore_authority(data: Dictionary) -> void:
	var id := StringName(String(data.get("id", "")))
	if id == &"":
		return
	var authority := ContentLibrary.authority_by_id(id)
	if authority == null:
		return
	_authority.apply(authority, run_state)
	_authority.revive_used = bool(data.get("revive_used", false))
	_authority.rewrite_used = bool(data.get("rewrite_used", false))
	_authority.archive_used = bool(data.get("archive_used", false))
	# Old checkpoints predate the key: treating the authority as granted in the
	# saved chapter keeps them from reopening a pick that already happened. The
	# saved chapter is read from the checkpoint itself because this runs in
	# `_ready`, before `_start_chapter` applies it to `_chapter`.
	_authority_granted_chapter = int(data.get("chapter", _resume_run_value("chapter", _chapter)))
	hud.set_authority(authority.display_name, _authority.can_use())


func _restore_frenzy(data: Dictionary) -> void:
	if data.is_empty() or not bool(data.get("active", false)):
		return
	_frenzy_left = maxf(float(data.get("left", 0.0)), 0.0)
	if _frenzy_left <= 0.0:
		return
	_frenzy_active = true
	_frenzy_saved_max_health = int(data.get("saved_max_health", 0))
	_frenzy_saved_health = int(data.get("saved_health", 0))
	_frenzy_cap = int(data.get("cap", 0))
	_frenzy_last_seconds = -1
	hud.set_frenzy(int(ceilf(_frenzy_left)))


func _serialize_shop_cache() -> Dictionary:
	var result: Dictionary = {}
	for key in _shop_cache:
		var offers: Array = _shop_cache[key]
		var entries: Array = []
		for offer in offers:
			if not offer is Dictionary:
				continue
			var entry: Dictionary = (offer as Dictionary).duplicate()
			var resource: Resource = entry.get("resource", null) as Resource
			entry["resource_id"] = String(resource.id) if resource != null else ""
			entry.erase("resource")
			entries.append(entry)
		result[String(key)] = entries
	return result


func _restore_shop_cache(data: Dictionary) -> void:
	_shop_cache.clear()
	for key in data:
		var entries: Array[Dictionary] = []
		for raw in data[key]:
			if not raw is Dictionary:
				continue
			var entry: Dictionary = (raw as Dictionary).duplicate()
			var resource_id := StringName(String(entry.get("resource_id", "")))
			entry.erase("resource_id")
			match StringName(entry.get("kind", &"")):
				&"relic":
					entry["resource"] = ContentLibrary.relic_by_id(resource_id)
				&"weapon":
					entry["resource"] = ContentLibrary.weapon_by_id(resource_id)
				&"word":
					var source := ContentLibrary.word_by_id(resource_id)
					entry["resource"] = WordRuntime.for_run(source, Flow.profile) if source != null else null
				_:
					pass
			entries.append(entry)
		_shop_cache[StringName(key)] = entries


func _build_run_save() -> Dictionary:
	var weapons: Array = [null, null]
	for slot in run_state.inventory.weapons.size():
		var weapon := run_state.inventory.weapons[slot]
		if weapon != null:
			weapons[slot] = {
				"id": String(weapon.id),
				"damage": weapon.damage,
				"display_name": weapon.display_name,
			}
	var phrases: Array = [{}, {}]
	for slot in run_state.inventory.phrases.size():
		var phrase := run_state.inventory.phrases[slot]
		if phrase != null:
			phrases[slot] = RunSave.phrase_to_dict(phrase)
	var words: Array = []
	for word in run_state.inventory.words:
		var entry := RunSave.word_to_dict(word)
		if not entry.is_empty():
			words.append(entry)
	var relics: Array = []
	for relic in run_state.inventory.relics:
		relics.append(String(relic.id))
	var authority: Dictionary = {}
	var active_authority := run_state.authority if run_state.authority != null else _authority.authority
	if active_authority != null:
		authority = {
			"id": String(active_authority.id),
			"revive_used": _authority.revive_used,
			"rewrite_used": _authority.rewrite_used,
			"archive_used": _authority.archive_used,
			# Which chapter's boss handed this authority over. It separates "the
			# pick for this chapter already happened" from "this is last
			# chapter's authority, the new pick is still owed" when a boss-death
			# checkpoint is resumed. Old saves lack the key and are treated as
			# granted in their own chapter (the pre-existing behaviour).
			"chapter": _authority_granted_chapter,
		}
	var examples: Array = []
	for phrase in _example_phrases:
		var entry := RunSave.phrase_to_dict(phrase)
		if not entry.is_empty():
			examples.append(entry)
	return {
		"version": RunSave.SAVE_VERSION,
		"run": {
			"seed": run_state.run_seed,
			"rng_state": run_state.rng.state,
			"difficulty": Flow.difficulty,
			"chapter": _chapter,
			"room": _mds_world.current_room if _mds_world != null and is_instance_valid(_mds_world) else "",
			"health": player.health,
			"max_health": player.max_health,
			"ink": run_state.ink,
			"max_ink": run_state.max_ink,
			"corruption": run_state.corruption,
			"corruption_gain_multiplier": run_state.corruption_gain_multiplier,
			"pages": run_state.pages,
			"kills": _kills,
			"mercy": _mercy,
			"records": _records,
			"burned_final": _burned_final,
		},
		"progress": {
			"cleared_in_chapter": _cleared_in_chapter,
			"cleared_encounters": _cleared_encounters.keys(),
			# Legacy room-key view: only carried over from older checkpoints,
			# never derived from partial per-node progress (that would make a
			# resumed multi-content room treat every prop as consumed).
			"cleared_rooms": _legacy_cleared_rooms.keys(),
			"vaults": _discovered_vaults.keys(),
		},
		"inventory": {
			"words": words,
			"weapons": weapons,
			"relics": relics,
			"phrases": phrases,
		},
		"authority": authority,
		"world": {
			"claimed_stele_ids": _claimed_steles.keys(),
			"claimed_steles": _legacy_claimed_steles.keys(),
			"opened_chest_ids": _opened_chests.keys(),
			"opened_chests": _legacy_opened_chests.keys(),
			"boss_defeated": _boss_defeated,
			"relic_revive_used": relic_effects.revive_used,
			"shops": _serialize_shop_cache(),
			"frenzy": {
				"active": _frenzy_active,
				"left": _frenzy_left,
				"saved_max_health": _frenzy_saved_max_health,
				"saved_health": _frenzy_saved_health,
				"cap": _frenzy_cap,
			},
			"example_phrases": examples,
		},
		"mds": _mds_world.get_save_data() if _mds_world != null and is_instance_valid(_mds_world) else {},
	}


## Persist the active run. Called on room entry, after rewards/events/shops and
## on window close; never while dead, finished, or watching an ending.
func save_run_now() -> bool:
	if Flow == null or not Flow.auto_save or run_state == null:
		return false
	if _finished or _ending_pending or _death_committed:
		return false
	if _reward_pending or (_reward_ui != null and _reward_ui.visible):
		# The room is marked cleared before the choice opens. Writing now would
		# resume into a cleared room with the unchosen reward gone; keep the
		# previous checkpoint so quitting at the reward screen only replays it.
		return false
	if not _mds_active or _mds_world == null or _mds_world.current_room.is_empty():
		return false
	return RunSave.write(_build_run_save(), Flow.run_save_path)


func save_run_on_exit() -> void:
	# Word mastery and mid-run decodes live on Profile; save them even when the
	# run checkpoint itself is intentionally skipped (e.g. reward screen).
	if Flow != null and Flow.auto_save:
		Flow.save_profile()
	save_run_now()


## HUD hides under any modal page so the page is the only thing to read.
func _sync_hud_visibility() -> void:
	var modal: bool = _overlay != null or pause_menu.is_open() or _story.is_open() 		or (_reward_ui != null and _reward_ui.visible) or (_shop_ui != null and _shop_ui.visible) 		or (_map_overlay != null and _map_overlay.is_open()) or ending_screen.visible 		or (_archive_choice != null and _archive_choice.is_open()) \
		or (_authority_choice != null and _authority_choice.is_open())
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
	var authority_damage := _authority.damage_multiplier(run_state)
	phrase_caster.damage_scale = 3.0 * relic_effects.damage_scale() * _archive_damage_multiplier * authority_damage
	player.damage_dealt_multiplier = authority_damage
	phrase_caster.tick(delta)
	if Input.is_action_just_pressed("cast_1"):
		_try_cast(0)
	if Input.is_action_just_pressed("cast_2"):
		_try_cast(1)
	if Input.is_action_just_pressed("interact"):
		if not _try_open_shop() and not _try_open_chest() and not _try_pickup_nearest() \
				and not _try_call_elevator() and not _try_use_bench():
			_claim_nearest_stele()
	if not _mds_active:
		var left := _chapter_level().position.x
		player.position.x = clampf(player.position.x, left + 30.0, left + CHAPTER_WIDTH - 30.0)
	# MDS rooms sit at absolute world coordinates (the hidden vault is one room
	# below the main path), so the fall guard has to compare the room-local Y:
	# checking the world Y would pin the player to the vault door and damage them
	# every invulnerability window. The limit itself is per room/area so a
	# multi-screen room can be taller than the legacy 850 px without killing the
	# player in its lower half.
	var fall_y := player.position.y
	if _mds_active and _mds_world != null and not _mds_world.current_room.is_empty():
		fall_y = player.global_position.y - _mds_world.world.get_origin(_mds_world.current_room).y
	if fall_y > _fall_limit_local:
		player.position = _last_checkpoint
		player.velocity = Vector2.ZERO
		# A checkpoint may sit on a collapsing platform; restore every platform
		# in the group before the player lands back on it.
		_reset_collapsing_platforms()
		# A fall is not a dodgeable hit: end any roll so it cannot count as a
		# perfect dodge and cancel the fall damage.
		player.cancel_dodge()
		player.take_damage(15)
		VFX.spawn(player.get_parent(), &"respawn", player.global_position + Vector2(0, Player.FOOT_Y))

func _input(event: InputEvent) -> void:
	# The keybind page owns every press until it commits or cancels.
	if Flow.input_capture_active:
		return
	if _finished or _ending_pending:
		return
	# The boss authority pick is a required modal that owns its own pause. A
	# pause press must not resume the world underneath it or open the pause
	# menu on top of the choice.
	if _authority_choice != null and _authority_choice.is_open():
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
		return
	# The death archive pick is also mandatory; B/Esc must not close it or open
	# the pause menu underneath the death settlement.
	if _archive_choice != null and _archive_choice.is_open():
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
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
			if not _close_settings_subpage():
				_close_overlay()
		else:
			_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	# While paused, D-pad/face-button shortcuts belong to the pause menu's
	# focus navigation, not to gameplay overlays.
	if pause_menu.is_open():
		return
	if event.is_action_pressed("ui_cancel") and _overlay != null:
		if not _close_settings_subpage():
			_close_overlay()
		get_viewport().set_input_as_handled()
		return
	# Controller shortcuts share the D-pad with menu focus; when a page is open
	# the D-pad must move focus instead of opening another page.
	if _overlay != null and not event is InputEventKey:
		return
	if event.is_action_pressed("map"):
		# The map owns its own pause rather than living on the overlay stack;
		# opening it above a modal page would let closing the map resume the
		# world with the page still visible. Modal pages keep M inert.
		if _overlay != null:
			return
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
		# One press closes a Settings subpage first, matching B/Esc and the Hub.
		if not _close_settings_subpage():
			_toggle_overlay(settings_menu)
	elif event.is_action_pressed("help"):
		_toggle_overlay(_help_ui)
	else:
		return
	get_viewport().set_input_as_handled()

# NOTE: audio deliberately outlives this scene. AudioManager (autoload) owns
# music/voice and shuts them down from its own _exit_tree at engine teardown;
# stopping them here races the audio thread and leaks Ogg playback objects.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree():
		if not _ended() and not get_tree().paused and pause_menu != null:
			save_run_now()
			pause_menu.open_pause()


func _toggle_pause() -> void:
	if _finished or _ending_pending or (_reward_ui != null and _reward_ui.visible):
		return
	if _authority_choice != null and _authority_choice.is_open():
		return
	if _archive_choice != null and _archive_choice.is_open():
		return
	pause_menu.toggle()
	if pause_menu.is_open():
		save_run_now()


func _on_pause_settings() -> void:
	if pause_menu.is_open():
		# Closing Settings must land back on the pause menu, still paused, with
		# focus on the item that opened it.
		var viewport := get_viewport()
		_pause_return_overlay = settings_menu
		_pause_return_focus = viewport.gui_get_focus_owner() if viewport != null else null
		pause_menu.toggle()
	_toggle_overlay(settings_menu)

## Settings hosts AI/keybind/help on the ModalLayer. B/Esc must close that top
## page first instead of dropping the whole settings overlay (and the pause).
func _close_settings_subpage() -> bool:
	return _overlay == settings_menu and settings_menu.close_subpage()


func _toggle_overlay(overlay: Control) -> void:
	if _overlay == overlay:
		_close_overlay()
		return
	if pause_menu.is_open():
		pause_menu.toggle()
	if _overlay == null:
		var viewport := get_viewport()
		_overlay_return_focus = viewport.gui_get_focus_owner() if viewport != null else null
	else:
		# Settings owns its subpages; hide them with it instead of leaving a
		# modal page stranded above the replacement.
		if _overlay == settings_menu:
			settings_menu.close_subpages()
		_overlay.hide()
		# Another page replaced it, so the pause-return path no longer applies.
		_pause_return_overlay = null
		_pause_return_focus = null
	_overlay = overlay
	_overlay.show()
	get_tree().paused = true
	_focus_overlay_entry()

## Give the page a usable starting focus: the codex offers its first word,
## other pages the first button that is not disabled.
func _focus_overlay_entry() -> void:
	if _overlay == null:
		return
	if _overlay.has_method("focus_entry"):
		_overlay.call("focus_entry")
		return
	var first := GameFlow.first_pressable_button(_overlay)
	if first != null:
		first.grab_focus()

func _close_overlay(overlay: Control = null) -> void:
	# A bound sender only reports its own close; ignore it when another page
	# (e.g. Settings hosting Help) is still the active overlay.
	if overlay != null and _overlay != overlay:
		return
	var return_to_pause := _overlay != null and _overlay == _pause_return_overlay
	var pause_focus := _pause_return_focus
	_pause_return_overlay = null
	_pause_return_focus = null
	if _overlay != null:
		if _overlay == settings_menu:
			settings_menu.close_subpages()
		_overlay.hide()
		_overlay = null
	var previous := _overlay_return_focus
	_overlay_return_focus = null
	if return_to_pause:
		# Keep the game paused and reopen the pause menu; open_pause() gives the
		# page a fallback focus (Resume) when the original item is gone.
		pause_menu.open_pause()
		if pause_focus != null and is_instance_valid(pause_focus) and pause_focus.is_inside_tree() and pause_focus.is_visible_in_tree():
			pause_focus.grab_focus()
		return
	if previous != null and is_instance_valid(previous) and previous.is_inside_tree() and previous.is_visible_in_tree():
		previous.grab_focus()
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
	# Trust tiers add pages from every NPC, on top of the one-shot 言灵 bonuses
	# but under the same cap, so tier income cannot outgrow the authored path.
	var start_pages := mini(
		int(round(float(pending.get("start_pages", 0.0)))) + TrustData.start_pages(Flow.profile), 20)
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


## 归档 authority: one item carried through death arrives at the next fresh
## run. A weapon replaces the starting blade; a relic joins the inventory.
func _apply_archived_item() -> void:
	if Flow.profile == null or run_state == null:
		return
	var item := Flow.profile.consume_archived_item()
	if item.is_empty():
		return
	var kind := String(item.get("kind", ""))
	var id := StringName(String(item.get("id", "")))
	if kind == "weapon":
		var base := ContentLibrary.weapon_by_id(id)
		if base == null:
			return
		var weapon := RunLoot.weapon_for_run(base, Flow.profile)
		_equip_weapon(0, weapon)
		hud.show_message("归档：" + weapon.display_name + " 已替换起始武器")
	elif kind == "relic":
		var relic := ContentLibrary.relic_by_id(id)
		if relic == null:
			return
		if run_state.inventory.add_relic(relic):
			run_state.add_corruption(relic.corruption)
			hud.show_message("归档：" + relic.display_name + " 已放进背包")
		else:
			hud.show_message("归档：" + relic.display_name + " 已在背包里")
	if Flow.auto_save:
		Flow.save_profile()


## Items the 归档 authority may preserve. The two weapons every run starts with
## are skipped: archiving them would not change the next run's opening hand.
func _archive_offers() -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	if run_state == null or run_state.inventory == null:
		return offers
	var starter_ids: Dictionary = {}
	if player != null and player.starter_weapon != null:
		starter_ids[player.starter_weapon.id] = true
	starter_ids[SECOND_WEAPON.id] = true
	var seen: Dictionary = {}
	for weapon in run_state.inventory.weapons:
		if weapon == null or starter_ids.has(weapon.id) or seen.has(weapon.id):
			continue
		seen[weapon.id] = true
		offers.append({
			"kind": &"weapon",
			"id": weapon.id,
			"name": weapon.display_name,
			"desc": "武器 · 伤害 %d · 间隔 %.2f 秒" % [weapon.damage, weapon.attack_cooldown],
		})
	for relic in run_state.inventory.relics:
		if relic == null:
			continue
		offers.append({
			"kind": &"relic",
			"id": relic.id,
			"name": relic.display_name,
			"desc": "遗物 · " + RelicEffects.describe(relic.effect_id),
		})
	return offers


## Final death with 归档: ask before the result page. The checkpoint is already
## gone, so quitting during this pick cannot restore the dead run.
func _offer_archive_on_death() -> void:
	var offers := _archive_offers()
	if offers.is_empty():
		return
	if not _authority.consume_archive():
		return
	var authority_name := run_state.authority.display_name if run_state.authority != null else "归档"
	hud.set_authority(authority_name, _authority.can_use())
	_archive_choice.open(offers)
	# The tree is paused now, so _process (and its HUD sync) will not run until
	# the pick closes; hide the HUD explicitly or it stays on top of the modal.
	_sync_hud_visibility()
	var index: int = await _archive_choice.chosen
	if not is_inside_tree():
		return
	if index < 0 or index >= offers.size() or Flow.profile == null:
		return
	var entry: Dictionary = offers[index]
	if Flow.profile.store_archived_item(entry["kind"], entry["id"]):
		if Flow.auto_save:
			Flow.save_profile()
		hud.show_message("归档：%s 将随下一局醒来" % String(entry.get("name", "物品")))


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


## Off switch for scripted checks that need the authored waves verbatim.
var encounter_variation_enabled := true
## Variation rolled for the arena being populated (see EncounterVariation).
var _last_variation: Dictionary = {}

func _populate_room(room: ArenaRoom, ids: Array, wave_ids: Array = []) -> void:
	var variation := _roll_variation(room, ids, wave_ids)
	_last_variation = variation
	var first: Array = variation.get("first", ids)
	var rest: Array = variation.get("rest", wave_ids)
	if _roaming_for(room):
		# Dead Cells-style: the whole encounter is already in the region,
		# spread over its floors and ledges, wandering until it notices you.
		var everyone: Array = first + rest
		_spawn_group(room, everyone, -140.0, variation, 0, _roaming_spots(room, everyone.size()))
		room.start_roaming()
		var roaming_root := room.get_node_or_null(ArenaRoom.ENEMIES_NODE)
		if roaming_root != null:
			roaming_root.process_mode = Node.PROCESS_MODE_PAUSABLE
		var roaming_modifier: StringName = variation.get("modifier", EncounterVariation.NONE)
		if roaming_modifier != EncounterVariation.NONE and hud != null:
			hud.show_message(EncounterVariation.modifier_hint(roaming_modifier))
		return
	_spawn_group(room, first, -140.0, variation, 0)
	if not rest.is_empty():
		var base := first.size()
		room.queue_wave(func(): _spawn_group(room, rest, -110.0, variation, base))
	var modifier: StringName = variation.get("modifier", EncounterVariation.NONE)
	if modifier != EncounterVariation.NONE and hud != null:
		hud.show_message(EncounterVariation.modifier_hint(modifier))


func _roll_variation(room: ArenaRoom, ids: Array, wave_ids: Array) -> Dictionary:
	if not encounter_variation_enabled or not Flow.encounter_variation \
			or run_state == null or run_state.run_seed == 0:
		return {}
	var key := "%d/%s" % [_chapter, String(room.get_meta(&"encounter_id", room.name))]
	var chapter_index := clampi(_chapter, 0, ROOM_WAVES.size() - 1)
	var pool := EncounterVariation.roster(ROOM_WAVES[chapter_index])
	var usable: Array[StringName] = []
	for id in pool:
		if ENEMY_SCENES.has(id):
			usable.append(id)
	var featured: Array[StringName] = []
	for id in CHAPTER_CREATURES[chapter_index]:
		if ENEMY_SCENES.has(id):
			featured.append(id)
	return EncounterVariation.roll(ids, wave_ids, usable, run_state.run_seed, key, _chapter, featured)


## Legacy linear arenas sit 250 px above their ground and keep the historical
## spawn offset. Big-map arenas are anchored on the walkable surface, so their
## enemies spawn just above the arena origin instead of 250 px underground.
func _enemy_spawn_y() -> float:
	if _chapter_plan != null and _chapter_plan.big_map:
		return -ENEMY_FOOT_Y - 2.0
	return 250.0


## Roaming applies to ordinary fights in a live run; elite and boss arenas keep
## the locked showdown.
## Objective line for a region whose fights are roaming: the live total.
func _refresh_roaming_objective() -> void:
	var alive := 0
	var any := false
	for room in _rooms:
		if is_instance_valid(room) and room.roaming and not room.is_cleared():
			any = true
			alive += room.enemy_count()
	if any and alive > 0:
		hud.set_objective("游荡的敌人 · 还剩 %d" % alive)


func _roaming_for(room: ArenaRoom) -> bool:
	if not Flow.roaming_encounters or run_state == null or not _mds_active:
		return false
	if _is_boss_room(room):
		return false
	var room_type := String(_current_plan_room().get("type", ""))
	return room_type != "elite" and room_type != "boss"


## Global feet positions for a roaming encounter: sampled along the region's
## floors and ledges, away from the player's arrival and the gates, biased to
## the arena's part of the region, then spread with farthest-point sampling.
func _roaming_spots(room: ArenaRoom, count: int) -> Array:
	var spots: Array = []
	if count <= 0 or _mds_world == null or not is_instance_valid(_mds_world.room_node):
		return spots
	var room_node := _mds_world.room_node as Node2D
	var surfaces: Array[Rect2] = []
	if room_node is MDSBigRoom:
		var big := room_node as MDSBigRoom
		for rect in big.built_ground_surfaces + big.built_platform_surfaces:
			surfaces.append(Rect2(room_node.to_global(rect.position), rect.size))
	elif room_node is MDSChapterRoom:
		var chapter_room := room_node as MDSChapterRoom
		surfaces.append(Rect2(room_node.to_global(Vector2(40, MDSChapterRoom.FLOOR_Y)), Vector2(1200, 16)))
		var layout := chapter_room._active_layout()
		if layout != null:
			for spec in chapter_room._platform_specs(layout):
				surfaces.append(Rect2(room_node.to_global(Vector2(float(spec[0]) - 110.0,
					float(spec[1]) * MDSChapterRoom.TILE_SIZE)), Vector2(220, 16)))
	var gates: Array[Vector2] = []
	for gate in room_node.find_children("*", "MDSGate", true, false):
		gates.append((gate as Node2D).global_position)
	var candidates: Array[Vector2] = []
	for rect in surfaces:
		var x := rect.position.x + 48.0
		while x <= rect.end.x - 48.0:
			var point := Vector2(x, rect.position.y)
			var clear := point.distance_to(player.global_position) > 420.0
			for gate in gates:
				if point.distance_to(gate) < 170.0:
					clear = false
			if clear:
				candidates.append(point)
			x += 56.0
	var near: Array[Vector2] = []
	for point in candidates:
		if point.distance_to(room.global_position) < 1100.0:
			near.append(point)
	if near.size() >= count * 2:
		candidates = near
	if candidates.is_empty():
		return spots
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("roam|%d|%s" % [run_state.run_seed, String(room.get_meta(&"encounter_id", room.name))])
	spots.append(candidates[rng.randi_range(0, candidates.size() - 1)])
	while spots.size() < count:
		var best := candidates[0]
		var best_score := -1.0
		for point in candidates:
			var nearest := INF
			for chosen in spots:
				nearest = minf(nearest, point.distance_to(chosen))
			var score := nearest + rng.randf() * 40.0
			if score > best_score:
				best_score = score
				best = point
		spots.append(best)
	return spots


func _spawn_group(room: ArenaRoom, ids: Array, start_offset: float,
		variation: Dictionary = {}, base_index: int = 0, spots: Array = []) -> void:
	var offset := start_offset
	var spawn_y := _enemy_spawn_y()
	var modifier: StringName = variation.get("modifier", EncounterVariation.NONE)
	var index := -1
	for id in ids:
		index += 1
		if not ENEMY_SCENES.has(id):
			continue
		var at_x := offset
		if not variation.is_empty():
			at_x = clampf(EncounterVariation.spawn_offset(variation, index,
				start_offset + 140.0), -480.0, 480.0)
		var local := Vector2(at_x, spawn_y)
		var roaming := index < spots.size()
		if roaming:
			local = room.to_local((spots[index] as Vector2) - Vector2(0, ENEMY_FOOT_Y + 2.0))
		var enemy := room.spawn_enemy(ENEMY_SCENES[id], local) as Enemy
		if enemy == null:
			continue
		if not roaming:
			VFX.spawn(enemy.get_parent(), &"enemy_spawn", enemy.global_position + Vector2(0, ENEMY_FOOT_Y))
		if CreatureArt.has(id):
			_apply_creature_art(enemy, id)
		else:
			var art_id: StringName = ENEMY_ART_FALLBACK.get(id, id)
			var tint := ENEMY_FALLBACK_TINT if ENEMY_ART_FALLBACK.has(id) else Color.WHITE
			_apply_art(enemy, ENEMY_ART[art_id], float(ENEMY_ART_SCALE.get(id, 1.0)), tint)
		var health_scale := Difficulty.enemy_health(Flow.difficulty) * chapter_health_scale(_chapter)
		var damage_scale := chapter_damage_scale(_chapter)
		var speed_scale := 1.0
		var elite := modifier == EncounterVariation.ELITE \
			and int(variation.get("elite", -1)) == base_index + index
		if elite:
			health_scale *= EncounterVariation.ELITE_HEALTH
			damage_scale = EncounterVariation.ELITE_DAMAGE
			speed_scale = 1.1
		elif modifier == EncounterVariation.SWIFT:
			speed_scale = EncounterVariation.SWIFT_SPEED
		elif modifier == EncounterVariation.HORDE:
			health_scale *= EncounterVariation.HORDE_HEALTH
		if not is_equal_approx(health_scale, 1.0) or not is_equal_approx(damage_scale, 1.0) \
				or not is_equal_approx(speed_scale, 1.0):
			var scaled := enemy.data.duplicate() as EnemyData
			scaled.max_health = maxi(int(round(scaled.max_health * health_scale)), 1)
			scaled.contact_damage = maxi(int(round(scaled.contact_damage * damage_scale)), 1)
			scaled.speed *= speed_scale
			enemy.data = scaled
		if elite:
			enemy.set_meta(&"elite", true)
			if enemy.sprite_visual != null:
				enemy.sprite_base_modulate = EncounterVariation.ELITE_TINT
				enemy.sprite_visual.modulate = EncounterVariation.ELITE_TINT
		elif modifier == EncounterVariation.SWIFT:
			enemy.attack_cooldown *= 0.85
		enemy.deaggro_range = 1150
		enemy.aggro_range = 600
		if roaming:
			# Wanders around its spot and only notices a player who comes close
			# on roughly the same level; fliers perch above their floor.
			if not enemy.apply_gravity:
				enemy.position.y -= 130.0
			enemy.home = enemy.global_position
			enemy.patrol_radius = randf_range(90.0, 170.0)
			enemy.aggro_range = 430.0
			enemy.aggro_vertical = 240.0
			enemy.deaggro_range = 900.0
		enemy.set_target(player)
		enemy.died.connect(_on_enemy_died)
		enemy.damaged.connect(relic_effects.on_damage)
		offset += 150

## Ordinary enemies reuse the same EnemyData in every chapter while the
## player keeps collecting weapons, relics and authorities, so later chapters
## went soft. Each chapter past the first adds health and contact damage
## (bosses already scale through CampaignData).
const CHAPTER_HEALTH_STEP := 0.35
const CHAPTER_DAMAGE_STEP := 0.15


static func chapter_health_scale(chapter_index: int) -> float:
	return 1.0 + CHAPTER_HEALTH_STEP * float(clampi(chapter_index, 0, 3))


static func chapter_damage_scale(chapter_index: int) -> float:
	return 1.0 + CHAPTER_DAMAGE_STEP * float(clampi(chapter_index, 0, 3))


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
	var boss := room.spawn_enemy(scene, Vector2(110, _enemy_spawn_y())) as InkArchivist
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

## Frame-animated creature art: same Sprite2D + ActorMotion path as painted
## enemies, with a CreatureArt child swapping the frames. The collider follows
## the drawn size (a snake stays low enough to jump over).
func _apply_creature_art(enemy: Enemy, id: StringName) -> void:
	var sheet := CreatureArt.sheet_for(id)
	var frames := CreatureArt.frames_for(sheet)
	if frames.is_empty():
		return
	var scale_factor := CreatureArt.display_scale(id)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	PixelSprite.setup(sprite, frames[0], scale_factor, ENEMY_FOOT_Y)
	enemy.add_child(sprite)
	enemy.sprite_visual = sprite
	enemy.sprite_base_modulate = Color.WHITE
	var animator := CreatureArt.new()
	animator.name = "CreatureArt"
	animator.sprite = sprite
	animator.frames = frames
	animator.fps = CreatureArt.frame_rate(sheet)
	enemy.add_child(animator)
	var rect := PixelSprite.opaque_rect(frames[0])
	var visual := Vector2(rect.size) * scale_factor
	var collider := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider != null:
		var shape := CapsuleShape2D.new()
		shape.radius = clampf(minf(visual.x, visual.y) * 0.32, 10.0, 30.0)
		shape.height = clampf(visual.y * 0.7, shape.radius * 2.0, 160.0)
		collider.shape = shape
		collider.position.y = ENEMY_FOOT_Y - shape.height * 0.5
	for node_name in ["Body", "Eye"]:
		var node := enemy.get_node_or_null(node_name)
		if node != null:
			node.hide()


func _start_chapter(index: int) -> void:
	_chapter = clampi(index, 0, CampaignData.chapter_count() - 1)
	await _start_mds_chapter(_chapter)


## Chapter plan resource, or null for chapters that still use the legacy
## CampaignData room list. Chapter 1 keeps its linear plan; Chapters 2–4 use
## their big-map region plans.
func _load_chapter_plan(chapter_index: int) -> ChapterPlanData:
	if chapter_index < 0 or chapter_index >= CHAPTER_PLAN_PATHS.size():
		return null
	var path := CHAPTER_PLAN_PATHS[chapter_index]
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as ChapterPlanData


## First room of a fresh chapter: the plan's authored entrance (big-map
## chapters) or the legacy `ch<N>_01` naming. Chapter 1 has no start region and
## therefore keeps `ch1_01` byte-for-byte.
func _chapter_start_room(chapter_index: int) -> String:
	if _chapter_plan != null:
		var region := _chapter_plan.start_region()
		if not region.is_empty():
			return region
	return "ch%d_01" % (chapter_index + 1)


func _start_mds_chapter(index: int) -> void:
	var chapter_index := clampi(index, 0, CampaignData.chapter_count() - 1)
	# A checkpoint belongs to exactly one chapter; resuming in it must keep the
	# saved room progress instead of clearing it with the chapter reset.
	var resume := not _resume_data.is_empty() and chapter_index == _resume_run_value("chapter", -1)
	_teardown_mds(not resume)
	_chapter = chapter_index
	var chapter := CampaignData.chapter(chapter_index)
	_chapter_plan = _load_chapter_plan(chapter_index)
	_event_room_id = ""
	_mds_active = true
	_rooms.clear()
	_boss = null
	_mds_boss_arena = null
	if not resume:
		_cleared_encounters.clear()
		_legacy_cleared_rooms.clear()
		_discovered_vaults.clear()
		_claimed_steles.clear()
		_legacy_claimed_steles.clear()
		_opened_chests.clear()
		_legacy_opened_chests.clear()
		_shop_cache.clear()
		_cleared_in_chapter = 0
		_boss_defeated = false
	_boss_aftermath_started = false
	_boss_bar_visible = false
	_boss_entrance_started = false
	_steles.clear()
	_shops.clear()
	_chests.clear()
	for hazard in get_tree().get_nodes_in_group("hostile_hazards"):
		hazard.queue_free()
	hud.set_region("%s · %s" % [chapter["region"], Difficulty.display_name(Flow.difficulty)])
	hud.set_progress(_cleared_in_chapter if resume else 0, _chapter_progress_total())
	hud.set_objective(chapter["objective"])
	hud.hide_boss()
	Audio.play_music(chapter["music"], 1.2)
	if not resume:
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
	if resume:
		world.set_save_data(_resume_data.get("mds", {}))
	else:
		world.starting_room = _chapter_start_room(chapter_index)
	if _map_overlay != null:
		_map_overlay.set_chapter(chapter_index)
		_map_overlay.set_world(MDS_WORLD_FILES[chapter_index])
		world.map_view = _map_overlay.map_view
	world.room_loaded.connect(_on_mds_room_loaded)
	add_child(world)
	_mds_world = world
	hud.show_message("目标：%s。按 %s 看操作说明。" % [String(chapter["objective"]), Flow.prompt_label(&"help")])


func _teardown_mds(clear_progress := true) -> void:
	if _map_overlay != null and _map_overlay.is_open():
		_map_overlay.close()
	if _mds_world != null and is_instance_valid(_mds_world):
		_mds_world.queue_free()
	_mds_world = null
	_mds_active = false
	_mds_boss_arena = null
	_fall_limit_local = ChapterPlanData.DEFAULT_FALL_Y
	if clear_progress:
		_cleared_encounters.clear()
		_legacy_cleared_rooms.clear()
		_discovered_vaults.clear()
	_rooms.clear()


## The world reports each room after the player has been placed; from then on
## game.gd owns the enemies, rewards and boss, exactly as it did for linear rooms.
func _on_mds_room_loaded(room_id: String) -> void:
	if not _mds_active or _mds_world == null:
		return
	_room_loaded_msec = Time.get_ticks_msec()
	var room_node := _mds_world.room_node
	if room_node == null:
		return
	_rooms.clear()
	_boss = null
	_mds_boss_arena = null
	_steles.clear()
	_shops.clear()
	_chests.clear()
	var has_bench := false
	for node in room_node.find_children("*", "", true, false):
		if node is MemoryStele:
			_steles.append(node)
		elif node is MemoryShop:
			_shops.append(node)
		elif node is BenchCheckpoint:
			has_bench = true
		elif node is TreasureChest:
			_chests.append(node)
	# Progress is recorded per prop/encounter, not per room, so several chests,
	# steles or arenas in one big-map room settle independently. A room-key
	# checkpoint written before ids existed still suppresses its (single)
	# content through the legacy fallback.
	var used_ids: Dictionary = {}
	for stele in _steles:
		_assign_content_id(stele, room_id, used_ids)
	for chest in _chests:
		_assign_content_id(chest, room_id, used_ids)
	var kept_steles: Array[MemoryStele] = []
	for stele in _steles:
		var stele_content := String(stele.get_meta(&"content_id", ""))
		if is_instance_valid(stele) and RoomProgress.is_recorded(
				_claimed_steles, _legacy_claimed_steles, stele_content, room_id):
			stele.is_claimed = true
			stele.queue_free()
		else:
			kept_steles.append(stele)
	_steles = kept_steles
	for chest in _chests:
		var chest_content := String(chest.get_meta(&"content_id", ""))
		if is_instance_valid(chest) and RoomProgress.is_recorded(
				_opened_chests, _legacy_opened_chests, chest_content, room_id):
			chest.open()
	_boss_bar_visible = false
	_boss_entrance_started = false
	var chapter := CampaignData.chapter(_chapter)
	var primary_arena := room_node.get_node_or_null("Arena") as ArenaRoom
	var arenas := _room_arenas(room_node, primary_arena)
	var room_index := _mds_room_index(room_id)
	var plan_room := _plan_room(room_id)
	var room_type := String(plan_room.get("type", ""))
	var big_map := _chapter_plan != null and _chapter_plan.big_map
	# Big-map rooms draw ground below their floor so the camera can clear
	# the bottom HUD strip; Chapter 1's single-screen rooms keep the frame.
	player.hud_bottom_pad = HUD_BOTTOM_PAD if big_map else 0.0
	if big_map:
		_open_hub_shortcut(room_id)
	if arenas.is_empty():
		var is_vault := room_id.ends_with("_vault")
		# Big-map entrance regions have neither combat nor rest facilities, so
		# they must not borrow the shop/bench arrival copy (the chapter 3 entry
		# used to greet the player with a chapter 4-flavoured rest line). Only
		# rooms that actually author a shop or a checkpoint bench keep the rest
		# branch; Chapter 1 keeps its authored rest room via `not big_map`.
		var rests_here := not big_map or has_bench or not _shops.is_empty()
		hud.set_objective("搜查隐藏书库" if is_vault
			else ("休整，或继续前进" if rests_here else "继续前进"))
		if is_vault and not _discovered_vaults.has(room_id):
			_discovered_vaults[room_id] = true
			hud.show_message(VaultRoomData.pick(run_state.run_seed, room_id))
			CombatFX.spawn(player.get_parent(), player.global_position, &"ring", Color("e6c87a"), 1.0, 130.0)
			var audio := get_node_or_null("/root/Audio")
			if audio != null:
				audio.call("play_sfx", &"pickup")
		elif not is_vault and rests_here and not _rest_greeted.has(room_id):
			_rest_greeted[room_id] = true
			var rest_line := RestRoomData.pick(run_state.run_seed, room_id)
			if rest_line != "":
				hud.show_message(rest_line)
	else:
		# A big-map room can hold several encounters. Every arena is wired and
		# keyed by its own node id; `Arena` stays the primary node that owns the
		# authored event/boss branch and the room-level objective, while big-map
		# waves are looked up per encounter id (never per region).
		for arena in arenas:
			var is_primary := arena == primary_arena
			var encounter_id := _assign_encounter_id(arena, room_id, used_ids)
			var encounter_cleared := RoomProgress.is_recorded(
				_cleared_encounters, _legacy_cleared_rooms, encounter_id, room_id)
			var cleared_handler := _on_room_cleared.bind(arena, _chapter)
			if not arena.cleared.is_connected(cleared_handler):
				arena.cleared.connect(cleared_handler)
			var enemies_root := arena.get_node_or_null(ArenaRoom.ENEMIES_NODE)
			# Locked arenas wake their enemies on entry; roaming ones are live
			# from the start (they wander and notice the player on their own).
			if enemies_root != null and not arena.roaming:
				enemies_root.process_mode = Node.PROCESS_MODE_DISABLED
			# Event pages are routed per chapter by `_event_data`. Chapter 1 keeps
			# its original primary-arena trigger; big-map event regions are
			# handled at region level after this loop.
			if is_primary and _chapter == 0 and room_type == "event":
				var event_id := RoomProgress.event_encounter_id(room_id)
				if RoomProgress.is_recorded(_cleared_encounters, _legacy_cleared_rooms, event_id, room_id):
					hud.set_objective("事件已经读过")
				else:
					hud.set_objective("事件 · 读或不读")
					# room_loaded fires before the camera fade finishes; opening a
					# paused modal inside that await would stall the transition.
					_open_event_after_transition.call_deferred(room_id)
			elif is_primary and (room_index == 7 or room_type == "boss"):
				_mds_boss_arena = arena
				_rooms.append(arena)
				if _boss_defeated:
					# Quit during the authority/outro sequence: finish it instead of
					# spawning a second boss and re-paying the kill reward.
					hud.set_objective("%s已经倒下" % chapter["boss_name"])
					_resume_boss_aftermath.call_deferred()
				else:
					_boss = _spawn_boss(arena, chapter, _chapter)
					hud.set_objective("击败 %s" % chapter["boss_name"])
			elif big_map:
				# Each listed combat encounter spawns from its own plan wave and
				# settles under its own node id. Event and boss regions never
				# consume an ordinary wave.
				var wave := _plan_wave(room_id, encounter_id)
				var combat := room_type != "event" and room_type != "boss" \
					and not wave.is_empty()
				if combat and not encounter_cleared:
					_rooms.append(arena)
					var first_count := mini(2, wave.size())
					_populate_room(arena, wave.slice(0, first_count), wave.slice(first_count))
					if is_primary:
						hud.set_objective("肃清此房间 · 敌人 %d" % arena.enemy_count())
				elif is_primary:
					hud.set_objective("此房间已肃清")
			elif is_primary and room_index >= 0 and room_index < 6 and not encounter_cleared:
				_rooms.append(arena)
				if _chapter_plan != null:
					var wave: Array = plan_room.get("wave", [])
					var first_count := mini(2, wave.size())
					_populate_room(arena, wave.slice(0, first_count), wave.slice(first_count))
				else:
					# Chapters 2–4 keep the authored first group + ROOM_WAVES wave.
					_populate_room(arena, chapter["rooms"][room_index], ROOM_WAVES[_chapter][room_index])
				hud.set_objective("肃清此房间 · 敌人 %d" % arena.enemy_count())
			elif not is_primary and room_index >= 0 and room_index < 6 \
					and room_type != "event" and room_type != "boss" and not encounter_cleared:
				# Extra encounters keep their authored content; the primary
				# arena above still owns the plan wave and the objective text.
				_rooms.append(arena)
			elif is_primary:
				hud.set_objective("此房间已肃清")
	# Big-map event regions author an `Event` arena instead of a primary `Arena`,
	# so the chapter-gated branch above never sees them. The page belongs to the
	# region: it opens once on entry, keyed by the plan's event node id, and a
	# settled node stays settled across reloads. The branch is chapter-agnostic:
	# any big-map chapter with authored event copy gets it (Chapters 2–4), while
	# the chapter still decides reachability through its plan slot.
	if big_map and room_type == "event" and not _event_data(room_id).is_empty():
		var event_id := RoomProgress.event_encounter_id(room_id)
		if RoomProgress.is_recorded(_cleared_encounters, _legacy_cleared_rooms, event_id, room_id):
			hud.set_objective("事件已经读过")
		else:
			hud.set_objective("事件 · 读或不读")
			_open_event_after_transition.call_deferred(room_id)
	_refresh_roaming_objective()
	_fall_limit_local = _resolve_fall_limit(room_id)
	_last_checkpoint = player.global_position
	hud.set_progress(_cleared_in_chapter, _chapter_progress_total())
	hud.hide_boss()
	save_run_now()


## All encounters in a loaded room. The editor-authored `Arena` is first when
## present; further direct-child arenas are additional big-map encounters and
## settle under their own node ids.
func _room_arenas(room_node: Node, primary: ArenaRoom) -> Array[ArenaRoom]:
	var arenas: Array[ArenaRoom] = []
	if primary != null:
		arenas.append(primary)
	for child in room_node.get_children():
		if child is ArenaRoom and child != primary:
			arenas.append(child)
	return arenas


func _assign_content_id(node: Node, room_id: String, used_ids: Dictionary) -> String:
	var authored := ""
	var value: Variant = node.get(&"content_id")
	if value is String or value is StringName:
		authored = String(value)
	var id := RoomProgress.unique_id(
		RoomProgress.content_id(room_id, String(node.name), authored), used_ids)
	node.set_meta(&"content_id", id)
	return id


func _assign_encounter_id(arena: ArenaRoom, room_id: String, used_ids: Dictionary) -> String:
	var id := RoomProgress.unique_id(
		RoomProgress.encounter_id(room_id, String(arena.name), String(arena.encounter_id)),
		used_ids)
	arena.set_meta(&"encounter_id", id)
	return id


func _encounter_id_for(arena: ArenaRoom, room_id: String) -> String:
	if arena == null:
		return ""
	var assigned := String(arena.get_meta(&"encounter_id", ""))
	if not assigned.is_empty():
		return assigned
	return RoomProgress.encounter_id(room_id, String(arena.name), String(arena.encounter_id))


func _content_id_for(node: Node, room_id: String) -> String:
	if node == null:
		return room_id
	var assigned := String(node.get_meta(&"content_id", ""))
	if not assigned.is_empty():
		return assigned
	var authored := ""
	var value: Variant = node.get(&"content_id")
	if value is String or value is StringName:
		authored = String(value)
	return RoomProgress.content_id(room_id, String(node.name), authored)


## Records one encounter/event clear. Returns false when the id was already
## settled, so re-entering or reloading a room cannot count twice.
func _mark_encounter_cleared(room_id: String, encounter_id: String) -> bool:
	if RoomProgress.is_recorded(
			_cleared_encounters, _legacy_cleared_rooms, encounter_id, room_id):
		return false
	_cleared_encounters[encounter_id] = true
	_cleared_in_chapter += 1
	hud.set_progress(_cleared_in_chapter, _chapter_progress_total())
	return true


func _resume_boss_aftermath() -> void:
	if _boss_aftermath_started or _finished or _ending_pending:
		return
	_boss_aftermath_started = true
	# A checkpoint is written before the authority pick. An authority carried
	# over from an earlier chapter therefore means this chapter's pick is still
	# owed; only an authority granted by this chapter skips the choice.
	if _authority.authority == null or _authority_granted_chapter != _chapter:
		await _grant_chapter_authority()
	if is_inside_tree() and not _ended():
		_complete_chapter()


func _plan_room(room_id: String) -> Dictionary:
	if _chapter_plan == null:
		return {}
	return _chapter_plan.room(room_id)


## Enemy wave authored for one encounter node. Big-map plans key `wave` by
## encounter id (`region/Node`), so two arenas in one region never share a
## wave; Chapter 1 keeps its room-level plan array.
func _plan_wave(room_id: String, encounter_id: String) -> Array:
	if _chapter_plan == null:
		return []
	return _chapter_plan.wave_for(room_id, encounter_id)


## Clears required to finish the chapter. Plans own the number (derived from
## their room types by default); chapters without a plan keep the legacy six.
func _chapter_clear_target() -> int:
	if _chapter_plan != null:
		var target := _chapter_plan.clear_target()
		if target > 0:
			return target
	return 6


## HUD denominator: the clear target plus the boss room.
func _chapter_progress_total() -> int:
	return _chapter_clear_target() + 1


## Room-local fall plane for [param room_id]. The chapter plan overrides first
## (it drives the big-map rooms), then scene metadata on the loaded room, then
## the legacy 850 px rule. Chapter 1 configures neither, so it keeps 850.
func _resolve_fall_limit(room_id: String) -> float:
	var local_height := _room_local_height(room_id)
	var plan_room := _plan_room(room_id)
	var from_plan := _fall_limit_from(plan_room, local_height)
	if not is_nan(from_plan):
		return from_plan
	if _mds_world != null and is_instance_valid(_mds_world.room_node) \
			and _mds_world.current_room == room_id:
		var room_node := _mds_world.room_node
		if room_node.has_meta(&"fall_y"):
			var meta_y: Variant = room_node.get_meta(&"fall_y")
			if meta_y is float or meta_y is int:
				return float(meta_y)
		if room_node.has_meta(&"fall_below_bounds"):
			var meta_below: Variant = room_node.get_meta(&"fall_below_bounds")
			if meta_below is float or meta_below is int:
				return local_height + float(meta_below)
	return ChapterPlanData.DEFAULT_FALL_Y


func _fall_limit_from(entry: Dictionary, local_height: float) -> float:
	return ChapterPlanData.fall_limit_from_entry(entry, local_height, NAN)


func _room_local_height(room_id: String) -> float:
	if _mds_world == null or not is_instance_valid(_mds_world) or not _mds_world.world:
		return 720.0
	var bounds := _mds_world.world.get_room_bounds(room_id)
	if bounds.size.y <= 0.0:
		return 720.0
	return bounds.end.y - _mds_world.world.get_origin(room_id).y


func _open_event_after_transition(room_id: String) -> void:
	await get_tree().create_timer(0.8).timeout
	# Walking back out before the page opens must cancel it: opening the paused
	# page during the next room's fade leaves the player on a black screen (the
	# story layer sits under the fade) and stalls the transition. Re-entering
	# the room schedules it again because it is still uncleared.
	while is_inside_tree() and not _finished and not _ending_pending:
		if not _mds_active or _mds_world == null or _mds_world.current_room != room_id:
			return
		# A transition started inside the beat means the player is already
		# leaving. `current_room` only flips after the fade-out, so without this
		# check the page could open on the dying room's black fade and freeze
		# there. Cancelling is safe: re-entering schedules the page again.
		if _mds_world.changing_room:
			return
		if not _ui_blocks_delayed_page():
			break
		# A page (map/pause/inventory/shop...) opened during the 0.8 s beat owns
		# the screen. Opening the event choice under or over it would stack two
		# modals; closing the map would then unpause the world while the required
		# choice is still up. Wait for the player to come back to gameplay.
		await get_tree().create_timer(0.05).timeout
	if not is_inside_tree() or _finished or _ending_pending:
		return
	if not _mds_active or _mds_world == null or _mds_world.current_room != room_id:
		return
	_open_chapter_event(room_id)


## True while another page/pause owns the screen. Delayed pages (event page,
## boss authority pick) must wait for it to close instead of stacking: the pause
## menu draws above every game page and the map unpauses unconditionally on
## close, so an overlap can hide a required choice or resume the run underneath
## it.
func _ui_blocks_delayed_page() -> bool:
	if get_tree().paused:
		return true
	if _overlay != null or pause_menu.is_open():
		return true
	if _map_overlay != null and _map_overlay.is_open():
		return true
	if _story != null and _story.is_open():
		return true
	if _reward_ui != null and _reward_ui.visible:
		return true
	if _shop_ui != null and _shop_ui.visible:
		return true
	if _authority_choice != null and _authority_choice.is_open():
		return true
	if _archive_choice != null and _archive_choice.is_open():
		return true
	return ending_screen != null and ending_screen.visible


## Event page for the active chapter: no forced fight; reading grants a word at
## a corruption cost, taking the pages is the safe economic choice. Chapter 1
## keeps Ch1EventData byte-for-byte; Chapters 2–4 read Ch2/Ch3/Ch4EventData keyed
## by the plan's event node id. All reuse the same fixed two-choice mechanics.
func _open_chapter_event(room_id: String) -> void:
	if _event_room_id == room_id or _finished or _ending_pending:
		return
	var data := _event_data(room_id)
	if data.is_empty():
		return
	_event_room_id = room_id
	var event: Dictionary = data["event"]
	var corruption_cost: int = data["corruption_cost"]
	var pages_reward: int = data["pages_reward"]
	var fallback_pages: int = data["fallback_pages"]
	var decode_pool := RunLoot.owned_undecoded_words(run_state, Flow.profile, _chapter)
	var read_note := "解明一个残页词，污染 +%d" % corruption_cost
	if decode_pool.is_empty():
		read_note = "残页 +%d，污染 +%d" % [fallback_pages, corruption_cost]
	elif decode_pool.size() > 1:
		read_note = "从 %d 个残页词中解明一个，污染 +%d" % [decode_pool.size(), corruption_cost]
	_story.open_choice(
		String(event.get("eyebrow", "事件 · 禁文")),
		String(event.get("title", "一页禁文在墨雨中发光。")),
		String(event.get("body", "读它，还是把残页带走？")),
		[
			{"label": String(event.get("read_label", "读禁文")), "note": read_note},
			{"label": String(event.get("take_label", "拿残页")),
				"note": "残页 +%d" % pages_reward},
		])
	# Hide the HUD on the same frame the page appears instead of waiting for the
	# next `_process` sync; pause/map/other pages already hide synchronously.
	_sync_hud_visibility()
	var picked: int = await _story.choice_made
	if picked == 0:
		run_state.add_corruption(corruption_cost)
		var decoded_name := _grant_event_word(fallback_pages)
		if decoded_name.is_empty():
			hud.show_message(String(event["read_pages_message"]) % [
				fallback_pages, corruption_cost])
		else:
			hud.show_message(String(event["read_word_message"]) % [
				decoded_name, corruption_cost])
	else:
		run_state.add_pages(pages_reward)
		hud.show_message(String(event["take_message"]) % pages_reward)
	_mark_encounter_cleared(room_id, RoomProgress.event_encounter_id(room_id))
	save_run_now()


## Event copy + tuning resolved through one per-chapter table. Chapter 1 keeps
## its exact legacy key (room id) and numbers, so its page is unchanged; the
## Chapter 2–4 pages key on the plan's event node id. Chapters without authored
## event content return {} and show no page.
func _event_data(room_id: String) -> Dictionary:
	match _chapter:
		0:
			return {
				"event": Ch1EventData.pick(run_state.run_seed, room_id),
				"corruption_cost": Ch1EventData.CORRUPTION_COST,
				"pages_reward": Ch1EventData.PAGES_REWARD,
				"fallback_pages": Ch1EventData.FALLBACK_PAGES,
			}
		1:
			return {
				"event": Ch2EventData.pick(
					run_state.run_seed, RoomProgress.event_encounter_id(room_id)),
				"corruption_cost": Ch2EventData.CORRUPTION_COST,
				"pages_reward": Ch2EventData.PAGES_REWARD,
				"fallback_pages": Ch2EventData.FALLBACK_PAGES,
			}
		2:
			return {
				"event": Ch3EventData.pick(
					run_state.run_seed, RoomProgress.event_encounter_id(room_id)),
				"corruption_cost": Ch3EventData.CORRUPTION_COST,
				"pages_reward": Ch3EventData.PAGES_REWARD,
				"fallback_pages": Ch3EventData.FALLBACK_PAGES,
			}
		3:
			return {
				"event": Ch4EventData.pick(
					run_state.run_seed, RoomProgress.event_encounter_id(room_id)),
				"corruption_cost": Ch4EventData.CORRUPTION_COST,
				"pages_reward": Ch4EventData.PAGES_REWARD,
				"fallback_pages": Ch4EventData.FALLBACK_PAGES,
			}
	return {}


## Returns the decoded word's display label, or "" when every fragment was
## already readable and the event pays pages instead.
func _grant_event_word(fallback_pages: int) -> String:
	var pool := RunLoot.owned_undecoded_words(run_state, Flow.profile, _chapter)
	if pool.is_empty():
		run_state.add_pages(fallback_pages)
		return ""
	var picked := pool[run_state.rng.randi_range(0, pool.size() - 1)]
	if not RunLoot.decode_owned_word(run_state, Flow.profile, picked):
		run_state.add_pages(fallback_pages)
		return ""
	# Decoding is cross-run Profile progress; persist it before the next room so
	# quitting mid-run cannot lose the fragment the player just read.
	if Flow.auto_save:
		Flow.save_profile()
	return RunLoot.word_label(picked)


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
		if room.is_locked() or room.is_cleared() or room.roaming:
			continue
		# A defeated boss stays down. A boss-death checkpoint restores the player
		# inside the arena, so re-locking it would replay the entrance sting over
		# a dead boss and overwrite the "已经倒下" objective with a fresh kill
		# order while the authority pick is already pending.
		if _boss_defeated and _is_boss_room(room):
			continue
		if room.contains_entry(player.global_position):
			var enemies_root := room.get_node_or_null(ArenaRoom.ENEMIES_NODE)
			if enemies_root != null:
				enemies_root.process_mode = Node.PROCESS_MODE_PAUSABLE
				for enemy in enemies_root.get_children():
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
	var entrance_line := BossEntranceData.pick(run_state.run_seed, _chapter)
	if entrance_line != "":
		hud.show_message(entrance_line)
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
	var room_id := ""
	var encounter_id := ""
	if _mds_active and _mds_world != null:
		room_id = _mds_world.current_room
		encounter_id = _encounter_id_for(room, room_id)
		# A room can hold several encounters; each one settles exactly once even
		# if a cleared signal is re-emitted after a reload.
		if RoomProgress.is_recorded(
				_cleared_encounters, _legacy_cleared_rooms, encounter_id, room_id):
			return
	_cleared_in_chapter += 1
	if not encounter_id.is_empty():
		_cleared_encounters[encounter_id] = true
	run_state.add_pages(maxi(1, int(round((4 + Flow.difficulty * 2) * Difficulty.reward_multiplier(Flow.difficulty)))))
	hud.set_progress(_cleared_in_chapter, _chapter_progress_total())
	relic_effects.on_room_cleared()
	if _cleared_in_chapter >= _chapter_clear_target():
		hud.set_objective("前往章节尽头 · 击败 " + String(CampaignData.chapter(_chapter)["boss_name"]))
	_update_hud()
	_reward_room = room
	# Spread the reward roll seed by the chapter's own clear target so a longer
	# big-map chapter cannot collide with the next chapter's sequence.
	var chapter_target := _chapter_clear_target()
	var chapter_seed := _chapter * chapter_target + _cleared_in_chapter
	if String(_current_plan_room().get("type", "")) == "elite":
		_reward_options = RunLoot.elite_choices(run_state, chapter_seed, Flow.profile, _chapter)
	else:
		_reward_options = RunLoot.choices(run_state, chapter_seed, Flow.profile, _chapter)
	_reward_pending = true
	_open_reward.call_deferred()

func _current_plan_room() -> Dictionary:
	if not _mds_active or _mds_world == null:
		return {}
	return _plan_room(_mds_world.current_room)


func _open_reward() -> void:
	# An enemy corpse is freed by a 0.35 s scene timer that keeps running while
	# the tree is paused, so killing the last enemy and opening the map, pause
	# menu or an overlay inside that window lets the room clear behind the page.
	# The reward is required; stacking it there lets closing the map resume the
	# world with an unpicked page on screen. Wait for gameplay to own the screen
	# like the event page and the authority pick do. Death is final: a run that
	# died in the same window is not owed the reward any more.
	while is_inside_tree() and not _ended() and not _death_committed:
		if _reward_ui != null and _reward_ui.visible:
			return
		# Unlike the event page this pick cannot be cancelled: the room is
		# already recorded cleared, so re-entering would not offer it again.
		# Wait the transition out instead of opening under the MDS fade.
		if _mds_active and _mds_world != null and _mds_world.changing_room:
			await get_tree().create_timer(0.05).timeout
			continue
		if not _ui_blocks_delayed_page():
			break
		await get_tree().create_timer(0.05).timeout
	if not is_inside_tree() or _ended() or _death_committed:
		_reward_pending = false
		return
	if _reward_ui != null and _reward_ui.visible:
		return
	if _reward_options.is_empty():
		# Nothing to offer: release the checkpoint hold so a later room entry
		# can still save. RunLoot always returns a full set, so this is a guard.
		_reward_pending = false
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
	_reward_pending = false
	_reward_ui.hide()
	get_tree().paused = false
	hud.show_message("获得：" + String(choice["title"]))
	_reward_room = null
	save_run_now()

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
	# Keep the mechanical phase banner; only the trailing flavor rotates.
	if _boss != null and is_instance_valid(_boss):
		VFX.spawn(_boss.get_parent(), &"boss_phase", _boss.global_position + Vector2(0, ENEMY_FOOT_Y))
	var phase_text := "%s · 第 %d 阶段" % [chapter["boss_name"], phase]
	var flavor := BossPhaseData.pick(run_state.run_seed, phase, _chapter)
	if not flavor.is_empty():
		phase_text += "：" + flavor
	hud.show_message(phase_text)
	_screen_fx.flash(Color("d96a7a", 0.2), 0.22)
	_hit_stop.freeze(0.07, 0.08)
	Audio.play_voice("boss_%s_phase%d" % [chapter["boss_voice"], phase])


## Ink paid for slipping a hit inside the roll's invulnerable window.
const PERFECT_DODGE_INK := 6
## Big-map chapters author a one-way door from the hub back to the entrance
## behind `ch<N>_shortcut`, but nothing ever granted it, so the door stayed
## shut for good. Reaching the hub now opens it (stored in the MDS save, so
## it stays open after a reload).
func _open_hub_shortcut(room_id: String) -> void:
	if _mds_world == null or not room_id.ends_with("_hub"):
		return
	var flag := "ch%d_shortcut" % (_chapter + 1)
	if _mds_world.has_ability(flag):
		return
	_mds_world.grant_ability(flag)
	hud.show_message("捷径已打通：枢纽的暗门可直接回到入口")


## Camera room under the floor so the bottom HUD does not cover the ground.
const HUD_BOTTOM_PAD := 96.0

func _on_perfect_dodge() -> void:
	if _hit_stop != null:
		_hit_stop.freeze(0.07, 0.15)
	run_state.restore_ink(PERFECT_DODGE_INK)
	if _screen_fx != null:
		_screen_fx.flash(Color(0.95, 0.82, 0.45, 0.18), 0.12)


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
	if player != null and is_inside_tree():
		var circle := VFX.spawn(player.get_parent(), &"cast_circle", player.global_position + Vector2(0, Player.FOOT_Y), false, 0.7)
		if circle != null:
			circle.modulate = Color(1, 1, 1, 0.8)
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
	if enemy is Node2D and is_inside_tree():
		var elite := enemy.has_meta(&"elite")
		VFX.spawn((enemy as Node2D).get_parent(), &"elite_die" if elite else &"enemy_die",
			(enemy as Node2D).global_position + Vector2(0, ENEMY_FOOT_Y))
		Audio.play_sfx(&"elite_die" if elite else &"enemy_die")
	if enemy != null and enemy.has_meta(&"elite"):
		run_state.add_pages(EncounterVariation.ELITE_PAGES)
	run_state.add_pages(maxi(1, int(round((1 + Flow.difficulty * 0.5) * Difficulty.reward_multiplier(Flow.difficulty)))))
	relic_effects.on_kill()
	_update_hud()
	if enemy is Node2D and run_state.rng.randf() < WEAPON_DROP_CHANCE:
		var dropped := RunLoot.dropped_weapon(run_state, Flow.profile, _chapter)
		if dropped != null:
			var enemy_position := (enemy as Node2D).global_position
			# Flying enemies die in the air; bring the page down to floor reach.
			var drop_at := Vector2(enemy_position.x, maxf(enemy_position.y, 540.0))
			_drop_weapon(dropped, drop_at)
	var roaming_alive := -1
	for room in _rooms:
		if room.roaming and not room.is_cleared():
			roaming_alive = maxi(roaming_alive, 0)
			var group := room.get_node_or_null("Enemies")
			if group != null:
				for child in group.get_children():
					if child is Enemy and not child.dead:
						roaming_alive += 1
		elif room.is_locked():
			var alive := 0
			for child in room.get_node("Enemies").get_children():
				if child is Enemy and not child.dead:
					alive += 1
			hud.set_objective("肃清此房间 · 敌人 %d" % alive)
	if roaming_alive > 0:
		hud.set_objective("游荡的敌人 · 还剩 %d" % roaming_alive)

func _on_boss_died(_enemy: Node, chapter_index: int) -> void:
	if chapter_index != _chapter or _ended():
		return
	_boss_defeated = true
	if _boss != null and is_instance_valid(_boss):
		VFX.spawn(_boss.get_parent(), &"boss_die", _boss.global_position + Vector2(0, ENEMY_FOOT_Y))
	var progress_total := _chapter_progress_total()
	hud.set_progress(progress_total, progress_total)
	run_state.add_pages(maxi(1, int(round((8 + Flow.difficulty * 4) * Difficulty.reward_multiplier(Flow.difficulty)))))
	_screen_fx.flash(Color(1.0, 0.9, 0.8, 0.3), 0.4)
	_hit_stop.freeze(0.1, 0.1)
	save_run_now()
	await _grant_chapter_authority()
	if not is_inside_tree() or _ended():
		return
	_complete_chapter()


## Boss reward for any chapter whose plan authors an authority pool. Chapter 1
## keeps its authored revive/rewrite base; Chapters 2–4 author the same base, and
## all of them get the conditional devour/archive additions through build_pool.
func _grant_chapter_authority() -> void:
	if _chapter_plan == null or _chapter_plan.authority_pool.is_empty():
		return
	await get_tree().create_timer(1.2).timeout
	# The 1.2 s beat leaves room to pause, open the map, or step through the door
	# the dying boss just unlocked. This pick is required, so wait until gameplay
	# owns the screen again. A page would stack above/below it; a room transition
	# would freeze under the MDS fade (CanvasLayer 100, above $UI) with the pick
	# invisible. `room_loaded` also fires before the fade-in clears.
	while is_inside_tree() and not _ended():
		if _mds_active and _mds_world != null and _mds_world.changing_room:
			await get_tree().create_timer(0.05).timeout
			continue
		if _ui_blocks_delayed_page():
			await get_tree().create_timer(0.05).timeout
			continue
		if Time.get_ticks_msec() - _room_loaded_msec < 400:
			await get_tree().create_timer(0.05).timeout
			continue
		break
	if not is_inside_tree() or _ended():
		return
	# The authored pool plus condition unlocks (devour at high corruption,
	# archive after enough records). Base options keep their authored order.
	var options := AuthorityController.build_pool(
		_chapter_plan.authority_pool, run_state, Flow.profile, _records)
	if options.is_empty():
		return
	_authority_choice.open(options)
	# Same-frame HUD hide: the required pick pauses the tree, so a check taken
	# before the next `_process` must already see the modal as the only layer.
	_sync_hud_visibility()
	var index: int = await _authority_choice.chosen
	if not is_inside_tree():
		return
	var picked := options[clampi(index, 0, options.size() - 1)]
	_authority.apply(picked, run_state)
	_authority_granted_chapter = _chapter
	hud.set_authority(picked.display_name, _authority.can_use())
	hud.show_message("获得权柄：%s · %s" % [picked.display_name, picked.description])
	save_run_now()


func _on_rewrite_requested() -> void:
	if not _authority.consume_rewrite():
		return
	var authority_name := run_state.authority.display_name if run_state.authority != null else "改写"
	hud.set_authority(authority_name, _authority.can_use())
	var room_number := _chapter * _chapter_clear_target() + _cleared_in_chapter + 1
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
	# Chapter 1 hands off to the Chapter 2 big-map campaign. The authored
	# choice effects are unchanged; the demo flag still marks "Chapter 1 has
	# been finished" because the Hub NPC personal events read it.
	if _chapter == 0:
		if Flow.profile != null:
			Flow.profile.demo_cleared = true
			# `_finish(true)` used to persist this flag at the demo boundary;
			# keep that parity now that the campaign continues into Chapter 2.
			Flow.save_profile()
		_start_chapter(1)
		return
	# Chapter 2 hands off to the Chapter 3 big-map campaign. The authored choice
	# effects are unchanged; no ending is recorded at this boundary.
	if _chapter == 1:
		_start_chapter(2)
		return
	# Chapter 3 hands off to the Chapter 4 big-map campaign. The authored choice
	# effects are unchanged; no ending is recorded at this boundary.
	if _chapter == 2:
		_start_chapter(3)
		return
	# Chapter 4 is the final authored chapter: the campaign ends here instead of
	# looking for a fifth chapter.
	if _chapter == 3:
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
	save_run_now()

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
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group(BenchCheckpoint.GROUP):
			var bench := node as BenchCheckpoint
			if bench != null and is_instance_valid(bench):
				bench.set_player_near(bench.can_use(player.global_position))
		var feet := player.global_position + Vector2(0, Player.FOOT_Y)
		for node in get_tree().get_nodes_in_group(MovingPlatform.GROUP):
			var lift := node as MovingPlatform
			if lift != null and lift.call_mode and is_instance_valid(lift):
				lift.update_player(feet)


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
	VFX.spawn(chest.get_parent(), &"chest_open", chest.global_position)
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
	if _mds_active and _mds_world != null:
		_opened_chests[_content_id_for(chest, _mds_world.current_room)] = true
	save_run_now()


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
	_shop_ui.open_shop(_shop_cache[key], run_state.pages,
		Ch1ShopData.pick(run_state.run_seed, String(key)))
	get_tree().paused = true


## True when the cached shop row is a relic/word the player already carries.
## Other row kinds (rest, vitality, weapon swap) always have something to give.
func _shop_offer_owned(offer: Dictionary) -> bool:
	match StringName(offer.get("kind", &"")):
		&"relic":
			var relic := offer.get("resource", null) as RelicData
			return relic != null and run_state.inventory.has_relic(relic.id)
		&"word":
			var word := offer.get("resource", null) as WordData
			return word != null and run_state.inventory.has_word(word.id)
	return false


func _on_shop_buy(index: int) -> void:
	if _active_shop == null:
		return
	var offers: Array[Dictionary] = _shop_cache.get(_active_shop.shop_id, [])
	if index < 0 or index >= offers.size():
		return
	var offer := offers[index]
	if bool(offer.get("bought", false)):
		return
	# The stock is rolled once per stall and cached. A relic/word from that
	# list can be picked up elsewhere afterwards (reward, chest, stele); buying
	# it then would spend pages on a duplicate the inventory silently refuses.
	# Disable the row and keep the pages.
	if _shop_offer_owned(offer):
		_shop_ui.mark_owned(index, run_state.pages, "这件你已经有了，摊主不收残页。")
		save_run_now()
		return
	if not run_state.spend_pages(int(offer["cost"])):
		_shop_ui.show_error("残页不足。继续战斗，纸人会记得。")
		return
	_apply_reward(offer)
	_shop_ui.mark_bought(index, run_state.pages,
		Ch1ShopData.pick_buy(run_state.run_seed, String(_active_shop.shop_id), index))
	_update_hud()
	save_run_now()


func _on_shop_closed() -> void:
	_active_shop = null
	get_tree().paused = false
	save_run_now()

## Big-map bench checkpoint. Chapter 1 rooms have no benches, so this is a
## no-op there and the demo's room-entry checkpoint stays exactly as it was.
## The run save keeps its existing shape: the bench writes the same checkpoint
## (current room + player position) every other checkpoint writes.
## Interact next to a call panel summons the elevator; on the car it rides to
## the other end.
func _try_call_elevator() -> bool:
	if not is_inside_tree() or player == null:
		return false
	var feet := player.global_position + Vector2(0, Player.FOOT_Y)
	for node in get_tree().get_nodes_in_group(MovingPlatform.GROUP):
		var lift := node as MovingPlatform
		if lift != null and lift.call_mode and is_instance_valid(lift) and lift.try_interact(feet):
			return true
	return false


func _try_use_bench() -> bool:
	if not is_inside_tree() or player == null:
		return false
	for node in get_tree().get_nodes_in_group(BenchCheckpoint.GROUP):
		var bench := node as BenchCheckpoint
		if bench == null or not is_instance_valid(bench):
			continue
		if not bench.can_use(player.global_position):
			continue
		_last_checkpoint = bench.respawn_position()
		player.velocity = Vector2.ZERO
		bench.activate()
		hud.show_message(BenchCheckpoint.MESSAGE)
		save_run_now()
		return true
	return false


## Restores every collapsing platform in the loaded room. Called when the fall
## guard or a death sends the player back to a checkpoint, so the recovered
## position is never over a hole the platform left behind.
func _reset_collapsing_platforms() -> void:
	if not is_inside_tree():
		return
	get_tree().call_group(CollapsingPlatform.GROUP, &"reset_now")


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
			if _mds_active and _mds_world != null:
				_claimed_steles[_content_id_for(stele, _mds_world.current_room)] = true
			save_run_now()
			return

func _on_player_health_changed(current: int, maximum: int) -> void:
	run_state.health = current
	run_state.max_health = maximum
	run_state.health_changed.emit(current, maximum)

func _on_player_died() -> void:
	# Revive-in-place must not leave the player above a platform that fell.
	_reset_collapsing_platforms()
	if _authority.consume_revive():
		player.revive(50)
		var authority_name := run_state.authority.display_name if run_state.authority != null else "续命"
		hud.set_authority(authority_name, _authority.can_use())
		hud.show_message(DeathHintData.pick(run_state.run_seed, &"authority"))
		return
	if relic_effects.has(&"revive_once") and not relic_effects.revive_used:
		relic_effects.revive_used = true
		player.revive(40)
		hud.show_message(DeathHintData.pick(run_state.run_seed, &"relic"))
		return
	# Death is final from here on. Drop the checkpoint before the archive pick
	# can pause the tree: a window close during that modal must not leave the
	# pre-death checkpoint to "继续本局" back into a live run.
	_death_committed = true
	if Flow != null and Flow.auto_save:
		RunSave.clear(Flow.run_save_path)
	_screen_fx.flash(Color(0.6, 0.05, 0.08, 0.34), 0.4)
	_hit_stop.freeze(0.12, 0.15)
	if _authority.can_archive() and not _archive_offers().is_empty():
		await _offer_archive_on_death()
		if not is_inside_tree() or _ended():
			return
	_finish(false)

func _ended() -> bool:
	return _finished or _ending_pending

func _finish(won: bool, forced_ending: Dictionary = {}) -> void:
	if _finished or _ending_pending:
		return
	_ending_pending = true
	# Death is final the moment it is committed. Drop the checkpoint before the
	# 0.65 s result delay: closing the window during the animation would
	# otherwise leave the pre-death checkpoint on disk and "继续本局" would
	# bring the player back alive. A victory keeps its boss-defeated checkpoint
	# so quitting during the same delay can resume the aftermath and still
	# reach the ending.
	if not won and Flow != null and Flow.auto_save:
		RunSave.clear(Flow.run_save_path)
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
	ending_screen.show_campaign_ending(won, Flow.last_reward, ending, _records, _kills,
		_chapter == 0, run_state.run_seed)

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
