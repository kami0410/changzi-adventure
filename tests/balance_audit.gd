extends SceneTree

## Dev audit over random distinct word combinations using the real resolver.
## Godot --headless --path . --script tests/balance_audit.gd -- --samples=200000

var _samples := 200000


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--samples="):
			_samples = maxi(int(argument.trim_prefix("--samples=")), 1)
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
	var records: Array[Dictionary] = []
	for sample in _samples:
		var count := rng.randi_range(1, 4)
		var pool := words.duplicate()
		var combo: Array[WordData] = []
		for index in count:
			var pick := rng.randi_range(0, pool.size() - 1)
			combo.append(pool[pick])
			pool.remove_at(pick)
		var phrase := resolver.resolve(combo)
		if phrase == null:
			continue
		var damage := float(phrase.components.get(&"damage", 0.0))
		var efficiency := damage / maxf(float(phrase.ink_cost), 1.0)
		max_damage = maxf(max_damage, damage)
		max_efficiency = maxf(max_efficiency, efficiency)
		max_ink = maxi(max_ink, phrase.ink_cost)
		min_ink = mini(min_ink, phrase.ink_cost)
		min_cooldown = minf(min_cooldown, phrase.cooldown)
		max_cooldown = maxf(max_cooldown, phrase.cooldown)
		records.append({
			"damage": damage,
			"efficiency": efficiency,
			"ink": phrase.ink_cost,
			"cooldown": phrase.cooldown,
			"name": phrase.display_name,
		})
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["damage"]) > float(b["damage"])
	)
	print("AUDIT samples=%d max_damage=%.1f max_damage_per_ink=%.3f ink=[%d, %d] cooldown=[%.2f, %.2f]" % [
		_samples, max_damage, max_efficiency, min_ink, max_ink, min_cooldown, max_cooldown,
	])
	for index in mini(5, records.size()):
		var record := records[index]
		print("  damage=%.1f ink=%d cd=%.2f  %s" % [
			float(record["damage"]), int(record["ink"]), float(record["cooldown"]), String(record["name"]),
		])
	quit()
