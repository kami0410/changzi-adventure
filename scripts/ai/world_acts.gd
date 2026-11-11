class_name WorldActs
extends Node

## 言灵世界改写 (1.1): the vocabulary a sentence — read offline or by the AI —
## uses to change the run beyond a spell's numbers.
##
## An *act* is one small, concrete change: `{"do": "shrink", "target": "all",
## "scale": 0.5, "seconds": 10}`. A sentence carries a list of acts that happen
## when it is cast, and a list of *rules*: `{"when": "on_kill", "do": [acts],
## "seconds": 20}` keeps firing its acts whenever the trigger happens. Acts are
## building blocks, so the AI can compose effects no menu lists.
##
## Like the spell components, strength is not capped: the price is the ink,
## cooldown and corruption the sentence carries. Only the number of things
## created at once is limited (frame budget), and everything from outside is
## treated as data: unknown verbs and keys are dropped, numbers must be finite.
##
## The node lives in the run scene. It talks to the game through the Callables
## below, so the rules can be tested without the whole scene.

signal acted(act: Dictionary)
signal rule_started(rule: Dictionary)
signal rule_fired(rule: Dictionary)

## verb -> default parameters. The type of each default is the type accepted.
const ACTS := {
	# --- enemies ---
	&"damage": {"amount": 20.0, "target": "all", "count": 0.0},
	&"stun": {"seconds": 2.0, "target": "all", "count": 0.0},
	&"slow": {"amount": 0.5, "seconds": 6.0, "target": "all", "count": 0.0},
	&"shrink": {"scale": 0.5, "seconds": 10.0, "target": "all", "count": 0.0},
	&"grow": {"scale": 1.6, "seconds": 10.0, "target": "all", "count": 0.0},
	&"weaken": {"amount": 0.5, "seconds": 10.0, "target": "all", "count": 0.0},
	&"disarm": {"seconds": 6.0, "target": "all", "count": 0.0},
	&"infight": {"seconds": 10.0, "target": "nearest", "count": 2.0},
	&"kill": {"target": "nearest", "count": 1.0},
	&"knockback": {"force": 3.0, "target": "all", "count": 0.0},
	&"pull": {"force": 3.0, "target": "all", "count": 0.0},
	&"launch": {"force": 3.0, "target": "all", "count": 0.0},
	&"transform": {"into": "scribe_bug", "target": "nearest", "count": 1.0},
	&"summon": {"id": "ink_hound", "count": 2.0, "seconds": 20.0, "hostile": 0.0},
	&"dispel": {},
	# --- the caster ---
	&"heal": {"amount": 20.0},
	&"shield": {"amount": 20.0, "seconds": 8.0},
	&"ink": {"amount": 20.0},
	&"pages": {"amount": 5.0},
	&"purify": {"amount": 10.0},
	&"corrupt": {"amount": 10.0},
	&"invulnerable": {"seconds": 3.0},
	&"haste": {"amount": 1.5, "seconds": 8.0},
	&"jump": {"amount": 1.5, "seconds": 12.0},
	&"air_jumps": {"count": 3.0, "seconds": 15.0},
	&"resize_self": {"scale": 1.5, "seconds": 10.0},
	&"teleport": {"to": "forward", "distance": 300.0},
	&"power": {"amount": 2.0, "seconds": 10.0},
	&"armor": {"amount": 0.5, "seconds": 10.0},
	&"cooldown": {"amount": 0.5, "seconds": 10.0},
	&"free_cast": {"seconds": 6.0},
	# --- the room and the run ---
	&"gravity": {"amount": 0.4, "seconds": 10.0},
	&"time_scale": {"amount": 0.5, "seconds": 5.0},
	&"darkness": {"amount": 0.6, "seconds": 10.0},
	&"tint": {"color": "#8fe8dc", "seconds": 8.0},
	&"platforms": {"count": 4.0, "pattern": "stairs", "seconds": 10.0},
	&"wall": {"seconds": 8.0, "height": 160.0},
	&"unlock": {},
	&"reveal": {},
	&"say": {"text": "", "who": "narrator"},
	&"mutator": {"key": "damage_dealt", "amount": 1.5, "seconds": 0.0},
	&"relic": {"name": "", "description": "", "mods": {}, "rules": []},
	&"weapon": {"name": "", "damage": 20.0, "cooldown": 0.4, "range": 70.0, "kind": "melee"},
}
const TARGETS: Array[String] = ["all", "nearest", "farthest", "random", "boss", "weakest", "strongest"]
const TELEPORTS: Array[String] = ["forward", "back", "up", "enemy", "boss", "behind_boss"]
const PATTERNS: Array[String] = ["stairs", "bridge", "tower"]
const SPEAKERS: Array[String] = ["narrator", "boss", "enemy", "changzi"]
const WEAPON_KINDS: Array[String] = ["melee", "ranged"]
## Run-wide multipliers a `mutator` act (or a relic's `mods`) may set.
const MODIFIERS := {
	&"damage_dealt": "造成伤害", &"damage_taken": "受到伤害", &"cooldown": "言灵冷却",
	&"ink_cost": "墨耗", &"corruption_gain": "污染增长", &"kill_ink": "击杀回墨",
	&"kill_pages": "击杀残页", &"enemy_speed": "敌人速度", &"enemy_damage": "敌人伤害",
	&"player_speed": "移动速度", &"gravity": "重力",
}
const TRIGGERS := {
	&"on_kill": "每击杀一个敌人", &"on_hit": "每次武器命中", &"on_hurt": "每次受伤",
	&"on_dodge": "每次完美闪避", &"on_cast": "每次施放言灵", &"on_jump": "每次起跳",
	&"every": "每隔一段时间", &"on_low_health": "生命垂危时", &"on_room_clear": "肃清房间时",
}

