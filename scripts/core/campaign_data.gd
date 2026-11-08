class_name CampaignData
extends RefCounted

## Four authored chapters, each a continuous level that ends on its own boss.
## Chapters 1–3 are reachable in this build (Chapter 1 linear rooms, Chapters
## 2–3 big-map regions); Chapter 4 is authored but not routed yet.

const LEVEL_PATHS: Array[String] = [
	"res://scenes/levels/biome_1.tscn",
	"res://scenes/levels/biome_breathing.tscn",
	"res://scenes/levels/lightless_sea.tscn",
]

const CHAPTERS: Array[Dictionary] = [
	{
		"id": &"ink_archive",
		"number": 1,
		"title": "第一章 · 墨雨档案馆",
		"subtitle": "被撕走的名册",
		"region": "墨雨档案馆",
		"objective": "找回失踪名册的第一页",
		"intro": [
			"陆沉：名册被撕走了三页。第一页还在档案馆深处。",
			"昌子：我连自己的名字都只剩一半。",
			"陆沉：那就从别人的名字开始找。",
			"陆沉：记住，档案不是真相。档案只是某个人希望后人相信的真相。",
			"昌子：那你希望我相信什么？",
			"陆沉：……先活着回来。剩下的，等你能读懂再说。",
		],
		"voice_intro": "ch1_intro",
		"voice_outro": "ch1_outro",
		"boss_voice": "ink",
		"music": "res://assets/audio/music/chapter_archive.ogg",
		"outro": [
			"墨骸史官倒下时，散落的纸页拼出半页名册。",
			"上面有一个被反复涂改的名字：昌子。",
			"第一页的背面写着一行小字：不要相信替你保存记忆的人。",
			"昌子把纸页翻过来。那行字和昌子自己的笔迹一模一样。",
		],
		"rooms": [
			[&"ink_hound", &"ink_hound", &"scribe_bug"],
			[&"blank_man", &"typo_beast", &"ink_hound"],
			[&"ink_hound", &"blank_man", &"scribe_bug"],
			[&"blank_man", &"ink_bomber", &"typo_beast"],
			[&"ink_hound", &"blank_man", &"page_swarm"],
			[&"scribe_bug", &"ink_hound", &"ink_bomber"],
		],
		"boss_name": "墨骸史官",
		"boss_hp": 280,
		"boss_scene": preload("res://scenes/bosses/ink_archivist_ch1.tscn"),
		"boss_damage": 12,
		"boss_speed": 65.0,
		"boss_texture": "res://assets/sprites/bosses/ink_archivist.png",
		"boss_scale": 1.0,
		"boss_tint": Color.WHITE,
		"boss_script": &"ink",
		"choice": {
			"title": "半页名册在你手里发烫。",
			"body": "带走它，陆沉也许能补全档案；烧掉它，墨雨会记住你的名字。",
			"options": [
				{"label": "带回档案馆", "note": "仁慈 +1，恢复 20 生命", "mercy": 1},
				{"label": "投入墨雨", "note": "污染 +10，获得一件遗物", "corruption": 10},
			],
		},
	},
	{
		"id": &"breathing_ruins",
		"number": 2,
		"title": "第二章 · 呼吸废墟",
		"subtitle": "肺钟与第二页",
		"region": "呼吸废墟",
		"objective": "让肺钟停下，取回第二页名册",
		"intro": [
			"呼吸废墟的肺钟每响一次，就有一段记忆被呼出体外。",
			"阿砚：跟紧我留下的灯。别在雾里回头。",
			"昌子：如果回头呢？",
			"阿砚：那你会看见自己忘记的人。",
			"阿砚：这座城原本会呼吸。肺钟是它的心跳，也是它的牢笼。",
			"昌子：你以前来过这里？",
			"阿砚：我给那口钟打过一颗钉子。现在它还记得我的锤声。",
		],
		"voice_intro": "ch2_intro",
		"voice_outro": "ch2_outro",
		"boss_voice": "lung",
		"music": "res://assets/audio/music/chapter_breathing.ogg",
		"outro": [
			"肺钟守卫：……还给我……那是我的名字……",
			"钟声停了，雾里浮出第二页名册。",
			"第二页上没有一个活人的名字。全是这座城死去的人。",
			"阿砚在名单末尾看见了自己。他没有说话，只是把灯芯拧得更亮了一点。",
		],
		"rooms": [
			[&"breath_hound", &"lung_moth", &"rust_whisperer"],
			[&"choir_summoner", &"breath_hound", &"blank_man", &"lung_moth"],
			[&"breath_hound", &"rust_whisperer", &"collapse_husk"],
			[&"page_swarm", &"blank_man", &"breath_hound"],
			[&"collapse_husk", &"lung_moth", &"blank_man"],
			[&"breath_hound", &"rust_whisperer", &"collapse_husk"],
		],
		"boss_name": "肺钟守卫",
		"boss_hp": 360,
		"boss_damage": 14,
		"boss_speed": 75.0,
		"boss_texture": "res://assets/sprites/bosses/lung_bell_guardian.png",
		"boss_scale": 1.0,
		"boss_tint": Color.WHITE,
		"boss_script": &"ink",
		"choice": {
			"title": "肺钟里还剩最后一口气。",
			"body": "替它续上，雾会散开一条路；敲碎它，钟里的词会全部归你。",
			"options": [
				{"label": "替它续气", "note": "仁慈 +1，获得护盾", "mercy": 1},
				{"label": "敲碎肺钟", "note": "污染 +8，武器强化", "corruption": 8},
			],
		},
	},
	{
		"id": &"lightless_sea",
		"number": 3,
		"title": "第三章 · 无光海",
		"subtitle": "最后的读者",
		"region": "无光海",
		"objective": "穿过无光海，找到最后的读者",
		"intro": [
			"无光海上没有倒影。你看见的每一张脸，都是别人丢失的。",
			"最后的读者：昌子，你终于走到这里。名册的最后一页，写的是你。",
			"昌子：那我还需要找回什么？",
			"最后的读者：选择由谁来写下一页。",
			"最后的读者：我读过所有结局。你会赢，也会输，还会在同一个地方反复醒过来。",
			"昌子：那你为什么不阻止我？",
			"最后的读者：因为故事需要有人翻页。哪怕翻页的人会疼。",
		],
		"voice_intro": "ch3_intro",
		"voice_outro": "ch3_outro",
		"boss_voice": "reader",
		"music": "res://assets/audio/music/chapter_sea.ogg",
		"outro": [
			"最后的读者合上书，把最后一页交给你。",
			"海面裂开，露出一座仍在鼓掌的剧场。",
			"最后一页是空白的。只在最下方印着一行极小的字：演出继续。",
			"读者：笑面史官在等你。他记得你所有的名字，包括那些你还没用过的。",
		],
		"rooms": [
			[&"echo_enemy", &"hanging_scribe", &"rust_whisperer"],
			[&"mirror_sniper", &"typo_beast", &"collapse_husk", &"scribe_bug"],
			[&"echo_enemy", &"lung_moth", &"rust_whisperer"],
			[&"mirror_sniper", &"hanging_scribe", &"typo_beast"],
			[&"echo_enemy", &"collapse_husk", &"lung_moth"],
			[&"hanging_scribe", &"rust_whisperer", &"echo_enemy"],
		],
		"boss_name": "最后的读者",
		"boss_hp": 380,
		"boss_damage": 15,
		"boss_speed": 78.0,
		"boss_texture": "res://assets/sprites/bosses/last_reader.png",
		"boss_scale": 1.0,
		"boss_tint": Color.WHITE,
		"boss_script": &"reader",
		"choice": {
			"title": "最后一页在你手里。",
			"body": "带走读者，还是让这一页永远留在无光海？",
			"options": [
				{"label": "带读者离开", "note": "仁慈 +1，恢复 20 生命", "mercy": 1},
				{"label": "留下最后一页", "note": "污染 +8，获得一件遗物", "corruption": 8},
			],
		},
	},
	{
		"id": &"smiling_theater",
		"number": 4,
		"title": "第四章 · 笑面剧场",
		"subtitle": "最后一页的观众",
		"region": "笑面剧场",
		"objective": "穿过空座，走上舞台，结束这场演出",
		"intro": [
			"剧场里坐满了纸人，它们只为最后一页鼓掌。",
			"笑面史官：你终于来了。我等你写这一页，等了很久。",
			"昌子：你是谁？",
			"笑面史官：一个记得你所有名字的人。",
			"笑面史官：陆沉教你怎么读，阿砚教你怎么活，闻烬教你怎么改，白榆教你怎么走。",
			"笑面史官：可没人教你，写完之后该怎么忘。",
			"昌子：那你教我。",
			"笑面史官：不。这次换你写我。",
		],
		"voice_intro": "ch4_intro",
		"voice_outro": "ch4_outro",
		"boss_voice": "smiling",
		"music": "res://assets/audio/music/chapter_theater.ogg",
		"outro": [
			"笑面史官：你记得自己是谁吗？",
			"昌子：我记得我选择记住谁。",
			"笑面史官的笑脸终于裂开。里面没有脸，只有一页写满昌子名字的纸。",
			"纸人说完了最后一句台词：谢幕。",
		],
		"rooms": [
			[&"mask_enemy", &"seat_husk", &"echo_enemy"],
			[&"choir_summoner", &"mask_enemy", &"seat_husk", &"typo_beast"],
			[&"mirror_sniper", &"seat_husk", &"mask_enemy"],
			[&"seat_husk", &"ink_bomber", &"typo_beast"],
			[&"mask_enemy", &"seat_husk", &"echo_enemy"],
			[&"mask_enemy", &"mask_enemy", &"seat_husk"],
		],
		"boss_name": "笑面史官",
		"boss_hp": 520,
		"boss_damage": 18,
		"boss_speed": 92.0,
		"boss_texture": "res://assets/sprites/bosses/smiling_archivist.png",
		"boss_scale": 1.0,
		"boss_tint": Color.WHITE,
		"boss_script": &"smiling",
		"choice": {
			"title": "名册翻到最后一页。",
			"body": "写下新的档案，或让所有记录在这里结束。",
			"options": [
				{"label": "重写名册", "note": "以你保存的记录决定结局", "mercy": 1},
				{"label": "焚毁名册", "note": "世界失去历史，但获得自由", "corruption": 12},
			],
		},
	},
]


