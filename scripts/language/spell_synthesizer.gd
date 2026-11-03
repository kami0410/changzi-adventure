class_name SpellSynthesizer
extends RefCounted

## 言出法随的离线推演器（v2）。
##
## 文本先被拆成“已拥有的词 / 未收录的词义 / 意图修饰”三层：
## - 已拥有：用 WordData 原样参与结算；
## - 未收录：借用同标签的“回声词”，但带污染、降低稳定度；
## - 意图：范围、连续、缓慢、治愈、护盾、吸血、献祭、目标。
## 任何输入都会得到一个可装备、可施放、可解释的法术。
## AI 钩子只返回意图/模板；数值仍由本文件钳制。

const MAX_WORDS := 4
const TAG_WORDS: Dictionary = {
	&"flame": ["火", "焰", "燃烧", "烧", "灼", "炎", "焚", "烬", "燃"],
	&"thunder": ["雷", "电", "闪电", "风暴", "轰鸣", "霹雳", "暴风"],
	&"blood": ["血", "猩红", "悲鸣", "吸", "噬", "流血"],
	&"time": ["时间", "时", "静默", "缓慢", "迟滞", "回望", "永恒", "停", "慢"],
	&"abyss": ["深渊", "渊", "侵蚀", "毒", "腐", "破碎", "虚空", "黑"],
	&"shield": ["护", "盾", "庇护", "保护", "守", "悬鱼"],
	&"summon": ["召唤", "回声", "影", "使魔", "灵"],
	&"life": ["生命", "生", "治愈", "恢复", "回血", "活"],
	&"archive": ["记录", "档案", "铭刻", "书", "页", "写", "记", "记忆"],
	&"movement": ["迅捷", "闪", "跃", "疾", "风", "快"],
	&"ice": ["冰", "霜", "冻", "寒", "雪"],
	&"wind": ["风", "气", "羽", "翼", "飞"],
	&"earth": ["岩", "土", "山", "石", "骨"],
	&"water": ["水", "海", "潮", "雨", "浪"],
	&"light": ["光", "日", "明", "圣", "辉"],
	&"shadow": ["影", "暗", "黑", "夜", "幕"],
	&"dream": ["梦", "眠", "幻", "醒"],
	&"star": ["星", "辰", "坠"],
	&"moon": ["月", "夜", "潮"],
	&"door": ["门", "钥", "开", "关", "路"],
	&"mirror": ["镜", "双", "反", "映"],
	&"feather": ["羽", "翼", "飞", "轻"],
	&"bone": ["骨", "骸", "墓", "白"],
	&"heart": ["心", "血", "生"],
	&"eye": ["眼", "目", "看", "读"],
	&"crown": ["冠", "王", "权", "座"],
	&"flower": ["花", "根", "绽", "树"],
	&"song": ["歌", "唱", "诗", "曲"],
	&"sound": ["声", "响", "喧", "静"],
	&"memory": ["记忆", "忘", "记", "梦"],
	&"holy": ["圣", "神", "净", "光"],
	&"purify": ["净化", "洗涤", "洗去", "赦免", "洁净", "涤", "净", "洗"],
	&"corruption": ["污", "腐", "毒", "秽", "蚀"],
	&"scale": ["巨大", "微小", "巨", "微", "大", "小"],
	&"multi": ["连续", "多", "连", "重", "复"],
	&"reverse": ["逆", "反", "倒", "回"],
	&"final": ["最后", "终", "末", "尽"],
	&"first": ["第一", "初", "始", "首"],
	&"nameless": ["无名", "未名", "空", "虚"],
	&"space": ["空间", "距离", "折叠", "虚空", "宇宙"],
	&"order": ["秩序", "法则", "律", "审判", "规则"],
	&"chaos": ["混沌", "狂乱", "乱", "疯"],
	&"name": ["名字", "真名", "姓名", "名"],
	&"ink": ["墨", "墨水", "墨汁", "泼墨"],
	&"word": ["字", "词", "言", "文字", "句子"],
	&"silence": ["沉默", "寂静", "缄默", "噤声"],
}
const TAG_MEANING: Dictionary = {
	&"flame": "火", &"thunder": "雷", &"blood": "血", &"time": "时",
	&"abyss": "渊", &"shield": "护", &"summon": "回声", &"life": "生命",
	&"archive": "记录", &"movement": "迅捷",
	&"ice": "冰", &"wind": "风", &"earth": "岩", &"water": "水",
	&"light": "光", &"shadow": "影", &"dream": "梦", &"star": "星",
	&"moon": "月", &"door": "门", &"mirror": "镜", &"feather": "羽",
	&"bone": "骨", &"heart": "心", &"eye": "眼", &"crown": "冠",
	&"flower": "花", &"song": "歌", &"sound": "声", &"memory": "记忆",
	&"holy": "圣", &"purify": "净化", &"corruption": "污", &"scale": "尺度", &"multi": "连续",
	&"reverse": "逆", &"final": "终", &"first": "初", &"nameless": "无名",
	&"space": "空间", &"order": "秩序", &"chaos": "混沌", &"name": "真名",
	&"ink": "墨", &"word": "字", &"silence": "寂静",
}
const TAG_COMPONENTS: Dictionary = {
	&"flame": {&"damage": 2.0, &"area": 0.4},
	&"thunder": {&"damage": 2.0},
	&"blood": {&"damage": 1.0, &"lifesteal": 0.12},
	&"time": {&"slow": 0.2},
	&"abyss": {&"damage": 2.0, &"corruption_gain": 1.0},
	&"shield": {&"shield": 4.0},
	&"summon": {&"summon": 1.0},
	&"life": {&"heal": 2.0},
	&"archive": {&"shield": 1.0},
	&"movement": {&"move_speed": 0.15},
	&"ice": {&"slow": 0.25, &"damage": 1.0},
	&"wind": {&"move_speed": 0.2, &"knockback": 1.5},
	&"earth": {&"shield": 2.0, &"damage": 1.0, &"knockback": 1.0},
	&"water": {&"heal": 1.0, &"slow": 0.1},
	&"light": {&"heal": 2.0, &"shield": 1.0},
	&"shadow": {&"summon": 1.0, &"damage": 1.0},
	&"dream": {&"slow": 0.2, &"heal": 1.0},
	&"star": {&"damage": 2.0, &"area": 0.4, &"explosion": 1.0},
	&"moon": {&"slow": 0.2, &"heal": 1.0},
	&"door": {&"move_speed": 0.15, &"shield": 1.0},
	&"mirror": {&"shield": 2.0, &"damage": 1.0},
	&"feather": {&"move_speed": 0.25, &"projectiles": 3.0, &"homing": 0.6},
	&"bone": {&"damage": 2.0, &"shield": 1.0},
	&"heart": {&"heal": 3.0},
	&"eye": {&"damage": 2.0, &"pierce": 1.0},
	&"crown": {&"damage": 2.0, &"shield": 2.0, &"duration": 2.0},
	&"flower": {&"heal": 2.0, &"area": 0.3},
	&"song": {&"summon": 1.0, &"damage": 1.0},
	&"sound": {&"damage": 2.0, &"area": 0.2},
	&"memory": {&"heal": 1.0, &"slow": 0.1},
	&"holy": {&"heal": 3.0, &"shield": 2.0},
	&"purify": {&"purify": 6.0, &"heal": 1.0},
	&"corruption": {&"damage": 2.0, &"corruption_gain": 2.0},
	&"scale": {&"area": 0.8},
	&"multi": {&"area": 0.2},
	&"reverse": {&"damage": 2.0, &"slow": 0.2},
	&"final": {&"damage": 3.0},
	&"first": {&"damage": 2.0, &"shield": 1.0},
	&"nameless": {&"damage": 2.0, &"corruption_gain": 1.0},
	&"space": {&"area": 0.6, &"slow": 0.15},
	&"order": {&"damage": 2.0, &"stun": 0.4},
	&"chaos": {&"damage": 3.0, &"corruption_gain": 2.0},
	&"name": {&"damage": 3.0, &"pierce": 1.0},
	&"ink": {&"damage": 1.0, &"ink_gain": 4.0},
	&"word": {&"damage": 1.0, &"projectiles": 3.0},
	&"silence": {&"slow": 0.25, &"stun": 0.3},
}
const SHAPE_WORDS: Dictionary = {
	&"blade": ["斩", "砍", "刺", "刃", "剑", "切"],
	&"chain": ["雷", "电", "连锁", "风暴"],
	&"flame": ["烧", "燃", "焰", "火", "焚"],
	&"blood": ["血", "噬", "吸"],
	&"vortex": ["时间", "停", "慢", "迟滞", "漩涡", "黑洞"],
	&"ward": ["护", "盾", "守", "保护"],
	&"sentinel": ["召唤", "回声", "使魔"],
	&"void": ["深渊", "侵蚀", "虚空", "毒"],
	&"missile": ["追踪", "导弹", "飞弹", "弹幕", "万箭", "飞剑", "群鸦"],
	&"beam": ["光束", "射线", "贯穿", "激光", "穿透", "一线"],
	&"quake": ["地裂", "地震", "裂地", "冲击波", "震地", "崩山", "山崩"],
	&"meteor": ["陨石", "流星", "坠星", "天降", "星落", "砸下"],
	&"domain": ["领域", "结界", "光环", "大阵", "法阵", "王座"],
}
## Checked before SHAPE_WORDS so explicit form words beat element words
## ("火焰追踪弹" is a homing volley, not a flamethrower).
const SHAPE_PRIORITY: Array[StringName] = [&"meteor", &"quake", &"domain", &"beam", &"missile"]
const SCALE_WORDS: Dictionary = {
	&"area": ["巨大", "爆炸", "爆发", "范围", "四周", "周围", "全场", "轰"],
	&"multi": ["连续", "连环", "多次", "暴雨", "弹幕", "不断"],
	&"slow": ["缓慢", "迟滞", "冻结", "停下", "静止"],
	&"heal": ["治愈", "恢复", "愈合", "回血"],
	&"shield": ["护盾", "保护", "守护"],
	&"lifesteal": ["吸血", "吞噬", "吸取"],
	&"corruption": ["献祭", "禁术", "污染", "腐化"],
	&"homing": ["追踪", "追击", "锁定", "跟踪", "寻敌"],
	&"pierce": ["贯穿", "穿透", "洞穿", "一线"],
	&"explosion": ["爆炸", "爆裂", "炸开", "引爆", "爆发"],
	&"stun": ["定身", "眩晕", "定住", "冻住", "石化", "定"],
	&"knockback": ["击退", "推开", "震飞", "吹飞", "弹开"],
	&"pull": ["吸入", "吞吸", "拉扯", "引力", "黑洞"],
	&"burn": ["灼烧", "点燃", "焚烧", "燃尽"],
	&"long": ["持续", "永久", "长久", "不灭", "一直"],
}
const TARGET_SELF: Array[String] = ["自己", "自身", "我"]
const TARGET_AREA: Array[String] = ["周围", "四周", "附近", "全场", "身边"]

