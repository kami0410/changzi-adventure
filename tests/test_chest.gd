extends RefCounted

func run(t: Callable) -> void:
	var chest := TreasureChest.new()
	var opened := [0]
	chest.opened.connect(func(_chest): opened[0] += 1)
	t.call(chest.open(), true, "chest_opens")
	t.call(chest.is_open, true, "chest_open_state")
	t.call(chest.open(), false, "chest_cannot_open_twice")
	t.call(opened[0], 1, "chest_emits_once")
	chest.free()

	var run := RunState.new()
	run.reset_for_new_run(12345)
	var profile := Profile.new()
	var loot := RunLoot.chest_loot(run, profile, 0)
	t.call(loot.is_empty(), false, "chest_loot_not_empty")
	t.call(String(loot.get("title", "")).is_empty(), false, "chest_loot_has_title")
	t.call([&"weapon", &"word", &"relic", &"pages"].has(StringName(loot.get("kind", &""))), true, "chest_loot_kind")
	profile.free()
