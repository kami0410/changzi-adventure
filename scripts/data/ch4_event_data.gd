class_name Ch4EventData
extends RefCounted

## Copy and tuning for the Chapter 4 event region (笑面剧场). The mechanics are
## the same fixed pair the Chapter 1/2/3 pages use: reading always costs
## corruption and decodes one owned fragment (or pays pages when nothing is
## left to decode); taking always pays pages. Only the fiction rotates, seeded
## by the run and the plan's event node id, so a repeat run can read a
## different page.
##
## The theatre seats are full of paper people who applaud only the last page,
## the smiling archivist remembers every name, and the show ends on a curtain
## call (CampaignData chapter 4 intro/outro, docs/story-bible.md). These are
## flavour lines only; do not turn them into new plot facts.

const CORRUPTION_COST := 8
const PAGES_REWARD := 12
const FALLBACK_PAGES := 6


static func variants() -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{
			"eyebrow": "事件 · 纸人",
			"title": "观众席上坐满纸人，掌心里都攥着一页节目单。",
			"body": "抽一页来读，还是让它们继续鼓掌？",
			"read_label": "读节目单",
			"take_label": "让它们鼓掌",
			"read_word_message": "纸人翻页 · 解明「%s」，污染 +%d",
			"read_pages_message": "纸人翻页 · 残页 +%d，污染 +%d",
			"take_message": "收起节目单 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 面具",
			"title": "一张笑脸面具挂在椅背上，背面写着一行小字。",
			"body": "翻过来读，还是让它继续笑着？",
			"read_label": "翻过面具",
			"take_label": "让它笑着",
			"read_word_message": "面具背面 · 解明「%s」，污染 +%d",
			"read_pages_message": "面具背面 · 残页 +%d，污染 +%d",
			"take_message": "留下面具 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 名册",
			"title": "名册摊在舞台边，其中一页写满了同一个名字。",
			"body": "读那一页，还是把名册合上？",
			"read_label": "读那一页",
			"take_label": "合上名册",
			"read_word_message": "名册显名 · 解明「%s」，污染 +%d",
			"read_pages_message": "名册显名 · 残页 +%d，污染 +%d",
			"take_message": "合上名册 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 幕布",
			"title": "血红的幕布垂到台口，褶子里夹着一页台词。",
			"body": "掀开幕布读，还是让它继续垂着？",
			"read_label": "掀开幕布",
			"take_label": "让它垂着",
			"read_word_message": "幕布落字 · 解明「%s」，污染 +%d",
			"read_pages_message": "幕布落字 · 残页 +%d，污染 +%d",
			"take_message": "放下幕布 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 台词",
			"title": "空荡的舞台上有声音在念台词，念的是你的名字。",
			"body": "接下一句，还是捂住耳朵？",
			"read_label": "接下一句",
			"take_label": "捂住耳朵",
			"read_word_message": "台词入耳 · 解明「%s」，污染 +%d",
			"read_pages_message": "台词入耳 · 残页 +%d，污染 +%d",
			"take_message": "转身离开 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 聚光灯",
			"title": "聚光灯照在空座位上，光里浮着一页没人认领的字。",
			"body": "走进光里读，还是把灯关掉？",
			"read_label": "走进光里",
			"take_label": "关掉聚光灯",
			"read_word_message": "追光落字 · 解明「%s」，污染 +%d",
			"read_pages_message": "追光落字 · 残页 +%d，污染 +%d",
			"take_message": "关掉聚光灯 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 谢幕",
			"title": "纸人全体起立，等着最后一句台词落下。",
			"body": "替它们说完，还是提前谢幕？",
			"read_label": "说完这句",
			"take_label": "提前谢幕",
			"read_word_message": "谢幕词 · 解明「%s」，污染 +%d",
			"read_pages_message": "谢幕词 · 残页 +%d，污染 +%d",
			"take_message": "提前谢幕 · 残页 +%d",
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
