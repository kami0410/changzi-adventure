class_name Ch1EventData
extends RefCounted

## Copy and tuning for the Chapter 1 event room. The mechanics are fixed:
## reading always costs corruption and decodes one owned fragment (or pays
## pages when nothing is left to decode); taking always pays pages. Only the
## fiction rotates, seeded by the run so a repeat run can read a different page.

const CORRUPTION_COST := 8
const PAGES_REWARD := 12
const FALLBACK_PAGES := 6


static func variants() -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{
			"eyebrow": "事件 · 禁文",
			"title": "一页禁文在墨雨中发光。",
			"body": "读它，还是把残页带走？",
			"read_label": "读禁文",
			"take_label": "拿残页",
			"read_word_message": "禁文入脑 · 解明「%s」，污染 +%d",
			"read_pages_message": "禁文入脑 · 残页 +%d，污染 +%d",
			"take_message": "带走残页 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 回声",
			"title": "墙缝里传来你还没说出口的话。",
			"body": "应它，还是把这句话记下来？",
			"read_label": "应声",
			"take_label": "记下回声",
			"read_word_message": "回声入脑 · 解明「%s」，污染 +%d",
			"read_pages_message": "回声入脑 · 残页 +%d，污染 +%d",
			"take_message": "记下回声 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 空页",
			"title": "一页空白被雨泡软，边角写着你的名字。",
			"body": "翻开它，还是收进书袋？",
			"read_label": "翻开空页",
			"take_label": "收起空页",
			"read_word_message": "空页显影 · 解明「%s」，污染 +%d",
			"read_pages_message": "空页显影 · 残页 +%d，污染 +%d",
			"take_message": "收起空页 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 墨汛",
			"title": "墨潮退去，滩上搁着一页没被泡烂的字。",
			"body": "捡起来读，还是收进书袋？",
			"read_label": "读这一页",
			"take_label": "收好残页",
			"read_word_message": "墨汛留字 · 解明「%s」，污染 +%d",
			"read_pages_message": "墨汛留字 · 残页 +%d，污染 +%d",
			"take_message": "收好残页 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 借阅",
			"title": "书架深处有人替你翻好了一页。",
			"body": "顺着他的手读下去，还是把书合上？",
			"read_label": "读下去",
			"take_label": "合上书",
			"read_word_message": "借阅成真 · 解明「%s」，污染 +%d",
			"read_pages_message": "借阅成真 · 残页 +%d，污染 +%d",
			"take_message": "合上书 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 落款",
			"title": "一页契约末尾，落着你的名字。",
			"body": "签下它，还是把笔折了？",
			"read_label": "签下名字",
			"take_label": "折笔离开",
			"read_word_message": "落款生效 · 解明「%s」，污染 +%d",
			"read_pages_message": "落款生效 · 残页 +%d，污染 +%d",
			"take_message": "折笔离开 · 残页 +%d",
		},
		{
			"eyebrow": "事件 · 补页",
			"title": "书脊里夹着一页刚补好的纸。",
			"body": "读它，还是把它塞回去？",
			"read_label": "读补页",
			"take_label": "塞回去",
			"read_word_message": "补页成形 · 解明「%s」，污染 +%d",
			"read_pages_message": "补页成形 · 残页 +%d，污染 +%d",
			"take_message": "塞回书脊 · 残页 +%d",
		},
	]
	return result


## Stable for one run + room, without consuming run RNG: the event copy must
## not shift the loot sequence when the room is entered after a resume.
static func pick(run_seed: int, room_id: String) -> Dictionary:
	var entries := variants()
	if entries.is_empty():
		return {}
	return entries[posmod(hash("%d:%s" % [run_seed, room_id]), entries.size())]
