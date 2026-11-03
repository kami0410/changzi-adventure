class_name PhraseResolver
extends RefCounted

## 言出法随：1–4 个词任意组合都成立，不再要求词性或位置。
## 词义通过标签相加，重复词递减；组合本身决定法术形态与共鸣。

const MIN_WORDS := 1
const MAX_WORDS := 4
const DUPLICATE_WEIGHT := 0.55


func validation_error(words: Array[WordData]) -> StringName:
	if words.is_empty():
		return &"too_few"
	if words.size() > MAX_WORDS:
		return &"too_many"
	for word in words:
		if word == null:
			return &"null_word"
	return &""


func resolve(words: Array[WordData]) -> ResolvedPhrase:
	if validation_error(words) != &"":
		return null

	var phrase := ResolvedPhrase.new()
	var meanings: Array[String] = []
	var tag_set: Dictionary = {}
	var components: Dictionary = {}
	var power := 0
	var corruption := 0
	var has_undecoded := false
	var seen: Dictionary = {}
	var duplicates := 0
	var wild_count := 0

	for word in words:
		if word.tags.has(&"wild"):
			wild_count += 1
		var weight := 1.0
		if seen.has(word.id):
			weight = DUPLICATE_WEIGHT
			duplicates += 1
		seen[word.id] = true
		meanings.append(word.meaning if word.decoded else word.glyph)
		power += int(round(word.power * weight))
		corruption += int(round(word.corruption * weight))
		if not word.decoded:
			has_undecoded = true
		for tag in word.tags:
			tag_set[tag] = true
		for key in word.components:
			_add(components, key, float(word.components[key]) * weight)

	var resonances := _apply_resonances(tag_set, components)
	phrase.display_name = "·".join(meanings)
	phrase.words = words.duplicate()
	phrase.components = components
	phrase.tags = _tag_array(tag_set)
	phrase.word_count = words.size()
	phrase.resonances = resonances

	# Price the spell from the effects it actually produces. Word power alone
	# let four damage words with a multi-pulse shape outrun their ink cost.
	var spell := SpellStyle.decide(phrase.tags, components, words.size())
	var complexity := 1.0 + 0.18 * float(words.size() - 1)
	var shape_scale := _shape_scale(components, spell)
	var budget := _effect_budget(components, shape_scale)
	phrase.ink_cost = clampi(int(round((6.0 + float(power) * 1.4 + budget * 0.9) * complexity)), 1, 95)
	phrase.cooldown = clampf(
		(1.2 + float(power) * 0.12 + budget * 0.075) * (1.0 + 0.1 * float(words.size() - 1)),
		0.8,
		9.0,
	)
	phrase.wild_count = wild_count
	phrase.stability = clampf(1.0 - 0.08 * float(words.size() - 1) - (0.15 if has_undecoded else 0.0) - 0.05 * duplicates - 0.08 * wild_count, 0.25, 1.0)
	phrase.corruption_gain = corruption + int(components.get(&"corruption_gain", 0.0)) + duplicates + wild_count * 2
	phrase.unstable = has_undecoded or wild_count > 0 or (tag_set.has(&"life") and tag_set.has(&"abyss"))
	if has_undecoded:
		phrase.corruption_gain += 3
	if duplicates > 0:
		phrase.corruption_gain += 1
	phrase.spell = spell
	phrase.spell[&"resonances"] = resonances
	# Stable cross-run key: word ids sorted, not meanings (which change with
	# decoding and display aliases).
	var ids: Array[String] = []
	for word in words:
		ids.append(String(word.id))
	ids.sort()
	phrase.signature = "%s|%d" % [",".join(ids), words.size()]
	return phrase


## Extra hits a shape really produces; these were previously free.
func _shape_scale(components: Dictionary, spell: Dictionary) -> float:
	var pulses := maxf(float(spell.get(&"pulses", 1)), 1.0)
	var projectiles := maxf(float(components.get(&"projectiles", 0.0)), 1.0)
	var area := maxf(float(components.get(&"area", 0.0)), 0.0)
	return 1.0 + (pulses - 1.0) * 0.16 + (projectiles - 1.0) * 0.05 + area * 0.12


