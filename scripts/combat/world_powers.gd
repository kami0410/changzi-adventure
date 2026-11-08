class_name WorldPowers
extends RefCounted

## 言灵权能（1.0）：言出法随不只是伤害数字，一句话可以直接改写这一刻的世界。
## AI 意图与离线推演都可以给出下列组件，数值不设上限，全部真实生效；
## 代价仍由墨耗、冷却与污染承担。
##
## - time_stop  秒：场上所有敌人定格（Boss 按血量缩短），敌方弹幕凝固后消散
## - execute    0–1：抹去生命低于该比例的普通敌人；Boss 失去该比例 × 25% 的最大生命
## - charm      个数：改写最近的若干普通敌人的名字，让它们为你而战，名字燃尽后倒下
## - blink      像素：朝面向瞬移，穿不过墙
## - invulnerable 秒：无敌
## - terrain    级数：在前方铺出一段向上的墨阶（临时单向平台）
## - reveal     >0：揭开本章地图（所有区域、隐藏书库）
## - unlock     >0：解除当前房间的封锁与捷径屏障
## - conjure    残页数：凭空写出残页
##
## 需要关卡上下文的权能（reveal / unlock / conjure）由 PhraseCaster 发出
## world_power_requested，交给 game.gd 落地。

const KEYS: Array[StringName] = [
	&"time_stop", &"execute", &"charm", &"blink", &"invulnerable",
	&"terrain", &"reveal", &"unlock", &"conjure",
]
const LABELS := {
	&"time_stop": "时停", &"execute": "处决线", &"charm": "改写敌名", &"blink": "瞬移",
	&"invulnerable": "无敌", &"terrain": "墨阶", &"reveal": "揭图", &"unlock": "破封",
	&"conjure": "写出残页",
}
## Entity limits only (frame budget); the strength of each power is uncapped.
const MAX_CHARMED := 8
const MAX_STEPS := 12
const STEP_SIZE := Vector2(112, 16)
const STEP_RISE := 64.0
const STEP_RUN := 120.0
const TERRAIN_SECONDS := 9.0
const CHARM_SECONDS := 10.0
const BLINK_STEP := 16.0

## Game-level powers handed to game.gd.
const GAME_POWERS: Array[StringName] = [&"reveal", &"unlock", &"conjure"]


static func has_any(components: Dictionary) -> bool:
	for key in KEYS:
		if float(components.get(key, 0.0)) > 0.0:
			return true
	return false


## Applies every world power in [param components]. [param emit_game] receives
## (power, amount) for the powers that need the level. Returns the applied keys.
static func apply(ctx: SpellContext, components: Dictionary, targets: Array[Dictionary], emit_game: Callable) -> Array[StringName]:
	var applied: Array[StringName] = []
	var extra := maxf(ctx.extra_duration, 0.0)
	var stop := SpellContext.number(components, &"time_stop")
	if stop > 0.0:
		time_stop(ctx, targets, stop + extra * 0.5)
		applied.append(&"time_stop")
	var execute_line := SpellContext.number(components, &"execute")
	if execute_line > 0.0:
		execute(ctx, targets, execute_line)
		applied.append(&"execute")
	var charm_count := SpellContext.number(components, &"charm")
	if charm_count > 0.0:
		charm(ctx, targets, SpellContext.whole(charm_count), CHARM_SECONDS + extra)
		applied.append(&"charm")
	var invulnerable := SpellContext.number(components, &"invulnerable")
	if invulnerable > 0.0 and _player_ok(ctx):
		ctx.player.grant_invulnerability(invulnerable + extra * 0.25)
		applied.append(&"invulnerable")
	var blink_distance := SpellContext.number(components, &"blink")
	if blink_distance > 0.0 and _player_ok(ctx):
		blink(ctx, blink_distance)
		applied.append(&"blink")
	var steps := SpellContext.number(components, &"terrain")
	if steps > 0.0:
		terrain(ctx, clampi(SpellContext.whole(steps), 1, MAX_STEPS), TERRAIN_SECONDS + extra)
		applied.append(&"terrain")
	for key in GAME_POWERS:
		var amount := SpellContext.number(components, key)
		if amount > 0.0:
			if emit_game.is_valid():
				emit_game.call(key, amount)
			applied.append(key)
	return applied


static func _player_ok(ctx: SpellContext) -> bool:
	return ctx.player != null and is_instance_valid(ctx.player)


static func _enemies(targets: Array[Dictionary]) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for entry in targets:
		var enemy := entry.get("enemy") as Enemy
		if enemy != null and is_instance_valid(enemy) and not enemy.dead:
			out.append(enemy)
	return out


