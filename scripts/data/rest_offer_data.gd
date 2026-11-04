class_name RestOfferData
extends RefCounted

## Flavour copy for the rest card offered after every cleared room. The effect
## numbers stay in RunLoot/game.gd; this file only rotates the title and the
## short line above them. Picking is seeded by the run and the room number, so
## a resumed reward screen shows the same page and the pick never consumes the
## run RNG (the loot sequence must not shift).

const EFFECT_TEXT := "恢复 35 生命与 45 墨量。\n污染降低 12。"

const FLAVOURS: Array[Dictionary] = [
	{"title": "修补记忆", "flavour": "把撕开的边角对齐。"},
	{"title": "烘干墨迹", "flavour": "让潮气从纸背退去。"},
	{"title": "借一页空白", "flavour": "空白不记事，只让人喘息。"},
	{"title": "压平折角", "flavour": "把折起的名字摊平。"},
	{"title": "给灯添油", "flavour": "灯芯亮，影子退后。"},
	{"title": "念一遍名字", "flavour": "低声念完，手就不抖。"},
	{"title": "让雨停在窗外", "flavour": "屋檐下只剩翻页声。"},
	{"title": "缝住这一页", "flavour": "线脚粗，但字不再漏。"},
]


static func variants() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in FLAVOURS:
		result.append({
			"title": String(entry.get("title", "")),
			"description": String(entry.get("flavour", "")) + "\n" + EFFECT_TEXT,
		})
	return result


## Stable for one run + room, without touching run.rng.
static func pick(run_seed: int, room_number: int) -> Dictionary:
	var entries := variants()
	if entries.is_empty():
		return {}
	return entries[posmod(hash("%d:%d" % [run_seed, room_number]), entries.size())]
