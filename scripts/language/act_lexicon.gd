class_name ActLexicon
extends RefCounted

## 言灵世界改写，离线读法 (1.1): finds the acts and "当…就…" rules a sentence
## asks for without any AI, so every verb in WorldActs can be spoken offline.
##
## The sentence is cut into clauses at punctuation. A clause that names a
## trigger ("每杀一个敌人", "每次受伤", "每三秒") turns the acts of the same
## clause — or, when it has none, of the next clause — into a rule; other
## clauses act at once. Numbers written before 秒 / 倍 / a measure word set
## how long, how strong and how many.
##
## As with the other world powers, saying it is enough: the price is ink,
## cooldown and corruption (PRICES), not a cap on what happens.

## verb -> [keywords, act template]. Checked in order; one clause can hold
## several acts.
const ACT_WORDS: Array = [
	[["缩小", "变小", "缩成", "渺小", "侏儒"], {"do": "shrink", "scale": 0.5}],
	[["巨大化", "变大", "膨胀"], {"do": "grow", "scale": 1.6}],
	[["削弱", "变弱", "虚弱", "无力", "软弱"], {"do": "weaken", "amount": 0.5}],
	[["缴械", "不能攻击", "无法攻击", "放下武器", "手无寸铁", "封印攻击"], {"do": "disarm"}],
	[["内讧", "自相残杀", "互相攻击", "反目", "窝里斗"], {"do": "infight", "count": 2.0}],
	[["变成", "化作", "化为", "变形"], {"do": "transform", "into": "scribe_bug"}],
	[["抛起", "飞上天", "浮空", "升天", "托起", "抛上"], {"do": "launch"}],
	[["拉过来", "拉到面前", "拽过来", "过来受死"], {"do": "pull"}],
	[["驱散", "清除弹幕", "子弹消失", "弹幕消失", "抹掉弹幕"], {"do": "dispel"}],
	[["失重", "低重力", "轻如羽毛", "月球", "漂浮"], {"do": "gravity", "amount": 0.35}],
	[["重力加倍", "千斤", "超重", "沉重"], {"do": "gravity", "amount": 2.0}],
	[["慢动作", "时间变慢", "子弹时间", "世界变慢", "放慢时间"], {"do": "time_scale", "amount": 0.5}],
	[["快进", "加速时间", "时间加速"], {"do": "time_scale", "amount": 1.6}],
	[["天黑", "黑暗降临", "熄灯", "永夜", "遮天"], {"do": "darkness"}],
	[["跳得更高", "高跳", "跳跃力", "一跃千里", "弹跳"], {"do": "jump", "amount": 1.5}],
	[["无限跳", "飞行", "飞起来", "御空", "凌空"], {"do": "air_jumps", "count": 99.0}],
	[["多段跳", "三段跳", "连跳", "再跳"], {"do": "air_jumps", "count": 3.0}],
	[["力量加倍", "伤害翻倍", "双倍伤害", "伤害加倍", "力量翻倍", "更强", "狂暴"], {"do": "power", "amount": 2.0}],
	[["坚不可摧", "减伤", "铁壁", "钢铁之躯", "皮糙肉厚"], {"do": "armor", "amount": 0.5}],
	[["冷却减半", "快速咏唱", "连续咏唱", "无冷却", "冷却缩短"], {"do": "cooldown", "amount": 0.5}],
	[["不耗墨", "免费施法", "墨水无限", "无限墨", "墨如泉涌"], {"do": "free_cast"}],
	[["墨墙", "一面墙", "一堵墙", "城墙", "立墙", "屏障"], {"do": "wall"}],
	[["墨桥", "一座桥", "长桥"], {"do": "platforms", "pattern": "bridge", "count": 6.0}],
	[["墨塔", "高塔", "天梯"], {"do": "platforms", "pattern": "tower", "count": 8.0}],
	[["背后", "身后", "绕后"], {"do": "teleport", "to": "behind_boss"}],
	[["到敌人身边", "贴身", "欺身"], {"do": "teleport", "to": "enemy"}],
	[["写出一把", "造一把", "给我一把", "铸一把", "赐我一把", "一柄"], {"do": "weapon"}],
	[["加速", "疾走", "疾行", "飞奔", "神速"], {"do": "haste", "amount": 1.5}],
	[["回墨", "补墨", "墨水回复", "恢复墨"], {"do": "ink", "amount": 20.0}],
	[["巨人", "顶天立地"], {"do": "resize_self", "scale": 1.6}],
	[["猎犬助战", "召来猎犬", "召唤猎犬", "放狗", "召唤墨犬", "召来墨犬"], {"do": "summon", "id": "ink_hound"}],
	[["召来书虫", "召唤书虫", "虫群助战"], {"do": "summon", "id": "scribe_bug", "count": 4.0}],
]
## What "变成 X" turns an enemy into.
const CREATURE_WORDS := {
	"scribe_bug": ["虫", "书虫", "蠹"],
	"ink_hound": ["狗", "犬", "猎犬"],
	"lung_moth": ["蛾", "蝴蝶", "飞蛾"],
	"page_swarm": ["纸", "纸片", "书页"],
	"seat_husk": ["椅", "空壳", "木头"],
}
const TRIGGER_WORDS := {
	"on_kill": ["每杀", "每击杀", "每次击杀", "每当击杀", "杀死一个", "每消灭", "每打倒", "每抹去"],
	"on_hurt": ["每次受伤", "每当受伤", "每次挨打", "每次被打", "每次被击中", "受伤时", "每受伤"],
	"on_hit": ["每次命中", "每次打中", "每次砍中", "每当命中", "每一刀", "每一击", "每次攻击"],
	"on_dodge": ["每次闪避", "每次翻滚", "每当闪避", "完美闪避时", "每次躲开"],
	"on_cast": ["每次施法", "每次咏唱", "每念一句", "每次施放", "每说一句"],
	"on_jump": ["每次跳", "每次起跳", "每当起跳", "每跳一次"],
	"on_low_health": ["濒死", "垂危", "快死", "残血", "生命垂危"],
	"on_room_clear": ["肃清", "清场", "清空房间", "每清完"],
	"every": ["每隔", "每过", "每秒", "秒一次"],
}
const SELF_WORDS: Array[String] = ["我", "自己", "自身", "昌子"]
const FOREVER_WORDS: Array[String] = ["本局", "整局", "这一局", "永远", "永久", "直到结束", "从今以后", "从此"]
const ALL_WORDS: Array[String] = ["所有", "全部", "全体", "每个敌人", "一切", "全场"]
const BOSS_WORDS: Array[String] = ["Boss", "boss", "首领", "馆长", "守护者", "读者"]
const WEAPON_RANGED: Array[String] = ["弓", "弩", "枪", "铳", "笔"]
const CLAUSE_BREAKS: Array[String] = ["，", ",", "。", "；", ";", "！", "!", "\n", "、", "然后", "并且", "同时"]
## verb -> [ink, corruption] added to the sentence. A rule costs double: it
## keeps happening.
const PRICES := {
	"shrink": [6, 2], "grow": [2, 0], "weaken": [6, 2], "disarm": [8, 4], "infight": [8, 4],
	"transform": [10, 6], "launch": [4, 1], "pull": [3, 1], "dispel": [6, 2], "gravity": [6, 3],
	"time_scale": [10, 6], "darkness": [3, 2], "jump": [3, 0], "air_jumps": [5, 2],
	"power": [10, 5], "armor": [8, 3], "cooldown": [10, 5], "free_cast": [0, 14],
	"wall": [5, 1], "platforms": [5, 1], "teleport": [5, 2], "weapon": [14, 8], "haste": [3, 0],
	"ink": [0, 6], "resize_self": [6, 3], "summon": [10, 5],
}
const DEFAULT_PRICE: Array = [5, 2]
const SECONDS_ACTS: Array[String] = ["shrink", "grow", "weaken", "disarm", "infight", "gravity", "time_scale",
	"darkness", "jump", "air_jumps", "power", "armor", "cooldown", "free_cast", "wall", "platforms", "haste",
	"resize_self", "summon"]