## Frame-budget limits (how many things exist), never how strong they are.
const MAX_ACTS := 12
const MAX_RULES := 12
const MAX_SUMMONS := 8
const MAX_TARGETS := 24
const MAX_PLATFORMS := 12
const MAX_NESTING := 2
const MIN_RULE_GAP := 0.15
const DEFAULT_RULE_SECONDS := 20.0
const LOW_HEALTH := 0.3
const KNOCK_UNIT := 180.0

# --- wiring (set by the run scene) -----------------------------------------
var player: Player
var run: RunState
## Where platforms, walls and effects are added (the scene the player is in).
var host: Node
## () -> Array of live Enemy nodes the sentence can reach.
var targets: Callable
## (text: String) -> void: a line on the HUD.
var notify: Callable
## (id: StringName, at: Vector2, hostile: bool) -> Enemy: spawns a fully
## dressed enemy; a hostile one joins the fight the caster is in.
var spawner: Callable
## (power: StringName, amount: float) -> void: reveal / unlock.
var game_power: Callable
## (weapon: WeaponData, at: Vector2) -> void
var weapon_dropper: Callable
## (relic: RelicData) -> bool
var relic_giver: Callable
## Enemy ids `transform` and `summon` accept (filled from the game's roster).
var enemy_ids: Array[StringName] = []
## "melee" / "ranged" -> WeaponData a written weapon is modelled on, so it
## swings, shoots and saves like the weapons the game ships.
var weapon_bases: Dictionary = {}

var rules: Array[Dictionary] = []
var _mods: Dictionary = {}
var _overrides: Array[Dictionary] = []
var _summoned: Array[Enemy] = []
## Acts of the relics written this run (saved with the run).
var _relic_acts: Array[Dictionary] = []
var _arming_relic := false
var _loading := false
var _was_low := false
var _tint_layer: CanvasModulate
var _dark_layer: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


# === validation (static: used by AIService, the grimoire and tests) ==========

