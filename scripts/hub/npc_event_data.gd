class_name NPCEventData
extends RefCounted

## One Hub personal event per visible NPC (叙事审计 E2, 第一批). The story
## beats come from docs/story-bible.md 「四位同行者 / 五位 NPC」: 陆沉 admits he
## tore the three pages to protect himself (red folder), 阿砚 refuses the god
## name and lights the furnace once more (broken-page sword as his gravestone),
## 咕噜 refuses to sell the glass bottle holding 「永」.
##
## The event is a conversation only. It grants no items, pages, fragments or
## trust; the sole persistent effect is the Profile flag recorded when the last
## line is read. Thresholds pair one trust tier with the demo chapter progress
## (`Profile.demo_cleared`), so every event is reachable inside Chapter 1.

const EVENTS: Dictionary = {
	&"luchen": {
		"id": "luchen_red_folder",
		"title": "红色文件夹",
		"prop": "红色文件夹",
		"min_tier": 2,
		"requires_demo_cleared": true,
		"lines": [
			"坐。今天不讲词，也不讲世界史。",
			"（他从抽屉最里面取出一个红色文件夹，放在桌上。封面没有字，只有一个被反复摩挲过的凹痕。）",
			"你一直以为，我撕下那三页，是为了不让死者被忘记。",
			"不是。至少，不全是。",
			"名册上有一栏，叫「已死之人」。那晚我在那一栏里看见了自己的名字——不是预言，是已经写好的字。",
			"撕掉三页，那一栏就少了一页。我告诉自己这是为了档案馆。可我当时只想着：我还不想被归档。",
			"（他摘下眼镜，用袖口擦了很久。镜片上什么也没有。）",
			"这个文件夹里，是你最初的入职档案。上面的名字，比你记得的那个完整。",
			"我一直在替你决定该读什么、该忘什么。现在我不想替你决定了。",
			"……你可以骂我。档案长也该被归档一次。",
			"（红色文件夹仍留在桌上。他伸手，把它合上了。）",
		],
	},
	&"ayan": {
		"id": "ayan_furnace",
		"title": "再烧一次炉",
		"prop": "断页剑",
		"min_tier": 3,
		"requires_demo_cleared": true,
		"lines": [
			"……又是你。剑放砧上，人别挡光。",
			"（铁砧边靠着那把断页剑。剑脊上有一道缺页似的裂口，从护手一直裂到剑尖。）",
			"别碰。那把剑修不好。不是材料的问题——它本来就不该被修好。",
			"你问我为什么留着它？铺子里不留废铁。",
			"……那是块碑。给我自己的。",
			"（他把锤子放回砧上，动作轻得不像他。）",
			"旧世界最后一座军械库，是我烧的最后一炉。诸神走光以后，没人再需要门闩，也没人再需要一尊神。",
			"所以我把名字留在炉底，改叫阿砚。守夜人不需要名字：天亮了换班，没人会记得。这样挺好。",
			"你说不是？……别说了。神不会把剑修成这样。神也不会守着一间没有火的铺子。",
			"（他沉默了很久，伸手在冷炉膛里按了一下。炉底亮起一线暗红，像有人从很远的地方应了一声。）",
			"只烧这一次。不是给神，也不是给这个世界。是给你。",
			"（火光映着他的侧脸。他没有再提「神」这个字。）",
			"把剑拿好。下次来，别问真名。",
		],
	},
	&"guru": {
		"id": "guru_bottle",
		"title": "不卖的瓶子",
		"prop": "玻璃瓶",
		"min_tier": 1,
		"requires_demo_cleared": true,
		"lines": [
			"哟，史官大人。今天不看货架，专程来看我？",
			"（货架最里面压着一只玻璃瓶。瓶里没有药水，只有一个「永」字，像一小片没烧完的夜。）",
			"那个不卖。看可以，别伸手。",
			"……你别用那种眼神。不是价没谈拢。是不卖。",
			"我什么都卖。词、传闻、别人的记性，连「永」和「恒」我都拆开卖过。",
			"可这只瓶子不行。里面是我第一次醒来时吞下的那个字。",
			"那时候我趴在一堆烧焦的词上，四周什么都没有。就这个「永」还亮着。",
			"我把它装起来，想着哪天没人来买东西了，就拿出来看看——至少还有一个字，是永远不会被我卖掉的。",
			"（他把瓶子往货架里面推了推，比平时轻。）",
			"所以啊，史官大人，别死太早。你死了，谁还来听我讲价？",
			"……瓶子的账，等我哪天不在了再算。今天不谈这个。",
		],
	},
}


static func event_for(npc_id: StringName) -> Dictionary:
	var event: Dictionary = EVENTS.get(npc_id, {})
	return event.duplicate(true)


static func event_id(npc_id: StringName) -> String:
	return String(EVENTS.get(npc_id, {}).get("id", ""))


## An event fires once, after the NPC's trust tier and the chapter progress
## gate are both met. Hidden NPCs (闻烬/白榆) have no entry and never fire.
static func can_trigger(profile: Profile, npc_id: StringName) -> bool:
	if profile == null:
		return false
	var event: Dictionary = EVENTS.get(npc_id, {})
	if event.is_empty():
		return false
	var id := String(event.get("id", ""))
	if id.is_empty() or profile.has_npc_event(id):
		return false
	if bool(event.get("requires_demo_cleared", true)) and not profile.demo_cleared:
		return false
	return TrustData.tier_for(profile, npc_id) >= int(event.get("min_tier", 0))
