class_name RestRoomData
extends RefCounted

## Short arrival line for a rest room. Copy only: the objective, shop stock and
## rewards stay untouched. Picking is stable per run + room id and never
## consumes the run RNG, so the loot sequence does not move.

const LINES: Array[String] = [
	"纸人把灯芯拨亮，等你开口。",
	"屋檐滴水，摊上的旧货都醒着。",
	"这里的雨声比外面轻。",
	"灯下留着一页空白，正好歇脚。",
	"纸人挪开半边柜台：先坐，买卖不急。",
	"墙上的门牌褪了色，门还认得你。",
	"炉灰冷了，纸人仍替你留着一盏。",
	"墨迹未干的名字在墙角晾着。",
]


static func variants() -> Array[String]:
	return LINES.duplicate()


## Stable for one run + room, without touching run.rng.
static func pick(run_seed: int, room_id: String) -> String:
	if LINES.is_empty():
		return ""
	return LINES[posmod(hash("%d:%s" % [run_seed, room_id]), LINES.size())]
