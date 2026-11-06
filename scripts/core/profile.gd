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
## One item preserved by the 归档 authority when a run ends in death. Handed to
## the next fresh run exactly once, then cleared.
var archived_item: Dictionary = {}
## Unbounded Archive altar levels: track id -> level.
var archive_levels: Dictionary = {}
## Per-word mastery XP; level = xp / 5, uncapped with diminishing returns.
var word_mastery: Dictionary = {}
var weapon_base_levels: Dictionary[StringName, int] = {}
var unlocked_patterns: Array[StringName] = []
## Current-format phrase signatures ("id1,id2|count") shown in the Codex.
var discovered_phrases: Array[String] = []
## v1 wrote meaning-based signatures here (e.g. "呓·火"). They cannot be
## mapped to word ids without guessing, so they are kept verbatim for data
## safety but never displayed or consulted by any gameplay logic.
var legacy_discovered_phrases: Array[String] = []
var endings: Array[String] = []
var runs_completed: int = 0
var records_found: int = 0
var shake_scale: float = 1.0
var flash_scale: float = 1.0
## Master bus volume, 0..1. Persisted with the other settings so the player
## does not have to re-adjust it every launch.
var master_volume: float = 1.0
## 言灵改变 NPC 职能后留下的长期效果；键为 npc_id → 效果名 → 数值。
var npc_blessings: Dictionary = {}
## 每个 NPC 对昌子的信任；用于 AI 对话口吻和隐藏回应。
var npc_trust: Dictionary = {}
## 已看过的 Hub 个人事件 id。只记事件本身，不给背包物品。
var npc_events: Array[String] = []
## 玩家自定义键位：action -> physical keycode。
var keybinds: Dictionary = {}
## 玩家自定义手柄键：action -> JoyButton。
var joybinds: Dictionary = {}


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
	if archive_level(track_id) >= ArchiveData.MAX_LEVEL:
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


func store_archived_item(kind: StringName, item_id: StringName) -> bool:
	if item_id == &"" or not (kind == &"relic" or kind == &"weapon"):
		return false
	archived_item = {"kind": String(kind), "id": String(item_id)}
	return true


## Hands the archived item to the next fresh run exactly once.
func consume_archived_item() -> Dictionary:
	var result := archived_item.duplicate()
	archived_item.clear()
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
	if not is_current_phrase_signature(signature) or discovered_phrases.has(signature):
		return false
	discovered_phrases.append(signature)
	return true


## Current signatures are "id1,id2,...|count" with word ids sorted by
## PhraseResolver. Anything else is a v1 meaning-based signature and belongs
## to legacy storage: guessing a word-id mapping could show players combos
## they never actually cast.
static func is_current_phrase_signature(signature: String) -> bool:
	var parts := signature.split("|")
	if parts.size() != 2:
		return false
	var count_text := parts[1]
	if not count_text.is_valid_int():
		return false
	var count := int(count_text)
	if count <= 0 or str(count) != count_text:
		return false
	var ids := parts[0].split(",")
	if ids.size() != count:
		return false
	for word_id in ids:
		if not _is_word_id(word_id):
			return false
	return true


static func _is_word_id(word_id: String) -> bool:
	# Synthetic wild words use "__wild_*" ids and stay ephemeral by design.
	if word_id.is_empty() or word_id.begins_with("__"):
		return false
	for index in word_id.length():
		var code := word_id.unicode_at(index)
		var is_lower := code >= 97 and code <= 122
		var is_digit := code >= 48 and code <= 57
		if not is_lower and not is_digit and code != 95:
			return false
	return true


func _add_legacy_phrase(signature: String) -> void:
	if signature.is_empty() or legacy_discovered_phrases.has(signature):
		return
	legacy_discovered_phrases.append(signature)


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


func has_npc_event(event_id: String) -> bool:
	return npc_events.has(event_id)


