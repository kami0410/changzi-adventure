extends RefCounted

## Hub personal events (叙事审计 E2, 第一批). The data is authored from the
## story bible; these checks pin the three visible NPCs, their trust/chapter
## gates, the once-only flag and the no-reward rule. 闻烬/白榆 stay hidden and
## have no event.

const VISIBLE: Array[StringName] = [&"luchen", &"ayan", &"guru"]
const HIDDEN: Array[StringName] = [&"wenjin", &"baiyu"]


func run(t: Callable) -> void:
	_test_data(t)
	_test_trigger_gates(t)
	_test_once_only(t)
	_test_no_rewards(t)
	_test_persistence(t)
	_test_old_save(t)
	_test_line_content(t)


func _test_data(t: Callable) -> void:
	t.call(NPCEventData.EVENTS.size(), VISIBLE.size(), "npc_event_count")
	var ids: Dictionary = {}
	for npc_id in VISIBLE:
		var event := NPCEventData.event_for(npc_id)
		t.call(event.is_empty(), false, "npc_event_present_" + String(npc_id))
		t.call(String(event.get("id", "")).is_empty(), false, "npc_event_id_" + String(npc_id))
		t.call(ids.has(String(event.get("id", ""))), false,
			"npc_event_id_unique_" + String(npc_id))
		ids[String(event.get("id", ""))] = true
		t.call(String(event.get("prop", "")).is_empty(), false,
			"npc_event_prop_" + String(npc_id))
		t.call(bool(event.get("requires_demo_cleared", false)), true,
			"npc_event_needs_chapter_progress_" + String(npc_id))
	t.call(String(NPCEventData.event_for(&"luchen").get("prop", "")), "红色文件夹",
		"npc_event_luchen_prop")
	t.call(String(NPCEventData.event_for(&"ayan").get("prop", "")), "断页剑",
		"npc_event_ayan_prop")
	t.call(String(NPCEventData.event_for(&"guru").get("prop", "")), "玻璃瓶",
		"npc_event_guru_prop")
	t.call(int(NPCEventData.event_for(&"luchen").get("min_tier", -1)), 2,
		"npc_event_luchen_tier")
	t.call(int(NPCEventData.event_for(&"ayan").get("min_tier", -1)), 3,
		"npc_event_ayan_tier")
	t.call(int(NPCEventData.event_for(&"guru").get("min_tier", -1)), 1,
		"npc_event_guru_tier")
	for npc_id in HIDDEN:
		t.call(NPCEventData.event_for(npc_id).is_empty(), true,
			"npc_event_hidden_has_none_" + String(npc_id))
		t.call(NPCEventData.event_id(npc_id), "", "npc_event_hidden_id_" + String(npc_id))
	t.call(NPCEventData.event_for(&"missing").is_empty(), true, "npc_event_missing")
	t.call(NPCEventData.event_id(&"missing"), "", "npc_event_missing_id")

	# event_for hands out a copy; callers cannot mutate the authored table.
	var copy := NPCEventData.event_for(&"luchen")
	copy["lines"] = []
	t.call((NPCEventData.event_for(&"luchen").get("lines", []) as Array).size() > 0,
		true, "npc_event_data_is_copied")


