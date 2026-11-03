class_name Difficulty
extends RefCounted

## Four authored difficulty tiers. The world, enemy data and rewards read these
## multipliers instead of sprinkling `if Flow.difficulty > 0` checks around.
const LEVELS: Array[Dictionary] = [
	{
		&"id": &"calm", &"name": "平静", &"subtitle": "为故事而来",
		&"enemy_health": 1.0, &"enemy_damage": 1.0,
		&"reward": 1.0, &"corruption": 1.0,
		&"note": "敌人保持原样，适合先看剧情与构筑。",
	},
	{
		&"id": &"rain", &"name": "墨雨", &"subtitle": "档案馆的标准难度",
		&"enemy_health": 1.25, &"enemy_damage": 1.15,
		&"reward": 1.15, &"corruption": 1.0,
		&"note": "敌人更耐打，收益略高。",
	},
	{
		&"id": &"abyss", &"name": "深渊", &"subtitle": "为熟悉言灵的史官准备",
		&"enemy_health": 1.5, &"enemy_damage": 1.3,
		&"reward": 1.3, &"corruption": 1.15,
		&"note": "敌人更凶，污染也更难压住，但残页与碎片更多。",
	},
	{
		&"id": &"nightmare", &"name": "噩梦", &"subtitle": "档案馆不再保护你",
		&"enemy_health": 1.85, &"enemy_damage": 1.5,
		&"reward": 1.6, &"corruption": 1.3,
		&"note": "高伤高血肉量，只有最熟练的构筑能走完四章。",
	},
]


static func level(index: int) -> Dictionary:
	return LEVELS[clampi(index, 0, LEVELS.size() - 1)]


static func count() -> int:
	return LEVELS.size()


static func display_name(index: int) -> String:
	return String(level(index).get(&"name", "墨雨"))


static func subtitle(index: int) -> String:
	return String(level(index).get(&"subtitle", ""))


static func note(index: int) -> String:
	return String(level(index).get(&"note", ""))


static func enemy_health(index: int) -> float:
	return float(level(index).get(&"enemy_health", 1.0))


static func enemy_damage(index: int) -> float:
	return float(level(index).get(&"enemy_damage", 1.0))


static func reward_multiplier(index: int) -> float:
	return float(level(index).get(&"reward", 1.0))


static func corruption_multiplier(index: int) -> float:
	return float(level(index).get(&"corruption", 1.0))
