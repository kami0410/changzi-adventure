class_name SpellContext
extends RefCounted

## One cast, from the button press to the last delayed hit: where it started,
## its per-hit payload (damage, burn, slow, stun, knockback, explosion,
## lifesteal) and who it may hit. Bolts, waves, meteors, echoes and domains
## keep a reference, so hits that land seconds later still heal the caster
## and apply the phrase's statuses. Layered shapes run on a fork() so their
## per-shape defaults stay local while damage still tallies on the root.

const BURN_INTERVAL := 0.6
const EXPLOSION_UNIT := 60.0
const KNOCKBACK_UNIT := 120.0
## Physical impulse cap; damage stays uncapped, bodies just stop flying off.
const MAX_KNOCKBACK_SPEED := 1600.0
const _COPY: Array[String] = [
	"player", "run", "target_provider", "feedback", "fx_host", "shape", "origin", "feet",
	"direction", "reach", "extra_duration", "damage", "pulses", "area_scale", "color",
	"secondary", "burn", "burn_ticks", "slow", "slow_duration", "stun", "knockback",
	"explosion", "lifesteal", "pierce", "chain", "homing", "pull", "shield", "heal",
	"move_speed", "summon", "projectiles", "spread", "vfx_scale", "trail", "rings",
	"glyphs", "shake_gain", "freeze", "per_hit",
]

var player: Player
var run: RunState
## Returns Array[Dictionary] of SpellTargets entries.
var target_provider: Callable = Callable()
## Called with (strength, freeze) for camera shake / hit-stop.
var feedback: Callable = Callable()
var fx_host: Node
var root: SpellContext

var shape: StringName = &"blade"
var origin := Vector2.ZERO
var feet := Vector2.ZERO
var direction := Vector2.RIGHT
var reach := 160.0
var extra_duration := 0.0
var damage := 0.0
var pulses := 1
var area_scale := 1.0

var color := Color("79e8d5")
var secondary := Color("f1ddae")
var burn := 0
var burn_ticks := 4
var slow := 0.0
var slow_duration := 2.0
var stun := 0.0
var knockback := 0.0
var explosion := 0.0
var lifesteal := 0.0
var pierce := 0
var chain := 0
var homing := 0.0
var pull := 0.0
var shield := 0.0
var heal := 0.0
var move_speed := 0.0
var summon := 0.0
var projectiles := 0.0
var spread := 0.0
var vfx_scale := 1.0
var trail := 6
var rings := 3
var glyphs := 10
var shake_gain := 1.0
var freeze := 0.0
## True when damage is already per hit (AI intents); volleys then do not divide it.
var per_hit := false

var dealt := 0
var hits := 0
var _heal_carry := 0.0
var _fx_left := 24
var _blasts_left := 8


static func from_phrase(phrase: ResolvedPhrase, base_slow_duration: float) -> SpellContext:
	var ctx := SpellContext.new()
	var c := phrase.components
	var style := phrase.spell
	ctx.color = style.get(&"color", ctx.color)
	var vfx: Dictionary = style.get(&"vfx", {})
	ctx.secondary = vfx.get(&"secondary", ctx.color.lightened(0.45))
	ctx.vfx_scale = clampf(float(vfx.get(&"size", 1.0)), 0.4, 3.0)
	ctx.trail = clampi(int(clampf(float(vfx.get(&"trail", 6)), 0.0, 64.0)), 2, 24)
	ctx.rings = clampi(int(clampf(float(vfx.get(&"rings", 3)), 0.0, 64.0)), 1, 8)
	ctx.glyphs = clampi(int(clampf(float(vfx.get(&"glyphs", 10)), 0.0, 64.0)), 4, 32)
	var feel: Dictionary = style.get(&"feel", {})
	ctx.shake_gain = clampf(float(feel.get(&"screen_shake", 1.0)), 0.0, 2.0)
	ctx.freeze = clampf(float(feel.get(&"hit_stop", 0.0)), 0.0, 0.15)
	ctx.per_hit = bool(style.get(&"per_hit", false))
	ctx.extra_duration = number(c, &"duration")
	ctx.burn = whole(number(c, &"burn"))
	ctx.burn_ticks = maxi(4, int(ceil(minf(ctx.extra_duration, 600.0) / BURN_INTERVAL)))
	ctx.slow = number(c, &"slow")
	ctx.slow_duration = base_slow_duration + ctx.extra_duration
	ctx.stun = number(c, &"stun")
	ctx.knockback = number(c, &"knockback")
	ctx.explosion = number(c, &"explosion")
	ctx.lifesteal = number(c, &"lifesteal")
	ctx.pierce = whole(number(c, &"pierce"))
	ctx.chain = whole(number(c, &"chain"))
	ctx.homing = number(c, &"homing")
	ctx.pull = number(c, &"pull")
	ctx.shield = number(c, &"shield")
	ctx.heal = number(c, &"heal")
	ctx.move_speed = number(c, &"move_speed")
	ctx.summon = number(c, &"summon")
	ctx.projectiles = number(c, &"projectiles")
	ctx.spread = number(c, &"spread")
	return ctx