static var remote_provider: Callable = Callable()


static func synthesize(text: String, known_words: Array) -> ResolvedPhrase:
	var cleaned := text.strip_edges()
	if cleaned.is_empty():
		return null
	if remote_provider.is_valid():
		var payload = remote_provider.call(cleaned)
		if payload is Dictionary:
			if payload.has("damage") or payload.has("ink_cost"):
				var legacy := _from_payload(cleaned, payload)
				if legacy != null:
					return legacy
			else:
				var remote := _from_intent(cleaned, payload, known_words)
				if remote != null:
					return remote
	var analysis := analyze(cleaned, known_words)
	var words := _build_words(analysis, known_words)
	var resolver := PhraseResolver.new()
	var phrase := resolver.resolve(words)
	if phrase == null:
		return null
	phrase.from_text = cleaned
	phrase.synthesis = analysis
	_apply_intent(phrase, analysis)
	return phrase


static func analyze(text: String, known_words: Array) -> Dictionary:
	var canonical := _canonical(text)
	var matched := _match_known(canonical, known_words)
	var matched_tags: Dictionary = {}
	for word in matched:
		for tag in word.tags:
			matched_tags[tag] = true
	var tags: Array[StringName] = []
	for tag in TAG_WORDS.keys():
		if _contains_any(canonical, TAG_WORDS[tag]):
			tags.append(StringName(tag))
	var concepts: Array[StringName] = []
	for tag in tags:
		if not matched_tags.has(tag):
			concepts.append(tag)
	var intent := {
		&"area": _contains_any(canonical, SCALE_WORDS[&"area"]),
		&"multi": _contains_any(canonical, SCALE_WORDS[&"multi"]),
		&"slow": _contains_any(canonical, SCALE_WORDS[&"slow"]),
		&"heal": _contains_any(canonical, SCALE_WORDS[&"heal"]),
		&"shield": _contains_any(canonical, SCALE_WORDS[&"shield"]),
		&"lifesteal": _contains_any(canonical, SCALE_WORDS[&"lifesteal"]),
		&"corruption": _contains_any(canonical, SCALE_WORDS[&"corruption"]),
		&"self": _contains_any(canonical, TARGET_SELF),
		&"area_target": _contains_any(canonical, TARGET_AREA),
	}
	for key in [&"homing", &"pierce", &"explosion", &"stun", &"knockback", &"pull", &"burn", &"long"]:
		intent[key] = _contains_any(canonical, SCALE_WORDS[key])
	intent[&"count"] = count_before(canonical, COUNT_MEASURES)
	intent[&"repeat"] = count_before(canonical, REPEAT_MEASURES)
	var shape: StringName = &""
	for candidate in SHAPE_PRIORITY:
		if _contains_any(canonical, SHAPE_WORDS[candidate]):
			shape = candidate
			break
	if shape == &"":
		for candidate in SHAPE_WORDS.keys():
			if _contains_any(canonical, SHAPE_WORDS[candidate]):
				shape = StringName(candidate)
				break
	var terms: Array[String] = []
	for word in matched:
		terms.append(word.meaning)
	for tag in concepts:
		terms.append(TAG_MEANING.get(tag, String(tag)))
	return {
		&"matched": matched,
		&"matched_terms": terms,
		&"concepts": concepts,
		&"tags": tags,
		&"intent": intent,
		&"shape": shape,
		&"wild": matched.is_empty() and concepts.is_empty(),
	}


