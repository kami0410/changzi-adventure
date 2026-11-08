class_name PhraseCaster
extends Node

## 短语释放器：管理槽位、墨耗、冷却，并按 ResolvedPhrase 的形态与组件结算。
## 主线程负责接线：bind_run_state / set_player / set_enemy_root / equip_phrase / cast / tick。
##
## v3：组件不再只是“伤害数字”。每个 AI/词库组件都有可见的落地：
## projectiles 真正发射弹幕，pulses 真正分段重复，spread 是扇面角度（弧度），
## duration 延长持续体，burn/slow/stun/knockback 逐次命中生效，chain 在敌人间跳，
## homing 让弹道追踪，pierce 穿透，explosion 命中溅射，summon 召唤回声，
## shield/heal/move_speed 作用于自身。主形态之外的组件会叠加成次级效果层。

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/projectile.tscn")
const MAX_PHRASE_SLOTS := 2
## 单次施放的实体数量上限：保护 120 FPS，数值本身（伤害/范围）不设上限。
const MAX_BOLTS := 96
const MAX_PULSES := 12
const MAX_METEORS := 24
const MAX_ECHOES := 6
const MAX_ZONE_SECONDS := 60.0
const PULSE_GAP := 0.14

## 没有 area 组件时的基础影响半径。
@export var cast_radius: float = 180.0
## slow 组件的基础持续时间；duration 组件会叠加上去。
@export var slow_duration: float = 2.0
@export var projectile_muzzle_offset: float = 20.0

signal cast_succeeded(slot: int)
signal status_changed(slot: int, remaining: float, total: float, cost: int, available: bool)
## 每次法术命中/爆炸时发出，game.gd 用它驱动震屏和顿帧。
signal impact_requested(strength: float, freeze: float)
## A purification phrase actually removed pollution; game.gd announces it.
signal purified(amount: int)
## 言灵权能 that need the level (reveal / unlock / conjure); game.gd applies them.
signal world_power_requested(power: StringName, amount: float)
## Every world power a cast applied, for the HUD toast.
signal world_powers_cast(powers: Array[StringName])

var cooldown_scale: float = 1.0
var damage_scale: float = 1.0
var last_context: SpellContext
var _last_status: Array[String] = ["", ""]
var _active_slot: int = -1
var _cooldown_totals: Array[float] = [0.0, 0.0]
var _run: RunState = null
var _player: Player = null
var _enemy_root: Node2D = null
var _phrases: Array[ResolvedPhrase] = []
var _cooldowns: Array[float] = []

var _enemies_override: Array[Enemy] = []
var _has_enemy_override: bool = false


func _init() -> void:
	_phrases.resize(MAX_PHRASE_SLOTS)
	_cooldowns.resize(MAX_PHRASE_SLOTS)


func bind_run_state(run: RunState) -> void:
	_run = run


func set_player(player: Player) -> void:
	_player = player


func set_enemy_root(root: Node2D) -> void:
	_enemy_root = root


## 测试/特殊战斗用：显式指定敌人列表，优先于 enemy_root 与 enemies 组。
func set_enemies(enemies: Array[Enemy]) -> void:
	_enemies_override.clear()
	for enemy in enemies:
		_enemies_override.append(enemy)
	_has_enemy_override = true


func equip_phrase(slot: int, phrase: ResolvedPhrase) -> bool:
	if slot < 0 or slot >= MAX_PHRASE_SLOTS or phrase == null:
		return false
	_phrases[slot] = phrase
	# 更换短语保留槽位剩余冷却，避免开菜单刷新技能。
	_last_status[slot] = ""
	return true


## Corruption raises the price of every word, so the HUD must show the real
## number rather than the base cost that never matched what was spent.
func effective_ink_cost(slot: int) -> int:
	if slot < 0 or slot >= MAX_PHRASE_SLOTS:
		return 0
	var phrase := _phrases[slot]
	if phrase == null:
		return 0
	var scale := _run.corruption_ink_cost_multiplier() if _run != null else 1.0
	scale *= 1.0 - _mastery_ink_discount(phrase)
	return maxi(int(ceilf(float(phrase.ink_cost) * scale)), 0)


