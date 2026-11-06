class_name RunSave
extends RefCounted

## Mid-run checkpoint at user://run_save.cfg. The profile owns cross-run
## progress; this file owns exactly one unfinished run. Writes are atomic and
## every read validates the version/shape before the game touches it, so a
## half-written or hand-edited file can never break a launch.

const SAVE_VERSION := 1
const DEFAULT_PATH := "user://run_save.cfg"


static func has_save(path: String = DEFAULT_PATH) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")


## Returns {} when the file is missing, corrupt, or from another version.
## Corrupt files are removed so the title cannot keep offering a broken run.
static func read(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak"):
		return {}
	var saved := _read_file(path)
	# A missing, truncated or hand-edited main file still has the previous
	# checkpoint in `.bak`. Read it with a fresh ConfigFile: a failed load
	# leaves the instance unusable for a second attempt.
	if saved.is_empty() and FileAccess.file_exists(path + ".bak"):
		saved = _read_file(path + ".bak")
		if not saved.is_empty():
			# Promote the good backup. Otherwise the next checkpoint would copy
			# the corrupt main over the only recoverable copy.
			_restore_main(saved, path)
	if saved.is_empty():
		clear(path)
	return saved


static func _read_file(path: String) -> Dictionary:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return {}
	var data: Variant = config.get_value("save", "data", {})
	if not data is Dictionary:
		return {}
	var saved: Dictionary = data
	if int(saved.get("version", 0)) != SAVE_VERSION:
		return {}
	if not _has_valid_shape(saved):
		return {}
	return saved


## The game reads these containers directly, so a hand-edited file with a
## correctly versioned top level but a string where a dictionary belongs would
## abort scene setup. Reject the checkpoint instead of trusting the shape.
static func _has_valid_shape(saved: Dictionary) -> bool:
	var run: Variant = saved.get("run", {})
	if not run is Dictionary:
		return false
	var run_data: Dictionary = run
	var room: Variant = run_data.get("room", "")
	if not (room is String or room is StringName) or String(room).is_empty():
		return false
	for key in [
		"seed", "rng_state", "difficulty", "chapter", "health", "max_health",
		"ink", "max_ink", "corruption", "corruption_gain_multiplier", "pages",
		"kills", "mercy", "records",
	]:
		if run_data.has(key) and not _is_number(run_data[key]):
			return false
	if run_data.has("burned_final") and not run_data["burned_final"] is bool:
		return false

	var inventory: Variant = saved.get("inventory", {})
	if not inventory is Dictionary:
		return false
	var items: Dictionary = inventory
	for key in ["words", "weapons", "phrases"]:
		if not items.has(key):
			continue
		if not items[key] is Array:
			return false
		for entry in items[key]:
			if entry != null and not entry is Dictionary:
				return false
	if items.has("relics"):
		if not items["relics"] is Array:
			return false
		for entry in items["relics"]:
			if not (entry is String or entry is StringName):
				return false

	for key in ["progress", "world", "authority", "mds"]:
		if saved.has(key) and not saved[key] is Dictionary:
			return false
	var progress: Dictionary = saved.get("progress", {})
	if progress.has("cleared_in_chapter") and not _is_number(progress["cleared_in_chapter"]):
		return false
	# The per-node keys are newer; the room-key lists are the legacy fallback
	# read by older checkpoints, so both are optional and both must be arrays.
	for key in ["cleared_encounters", "cleared_rooms", "vaults"]:
		if progress.has(key) and not progress[key] is Array:
			return false

	var world: Dictionary = saved.get("world", {})
	if world.has("boss_defeated") and not world["boss_defeated"] is bool:
		return false
	for key in [
		"claimed_stele_ids", "claimed_steles", "opened_chest_ids", "opened_chests",
		"example_phrases",
	]:
		if world.has(key) and not world[key] is Array:
			return false
	for key in ["shops", "frenzy"]:
		if world.has(key) and not world[key] is Dictionary:
			return false

	var authority: Dictionary = saved.get("authority", {})
	if authority.has("id") and not (authority["id"] is String or authority["id"] is StringName):
		return false
	for key in ["revive_used", "rewrite_used", "archive_used"]:
		if authority.has(key) and not authority[key] is bool:
			return false

	var mds: Dictionary = saved.get("mds", {})
	if mds.has("room") and not (mds["room"] is String or mds["room"] is StringName):
		return false
	for key in ["visited", "abilities", "stored", "objectives", "defeated", "bosses"]:
		if mds.has(key) and not mds[key] is Array:
			return false
	for key in ["areas", "moved", "map"]:
		if mds.has(key) and not mds[key] is Dictionary:
			return false
	if mds.has("position"):
		if not mds["position"] is Array or (mds["position"] as Array).size() != 2:
			return false
		for value in mds["position"]:
			if not _is_number(value):
				return false
	return true


static func _is_number(value: Variant) -> bool:
	return value is int or value is float


## Write a validated checkpoint over a corrupt main file without touching the
## backup that supplied it.
static func _restore_main(saved: Dictionary, path: String) -> void:
	var config := ConfigFile.new()
	config.set_value("save", "data", saved)
	var tmp := path + ".tmp"
	if config.save(tmp) != OK:
		return
	var tmp_absolute := ProjectSettings.globalize_path(tmp)
	if DirAccess.rename_absolute(tmp_absolute, ProjectSettings.globalize_path(path)) != OK:
		if FileAccess.file_exists(tmp):
			DirAccess.remove_absolute(tmp_absolute)


static func write(data: Dictionary, path: String = DEFAULT_PATH) -> bool:
	var config := ConfigFile.new()
	config.set_value("save", "data", data)
	var tmp := path + ".tmp"
	if config.save(tmp) != OK:
		return false
	var absolute := ProjectSettings.globalize_path(path)
	var tmp_absolute := ProjectSettings.globalize_path(tmp)
	var backup := path + ".bak"
	if FileAccess.file_exists(path):
		if DirAccess.copy_absolute(absolute, ProjectSettings.globalize_path(backup)) != OK:
			# Do not delete the only checkpoint when the backup copy failed.
			DirAccess.remove_absolute(tmp_absolute)
			return false
		if DirAccess.remove_absolute(absolute) != OK:
			DirAccess.remove_absolute(tmp_absolute)
			return false
	var error := DirAccess.rename_absolute(tmp_absolute, absolute)
	if error != OK:
		# Never lose the previous checkpoint to a failed rename.
		if FileAccess.file_exists(backup):
			DirAccess.copy_absolute(ProjectSettings.globalize_path(backup), absolute)
		return false
	return true


static func clear(path: String = DEFAULT_PATH) -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var full: String = path + String(suffix)
		if FileAccess.file_exists(full):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(full))