## Cleans a list of acts from outside: unknown verbs and keys are dropped,
## numbers must be finite and non-negative, strings come from fixed lists or
## are stripped of markup.
static func sanitize(raw: Variant, depth: int = 0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not raw is Array:
		return out
	for entry in raw:
		if out.size() >= MAX_ACTS:
			break
		if not entry is Dictionary:
			continue
		var verb := StringName(String((entry as Dictionary).get("do", "")))
		if not ACTS.has(verb):
			continue
		var spec: Dictionary = ACTS[verb]
		var act := {"do": String(verb)}
		for key in spec:
			var fallback: Variant = spec[key]
			var value: Variant = (entry as Dictionary).get(key, fallback)
			if fallback is float:
				act[key] = _number(value, float(fallback))
			elif fallback is String:
				act[key] = _word(String(key), value, String(fallback))
			elif fallback is Dictionary:
				act[key] = sanitize_mods(value)
			elif fallback is Array:
				act[key] = sanitize_rules(value, depth + 1) if depth < MAX_NESTING else []
		out.append(act)
	return out


static func sanitize_rules(raw: Variant, depth: int = 0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not raw is Array:
		return out
	for entry in raw:
		if out.size() >= MAX_RULES:
			break
		if not entry is Dictionary:
			continue
		var source := entry as Dictionary
		var when := StringName(String(source.get("when", "")))
		if not TRIGGERS.has(when):
			continue
		var acts := sanitize(source.get("do", []), depth + 1)
		if acts.is_empty():
			continue
		out.append({
			"when": String(when),
			"do": acts,
			# 0 seconds = until the run ends.
			"seconds": _number(source.get("seconds", DEFAULT_RULE_SECONDS), DEFAULT_RULE_SECONDS),
			# 0 times = no limit.
			"times": _number(source.get("times", 0.0), 0.0),
			"interval": maxf(_number(source.get("interval", 1.0), 1.0), MIN_RULE_GAP),
			"name": _text(source.get("name", ""), 24),
		})
	return out


static func sanitize_mods(raw: Variant) -> Dictionary:
	var out := {}
	if raw is Dictionary:
		for key in raw:
			if MODIFIERS.has(StringName(String(key))):
				out[String(key)] = _number((raw as Dictionary)[key], 1.0)
	return out


static func _number(value: Variant, fallback: float) -> float:
	if not (value is float or value is int or value is String or value is bool):
		return fallback
	var number := float(value)
	if not is_finite(number) or number < 0.0:
		return fallback
	return number


static func _word(key: String, value: Variant, fallback: String) -> String:
	var text := String(value) if (value is String or value is StringName) else fallback
	match key:
		"target":
			return text if TARGETS.has(text) else fallback
		"to":
			return text if TELEPORTS.has(text) else fallback
		"pattern":
			return text if PATTERNS.has(text) else fallback
		"who":
			return text if SPEAKERS.has(text) else fallback
		"kind":
			return text if WEAPON_KINDS.has(text) else fallback
		"key":
			return text if MODIFIERS.has(StringName(text)) else fallback
		"color":
			return text if text.begins_with("#") and Color.html_is_valid(text) else fallback
		"id", "into":
			# The roster is checked when the act runs; here only the shape.
			return text if text.is_valid_identifier() and text.length() <= 32 else fallback
		"text":
			return _text(text, 80)
		"name":
			return _text(text, 16)
		"description":
			return _text(text, 80)
	return _text(text, 40)


static func _text(value: Variant, limit: int) -> String:
	var text := String(value) if (value is String or value is StringName) else ""
	text = text.strip_edges().replace("<", "").replace(">", "")
	text = text.replace("http://", "").replace("https://", "")
	return text.substr(0, limit).strip_edges()


# === description (preview in the codex, HUD lines) ===========================

static func describe(act: Dictionary) -> String:
	var verb := String(act.get("do", ""))
	var seconds := _seconds_text(float(act.get("seconds", 0.0)))
	var who := _target_text(act)
	match verb:
		"damage": return "%s受到 %d 伤害" % [who, int(act["amount"])]
		"stun": return "%s定身%s" % [who, seconds]
		"slow": return "%s减速 %d%%%s" % [who, int(float(act["amount"]) * 100.0), seconds]
		"shrink", "grow": return "%s变为 %d%% 大小%s" % [who, int(float(act["scale"]) * 100.0), seconds]
		"weaken": return "%s的伤害变为 %d%%%s" % [who, int(float(act["amount"]) * 100.0), seconds]
		"disarm": return "%s被缴械%s" % [who, seconds]
		"infight": return "%s为你而战%s" % [who, seconds]
		"kill": return "%s被抹去" % who
		"knockback": return "%s被震开" % who
		"pull": return "%s被拉到你面前" % who
		"launch": return "%s被抛向空中" % who
		"transform": return "%s变成「%s」" % [who, act["into"]]
		"summon":
			return "召来 %d 个「%s」%s" % [int(act["count"]), act["id"],
				"与你为敌" if float(act["hostile"]) > 0.0 else "为你而战" + seconds]
		"dispel": return "驱散场上所有敌方弹幕"
		"heal": return "恢复 %d 生命" % int(act["amount"])
		"shield": return "获得 %d 护盾%s" % [int(act["amount"]), seconds]
		"ink": return "恢复 %d 墨量" % int(act["amount"])
		"pages": return "写出 %d 张残页" % int(act["amount"])
		"purify": return "净化 %d 污染" % int(act["amount"])
		"corrupt": return "污染 +%d" % int(act["amount"])
		"invulnerable": return "无敌%s" % seconds
		"haste": return "移动速度 ×%.1f%s" % [float(act["amount"]), seconds]
		"jump": return "跳跃力 ×%.1f%s" % [float(act["amount"]), seconds]
		"air_jumps": return "空中可再跳 %d 次%s" % [int(act["count"]), seconds]
		"resize_self": return "自身变为 %d%% 大小%s" % [int(float(act["scale"]) * 100.0), seconds]
		"teleport": return "瞬移：%s" % {"forward": "向前", "back": "向后", "up": "向上", "enemy": "到最近的敌人身边",
			"boss": "到 Boss 面前", "behind_boss": "到 Boss 背后"}.get(act["to"], "向前")
		"power": return "造成伤害 ×%.1f%s" % [float(act["amount"]), seconds]
		"armor": return "受到伤害 ×%.1f%s" % [float(act["amount"]), seconds]
		"cooldown": return "言灵冷却 ×%.1f%s" % [float(act["amount"]), seconds]
		"free_cast": return "言灵不耗墨%s" % seconds
		"gravity": return "重力 ×%.1f%s" % [float(act["amount"]), seconds]
		"time_scale": return "世界流速 ×%.1f%s" % [float(act["amount"]), seconds]
		"darkness": return "黑暗降临%s" % seconds
		"tint": return "世界染色%s" % seconds
		"platforms": return "写出 %d 级%s%s" % [int(act["count"]), {"stairs": "墨阶", "bridge": "墨桥", "tower": "墨塔"}.get(act["pattern"], "墨阶"), seconds]
		"wall": return "立起一面墨墙%s" % seconds
		"unlock": return "解除封锁"
		"reveal": return "揭开本章地图"
		"say": return "「%s」" % act["text"]
		"mutator":
			return "本局规则：%s ×%.2f%s" % [MODIFIERS.get(StringName(String(act["key"])), act["key"]),
				float(act["amount"]), seconds if float(act["seconds"]) > 0.0 else "（直到本局结束）"]
		"relic": return "写出遗物「%s」" % act["name"]
		"weapon": return "写出武器「%s」（伤害 %d）" % [act["name"], int(act["damage"])]
	return verb


static func describe_rule(rule: Dictionary) -> String:
	var parts: Array[String] = []
	for act in rule.get("do", []):
		parts.append(describe(act))
	var when := String(TRIGGERS.get(StringName(String(rule.get("when", ""))), "当"))
	if String(rule.get("when", "")) == "every":
		when = "每 %.1f 秒" % float(rule.get("interval", 1.0))
	var seconds := float(rule.get("seconds", 0.0))
	var span := "接下来 %d 秒内，" % int(seconds) if seconds > 0.0 else "本局之内，"
	return "%s%s：%s" % [span, when, "；".join(parts)]


## Every act and rule of a sentence as readable lines (codex preview).
static func describe_all(acts: Array, rule_list: Array) -> Array[String]:
	var lines: Array[String] = []
	for act in acts:
		lines.append(describe(act))
	for rule in rule_list:
		lines.append(describe_rule(rule))
	return lines


static func _seconds_text(seconds: float) -> String:
	return " %d 秒" % int(roundf(seconds)) if seconds >= 1.0 else ""


static func _target_text(act: Dictionary) -> String:
	if not act.has("target"):
		return ""
	var count := int(float(act.get("count", 0.0)))
	match String(act["target"]):
		"nearest": return "最近的 %d 个敌人" % maxi(count, 1)
		"farthest": return "最远的 %d 个敌人" % maxi(count, 1)
		"random": return "随机 %d 个敌人" % maxi(count, 1)
		"weakest": return "最虚弱的 %d 个敌人" % maxi(count, 1)
		"strongest": return "最强的 %d 个敌人" % maxi(count, 1)
		"boss": return "Boss "
	return "所有敌人" if count <= 0 else "%d 个敌人" % count


# === run-wide modifiers ======================================================

## Product of every live modifier for [param key] (1.0 when none).
func modifier(key: StringName) -> float:
	var value := 1.0
	for entry in _mods.get(key, []):
		value *= float(entry["value"])
	return value


func add_modifier(key: StringName, value: float, seconds: float) -> void:
	if not MODIFIERS.has(key):
		return
	if not _mods.has(key):
		_mods[key] = []
	# 0 seconds = for the rest of the run.
	(_mods[key] as Array).append({"value": value, "left": seconds if seconds > 0.0 else INF,
		"relic": _arming_relic})


## Every modifier that differs from 1, for the HUD and the save.
func active_modifiers() -> Dictionary:
	var out := {}
	for key in _mods:
		var value := modifier(key)
		if not is_equal_approx(value, 1.0):
			out[key] = value
	return out


# === running acts ============================================================

## Performs a sentence: its acts now, its rules from now on.
func perform(acts: Array, rule_list: Array = []) -> void:
	for act in acts:
		if act is Dictionary:
			apply(act)
	for rule in rule_list:
		if rule is Dictionary:
			add_rule(rule)


func add_rule(rule: Dictionary) -> bool:
	if rules.size() >= MAX_RULES:
		# The oldest rule makes room: a new sentence always takes effect.
		rules.pop_front()
	var live := rule.duplicate(true)
	var seconds := float(live.get("seconds", DEFAULT_RULE_SECONDS))
	live["left"] = seconds if seconds > 0.0 else INF
	live["fired"] = 0
	live["gap"] = 0.0
	live["clock"] = 0.0
	live["relic"] = _arming_relic
	rules.append(live)
	rule_started.emit(live)
	if notify.is_valid() and not _loading and not _arming_relic:
		notify.call("言出法随：" + describe_rule(live))
	return true


## Something happened that rules may be waiting for.
func trigger(when: StringName) -> void:
	for rule in rules.duplicate():
		if StringName(String(rule["when"])) != when or float(rule["gap"]) > 0.0:
			continue
		_fire(rule)


func _fire(rule: Dictionary) -> void:
	rule["gap"] = MIN_RULE_GAP
	rule["fired"] = int(rule["fired"]) + 1
	for act in rule["do"]:
		apply(act, true)
	rule_fired.emit(rule)
	var times := int(float(rule.get("times", 0.0)))
	if times > 0 and int(rule["fired"]) >= times:
		rules.erase(rule)


func _process(delta: float) -> void:
	_tick_rules(delta)
	_tick_mods(delta)
	_tick_overrides(delta)
	if player != null and is_instance_valid(player) and player.max_health > 0:
		var low := float(player.health) / float(player.max_health) <= LOW_HEALTH and player.health > 0
		if low and not _was_low:
			trigger(&"on_low_health")
		_was_low = low


func _tick_rules(delta: float) -> void:
	for rule in rules.duplicate():
		rule["gap"] = maxf(float(rule["gap"]) - delta, 0.0)
		rule["left"] = float(rule["left"]) - delta
		if float(rule["left"]) <= 0.0:
			rules.erase(rule)
			continue
		if String(rule["when"]) == "every":
			rule["clock"] = float(rule["clock"]) + delta
			if float(rule["clock"]) >= float(rule["interval"]):
				rule["clock"] = 0.0
				_fire(rule)


func _tick_mods(delta: float) -> void:
	for key in _mods.keys():
		var list: Array = _mods[key]
		for entry in list.duplicate():
			entry["left"] = float(entry["left"]) - delta
			if float(entry["left"]) <= 0.0:
				list.erase(entry)
		if list.is_empty():
			_mods.erase(key)


## Applies one act. [param quiet] skips the HUD line (rule firings).
func apply(act: Dictionary, quiet: bool = false) -> void:
	var verb := String(act.get("do", ""))
	if not ACTS.has(StringName(verb)):
		return
	match verb:
		"damage", "stun", "slow", "shrink", "grow", "weaken", "disarm", "kill", \
		"knockback", "pull", "launch":
			for enemy in _pick(act):
				_touch_enemy(enemy, verb, act)
		"infight":
			for enemy in _pick(act):
				if not _is_boss(enemy):
					enemy.charm(float(act["seconds"]))
		"transform":
			_transform(act)
		"summon":
			_summon(act)
		"dispel":
			_dispel()
		"heal":
			if _player_ok():
				player.heal(int(act["amount"]))
		"shield":
			if _player_ok():
				player.grant_shield(int(act["amount"]), float(act["seconds"]))
		"ink":
			if run != null:
				run.restore_ink(int(act["amount"]))
		"pages":
			if run != null:
				run.add_pages(int(act["amount"]))
		"purify":
			if run != null:
				run.add_corruption(-int(act["amount"]))
		"corrupt":
			if run != null:
				run.add_corruption(int(act["amount"]))
		"invulnerable":
			if _player_ok():
				player.grant_invulnerability(float(act["seconds"]))
		"haste":
			if _player_ok():
				player.grant_haste(float(act["amount"]), float(act["seconds"]))
		"jump":
			if _player_ok():
				_override(player, &"jump_velocity", player.jump_velocity * float(act["amount"]), float(act["seconds"]))
				_override(player, &"double_jump_velocity", player.double_jump_velocity * float(act["amount"]), float(act["seconds"]))
		"air_jumps":
			if _player_ok():
				_override(player, &"air_jumps", int(act["count"]), float(act["seconds"]))
				player._air_jumps_left = int(act["count"])
		"resize_self":
			if _player_ok():
				var factor := clampf(float(act["scale"]), 0.3, 3.0)
				_override(player, &"scale", Vector2.ONE * factor, float(act["seconds"]))
				# Bigger hits harder and is hit harder; smaller is the reverse.
				add_modifier(&"damage_dealt", factor, float(act["seconds"]))
		"teleport":
			_teleport(act)
		"power":
			add_modifier(&"damage_dealt", float(act["amount"]), float(act["seconds"]))
		"armor":
			add_modifier(&"damage_taken", float(act["amount"]), float(act["seconds"]))
		"cooldown":
			add_modifier(&"cooldown", float(act["amount"]), float(act["seconds"]))
		"free_cast":
			add_modifier(&"ink_cost", 0.0, float(act["seconds"]))
		"gravity":
			_gravity(float(act["amount"]), float(act["seconds"]))
		"time_scale":
			_time_scale(float(act["amount"]), float(act["seconds"]))
		"darkness":
			_darkness(float(act["amount"]), float(act["seconds"]))
		"tint":
			_tint(Color.from_string(String(act["color"]), Color.WHITE), float(act["seconds"]))
		"platforms":
			_platforms(act)
		"wall":
			_wall(act)
		"unlock", "reveal":
			if game_power.is_valid():
				game_power.call(StringName(verb), 1.0)
		"say":
			if notify.is_valid() and not String(act["text"]).is_empty():
				notify.call(_speaker_prefix(String(act["who"])) + String(act["text"]))
		"mutator":
			if String(act["key"]) == "gravity":
				_gravity(float(act["amount"]), float(act["seconds"]))
			else:
				add_modifier(StringName(String(act["key"])), float(act["amount"]), float(act["seconds"]))
		"relic":
			_make_relic(act)
		"weapon":
			_make_weapon(act)
	acted.emit(act)
	if not quiet and notify.is_valid() and verb != "say":
		notify.call("言出法随：" + describe(act))


# --- enemies -----------------------------------------------------------------

func _live_enemies() -> Array[Enemy]:
	var out: Array[Enemy] = []
	if not targets.is_valid():
		return out
	for entry in targets.call():
		var enemy := entry as Enemy
		if enemy != null and is_instance_valid(enemy) and not enemy.dead and not enemy.is_charmed():
			out.append(enemy)
	return out


static func _is_boss(enemy: Enemy) -> bool:
	return enemy is InkArchivist


static func _bosses(pool: Array[Enemy]) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for enemy in pool:
		if _is_boss(enemy):
			out.append(enemy)
	return out


func _pick(act: Dictionary) -> Array[Enemy]:
	var pool := _live_enemies()
	var count := int(float(act.get("count", 0.0)))
	var origin := player.global_position if _player_ok() else Vector2.ZERO
	match String(act.get("target", "all")):
		"boss":
			return _bosses(pool)
		"nearest":
			pool.sort_custom(func(a: Enemy, b: Enemy) -> bool:
				return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin))
			count = maxi(count, 1)
		"farthest":
			pool.sort_custom(func(a: Enemy, b: Enemy) -> bool:
				return a.global_position.distance_squared_to(origin) > b.global_position.distance_squared_to(origin))
			count = maxi(count, 1)
		"weakest":
			pool.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.health < b.health)
			count = maxi(count, 1)
		"strongest":
			pool.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.health > b.health)
			count = maxi(count, 1)
		"random":
			pool.shuffle()
			count = maxi(count, 1)
	var limit := MAX_TARGETS if count <= 0 else mini(count, MAX_TARGETS)
	return pool.slice(0, limit)


