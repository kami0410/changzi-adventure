class_name ArchiveData
extends RefCounted

## The Archive altar's permanent, uncapped upgrade tracks. Costs grow
## geometrically; values are deliberately small per level so a long-lived
## archive grows without flattening a fresh run.
const TRACKS: Array[Dictionary] = [
	{
		&"id": &"vitality", &"name": "生命上限",
		&"description": "每级 +10 生命上限",
		&"base_cost": 20, &"growth": 1.35,
	},
	{
		&"id": &"ink", &"name": "墨量上限",
		&"description": "每级 +5 墨量上限",
		&"base_cost": 18, &"growth": 1.35,
	},
	{
		&"id": &"damage", &"name": "言灵伤害",
		&"description": "每级 +4% 言灵伤害",
		&"base_cost": 25, &"growth": 1.4,
	},
	{
		&"id": &"ward", &"name": "污染抗性",
		&"description": "每级降低污染获取（递减，永不免疫）",
		&"base_cost": 22, &"growth": 1.4,
	},
]


static func track(track_id: StringName) -> Dictionary:
	for entry in TRACKS:
		if StringName(entry.get(&"id", &"")) == track_id:
			return entry
	return {}


static func cost(track_id: StringName, level: int) -> int:
	var entry := track(track_id)
	if entry.is_empty():
		return 0
	var base := float(entry.get(&"base_cost", 20))
	var growth := float(entry.get(&"growth", 1.35))
	return mini(int(ceil(base * pow(growth, maxi(level, 0)))), 999999)
