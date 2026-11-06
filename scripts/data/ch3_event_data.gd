class_name Ch3EventData
extends RefCounted

## Copy and tuning for the Chapter 3 event region (无光海). The mechanics are
## the same fixed pair the Chapter 1/2 pages use: reading always costs
## corruption and decodes one owned fragment (or pays pages when nothing is
## left to decode); taking always pays pages. Only the fiction rotates, seeded
## by the run and the plan's event node id, so a repeat run can read a
## different page.
##
## The lightless sea has no reflections, every face belongs to someone who lost
## it, and the last reader is a child who has read every ending
## (docs/story-bible.md). These are flavour lines only; do not turn them into
## new plot facts.

const CORRUPTION_COST := 8
const PAGES_REWARD := 12
const FALLBACK_PAGES := 6


static func variants() -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{
			"eyebrow": "事件 · 倒影",
			"title": "海面没有你的倒影，只有一张别人的脸。",
			"body": "听它说完，还是把脸收进书袋？",
			"read_label": "听它说完",
			"take_label": "收进书袋",
			"read_word_message": "倒影开口 · 解明「%s」，污染 +%d",
			"read_pages_message": "倒影开口 · 残页 +%d，污染 +%d",
			"take_message": "收起脸 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 盐页",
			"title": "最后一页是空白的，边缘沾着盐。",
			"body": "翻开它，还是让它空着？",
			"read_label": "翻开空页",
			"take_label": "让它空着",
			"read_word_message": "空页映字 · 解明「%s」，污染 +%d",
			"read_pages_message": "空页映字 · 残页 +%d，污染 +%d",
			"take_message": "留下空页 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 小读者",
			"title": "一个孩子坐在礁石上，膝头摊着一本读完的书。",
			"body": "听他念完，还是把书合上？",
			"read_label": "听他念完",
			"take_label": "合上书",
			"read_word_message": "孩子翻页 · 解明「%s」，污染 +%d",
			"read_pages_message": "孩子翻页 · 残页 +%d，污染 +%d",
			"take_message": "合上书 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 镜面",
			"title": "镜面狙手的碎片浮在海上，映出一页字。",
			"body": "照它读，还是把镜面打碎？",
			"read_label": "照镜读字",
			"take_label": "打碎镜面",
			"read_word_message": "镜面折字 · 解明「%s」，污染 +%d",
			"read_pages_message": "镜面折字 · 残页 +%d，污染 +%d",
			"take_message": "打碎镜面 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 海页",
			"title": "一叠残页被浪推上岸，字迹还没被泡开。",
			"body": "读它，还是趁湿收起来？",
			"read_label": "读这一页",
			"take_label": "趁湿收起",
			"read_word_message": "海页显字 · 解明「%s」，污染 +%d",
			"read_pages_message": "海页显字 · 残页 +%d，污染 +%d",
			"take_message": "趁湿收起 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 吊影",
			"title": "悬吊书吏的影子垂到海面，影子里夹着一页。",
			"body": "顺着影子读，还是剪断它？",
			"read_label": "顺着影子读",
			"take_label": "剪断影子",
			"read_word_message": "影子垂字 · 解明「%s」，污染 +%d",
			"read_pages_message": "影子垂字 · 残页 +%d，污染 +%d",
			"take_message": "剪断影子 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 翻页",
			"title": "海风翻开一页，停在写着你名字的那一行。",
			"body": "读下去，还是按住这一页？",
			"read_label": "读下去",
			"take_label": "按住这一页",
			"read_word_message": "名字翻页 · 解明「%s」，污染 +%d",
			"read_pages_message": "名字翻页 · 残页 +%d，污染 +%d",
			"take_message": "按住这一页 · 残页 +%d",
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
