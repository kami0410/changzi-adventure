class_name SpellStyle
extends RefCounted

## The visual and mechanical identity of a resolved phrase. Shapes are chosen
## from the words' tags, so the same damage can play like a swipe, a shock,
## a devouring beam, a time trap, a ward, a summoned echo, a homing barrage,
## a ground fissure, falling stars or a domain that walks with you.

const COLORS := {
	&"flame": Color("ff9c63"),
	&"blood": Color("e06372"),
	&"chain": Color("bcdcff"),
	&"vortex": Color("8f8be8"),
	&"ward": Color("8bd3bd"),
	&"sentinel": Color("90d6b8"),
	&"void": Color("b56fe0"),
	&"blade": Color("dfe7d7"),
	&"missile": Color("9fd8ff"),
	&"beam": Color("ffe9a8"),
	&"quake": Color("d8a46a"),
	&"meteor": Color("ffb36b"),
	&"domain": Color("7fe3c4"),
}

const NAMES := {
	&"flame": "焰",
	&"blood": "噬血",
	&"chain": "裂空",
	&"vortex": "迟滞漩涡",
	&"ward": "护写",
	&"sentinel": "回声",
	&"void": "渊蚀",
	&"blade": "墨刃",
	&"missile": "追踪弹幕",
	&"beam": "贯光",
	&"quake": "地裂",
	&"meteor": "坠星",
	&"domain": "领域",
}

const DESCRIPTIONS := {
	&"flame": "向前喷出扇焰，命中并点燃。",
	&"blood": "射出噬血墨束，命中回复生命。",
	&"chain": "召下闪电，在邻近敌人间连跳。",
	&"vortex": "留下一片把敌人拖向中心的时渊。",
	&"ward": "在身边写下护盾，并将周围敌人推开。",
	&"sentinel": "留下会自行追击的回声。",
	&"void": "引导高伤深渊，代价是污染。",
	&"blade": "挥出三段墨刃，适合贴身连斩。",
	&"missile": "放出一群会自己寻找目标的墨弹。",
	&"beam": "射出贯穿一整行的光束。",
	&"quake": "让地面沿着前方裂开，掀飞路上的敌人。",
	&"meteor": "从天顶召下坠星，砸向敌人。",
	&"domain": "展开随你移动的领域，持续侵蚀其中的敌人。",
}

## Per-shape defaults the caster builds on: reach in px, lifetime in seconds
## for persistent shapes, and how many bolts/stars a volley shape releases.
const BASE := {
	&"flame": {&"range": 155.0, &"duration": 0.0, &"count": 0},
	&"blood": {&"range": 320.0, &"duration": 0.0, &"count": 0},
	&"chain": {&"range": 320.0, &"duration": 0.0, &"count": 0},
	&"vortex": {&"range": 170.0, &"duration": 5.0, &"count": 0},
	&"ward": {&"range": 150.0, &"duration": 5.0, &"count": 0},
	&"sentinel": {&"range": 170.0, &"duration": 9.0, &"count": 0},
	&"void": {&"range": 170.0, &"duration": 0.0, &"count": 0},
	&"blade": {&"range": 170.0, &"duration": 0.0, &"count": 0},
	&"missile": {&"range": 520.0, &"duration": 0.0, &"count": 6},
	&"beam": {&"range": 640.0, &"duration": 0.0, &"count": 0},
	&"quake": {&"range": 420.0, &"duration": 0.0, &"count": 0},
	&"meteor": {&"range": 520.0, &"duration": 0.0, &"count": 3},
	&"domain": {&"range": 170.0, &"duration": 6.0, &"count": 0},
}


## Element colours win over shape colours, so a homing volley of fire still
## reads as fire. First matching tag in this order decides.
const ELEMENT_COLORS := [
	[&"flame", Color("ff9c63")], [&"thunder", Color("bcdcff")], [&"ice", Color("a9e6ff")],
	[&"blood", Color("e06372")], [&"star", Color("ffd27a")], [&"holy", Color("fff0b8")], [&"purify", Color("9fe8c8")],
	[&"abyss", Color("b56fe0")], [&"corruption", Color("9b5be0")], [&"chaos", Color("d36ad9")],
	[&"shadow", Color("8a7bd1")], [&"moon", Color("c9d6ff")], [&"light", Color("ffe9a8")],
	[&"wind", Color("b9f2e0")], [&"feather", Color("d9f5ea")], [&"earth", Color("d8a46a")],
	[&"bone", Color("e8dcc0")], [&"water", Color("6fb7e8")], [&"flower", Color("f2a7c3")],
	[&"life", Color("9fe8a8")], [&"dream", Color("c7a8f0")], [&"time", Color("8f8be8")],
	[&"crown", Color("f0c36c")], [&"order", Color("e6d7a3")], [&"space", Color("7c8cff")],
	[&"name", Color("f4e6c8")], [&"ink", Color("79e8d5")], [&"word", Color("dfe7d7")],
]