static func _build_words(analysis: Dictionary, known_words: Array) -> Array[WordData]:
	var result: Array[WordData] = []
	var matched: Array = analysis.get(&"matched", [])
	for word in matched:
		if result.size() >= MAX_WORDS:
			break
		result.append(word)
	var concepts: Array = analysis.get(&"concepts", [])
	for tag in concepts:
		if result.size() >= MAX_WORDS:
			break
		result.append(_concept_word(StringName(tag)))
	if result.is_empty():
		var terms: Array = analysis.get(&"matched_terms", [])
		var wild_text := "未名"
		if not terms.is_empty():
			wild_text = String(terms[0])
		result.append(_wild_word(wild_text))
	return result


static func _apply_intent(phrase: ResolvedPhrase, analysis: Dictionary) -> void:
	var intent: Dictionary = analysis.get(&"intent", {})
	var components := phrase.components
	if bool(intent.get(&"area", false)):
		components[&"area"] = float(components.get(&"area", 0.0)) + 0.8
		components[&"damage"] = float(components.get(&"damage", 0.0)) + 1.0
	if bool(intent.get(&"multi", false)):
		phrase.spell[&"pulses"] = maxi(int(phrase.spell.get(&"pulses", 1)), 2)
	if bool(intent.get(&"slow", false)):
		components[&"slow"] = float(components.get(&"slow", 0.0)) + 0.2
	if bool(intent.get(&"heal", false)):
		components[&"heal"] = float(components.get(&"heal", 0.0)) + 2.0
	if bool(intent.get(&"shield", false)):
		components[&"shield"] = float(components.get(&"shield", 0.0)) + 3.0
	if bool(intent.get(&"lifesteal", false)):
		components[&"lifesteal"] = float(components.get(&"lifesteal", 0.0)) + 0.1
	if bool(intent.get(&"corruption", false)):
		components[&"corruption_gain"] = float(components.get(&"corruption_gain", 0.0)) + 4.0
	if bool(intent.get(&"homing", false)):
		components[&"homing"] = maxf(float(components.get(&"homing", 0.0)), 1.0)
		components[&"projectiles"] = maxf(float(components.get(&"projectiles", 0.0)), 5.0)
	if bool(intent.get(&"pierce", false)):
		components[&"pierce"] = float(components.get(&"pierce", 0.0)) + 2.0
	if bool(intent.get(&"explosion", false)):
		components[&"explosion"] = float(components.get(&"explosion", 0.0)) + 1.5
	if bool(intent.get(&"stun", false)):
		components[&"stun"] = float(components.get(&"stun", 0.0)) + 0.8
	if bool(intent.get(&"knockback", false)):
		components[&"knockback"] = float(components.get(&"knockback", 0.0)) + 2.5
	if bool(intent.get(&"pull", false)):
		components[&"pull"] = float(components.get(&"pull", 0.0)) + 1.5
	if bool(intent.get(&"burn", false)):
		components[&"burn"] = float(components.get(&"burn", 0.0)) + 3.0
	if bool(intent.get(&"long", false)):
		components[&"duration"] = float(components.get(&"duration", 0.0)) + 3.0
	var count := int(intent.get(&"count", 0))
	var repeat := int(intent.get(&"repeat", 0))
	# 说得越大，代价越大：numbers in the sentence buy volume with ink, time and
	# corruption ("读到超出人类容量的句子"), not with free damage.
	var claim_cost := 0
	var claim_corruption := 0
	if count >= 2:
		components[&"projectiles"] = maxf(float(components.get(&"projectiles", 0.0)), float(count))
		claim_cost += int(ceil(float(mini(count, 400) - 1) / 4.0))
		claim_corruption += maxi(count - 20, 0) / 10
	if repeat >= 2:
		phrase.spell[&"pulses"] = maxi(int(phrase.spell.get(&"pulses", 1)), repeat)
		claim_cost += mini(repeat, 32) * 2
		claim_corruption += maxi(repeat - 4, 0)
	phrase.components = components
	phrase.ink_cost += claim_cost
	phrase.cooldown += minf(float(claim_cost) * 0.04, 3.0)
	phrase.corruption_gain += claim_corruption
	var shape: StringName = StringName(analysis.get(&"shape", &""))
	if shape != &"" and SpellStyle.NAMES.has(shape):
		phrase.spell[&"shape"] = shape
		phrase.spell[&"name"] = SpellStyle.NAMES[shape]
		phrase.spell[&"description"] = SpellStyle.DESCRIPTIONS.get(shape, "")
		phrase.spell[&"color"] = SpellStyle.color_for(phrase.tags, shape)
		phrase.spell[&"range"] = float(SpellStyle.base_for(shape)[&"range"])
	var concepts: Array = analysis.get(&"concepts", [])
	phrase.ink_cost = clampi(phrase.ink_cost + concepts.size() * 2, 4, 60)
	phrase.cooldown = clampf(phrase.cooldown + concepts.size() * 0.1, 1.0, 9.0)