func _mastery_power(phrase: ResolvedPhrase) -> float:
	var profile := Flow.profile if Flow != null else null
	if phrase == null or profile == null:
		return 0.0
	var total := 0.0
	var count := 0
	for word in phrase.words:
		if word != null and not String(word.id).begins_with("__"):
			total += profile.word_mastery_power_bonus(word.id)
			count += 1
	return total / float(count) if count > 0 else 0.0


func _mastery_ink_discount(phrase: ResolvedPhrase) -> float:
	var profile := Flow.profile if Flow != null else null
	if phrase == null or profile == null:
		return 0.0
	var total := 0.0
	var count := 0
	for word in phrase.words:
		if word != null and not String(word.id).begins_with("__"):
			total += profile.word_mastery_ink_discount(word.id)
			count += 1
	return clampf(total / float(count), 0.0, 0.3) if count > 0 else 0.0


func is_ready(slot: int) -> bool:
	if slot < 0 or slot >= MAX_PHRASE_SLOTS:
		return false
	var phrase := _phrases[slot]
	if phrase == null or _run == null or _player == null or not is_instance_valid(_player):
		return false
	if _cooldowns[slot] > 0.0:
		return false
	if slot < _player.disabled_phrase_slots.size() and _player.disabled_phrase_slots[slot]:
		return false
	return _run.ink >= effective_ink_cost(slot)


func get_cooldown_left(slot: int) -> float:
	if slot < 0 or slot >= MAX_PHRASE_SLOTS:
		return 0.0
	return _cooldowns[slot]


func cast(slot: int) -> bool:
	if not is_ready(slot):
		return false
	var phrase := _phrases[slot]
	if not _run.spend_ink(effective_ink_cost(slot)):
		return false
	_active_slot = slot
	var cooldown_multiplier := _run.corruption_cooldown_multiplier() if _run != null else 1.0
	_cooldowns[slot] = maxf(phrase.cooldown * cooldown_scale * cooldown_multiplier, 0.0)
	_cooldown_totals[slot] = _cooldowns[slot]
	_apply_phrase(phrase)
	cast_succeeded.emit(slot)
	return true


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	for index in _cooldowns.size():
		_cooldowns[index] = maxf(_cooldowns[index] - delta, 0.0)
		var phrase := _phrases[index]
		if phrase == null:
			continue
		var ready := is_ready(index)
		var status := "%.1f/%s/%d" % [_cooldowns[index], ready, effective_ink_cost(index)]
		if status != _last_status[index]:
			_last_status[index] = status
			status_changed.emit(index, _cooldowns[index], _cooldown_totals[index], effective_ink_cost(index), ready)


func _apply_phrase(phrase: ResolvedPhrase) -> void:
	if not phrase.spell.is_empty():
		_cast_spell(phrase)
		return
	_apply_legacy(phrase)


# --- v3 spell pipeline ---------------------------------------------------

func _cast_spell(phrase: ResolvedPhrase) -> void:
	var ctx := _build_context(phrase)
	last_context = ctx
	var shape := ctx.shape
	_apply_ink(phrase.components)
	_apply_self_buffs(ctx, shape)
	if ctx.can_draw():
		CombatFX.spawn(ctx.fx_host, ctx.origin, &"cast", ctx.color, ctx.direction.x, minf(ctx.reach, 220.0))
	_cast_shape(ctx, shape)
	var layers := _layers_for(ctx, shape)
	for layer in layers:
		_cast_layer(ctx.fork(), layer)
	if WorldPowers.has_any(phrase.components):
		var applied := WorldPowers.apply(ctx, phrase.components, _target_list(), func(power: StringName, amount: float) -> void:
			world_power_requested.emit(power, amount))
		if not applied.is_empty():
			world_powers_cast.emit(applied)
	_apply_corruption(phrase, phrase.components)
	if ctx.total_dealt() > 0 and ctx.can_draw():
		CombatFX.spawn(ctx.fx_host, ctx.origin + Vector2(0, -24), &"number", Color("f1ddae"), ctx.direction.x, 30, ctx.total_dealt())
	_apply_healing(phrase.components, ctx.total_dealt(), ctx.lifesteal > 0.0)
	ctx.impact(_cast_weight(shape))


