class_name TrustData
extends RefCounted

## Trust has always been stored in Profile as a raw, uncapped float. This class
## turns that number into four readable tiers and derives every tier benefit at
## read time, so existing saves need no migration and no new key is written.
##
## Tier benefits deliberately do not stack with the authored blessings: a
## discount is max(blessing, tier), and the 托付 forge blessing is a per-Hub-visit
## flag owned by the caller.

const TIER_COUNT := 4
const THRESHOLDS: Array[float] = [0.0, 2.0, 6.0, 12.0]
const TIER_IDS: Array[StringName] = [&"stranger", &"acquainted", &"trusted", &"devoted"]
const TIER_NAMES: Array[String] = ["陌生", "熟悉", "信任", "托付"]
const DISCOUNTS: Array[float] = [0.0, 0.05, 0.10, 0.15]
## Pages every trusted NPC contributes to the next fresh run.
const START_PAGES: Array[int] = [0, 1, 3, 6]
const START_PAGES_CAP := 20


static func tier_index(trust: float) -> int:
	if not is_finite(trust):
		return 0
	var result := 0
	for index in THRESHOLDS.size():
		if trust >= THRESHOLDS[index]:
			result = index
	return result


static func tier_id(trust: float) -> StringName:
	return TIER_IDS[tier_index(trust)]


static func tier_name(trust: float) -> String:
	return TIER_NAMES[tier_index(trust)]


static func tier_for(profile: Profile, npc_id: StringName) -> int:
	if profile == null:
		return 0
	return tier_index(profile.npc_trust_value(npc_id))


static func tier_name_for(profile: Profile, npc_id: StringName) -> String:
	return TIER_NAMES[tier_for(profile, npc_id)]


## Shop discount is the higher of 咕噜's authored blessing and the tier value.
static func shop_discount(profile: Profile) -> float:
	if profile == null:
		return 0.0
	var blessing := profile.npc_blessing(&"guru", "shop_discount", 0.0)
	return maxf(blessing, DISCOUNTS[tier_for(profile, &"guru")])


## Forge discount is the higher of 阿砚's authored blessing and the tier value.
static func forge_discount(profile: Profile) -> float:
	if profile == null:
		return 0.0
	var blessing := profile.npc_blessing(&"ayan", "forge_discount", 0.0)
	return maxf(blessing, DISCOUNTS[tier_for(profile, &"ayan")])


## 托付 with 阿砚 earns one free forge per Hub visit. Hub owns the visit flag;
## this only answers whether the tier qualifies.
static func forge_blessing(profile: Profile) -> bool:
	return tier_for(profile, &"ayan") >= TIER_COUNT - 1


## Pages the current roster contributes to a fresh run, capped like the other
## start-of-run bonuses.
static func start_pages(profile: Profile) -> int:
	if profile == null:
		return 0
	var total := 0
	for key in profile.npc_trust.keys():
		total += START_PAGES[tier_index(float(profile.npc_trust[key]))]
	return mini(total, START_PAGES_CAP)
