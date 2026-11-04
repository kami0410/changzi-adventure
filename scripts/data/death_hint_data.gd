class_name DeathHintData
extends RefCounted

## Rotating copy for the two revive paths. Every authority line keeps the exact
## "恢复 50 生命" mechanic; every relic line keeps the relic name and the
## "翻回上一页" action. Picking is stable per run + kind and never touches the
## run RNG, so the loot sequence and resume stay unchanged.

const AUTHORITY_LINES: Array[String] = [
	"续命生效 · 命数被驳回，恢复 50 生命",
	"续命生效 · 档案挡下这一笔，恢复 50 生命",
	"续命生效 · 墨迹倒流，恢复 50 生命",
	"续命生效 · 这一页还没写完，恢复 50 生命",
	"续命生效 · 名字被重新描深，恢复 50 生命",
	"续命生效 · 死亡被划去一行，恢复 50 生命",
	"续命生效 · 权柄拒绝归档，恢复 50 生命",
	"续命生效 · 从注脚里站起来，恢复 50 生命",
]

const RELIC_LINES: Array[String] = [
	"不灭档案替你翻回上一页",
	"不灭档案烧掉死字，替你翻回上一页",
	"不灭档案按住你的名字，替你翻回上一页",
	"不灭档案拒绝合上，替你翻回上一页",
	"不灭档案抖落墨灰，替你翻回上一页",
	"不灭档案留出一页空白，替你翻回上一页",
	"不灭档案把墨迹倒拨，替你翻回上一页",
	"不灭档案护住这一行，替你翻回上一页",
]


static func variants(kind: StringName) -> Array[String]:
	match kind:
		&"authority":
			return AUTHORITY_LINES.duplicate()
		&"relic":
			return RELIC_LINES.duplicate()
	return []


## Stable for one run + revive kind, without touching run.rng.
static func pick(run_seed: int, kind: StringName) -> String:
	var lines := variants(kind)
	if lines.is_empty():
		return ""
	return lines[posmod(hash("%d:%s" % [run_seed, String(kind)]), lines.size())]