func _build_context(phrase: ResolvedPhrase) -> SpellContext:
	var ctx := SpellContext.from_phrase(phrase, slow_duration)
	var style := phrase.spell
	var c := phrase.components
	ctx.shape = StringName(style.get(&"shape", &"blade"))
	if not SpellStyle.NAMES.has(ctx.shape):
		ctx.shape = &"blade"
	ctx.player = _player
	ctx.run = _run
	ctx.fx_host = get_parent() if is_inside_tree() else null
	ctx.target_provider = _target_list
	ctx.feedback = func(strength: float, freeze: float) -> void:
		impact_requested.emit(strength, freeze)
	ctx.direction = _cast_direction()
	ctx.feet = _cast_origin()
	ctx.origin = ctx.feet + Vector2(0, -28)
	# Mastery is real damage, capped at +25% so it cannot be farmed forever.
	var mastery_bonus := clampf(_mastery_power(phrase), 0.0, 0.25)
	ctx.damage = SpellContext.number(c, &"damage") * damage_scale * (1.0 + mastery_bonus)
	ctx.area_scale = 1.0 + minf(SpellContext.number(c, &"area"), 40.0) * 0.45
	var base := SpellStyle.base_for(ctx.shape)
	ctx.reach = maxf(float(style.get(&"range", base[&"range"])), 40.0) * ctx.area_scale
	ctx.pulses = clampi(SpellContext.whole(maxf(float(style.get(&"pulses", 1)), SpellContext.number(c, &"pulses"))), 1, MAX_PULSES)
	return ctx


## Every cast target, alive and active, as SpellTargets dictionaries.
func _target_list() -> Array[Dictionary]:
	if _has_enemy_override:
		return SpellTargets.describe(_enemies_override)
	if _enemy_root != null and is_instance_valid(_enemy_root):
		if is_inside_tree():
			return SpellTargets.active(get_tree())
		var found: Array[Enemy] = []
		_collect_from_node(_enemy_root, found)
		return SpellTargets.describe(found)
	if is_inside_tree():
		return SpellTargets.active(get_tree())
	return []


func _cast_shape(ctx: SpellContext, shape: StringName) -> void:
	match shape:
		&"flame":
			_cast_flame(ctx)
		&"blood":
			_cast_blood(ctx)
		&"chain":
			_cast_chain(ctx)
		&"vortex":
			_cast_vortex(ctx)
		&"ward":
			_cast_ward(ctx)
		&"sentinel":
			_cast_sentinel(ctx)
		&"void":
			_cast_void(ctx)
		&"missile":
			_cast_missiles(ctx)
		&"beam":
			_cast_beam(ctx)
		&"quake":
			_cast_quake(ctx)
		&"meteor":
			_cast_meteors(ctx)
		&"domain":
			_cast_domain(ctx)
		_:
			_cast_blade(ctx)
	if ctx.can_draw() and shape != &"chain" and shape != &"blood":
		SpellVFX.spawn(ctx.fx_host, ctx.origin, shape, ctx.color, ctx.direction.x, minf(ctx.reach, 360.0), PackedVector2Array([Vector2.ZERO]))


## Components that the main shape does not already express become extra layers,
## so "a flame that also summons bolts" really does both.
func _layers_for(ctx: SpellContext, shape: StringName) -> Array[StringName]:
	var layers: Array[StringName] = []
	var volley := ctx.projectiles >= 2.0 or (ctx.projectiles >= 1.0 and ctx.homing > 0.0)
	if volley and not shape in [&"missile", &"meteor", &"chain"]:
		layers.append(&"missile")
	if ctx.chain >= 2 and shape != &"chain":
		layers.append(&"chain")
	if ctx.summon >= 1.0 and shape != &"sentinel":
		layers.append(&"sentinel")
	if ctx.extra_duration >= 2.0 and ctx.damage > 0.0 and not shape in [&"vortex", &"domain", &"sentinel", &"ward"]:
		layers.append(&"domain")
	return layers


func _cast_layer(ctx: SpellContext, layer: StringName) -> void:
	ctx.shape = layer
	match layer:
		&"missile":
			ctx.reach = maxf(ctx.reach, 420.0)
			_cast_missiles(ctx)
		&"chain":
			ctx.reach = maxf(ctx.reach, 320.0)
			_cast_chain(ctx)
		&"sentinel":
			_cast_sentinel(ctx)
		&"domain":
			ctx.damage *= 0.35
			ctx.reach = maxf(ctx.reach * 0.8, 120.0)
			_cast_domain(ctx)


