class_name BossEntranceData
extends RefCounted

## Rotating flavour for the Chapter 1 boss entrance. Copy only: the boss bar
## and objective keep the mechanical text, and picking is stable per run +
## chapter without touching the run RNG (loot must not shift). Chapters 2–4
## keep the silent entrance until their demo content is authored.

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


static func variants(chapter_index: int) -> Array[String]:
	if chapter_index == 0:
		return CH1_LINES.duplicate()
	return []


## Stable for one run + chapter; "" means the caller shows no entrance line.
static func pick(run_seed: int, chapter_index: int) -> String:
	var lines := variants(chapter_index)
	if lines.is_empty():
		return ""
	return lines[posmod(hash("%d:%d" % [run_seed, chapter_index]), lines.size())]
