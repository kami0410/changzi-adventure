class_name Profile
extends Node

const SAVE_VERSION := 2
## The six words a fresh player can read. Every other owned word starts as a
## glyph and must be decoded through 陆沉 / steles / the chapter boss.
const DEFAULT_DECODED: Array[StringName] = [&"posui", &"ranshao", &"yan", &"jilu", &"gr", &"grguan"]
## Owned from the first run: the six starter words plus the twelve demo
## fragments. Ownership is separate from decoding.
const DEFAULT_OWNED: Array[StringName] = [
	&"posui", &"ranshao", &"yan", &"jilu", &"gr", &"grguan",
	&"xue", &"dongjie", &"shenyuan", &"yongheng", &"zhaohuan", &"jinghua",
	&"tunshi", &"shouwang", &"guang", &"huiwang", &"guize", &"shensheng",
]

var memory_fragments: int = 0
var unlocked_words: Array[StringName] = []
## Cross-run decoding state. Shared WordData .tres files are never mutated;
## per-run copies read this list through WordRuntime.
var decoded_words: Array[StringName] = []
## Bonuses that apply to exactly the next run (NPC map pages, abyssal
## starting corruption). Consumed at run start and then cleared.
var pending_run_bonuses: Dictionary = {}
## First-visit Hub onboarding completed (Codex equip + training stele).
var tutorial_done := false
## HUD text size in pixels: 12 / 16 / 20.
var text_scale: int = 16
## Chapter 1 demo reached the end screen at least once.
var demo_cleared := false
## Relics bought from 咕噜, waiting to be carried into the next run.
var stored_relics: Array[StringName] = []
## Unbounded Archive altar levels: track id -> level.
var archive_levels: Dictionary = {}
## Per-word mastery XP; level = xp / 5, uncapped with diminishing returns.
var word_mastery: Dictionary = {}
var weapon_base_levels: Dictionary[StringName, int] = {}
var unlocked_patterns: Array[StringName] = []
var discovered_phrases: Array[String] = []
var endings: Array[String] = []
var runs_completed: int = 0
var records_found: int = 0
var shake_scale: float = 1.0
var flash_scale: float = 1.0
## 言灵改变 NPC 职能后留下的长期效果；键为 npc_id → 效果名 → 数值。
var npc_blessings: Dictionary = {}
## 每个 NPC 对昌子的信任；用于 AI 对话口吻和隐藏回应。
var npc_trust: Dictionary = {}
## 玩家自定义键位：action -> physical keycode。
var keybinds: Dictionary = {}


func _init() -> void:
	decoded_words = DEFAULT_DECODED.duplicate()
	unlocked_words = DEFAULT_OWNED.duplicate()


func record_ending(ending_id: StringName) -> void:
	var key := String(ending_id)
	if not endings.has(key):
		endings.append(key)


func add_memory_fragments(amount: int) -> void:
	if amount <= 0:
		return
	memory_fragments += amount


func unlock_word(word_id: StringName) -> bool:
	if word_id == &"" or unlocked_words.has(word_id):
		return false
	unlocked_words.append(word_id)
	return true


func is_word_unlocked(word_id: StringName) -> bool:
	return unlocked_words.has(word_id)


func is_word_decoded(word_id: StringName) -> bool:
	return decoded_words.has(word_id)


## Decoding implies ownership and persists across runs.
func decode_word(word_id: StringName) -> bool:
	if word_id == &"" or decoded_words.has(word_id):
		return false
	decoded_words.append(word_id)
	unlock_word(word_id)
	return true


func archive_level(track_id: StringName) -> int:
	return int(archive_levels.get(String(track_id), 0))


func buy_archive_level(track_id: StringName, cost: int) -> bool:
	if track_id == &"" or ArchiveData.track(track_id).is_empty() or cost <= 0 or memory_fragments < cost:
		return false
	if archive_level(track_id) >= 10:
		return false
	memory_fragments -= cost
	var key := String(track_id)
	archive_levels[key] = int(archive_levels.get(key, 0)) + 1
	return true


func add_word_mastery(word_id: StringName, amount: int = 1) -> void:
	if word_id == &"" or amount <= 0:
		return
	var key := String(word_id)
	if key.begins_with("__"):
		return
	word_mastery[key] = int(word_mastery.get(key, 0)) + amount


func word_mastery_xp(word_id: StringName) -> int:
	return int(word_mastery.get(String(word_id), 0))


func word_mastery_level(word_id: StringName) -> int:
	return word_mastery_xp(word_id) / 5