static func word_to_dict(word: WordData) -> Dictionary:
	if word == null:
		return {}
	var tags: Array = []
	for tag in word.tags:
		tags.append(String(tag))
	var components: Dictionary = {}
	for key in word.components:
		components[String(key)] = float(word.components[key])
	return {
		"id": String(word.id),
		"glyph": word.glyph,
		"phoneme": word.phoneme,
		"meaning": word.meaning,
		"grammar_role": int(word.grammar_role),
		"tags": tags,
		"power": word.power,
		"corruption": word.corruption,
		"decoded": word.decoded,
		"components": components,
		"description": word.description,
	}


static func word_from_dict(data: Dictionary) -> WordData:
	var id := StringName(String(data.get("id", "")))
	if id == &"":
		return null
	var word := WordData.new()
	word.id = id
	word.glyph = String(data.get("glyph", ""))
	word.phoneme = String(data.get("phoneme", ""))
	word.meaning = String(data.get("meaning", ""))
	word.grammar_role = clampi(int(data.get("grammar_role", 0)), 0, 2)
	var tags: Array[StringName] = []
	for tag in data.get("tags", []):
		tags.append(StringName(tag))
	word.tags = tags
	word.power = int(data.get("power", 1))
	word.corruption = int(data.get("corruption", 0))
	word.decoded = bool(data.get("decoded", false))
	var components: Dictionary[StringName, float] = {}
	var saved_components: Dictionary = data.get("components", {})
	for key in saved_components:
		components[StringName(key)] = float(saved_components[key])
	word.components = components
	word.description = String(data.get("description", ""))
	return word