## Camera trauma at the moment of casting. Kept below the hit-stop threshold:
## time only freezes on impacts, never on the button press.
func _cast_weight(shape: StringName) -> float:
	match shape:
		&"void", &"quake":
			return 0.35
		&"beam", &"chain", &"meteor":
			return 0.25
		&"blade":
			return 0.12
	return 0.18


func _repeat(ctx: SpellContext, callback: Callable) -> void:
	for pulse in ctx.pulses:
		SpellSequence.schedule(ctx.fx_host, PULSE_GAP * pulse, callback.bind(pulse))


func _cast_flame(ctx: SpellContext) -> void:
	var cone := cos(clampf(0.72 + ctx.spread * 0.25, 0.3, PI * 0.95))
	if ctx.burn <= 0:
		ctx.burn = maxi(SpellContext.whole(ctx.damage * 0.22), 1)
	_repeat(ctx, func(_pulse: int) -> void:
		for target in _in_cone(ctx, ctx.reach, cone):
			ctx.strike(target, ctx.damage, ctx.origin)
		if _pulse > 0 and ctx.can_draw():
			SpellVFX.spawn(ctx.fx_host, ctx.origin, &"flame", ctx.color, ctx.direction.x, ctx.reach, PackedVector2Array([Vector2.ZERO]))
	)


func _cast_blade(ctx: SpellContext) -> void:
	var cone := cos(clampf(0.98 + ctx.spread * 0.2, 0.3, PI * 0.95))
	_repeat(ctx, func(_pulse: int) -> void:
		for target in _in_cone(ctx, ctx.reach, cone):
			ctx.strike(target, ctx.damage * 0.4, ctx.origin)
		if ctx.can_draw():
			CombatFX.spawn(ctx.fx_host, ctx.origin + ctx.direction * 30.0, &"slash", ctx.color, ctx.direction.x, minf(ctx.reach * 0.6, 160.0))
	)


func _cast_blood(ctx: SpellContext) -> void:
	if ctx.lifesteal <= 0.0:
		ctx.lifesteal = 0.2
	var target := _nearest_in_front(ctx, ctx.reach)
	if not target.is_empty():
		_repeat(ctx, func(_pulse: int) -> void:
			ctx.strike(target, ctx.damage, ctx.origin)
		)
		if ctx.can_draw():
			var points := PackedVector2Array([Vector2.ZERO, (target["center"] as Vector2) - ctx.origin])
			SpellVFX.spawn(ctx.fx_host, ctx.origin, &"blood", ctx.color, ctx.direction.x, ctx.reach, points)


func _cast_chain(ctx: SpellContext) -> void:
	var jumps := clampi(ctx.chain if ctx.chain > 0 else 4, 1, 32)
	_repeat(ctx, func(_pulse: int) -> void:
		var points := PackedVector2Array([Vector2.ZERO])
		var visited: Dictionary = {}
		var current := ctx.origin
		for index in jumps:
			var best := SpellTargets.nearest(ctx.targets(), current, ctx.reach if index == 0 else 240.0 * ctx.area_scale, visited)
			if best.is_empty():
				break
			visited[SpellTargets.id_of(best)] = true
			ctx.strike(best, ctx.damage * pow(0.72, index), current)
			current = best["center"]
			points.append(current - ctx.origin)
		if points.size() == 1:
			points.append(ctx.direction * ctx.reach)
		if ctx.can_draw():
			SpellVFX.spawn(ctx.fx_host, ctx.origin, &"chain", ctx.color, ctx.direction.x, ctx.reach, points)
	)


func _cast_vortex(ctx: SpellContext) -> void:
	if ctx.slow <= 0.0:
		ctx.slow = 0.25
		ctx.slow_duration = maxf(ctx.slow_duration, 0.8)
	var life := minf(5.0 + ctx.extra_duration, MAX_ZONE_SECONDS)
	var pull := maxf(ctx.pull, 1.0)
	if ctx.can_draw():
		SpellDomain.open(ctx.fx_host, ctx, ctx.origin + ctx.direction * 60.0, ctx.reach, life, maxf(ctx.damage * 0.45, 2.0), {"pull": pull, "tick": 0.6})
	else:
		_field_tick_now(ctx, ctx.origin + ctx.direction * 60.0, ctx.reach, maxf(ctx.damage * 0.45, 2.0))