static func compile_intent(text: String, intent: Dictionary, known_words: Array = []) -> ResolvedPhrase:
	return _from_intent(text, intent, known_words)


static func abyssal_phrase(text: String) -> ResolvedPhrase:
	var cleaned := text.strip_edges()
	if cleaned.is_empty():
		return null
	var word := WordData.new()
	word.id = StringName("__abyss_%d" % absi(cleaned.hash()))
	word.glyph = "渊"
	word.meaning = cleaned.substr(0, 12)
	word.tags = [&"abyss", &"wild"]
	word.power = 4
	word.corruption = 8
	word.decoded = true
	word.components = {
		&"damage": 18.0 + float(cleaned.length()) * 2.0,
		&"area": 1.0,
		&"slow": 0.1,
		&"corruption_gain": 20.0,
	}
	word.description = "AI 无法理解这句话，深渊替你补完了剩下的部分。"
	var phrase := PhraseResolver.new().resolve([word])
	if phrase == null:
		return null
	phrase.from_text = cleaned
	phrase.display_name = "深渊回响 · " + cleaned.substr(0, 10)
	phrase.spell[&"shape"] = &"void"
	phrase.spell[&"name"] = "深渊回响"
	phrase.spell[&"description"] = "这不是你写下的句子。它很强，但它正在读你。"
	phrase.spell[&"color"] = Color("a24dff")
	phrase.spell[&"resonances"] = ["深渊污染"]
	phrase.spell[&"pulses"] = 1
	phrase.ink_cost = 18
	phrase.cooldown = 4.0
	phrase.stability = 0.3
	phrase.synthesis = {
		&"abyssal": true,
		&"matched": [],
		&"matched_terms": [],
		&"concepts": [&"abyss"],
		&"tags": [&"abyss", &"wild"],
		&"intent": {},
		&"shape": &"void",
		&"wild": true,
	}
	return phrase


