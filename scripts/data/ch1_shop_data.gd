class_name Ch1ShopData
extends RefCounted

## Flavour copy for the Chapter 1 paper-man exchange. Stock, prices and the
## purchase effects stay in RunLoot; only the paper man's opening line rotates.
## It is seeded by the run and the stall id so a resume shows the same line and
## the pick never consumes the run RNG (loot order must not shift).

const LINES: Array[String] = [
	"纸人只收残页。买完这一页，它就会翻过去。",
	"纸人的脸是空白的。它说，价钱都写在你的表情上。",
	"雨从书缝里漏下来。纸人把货架往干处挪了挪。",
	"纸人翻开账本，里面没有字，只有一排湿掉的指印。",
	"纸人朝你鞠躬，纸褶里掉出一句别人没说完的话。",
]
## After a sale the paper man answers the purchase itself. Seeded by run, stall
## and row so a resumed run shows the same feedback and no run RNG is consumed.
const BUY_LINES: Array[String] = [
	"纸人把残页收进袖里，替你翻到下一页。",
	"交易成了。纸人的空白脸上浮出一枚很淡的印章。",
	"纸人点了点头，纸褶里掉出一小截干掉的墨线。",
	"货架轻了一格。纸人把空出来的位置擦了三遍。",
	"纸人无声地笑了一下——如果那张脸算是在笑。",
]


static func pick(run_seed: int, shop_id: String) -> String:
	if LINES.is_empty():
		return ""
	return LINES[posmod(hash("%d:%s" % [run_seed, shop_id]), LINES.size())]


static func pick_buy(run_seed: int, shop_id: String, row: int) -> String:
	if BUY_LINES.is_empty():
		return ""
	return BUY_LINES[posmod(hash("%d:%s:%d" % [run_seed, shop_id, row]), BUY_LINES.size())]
