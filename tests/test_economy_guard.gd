extends RefCounted

## NPC inspiration cannot be farmed: one effect per NPC per Hub visit, hard
## caps per grant, next-run bonuses consumed once, and AI never doubles the
## offline effect.


func run(t: Callable) -> void:
	_test_one_effect_per_visit(t)
	_test_effect_caps(t)
	_test_pending_run_bonuses(t)
	_test_ai_does_not_double(t)


func _test_one_effect_per_visit(t: Callable) -> void:
	var profile := Profile.new()
	var used: Dictionary = {}
	for index in 10:
		NPCProfiles.apply_effect_once(profile, &"guru", {"fragments": 6.0}, used)
	t.call(profile.memory_fragments, 6, "one_effect_per_hub_visit")
	t.call(profile.memory_fragments <= 12, true, "ten_submissions_stay_under_cap")
	profile.free()


func _test_effect_caps(t: Callable) -> void:
	var profile := Profile.new()
	NPCProfiles.apply_effect(profile, &"guru", {"fragments": 50.0})
	t.call(profile.memory_fragments, 12, "fragments_capped_at_12")
	NPCProfiles.apply_effect(profile, &"baiyu", {"map_pages": 50.0})
	t.call(profile.pending_run_bonuses.get("start_pages", 0.0), 20.0, "map_pages_capped_at_20")
	NPCProfiles.apply_effect(profile, &"__abyss__", {"corruption": 50.0})
	t.call(profile.pending_run_bonuses.get("start_corruption", 0.0), 6.0, "start_corruption_capped_at_6")
	for index in 5:
		NPCProfiles.apply_effect(profile, &"ayan", {"forge_bonus": 5.0})
	t.call(profile.npc_blessing(&"ayan", "forge_bonus", 0.0), 3.0, "forge_bonus_total_capped_at_3")
	NPCProfiles.apply_effect(profile, &"ayan", {"forge_free": 50.0})
	t.call(profile.npc_blessing(&"ayan", "forge_free", 0.0), 1.0, "forge_free_capped_at_1")
	NPCProfiles.apply_effect(profile, &"ayan", {"forge_discount": 5.0})
	t.call(profile.npc_blessing(&"ayan", "forge_discount", 0.0), 0.35, "forge_discount_capped")
	NPCProfiles.apply_effect(profile, &"guru", {"shop_discount": 5.0})
	t.call(profile.npc_blessing(&"guru", "shop_discount", 0.0), 0.35, "shop_discount_capped")
	profile.free()


func _test_pending_run_bonuses(t: Callable) -> void:
	var profile := Profile.new()
	NPCProfiles.apply_effect(profile, &"baiyu", {"map_pages": 8.0})
	t.call(profile.npc_blessing(&"baiyu", "start_pages", 0.0), 0.0, "map_pages_not_permanent")
	var pending := profile.consume_pending_run_bonuses()
	t.call(pending.get("start_pages", 0.0), 8.0, "pending_pages_consumed")
	t.call(profile.consume_pending_run_bonuses().is_empty(), true, "pending_pages_consumed_once")
	NPCProfiles.apply_effect(profile, &"__abyss__", {"corruption": 3.0})
	t.call(profile.npc_blessing(&"__abyss__", "start_corruption", 0.0), 0.0, "start_corruption_not_permanent")
	t.call(profile.consume_pending_run_bonuses().get("start_corruption", 0.0), 3.0, "pending_corruption_consumed")
	profile.free()


func _test_ai_does_not_double(t: Callable) -> void:
	var profile := Profile.new()
	var hub := Hub.new()
	hub.profile = profile
	hub._npc_effect_used = {}

	var skipped := hub._apply_inspiration_effect(&"guru", {"fragments": 6.0}, true)
	t.call(skipped.is_empty(), true, "ai_configured_skips_offline_effect")
	t.call(profile.memory_fragments, 0, "ai_configured_no_offline_gain")

	var ai_effect := hub._apply_inspiration_effect(&"guru", {"fragments": 6.0}, false)
	t.call(ai_effect.get("fragments", 0.0), 6.0, "ai_effect_applies_once")
	t.call(hub._apply_inspiration_effect(&"guru", {"fragments": 6.0}, false).is_empty(), true, "ai_effect_not_repeated")
	t.call(profile.memory_fragments, 6, "ai_effect_single_total")

	hub._npc_effect_used = {}
	t.call(hub._apply_inspiration_effect(&"guru", {"fragments": 6.0}, true).is_empty(), true, "failure_fallback_starts_clean")
	t.call(hub._apply_inspiration_effect(&"guru", {"fragments": 6.0}, false).get("fragments", 0.0), 6.0, "failure_fallback_applies_offline_once")
	t.call(hub._apply_inspiration_effect(&"guru", {"fragments": 6.0}, false).is_empty(), true, "failure_fallback_not_repeated")
	hub.free()
	profile.free()