const AMOUNT_ACTS: Array[String] = ["power", "haste", "jump", "gravity"]
const COUNT_ACTS: Array[String] = ["summon", "platforms", "infight", "transform"]


## Reads a sentence. Returns `{acts, rules, ink, corruption}`; acts and rules
## are already in WorldActs' sanitized form.
static func read(text: String) -> Dictionary:
	var acts: Array = []
	var rules: Array = []
	var ink := 0
	var corruption := 0
	var pending: Dictionary = {}
	for clause in _clauses(text):
		var found := _acts_in(clause)
		var trigger := _trigger_in(clause)
		if trigger.is_empty() and not pending.is_empty() and not found.is_empty():
			# "每杀一个敌人，就回墨" — the trigger clause had no act of its own.
			pending["do"] = found
			rules.append(pending)
			pending = {}
			for act in found:
				var price := _price(act)
				ink += price[0] * 2
				corruption += price[1] * 2
			continue
		pending = {}
		if not trigger.is_empty():
			var rule := {"when": trigger, "seconds": _rule_seconds(clause), "interval": _interval(clause, trigger)}
			if found.is_empty():
				pending = rule
				continue
			rule["do"] = found
			rules.append(rule)
			for act in found:
				var price := _price(act)
				ink += price[0] * 2
				corruption += price[1] * 2
			continue
		for act in found:
			acts.append(act)
			var price := _price(act)
			ink += price[0]
			corruption += price[1]
	return {
		"acts": WorldActs.sanitize(acts),
		"rules": WorldActs.sanitize_rules(rules),
		"ink": ink,
		"corruption": corruption,
	}


static func _clauses(text: String) -> Array[String]:
	var marked := text
	for mark in CLAUSE_BREAKS:
		marked = marked.replace(mark, "\u0001")
	# "…就…" splits a trigger from what it does: "每杀一个敌人就回墨".
	for trigger in TRIGGER_WORDS:
		for word in TRIGGER_WORDS[trigger]:
			var at := marked.find(word)
			if at >= 0:
				var then := marked.find("就", at)
				var stop := marked.find("\u0001", at)
				if then >= 0 and (stop < 0 or then < stop):
					marked = marked.substr(0, then) + "\u0001" + marked.substr(then + 1)
	var out: Array[String] = []
	for part in marked.split("\u0001", false):
		var clause := part.strip_edges()
		if not clause.is_empty():
			out.append(clause)
	return out


