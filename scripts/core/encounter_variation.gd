class_name EncounterVariation
extends RefCounted

## Per-run variation for ordinary combat encounters (all chapters).
##
## The authored wave stays the backbone; on top of it each run rolls, from the
## run seed and the encounter id, so a reload or checkpoint replays the same
## fight while a new run gets a different one:
## - some enemies swapped for others from the same chapter's roster,
## - sometimes one extra enemy (more likely in later chapters),
## - an optional modifier: 精英 (one hardened enemy that pays extra pages),
##   迅潮 (everyone faster) or 群潮 (two extra, frailer enemies),
## - shuffled spawn spacing and side.
## Never consumes the run RNG, so loot rolls are unaffected.

const NONE := &"none"
const ELITE := &"elite"
const SWIFT := &"swift"
const HORDE := &"horde"
const MODIFIERS: Array[StringName] = [ELITE, SWIFT, HORDE]
const MODIFIER_NAMES := {
	ELITE: "精英",
	SWIFT: "迅潮",
	HORDE: "群潮",
}
const MODIFIER_HINTS := {
	ELITE: "遭遇变数 · 精英：金色的敌人更硬更痛，击败多掉残页",
	SWIFT: "遭遇变数 · 迅潮：敌人行动更快",
	HORDE: "遭遇变数 · 群潮：敌人更多，但更脆弱",
}
const SUBSTITUTE_CHANCE := 0.35
const EXTRA_BASE_CHANCE := 0.3
const EXTRA_PER_CHAPTER := 0.1
const MODIFIER_CHANCE := 0.35
const ELITE_HEALTH := 2.0
const ELITE_DAMAGE := 1.3
const ELITE_PAGES := 4
const SWIFT_SPEED := 1.25
const HORDE_HEALTH := 0.6
const ELITE_TINT := Color(1.35, 1.12, 0.62)


## Deterministic RNG for one encounter of one run.
static func rng_for(run_seed: int, key: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%s" % [run_seed, key])
	return rng


## Every enemy id used by a chapter's authored waves, in first-seen order.
static func roster(waves: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for wave in waves:
		if not wave is Array:
			continue
		for id in wave:
			var sid := StringName(id)
			if not out.has(sid):
				out.append(sid)
	return out


## Rolls the variation. Returns {first, rest, modifier, elite, offsets_sign,
## spacing, start}. `elite` indexes the combined first+rest list (-1 = none).
static func roll(first: Array, rest: Array, pool: Array[StringName], run_seed: int,
		key: String, chapter: int) -> Dictionary:
	var rng := rng_for(run_seed, key)
	var out_first: Array = first.duplicate()
	var out_rest: Array = rest.duplicate()
	if not pool.is_empty():
		for list in [out_first, out_rest]:
			for i in list.size():
				if rng.randf() < SUBSTITUTE_CHANCE:
					list[i] = pool[rng.randi_range(0, pool.size() - 1)]
		if rng.randf() < EXTRA_BASE_CHANCE + EXTRA_PER_CHAPTER * float(clampi(chapter, 0, 3)):
			out_rest.append(pool[rng.randi_range(0, pool.size() - 1)])
	var modifier: StringName = NONE
	if rng.randf() < MODIFIER_CHANCE:
		modifier = MODIFIERS[rng.randi_range(0, MODIFIERS.size() - 1)]
	if modifier == HORDE and not pool.is_empty():
		for i in 2:
			out_rest.append(pool[rng.randi_range(0, pool.size() - 1)])
	var total := out_first.size() + out_rest.size()
	var elite := rng.randi_range(0, maxi(total - 1, 0)) if modifier == ELITE and total > 0 else -1
	return {
		"first": out_first,
		"rest": out_rest,
		"modifier": modifier,
		"elite": elite,
		"side": -1.0 if rng.randf() < 0.5 else 1.0,
		"spacing": rng.randf_range(120.0, 170.0),
		"start": rng.randf_range(90.0, 170.0),
	}


## Spawn x offset (from the arena centre) for the [param index]-th enemy of a
## group. Like the authored layout the line starts on one side and marches
## across; [param group_shift] lets the second group start a little closer.
static func spawn_offset(variation: Dictionary, index: int, group_shift: float = 0.0) -> float:
	var side: float = variation.get("side", 1.0)
	var start: float = variation.get("start", 140.0)
	var spacing: float = variation.get("spacing", 150.0)
	return side * (-(start + group_shift) + spacing * float(index))


static func modifier_name(modifier: StringName) -> String:
	return String(MODIFIER_NAMES.get(modifier, ""))


static func modifier_hint(modifier: StringName) -> String:
	return String(MODIFIER_HINTS.get(modifier, ""))