func _cast_domain(ctx: SpellContext) -> void:
	var life := minf(6.0 + ctx.extra_duration, MAX_ZONE_SECONDS)
	var tick := clampf(0.5 / maxf(float(ctx.pulses), 1.0), 0.15, 0.5)
	var follow: Node2D = _player if _player != null and is_instance_valid(_player) else null
	if ctx.can_draw():
		SpellDomain.open(ctx.fx_host, ctx, ctx.origin, ctx.reach, life, maxf(ctx.damage * 0.35, 1.0), {"follow": follow, "tick": tick, "pull": ctx.pull})
	else:
		_field_tick_now(ctx, ctx.origin, ctx.reach, maxf(ctx.damage * 0.35, 1.0))


## Outside the tree there is no frame loop: apply one tick so tests and
## scripted fights still see the field's damage and statuses.
func _field_tick_now(ctx: SpellContext, at: Vector2, radius: float, amount: float) -> void:
	for target in ctx.targets():
		if (target["center"] as Vector2).distance_to(at) <= radius + (target["half"] as Vector2).x:
			ctx.strike_field(target, amount, true)


func _cast_ward(ctx: SpellContext) -> void:
	if _player != null and is_instance_valid(_player):
		var duration := minf(5.0 + ctx.extra_duration, MAX_ZONE_SECONDS)
		_player.grant_shield(maxi(SpellContext.whole(ctx.shield), 6), duration)
	if ctx.knockback <= 0.0:
		ctx.knockback = 2.2
	for target in _in_radius(ctx, ctx.origin, 150.0 * ctx.area_scale):
		ctx.strike(target, ctx.damage * 0.5, ctx.origin)


func _cast_sentinel(ctx: SpellContext) -> void:
	var count := clampi(SpellContext.whole(maxf(ctx.summon, 1.0)), 1, MAX_ECHOES)
	var life := minf(9.0 + ctx.extra_duration, MAX_ZONE_SECONDS)
	var interval := clampf(0.65 / maxf(float(ctx.pulses), 1.0), 0.15, 0.65)
	var bolt_damage := maxf(ctx.damage * 0.5, 3.0)
	if ctx.can_draw():
		for index in count:
			var angle := TAU * float(index) / float(count) - PI * 0.5
			var offset := Vector2.from_angle(angle) * (34.0 if count > 1 else 0.0) + Vector2(-ctx.direction.x * 26.0, -18.0)
			EchoSentinel.create(ctx.fx_host, ctx.origin + offset, bolt_damage, life, ctx, interval, offset)
	else:
		var target := SpellTargets.nearest(ctx.targets(), ctx.origin, 520.0)
		if not target.is_empty():
			ctx.strike(target, bolt_damage * count, ctx.origin)


func _cast_void(ctx: SpellContext) -> void:
	_repeat(ctx, func(_pulse: int) -> void:
		for target in _in_radius(ctx, ctx.origin, ctx.reach * 1.35):
			ctx.strike(target, ctx.damage * 1.7, ctx.origin)
	)
	if _run != null:
		_run.add_corruption(6)


func _cast_missiles(ctx: SpellContext) -> void:
	var base := SpellStyle.base_for(&"missile")
	var count := clampi(SpellContext.whole(ctx.projectiles if ctx.projectiles >= 1.0 else float(base[&"count"])), 1, MAX_BOLTS)
	var arc := ctx.spread if ctx.spread > 0.0 else (0.5 + 0.06 * count)
	arc = clampf(arc, 0.0, TAU)
	var per_bolt := ctx.share(count * ctx.pulses)
	var homing := ctx.homing if ctx.homing > 0.0 else (0.9 if ctx.shape == &"missile" else 0.0)
	var speed := 520.0 if homing > 0.0 else 680.0
	var life := clampf(ctx.reach / speed + 0.35 + (0.6 if homing > 0.0 else 0.0), 0.5, 4.0)
	# Homing volleys split across the crowd instead of all chasing one enemy.
	var spread_targets: Array[Dictionary] = []
	if homing > 0.0:
		for target in ctx.targets():
			if (target["center"] as Vector2).distance_to(ctx.origin) <= ctx.reach + 200.0:
				spread_targets.append(target)
		spread_targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return (a["center"] as Vector2).distance_squared_to(ctx.origin) < (b["center"] as Vector2).distance_squared_to(ctx.origin))
	var headless: Array[SpellBolt] = []
	for wave in ctx.pulses:
		for index in count:
			var t := 0.5 if count == 1 else float(index) / float(count - 1)
			var heading := ctx.direction.rotated((t - 0.5) * arc)
			if homing > 0.0 and count > 1:
				heading = heading.rotated(-ctx.direction.x * 0.35)
			var delay := wave * PULSE_GAP + index * minf(0.02, 0.4 / count)
			var options := {"speed": speed, "lifetime": life, "homing": homing, "chain": mini(ctx.chain, 8), "delay": delay}
			if not spread_targets.is_empty():
				options["seek"] = spread_targets[(index + wave) % spread_targets.size()]
			var muzzle := ctx.origin + heading * projectile_muzzle_offset
			if ctx.can_draw():
				SpellBolt.fire(ctx.fx_host, ctx, muzzle, heading, per_bolt, options)
			else:
				var bolt := SpellBolt.create(ctx, heading, per_bolt, options)
				bolt.global_position = muzzle
				headless.append(bolt)
	if not headless.is_empty():
		_simulate_bolts(headless)


