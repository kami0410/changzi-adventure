class_name StatusEffects
extends RefCounted

## 状态效果工具。目前只包含减速；数值语义统一在这里换算。

const MIN_SLOW_MULTIPLIER := 0.05


## slow_amount 是减速比例：0.2 表示速度降低 20%，即倍率 0.8。
static func slow_multiplier(amount: float) -> float:
	return clampf(1.0 - amount, MIN_SLOW_MULTIPLIER, 1.0)


## 对一组敌人施加同一减速；死亡的敌人会被跳过。
static func apply_slow(enemies: Array[Enemy], amount: float, duration: float) -> void:
	if amount <= 0.0 or duration <= 0.0:
		return
	var multiplier := slow_multiplier(amount)
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy) or enemy.is_dead():
			continue
		enemy.apply_slow(multiplier, duration)