## A finite, non-negative component value (0 when absent or invalid).
static func number(source: Dictionary, key: StringName) -> float:
	var value := float(source.get(key, 0.0))
	return value if is_finite(value) and value > 0.0 else 0.0


## Rounds a spell number to an int without overflowing on absurd AI values.
static func whole(value: float) -> int:
	return int(roundf(clampf(value, 0.0, 1.0e9)))


## A copy for a layered shape: same payload and targets, own per-shape tweaks.
func fork() -> SpellContext:
	var copy := SpellContext.new()
	for key in _COPY:
		copy.set(key, get(key))
	copy.root = _tally()
	return copy


func targets() -> Array[Dictionary]:
	if target_provider.is_valid():
		return target_provider.call()
	return []


## Damage per entity when one cast releases `count` of them. Lexicon and
## free-text spells spread their damage (more bolts, less each); AI intents
## that already state per-hit damage keep it.
func share(count: int, full_until: int = 1) -> float:
	return share_for(damage, count, per_hit, full_until)


static func share_for(amount: float, count: int, already_per_hit: bool, full_until: int = 1) -> float:
	if already_per_hit or count <= full_until:
		return amount
	if count <= 6:
		return amount * 0.55
	return amount * 0.55 * sqrt(6.0 / float(count))


## Visual budget: one cast may spawn at most this many extra hit sparks, so a
## 96-bolt volley does not flood the screen (enemies still flash and pop numbers).
func fx_allowed() -> bool:
	var tally := _tally()
	if tally._fx_left <= 0:
		return false
	tally._fx_left -= 1
	return true


func explosion_radius() -> float:
	return minf(explosion * EXPLOSION_UNIT, 900.0)


func can_draw() -> bool:
	return fx_host != null and is_instance_valid(fx_host) and fx_host.is_inside_tree()


func total_dealt() -> int:
	return _tally().dealt


func total_hits() -> int:
	return _tally().hits


## Damage one target and apply the phrase's on-hit statuses. Splash from
## explosions never explodes again.
func strike(target: Dictionary, amount: float, from: Vector2, splash: bool = true) -> int:
	var enemy := _enemy_of(target)
	if enemy == null:
		return 0
	var center: Vector2 = target["center"]
	var amount_dealt := _hurt(enemy, amount)
	if SpellTargets.alive(enemy):
		if stun > 0.0:
			enemy.apply_stun(stun)
		if knockback > 0.0:
			var side := signf(center.x - from.x)
			if is_zero_approx(side):
				side = direction.x if not is_zero_approx(direction.x) else 1.0
			var force := minf(knockback, 6.0)
			var speed := minf(KNOCKBACK_UNIT * knockback, MAX_KNOCKBACK_SPEED)
			enemy.apply_knockback(Vector2(side * speed, -45.0 * force), 0.18 + force * 0.04)
	if splash and explosion > 0.0:
		explode(center, amount * 0.6, enemy)
	return amount_dealt


## A tick from a persistent field: damage, burn and slow every tick; stun only
## when the field first touches this enemy; never knockback or explosions.
func strike_field(target: Dictionary, amount: float, first_touch: bool) -> int:
	var enemy := _enemy_of(target)
	if enemy == null:
		return 0
	var amount_dealt := _hurt(enemy, amount)
	if first_touch and stun > 0.0 and SpellTargets.alive(enemy):
		enemy.apply_stun(stun)
	return amount_dealt


