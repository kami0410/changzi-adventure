class_name EndingEchoData
extends RefCounted

## 叙事审计 E3：五个结局的 NPC 余味与「笑面史官 / 最后一页」回收。
##
## 只写 docs/story-bible.md 已定义的弧线与结局含义，不新增剧情事实：
## - 复原：三页对齐、失踪者回到纸上；陆沉交文件夹、阿砚走出铁匠铺、咕噜瓶子空了、
##   闻烬重写名字、白榆地图出现新路（圣经「结局 · 复原」）。
## - 焚毁：名册烧了三天三夜，世界失去历史与用过去命令人的权力（「结局 · 焚毁档案」）。
## - 深渊：墨自己动起来，昌子成为污染的一部分、唯一还记得世界的人（「结局 · 深渊回响」）。
## - 未完：名册补全但留一页空白，下一次潮水带来新名字（「结局 · 未完的注脚」）。
## - 中断：污染吞没这一页，名字淡去，记忆碎片已经写下（「结局 · 记录中断」）。
##
## 笑面史官身份见圣经「反派：笑面史官」：未来的昌子、所有失败版本的集合，
## 脸后面是一页写满「昌子」名字的纸。最后一页见第三章节拍（最后的读者交出空白
## 的最后一页）与深渊结局（昌子写下最后一页）。两处都由每个结局的 CODAS 回收。
##
## 文本只在这里维护；CampaignData 的 id / 标题 / 正文与 ending_for 判定不变。
## 「这个不卖，借你」只在复原（信任足够）出现；阿砚的真名分支未实现，余味只写到
## 「愿意再为一个人烧一次炉」为止，不写成已经叫出真名、走出铁匠铺。

const NPC_ORDER: Array[StringName] = [&"luchen", &"ayan", &"guru", &"wenjin", &"baiyu"]

const NPC_NAMES: Dictionary = {
	&"luchen": "陆沉",
	&"ayan": "阿砚",
	&"guru": "咕噜",
	&"wenjin": "闻烬",
	&"baiyu": "白榆",
}

const ENDING_ORDER: Array[StringName] = [
	&"restored", &"burned", &"abyss", &"unfinished", &"interrupted",
]

const ECHOES: Dictionary = {
	&"restored": {
		&"luchen": "陆沉把红色文件夹推到昌子面前，这次没有合上。他说入职档案上的名字比你记得的完整，剩下的该由你自己读。",
		&"ayan": "阿砚的炉子没有再熄。断页剑还靠在砧边，他不再说那是碑，只说等昌子下次来，再打一截新的剑脊。",
		&"guru": "咕噜把玻璃瓶塞进昌子手里：这个不卖，借你。瓶子空了，它说「永」字已经用在该用的地方，账不用算。",
		&"wenjin": "闻烬用那支断尖笔，在名册边角写了一次自己的名字。写完她把笔收起来，说这笔尖早该磨了。",
		&"baiyu": "白榆把那张没有终点的手绘地图铺开。地图边缘多出一条从未有过的路，他看了很久，说这回我陪你走一段。",
	},
	&"burned": {
		&"luchen": "陆沉没有交出红色文件夹。火烧过档案馆时，他把它放在观众席第一排，像还给一个不会再来的自己。",
		&"ayan": "火烧到铁匠铺时，阿砚先搬走了砧子，没管那把断页剑。他说碑烧了也好，省得有人对着一块铁念名字。",
		&"guru": "咕噜蹲在烧剩的词堆里翻找，货架空了。它说「永」字大概也烧没了，可只要还有人还价，它就还能再进一批货。",
		&"wenjin": "闻烬没有拦那把火。她说改过的名字本来就不算数，烧了干净。断尖笔在她指间转了一圈，最后收进袖子里。",
		&"baiyu": "白榆的地图被火烧掉一半。他看着剩下的一半说，没有终点也好，走到哪里都算新路。",
	},
	&"abyss": {
		&"luchen": "陆沉还想替昌子决定该读什么，可他已经读不懂昌子写下的句子。红色文件夹摊在桌上，入职档案被墨浸成一页空白。",
		&"ayan": "阿砚的炉子还亮着，可他已经认不出推门进来的是谁。锤子举到一半又放下，像在等一句不会再有人说的真名。",
		&"guru": "咕噜还在货架后面讲价，只是没有客人。它把玻璃瓶推给一团墨，说这个不卖——墨没有回答，它也没有收回去。",
		&"wenjin": "闻烬在墨里改最后一个名字，改到一半停住了。她第一次承认，有些字被污染读过之后，连她也改不回去。",
		&"baiyu": "白榆还在画路，可画出的每一条都通向同一片墨。他把笔放下，说这条路他带不了，昌子得自己走。",
	},
	&"unfinished": {
		&"luchen": "陆沉把红色文件夹收回抽屉。他说等那一页空白补上再交给你，可他自己也知道，那一天大概不会来。",
		&"ayan": "阿砚把断页剑翻了个面，裂口朝里。他说等昌子把那一页空白补上，再决定这把剑是碑还是剑。",
		&"guru": "咕噜把玻璃瓶往货架里面推了推，说瓶子的账等那一页空白补上再算。今天不谈这个。",
		&"wenjin": "闻烬把断尖笔搁在名册上。她说等昌子想清楚要留下谁，再来找她改那一页——价钱照旧。",
		&"baiyu": "白榆把地图卷起来，故意留了一角空白。他说那一角等昌子自己走完，再画上去。",
	},
	&"interrupted": {
		&"luchen": "陆沉翻开红色文件夹，昌子的入职档案停在半页。他没有往下读，只把文件夹合上，放回抽屉最里面。",
		&"ayan": "阿砚把炉门关上，只留一线暗红。他说铺子今晚不开，等那个赊账的史官回来再说。",
		&"guru": "咕噜把玻璃瓶从货架上拿下来，又放回去。它说史官大人只是暂时赊账，账还挂在墙上，利息照算。",
		&"wenjin": "闻烬翻到昌子那一页，笔尖悬了很久，最终没有落下去。她说这一页她改不了，也不想改。",
		&"baiyu": "白榆把地图折好，放在昌子最后一次出发的地方。他说路不会消失，只是会等人。",
	},
}

