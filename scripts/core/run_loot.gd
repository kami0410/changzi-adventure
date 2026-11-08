class_name RunLoot
extends RefCounted

const STARTER_WORDS: Array[StringName] = [&"posui", &"ranshao", &"yan", &"jilu", &"gr", &"grguan"]
## Owned from the first run as word fragments: readable only as glyphs until
## decoded. Twelve covers the demo's 10–15 decodable-word target.
const DEMO_FRAGMENT_WORDS: Array[StringName] = [
	&"xue", &"dongjie", &"shenyuan", &"yongheng", &"zhaohuan", &"jinghua",
	&"tunshi", &"shouwang", &"guang", &"huiwang", &"guize", &"shensheng",
]


static func demo_word_pool() -> Array[WordData]:
	var result: Array[WordData] = []
	var wanted: Dictionary = {}
	for word_id in STARTER_WORDS:
		wanted[word_id] = true
	for word_id in DEMO_FRAGMENT_WORDS:
		wanted[word_id] = true
	for entry in ContentLibrary.WORDS:
		var word := entry as WordData
		if word != null and wanted.has(word.id):
			result.append(word)
	return result


static func _word_pool(chapter: int) -> Array[WordData]:
	if chapter == 0:
		return demo_word_pool()
	var result: Array[WordData] = []
	for entry in ContentLibrary.WORDS:
		var word := entry as WordData
		if word != null:
			result.append(word)
	return result


static func word_label(word: WordData) -> String:
	if word == null:
		return ""
	if word.decoded:
		return word.meaning
	return "%s（未解码）" % (word.glyph if word.glyph != "" else "？？？")


## Fragments the run already owns but has not decoded yet. The demo grants all
## twelve fragments at run start, so a "new word" reward must decode one of
## those instead of trying to add a word the player already owns.
static func owned_undecoded_words(run: RunState, profile: Profile, chapter: int = 0) -> Array[WordData]:
	var result: Array[WordData] = []
	if run == null:
		return result
	var allowed: Dictionary = {}
	for entry in _word_pool(chapter):
		var data := entry as WordData
		if data != null:
			allowed[data.id] = true
	for word in run.inventory.words:
		if word == null or word.decoded or not allowed.has(word.id):
			continue
		if profile != null and profile.is_word_decoded(word.id):
			continue
		result.append(word)
	return result


## Decodes an owned fragment in place: the Profile owns the cross-run state,
## while the run's copy feeds this run's Codex, inventory and phrase preview.
static func decode_owned_word(run: RunState, profile: Profile, word: WordData) -> bool:
	if run == null or word == null:
		return false
	var target: WordData = null
	for entry in run.inventory.words:
		if entry != null and entry.id == word.id:
			target = entry
			break
	if target == null or target.decoded:
		return false
	if profile != null:
		profile.decode_word(word.id)
	WordRuntime.mark_decoded(target)
	# Decoding mutates the run's word copy in place. The Codex and Inventory
	# grids are built from that copy, so notify them to rebuild; otherwise the
	# word keeps showing "未解码" until some unrelated inventory change.
	if run.inventory != null:
		run.inventory.changed.emit()
	return true


static func _weapon_pool(chapter: int) -> Array[Resource]:
	return ContentLibrary.DEMO_WEAPONS if chapter == 0 else ContentLibrary.WEAPONS


static func _relic_pool(chapter: int) -> Array[Resource]:
	return ContentLibrary.DEMO_RELICS if chapter == 0 else ContentLibrary.RELICS

static func starting_words(profile: Profile) -> Array[WordData]:
	var wanted: Dictionary = {}
	for word_id in STARTER_WORDS:
		wanted[word_id] = true
	for word_id in DEMO_FRAGMENT_WORDS:
		wanted[word_id] = true
	if profile != null:
		for word_id in profile.unlocked_words:
			wanted[word_id] = true
	var result: Array[WordData] = []
	for entry in ContentLibrary.WORDS:
		var word := entry as WordData
		if wanted.has(word.id):
			result.append(WordRuntime.for_run(word, profile))
	return result