## Area damage around a point; the excluded enemy already took the direct hit.
func explode(at: Vector2, amount: float, exclude: Enemy = null) -> int:
	var radius := maxf(explosion_radius(), 24.0)
	var total := 0
	for target in targets():
		var entry = target.get("enemy")
		if not SpellTargets.alive(entry) or entry == exclude:
			continue
		if SpellTargets.overlaps(target, at, radius):
			total += strike(target, amount, at, false)
	if can_draw() and blast_fx_allowed():
		CombatFX.spawn(fx_host, at, &"bomb", color, 1.0, radius)
		CombatFX.spawn(fx_host, at, &"ring", secondary, 1.0, radius * 1.15)
	impact(0.3 + minf(explosion, 4.0) * 0.08)
	return total


## Blast visuals per cast are capped separately from hit sparks: a volley of
## exploding bolts shows a handful of big bursts, the damage still lands on all.
func blast_fx_allowed() -> bool:
	var tally := _tally()
	if tally._blasts_left <= 0:
		return false
	tally._blasts_left -= 1
	return true


func impact(strength: float) -> void:
	if feedback.is_valid():
		feedback.call(strength * shake_gain, freeze)


func _tally() -> SpellContext:
	return root if root != null else self


func _enemy_of(target: Dictionary) -> Enemy:
	if target.is_empty():
		return null
	var entry = target.get("enemy")
	return entry as Enemy if SpellTargets.alive(entry) else null


## Impact sprite per spell shape (assets/vfx). Shapes without an entry keep
## only their drawn SpellVFX. Throttled so a big volley does not stack dozens.
const HIT_FX := {
	&"flame": [&"spell_fire", 0.5],
	&"meteor": [&"spell_fire", 0.7],
	&"chain": [&"spell_lightning", 0.8],
	&"void": [&"spell_shadow", 0.45],
	&"beam": [&"spell_holy", 0.5],
	&"quake": [&"smash", 1.0],
	&"blood": [&"claw", 1.0],
	&"vortex": [&"spell_ice", 0.5],
	&"domain": [&"mana_burst", 0.5],
	&"missile": [&"hit_spark", 1.0],
	&"blade": [&"hit_spark", 1.0],
}
static var _hit_fx_frame := -1
static var _hit_fx_count := 0


func _hit_fx(enemy: Enemy) -> void:
	if not can_draw() or not SpellTargets.alive(enemy):
		return
	var frame := Engine.get_process_frames()
	if frame != _hit_fx_frame:
		_hit_fx_frame = frame
		_hit_fx_count = 0
	if _hit_fx_count >= 3:
		return
	_hit_fx_count += 1
	var entry: Array = HIT_FX.get(shape, [&"hit_spark", 1.0])
	VFX.spawn(fx_host, entry[0], enemy.global_position + Vector2(0, -24), direction.x < 0.0, float(entry[1]))


func _hurt(enemy: Enemy, amount: float) -> int:
	_hit_fx(enemy)
	var amount_dealt := SpellTargets.damage(enemy, amount)
	var tally := _tally()
	tally.dealt = mini(tally.dealt + amount_dealt, 2000000000)
	tally.hits += 1
	_lifesteal(amount_dealt)
	if SpellTargets.alive(enemy):
		if burn > 0:
			BurnStatus.apply(enemy, burn, burn_ticks)
			VFX.attach(enemy, &"status_burning", 0.5 * float(maxi(burn_ticks, 1)), Vector2(0, 10))
		if slow > 0.0:
			enemy.apply_slow(StatusEffects.slow_multiplier(slow), slow_duration)
			VFX.attach(enemy, &"status_slowed", slow_duration, Vector2(0, -70))
	return amount_dealt


func _lifesteal(amount_dealt: int) -> void:
	if lifesteal <= 0.0 or amount_dealt <= 0:
		return
	if player == null or not is_instance_valid(player):
		return
	_heal_carry += float(amount_dealt) * lifesteal
	var gained := int(floorf(minf(_heal_carry, 1.0e9)))
	if gained > 0:
		_heal_carry -= gained
		player.heal(gained)