func _test_trigger_gates(t: Callable) -> void:
	var profile := Profile.new()
	for npc_id in VISIBLE:
		t.call(NPCEventData.can_trigger(profile, npc_id), false,
			"npc_event_fresh_profile_" + String(npc_id))
	t.call(NPCEventData.can_trigger(null, &"luchen"), false, "npc_event_null_profile")
	t.call(NPCEventData.can_trigger(profile, &"missing"), false, "npc_event_unknown_npc")

	# Chapter progress alone is not enough.
	profile.demo_cleared = true
	for npc_id in VISIBLE:
		t.call(NPCEventData.can_trigger(profile, npc_id), false,
			"npc_event_progress_without_trust_" + String(npc_id))

	# Trust alone is not enough either: the confession waits for the first
	# finished chapter, which is the demo's only durable progress flag.
	var trusted_only := Profile.new()
	trusted_only.add_npc_trust(&"luchen", 6.0)
	trusted_only.add_npc_trust(&"ayan", 12.0)
	trusted_only.add_npc_trust(&"guru", 2.0)
	for npc_id in VISIBLE:
		t.call(NPCEventData.can_trigger(trusted_only, npc_id), false,
			"npc_event_trust_without_progress_" + String(npc_id))

	# One point below the tier never fires, even with the chapter finished.
	profile.add_npc_trust(&"luchen", 5.99)
	profile.add_npc_trust(&"ayan", 11.99)
	profile.add_npc_trust(&"guru", 1.99)
	for npc_id in VISIBLE:
		t.call(NPCEventData.can_trigger(profile, npc_id), false,
			"npc_event_below_tier_" + String(npc_id))

	# Reaching the authored tier fires exactly that NPC.
	profile.add_npc_trust(&"luchen", 0.01)
	t.call(NPCEventData.can_trigger(profile, &"luchen"), true, "npc_event_luchen_at_tier")
	t.call(NPCEventData.can_trigger(profile, &"ayan"), false, "npc_event_ayan_still_below")
	profile.add_npc_trust(&"ayan", 0.01)
	t.call(NPCEventData.can_trigger(profile, &"ayan"), true, "npc_event_ayan_at_tier")
	profile.add_npc_trust(&"guru", 0.01)
	t.call(NPCEventData.can_trigger(profile, &"guru"), true, "npc_event_guru_at_tier")
	# Higher tiers keep qualifying.
	profile.add_npc_trust(&"guru", 30.0)
	t.call(NPCEventData.can_trigger(profile, &"guru"), true, "npc_event_above_tier")
	profile.free()
	trusted_only.free()


func _test_once_only(t: Callable) -> void:
	var profile := Profile.new()
	profile.demo_cleared = true
	profile.add_npc_trust(&"luchen", 6.0)
	t.call(profile.has_npc_event("luchen_red_folder"), false, "npc_event_flag_default_false")
	t.call(profile.record_npc_event("luchen_red_folder"), true, "npc_event_record_first")
	t.call(profile.record_npc_event("luchen_red_folder"), false, "npc_event_record_second")
	t.call(profile.npc_events.size(), 1, "npc_event_record_no_duplicate")
	t.call(profile.has_npc_event("luchen_red_folder"), true, "npc_event_flag_set")
	t.call(NPCEventData.can_trigger(profile, &"luchen"), false, "npc_event_seen_never_again")
	t.call(profile.record_npc_event(""), false, "npc_event_record_empty")
	t.call(profile.npc_events.size(), 1, "npc_event_empty_not_stored")
	profile.free()


func _test_no_rewards(t: Callable) -> void:
	var profile := Profile.new()
	profile.demo_cleared = true
	profile.add_npc_trust(&"luchen", 6.0)
	profile.memory_fragments = 17
	var trust_before: float = profile.npc_trust_value(&"luchen")
	var fragments_before: int = profile.memory_fragments
	t.call(NPCEventData.can_trigger(profile, &"luchen"), true, "npc_event_reward_gate")
	profile.record_npc_event("luchen_red_folder")
	t.call(profile.npc_trust_value(&"luchen"), trust_before, "npc_event_grants_no_trust")
	t.call(profile.memory_fragments, fragments_before, "npc_event_grants_no_fragments")
	t.call(profile.npc_blessings.is_empty(), true, "npc_event_grants_no_blessing")
	t.call(profile.endings.is_empty(), true, "npc_event_grants_no_ending")
	profile.free()