static func weapon_for_run(source: WeaponData, profile: Profile, room_number: int = 0) -> WeaponData:
	var weapon := source.duplicate() as WeaponData
	var level := profile.weapon_base_level(weapon.id) if profile != null else 0
	var bonded_damage := 0
	if profile != null:
		bonded_damage = int(round(
			profile.npc_blessing(&"ayan", "damage", 0.0)
			+ profile.npc_blessing(&"wenjin", "damage", 0.0)
			+ profile.npc_blessing(&"luchen", "damage", 0.0)
			+ profile.npc_blessing(&"guru", "damage", 0.0)
			+ profile.npc_blessing(&"baiyu", "damage", 0.0)
			+ profile.npc_blessing(&"ayan", "forge_bonus", 0.0) * 3.0
		))
	weapon.damage += level * 2 + room_number * 2 + bonded_damage
	if room_number > 0:
		weapon.display_name += " +%d" % room_number
	return weapon


## Enemy drop: the same chapter pool used by rewards and chests, so Chapter 1
## never leaks a full-game weapon into the demo.
static func dropped_weapon(run: RunState, profile: Profile, chapter: int = 0) -> WeaponData:
	if run == null:
		return null
	var pool := _weapon_pool(chapter)
	if pool.is_empty():
		return null
	var base := pool[run.rng.randi_range(0, pool.size() - 1)] as WeaponData
	return weapon_for_run(base, profile, chapter * 2 + 1)


static func chest_loot(run: RunState, profile: Profile, chapter: int = 0) -> Dictionary:
	if run == null:
		return {}
	var roll := run.rng.randf()
	if roll < 0.55:
		var weapon_pool := _weapon_pool(chapter)
		var base := weapon_pool[run.rng.randi_range(0, weapon_pool.size() - 1)] as WeaponData
		var weapon := weapon_for_run(base, profile, 2 + chapter * 2)
		return {
			"kind": &"weapon",
			"resource": weapon,
			"title": "宝箱武器 · " + weapon.display_name,
			"description": "伤害 %d · 间隔 %.2f 秒" % [weapon.damage, weapon.attack_cooldown],
		}
	if roll < 0.8:
		var pool: Array[WordData] = []
		for word in _word_pool(chapter):
			if not run.inventory.has_word(word.id):
				pool.append(word)
		if not pool.is_empty():
			var picked := WordRuntime.for_run(pool[run.rng.randi_range(0, pool.size() - 1)], profile)
			return {
				"kind": &"word",
				"resource": picked,
				"title": "宝箱残页 · " + word_label(picked),
				"description": picked.description if picked.decoded else "一枚尚未解读的残页。",
			}
	var relic_pool: Array[RelicData] = []
	for entry in _relic_pool(chapter):
		var relic := entry as RelicData
		if not run.inventory.has_relic(relic.id):
			relic_pool.append(relic)
	if not relic_pool.is_empty():
		var picked_relic := relic_pool[run.rng.randi_range(0, relic_pool.size() - 1)]
		return {
			"kind": &"relic",
			"resource": picked_relic,
			"title": "宝箱遗物 · " + picked_relic.display_name,
			"description": RelicEffects.describe(picked_relic.effect_id),
		}
	return {"kind": &"pages", "title": "宝箱碎片", "description": "记忆碎片 +12"}