func _touch_enemy(enemy: Enemy, verb: String, act: Dictionary) -> void:
	var boss := _is_boss(enemy)
	match verb:
		"damage":
			enemy.take_damage(maxi(int(act["amount"]), 1))
		"stun":
			enemy.apply_stun(float(act["seconds"]))
		"slow":
			enemy.apply_slow(clampf(1.0 - float(act["amount"]), 0.05, 1.0), float(act["seconds"]))
		"shrink":
			enemy.resize(minf(float(act["scale"]), 1.0) if not boss else maxf(float(act["scale"]), 0.6), float(act["seconds"]))
		"grow":
			enemy.resize(maxf(float(act["scale"]), 1.0), float(act["seconds"]))
		"weaken":
			enemy.weaken(float(act["amount"]), float(act["seconds"]))
		"disarm":
			# A boss shrugs it off sooner, like stuns.
			enemy.disarm(float(act["seconds"]) * (0.35 if boss else 1.0))
		"kill":
			if boss:
				enemy.take_damage(maxi(int(float(enemy.max_health) * 0.25), 1))
			else:
				enemy.take_damage(enemy.health)
		"knockback", "pull", "launch":
			if boss:
				return
			var force := float(act["force"])
			var side := signf(enemy.global_position.x - player.global_position.x) if _player_ok() else 1.0
			if is_zero_approx(side):
				side = 1.0
			var impulse := Vector2(side * KNOCK_UNIT * force, -60.0 * minf(force, 6.0))
			if verb == "pull":
				impulse.x = -impulse.x
			elif verb == "launch":
				impulse = Vector2(0.0, -KNOCK_UNIT * 1.6 * force)
			enemy.apply_knockback(impulse.limit_length(1600.0), 0.2 + minf(force, 6.0) * 0.04)