func _test_persistence(t: Callable) -> void:
	var path := "user://test_npc_events_profile.cfg"
	for suffix in ["", ".bak", ".tmp"]:
		var target: String = path + String(suffix)
		if FileAccess.file_exists(target):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(target))
	var profile := Profile.new()
	profile.demo_cleared = true
	profile.add_npc_trust(&"ayan", 12.0)
	t.call(profile.record_npc_event("ayan_furnace"), true, "npc_event_persist_record")
	profile.save_profile(path)
	var loaded := Profile.new()
	t.call(loaded.load_profile(path), true, "npc_event_persist_loads")
	t.call(loaded.has_npc_event("ayan_furnace"), true, "npc_event_persist_flag")
	t.call(loaded.npc_events.size(), 1, "npc_event_persist_count")
	t.call(NPCEventData.can_trigger(loaded, &"ayan"), false,
		"npc_event_persist_blocks_retrigger")
	t.call(loaded.demo_cleared, true, "npc_event_persist_keeps_progress")
	t.call(loaded.npc_trust_value(&"ayan"), 12.0, "npc_event_persist_keeps_trust")
	# Saving again must not duplicate the id.
	loaded.save_profile(path)
	var reloaded := Profile.new()
	t.call(reloaded.load_profile(path), true, "npc_event_persist_reloads")
	t.call(reloaded.npc_events.size(), 1, "npc_event_persist_stable")
	profile.free()
	loaded.free()
	reloaded.free()
	for suffix in ["", ".bak", ".tmp"]:
		var target: String = path + String(suffix)
		if FileAccess.file_exists(target):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(target))


func _test_old_save(t: Callable) -> void:
	# A pre-event save has no [npc] events key; it must load clean and still be
	# able to fire once the gates are met.
	var path := "user://test_npc_events_old.cfg"
	for suffix in ["", ".bak", ".tmp"]:
		var target: String = path + String(suffix)
		if FileAccess.file_exists(target):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(target))
	var config := ConfigFile.new()
	config.set_value("meta", "version", 2)
	config.set_value("progress", "demo_cleared", true)
	config.set_value("npc", "trust", {"guru": 2.0})
	config.save(path)
	var profile := Profile.new()
	t.call(profile.load_profile(path), true, "npc_event_old_save_loads")
	t.call(profile.npc_events.is_empty(), true, "npc_event_old_save_empty")
	t.call(NPCEventData.can_trigger(profile, &"guru"), true, "npc_event_old_save_can_fire")
	profile.save_profile(path)
	var reloaded := Profile.new()
	t.call(reloaded.load_profile(path), true, "npc_event_old_save_roundtrip")
	t.call(reloaded.npc_events.is_empty(), true, "npc_event_old_save_roundtrip_empty")
	profile.free()
	reloaded.free()
	for suffix in ["", ".bak", ".tmp"]:
		var target: String = path + String(suffix)
		if FileAccess.file_exists(target):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(target))


func _test_line_content(t: Callable) -> void:
	for npc_id in VISIBLE:
		var event := NPCEventData.event_for(npc_id)
		var lines: Array = event.get("lines", [])
		var suffix := String(npc_id)
		t.call(lines.size() >= 8, true, "npc_event_lines_long_enough_" + suffix)
		var seen: Dictionary = {}
		var prop := String(event.get("prop", ""))
		var mentions_prop := false
		for line in lines:
			var text := String(line)
			t.call(text.strip_edges().is_empty(), false, "npc_event_line_not_blank_" + suffix)
			t.call(text.contains("%s") or text.contains("%d") or text.contains("{"), false,
				"npc_event_line_no_placeholder_" + suffix)
			t.call(seen.has(text), false, "npc_event_line_unique_" + suffix)
			seen[text] = true
			if text.contains(prop):
				mentions_prop = true
		t.call(mentions_prop, true, "npc_event_line_mentions_prop_" + suffix)
	# The bottle's word is the beat, not just the prop name.
	var guru_lines: Array = NPCEventData.event_for(&"guru").get("lines", [])
	var mentions_yong := false
	for line in guru_lines:
		if String(line).contains("永"):
			mentions_yong = true
	t.call(mentions_yong, true, "npc_event_guru_bottle_word")