## 每个结局一段「回收」，同时落到笑面史官的身份与最后一页；在结束屏与
## 已解锁的画廊条目里展示，未解锁结局不显示。
const CODAS: Dictionary = {
	&"restored": "笑面史官的脸后面是一页写满「昌子」的纸，每一个名字都是一次失败的重来。复原之后，昌子把那页纸合进名册，最后一页没有撕掉——上面只留下自己选择记住的人。",
	&"burned": "最后一页和名册一起烧了。笑面史官那张写满「昌子」的脸在火里卷起来，每一个失败的名字都烧成同一个字。灰烬里没有人再需要结局。",
	&"abyss": "最后一页是昌子自己写的。墨动起来时，笑面史官的脸后面那页纸终于写满——上面每一个「昌子」都睁开了眼，却没有一个还叫昌子。",
	&"unfinished": "最后一页还空着。笑面史官没有来催，只把那张写满「昌子」的纸压在名册底下，等下一次潮水带来新的名字。",
	&"interrupted": "最后一页没有写完。笑面史官的脸后面那页纸还留着空行，等下一次昌子醒来，再添一个名字。",
}


static func ending_ids() -> Array[StringName]:
	return ENDING_ORDER.duplicate()


static func npc_ids() -> Array[StringName]:
	return NPC_ORDER.duplicate()


static func npc_name(npc_id: StringName) -> String:
	return String(NPC_NAMES.get(npc_id, ""))


static func has_ending(ending_id: StringName) -> bool:
	return ECHOES.has(ending_id)


static func echoes_for(ending_id: StringName) -> Dictionary:
	return ECHOES.get(ending_id, {}).duplicate(true)


static func echo_for(ending_id: StringName, npc_id: StringName) -> String:
	var echoes: Dictionary = ECHOES.get(ending_id, {})
	return String(echoes.get(npc_id, ""))


static func coda_for(ending_id: StringName) -> String:
	return String(CODAS.get(ending_id, ""))


## 「陆沉：……\n阿砚：……\n\n<回收段>」；未收录的结局返回空串。
static func display_text(ending_id: StringName) -> String:
	if not ECHOES.has(ending_id):
		return ""
	var lines: Array[String] = []
	for npc_id in NPC_ORDER:
		var line := echo_for(ending_id, npc_id)
		if line.is_empty():
			continue
		lines.append("%s：%s" % [npc_name(npc_id), line])
	var coda := coda_for(ending_id)
	if not coda.is_empty():
		if not lines.is_empty():
			lines.append("")
		lines.append(coda)
	return "\n".join(lines)