func _transform(act: Dictionary) -> void:
	var into := StringName(String(act["into"]))
	if not spawner.is_valid() or not enemy_ids.has(into):
		return
	for enemy in _pick(act):
		if _is_boss(enemy):
			continue
		var at := enemy.global_position
		var share := float(enemy.health) / float(maxi(enemy.max_health, 1))
		var made := spawner.call(into, at, true) as Enemy
		if made == null:
			continue
		# It keeps the share of life it had: a transformation is not a heal.
		made.health = maxi(int(roundf(float(made.max_health) * share)), 1)
		made._sync_health_bar()
		# Not a kill: no pages, no kill rules. The room simply tracks the
		# new body instead of the old one.
		enemy.dead = true
		enemy.queue_free()
		if host != null and is_instance_valid(host) and host.is_inside_tree():
			VFX.spawn(host, &"enemy_spawn", at + Vector2(0, 16))


func _summon(act: Dictionary) -> void:
	var id := StringName(String(act["id"]))
	if not spawner.is_valid() or not enemy_ids.has(id) or not _player_ok():
		return
	var standing: Array[Enemy] = []
	for ally in _summoned:
		if ally != null and is_instance_valid(ally) and not ally.dead:
			standing.append(ally)
	_summoned = standing
	var hostile := float(act["hostile"]) > 0.0
	var count := clampi(int(act["count"]), 1, MAX_SUMMONS)
	if not hostile:
		count = mini(count, MAX_SUMMONS - _summoned.size())
	for index in count:
		var side := 1.0 if index % 2 == 0 else -1.0
		var at := player.global_position + Vector2(side * (70.0 + 40.0 * float(index / 2)), -8.0)
		var made := spawner.call(id, at, hostile) as Enemy
		if made == null:
			continue
		if hostile:
			continue
		# An ally is an enemy whose name is already rewritten; it falls when
		# the borrowed name burns out and never counts toward the room.
		made.set_meta(&"word_ally", true)
		made.charm(maxf(float(act["seconds"]), 1.0))
		_summoned.append(made)


