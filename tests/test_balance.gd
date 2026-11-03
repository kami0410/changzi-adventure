extends RefCounted

## Seeded sample over free word combinations. This is not a full proof (there
## are ~3.3M four-word combinations); it catches the outlier shape that free
## combinations used to create: high damage or high damage-per-ink at low cost.

const SAMPLES := 30000
const MAX_DAMAGE := 30.0
const MAX_EFFICIENCY := 0.6
const MAX_INK := 95

func run(t: Callable) -> void:
	var words: Array[WordData] = []
	for entry in ContentLibrary.WORDS:
		words.append(entry as WordData)
	var resolver := PhraseResolver.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261102
	var max_damage := 0.0
	var max_efficiency := 0.0
	var max_ink := 0
	var min_ink := 999
	var min_cooldown := 99.0
	var max_cooldown := 0.0
	var valid := 0
	for sample in SAMPLES:
		var count := rng.randi_range(1, 4)
		var combo: Array[WordData] = []
		for index in count:
			combo.append(words[rng.randi_range(0, words.size() - 1)])
		var phrase := resolver.resolve(combo)
		if phrase == null:
			continue
		valid += 1
		var damage := float(phrase.components.get(&"damage", 0.0))
		max_damage = maxf(max_damage, damage)
		max_efficiency = maxf(max_efficiency, damage / maxf(float(phrase.ink_cost), 1.0))
		max_ink = maxi(max_ink, phrase.ink_cost)
		min_ink = mini(min_ink, phrase.ink_cost)
		min_cooldown = minf(min_cooldown, phrase.cooldown)
		max_cooldown = maxf(max_cooldown, phrase.cooldown)
	t.call(valid > SAMPLES / 2, true, "balance_sample_valid")
	t.call(max_damage <= MAX_DAMAGE, true, "balance_damage_bounded")
	t.call(max_efficiency <= MAX_EFFICIENCY, true, "balance_efficiency_bounded")
	t.call(max_ink <= MAX_INK, true, "balance_max_ink_bounded")
	t.call(min_ink >= 1, true, "balance_min_ink_bounded")
	t.call(min_cooldown >= 0.8 and max_cooldown <= 9.0, true, "balance_cooldown_bounded")
	print("BALANCE max_damage=%.1f max_dmg_per_ink=%.3f max_ink=%d cooldown=[%.2f, %.2f]" % [
		max_damage, max_efficiency, max_ink, min_cooldown, max_cooldown,
	])