static func phrase_to_dict(phrase: ResolvedPhrase) -> Dictionary:
	if phrase == null:
		return {}
	var words: Array = []
	for word in phrase.words:
		var entry := word_to_dict(word)
		if not entry.is_empty():
			words.append(entry)
	if words.is_empty():
		return {}
	var tags: Array = []
	for tag in phrase.tags:
		tags.append(String(tag))
	var components: Dictionary = {}
	for key in phrase.components:
		components[String(key)] = float(phrase.components[key])
	var resonances: Array = []
	for resonance in phrase.resonances:
		resonances.append(String(resonance))
	return {
		"words": words,
		"display_name": phrase.display_name,
		"from_text": phrase.from_text,
		"tags": tags,
		"components": components,
		"ink_cost": phrase.ink_cost,
		"cooldown": phrase.cooldown,
		"corruption_gain": phrase.corruption_gain,
		"unstable": phrase.unstable,
		"stability": phrase.stability,
		"word_count": phrase.word_count,
		"wild_count": phrase.wild_count,
		"resonances": resonances,
		"signature": phrase.signature,
		"spell": phrase.spell,
		"synthesis": phrase.synthesis,
	}


static func phrase_from_dict(data: Dictionary, resolver: PhraseResolver) -> ResolvedPhrase:
	if data.is_empty() or resolver == null:
		return null
	var words: Array[WordData] = []
	for entry in data.get("words", []):
		if not entry is Dictionary:
			continue
		var word := word_from_dict(entry)
		if word != null:
			words.append(word)
	if words.is_empty():
		return null
	var phrase := resolver.resolve(words)
	if phrase == null:
		return null
	var display_name := String(data.get("display_name", ""))
	if not display_name.is_empty():
		phrase.display_name = display_name
	phrase.from_text = String(data.get("from_text", ""))
	# Synthesis (especially AI-compiled intents) can add effects that are not
	# recoverable from word data alone; restore the computed phrase verbatim.
	if data.has("ink_cost"):
		phrase.ink_cost = int(data["ink_cost"])
	if data.has("cooldown"):
		phrase.cooldown = float(data["cooldown"])
	if data.has("corruption_gain"):
		phrase.corruption_gain = int(data["corruption_gain"])
	if data.has("unstable"):
		phrase.unstable = bool(data["unstable"])
	if data.has("stability"):
		phrase.stability = float(data["stability"])
	if data.has("word_count"):
		phrase.word_count = int(data["word_count"])
	if data.has("wild_count"):
		phrase.wild_count = int(data["wild_count"])
	if data.has("signature"):
		phrase.signature = String(data["signature"])
	var tags: Array[StringName] = []
	for tag in data.get("tags", []):
		tags.append(StringName(tag))
	if not tags.is_empty():
		phrase.tags = tags
	var components: Dictionary[StringName, float] = {}
	for key in data.get("components", {}):
		components[StringName(key)] = float(data["components"][key])
	if not components.is_empty():
		phrase.components = components
	var resonances: Array[String] = []
	for resonance in data.get("resonances", []):
		resonances.append(String(resonance))
	if not resonances.is_empty():
		phrase.resonances = resonances
	if data.has("spell"):
		phrase.spell = _string_name_keys(data["spell"])
	if data.has("synthesis"):
		phrase.synthesis = _string_name_keys(data["synthesis"])
	return phrase


## ConfigFile may return dictionary keys as String after a round-trip; the
## spell/component lookups in PhraseCaster use StringName keys.
static func _string_name_keys(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value:
			result[StringName(key)] = _string_name_keys(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_string_name_keys(item))
		return result
	return value