func _dispel() -> void:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return
	for hazard in host.get_tree().get_nodes_in_group(&"hostile_hazards"):
		if hazard is HostileBolt and not (hazard as HostileBolt).friendly:
			(hazard as Node).queue_free()


# --- the caster --------------------------------------------------------------

func _player_ok() -> bool:
	return player != null and is_instance_valid(player)


func _teleport(act: Dictionary) -> void:
	if not _player_ok():
		return
	var facing := 1.0
	if player.sprite_visual != null and player.sprite_visual.flip_h:
		facing = -1.0
	var destination := player.global_position
	var distance := minf(float(act["distance"]), 4000.0)
	match String(act["to"]):
		"forward":
			_slide(Vector2(facing, 0.0), distance)
			return
		"back":
			_slide(Vector2(-facing, 0.0), distance)
			return
		"up":
			_slide(Vector2.UP, distance)
			return
		"enemy", "boss", "behind_boss":
			var pool := _live_enemies()
			if String(act["to"]) != "enemy":
				pool = _bosses(pool)
			if pool.is_empty():
				return
			pool.sort_custom(func(a: Enemy, b: Enemy) -> bool:
				return a.global_position.distance_squared_to(player.global_position) \
					< b.global_position.distance_squared_to(player.global_position))
			var enemy := pool[0]
			var side := signf(player.global_position.x - enemy.global_position.x)
			if is_zero_approx(side):
				side = -1.0
			if String(act["to"]) == "behind_boss":
				side = -side
			destination = enemy.global_position + Vector2(side * 90.0, -6.0)
	var start := player.global_position
	player.global_position = destination
	# Never leave the caster inside a wall: step back toward where it came from.
	if player.is_inside_tree():
		var back := (start - destination).normalized()
		var guard := 0
		while guard < 40 and player.test_move(player.global_transform, Vector2.ZERO):
			player.global_position += back * 16.0
			guard += 1
	player.velocity = Vector2.ZERO
	player.grant_invulnerability(0.35)
	_blink_fx(start)


func _slide(direction: Vector2, distance: float) -> void:
	var start := player.global_position
	var travelled := 0.0
	if player.is_inside_tree():
		while travelled + WorldPowers.BLINK_STEP <= distance:
			if player.test_move(player.global_transform, direction * WorldPowers.BLINK_STEP):
				break
			player.global_position += direction * WorldPowers.BLINK_STEP
			travelled += WorldPowers.BLINK_STEP
	else:
		player.global_position += direction * distance
	player.velocity.y = minf(player.velocity.y, 0.0)
	player.grant_invulnerability(0.35)
	_blink_fx(start)


func _blink_fx(start: Vector2) -> void:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return
	VFX.spawn(host, &"parry", start + Vector2(0, -30))
	VFX.spawn(host, &"parry", player.global_position + Vector2(0, -30))


# --- timed property overrides ------------------------------------------------

## Sets [param property] on [param object] for [param seconds], then restores
## what it was. A second override of the same property keeps the original
## value to return to.
func _override(object: Object, property: StringName, value: Variant, seconds: float) -> void:
	for entry in _overrides:
		if entry["object"] == object and entry["property"] == property:
			entry["left"] = maxf(float(entry["left"]), seconds)
			object.set(property, value)
			return
	_overrides.append({"object": object, "property": property, "base": object.get(property), "left": maxf(seconds, 0.05)})
	object.set(property, value)


