class_name EmptyStateData
extends RefCounted

## Empty-state lines for the Codex and Inventory pages. Copy only: the pages
## still show the same state, the same grids and the same counts. Picking is
## stable per run seed + surface id, so a page never flickers mid-run and the
## selection never reads or advances RunState.rng. Every line keeps the
## mechanical meaning ("尚未收集任何词" / "尚未获得遗物" / "尚未发现组合" and
## the forge hint) so the state stays unambiguous.

const CODEX_WORDS: Array[String] = [
	"尚未收集任何词。",
	"尚未收集任何词，名册这一页空着。",
	"尚未收集任何词，等第一枚落进档案。",
	"尚未收集任何词，墨迹还没干。",
	"尚未收集任何词，风把纸页吹空了。",
	"尚未收集任何词，词还在外面流浪。",
	"尚未收集任何词，档案馆替你留着位置。",
	"尚未收集任何词，先从残页里找一个。",
]

const INVENTORY_WORDS: Array[String] = [
	"尚未收集任何词。",
	"尚未收集任何词，背包里只有纸屑。",
	"尚未收集任何词，第一枚总会来的。",
	"尚未收集任何词，灯下还没有字。",
	"尚未收集任何词，口袋是空的。",
	"尚未收集任何词，等一枚词自己开口。",
	"尚未收集任何词，名册还没写上。",
	"尚未收集任何词，去外面找一枚。",
]

const INVENTORY_RELICS: Array[String] = [
	"尚未获得遗物。",
	"尚未获得遗物，架子上只有灰。",
	"尚未获得遗物，第一件还在路上。",
	"尚未获得遗物，口袋里没有旧物。",
	"尚未获得遗物，档案馆还欠你一件。",
	"尚未获得遗物，等一段记忆附上来。",
	"尚未获得遗物，灯芯旁空着。",
	"尚未获得遗物，下一间房也许有。",
]

const CODEX_COMBOS: Array[String] = [
	"尚未发现组合。在造句台组合 2–3 个词后，配方会记录在这里。",
	"尚未发现组合。在造句台试着组合 2–3 个词，配方会记录在这里。",
	"尚未发现组合。在造句台把 2–3 个词排成一句，配方会记录在这里。",
	"尚未发现组合。在造句台挑 2–3 个词碰一碰，配方会记录在这里。",
	"尚未发现组合。在造句台组合 2–3 个词，失败也算，配方会记录在这里。",
	"尚未发现组合。在造句台用 2–3 个词写第一句，配方会记录在这里。",
	"尚未发现组合。在造句台组合 2–3 个词试试，配方会记录在这里。",
	"尚未发现组合。在造句台留下 2–3 个词的搭配，配方会记录在这里。",
]


static func variants(state_id: StringName) -> Array[String]:
	match state_id:
		&"codex_words":
			return CODEX_WORDS.duplicate()
		&"codex_combos":
			return CODEX_COMBOS.duplicate()
		&"inventory_words":
			return INVENTORY_WORDS.duplicate()
		&"inventory_relics":
			return INVENTORY_RELICS.duplicate()
	return []


static func pick(state_id: StringName, run_seed: int = 0) -> String:
	var lines := variants(state_id)
	if lines.is_empty():
		return ""
	return lines[posmod(hash("empty_state:%d:%s" % [run_seed, state_id]), lines.size())]
