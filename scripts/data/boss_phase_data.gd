class_name BossPhaseData
extends RefCounted

## Rotating flavor for the Chapter 1 boss phases 2 and 3. The mechanical
## "<boss> · 第 N 阶段" prefix stays in game.gd, every line is copy only, and
## picking is stable per run + phase without touching the run RNG (loot must
## not shift). Phase 1 has no phase-change banner, other phases keep the base
## text and return an empty flavor line.

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


static func variants(phase: int) -> Array[String]:
	match phase:
		2:
			return PHASE2_LINES.duplicate()
		3:
			return PHASE3_LINES.duplicate()
	return []


## Stable for one run + phase; "" means the caller keeps the plain prefix.
static func pick(run_seed: int, phase: int) -> String:
	var lines := variants(phase)
	if lines.is_empty():
		return ""
	return lines[posmod(hash("%d:%d" % [run_seed, phase]), lines.size())]
