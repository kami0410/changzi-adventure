class_name NPCProfiles
extends RefCounted

## Every hub character is a small person with a domain, a wound and a
## function. The same data drives offline replies, the AI prompt and the
## mechanical effect of a player's 言灵.

const PROFILES: Dictionary = {
	&"luchen": {
		"name": "陆沉",
		"title": "档案长 · 记忆的守门人",
		"domain": "语言、档案与记忆",
		"accent": Color(0.66, 0.34, 0.3, 1.0),
		"story": [
			"陆沉曾是宇宙档案馆最后一任档案长。他记得每一个来找自己改名的人，却故意不记得自己原来的名字。",
			"世界碎裂那天，他把名册撕成三页，分别藏进墨雨、呼吸废墟与无光海。他说那是为了保护记忆，其实也在保护自己。",
			"他教昌子读词，是因为只有昌子的喉咙还能承受完整的宇宙语言。他从不承认自己在利用昌子。",
		],
		"personality": "克制、耐心、学究气，愧疚时会把眼镜摘下来擦。",
		"greeting": "昌子。先坐下，把你今天听见的词说给我听。",
		"fallback": [
			"这句话不在我读过的档案里。但档案也不是世界本身。",
			"你刚才的发音让书架动了一下。再说一遍，慢一点。",
			"我听见了一个名字，但不确定那是你的还是我的。",
		],
		"trust_lines": [
			"档案长只对登记在册的人负责。你先把名字说清楚。",
			"你的脚步声我已经认得。坐吧，茶还是温的。",
			"有些页我本来不该给你看。但我想，你会替我记住。",
			"如果有一天我连自己的名字也忘了，你会替我写回去的，对吗？",
		],
		"functions": [
			{"id": &"decode", "name": "解词", "cost": 0, "desc": "让陆沉替你解开一个卡在喉咙里的词。"},
			{"id": &"lore", "name": "讲述档案", "cost": 6, "desc": "花费 6 记忆碎片，听一段被撕掉的世界史，并随机解开一个词。"},
			{"id": &"archive", "name": "档案馆升级", "cost": 0, "desc": "用记忆碎片永久强化生命、墨量、言灵伤害与污染抗性；demo 每个方向上限 10 级。"},
		],
		"keywords": {
			"名字": {"reply": "名字不是标签。是别人愿意为你保留的那一行。", "lore": 1.0},
			"记忆": {"reply": "记忆会骗人，档案不会。可档案也会被人改写。", "lore": 1.0},
			"真相": {"reply": "真相通常不是被藏起来的，是被写得太复杂。", "lore": 2.0},
			"老师": {"reply": "别叫我老师。老师会让学生替自己承担后果。", "trust": 1.0},
			"对不起": {"reply": "……你不需要替任何人道歉。至少现在不需要。", "trust": 2.0},
		},
		"ai_actions": [&"lore", &"decode"],
		"ai_system": "你是陆沉，宇宙档案馆的档案长，克制、愧疚、学识渊博。你相信记忆需要被保存，但也知道自己曾为了自保篡改档案。称呼玩家为昌子。回答不超过三句话，不要解释规则。",
	},
	&"ayan": {
		"name": "阿砚",
		"title": "锻造之神 · 被遗忘的守夜人",
		"domain": "锻造、武器与守护",
		"accent": Color(0.42, 0.62, 0.78, 1.0),
		"story": [
			"阿砚原本不是守夜人。他是旧世界最后一座军械库的锻造之神，替诸神铸过门闩、替死者铸过牙齿。",
			"世界忘记他的神名之后，他只剩下一间没有炉火的铁匠铺和一把永远修不好的断页剑。他给自己取名叫阿砚，假装只是个脾气不好的铁匠。",
			"他从不提“神”这个字，因为每次提起，铁砧上都会多一道裂纹。但他仍然会在没人看见的时候，对着剑胚念一段很旧的祷词。",
			"如果昌子能叫出他的真名，他也许愿意再为这个世界烧一次炉。",
		],
		"personality": "嘴硬、手稳、讨厌客套。谈到锻造时像换了一个人，充满近乎宗教的耐心。",
		"greeting": "刀口又卷了？拿过来。别碰炉子，烫。",
		"fallback": [
			"……你刚才那句话，让铁砧响了。再说一遍。",
			"我听不懂。但炉子听懂了，这就不关我的事。",
			"别在我铺子里说这种话。会把没成形的东西叫醒。",
		],
		"trust_lines": [
			"剑放砧上。人站远点。",
			"又是你。炉子刚热，别浪费。",
			"这把剑的毛病，只有你看得出来。别告诉别人。",
			"真名的事……等你准备好，再来问我一次。",
		],
		"functions": [
			{"id": &"forge", "name": "锻造基底", "cost": 0, "desc": "提升断页剑基底等级，所有掉落的断页剑都会继承。"},
			{"id": &"forge_god", "name": "神铸", "cost": 25, "desc": "花费 25 记忆碎片，唤醒一次锻造之神的本能：断页剑基底直接提升 1 级，并获得锻造祝福（上限 3）。"},
		],
		"keywords": {
			"锻造": {"reply": "锻造不是把铁打服。是让它想起自己本来该是什么形状。", "forge_discount": 0.12},
			"火": {"reply": "炉火从来没灭。只是我懒得添。", "forge_discount": 0.1},
			"神": {"reply": "……别叫我神。神不会把剑修成这样。", "forge_bonus": 1.0, "trust": 2.0},
			"真名": {"reply": "我的真名？你确定你的喉咙受得住？", "forge_free": 1.0, "corruption": 3.0},
			"守夜": {"reply": "守夜的人不需要名字。只要天还没亮，我就还在。", "forge_bonus": 1.0},
			"谢谢": {"reply": "少来这套。把剑拿稳，就是谢我。", "trust": 1.0},
		},
		"ai_actions": [&"forge", &"forge_god"],
		"ai_system": "你是阿砚，表面是脾气不好的铁匠，真实身份是被遗忘的锻造之神。你嘴硬、手稳、厌恶客套，但谈到锻造会变得虔诚。你从不主动承认神格；若玩家叫你真名或提到神，你会沉默、恼怒或流露极短暂的悲伤。回答不超过三句话。",
	},
	&"guru": {
		"name": "咕噜",
		"title": "语言残片的拾荒者 · 黑市商人",
		"domain": "交易、拾荒与 rumor",
		"accent": Color(0.82, 0.72, 0.3, 1.0),
		"story": [
			"咕噜不是这个世界原生的生物。它第一次出现时，正趴在一堆被烧焦的词上，把“永”和“恒”分开卖。",
			"它没有固定形状，靠吞下别人不要的记忆维持自己。它说这是生意，其实是在替那些记忆找一个不会被彻底忘记的地方。",
			"它最怕的不是死，是有一天没人再来买东西。那时候它就只是一团没有名字的旧纸。",
		],
		"personality": "热络、狡黠、害怕孤独。用玩笑掩饰自己其实很在意常客。",
		"greeting": "哟，史官大人。今天想买点什么？",
		"fallback": [
			"这句话我没进货。你要不要换个说法，我看看能不能收？",
			"哎哟，这话有点扎耳朵。不过扎耳朵的东西通常值钱。",
			"听不懂才好，听不懂的才没人跟我抢。",
		],
		"trust_lines": [
			"生面孔？先看看货，别急着讲价。",
			"哟，常客。今天的货给你留了一格。",
			"有些东西我不摆上架，只留给信得过的人。",
			"要是哪天我不在了，这堆旧记忆就归你。别让它们发霉。",
		],
		"functions": [
			{"id": &"shop", "name": "看看货", "cost": 0, "desc": "打开黑市货架，用记忆碎片换词与遗物。"},
			{"id": &"rumor", "name": "买一条传闻", "cost": 3, "desc": "花费 3 记忆碎片，听一条关于下一章的传闻，并获得一个随机未解锁词。"},
		],
		"keywords": {
			"便宜": {"reply": "便宜？你把我当什么了。……好吧，今天算你运气好。", "shop_discount": 0.18},
			"朋友": {"reply": "朋友？朋友可不会赊账。……但朋友可以打折。", "shop_discount": 0.12, "trust": 2.0},
			"记忆": {"reply": "记忆这玩意儿，放久了会发霉。拿出来换，才不亏。", "fragments": 6.0},
			"名字": {"reply": "名字是货架上最贵的东西。你确定要问价？", "lore": 1.0},
			"孤独": {"reply": "……你这人怎么突然说这个。买不买？不买别挡着我晒太阳。", "trust": 1.0},
		},
		"ai_actions": [&"shop", &"rumor"],
		"ai_system": "你是咕噜，一个靠吞食废弃记忆维生的黑市商人，外形圆润、语气热络、爱开玩笑，但害怕孤独。你称玩家为史官大人。你可以主动报价、讲价或送一点小东西，但不要离开商人的口吻。回答不超过三句话。",
	},
	&"wenjin": {
		"name": "闻烬",
		"title": "篡改史官 · 幸存的情报贩子",
		"domain": "情报、任务与谎言",
		"accent": Color(0.76, 0.42, 0.36, 1.0),
		"story": [
			"闻烬和昌子受过同一位老师的教导。她比昌子更早学会改写记录，也更早发现：改写记录比杀死一个人更彻底。",
			"世界碎裂后，她靠替人修改过去活了下来。她不觉得这是背叛，只觉得记忆本来就该由活着的人重新编排。",
			"她仍然留着昌子当年送她的一支笔。笔尖早就断了，但她从不换。",
		],
		"personality": "锋利、疲惫、警觉。对昌子有竞争心，也有无法承认的依赖。",
		"greeting": "你还活着。真可惜，我本来想把你那一页写得更精彩一点。",
		"fallback": [
			"这句话我没法归档。你是故意的吗？",
			"别用这种句子试探我。我改过的档案比你吃过的饭还多。",
			"有意思。你终于开始写一些连我都猜不到的东西了。",
		],
		"trust_lines": [
			"别靠太近。我不替陌生人改档案。",
			"你还没死。看来我上次那页写得不够狠。",
			"有一页我谁都没给看过。你例外，但只有一次。",
			"如果最后要有人记住我们谁先动的手……那个人得是你。",
		],
		"functions": [
			{"id": &"intel", "name": "买情报", "cost": 8, "desc": "花费 8 记忆碎片，获知下一章 Boss 的弱点，并让你所有武器的伤害永久 +2。"},
			{"id": &"contract", "name": "签一份契约", "cost": 12, "desc": "花费 12 记忆碎片，获得一条危险的捷径：本局起始多 10 残页，但污染 +6。"},
		],
		"keywords": {
			"真相": {"reply": "真相？真相只是还没被改得更好的版本。", "intel": 1.0},
			"谎言": {"reply": "谎言说久了，连说的人都会信。这很方便。", "intel": 1.0, "trust": 1.0},
			"昌子": {"reply": "别用那种眼神看我。我们都没得选。", "trust": 2.0},
			"老师": {"reply": "老师教我们保存记忆。可保存下来的，都是谁挑过的？", "intel": 1.0},
			"笔": {"reply": "……你还记得这支笔。那就别问它为什么断了。", "trust": 2.0},
		},
		"ai_actions": [&"intel", &"contract"],
		"ai_system": "你是闻烬，昌子的同门、竞争史官、情报贩子。你锋利、疲惫、警觉，靠改写记录活下来。你对昌子有竞争心，也有不愿承认的依赖。你说话带刺，但不会真的伤害昌子。回答不超过三句话。",
	},
	&"baiyu": {
		"name": "白榆",
		"title": "引路人 · 地图绘制者",
		"domain": "路线、地图与传闻",
		"accent": Color(0.42, 0.56, 0.86, 1.0),
		"story": [
			"白榆画过这个世界所有的路，包括那些已经不存在的地方。他的地图上有很多空白，因为有些地方他还没想好该不该让人找到。",
			"他从不告诉别人自己从哪里来。有人说他是活人，有人说他是地图自己长出来的。他两种说法都不否认。",
			"他愿意为昌子带路，但每次都会在岔路口多停一会儿，像是在等一个不会来的人。",
		],
		"personality": "平静、温和、保留。说话像在念一条很长的路。",
		"greeting": "路还在。只是这次，你想走哪一条？",
		"fallback": [
			"地图上没有这句话。也许它还没被走到。",
			"你指的方向不对。但我可以先陪你站一会儿。",
			"有些地方，名字比路先到。你刚才就快说出它的名字了。",
		],
		"trust_lines": [
			"路在脚下。你走你的，我跟不跟，看方向。",
			"这段路我陪你走过。下次可以走得慢一点。",
			"地图上有一块空白，我一直没画。也许该带你去看。",
			"如果走到没有路的地方，就照着你记得的我走。",
		],
		"functions": [
			{"id": &"map", "name": "绘制路线", "cost": 6, "desc": "花费 6 记忆碎片，获得下一章的路线与宝箱分布，并让本局起始多 8 残页。"},
			{"id": &"shortcut", "name": "寻找近路", "cost": 15, "desc": "花费 15 记忆碎片，找到一条不该存在的近路：本局起始多 15 残页。"},
		],
		"keywords": {
			"路": {"reply": "路不会消失。它只是会等你走错几次之后，才愿意出现。", "map_pages": 8.0},
			"地图": {"reply": "地图不是用来记住地方的。是用来决定哪些地方可以被忘记。", "map_pages": 10.0},
			"家": {"reply": "……家的位置我记得。只是回去的路，我还没画完。", "trust": 2.0, "map_pages": 6.0},
			"名字": {"reply": "名字是路标。没有名字的地方，最容易走丢。", "lore": 1.0},
			"谢谢": {"reply": "不用谢。我只是顺路。", "trust": 1.0},
		},
		"ai_actions": [&"map", &"shortcut"],
		"ai_system": "你是白榆，引路人与地图绘制者。你平静、温和、保留，知道很多路线，却从不解释自己的来历。你说话像在描述一条路。你愿意帮助昌子，但总像在等一个不会再出现的人。回答不超过三句话。",
	},
}


