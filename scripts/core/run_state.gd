class_name RunState
extends RefCounted

signal corruption_changed(value: int)
signal corruption_tier_changed(tier: int)
signal ink_changed(value: int)
signal health_changed(current: int, maximum: int)
signal pages_changed(value: int)

const CORRUPTION_THRESHOLDS := [25, 50, 75, 100]

var run_seed: int = 0
var rng := RandomNumberGenerator.new()
var health: int = 100
var max_health: int = 100
var ink: int = 100
var max_ink: int = 100
var corruption: int = 0
var pages: int = 0
## Chapter mutator (RunMutators.CORRUPTION_GAIN); set at chapter start, not saved.
var mutator_corruption_scale: float = 1.0
## 言灵世界改写 (1.1): a sentence's run rule on corruption gain; not saved here
## (WorldActs saves its own run-long rules).
var word_corruption_scale: float = 1.0
var inventory := Inventory.new()
var current_biome: StringName = &""
var authority: AuthorityData
## Set at run start from difficulty and archive upgrades; positive gains only.
var corruption_gain_multiplier: float = 1.0

var _last_corruption_tier: int = 0


func reset_for_new_run(seed_value: int = 0) -> void:
	run_seed = seed_value if seed_value != 0 else randi()
	rng.seed = run_seed
	health = max_health
	ink = max_ink
	corruption = 0
	pages = 0
	inventory = Inventory.new()
	current_biome = &""
	authority = null
	_last_corruption_tier = 0
	health_changed.emit(health, max_health)
	ink_changed.emit(ink)
	corruption_changed.emit(corruption)
	pages_changed.emit(pages)


func add_pages(amount: int) -> void:
	pages = maxi(pages + amount, 0)
	pages_changed.emit(pages)


func spend_pages(amount: int) -> bool:
	if amount <= 0 or pages < amount:
		return false
	pages -= amount
	pages_changed.emit(pages)
	return true


func add_corruption(amount: int) -> void:
	if amount == 0:
		return
	var gain := corruption_gain_multiplier * mutator_corruption_scale * word_corruption_scale
	if amount > 0 and not is_equal_approx(gain, 1.0):
		amount = maxi(int(ceilf(float(amount) * gain)), 0 if is_zero_approx(gain) else 1)
		if amount == 0:
			return
	corruption = clampi(corruption + amount, 0, 100)
	corruption_changed.emit(corruption)
	var tier := corruption_tier()
	if tier != _last_corruption_tier:
		_last_corruption_tier = tier
		corruption_tier_changed.emit(tier)


func corruption_tier() -> int:
	var tier := 0
	for threshold in CORRUPTION_THRESHOLDS:
		if corruption >= threshold:
			tier += 1
	return tier


## Forced adjustment (frenzy recovery, scripted events): keeps the tier cache
## honest so crossing 100 again still fires the frenzy.
func set_corruption(value: int) -> void:
	corruption = clampi(value, 0, 100)
	corruption_changed.emit(corruption)
	var tier := corruption_tier()
	if tier != _last_corruption_tier:
		_last_corruption_tier = tier
		corruption_tier_changed.emit(tier)


## Pollution is a risk axis, not a number on the HUD: every threshold makes the
## player physically weaker while the abyss-flavoured build stays available.
func corruption_tier_name() -> String:
	match corruption_tier():
		1: return "低语"
		2: return "侵蚀"
		3: return "深渊"
		4: return "失控"
	return "平静"


func corruption_damage_taken_multiplier() -> float:
	match corruption_tier():
		1: return 1.15
		2: return 1.30
		3: return 1.45
		4: return 1.60
	return 1.0


func corruption_ink_cost_multiplier() -> float:
	match corruption_tier():
		1: return 1.15
		2: return 1.30
		3: return 1.45
		4: return 1.60
	return 1.0


func corruption_cooldown_multiplier() -> float:
	match corruption_tier():
		1: return 1.0
		2: return 1.20
		3: return 1.35
		4: return 1.50
	return 1.0


func corruption_tier_warning() -> String:
	# Copy rotates per run + tier; the mechanics text inside each variant is
	# fixed, and the pick never consumes the run RNG.
	return CorruptionWarningData.pick(run_seed, corruption_tier())


func set_authority(value: AuthorityData) -> void:
	authority = value


func spend_ink(amount: int) -> bool:
	if amount < 0 or ink < amount:
		return false
	ink -= amount
	ink_changed.emit(ink)
	return true


func restore_ink(amount: int) -> void:
	if amount <= 0:
		return
	ink = mini(ink + amount, max_ink)
	ink_changed.emit(ink)


func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)


func heal(amount: int) -> void:
	if amount <= 0:
		return
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)
