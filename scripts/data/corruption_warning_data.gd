class_name CorruptionWarningData
extends RefCounted

## Rotating copy for the corruption tier warning. Every variant keeps the exact
## mechanical numbers of its tier, so the HUD never loses information. Picking
## is stable per run + tier and never touches the run RNG (the loot sequence
## must not shift).

const MECHANICS := {
	1: "敌人伤害 +15%，短语墨耗 +15%。",
	2: "敌人伤害 +30%，短语墨耗 +30%，冷却 +20%。",
	3: "敌人伤害 +45%，短语墨耗 +45%，冷却 +35%。",
}

const LEADS := {
	1: [
		"污染低语",
		"纸页边缘渗出细声",
		"喉咙里多了一道声音",
		"墨在血管里轻轻敲打",
	],
	2: [
		"污染侵蚀",
		"名字被泡软了一半",
		"低语开始替你数拍子",
		"影子比你先动了一步",
	],
	3: [
		"深渊缠身",
		"纸背伸出湿冷的手",
		"你听见自己在很远的地方尖叫",
		"墨雨落进骨头缝里",
	],
}

const FRENZY: Array[String] = [
	"污染失控。昌子再也压不住喉咙里的东西。",
	"污染失控。那个名字正从喉咙里往外爬。",
	"污染失控。昌子听见自己的声音在别处说话。",
	"污染失控。墨把最后一页空白也吞了。",
]


static func variants(tier: int) -> Array[String]:
	if tier == 4:
		return FRENZY.duplicate()
	if not LEADS.has(tier):
		return []
	var result: Array[String] = []
	for lead in LEADS[tier]:
		result.append("%s：%s" % [String(lead), String(MECHANICS[tier])])
	return result


## Stable for one run + tier, without touching run.rng.
static func pick(run_seed: int, tier: int) -> String:
	var entries := variants(tier)
	if entries.is_empty():
		return ""
	return entries[posmod(hash("%d:%d" % [run_seed, tier]), entries.size())]