func _effect_budget(components: Dictionary, shape_scale: float) -> float:
	var budget := 0.0
	budget += maxf(float(components.get(&"damage", 0.0)), 0.0) * shape_scale
	budget += maxf(float(components.get(&"heal", 0.0)), 0.0) * 0.6
	budget += maxf(float(components.get(&"shield", 0.0)), 0.0) * 0.6
	budget += maxf(float(components.get(&"purify", 0.0)), 0.0) * 0.8
	budget += maxf(float(components.get(&"slow", 0.0)), 0.0) * 1.6
	budget += maxf(float(components.get(&"stun", 0.0)), 0.0) * 1.6
	budget += maxf(float(components.get(&"lifesteal", 0.0)), 0.0) * 9.0
	budget += maxf(float(components.get(&"explosion", 0.0)), 0.0) * 1.8
	budget += maxf(float(components.get(&"chain", 0.0)), 0.0) * 1.2
	budget += maxf(float(components.get(&"summon", 0.0)), 0.0) * 1.8
	budget += maxf(float(components.get(&"knockback", 0.0)), 0.0) * 0.35
	return budget


func _apply_resonances(tag_set: Dictionary, components: Dictionary) -> Array[String]:
	var resonances: Array[String] = []
	if tag_set.has(&"life") and tag_set.has(&"archive"):
		_add(components, &"lifesteal", 0.15)
		_add(components, &"heal", 2.0)
		resonances.append("生命·记录")
	if tag_set.has(&"time") and tag_set.has(&"abyss"):
		_add(components, &"slow", 0.2)
		_add(components, &"area", 1.0)
		resonances.append("时间·深渊")
	if tag_set.has(&"corruption") and tag_set.has(&"authority"):
		_add(components, &"damage", 4.0)
		_add(components, &"corruption_gain", 5.0)
		resonances.append("污染·权柄")
	if tag_set.has(&"life") and tag_set.has(&"abyss"):
		_add(components, &"damage", 6.0)
		_add(components, &"corruption_gain", 6.0)
		resonances.append("生命·深渊")
	if tag_set.has(&"flame") and tag_set.has(&"thunder"):
		_add(components, &"damage", 2.0)
		resonances.append("雷火")
	if tag_set.has(&"time") and tag_set.has(&"flame"):
		_add(components, &"slow", 0.12)
		resonances.append("时焰")
	if tag_set.has(&"blood") and tag_set.has(&"shield"):
		_add(components, &"heal", 2.0)
		resonances.append("血护")
	if tag_set.has(&"abyss") and tag_set.has(&"summon"):
		_add(components, &"damage", 2.0)
		resonances.append("渊召")
	if tag_set.has(&"ice") and tag_set.has(&"flame"):
		_add(components, &"damage", 2.0)
		_add(components, &"area", 0.3)
		resonances.append("霜火")
	if tag_set.has(&"light") and tag_set.has(&"shadow"):
		_add(components, &"damage", 3.0)
		_add(components, &"corruption_gain", 3.0)
		resonances.append("蚀光")
	if tag_set.has(&"dream") and tag_set.has(&"star"):
		_add(components, &"slow", 0.15)
		_add(components, &"area", 0.4)
		resonances.append("星梦")
	if tag_set.has(&"water") and tag_set.has(&"thunder"):
		_add(components, &"area", 0.5)
		resonances.append("导电")
	if tag_set.has(&"song") and tag_set.has(&"sound"):
		_add(components, &"damage", 2.0)
		resonances.append("合唱")
	if tag_set.has(&"mirror") and tag_set.has(&"blood"):
		_add(components, &"lifesteal", 0.1)
		resonances.append("血镜")
	if tag_set.has(&"purify") and tag_set.has(&"holy"):
		_add(components, &"purify", 2.0)
		resonances.append("净化·圣")
	if tag_set.has(&"purify") and tag_set.has(&"water"):
		_add(components, &"purify", 1.0)
		_add(components, &"heal", 1.0)
		resonances.append("净化·水")
	if tag_set.has(&"purify") and tag_set.has(&"life"):
		_add(components, &"purify", 1.0)
		_add(components, &"heal", 2.0)
		resonances.append("净化·生")
	return resonances


func _tag_array(tag_set: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	for tag in tag_set.keys():
		result.append(StringName(tag))
	return result


func _add(target: Dictionary, key: StringName, value: float) -> void:
	target[key] = float(target.get(key, 0.0)) + value
