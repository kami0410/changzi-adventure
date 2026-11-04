class_name VaultRoomData
extends RefCounted

## First-discovery line for a hidden vault. Copy only: the objective, chest and
## stele stay untouched, and every line keeps the same search hint. Picking is
## stable per run + room id and never consumes the run RNG.

const LINES: Array[String] = [
	"发现隐藏书库 · 书架后还有一页灯亮着，搜查宝箱与残碑",
	"发现隐藏书库 · 门缝里漏出旧纸的气味，搜查宝箱与残碑",
	"发现隐藏书库 · 有人把名字藏在这里，搜查宝箱与残碑",
	"发现隐藏书库 · 尘埃下面压着未读完的段落，搜查宝箱与残碑",
	"发现隐藏书库 · 书脊上留着新鲜的指印，搜查宝箱与残碑",
	"发现隐藏书库 · 最里面那格书架刚刚合上，搜查宝箱与残碑",
	"发现隐藏书库 · 灯芯还温着，搜查宝箱与残碑",
	"发现隐藏书库 · 这一间不在地图上，搜查宝箱与残碑",
]


static func variants() -> Array[String]:
	return LINES.duplicate()


## Stable for one run + room, without touching run.rng.
static func pick(run_seed: int, room_id: String) -> String:
	if LINES.is_empty():
		return ""
	return LINES[posmod(hash("%d:%s" % [run_seed, room_id]), LINES.size())]