static func is_boss(enemy: Enemy) -> bool:
	return enemy is InkArchivist


static func time_stop(ctx: SpellContext, targets: Array[Dictionary], seconds: float) -> void:
	for enemy in _enemies(targets):
		if enemy.is_charmed():
			continue
		enemy.apply_stun(seconds)
		enemy.velocity = Vector2.ZERO
	if ctx.fx_host != null and is_instance_valid(ctx.fx_host) and ctx.fx_host.is_inside_tree():
		# Frozen shots crumble; pools, warnings and boss rings stay.
		for hazard in ctx.fx_host.get_tree().get_nodes_in_group(&"hostile_hazards"):
			if hazard is HostileBolt:
				(hazard as Node).queue_free()
		CombatFX.spawn(ctx.fx_host, ctx.origin, &"shockwave", Color("c9e9ff"), ctx.direction.x, 520.0)
		VFX.spawn(ctx.fx_host, &"spell_ice", ctx.origin, false, 1.6)


static func execute(ctx: SpellContext, targets: Array[Dictionary], line: float) -> void:
	for enemy in _enemies(targets):
		if enemy.is_charmed():
			continue
		if is_boss(enemy):
			enemy.take_damage(maxi(int(roundf(float(enemy.max_health) * minf(line, 4.0) * 0.25)), 1))
		elif float(enemy.health) <= float(enemy.max_health) * line:
			enemy.take_damage(enemy.health)
			if ctx.can_draw():
				VFX.spawn(ctx.fx_host, &"hit_crit", enemy.global_position + Vector2(0, -30), false, 1.2)


static func charm(ctx: SpellContext, targets: Array[Dictionary], count: int, seconds: float) -> int:
	var candidates: Array[Enemy] = []
	for enemy in _enemies(targets):
		if not is_boss(enemy) and not enemy.is_charmed():
			candidates.append(enemy)
	candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return a.global_position.distance_squared_to(ctx.feet) < b.global_position.distance_squared_to(ctx.feet))
	var done := 0
	for enemy in candidates:
		if done >= mini(count, MAX_CHARMED):
			break
		enemy.charm(seconds)
		done += 1
		if ctx.can_draw():
			VFX.spawn(ctx.fx_host, &"spell_holy", enemy.global_position + Vector2(0, -30), false, 0.8)
	return done


static func blink(ctx: SpellContext, distance: float) -> void:
	var player := ctx.player
	var direction := Vector2(signf(ctx.direction.x) if ctx.direction.x != 0.0 else 1.0, 0.0)
	var start := player.global_position
	var travelled := 0.0
	var budget := minf(distance, 4000.0)
	if player.is_inside_tree():
		while travelled + BLINK_STEP <= budget:
			if player.test_move(player.global_transform, direction * BLINK_STEP):
				break
			player.global_position += direction * BLINK_STEP
			travelled += BLINK_STEP
	else:
		player.global_position += direction * budget
	player.grant_invulnerability(0.35)
	if ctx.can_draw():
		VFX.spawn(ctx.fx_host, &"parry", start + Vector2(0, -30), direction.x < 0.0, 1.0)
		VFX.spawn(ctx.fx_host, &"parry", player.global_position + Vector2(0, -30), direction.x < 0.0, 1.0)


## Rising ink steps ahead of the caster: temporary one-way platforms that fade
## away. Placed in the caster's world (the room), never saved.
static func terrain(ctx: SpellContext, steps: int, seconds: float) -> Array[Node]:
	var made: Array[Node] = []
	var host := ctx.fx_host
	if host == null or not is_instance_valid(host):
		return made
	var side := signf(ctx.direction.x) if ctx.direction.x != 0.0 else 1.0
	for i in steps:
		var platform := OneWayPlatform.new()
		platform.name = "InkStep_%d" % i
		platform.size = STEP_SIZE
		platform.color = Color("1b2a33")
		platform.edge_color = Color("8fe8dc")
		var x := ctx.feet.x + side * (60.0 + i * STEP_RUN) - (STEP_SIZE.x if side < 0.0 else 0.0)
		platform.position = Vector2(x, ctx.feet.y - STEP_RISE * (i + 1))
		platform.set_meta(&"ink_step", true)
		host.add_child(platform)
		made.append(platform)
		if platform.is_inside_tree():
			var fade := platform.create_tween()
			fade.tween_interval(maxf(seconds - 1.0, 0.5) + i * 0.08)
			fade.tween_property(platform, "modulate:a", 0.0, 1.0)
			fade.tween_callback(platform.queue_free)
	if ctx.can_draw():
		CombatFX.spawn(host, ctx.feet, &"cast", Color("8fe8dc"), side, 120.0)
	return made
