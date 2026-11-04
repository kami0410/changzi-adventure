class_name EndingHintData
extends RefCounted

## Rotating copy for the ending screen's return hint. Every line keeps the
## "按 <键>" prompt and the "回到最后的档案馆" destination, so the mechanic is
## unchanged; only the flavour around it rotates. Picking is stable per run +
## outcome and never touches the run RNG.

const VICTORY_LINES: Array[String] = [
	"按 %s 回到最后的档案馆，把这一页合上。",
	"按 %s 回到最后的档案馆，名册已经对齐。",
	"按 %s 回到最后的档案馆，灯还亮着。",
	"按 %s 回到最后的档案馆，雨声还没停。",
	"按 %s 回到最后的档案馆，残页已经归位。",
	"按 %s 回到最后的档案馆，名字收好了。",
	"按 %s 回到最后的档案馆，这一页写完了。",
	"按 %s 回到最后的档案馆，墨迹终于干了。",
]

const DEFEAT_LINES: Array[String] = [
	"按 %s 回到最后的档案馆，把断页翻过去。",
	"按 %s 回到最后的档案馆，墨迹还没干。",
	"按 %s 回到最后的档案馆，名字仍在册上。",
	"按 %s 回到最后的档案馆，下一次写轻点。",
	"按 %s 回到最后的档案馆，灯芯还剩一截。",
	"按 %s 回到最后的档案馆，碎片替你记得。",
	"按 %s 回到最后的档案馆，这一页先撕下。",
	"按 %s 回到最后的档案馆，别让污染读到。",
]


static func variants(won: bool) -> Array[String]:
	return VICTORY_LINES.duplicate() if won else DEFEAT_LINES.duplicate()


## Stable for one run + outcome, without touching run.rng.
static func pick(run_seed: int, won: bool) -> String:
	var lines := variants(won)
	if lines.is_empty():
		return ""
	var outcome := "won" if won else "lost"
	return lines[posmod(hash("%d:%s" % [run_seed, outcome]), lines.size())]


## Inserts the current key label into an authored template.
static func format_hint(template: String, key: String) -> String:
	if template.is_empty():
		return ""
	return template.replace("%s", key)