func _tick_overrides(delta: float) -> void:
	for entry in _overrides.duplicate():
		entry["left"] = float(entry["left"]) - delta
		var object: Variant = entry["object"]
		if object == null or not is_instance_valid(object):
			_overrides.erase(entry)
		elif float(entry["left"]) <= 0.0:
			(object as Object).set(entry["property"], entry["base"])
			_overrides.erase(entry)


## Restores every timed override at once (scene teardown, death, tests).
func restore_all() -> void:
	for entry in _overrides:
		var object: Variant = entry["object"]
		if object != null and is_instance_valid(object):
			(object as Object).set(entry["property"], entry["base"])
	_overrides.clear()
	if Engine.time_scale != 1.0 and _time_scaled:
		Engine.time_scale = 1.0
	_time_scaled = false


func _exit_tree() -> void:
	restore_all()


# --- the room ----------------------------------------------------------------

func _gravity(amount: float, seconds: float) -> void:
	# The run scene reads modifier(&"gravity") every frame for the caster and
	# every enemy, so bodies spawned later fall the same way.
	add_modifier(&"gravity", clampf(amount, 0.05, 6.0), seconds)


var _time_scaled := false
var _time_left := 0.0


func _time_scale(amount: float, seconds: float) -> void:
	var factor := clampf(amount, 0.1, 3.0)
	Engine.time_scale = factor
	_time_scaled = true
	# Engine.time_scale also stretches this node's delta, so count real time.
	var timer := get_tree().create_timer(maxf(seconds, 0.1), true, false, true) if is_inside_tree() else null
	if timer != null:
		timer.timeout.connect(func() -> void:
			if _time_scaled:
				Engine.time_scale = 1.0
				_time_scaled = false)
	# The speaker of the sentence keeps their own pace while the world drags.
	if factor < 1.0 and _player_ok():
		player.grant_haste(1.0 / factor, seconds * factor)


func _darkness(amount: float, seconds: float) -> void:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return
	var layer := CanvasLayer.new()
	layer.layer = 4
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(0.0, 0.0, 0.02, 0.0)
	layer.add_child(rect)
	add_child(layer)
	var tween := layer.create_tween()
	tween.tween_property(rect, "color:a", clampf(amount, 0.0, 0.92), 0.5)
	tween.tween_interval(maxf(seconds - 1.0, 0.1))
	tween.tween_property(rect, "color:a", 0.0, 0.5)
	tween.tween_callback(layer.queue_free)


func _tint(color: Color, seconds: float) -> void:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return
	if _tint_layer != null and is_instance_valid(_tint_layer):
		_tint_layer.queue_free()
	_tint_layer = CanvasModulate.new()
	_tint_layer.color = Color.WHITE
	host.add_child(_tint_layer)
	var layer := _tint_layer
	var target := Color.WHITE.lerp(color, 0.45)
	var tween := layer.create_tween()
	tween.tween_property(layer, "color", target, 0.4)
	tween.tween_interval(maxf(seconds - 0.8, 0.1))
	tween.tween_property(layer, "color", Color.WHITE, 0.4)
	tween.tween_callback(layer.queue_free)


func _platforms(act: Dictionary) -> void:
	if host == null or not is_instance_valid(host) or not _player_ok():
		return
	var count := clampi(int(act["count"]), 1, MAX_PLATFORMS)
	var seconds := maxf(float(act["seconds"]), 2.0)
	var side := -1.0 if (player.sprite_visual != null and player.sprite_visual.flip_h) else 1.0
	var feet := player.global_position + Vector2(0, Player.FOOT_Y)
	for index in count:
		var platform := OneWayPlatform.new()
		platform.name = "WordStep_%d" % index
		platform.size = WorldPowers.STEP_SIZE
		platform.color = Color("1b2a33")
		platform.edge_color = Color("8fe8dc")
		var at := Vector2.ZERO
		match String(act["pattern"]):
			"bridge":
				at = Vector2(feet.x + side * (60.0 + index * WorldPowers.STEP_SIZE.x), feet.y - 8.0)
			"tower":
				at = Vector2(feet.x + (40.0 if index % 2 == 0 else -150.0), feet.y - WorldPowers.STEP_RISE * (index + 1))
			_:
				at = Vector2(feet.x + side * (60.0 + index * WorldPowers.STEP_RUN), feet.y - WorldPowers.STEP_RISE * (index + 1))
		if side < 0.0 and String(act["pattern"]) != "tower":
			at.x -= WorldPowers.STEP_SIZE.x
		platform.position = at
		platform.set_meta(&"ink_step", true)
		host.add_child(platform)
		_fade_out(platform, seconds + index * 0.08)


func _wall(act: Dictionary) -> void:
	if host == null or not is_instance_valid(host) or not _player_ok():
		return
	var side := -1.0 if (player.sprite_visual != null and player.sprite_visual.flip_h) else 1.0
	var height := clampf(float(act["height"]), 48.0, 480.0)
	var body := StaticBody2D.new()
	body.name = "WordWall"
	# Layer 1 is the world: enemies and their shots stop at it; the caster,
	# who also lives on layer 1, is let through by the exception below.
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22.0, height)
	shape.shape = rect
	body.add_child(shape)
	var visual := ColorRect.new()
	visual.color = Color("1b2a33")
	visual.size = rect.size
	visual.position = -rect.size * 0.5
	body.add_child(visual)
	var edge := ColorRect.new()
	edge.color = Color("8fe8dc")
	edge.size = Vector2(3.0, height)
	edge.position = Vector2(-rect.size.x * 0.5 if side > 0.0 else rect.size.x * 0.5 - 3.0, -height * 0.5)
	body.add_child(edge)
	body.position = player.global_position + Vector2(side * 70.0, Player.FOOT_Y - height * 0.5)
	host.add_child(body)
	player.add_collision_exception_with(body)
	_fade_out(body, maxf(float(act["seconds"]), 1.0))