## Diminishing but uncapped: level 30 is ~15% ink discount, level 100 ~23%.
func word_mastery_ink_discount(word_id: StringName) -> float:
	var level := float(word_mastery_level(word_id))
	return level / (level + 30.0) * 0.3


## Diminishing but uncapped: level 30 is ~10% stronger, level 100 ~15%.
func word_mastery_power_bonus(word_id: StringName) -> float:
	var level := float(word_mastery_level(word_id))
	return level / (level + 30.0) * 0.2


func store_relic(relic_id: StringName) -> bool:
	if relic_id == &"" or stored_relics.has(relic_id):
		return false
	stored_relics.append(relic_id)
	return true


## Hands the purchased relics to a new run exactly once.
func consume_stored_relics() -> Array[StringName]:
	var result: Array[StringName] = stored_relics.duplicate()
	stored_relics.clear()
	return result


func weapon_base_level(weapon_id: StringName) -> int:
	return int(weapon_base_levels.get(weapon_id, 0))


func upgrade_weapon_base(weapon_id: StringName) -> bool:
	if weapon_id == &"":
		return false
	var level := weapon_base_level(weapon_id)
	var cost := 10 + level * 10
	if memory_fragments < cost:
		return false
	memory_fragments -= cost
	weapon_base_levels[weapon_id] = level + 1
	return true


func force_upgrade_weapon_base(weapon_id: StringName) -> bool:
	if weapon_id == &"":
		return false
	weapon_base_levels[weapon_id] = weapon_base_level(weapon_id) + 1
	return true


func discover_phrase(signature: String) -> bool:
	if signature.is_empty() or discovered_phrases.has(signature):
		return false
	discovered_phrases.append(signature)
	return true


func add_npc_blessing(npc_id: StringName, key: StringName, amount: float) -> void:
	if npc_id == &"" or key == &"" or not is_finite(amount) or amount == 0.0:
		return
	var npc_key := String(npc_id)
	var entry: Dictionary = npc_blessings.get(npc_key, {})
	entry[String(key)] = float(entry.get(String(key), 0.0)) + amount
	npc_blessings[npc_key] = entry


func npc_blessing(npc_id: StringName, key: StringName, fallback: float = 0.0) -> float:
	var entry: Dictionary = npc_blessings.get(String(npc_id), {})
	return float(entry.get(String(key), fallback))


func consume_npc_blessing(npc_id: StringName, key: StringName, amount: float = 1.0) -> bool:
	var current := npc_blessing(npc_id, key, 0.0)
	if current < amount:
		return false
	add_npc_blessing(npc_id, key, -amount)
	return true


func add_pending_run_bonus(key: StringName, amount: float) -> void:
	if key == &"" or not is_finite(amount) or amount <= 0.0:
		return
	pending_run_bonuses[String(key)] = float(pending_run_bonuses.get(String(key), 0.0)) + amount


func consume_pending_run_bonuses() -> Dictionary:
	var result := pending_run_bonuses.duplicate()
	pending_run_bonuses.clear()
	return result


func add_npc_trust(npc_id: StringName, amount: float) -> void:
	if npc_id == &"" or not is_finite(amount):
		return
	npc_trust[String(npc_id)] = npc_trust_value(npc_id) + amount


func npc_trust_value(npc_id: StringName) -> float:
	return float(npc_trust.get(String(npc_id), 0.0))


func save_profile(path: String = "user://profile.cfg") -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", SAVE_VERSION)
	config.set_value("progress", "memory_fragments", memory_fragments)
	config.set_value("progress", "unlocked_words", unlocked_words)
	config.set_value("progress", "decoded_words", decoded_words)
	config.set_value("progress", "pending_run_bonuses", pending_run_bonuses)
	config.set_value("progress", "tutorial_done", tutorial_done)
	config.set_value("progress", "demo_cleared", demo_cleared)
	config.set_value("settings", "text_scale", text_scale)
	config.set_value("progress", "stored_relics", stored_relics)
	config.set_value("progress", "archive_levels", archive_levels)
	config.set_value("progress", "word_mastery", word_mastery)
	config.set_value("progress", "weapon_base_levels", weapon_base_levels)
	config.set_value("progress", "unlocked_patterns", unlocked_patterns)
	config.set_value("progress", "discovered_phrases", discovered_phrases)
	config.set_value("progress", "endings", endings)
	config.set_value("progress", "runs_completed", runs_completed)
	config.set_value("progress", "records_found", records_found)
	config.set_value("settings", "shake_scale", shake_scale)
	config.set_value("settings", "flash_scale", flash_scale)
	config.set_value("npc", "blessings", npc_blessings)
	config.set_value("npc", "trust", npc_trust)
	config.set_value("input", "keybinds", keybinds)

	# Atomic write: tmp -> backup -> rename. A crash never leaves a half save.
	var tmp := path + ".tmp"
	var backup := path + ".bak"
	if config.save(tmp) != OK:
		return
	var absolute := ProjectSettings.globalize_path(path)
	var tmp_absolute := ProjectSettings.globalize_path(tmp)
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(absolute, ProjectSettings.globalize_path(backup))
		DirAccess.remove_absolute(absolute)
	var error := DirAccess.rename_absolute(tmp_absolute, absolute)
	if error != OK and FileAccess.file_exists(backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(backup), absolute)


