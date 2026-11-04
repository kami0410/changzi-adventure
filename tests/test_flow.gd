extends RefCounted


func run(t: Callable) -> void:
	var path := "user://test_profile.cfg"
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)

	var profile := Profile.new()
	profile.memory_fragments = 42
	profile.unlocked_words.append(&"gr")
	profile.weapon_base_levels[&"sword"] = 2
	profile.unlocked_patterns.append(&"VERB_NOUN")
	profile.discovered_phrases.append("gr,grguan|2")
	profile.save_profile(path)

	var loaded := Profile.new()
	t.call(loaded.load_profile(path), true, "profile_load_ok")
	t.call(loaded.memory_fragments, 42, "profile_fragments")
	t.call(loaded.unlocked_words.has(&"gr"), true, "profile_words")
	t.call(loaded.weapon_base_levels.get(&"sword", 0), 2, "profile_weapon_level")
	t.call(loaded.discovered_phrases.has("gr,grguan|2"), true, "profile_phrase")

	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
	var missing := Profile.new()
	t.call(missing.load_profile("user://does_not_exist.cfg"), false, "profile_missing")

	var flow := GameFlow.new()
	flow.profile = Profile.new()
	flow.auto_save = false
	var run := flow.start_run(123)
	t.call(run.run_seed, 123, "flow_start_seed")
	flow.end_run(true)
	t.call(flow.current_run, null, "flow_end_clears")
	t.call(flow.profile.memory_fragments > 0, true, "flow_reward")
	t.call(flow.last_victory, true, "flow_last_victory")
	t.call(flow.last_reward > 0, true, "flow_last_reward")

	flow.profile.memory_fragments = 100
	t.call(flow.profile.upgrade_weapon_base(&"sword"), true, "upgrade_base")
	t.call(flow.profile.weapon_base_level(&"sword"), 1, "upgrade_level")
	t.call(flow.profile.memory_fragments, 90, "upgrade_cost")

	flow.profile.free()
	flow.free()
	profile.free()
	loaded.free()
	missing.free()
