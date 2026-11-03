extends RefCounted
class_name ContentLibrary

## Explicitly preloaded content. Runtime directory scans do not survive
## Godot exports reliably, so every shipped .tres is referenced here.

const WORDS: Array[Resource] = [
	preload("res://resources/words/bihu.tres"),
	preload("res://resources/words/jinghua.tres"),
	preload("res://resources/words/xidi.tres"),
	preload("res://resources/words/shemian.tres"),
	preload("res://resources/words/gr.tres"),
	preload("res://resources/words/grguan.tres"),
	preload("res://resources/words/grlufai.tres"),
	preload("res://resources/words/guanzilu.tres"),
	preload("res://resources/words/hongming.tres"),
	preload("res://resources/words/huixiang.tres"),
	preload("res://resources/words/jilu.tres"),
	preload("res://resources/words/lei.tres"),
	preload("res://resources/words/posui.tres"),
	preload("res://resources/words/quanbing.tres"),
	preload("res://resources/words/ranshao.tres"),
	preload("res://resources/words/shenyuan.tres"),
	preload("res://resources/words/tunshi.tres"),
	preload("res://resources/words/weiyi.tres"),
	preload("res://resources/words/wusheng.tres"),
	preload("res://resources/words/xinghong.tres"),
	preload("res://resources/words/xue.tres"),
	preload("res://resources/words/xunji.tres"),
	preload("res://resources/words/yan.tres"),
	preload("res://resources/words/yongheng.tres"),
	preload("res://resources/words/yueqian.tres"),
	preload("res://resources/words/zhaohuan.tres"),
	preload("res://resources/words/zhuore.tres"),
	preload("res://resources/words/fengbao.tres"),
	preload("res://resources/words/jingmo.tres"),
	preload("res://resources/words/gengu.tres"),
	preload("res://resources/words/beiming.tres"),
	preload("res://resources/words/guiyan.tres"),
	preload("res://resources/words/shanhuo.tres"),
	preload("res://resources/words/xuanyu.tres"),
	preload("res://resources/words/duyao.tres"),
	preload("res://resources/words/huiwang.tres"),
	preload("res://resources/words/yinyan.tres"),
	preload("res://resources/words/jiyi.tres"),
	preload("res://resources/words/guize.tres"),
	preload("res://resources/words/bing.tres"),
	preload("res://resources/words/feng.tres"),
	preload("res://resources/words/guang.tres"),
	preload("res://resources/words/ying.tres"),
	preload("res://resources/words/meng.tres"),
	preload("res://resources/words/xing.tres"),
	preload("res://resources/words/jing.tres"),
	preload("res://resources/words/dongjie.tres"),
	preload("res://resources/words/gechang.tres"),
	preload("res://resources/words/yiwang.tres"),
	preload("res://resources/words/juda.tres"),
	preload("res://resources/words/shensheng.tres"),
	preload("res://resources/words/qihei.tres"),
	preload("res://resources/words/shuangsheng.tres"),
	preload("res://resources/words/baolie.tres"),
	preload("res://resources/words/buxi.tres"),
	preload("res://resources/words/chao.tres"),
	preload("res://resources/words/chongxie.tres"),
	preload("res://resources/words/deng.tres"),
	preload("res://resources/words/dingshen.tres"),
	preload("res://resources/words/gu.tres"),
	preload("res://resources/words/guan.tres"),
	preload("res://resources/words/guanchuan.tres"),
	preload("res://resources/words/hua.tres"),
	preload("res://resources/words/hundun.tres"),
	preload("res://resources/words/kong.tres"),
	preload("res://resources/words/kongbai.tres"),
	preload("res://resources/words/kuangluan.tres"),
	preload("res://resources/words/lianhuan.tres"),
	preload("res://resources/words/liekai.tres"),
	preload("res://resources/words/men.tres"),
	preload("res://resources/words/mingliang.tres"),
	preload("res://resources/words/mo.tres"),
	preload("res://resources/words/qiyue.tres"),
	preload("res://resources/words/ruili.tres"),
	preload("res://resources/words/shan.tres"),
	preload("res://resources/words/shouwang.tres"),
	preload("res://resources/words/shuang.tres"),
	preload("res://resources/words/shui.tres"),
	preload("res://resources/words/suolian.tres"),
	preload("res://resources/words/tansuo.tres"),
	preload("res://resources/words/wanqian.tres"),
	preload("res://resources/words/xin.tres"),
	preload("res://resources/words/ya.tres"),
	preload("res://resources/words/yanjing.tres"),
	preload("res://resources/words/ye.tres"),
	preload("res://resources/words/yu.tres"),
	preload("res://resources/words/yuangu.tres"),
	preload("res://resources/words/yue.tres"),
	preload("res://resources/words/zhenming.tres"),
	preload("res://resources/words/zhentui.tres"),
	preload("res://resources/words/zhixu.tres"),
	preload("res://resources/words/zhong.tres"),
	preload("res://resources/words/zhuilie.tres"),
	preload("res://resources/words/zhuiluo.tres"),
	preload("res://resources/words/zi.tres"),
]

static func words() -> Array[Resource]:
	return WORDS.duplicate()