## Returns true only the first time, so a caller can tell whether to persist.
func record_npc_event(event_id: String) -> bool:
	if event_id.is_empty() or npc_events.has(event_id):
		return false
	npc_events.append(event_id)
	return true


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
	config.set_value("progress", "archived_item", archived_item)
	config.set_value("progress", "archive_levels", archive_levels)
	config.set_value("progress", "word_mastery", word_mastery)
	config.set_value("progress", "weapon_base_levels", weapon_base_levels)
	config.set_value("progress", "unlocked_patterns", unlocked_patterns)
	config.set_value("progress", "discovered_phrases", discovered_phrases)
	config.set_value("progress", "legacy_discovered_phrases", legacy_discovered_phrases)
	config.set_value("progress", "endings", endings)
	config.set_value("progress", "runs_completed", runs_completed)
	config.set_value("progress", "records_found", records_found)
	config.set_value("settings", "shake_scale", shake_scale)
	config.set_value("settings", "flash_scale", flash_scale)
	config.set_value("settings", "master_volume", master_volume)
	config.set_value("npc", "blessings", npc_blessings)
	config.set_value("npc", "trust", npc_trust)
	config.set_value("npc", "events", npc_events)
	config.set_value("input", "keybinds", keybinds)
	config.set_value("input", "joybinds", joybinds)

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
	# Fall back to the last good backup after a crashed write or a truncated
	# main file. A fresh ConfigFile is required: a failed load leaves the
	# instance unusable, so retrying on the same object would fail too.
	var loaded_backup := false
	if loaded != OK or not _is_valid_profile(config):
		var backup := path + ".bak"
		if not FileAccess.file_exists(backup):
			return false
		config = ConfigFile.new()
		loaded = config.load(backup)
		loaded_backup = loaded == OK and _is_valid_profile(config)
	if loaded != OK or not _is_valid_profile(config):
		return false
	if loaded_backup:
		# Keep the recovered copy as the main file; otherwise the next save
		# would overwrite the only good backup with the corrupt main file.
		_promote_backup(config, path)

	memory_fragments = _as_int(config.get_value("progress", "memory_fragments", 0), 0)

	unlocked_words = _read_names(config.get_value("progress", "unlocked_words", []))
	for default_id in DEFAULT_OWNED:
		if not unlocked_words.has(default_id):
			unlocked_words.append(default_id)

	# v1 saves have no decoded_words key: fall back to the six starter words
	# without touching the saved owned-word list.
	decoded_words = _read_names(
		config.get_value("progress", "decoded_words", DEFAULT_DECODED), DEFAULT_DECODED)

	pending_run_bonuses = {}
	var pending := _as_dictionary(config.get_value("progress", "pending_run_bonuses", {}))
	for key in pending:
		var bonus := _as_float(pending[key], NAN)
		if is_finite(bonus):
			pending_run_bonuses[String(key)] = bonus
	tutorial_done = _as_bool(config.get_value("progress", "tutorial_done", false), false)
	demo_cleared = _as_bool(config.get_value("progress", "demo_cleared", false), false)
	text_scale = clampi(_as_int(config.get_value("settings", "text_scale", 16), 16), 12, 20)

	stored_relics = _read_names(config.get_value("progress", "stored_relics", []))

	archived_item = {}
	var saved_archived := _as_dictionary(config.get_value("progress", "archived_item", {}))
	var archived_kind := _as_string(saved_archived.get("kind", ""))
	var archived_id := _as_string(saved_archived.get("id", ""))
	if (archived_kind == "relic" or archived_kind == "weapon") and not archived_id.is_empty():
		archived_item = {"kind": archived_kind, "id": archived_id}

	archive_levels = {}
	var saved_levels := _as_dictionary(config.get_value("progress", "archive_levels", {}))
	for key in saved_levels:
		archive_levels[String(key)] = _as_int(saved_levels[key], 0)

	word_mastery = {}
	var saved_mastery := _as_dictionary(config.get_value("progress", "word_mastery", {}))
	for key in saved_mastery:
		word_mastery[String(key)] = _as_int(saved_mastery[key], 0)

	weapon_base_levels.clear()
	var levels := _as_dictionary(config.get_value("progress", "weapon_base_levels", {}))
	for key in levels:
		var weapon_id := _as_string(key)
		if not weapon_id.is_empty():
			weapon_base_levels[StringName(weapon_id)] = _as_int(levels[key], 0)

	unlocked_patterns = _read_names(config.get_value("progress", "unlocked_patterns", []))

	# v1 and early v2 saves stored every signature under discovered_phrases,
	# including v1 meaning-based ones. Partition them once: current word-id
	# signatures keep working, raw v1 strings move to legacy storage. The
	# legacy key itself is never re-parsed, so repeated load/save is stable.
	discovered_phrases.clear()
	legacy_discovered_phrases.clear()
	for value in _as_array(config.get_value("progress", "discovered_phrases", [])):
		var signature := _as_string(value)
		if signature.is_empty():
			continue
		if is_current_phrase_signature(signature):
			if not discovered_phrases.has(signature):
				discovered_phrases.append(signature)
		else:
			_add_legacy_phrase(signature)
	for value in _as_array(config.get_value("progress", "legacy_discovered_phrases", [])):
		var legacy := _as_string(value)
		if not legacy.is_empty():
			_add_legacy_phrase(legacy)

	endings.clear()
	for value in _as_array(config.get_value("progress", "endings", [])):
		var ending := _as_string(value)
		if not ending.is_empty():
			endings.append(ending)
	runs_completed = _as_int(config.get_value("progress", "runs_completed", 0), 0)
	records_found = _as_int(config.get_value("progress", "records_found", 0), 0)
	shake_scale = clampf(_as_float(config.get_value("settings", "shake_scale", 1.0), 1.0), 0.0, 1.0)
	flash_scale = clampf(_as_float(config.get_value("settings", "flash_scale", 1.0), 1.0), 0.0, 1.0)
	master_volume = clampf(_as_float(config.get_value("settings", "master_volume", 1.0), 1.0), 0.0, 1.0)

	npc_blessings = {}
	var blessings := _as_dictionary(config.get_value("npc", "blessings", {}))
	for npc_key in blessings:
		var npc_name := _as_string(npc_key)
		var raw_entry = blessings[npc_key]
		if npc_name.is_empty() or not raw_entry is Dictionary:
			continue
		var entry: Dictionary = {}
		for effect_key in raw_entry:
			var effect_name := _as_string(effect_key)
			var amount := _as_float(raw_entry[effect_key], NAN)
			if not effect_name.is_empty() and is_finite(amount):
				entry[effect_name] = amount
		npc_blessings[npc_name] = entry
	npc_trust = {}
	var trust := _as_dictionary(config.get_value("npc", "trust", {}))
	for npc_key in trust:
		var npc_name := _as_string(npc_key)
		var amount := _as_float(trust[npc_key], NAN)
		if not npc_name.is_empty() and is_finite(amount):
			npc_trust[npc_name] = amount
	# Older saves have no events key: an empty list keeps them compatible.
	npc_events.clear()
	for value in _as_array(config.get_value("npc", "events", [])):
		var event_id := _as_string(value)
		if not event_id.is_empty() and not npc_events.has(event_id):
			npc_events.append(event_id)

	keybinds = {}
	var saved_keys := _as_dictionary(config.get_value("input", "keybinds", {}))
	for action in saved_keys:
		var action_name := _as_string(action)
		var keycode := _as_int(saved_keys[action], 0)
		if not action_name.is_empty() and keycode > 0:
			keybinds[action_name] = keycode

	joybinds = {}
	var saved_buttons := _as_dictionary(config.get_value("input", "joybinds", {}))
	for action in saved_buttons:
		var action_name := _as_string(action)
		var button := _as_int(saved_buttons[action], -1)
		if not action_name.is_empty() and button >= 0:
			joybinds[action_name] = button

	return true


