class_name Ch2EventData
extends RefCounted

## Copy and tuning for the Chapter 2 event region (呼吸废墟). The mechanics are
## the same fixed pair the Chapter 1 page uses: reading always costs corruption
## and decodes one owned fragment (or pays pages when nothing is left to
## decode); taking always pays pages. Only the fiction rotates, seeded by the
## run and the plan's event node id, so a repeat run can read a different page.
##
## The lungs, the fog and the names of the dead are the Chapter 2 fiction set by
## docs/story-bible.md; 阿砚's lamp and nail follow the chapter intro copy. Do
## not turn these lines into new plot facts: they are flavour text only.

const CORRUPTION_COST := 8
const PAGES_REWARD := 12
const FALLBACK_PAGES := 6


static func variants() -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{
			"eyebrow": "事件 · 呼气",
			"title": "雾里飘来一页被呼出的名字。",
			"body": "听它念完，还是把纸收进书袋？",
			"read_label": "听它念完",
			"take_label": "收进书袋",
			"read_word_message": "名字入肺 · 解明「%s」，污染 +%d",
			"read_pages_message": "名字入肺 · 残页 +%d，污染 +%d",
			"take_message": "收起名字 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 钟摆",
			"title": "钟摆扫过墙面，停在一行小字上。",
			"body": "读那行字，还是把钟摆推回去？",
			"read_label": "读那行字",
			"take_label": "推回钟摆",
			"read_word_message": "钟摆停字 · 解明「%s」，污染 +%d",
			"read_pages_message": "钟摆停字 · 残页 +%d，污染 +%d",
			"take_message": "推回钟摆 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 灯芯",
			"title": "阿砚留下的灯芯还亮着，旁边压着一页纸。",
			"body": "就着灯读，还是把灯芯掐灭？",
			"read_label": "就着灯读",
			"take_label": "掐灭灯芯",
			"read_word_message": "灯下显字 · 解明「%s」，污染 +%d",
			"read_pages_message": "灯下显字 · 残页 +%d，污染 +%d",
			"take_message": "掐灭灯芯 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 钉子",
			"title": "墙里露出一截锈钉，钉着一页没被风吹走的字。",
			"body": "拔出钉子读，还是让它钉着？",
			"read_label": "拔出钉子",
			"take_label": "让它钉着",
			"read_word_message": "锈钉松口 · 解明「%s」，污染 +%d",
			"read_pages_message": "锈钉松口 · 残页 +%d，污染 +%d",
			"take_message": "留下钉子 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 肺叶",
			"title": "一片肺叶贴在墙上起伏，里面裹着一页纸。",
			"body": "割开肺叶，还是等它自己松开？",
			"read_label": "割开肺叶",
			"take_label": "等它松开",
			"read_word_message": "肺叶吐字 · 解明「%s」，污染 +%d",
			"read_pages_message": "肺叶吐字 · 残页 +%d，污染 +%d",
			"take_message": "等它松开 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 死名",
			"title": "雾退了一寸，露出半页写满名字的纸。",
			"body": "念出这些名字，还是把它折好？",
			"read_label": "念出名字",
			"take_label": "折好带走",
			"read_word_message": "死名回响 · 解明「%s」，污染 +%d",
			"read_pages_message": "死名回响 · 残页 +%d，污染 +%d",
			"take_message": "折好带走 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 余气",
			"title": "肺钟漏出最后一口气，气里有一句没说完的话。",
			"body": "把话吸进去，还是屏住呼吸？",
			"read_label": "吸进去",
			"take_label": "屏住呼吸",
			"read_word_message": "余气入喉 · 解明「%s」，污染 +%d",
			"read_pages_message": "余气入喉 · 残页 +%d，污染 +%d",
			"take_message": "屏住呼吸 · 残页 +%d",
		},
	]
	return result


## Stable for one run + event node id, without consuming run RNG: the event copy
## must not shift the loot sequence when the region is entered after a resume.
static func pick(run_seed: int, event_id: String) -> Dictionary:
	var entries := variants()
	if entries.is_empty():
		return {}
	return entries[posmod(hash("%d:%s" % [run_seed, event_id]), entries.size())]