static func get_profile(npc_id: StringName) -> Dictionary:
	return PROFILES.get(npc_id, {}).duplicate(true)


static func all_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for key in PROFILES.keys():
		result.append(StringName(key))
	return result


## One attitude line per trust tier, in TrustData order. Missing profiles or
## lines return an empty string so callers can skip them safely.
static func trust_line(npc_id: StringName, tier: int) -> String:
	var lines: Array = PROFILES.get(npc_id, {}).get("trust_lines", [])
	if lines.is_empty():
		return ""
	return String(lines[clampi(tier, 0, lines.size() - 1)])


## Offline, deterministic interpretation of a player's 言灵.
## AI may replace the reply text, but the mechanical floor stays local.
## `trust` is the NPC's pre-conversation trust: at 熟悉 and above the reply
## carries the matching attitude line, so the offline path reflects tiers too.
static func resolve(npc_id: StringName, text: String, trust: float = 0.0) -> Dictionary:
	var data := get_profile(npc_id)
	if data.is_empty():
		return {"reply": "……", "effect": {}, "mood": "neutral", "matched": []}
	var cleaned := text.strip_edges()
	var effect: Dictionary = {}
	var matched: Array[String] = []
	var reply_parts: Array[String] = []
	for keyword in data.get("keywords", {}).keys():
		if cleaned.contains(keyword):
			matched.append(keyword)
			var entry: Dictionary = data["keywords"][keyword]
			if entry.has("reply"):
				reply_parts.append(String(entry["reply"]))
			for key in entry.keys():
				if key == "reply":
					continue
				effect[key] = float(effect.get(key, 0.0)) + float(entry[key])
	var power := 1.0 + float(cleaned.length()) * 0.08 + float(matched.size()) * 1.6
	if cleaned.length() >= 12:
		power += 1.0
	if matched.is_empty():
		# Unknown language is not rejected: it becomes an abyssal bargain.
		effect["corruption"] = float(effect.get("corruption", 0.0)) + 3.0
		effect["fragments"] = float(effect.get("fragments", 0.0)) + 4.0
		effect["trust"] = float(effect.get("trust", 0.0)) + 0.5
		var fallback: Array = data.get("fallback", [])
		if fallback.is_empty():
			reply_parts.append("……这句话我听不懂。但我听见了它里面的东西。")
		else:
			reply_parts.append(String(fallback[cleaned.hash() % fallback.size()]))
	else:
		effect["trust"] = float(effect.get("trust", 0.0)) + minf(power * 0.25, 2.0)
	var tier := TrustData.tier_index(trust)
	if tier > 0:
		var attitude := trust_line(npc_id, tier)
		if not attitude.is_empty():
			reply_parts.append(attitude)
	var mood := "warm" if effect.get("trust", 0.0) >= 1.0 else "neutral"
	if tier >= 2 and mood == "neutral":
		mood = "warm"
	if effect.get("corruption", 0.0) > 0.0:
		mood = "abyssal"
	var reply := " ".join(reply_parts)
	if reply.is_empty():
		reply = "我听着。继续说。"
	return {
		"reply": reply,
		"effect": effect,
		"mood": mood,
		"matched": matched,
		"power": power,
	}


