class_name RunMutators
extends RefCounted

## 章节异象（1.0）：每一局的每一章都从池子里抽一种全局异象，叠在遭遇变数之上，
## 让同一张地图每次打起来都不一样。由 run seed + 章节决定，重载/检查点
## 复现同一种，不占 run RNG，不新增存档键。
##
## 每种异象都是“一好一坏”，HUD 区域名后常驻显示，章首提示一次。

const NONE := &""
const INK_TIDE := &"ink_tide"
const BLOOD_MOON := &"blood_moon"
const SWARM := &"swarm"
const SILENCE := &"silence"
const ZEAL := &"zeal"
const BOUNTY := &"bounty"
const FOG := &"fog"
const IRON := &"iron"
const ALL: Array[StringName] = [INK_TIDE, BLOOD_MOON, SWARM, SILENCE, ZEAL, BOUNTY, FOG, IRON]

const NAMES := {
	INK_TIDE: "墨潮", BLOOD_MOON: "血月", SWARM: "群鸦", SILENCE: "静默",
	ZEAL: "狂信", BOUNTY: "丰饶", FOG: "雾锁", IRON: "铁壁",
}
const HINTS := {
	INK_TIDE: "每次击杀回 5 墨，但敌人生命 +15%",
	BLOOD_MOON: "精英出现得更频繁，精英掉落的残页翻倍",
	SWARM: "每场战斗多一个敌人，击杀残页 +1",
	SILENCE: "言灵冷却 -35%，但你受到的伤害 +10%",
	ZEAL: "你的伤害 +25%，受到的伤害也 +25%",
	BOUNTY: "击杀残页翻倍，但敌人更快",
	FOG: "污染增长 -40%，但敌人隔得更远就会发现你",
	IRON: "敌人生命 +40%，但武器掉落率翻倍",
}

## Numbers each hook reads; NONE leaves everything at 1 / 0.
const ENEMY_HEALTH := {INK_TIDE: 1.15, IRON: 1.4}
const ENEMY_SPEED := {BOUNTY: 1.12}
const KILL_INK := {INK_TIDE: 5}
const KILL_PAGES_BONUS := {SWARM: 1}
const KILL_PAGES_SCALE := {BOUNTY: 2.0}
const ELITE_PAGES_SCALE := {BLOOD_MOON: 2.0}
const ELITE_EXTRA_CHANCE := {BLOOD_MOON: 0.45}
const EXTRA_ENEMIES := {SWARM: 1}
const PHRASE_COOLDOWN := {SILENCE: 0.65}
const DAMAGE_TAKEN := {SILENCE: 1.1, ZEAL: 1.25}
const DAMAGE_DEALT := {ZEAL: 1.25}
const CORRUPTION_GAIN := {FOG: 0.6}
const AGGRO_BONUS := {FOG: 220.0}
const WEAPON_DROP_SCALE := {IRON: 2.0}


## The chapter's mutator for this run. Every chapter rolls (the first one too).
static func for_chapter(run_seed: int, chapter: int) -> StringName:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("mutator|%d|%d" % [run_seed, chapter])
	return ALL[rng.randi_range(0, ALL.size() - 1)]


static func display_name(mutator: StringName) -> String:
	return String(NAMES.get(mutator, ""))


static func hint(mutator: StringName) -> String:
	if mutator == NONE:
		return ""
	return "本章异象 · %s：%s" % [display_name(mutator), String(HINTS.get(mutator, ""))]


static func value(table: Dictionary, mutator: StringName, fallback: float = 1.0) -> float:
	return float(table.get(mutator, fallback))