static func _trigger_in(clause: String) -> String:
	for trigger in TRIGGER_WORDS:
		for word in TRIGGER_WORDS[trigger]:
			if clause.contains(word):
				return trigger
	# "每三秒" / "每 2 秒".
	if clause.contains("每") and SpellSynthesizer.count_before(clause, ["秒"]) > 0 \
			and clause.find("每") < clause.find("秒"):
		return "every"
	return ""


static func _acts_in(clause: String) -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	var seconds := SpellSynthesizer.count_before(clause, ["秒"])
	var times := SpellSynthesizer.count_before(clause, ["倍"])
	var count := SpellSynthesizer.count_before(clause, SpellSynthesizer.POWER_MEASURES)
	var about_self := _has(clause, SELF_WORDS)
	var forever := _has(clause, FOREVER_WORDS)
	for entry in ACT_WORDS:
		if not _has(clause, entry[0]):
			continue
		var act: Dictionary = (entry[1] as Dictionary).duplicate(true)
		var verb := String(act["do"])
		# "我变大 / 我变小" is about the speaker, not the enemies.
		if about_self and verb in ["shrink", "grow"] and _self_is_subject(clause, entry[0]):
			act = {"do": "resize_self", "scale": act["scale"]}
			verb = "resize_self"
		if seen.has(verb):
			continue
		seen[verb] = true
		if verb == "transform":
			act["into"] = _creature(clause)
		if verb == "weapon":
			act["name"] = _weapon_name(clause)
			act["kind"] = "ranged" if _has(clause, WEAPON_RANGED) else "melee"
			if count >= 2:
				act["damage"] = float(count)
		if verb == "teleport" and act["to"] == "behind_boss" and not _has(clause, BOSS_WORDS):
			act["to"] = "enemy"
		if seconds >= 1 and verb in SECONDS_ACTS:
			act["seconds"] = float(seconds)
		if times >= 2 and verb in AMOUNT_ACTS:
			act["amount"] = float(times) if verb != "gravity" else float(times)
		if times >= 2 and verb in ["grow", "resize_self"]:
			act["scale"] = float(times)
		if count >= 2 and verb in COUNT_ACTS:
			act["count"] = float(count)
		if _has(clause, BOSS_WORDS) and WorldActs.ACTS[StringName(verb)].has("target"):
			act["target"] = "boss"
		elif _has(clause, ALL_WORDS) and WorldActs.ACTS[StringName(verb)].has("target"):
			act["target"] = "all"
			act["count"] = 0.0
		# "本局伤害翻倍": a run-long rule instead of a timed buff.
		if forever and verb in ["power", "armor", "cooldown", "free_cast", "gravity"]:
			var key := {"power": "damage_dealt", "armor": "damage_taken", "cooldown": "cooldown",
				"free_cast": "ink_cost", "gravity": "gravity"}[verb] as String
			act = {"do": "mutator", "key": key, "seconds": 0.0,
				"amount": 0.0 if verb == "free_cast" else float(act.get("amount", 1.0))}
		out.append(act)
	return out


static func _self_is_subject(clause: String, words: Array) -> bool:
	for word in words:
		var at := clause.find(word)
		if at < 0:
			continue
		for me in SELF_WORDS:
			var mine := clause.find(me)
			if mine >= 0 and mine < at and not _has(clause.substr(mine, at - mine), ["敌", "它", "他们", "怪"]):
				return true
	return false


static func _creature(clause: String) -> String:
	for id in CREATURE_WORDS:
		if _has(clause, CREATURE_WORDS[id]):
			return id
	return "scribe_bug"


static func _weapon_name(clause: String) -> String:
	for marker in ["一把", "一柄"]:
		var at := clause.find(marker)
		if at >= 0:
			var name := clause.substr(at + marker.length(), 8)
			for stop in ["的武器", "给我", "，", "。", " "]:
				var cut := name.find(stop)
				if cut > 0:
					name = name.substr(0, cut)
			if not name.is_empty():
				return name
	return "言成之刃"


static func _rule_seconds(clause: String) -> float:
	if _has(clause, FOREVER_WORDS):
		return 0.0
	return WorldActs.DEFAULT_RULE_SECONDS


static func _interval(clause: String, trigger: String) -> float:
	if trigger != "every":
		return 1.0
	return maxf(float(SpellSynthesizer.count_before(clause, ["秒"])), 1.0)


static func _price(act: Dictionary) -> Array:
	var verb := String(act.get("do", ""))
	if verb == "mutator":
		return [16, 12]
	return PRICES.get(verb, DEFAULT_PRICE)


static func _has(text: String, words: Array) -> bool:
	for word in words:
		if text.contains(String(word)):
			return true
	return false