## Field-level sanitizers: a hand-edited or partially corrupted profile must
## never abort halfway through loading and leave the player with an empty
## inventory. Bad fields fall back to their defaults; good fields survive.
static func _as_dictionary(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func _as_array(value: Variant) -> Array:
	return value if value is Array else []


static func _as_int(value: Variant, fallback_value: int = 0) -> int:
	if value is int:
		return value
	if value is float:
		return int(value) if is_finite(value) else fallback_value
	if value is bool:
		return 1 if value else 0
	return fallback_value


static func _as_float(value: Variant, fallback_value: float = 0.0) -> float:
	if value is int or value is float:
		var number := float(value)
		return number if is_finite(number) else fallback_value
	return fallback_value


static func _as_bool(value: Variant, fallback_value: bool = false) -> bool:
	return value if value is bool else fallback_value


static func _as_string(value: Variant, fallback_value: String = "") -> String:
	if value is String:
		return value
	if value is StringName:
		return String(value)
	return fallback_value


static func _read_names(value: Variant, fallback_value: Array = []) -> Array[StringName]:
	var result: Array[StringName] = []
	var source: Array = value if value is Array else fallback_value
	for entry in source:
		var name := _as_string(entry)
		if name.is_empty():
			continue
		var id := StringName(name)
		if not result.has(id):
			result.append(id)
	return result


## Write a known-good ConfigFile directly over the main path, leaving `.bak`
## intact. Used only when the main file failed and the backup was loaded.
static func _promote_backup(config: ConfigFile, path: String) -> void:
	var tmp := path + ".tmp"
	if config.save(tmp) != OK:
		return
	var tmp_absolute := ProjectSettings.globalize_path(tmp)
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
	if DirAccess.rename_absolute(tmp_absolute, absolute) != OK and FileAccess.file_exists(tmp):
		DirAccess.remove_absolute(tmp_absolute)


## A garbage file can parse as an empty config; require a version or a
## progress section before accepting it.
func _is_valid_profile(config: ConfigFile) -> bool:
	if int(config.get_value("meta", "version", 0)) > 0:
		return true
	return config.has_section("progress")