func load_profile(path: String = "user://profile.cfg") -> bool:
	var config := ConfigFile.new()
	var loaded := config.load(path)
	if loaded != OK:
		# Fall back to the last good backup after a crashed write.
		var backup := path + ".bak"
		if FileAccess.file_exists(backup):
			loaded = config.load(backup)
	if loaded != OK:
		return false
	# A garbage file can parse as an empty config; require a version or a
	# progress section before accepting it.
	if int(config.get_value("meta", "version", 0)) <= 0 and not config.has_section("progress"):
		return false

	memory_fragments = int(config.get_value("progress", "memory_fragments", 0))

	unlocked_words.clear()
	for value in config.get_value("progress", "unlocked_words", []):
		unlocked_words.append(StringName(value))
	for default_id in DEFAULT_OWNED:
		if not unlocked_words.has(default_id):
			unlocked_words.append(default_id)

	# v1 saves have no decoded_words key: fall back to the six starter words
	# without touching the saved owned-word list.
	decoded_words.clear()
	for value in config.get_value("progress", "decoded_words", DEFAULT_DECODED):
		decoded_words.append(StringName(value))

	pending_run_bonuses = {}
	var pending: Dictionary = config.get_value("progress", "pending_run_bonuses", {})
	for key in pending:
		pending_run_bonuses[String(key)] = float(pending[key])
	tutorial_done = bool(config.get_value("progress", "tutorial_done", false))
	demo_cleared = bool(config.get_value("progress", "demo_cleared", false))
	text_scale = clampi(int(config.get_value("settings", "text_scale", 16)), 12, 20)

	stored_relics.clear()
	for value in config.get_value("progress", "stored_relics", []):
		stored_relics.append(StringName(value))

	archive_levels = {}
	var saved_levels: Dictionary = config.get_value("progress", "archive_levels", {})
	for key in saved_levels:
		archive_levels[String(key)] = int(saved_levels[key])

	word_mastery = {}
	var saved_mastery: Dictionary = config.get_value("progress", "word_mastery", {})
	for key in saved_mastery:
		word_mastery[String(key)] = int(saved_mastery[key])

	weapon_base_levels.clear()
	var levels: Dictionary = config.get_value("progress", "weapon_base_levels", {})
	for key in levels:
		weapon_base_levels[StringName(key)] = int(levels[key])

	unlocked_patterns.clear()
	for value in config.get_value("progress", "unlocked_patterns", []):
		unlocked_patterns.append(StringName(value))

	discovered_phrases.clear()
	for value in config.get_value("progress", "discovered_phrases", []):
		discovered_phrases.append(String(value))

	endings.clear()
	for value in config.get_value("progress", "endings", []):
		endings.append(String(value))
	runs_completed = int(config.get_value("progress", "runs_completed", 0))
	records_found = int(config.get_value("progress", "records_found", 0))
	shake_scale = clampf(float(config.get_value("settings", "shake_scale", 1.0)), 0.0, 1.0)
	flash_scale = clampf(float(config.get_value("settings", "flash_scale", 1.0)), 0.0, 1.0)

	npc_blessings = {}
	var blessings: Dictionary = config.get_value("npc", "blessings", {})
	for npc_key in blessings:
		if not blessings[npc_key] is Dictionary:
			continue
		var entry: Dictionary = {}
		for effect_key in blessings[npc_key]:
			entry[String(effect_key)] = float(blessings[npc_key][effect_key])
		npc_blessings[String(npc_key)] = entry
	npc_trust = {}
	var trust: Dictionary = config.get_value("npc", "trust", {})
	for npc_key in trust:
		npc_trust[String(npc_key)] = float(trust[npc_key])

	keybinds = {}
	var saved_keys: Dictionary = config.get_value("input", "keybinds", {})
	for action in saved_keys:
		var keycode := int(saved_keys[action])
		if keycode > 0:
			keybinds[String(action)] = keycode

	return true