static func shop_offers(run: RunState, chapter: int, profile: Profile) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	offers.append({"kind": &"rest", "title": "缝合书页", "description": "恢复 35 生命与 45 墨量，并净化 12 点污染。", "cost": 15})
	var relic: RelicData = null
	var relic_pool: Array[RelicData] = []
	for entry in _relic_pool(chapter):
		var candidate := entry as RelicData
		if not run.inventory.has_relic(candidate.id):
			relic_pool.append(candidate)
	if not relic_pool.is_empty():
		relic = relic_pool[run.rng.randi_range(0, relic_pool.size() - 1)]
		offers.append({"kind": &"relic", "resource": relic, "title": "遗物 · " + relic.display_name,
			"description": RelicEffects.describe(relic.effect_id), "cost": 25})
	else:
		offers.append({"kind": &"vitality", "title": "厚重书页", "description": "最大生命 +15，并恢复 15 生命。", "cost": 20})
	var word_pool: Array[WordData] = []
	for candidate in _word_pool(chapter):
		if not run.inventory.has_word(candidate.id):
			word_pool.append(candidate)
	if not word_pool.is_empty():
		var word := WordRuntime.for_run(word_pool[run.rng.randi_range(0, word_pool.size() - 1)], profile)
		offers.append({"kind": &"word", "resource": word, "title": "新词 · " + word_label(word),
			"description": word.description if word.decoded else "一枚尚未解读的残页。", "cost": 20 + chapter * 2})
	else:
		var weapon_pool := _weapon_pool(chapter)
		offers.append({"kind": &"weapon", "resource": weapon_pool[run.rng.randi_range(0, weapon_pool.size() - 1)],
			"title": "一页武器", "description": "与当前手持武器交换；旧武器会掉在身后。", "cost": 24})
	return offers


## Elite rooms must pay out a build-defining item: a relic (or vitality when
## every relic is owned), ahead of the normal word/weapon filler.
static func elite_choices(run: RunState, room_number: int, profile: Profile, chapter: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = choices(run, room_number, profile, chapter)
	var available: Array[RelicData] = []
	for entry in _relic_pool(chapter):
		var relic := entry as RelicData
		if not run.inventory.has_relic(relic.id):
			available.append(relic)
	if available.is_empty():
		result[0] = {"kind": &"vitality", "title": "厚重书页", "description": "最大生命 +15，并恢复 15 生命。"}
	else:
		var relic := available[run.rng.randi_range(0, available.size() - 1)] as RelicData
		result[0] = {"kind": &"relic", "resource": relic, "title": relic.display_name,
			"description": _relic_reward_text(relic)}
	return result


## A zero-corruption relic must not advertise "污染 +0" on its reward card.
static func _relic_reward_text(relic: RelicData) -> String:
	var text := RelicEffects.describe(relic.effect_id)
	if relic.corruption > 0:
		text += "\n污染 +%d" % relic.corruption
	return text


static func choices(run: RunState, room_number: int, profile: Profile, chapter: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var available_relics: Array[Resource] = []
	for relic in _relic_pool(chapter):
		if not run.inventory.has_relic(relic.id):
			available_relics.append(relic)
	if not available_relics.is_empty():
		var relic := available_relics[run.rng.randi_range(0, available_relics.size() - 1)] as RelicData
		result.append({"kind": &"relic", "resource": relic, "title": relic.display_name,
			"description": _relic_reward_text(relic)})
	else:
		result.append({"kind": &"vitality", "title": "厚重书页", "description": "最大生命 +15，并恢复 15 生命。"})
	var available_words: Array[Resource] = []
	for word in _word_pool(chapter):
		if not run.inventory.has_word(word.id):
			available_words.append(word)
	if room_number % 2 == 1 and not available_words.is_empty():
		var word := WordRuntime.for_run(
			available_words[run.rng.randi_range(0, available_words.size() - 1)] as WordData, profile)
		var word_note := word.description if word.decoded else "一枚尚未解读的残页。在 Hub 找陆沉解读。"
		result.append({"kind": &"word", "resource": word, "title": "新词 · " + word_label(word),
			"description": word_note + "\n加入词库，可在语言图鉴里组合新短语。"})
	else:
		var weapon_pool := _weapon_pool(chapter)
		var base := weapon_pool[run.rng.randi_range(0, weapon_pool.size() - 1)] as WeaponData
		var weapon := weapon_for_run(base, profile, room_number)
		result.append({"kind": &"weapon", "resource": weapon, "title": weapon.display_name,
			"description": "伤害 %d · 间隔 %.2f 秒\n与当前武器交换；旧武器掉在身后，可拾回。" % [weapon.damage, weapon.attack_cooldown]})
	var rest := RestOfferData.pick(run.run_seed, room_number)
	if rest.is_empty():
		rest = {"title": "修补记忆", "description": RestOfferData.EFFECT_TEXT}
	result.append({"kind": &"rest", "title": rest["title"], "description": rest["description"]})
	return result
