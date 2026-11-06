class_name BossPhaseData
extends RefCounted

## Rotating flavor for boss phases 2 and 3 of each authored chapter. The
## mechanical "<boss> · 第 N 阶段" prefix stays in game.gd, every line is copy
## only, and picking is stable per run + phase without touching the run RNG
## (loot must not shift). Phase 1 has no phase-change banner, other phases keep
## the base text and return an empty flavor line.
##
## Chapter 1 keeps its original selection key so the demo lines do not shift;
## other chapters mix the chapter index into the key.

const PHASE2_LINES: Array[String] = [
	"纸页在它身后立成风暴",
	"散落的残页开始自己翻动",
	"它把名字撕成两半又拼回去",
	"墨雨逆着落向天花板",
	"每一页都在重复同一句低语",
	"书架从墙里长出来围住退路",
	"它的手指翻过一页不存在的书",
	"被烧掉的段落重新浮上纸面",
]

const PHASE3_LINES: Array[String] = [
	"封印裂开，镜面里多出一个昌子",
	"它开始替你写下最后一页",
	"镜中的你先一步抬起手",
	"墨从裂缝里倒灌进房间",
	"它叫出了你还没想起的名字",
	"所有残页同时合上",
	"镜面映出的伤口不在你身上",
	"最后一页正被谁用力按住",
]

## Chapter 2 (呼吸废墟): the lung bell's pendulum and lung lobes, the fog it
## breathes and the dead names it keeps. Copy only; no new plot facts.
const CH2_PHASE2_LINES: Array[String] = [
	"钟摆开始倒转，雾往肺里灌",
	"它把死者的名字一口气呼出",
	"肺叶上的裂缝一齐张开",
	"钟声变成两个人的心跳",
	"雾里浮出无数没写完的名字",
	"它开始替这座城继续呼吸",
	"那截锈钉在钟腔里发亮",
	"每一口风都在喊同一个名字",
]

const CH2_PHASE3_LINES: Array[String] = [
	"肺钟裂开，里面没有钟摆",
	"整座废墟的呼吸同时停住",
	"它用最后一口气念出你的名字",
	"雾从裂缝里倒灌回钟腔",
	"阿砚的钉子被一口一口吐出",
	"名册的第二页在雾里发白",
	"它胸腔里的城市开始下沉",
	"钟声哑了，雾却更浓",
]


## Chapter 3 (无光海): the last reader turns the mirror barrage and the blank
## last page on the player. Copy only; no new plot facts.
const CH3_PHASE2_LINES: Array[String] = [
	"镜面弹幕从海面立起来",
	"孩子翻开书，你的短语哑了",
	"每一块碎片都在读你",
	"无光海把倒影全部收走",
	"他念到你还没走过的结局",
	"书页从海上翻到半空",
	"镜面里映出另一个你",
	"孩子的书签停在最后一页",
]

const CH3_PHASE3_LINES: Array[String] = [
	"最后一页翻开，海面开始发光",
	"他读完了所有结局，抬起头",
	"镜子碎成一场没有声音的雨",
	"你的名字在书页上被划掉",
	"孩子合上书，海却还在翻页",
	"镜面里所有失败的你同时开口",
	"他把空白的最后一页递过来",
	"故事翻到最后一页，停住了",
]


## Chapter 4 (笑面剧场): the stage turns on the player and the curtain call
## approaches. Copy only; no new plot facts.
const CH4_PHASE2_LINES: Array[String] = [
	"幕布升起，舞台机关开始转动",
	"纸人观众站起来，把座位让给影子",
	"他翻到名册里你失败的那一页",
	"聚光灯开始替你念台词",
	"舞台上的布景一页页翻过去",
	"他把你写过的句子改了一个字",
	"观众席传来整齐的翻页声",
	"他说：这一幕我见过很多次",
]

const CH4_PHASE3_LINES: Array[String] = [
	"笑脸裂开，里面是一页写满名字的纸",
	"他把最后一页举到聚光灯下",
	"纸人全体起立，等你谢幕",
	"舞台开始拆掉自己的布景",
	"他念出你还没用过的名字",
	"名册在他手里自己翻页",
	"你写的句子开始反过来写你",
	"他说：谢幕也是台词的一部分",
]


static func variants(phase: int, chapter_index: int = 0) -> Array[String]:
	match chapter_index:
		0:
			match phase:
				2:
					return PHASE2_LINES.duplicate()
				3:
					return PHASE3_LINES.duplicate()
		1:
			match phase:
				2:
					return CH2_PHASE2_LINES.duplicate()
				3:
					return CH2_PHASE3_LINES.duplicate()
		2:
			match phase:
				2:
					return CH3_PHASE2_LINES.duplicate()
				3:
					return CH3_PHASE3_LINES.duplicate()
		3:
			match phase:
				2:
					return CH4_PHASE2_LINES.duplicate()
				3:
					return CH4_PHASE3_LINES.duplicate()
	return []


## Stable for one run + phase (+ chapter); "" means the caller keeps the plain
## prefix. Chapter 1 keeps its legacy key so existing runs read the same line.
static func pick(run_seed: int, phase: int, chapter_index: int = 0) -> String:
	var lines := variants(phase, chapter_index)
	if lines.is_empty():
		return ""
	var key := "%d:%d" % [run_seed, phase]
	if chapter_index != 0:
		key = "%d:%d:%d" % [run_seed, chapter_index, phase]
	return lines[posmod(hash(key), lines.size())]
