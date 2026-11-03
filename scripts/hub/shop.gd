class_name Shop
extends RefCounted

var stock: Array[Dictionary] = []
## 0.0 = full price; set by a 言灵 spoken to 咕噜.
var discount: float = 0.0


func price_for(item_id: StringName) -> int:
	var entry := get_entry(item_id)
	if entry.is_empty():
		return 0
	var cost := int(entry.get("cost", 0))
	if cost <= 0:
		return 0
	return maxi(int(ceilf(float(cost) * (1.0 - clampf(discount, 0.0, 0.9)))), 1)


func get_entry(item_id: StringName) -> Dictionary:
	for entry in stock:
		if StringName(entry.get("id", &"")) == item_id:
			return entry
	return {}


func buy(item_id: StringName, profile: Profile) -> bool:
	if profile == null or item_id == &"":
		return false
	var entry := get_entry(item_id)
	if entry.is_empty():
		return false
	var kind := StringName(entry.get("kind", &"word"))
	if owned_by(entry, profile):
		return false
	var cost := price_for(item_id)
	if cost < 0 or profile.memory_fragments < cost:
		return false
	profile.memory_fragments -= cost
	if kind == &"word":
		profile.unlock_word(item_id)
	elif kind == &"relic":
		profile.store_relic(item_id)
	return true


func owned_by(entry: Dictionary, profile: Profile) -> bool:
	if profile == null or entry.is_empty():
		return false
	var item_id := StringName(entry.get("id", &""))
	if StringName(entry.get("kind", &"word")) == &"relic":
		return profile.stored_relics.has(item_id)
	return profile.is_word_unlocked(item_id)
