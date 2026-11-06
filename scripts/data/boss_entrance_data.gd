class_name BossEntranceData
extends RefCounted

## Rotating flavour for the boss entrance of each authored chapter. Copy only:
## the boss bar and objective keep the mechanical text, and picking is stable
## per run + chapter without touching the run RNG (loot must not shift).
## Chapters without an authored table keep the silent entrance.

const CH1_LINES: Array[String] = [
	"墨骸史官抬起没有脸的头",
	"它把名册翻到写着你的一页",
	"纸页从它的袖口里涌出来",
	"它认得你，尽管你还不认得它",
	"墨雨停在半空，等它开口",
	"它说：这一页我替你写好了",
	"档案馆的门在身后自己合上",
	"它的笔尖滴着别人的记忆",
]


## Chapter 2 (呼吸废墟): the lung bell is the city's heartbeat and its cage
## (story bible). The lines stay copy-only and never name a new plot fact.
const CH2_LINES: Array[String] = [
	"肺钟守卫从雾里抬起钟摆",
	"整座废墟跟着它的肺叶呼吸",
	"钟声把雾震成一圈一圈",
	"它胸腔里的钟摆敲着死者的名字",
	"雾里传来阿砚钉钉子的回声",
	"肺叶张开，风从里面漏出来",
	"它把这座城最后的心跳举高",
	"钟摆停了一瞬，像在听你开口",
]


## Chapter 3 (无光海): the last reader is a child who has read every ending
## (story bible). The lines stay copy-only and never name a new plot fact.
const CH3_LINES: Array[String] = [
	"最后的读者从海面抬起头",
	"他膝上摊着一本读完了的书",
	"无光海在他身后翻到最后一页",
	"孩子抬起手，镜面一齐亮起",
	"他念出你走过的每一个结局",
	"海面没有倒影，只有他的眼睛",
	"他把空白的最后一页举高",
	"他说：故事需要有人翻页",
]


## Chapter 4 (笑面剧场): the paper audience, the name ledger and the curtain
## call of the CampaignData intro/outro. Copy only; no new plot facts.
const CH4_LINES: Array[String] = [
	"笑面史官从帷幕后走上舞台",
	"观众席上的纸人一齐鼓掌",
	"他念出你同行者的名字",
	"他记得你每一个没走完的版本",
	"聚光灯落下，只照着你",
	"他手里摊着一本写满你名字的册子",
	"笑脸面具下没有脸",
	"他说：这次换你写我",
]


static func variants(chapter_index: int) -> Array[String]:
	match chapter_index:
		0:
			return CH1_LINES.duplicate()
		1:
			return CH2_LINES.duplicate()
		2:
			return CH3_LINES.duplicate()
		3:
			return CH4_LINES.duplicate()
	return []


## Stable for one run + chapter; "" means the caller shows no entrance line.
static func pick(run_seed: int, chapter_index: int) -> String:
	var lines := variants(chapter_index)
	if lines.is_empty():
		return ""
	return lines[posmod(hash("%d:%d" % [run_seed, chapter_index]), lines.size())]
