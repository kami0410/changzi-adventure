class_name AuthorityEffects
extends RefCounted

## 权柄整局效果的标记层。实际的复活/重掷/保留物品由主线程按标记执行。
## 返回值固定包含 revive / rewrite / devour / archive 四个布尔键；
## devour 额外返回临时伤害标记 damage_bonus 与 temporary。


static func apply(run: RunState, authority: AuthorityData) -> Dictionary:
	var result := {
		"revive": false,
		"rewrite": false,
		"devour": false,
		"archive": false,
	}
	if run == null or authority == null:
		return result

	run.set_authority(authority)
	var effect := authority.effect_id if authority.effect_id != &"" else authority.id
	match effect:
		&"revive":
			result["revive"] = true
		&"rewrite":
			result["rewrite"] = true
		&"devour":
			result["devour"] = true
			result["damage_bonus"] = run.corruption
			result["temporary"] = true
		&"archive":
			result["archive"] = true
	return result