const PHRASES: Array[Resource] = [
	preload("res://resources/phrases/broken_devour_abyss.tres"),
	preload("res://resources/phrases/broken_life.tres"),
	preload("res://resources/phrases/burn_blood.tres"),
	preload("res://resources/phrases/crimson_devour_blood.tres"),
	preload("res://resources/phrases/crimson_life.tres"),
	preload("res://resources/phrases/devour_abyss.tres"),
	preload("res://resources/phrases/erode_life.tres"),
	preload("res://resources/phrases/eternal_record_life.tres"),
	preload("res://resources/phrases/extend_record.tres"),
	preload("res://resources/phrases/record_life.tres"),
	preload("res://resources/phrases/scorching_record.tres"),
	preload("res://resources/phrases/shelter_authority.tres"),
	preload("res://resources/phrases/summon_echo.tres"),
	preload("res://resources/phrases/swift_jump_echo.tres"),
	preload("res://resources/phrases/thunder_summon_lei.tres"),
	preload("res://resources/phrases/unique_authority.tres"),
]

static func phrases() -> Array[Resource]:
	return PHRASES.duplicate()

const RELICS: Array[Resource] = [
	preload("res://resources/relics/abyssal_bell.tres"),
	preload("res://resources/relics/blood_quill.tres"),
	preload("res://resources/relics/breathing_lung.tres"),
	preload("res://resources/relics/immortal_archive.tres"),
	preload("res://resources/relics/ink_heart.tres"),
	preload("res://resources/relics/polluted_eye.tres"),
	preload("res://resources/relics/readers_tongue.tres"),
	preload("res://resources/relics/time_shard.tres"),
	preload("res://resources/relics/clean_ink_lantern.tres"),
]

static func relics() -> Array[Resource]:
	return RELICS.duplicate()

static func relic_by_id(id: StringName) -> RelicData:
	for resource in RELICS:
		var relic := resource as RelicData
		if relic != null and relic.id == id:
			return relic
	return null

const WEAPONS: Array[Resource] = [
	preload("res://resources/weapons/archive_hammer.tres"),
	preload("res://resources/weapons/blood_vein_whip.tres"),
	preload("res://resources/weapons/breath_cleaver.tres"),
	preload("res://resources/weapons/broken_page_sword.tres"),
	preload("res://resources/weapons/chain_blade.tres"),
	preload("res://resources/weapons/echo_flute.tres"),
	preload("res://resources/weapons/ink_axe.tres"),
	preload("res://resources/weapons/ink_bolt_gun.tres"),
	preload("res://resources/weapons/miasma_bow.tres"),
	preload("res://resources/weapons/page_shuriken.tres"),
	preload("res://resources/weapons/talisman_gun.tres"),
	preload("res://resources/weapons/thunder_rod.tres"),
]

static func weapons() -> Array[Resource]:
	return WEAPONS.duplicate()

## Chapter 1 demo exposes six weapons and six relics, each with a distinct
## behaviour. The rest stay in WEAPONS/RELICS for chapters 2–4 and the full game.
const DEMO_WEAPONS: Array[Resource] = [
	preload("res://resources/weapons/broken_page_sword.tres"),
	preload("res://resources/weapons/chain_blade.tres"),
	preload("res://resources/weapons/ink_axe.tres"),
	preload("res://resources/weapons/ink_bolt_gun.tres"),
	preload("res://resources/weapons/echo_flute.tres"),
	preload("res://resources/weapons/talisman_gun.tres"),
]

static func demo_weapons() -> Array[Resource]:
	return DEMO_WEAPONS.duplicate()

const DEMO_RELICS: Array[Resource] = [
	preload("res://resources/relics/ink_heart.tres"),
	preload("res://resources/relics/time_shard.tres"),
	preload("res://resources/relics/blood_quill.tres"),
	preload("res://resources/relics/immortal_archive.tres"),
	preload("res://resources/relics/clean_ink_lantern.tres"),
	preload("res://resources/relics/abyssal_bell.tres"),
]

static func demo_relics() -> Array[Resource]:
	return DEMO_RELICS.duplicate()

const ENEMIES: Array[Resource] = [
	preload("res://resources/enemies/amnesiac_echo.tres"),
	preload("res://resources/enemies/blank_man.tres"),
	preload("res://resources/enemies/breath_hound.tres"),
	preload("res://resources/enemies/collapse_husk.tres"),
	preload("res://resources/enemies/hanging_scribe.tres"),
	preload("res://resources/enemies/ink_hound.tres"),
	preload("res://resources/enemies/lung_moth.tres"),
	preload("res://resources/enemies/rust_whisperer.tres"),
	preload("res://resources/enemies/scribe_bug.tres"),
	preload("res://resources/enemies/typo_beast.tres"),
	preload("res://resources/enemies/ink_bomber.tres"),
	preload("res://resources/enemies/choir_summoner.tres"),
	preload("res://resources/enemies/mirror_sniper.tres"),
	preload("res://resources/enemies/page_swarm.tres"),
]

static func enemies() -> Array[Resource]:
	return ENEMIES.duplicate()

const AUTHORITIES: Array[Resource] = [
	preload("res://resources/authorities/archive.tres"),
	preload("res://resources/authorities/devour.tres"),
	preload("res://resources/authorities/revive.tres"),
	preload("res://resources/authorities/rewrite.tres"),
]

static func authorities() -> Array[Resource]:
	return AUTHORITIES.duplicate()

const BOSSES: Array[Resource] = [
	preload("res://resources/bosses/ink_archivist.tres"),
]

static func bosses() -> Array[Resource]:
	return BOSSES.duplicate()