static func explain(phrase: ResolvedPhrase) -> Dictionary:
	if phrase == null:
		return {}
	var analysis: Dictionary = phrase.synthesis
	var matched: Array[String] = []
	for word in analysis.get(&"matched", []):
		matched.append(word.meaning)
	var concepts: Array[String] = []
	for tag in analysis.get(&"concepts", []):
		concepts.append(TAG_MEANING.get(tag, String(tag)))
	return {
		"matched": "、".join(matched),
		"concepts": "、".join(concepts),
		"shape": SpellStyle.NAMES.get(phrase.spell.get(&"shape", &"blade"), "墨刃"),
		"wild": concepts.size() > 0,
		"intent": _intent_text(analysis.get(&"intent", {})),
	}


static func _intent_text(intent: Dictionary) -> String:
	var parts: Array[String] = []
	if bool(intent.get(&"area", false)):
		parts.append("范围")
	if bool(intent.get(&"multi", false)):
		parts.append("连续")
	if bool(intent.get(&"slow", false)):
		parts.append("迟滞")
	if bool(intent.get(&"heal", false)):
		parts.append("治愈")
	if bool(intent.get(&"shield", false)):
		parts.append("护盾")
	if bool(intent.get(&"lifesteal", false)):
		parts.append("吸取")
	if bool(intent.get(&"corruption", false)):
		parts.append("献祭")
	if bool(intent.get(&"self", false)):
		parts.append("自身")
	if bool(intent.get(&"area_target", false)):
		parts.append("周围")
	if int(intent.get(&"count", 0)) >= 2:
		parts.append("%d 发" % int(intent[&"count"]))
	if int(intent.get(&"repeat", 0)) >= 2:
		parts.append("%d 连" % int(intent[&"repeat"]))
	var extra := {&"homing": "追踪", &"pierce": "贯穿", &"explosion": "爆裂", &"stun": "定身",
		&"knockback": "击退", &"pull": "吸入", &"burn": "灼烧", &"long": "持续"}
	for key in extra:
		if bool(intent.get(key, false)):
			parts.append(extra[key])
	return " / ".join(parts)