## Headless fallback: fly every bolt in fixed steps so tests see exactly what
## the live game would hit.
func _simulate_bolts(bolts: Array[SpellBolt]) -> void:
	for frame in 300:
		var flying := false
		for bolt in bolts:
			if not bolt.is_done():
				bolt.step(1.0 / 60.0)
				flying = true
		if not flying:
			break
	for bolt in bolts:
		bolt.free()


func _cast_beam(ctx: SpellContext) -> void:
	var count := clampi(SpellContext.whole(ctx.projectiles), 1, 9)
	var arc := clampf(ctx.spread if ctx.spread > 0.0 else 0.4 * (count - 1), 0.0, PI)
	var length := maxf(ctx.reach, 480.0)
	var per_beam := ctx.damage if ctx.per_hit or count <= 3 else ctx.damage * sqrt(3.0 / float(count))
	for index in count:
		var t := 0.5 if count == 1 else float(index) / float(count - 1)
		var heading := ctx.direction.rotated((t - 0.5) * arc)
		if ctx.can_draw():
			SpellBeam.fire(ctx.fx_host, ctx, ctx.origin, heading, length, per_beam, ctx.pulses, ctx.vfx_scale)
		else:
			var beam := SpellBeam.new()
			beam.ctx = ctx
			beam.global_position = ctx.origin
			beam.heading = heading
			beam.length = length
			beam.damage = per_beam
			beam.pulses = ctx.pulses
			for pulse in ctx.pulses:
				beam._sweep()
			beam.free()


func _cast_quake(ctx: SpellContext) -> void:
	var waves := ctx.pulses
	var both_sides := ctx.spread >= PI * 0.75 or ctx.area_scale >= 2.0
	for wave in waves:
		for side in ([1.0, -1.0] if both_sides else [1.0]):
			var facing: float = ctx.direction.x * side
			if ctx.can_draw():
				var node := GroundWave.launch(ctx.fx_host, ctx, ctx.feet + Vector2(facing * 18.0, 2.0), facing, ctx.reach, ctx.damage, ctx.vfx_scale)
				node.delay = wave * PULSE_GAP * 1.4
			else:
				var node := GroundWave.new()
				node.ctx = ctx
				node.direction = facing
				node.reach = ctx.reach
				node.damage = ctx.damage
				node.global_position = ctx.feet + Vector2(facing * 18.0, 2.0)
				while not node.is_finished():
					node.step(0.05)
				node.free()


func _cast_meteors(ctx: SpellContext) -> void:
	var base := SpellStyle.base_for(&"meteor")
	var count := clampi(SpellContext.whole(ctx.projectiles if ctx.projectiles >= 1.0 else float(base[&"count"])) * ctx.pulses, 1, MAX_METEORS)
	var blast := (52.0 + minf(ctx.explosion, 10.0) * 18.0) * minf(ctx.area_scale, 3.0)
	var spots := _meteor_spots(ctx, count)
	var per_star := ctx.damage if ctx.per_hit or count <= 3 else ctx.damage * sqrt(3.0 / float(count))
	for index in spots.size():
		var delay := index * 0.12
		if ctx.can_draw():
			MeteorStrike.drop(ctx.fx_host, ctx, spots[index], per_star, blast, delay, ctx.vfx_scale)
		else:
			var meteor := MeteorStrike.new()
			meteor.ctx = ctx
			meteor.damage = per_star
			meteor.radius = blast
			meteor.global_position = spots[index]
			meteor.step(10.0)
			meteor.free()