static func base_for(shape: StringName) -> Dictionary:
	return BASE.get(shape, BASE[&"blade"])


static func color_for(tags: Array, shape: StringName) -> Color:
	for entry in ELEMENT_COLORS:
		if tags.has(entry[0]):
			return entry[1]
	return COLORS.get(shape, COLORS[&"blade"])


static func decide(tags: Array[StringName], components: Dictionary, word_count: int = 1) -> Dictionary:
	var has := func(tag: StringName) -> bool: return tags.has(tag)
	var damage := float(components.get(&"damage", 0.0))
	var heal := float(components.get(&"heal", 0.0))
	var shield := float(components.get(&"shield", 0.0))
	var slow := float(components.get(&"slow", 0.0))
	var homing := float(components.get(&"homing", 0.0))
	var volley := float(components.get(&"projectiles", 0.0))
	var pierce := float(components.get(&"pierce", 0.0))
	var shape: StringName = &"blade"
	if has.call(&"summon"):
		shape = &"sentinel"
	elif has.call(&"star"):
		shape = &"meteor"
	elif homing >= 0.5 or volley >= 3.0:
		shape = &"missile"
	elif has.call(&"thunder"):
		shape = &"chain"
	elif has.call(&"shield") or (heal > 0.0 and damage <= 0.0) or (shield > 0.0 and damage <= 0.0) or (has.call(&"life") and damage <= 0.0):
		shape = &"ward"
	elif (has.call(&"earth") or has.call(&"bone")) and damage > 0.0:
		shape = &"quake"
	elif has.call(&"flame"):
		shape = &"flame"
	elif has.call(&"blood") or float(components.get(&"lifesteal", 0.0)) >= 0.2:
		shape = &"blood"
	elif (has.call(&"heart") or has.call(&"holy") or has.call(&"flower")) and heal + shield >= damage * 2.0:
		shape = &"ward"
	elif has.call(&"crown") or has.call(&"order"):
		shape = &"domain"
	elif has.call(&"time") or (slow > 0.0 and damage <= 0.0):
		shape = &"vortex"
	elif has.call(&"abyss") or has.call(&"corruption") or has.call(&"chaos"):
		shape = &"void"
	elif has.call(&"ice") or has.call(&"dream") or has.call(&"space"):
		shape = &"vortex"
	elif has.call(&"moon"):
		shape = &"domain"
	elif has.call(&"eye") or has.call(&"sight") or has.call(&"name") or pierce >= 1.0 or (has.call(&"light") and damage > 0.0):
		shape = &"beam"
	elif has.call(&"wind") or has.call(&"feather") or has.call(&"word"):
		shape = &"missile"
	elif has.call(&"water"):
		shape = &"blood"
	elif has.call(&"light") or has.call(&"holy") or has.call(&"heart") or has.call(&"flower") or has.call(&"sound"):
		shape = &"ward"
	elif has.call(&"shadow") or has.call(&"nameless"):
		shape = &"void"
	elif has.call(&"door") or has.call(&"mirror") or has.call(&"song"):
		shape = &"sentinel"
	elif has.call(&"bone") or has.call(&"earth"):
		shape = &"ward" if shield > 0.0 else &"quake"
	var pulses := 3 if shape == &"blade" else 1
	if tags.has(&"movement") or tags.has(&"flame") and tags.has(&"time"):
		pulses = maxi(pulses, 2)
	if word_count >= 4 and shape == &"blade":
		pulses = 4
	# Word-level "pulses" components are extra repetitions on top of the shape's own.
	pulses += int(clampf(float(components.get(&"pulses", 0.0)), 0.0, 32.0))
	var spread := 1.0
	if tags.has(&"thunder"):
		spread = 2.0
	elif tags.has(&"abyss"):
		spread = 1.35
	var base := base_for(shape)
	return {
		&"shape": shape,
		&"color": color_for(tags, shape),
		&"name": NAMES[shape],
		&"description": DESCRIPTIONS[shape],
		&"pulses": pulses,
		&"spread": spread,
		&"range": float(base[&"range"]),
		&"duration": float(base[&"duration"]),
		&"word_count": word_count,
		&"resonances": [],
	}


static func label(style: Dictionary) -> String:
	var text := "%s · %s" % [style.get(&"name", "墨刃"), style.get(&"description", "")]
	var resonances: Array = style.get(&"resonances", [])
	if not resonances.is_empty():
		text += "\n共鸣：" + " / ".join(resonances)
	return text
