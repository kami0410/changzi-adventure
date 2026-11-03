class_name RelicEffects
extends RefCounted

var run: RunState
var player: Player
var revive_used: bool = false
var _second: float = 0.0
var _lifesteal_bank: float = 0.0
var _purify_seconds: float = 0.0

static func describe(effect_id: StringName) -> String:
	match effect_id:
		&"ink_regen": return "每秒额外恢复 3 墨量。"
		&"cooldown_reduction": return "短语冷却缩短 25%。"
		&"lifesteal_up": return "造成伤害的 10% 转化为生命。"
		&"rest_heal": return "清空房间后额外恢复 18 生命。"
		&"slow_aura": return "每秒减缓附近 220 像素内敌人 30%。"
		&"corruption_sight": return "污染达到 25 时，短语伤害提升 40%。"
		&"decode_bonus": return "获取新词时恢复 12 墨量，击杀额外回墨 3。"
		&"revive_once": return "每局一次：致命伤害后以 40 生命复活。"
		&"purify_flow": return "每 5 秒净化 1 点污染；清空房间时额外净化 4 点。"
	return "未知的记忆。"

func has(effect_id: StringName) -> bool:
	if run == null:
		return false
	for relic in run.inventory.relics:
		if relic != null and relic.effect_id == effect_id:
			return true
	return false

func tick(delta: float, enemies: Array[Node]) -> void:
	_second += delta
	if _second < 1.0 or run == null:
		return
	_second -= 1.0
	run.restore_ink(2 + (3 if has(&"ink_regen") else 0))
	if has(&"purify_flow"):
		_purify_seconds += 1.0
		if _purify_seconds >= 5.0:
			_purify_seconds = 0.0
			run.add_corruption(-1)
	if has(&"slow_aura") and is_instance_valid(player):
		for enemy in enemies:
			if enemy is Enemy and not enemy.dead and player.global_position.distance_to(enemy.global_position) < 220.0:
				enemy.apply_slow(0.7, 1.2)

func on_damage(amount: int) -> void:
	if amount <= 0 or not has(&"lifesteal_up") or not is_instance_valid(player):
		return
	_lifesteal_bank += amount * 0.1
	var heal_amount := int(_lifesteal_bank)
	if heal_amount > 0:
		_lifesteal_bank -= heal_amount
		player.heal(heal_amount)

func on_kill() -> void:
	if run != null:
		run.restore_ink(8 + (3 if has(&"decode_bonus") else 0))

func on_room_cleared() -> void:
	if has(&"rest_heal") and is_instance_valid(player):
		player.heal(18)
	if has(&"purify_flow") and run != null:
		run.add_corruption(-4)

func cooldown_scale() -> float:
	return 0.75 if has(&"cooldown_reduction") else 1.0

func damage_scale() -> float:
	return 1.4 if has(&"corruption_sight") and run.corruption >= 25 else 1.0