static func _match_known(text: String, known_words: Array) -> Array[WordData]:
	var found: Array[Dictionary] = []
	for entry in known_words:
		var word := entry as WordData
		if word == null:
			continue
		var best := -1
		var exact := false
		for key in [word.meaning, String(word.id), word.glyph, word.phoneme]:
			if key != "":
				var index := text.find(key)
				if index >= 0 and (best < 0 or index < best or (index == best and key == word.meaning)):
					best = index
					exact = key == word.meaning
		if best < 0:
			for tag in word.tags:
				var aliases: Array = TAG_WORDS.get(tag, [])
				if _contains_any(text, aliases):
					best = 0
					break
		if best >= 0:
			found.append({"index": best, "exact": exact, "word": word})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a["exact"]) != bool(b["exact"]):
			return bool(a["exact"])
		return int(a["index"]) < int(b["index"]))
	var result: Array[WordData] = []
	var used_tags: Dictionary = {}
	for entry in found:
		if result.size() >= MAX_WORDS:
			break
		var word: WordData = entry["word"]
		var duplicate_concept := false
		for tag in word.tags:
			if used_tags.has(tag):
				duplicate_concept = true
				break
		if duplicate_concept:
			continue
		result.append(word)
		for tag in word.tags:
			used_tags[tag] = true
	return result


static func _concept_word(tag: StringName) -> WordData:
	var word := WordData.new()
	word.id = StringName("__concept_%s" % tag)
	word.glyph = String(TAG_MEANING.get(tag, "◌")).substr(0, 1)
	word.meaning = String(TAG_MEANING.get(tag, tag))
	word.tags = [tag, &"wild"]
	word.power = 2
	word.corruption = 1
	word.decoded = true
	word.components = {}
	for key in TAG_COMPONENTS.get(tag, {}):
		word.components[StringName(key)] = float(TAG_COMPONENTS[tag][key])
	word.description = "你还没有真正拥有这个词，只是借用了它的回声。"
	return word


static func _wild_word(text: String) -> WordData:
	var hash_value: int = absi(text.hash())
	var word := WordData.new()
	word.id = StringName("__wild_%d" % hash_value)
	word.glyph = text.substr(0, 1)
	word.phoneme = ""
	word.meaning = text.substr(0, 10)
	word.grammar_role = WordData.GrammarRole.NOUN
	word.tags = [&"wild", WILD_TAGS[hash_value % WILD_TAGS.size()]]
	word.power = 1 + (hash_value / 7) % 3
	word.corruption = 1 + (hash_value / 11) % 2
	word.decoded = true
	word.components = {&"damage": 2.0 + float((hash_value / 13) % 3)}
	word.description = "你刚刚说出、还没有被任何档案收录的词。"
	return word


const WILD_TAGS: Array[StringName] = [&"flame", &"thunder", &"blood", &"time", &"abyss", &"shield", &"summon", &"archive"]



## Measure words: a number before one of these sets how many things the
## spell releases ("三十道雷", "100 颗星") or how often it repeats ("三连斩").
const COUNT_MEASURES: Array[String] = ["颗", "道", "发", "支", "枚", "根", "把", "只", "个", "条", "柄", "朵", "片", "团", "群"]
const REPEAT_MEASURES: Array[String] = ["次", "重", "连", "轮", "段", "遍"]
const DIGITS := {"零": 0, "一": 1, "二": 2, "两": 2, "三": 3, "四": 4, "五": 5, "六": 6, "七": 7, "八": 8, "九": 9}
const UNITS := {"十": 10, "百": 100, "千": 1000, "万": 10000}


## Largest number written before a measure word, or 0. Reads Arabic digits
## and Chinese numerals up to 万 ("一百二十", "两千", "十").
static func count_before(text: String, measures: Array[String]) -> int:
	var best := 0
	for measure in measures:
		var from := 0
		while true:
			var index := text.find(measure, from)
			if index < 0:
				break
			from = index + 1
			var start := index
			while start > 0 and _is_numeral(text[start - 1]):
				start -= 1
			if start < index:
				best = maxi(best, parse_number(text.substr(start, index - start)))
	return best


static func parse_number(text: String) -> int:
	if text.is_valid_int():
		return clampi(text.to_int(), 0, 1000000)
	var total := 0
	var section := 0
	var digit := -1
	for index in text.length():
		var ch := text[index]
		if ch.is_valid_int():
			digit = (maxi(digit, 0) * 10) + ch.to_int()
		elif DIGITS.has(ch):
			digit = int(DIGITS[ch])
		elif UNITS.has(ch):
			var unit: int = UNITS[ch]
			if unit == 10000:
				total += (section + maxi(digit, 0)) * unit
				section = 0
			else:
				section += (digit if digit > 0 else 1) * unit
			digit = -1
	return clampi(total + section + maxi(digit, 0), 0, 1000000)


static func _is_numeral(ch: String) -> bool:
	return ch.is_valid_int() or DIGITS.has(ch) or UNITS.has(ch)