func _fade_out(node: CanvasItem, seconds: float) -> void:
	if not node.is_inside_tree():
		return
	var tween := node.create_tween()
	tween.tween_interval(maxf(seconds - 1.0, 0.3))
	tween.tween_property(node, "modulate:a", 0.0, 1.0)
	tween.tween_callback(node.queue_free)


static func _speaker_prefix(who: String) -> String:
	match who:
		"boss": return "Boss："
		"enemy": return "敌人："
		"changzi": return "昌子："
	return ""


# --- things written into being ------------------------------------------------

func _make_relic(act: Dictionary) -> void:
	var name := String(act["name"])
	if name.is_empty():
		name = "无名之物"
	var relic := RelicData.new()
	relic.id = StringName("word_relic_%d" % absi(hash(name + String(act["description"]))))
	relic.display_name = name
	relic.effect_id = &"word_made"
	var lines: Array[String] = []
	var mods: Dictionary = act.get("mods", {})
	for key in mods:
		lines.append("%s ×%.2f" % [MODIFIERS.get(StringName(String(key)), key), float(mods[key])])
	var rule_list: Array = act.get("rules", [])
	for rule in rule_list:
		lines.append(describe_rule({"when": rule["when"], "do": rule["do"], "seconds": 0.0, "interval": rule.get("interval", 1.0)}))
	var body := String(act["description"])
	relic.description = body + ("\n" if not body.is_empty() and not lines.is_empty() else "") + "\n".join(lines)
	relic.set_meta(&"word_act", act.duplicate(true))
	if relic_giver.is_valid() and not bool(relic_giver.call(relic)):
		return
	_relic_acts.append(act.duplicate(true))
	arm_relic(act)


## Turns on a word-made relic's modifiers and rules for the rest of the run
## (also called when a saved run is restored).
func arm_relic(act: Dictionary) -> void:
	_arming_relic = true
	var mods: Dictionary = act.get("mods", {})
	for key in mods:
		add_modifier(StringName(String(key)), float(mods[key]), 0.0)
	for rule in act.get("rules", []):
		var forever: Dictionary = (rule as Dictionary).duplicate(true)
		forever["seconds"] = 0.0
		add_rule(forever)
	_arming_relic = false


# === saving (run checkpoints) ==================================================

## What outlives a checkpoint: written relics and run-long modifiers and rules.
## Timed effects are short on purpose and end with the session.
func save_state() -> Dictionary:
	var mods: Array = []
	for key in _mods:
		for entry in _mods[key]:
			if float(entry["left"]) == INF and not bool(entry.get("relic", false)):
				mods.append({"key": String(key), "value": float(entry["value"])})
	var forever: Array = []
	for rule in rules:
		if float(rule["left"]) == INF and not bool(rule.get("relic", false)):
			forever.append({"when": rule["when"], "do": rule["do"], "seconds": 0.0,
				"times": rule.get("times", 0.0), "interval": rule.get("interval", 1.0),
				"name": rule.get("name", "")})
	return {"relics": _relic_acts.duplicate(true), "mods": mods, "rules": forever}


func load_state(data: Dictionary) -> void:
	_loading = true
	for act in sanitize(data.get("relics", [])):
		if String(act["do"]) == "relic":
			_make_relic(act)
	var mods: Variant = data.get("mods", [])
	if mods is Array:
		for entry in mods:
			if entry is Dictionary:
				add_modifier(StringName(String(entry.get("key", ""))), _number(entry.get("value", 1.0), 1.0), 0.0)
	for rule in sanitize_rules(data.get("rules", [])):
		rule["seconds"] = 0.0
		add_rule(rule)
	_loading = false


## Short lines for the HUD: what the world is currently bent into.
func status_lines() -> Array[String]:
	var lines: Array[String] = []
	var active := active_modifiers()
	for key in active:
		lines.append("%s ×%.2f" % [MODIFIERS.get(key, key), float(active[key])])
	for rule in rules:
		var parts: Array[String] = []
		for act in rule["do"]:
			parts.append(describe(act))
		var when := String(TRIGGERS.get(StringName(String(rule["when"])), ""))
		var left := float(rule["left"])
		lines.append("%s：%s%s" % [when, "；".join(parts), "" if left == INF else "（%d 秒）" % int(ceilf(left))])
	return lines


func _make_weapon(act: Dictionary) -> void:
	if not weapon_dropper.is_valid() or not _player_ok():
		return
	var kind := String(act["kind"])
	var base := weapon_bases.get(kind) as WeaponData
	var weapon := base.duplicate() as WeaponData if base != null else WeaponData.new()
	var name := String(act["name"])
	if name.is_empty():
		name = "言成之刃"
	if base == null:
		weapon.id = StringName("word_weapon_%d" % absi(hash(name)))
		weapon.kind = WeaponData.Kind.RANGED if kind == "ranged" else WeaponData.Kind.MELEE
	weapon.display_name = name
	weapon.damage = maxi(int(act["damage"]), 1)
	weapon.attack_cooldown = clampf(float(act["cooldown"]), 0.08, 3.0)
	weapon.attack_range = clampf(float(act["range"]), 30.0, 600.0)
	var tags: Array[StringName] = weapon.tags.duplicate()
	tags.append(&"word")
	weapon.tags = tags
	weapon_dropper.call(weapon, player.global_position + Vector2(0, -20))