## AI may perform one concrete favour for the player per NPC per hub visit.
## Only the functions authored for that NPC are accepted; discounts are clamped
## and free uses are limited by the caller.
static func validate_action(npc_id: StringName, raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var data := get_profile(npc_id)
	if data.is_empty():
		return {}
	var allowed: Array = data.get("ai_actions", [])
	var action_id := StringName(raw.get("id", &""))
	if not allowed.has(action_id):
		return {}
	var discount := clampf(float(raw.get("discount", 0.0)), 0.0, 0.35)
	var free := bool(raw.get("free", false))
	return {"id": action_id, "discount": discount, "free": free}


## Per-conversation caps. One NPC effect per Hub visit is enforced by
## apply_effect_once; these caps bound what a single effect may grant.
const EFFECT_LIMITS := {
	"fragments": 12.0,
	"map_pages": 20.0,
	"corruption": 6.0,
	"forge_bonus": 1.0,
	"forge_free": 1.0,
	"forge_discount": 0.35,
	"shop_discount": 0.35,
}
const FORGE_BONUS_TOTAL_CAP := 3.0


## One mechanical effect per NPC per Hub visit. The `used` dictionary is owned
## by the Hub scene and therefore resets when the Hub is rebuilt.
static func apply_effect_once(profile: Profile, npc_id: StringName, effect: Dictionary, used: Dictionary) -> Dictionary:
	if profile == null or npc_id == &"":
		return {}
	if used.has(npc_id):
		return {}
	used[npc_id] = true
	return apply_effect(profile, npc_id, effect)


## Apply the mechanical part of an NPC 言灵 with per-effect caps. Unknown keys
## are ignored. Start-of-run values go to pending_run_bonuses, not permanent
## blessings, so they cannot be stacked forever.
static func apply_effect(profile: Profile, npc_id: StringName, effect: Dictionary) -> Dictionary:
	if profile == null:
		return {}
	var applied: Dictionary = {}
	for key in effect.keys():
		var value := float(effect[key])
		if not is_finite(value) or value <= 0.0:
			continue
		value = minf(value, float(EFFECT_LIMITS.get(String(key), INF)))
		match String(key):
			"forge_bonus":
				var remaining := maxf(FORGE_BONUS_TOTAL_CAP - profile.npc_blessing(&"ayan", "forge_bonus", 0.0), 0.0)
				value = minf(value, remaining)
				if value <= 0.0:
					continue
				profile.add_npc_blessing(&"ayan", "forge_bonus", value)
				applied[key] = value
			"forge_discount":
				profile.add_npc_blessing(&"ayan", "forge_discount", value)
				applied[key] = value
			"forge_free":
				profile.add_npc_blessing(&"ayan", "forge_free", value)
				applied[key] = value
			"shop_discount":
				profile.add_npc_blessing(&"guru", "shop_discount", value)
				applied[key] = value
			"map_pages":
				profile.add_pending_run_bonus(&"start_pages", value)
				applied[key] = value
			"intel":
				profile.add_npc_blessing(&"wenjin", "intel", value)
				applied[key] = value
			"lore":
				profile.add_npc_blessing(&"luchen", "lore", value)
				applied[key] = value
			"fragments":
				profile.memory_fragments += maxi(int(roundf(value)), 0)
				applied[key] = value
			"corruption":
				profile.add_pending_run_bonus(&"start_corruption", value)
				applied[key] = value
			"trust":
				profile.add_npc_trust(npc_id, value)
				applied[key] = value
	return applied