static func _canonical(text: String) -> String:
	var cleaned := text.strip_edges()
	for punctuation in ["，", "。", "！", "？", "、", "；", "：", "“", "”", "‘", "’", "《", "》", "（", "）", " ", "　", ",", ".", "!", "?", ";", ":"]:
		cleaned = cleaned.replace(punctuation, "")
	return cleaned


static func _contains_any(text: String, words: Array) -> bool:
	for word in words:
		if text.contains(String(word)):
			return true
	return false


static func _from_payload(text: String, payload: Dictionary) -> ResolvedPhrase:
	var phrase := ResolvedPhrase.new()
	phrase.display_name = String(payload.get("name", text.substr(0, 10)))
	phrase.from_text = text
	var damage := clampf(float(payload.get("damage", 5.0)), 1.0, 40.0)
	var components: Dictionary = {&"damage": damage}
	if payload.has("heal"):
		components[&"heal"] = clampf(float(payload["heal"]), 0.0, 20.0)
	if payload.has("shield"):
		components[&"shield"] = clampf(float(payload["shield"]), 0.0, 30.0)
	if payload.has("slow"):
		components[&"slow"] = clampf(float(payload["slow"]), 0.0, 0.6)
	if payload.has("area"):
		components[&"area"] = clampf(float(payload["area"]), 0.0, 2.0)
	phrase.components = components
	phrase.tags = [&"generated"]
	var shape := StringName(payload.get("shape", "blade"))
	var allowed: Array[StringName] = [&"flame", &"chain", &"blood", &"vortex", &"ward", &"sentinel", &"void", &"blade"]
	if not allowed.has(shape):
		shape = &"blade"
	phrase.spell = SpellStyle.decide([shape], components, 1)
	phrase.spell[&"shape"] = shape
	phrase.spell[&"name"] = str(payload.get("element", SpellStyle.NAMES.get(shape, "言灵")))
	phrase.spell[&"description"] = str(payload.get("description", "由你的话凝成的法术。"))
	var color_value = payload.get("color", SpellStyle.COLORS.get(shape, Color("79e8d5")))
	phrase.spell[&"color"] = color_value if color_value is Color else Color(str(color_value))
	phrase.ink_cost = clampi(int(payload.get("ink_cost", 12)), 4, 40)
	phrase.cooldown = clampf(float(payload.get("cooldown", 2.5)), 1.0, 6.0)
	phrase.corruption_gain = clampi(int(payload.get("corruption", 0)), 0, 20)
	phrase.word_count = 1
	phrase.signature = "ai:" + text.substr(0, 24)
	return phrase


## Every component an AI intent may set. Gameplay numbers are not capped here;
## PhraseCaster only limits how many entities one cast may spawn.
const INTENT_COMPONENTS: Array[StringName] = [
	&"damage", &"heal", &"shield", &"slow", &"area", &"lifesteal",
	&"summon", &"ink_gain", &"corruption_gain", &"burn", &"chain",
	&"pulses", &"projectiles", &"spread", &"duration", &"knockback",
	&"homing", &"pierce", &"explosion", &"stun", &"pull", &"move_speed",
]
## Below this confidence the AI admits it did not understand: the abyss
## finishes the sentence. Still strong, but it reads you back.
const ABYSS_CONFIDENCE := 0.25