## Authored endings in gallery order (GDD §12.2). Profile stores only the id,
## so this list is the single source for both the result page and the gallery.
const ENDINGS: Array[Dictionary] = [
	{"id": &"restored", "title": "复原",
		"body": "三页名册重新对齐。失踪者的名字回到纸上，\n昌子的名字也终于有了下一行。最后的档案馆亮起了灯。"},
	{"id": &"burned", "title": "焚毁档案",
		"body": "名册在舞台上烧了三天三夜。世界失去了历史，\n但从此没有人能用过去命令任何人。昌子第一次听见海的声音。"},
	{"id": &"abyss", "title": "深渊回响",
		"body": "你写下最后一页时，墨自己动了起来。\n昌子成为污染的一部分，也成为唯一还记得世界的人。档案继续生长。"},
	{"id": &"unfinished", "title": "未完的注脚",
		"body": "名册补全了，却仍有一页空白。昌子合上档案，\n知道下一次潮水会带来新的名字——而昌子会记得回来。"},
	{"id": &"interrupted", "title": "记录中断",
		"body": "污染吞没了这一页。昌子的名字从档案中淡去，\n但记忆碎片已经被写下——下一次，你会记得更多。"},
]


static func chapter_count() -> int:
	return CHAPTERS.size()


static func chapter(index: int) -> Dictionary:
	return CHAPTERS[clampi(index, 0, CHAPTERS.size() - 1)]


static func ending_count() -> int:
	return ENDINGS.size()


static func ending(index: int) -> Dictionary:
	return ENDINGS[clampi(index, 0, ENDINGS.size() - 1)]


static func ending_by_id(ending_id: StringName) -> Dictionary:
	for entry in ENDINGS:
		if StringName(entry.get("id", &"")) == ending_id:
			return entry
	return {}


static func ending_for(won: bool, corruption: int, mercy: int, burned: bool) -> Dictionary:
	var ending_id: StringName = &"unfinished"
	if not won:
		ending_id = &"interrupted"
	elif burned:
		ending_id = &"burned"
	elif corruption >= 60:
		ending_id = &"abyss"
	elif mercy >= 2:
		ending_id = &"restored"
	return ending_by_id(ending_id)