## Ground points for falling stars: on enemies in front first, then spread out.
func _meteor_spots(ctx: SpellContext, count: int) -> PackedVector2Array:
	var spots := PackedVector2Array()
	var ground_y := ctx.feet.y
	var ahead: Array[Dictionary] = []
	for target in ctx.targets():
		var offset: Vector2 = (target["center"] as Vector2) - ctx.origin
		if offset.x * ctx.direction.x >= -40.0 and offset.length() <= ctx.reach:
			ahead.append(target)
	ahead.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["center"] as Vector2).distance_squared_to(ctx.origin) < (b["center"] as Vector2).distance_squared_to(ctx.origin))
	for target in ahead:
		if spots.size() >= count:
			break
		var center: Vector2 = target["center"]
		spots.append(Vector2(center.x, center.y + (target["half"] as Vector2).y))
	var step := ctx.reach / maxf(float(count), 1.0)
	var index := 0
	while spots.size() < count:
		spots.append(Vector2(ctx.feet.x + ctx.direction.x * (90.0 + step * index), ground_y))
		index += 1
	return spots


func _apply_self_buffs(ctx: SpellContext, shape: StringName) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var duration := minf(3.0 + ctx.extra_duration, MAX_ZONE_SECONDS)
	if ctx.shield > 0.0 and shape != &"ward":
		_player.grant_shield(SpellContext.whole(ctx.shield), duration)
	if ctx.move_speed > 0.0:
		_player.grant_haste(1.0 + minf(ctx.move_speed, 3.0), duration)