static func _from_intent(text: String, payload: Dictionary, known_words: Array) -> ResolvedPhrase:
	var tags: Array[StringName] = []
	for tag in payload.get("tags", []):
		var tag_name := StringName(tag)
		if TAG_WORDS.has(tag_name) and not tags.has(tag_name):
			tags.append(tag_name)
	if tags.is_empty():
		return null
	var shape := StringName(payload.get("shape", "blade"))
	if not SpellStyle.NAMES.has(shape):
		shape = &"blade"
	var matched: Array[WordData] = []
	var used_tags: Dictionary = {}
	for entry in known_words:
		var word := entry as WordData
		if word == null:
			continue
		for tag in word.tags:
			if tags.has(tag) and not used_tags.has(tag):
				matched.append(word)
				for word_tag in word.tags:
					used_tags[word_tag] = true
				break
	var concepts: Array[StringName] = []
	for tag in tags:
		if not used_tags.has(tag):
			concepts.append(tag)
	var analysis := {
		&"matched": matched,
		&"matched_terms": _terms(matched),
		&"concepts": concepts,
		&"tags": tags,
		&"intent": {},
		&"shape": shape,
		&"wild": concepts.size() > 0,
	}
	var words := _build_words(analysis, known_words)
	var phrase := PhraseResolver.new().resolve(words)
	if phrase == null:
		return null
	phrase.from_text = text
	phrase.synthesis = analysis
	_apply_intent(phrase, analysis)
	var components: Dictionary = payload.get("components", {})
	for key in INTENT_COMPONENTS:
		if components.has(key):
			var number := float(components[key])
			if is_finite(number) and number >= 0.0:
				phrase.components[key] = number
	phrase.spell[&"pulses"] = _whole(float(phrase.components.get(&"pulses", phrase.spell.get(&"pulses", 1))))
	phrase.spell[&"projectiles"] = maxi(_whole(float(phrase.components.get(&"projectiles", 1))), 1)
	phrase.spell[&"spread"] = maxf(float(phrase.components.get(&"spread", 0.0)), 0.0)
	phrase.display_name = String(payload.get("name", phrase.display_name))
	phrase.spell[&"name"] = phrase.display_name if phrase.display_name != "" else phrase.spell.get(&"name", "言灵")
	phrase.spell[&"description"] = String(payload.get("description", phrase.spell.get(&"description", "")))
	if payload.has("color"):
		phrase.spell[&"color"] = Color.from_string(String(payload["color"]), phrase.spell.get(&"color", Color("79e8d5")))
	var vfx := _vfx_recipe(payload.get("vfx", {}))
	if not vfx.is_empty():
		phrase.spell[&"vfx"] = vfx
	var feel := _feel_recipe(payload.get("feel", {}))
	if not feel.is_empty():
		phrase.spell[&"feel"] = feel
	# AI damage is "每次命中伤害": volleys must not divide it.
	phrase.spell[&"per_hit"] = true
	phrase.ink_cost = _whole(float(payload.get("ink_cost", phrase.ink_cost)))
	phrase.cooldown = maxf(_finite(payload.get("cooldown", phrase.cooldown)), 0.0)
	phrase.corruption_gain = _whole(float(payload.get("corruption_gain", phrase.corruption_gain)))
	var confidence := clampf(_finite(payload.get("confidence", 1.0), 1.0), 0.0, 1.0)
	phrase.synthesis[&"confidence"] = confidence
	if confidence < ABYSS_CONFIDENCE:
		_abyss_takes_over(phrase)
	return phrase


## Low-confidence AI output: more damage and area, far more corruption.
static func _abyss_takes_over(phrase: ResolvedPhrase) -> void:
	var c := phrase.components
	c[&"damage"] = maxf(float(c.get(&"damage", 0.0)) * 1.6, 18.0)
	c[&"area"] = float(c.get(&"area", 0.0)) + 0.6
	c[&"corruption_gain"] = float(c.get(&"corruption_gain", 0.0)) + 20.0
	phrase.components = c
	phrase.corruption_gain = maxi(phrase.corruption_gain, 0) + 20
	if not phrase.tags.has(&"abyss"):
		phrase.tags.append(&"abyss")
	phrase.unstable = true
	phrase.stability = minf(phrase.stability, 0.3)
	var resonances: Array = phrase.spell.get(&"resonances", [])
	if not resonances.has("深渊污染"):
		resonances.append("深渊污染")
	phrase.spell[&"resonances"] = resonances
	phrase.synthesis[&"abyssal"] = true


## Optional AI look: secondary colour, size, trail, rings, glyphs. Only render
## limits apply; anything non-finite or negative is dropped.
static func _vfx_recipe(source: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not source is Dictionary:
		return result
	var data := source as Dictionary
	if data.has("secondary"):
		var text := String(data["secondary"])
		if text.begins_with("#"):
			result[&"secondary"] = Color.from_string(text, Color("f1ddae"))
	var limits := {&"size": [0.4, 3.0], &"trail": [2.0, 24.0], &"rings": [1.0, 8.0], &"glyphs": [4.0, 32.0]}
	for key in limits:
		if data.has(String(key)):
			var value := _finite(data[String(key)], -1.0)
			if value >= 0.0:
				result[key] = clampf(value, limits[key][0], limits[key][1])
	return result


static func _feel_recipe(source: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not source is Dictionary:
		return result
	var data := source as Dictionary
	if data.has("screen_shake"):
		var shake := _finite(data["screen_shake"], -1.0)
		if shake >= 0.0:
			result[&"screen_shake"] = clampf(shake, 0.0, 2.0)
	if data.has("hit_stop"):
		var stop := _finite(data["hit_stop"], -1.0)
		if stop >= 0.0:
			result[&"hit_stop"] = clampf(stop, 0.0, 0.15)
	return result


static func _finite(value: Variant, fallback: float = 0.0) -> float:
	var number := float(value) if value is float or value is int or value is String else fallback
	return number if is_finite(number) else fallback


## Non-negative int that never overflows on absurd AI numbers.
static func _whole(value: float) -> int:
	if not is_finite(value):
		return 0
	return int(roundf(clampf(value, 0.0, 1.0e9)))


static func _terms(words: Array) -> Array[String]:
	var result: Array[String] = []
	for word in words:
		result.append((word as WordData).meaning)
	return result
