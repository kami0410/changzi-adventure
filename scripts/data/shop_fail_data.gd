class_name ShopFailData
extends RefCounted

## Hub shop purchase-failure lines. Copy only: stock, prices, ownership and
## fragment counts do not change. There is no run RNG in the Hub, so picking is
## stable per failure kind + item id (a fixed id) and consumes no randomness.
## The mechanical prefix and both numbers stay in every insufficient line.

const OWNED_LINES: Array[String] = [
	"这件货已经在你的手里了。它记得每一笔，不用再翻。",
	"这件货已经在你的手里了。同一页不会卖第二次。",
	"这件货已经在你的手里了。它认得你，别再替它赎身。",
	"这件货已经在你的手里了。柜台不做重样的生意。",
	"这件货已经在你的手里了。你摸到口袋里那件旧货，账已经清了。",
	"这件货已经在你的手里了。算盘拨回去，回声都没有。",
	"这件货已经在你的手里了。再买一次，它也只会跟你回家。",
	"这件货已经在你的手里了。它在你行囊里睡得正沉。",
]

const INSUFFICIENT_LINES: Array[String] = [
	"记忆碎片不足：需要 {cost}，你只有 {have}。柜台后的影子把货推了回去。",
	"记忆碎片不足——这页要 {cost}，你只有 {have}。先去找些旧书页吧。",
	"记忆碎片不足。价签上写着 {cost}，你掌心里只有 {have}。",
	"记忆碎片不足：{cost} 枚的货，你的布袋里只有 {have} 枚。",
	"记忆碎片不足。它按住货：{cost} 枚；你数了两遍，{have} 枚。",
	"记忆碎片不足——货要 {cost} 枚，你只带了 {have} 枚。",
	"记忆碎片不足。柜台上的灯暗了一格：{cost} 枚，你只有 {have} 枚。",
	"记忆碎片不足。它不赊账：{cost} 枚的货，你只有 {have} 枚。",
]

const MISSING_LINES: Array[String] = [
	"没有这件货。柜台后翻遍货架，只翻出一层灰。",
	"没有这件货。货单上找不到这一页，也许它还没被写出来。",
	"没有这件货。柜台后的影子摊了摊手。",
	"没有这件货。灯芯爆了一下，像在替你尴尬。",
]


static func variants(kind: StringName) -> Array[String]:
	match kind:
		&"owned":
			return OWNED_LINES.duplicate()
		&"insufficient":
			return INSUFFICIENT_LINES.duplicate()
		&"missing":
			return MISSING_LINES.duplicate()
	return []


static func pick(kind: StringName, item_id: StringName) -> String:
	var lines := variants(kind)
	if lines.is_empty():
		return ""
	return lines[posmod(hash("shop_fail:%s:%s" % [kind, item_id]), lines.size())]


## Replaces the two numeric placeholders; lines without them pass through.
static func format(text: String, cost: int = 0, have: int = 0) -> String:
	return text.replace("{cost}", str(cost)).replace("{have}", str(have))