func _in_cone(ctx: SpellContext, reach: float, cos_limit: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for target in ctx.targets():
		var offset: Vector2 = (target["center"] as Vector2) - ctx.origin
		var distance := offset.length()
		if distance > reach + (target["half"] as Vector2).x:
			continue
		if distance < 24.0 or ctx.direction.dot(offset / distance) >= cos_limit:
			result.append(target)
	return result


func _in_radius(ctx: SpellContext, at: Vector2, radius: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for target in ctx.targets():
		if (target["center"] as Vector2).distance_to(at) <= radius + (target["half"] as Vector2).x:
			result.append(target)
	return result


func _nearest_in_front(ctx: SpellContext, reach: float) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := reach
	for target in ctx.targets():
		var offset: Vector2 = (target["center"] as Vector2) - ctx.origin
		if offset.x * ctx.direction.x <= 0.0 or offset.length() > best_distance:
			continue
		best = target
		best_distance = offset.length()
	return best


# --- legacy (phrases without a resolved spell style) --------------------------

func _apply_legacy(phrase: ResolvedPhrase) -> void:
	var components := phrase.components
	var damage := maxf(float(components.get(&"damage", 0.0)), 0.0) * damage_scale
	var slow_amount := maxf(float(components.get(&"slow", 0.0)), 0.0)
	var hit_enemies: Array[Enemy] = []
	if damage > 0.0 or slow_amount > 0.0:
		hit_enemies = _enemies_in_radius(_cast_origin(), _effect_radius(components))

	var damage_dealt := _apply_damage(hit_enemies, damage)
	if slow_amount > 0.0:
		var duration := slow_duration + maxf(float(components.get(&"duration", 0.0)), 0.0)
		StatusEffects.apply_slow(hit_enemies, slow_amount, duration)
	_apply_healing(components, damage_dealt)
	var duration := 3.0 + maxf(float(components.get(&"duration", 0.0)), 0.0)
	if _player != null and is_instance_valid(_player):
		if components.has(&"shield"):
			_player.grant_shield(int(components[&"shield"]), duration)
		if components.has(&"move_speed"):
			_player.grant_haste(1.0 + float(components[&"move_speed"]), duration)
	_apply_ink(components)
	_apply_corruption(phrase, components)
	_spawn_projectile(components)
	# 回声召唤将当前短语化作一道追击墨弹。
	if components.has(&"summon") and not components.has(&"projectile"):
		var echo := components.duplicate()
		echo[&"projectile"] = 1.0
		echo[&"damage"] = maxf(float(components.get(&"damage", 0.0)), 6.0)
		_spawn_projectile(echo)


func _effect_radius(components: Dictionary) -> float:
	var area := maxf(float(components.get(&"area", 0.0)), 0.0)
	return maxf(cast_radius * (1.0 + area), 0.0)


func _apply_damage(enemies: Array[Enemy], damage: float) -> int:
	if damage <= 0.0:
		return 0
	var amount := maxi(int(roundf(damage)), 1)
	var dealt := 0
	for enemy in enemies:
		if enemy.is_dead():
			continue
		var before := enemy.health
		enemy.take_damage(amount)
		dealt += maxi(before - enemy.health, 0)
	return dealt


## Flat heal plus lifesteal. When the spell context already healed per hit,
## pass lifesteal_done so damage is not converted twice.
func _apply_healing(components: Dictionary, damage_dealt: int, lifesteal_done: bool = false) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var flat_heal := SpellContext.number(components, &"heal")
	var lifesteal := 0.0 if lifesteal_done else SpellContext.number(components, &"lifesteal")
	var total := SpellContext.whole(flat_heal + float(damage_dealt) * lifesteal)
	if total > 0:
		_player.heal(total)


func _apply_ink(components: Dictionary) -> void:
	if _run == null:
		return
	var gain := SpellContext.whole(SpellContext.number(components, &"ink_gain"))
	if gain > 0:
		_run.restore_ink(gain)


func _apply_corruption(phrase: ResolvedPhrase, components: Dictionary) -> void:
	if _run == null:
		return
	var component_gain := SpellContext.whole(SpellContext.number(components, &"corruption_gain"))
	# phrase.corruption_gain 已包含组件部分（解析器合并），取较大值避免重复累计。
	var total := maxi(phrase.corruption_gain, component_gain)
	var purify := SpellContext.whole(SpellContext.number(components, &"purify"))
	var mastery := _mastery_power(phrase)
	if purify > 0 and mastery > 0.0:
		purify = maxi(int(round(float(purify) * (1.0 + mastery))), 1)
	if purify > 0:
		total -= purify
	if total > 0:
		_run.add_corruption(total)
	elif total < 0:
		var before := _run.corruption
		_run.add_corruption(total)
		var cleansed := before - _run.corruption
		if cleansed > 0:
			purified.emit(cleansed)


func _spawn_projectile(components: Dictionary) -> void:
	if not components.has(&"projectile"):
		return
	var count := clampi(int(components.get(&"projectiles", 1)), 1, 64)
	var spread := maxf(float(components.get(&"spread", 0.0)), 0.0)
	var base_direction := _cast_direction()
	for index in count:
		var projectile := PROJECTILE_SCENE.instantiate() as Projectile
		if projectile == null:
			continue
		var angle := 0.0
		if count > 1:
			angle = lerpf(-spread * 0.5, spread * 0.5, float(index) / float(count - 1))
		var direction := base_direction.rotated(angle)
		projectile.direction = direction
		projectile.damage = maxi(int(roundf(float(components.get(&"damage", 1.0)) * damage_scale)), 1)
		projectile.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(projectile)
		projectile.global_position = _cast_origin() + Vector2(0, -24) + direction * projectile_muzzle_offset


func _cast_origin() -> Vector2:
	if _player != null and is_instance_valid(_player):
		return _player.global_position
	return Vector2.ZERO


func _cast_direction() -> Vector2:
	if _player != null and is_instance_valid(_player):
		var facing := _player.facing
		if facing.length_squared() > 0.0:
			return facing.normalized()
	return Vector2.RIGHT


func _enemies_in_radius(origin: Vector2, radius: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for enemy in _collect_enemies():
		if enemy.global_position.distance_to(origin) <= radius:
			result.append(enemy)
	return result


func _collect_enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	if _has_enemy_override:
		for enemy in _enemies_override:
			_append_enemy(enemy, result)
		return result
	if _enemy_root != null and is_instance_valid(_enemy_root):
		_collect_from_node(_enemy_root, result)
		return result
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group(&"enemies"):
			if node is Enemy:
				_append_enemy(node as Enemy, result)
	return result


func _collect_from_node(node: Node, result: Array[Enemy]) -> void:
	if node is Enemy:
		_append_enemy(node as Enemy, result)
	for child in node.get_children():
		_collect_from_node(child, result)


func _append_enemy(enemy: Enemy, result: Array[Enemy]) -> void:
	if enemy == null or not is_instance_valid(enemy) or enemy.is_dead():
		return
	result.append(enemy)
