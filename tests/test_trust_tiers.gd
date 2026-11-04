extends RefCounted

## Trust tiers are derived, not persisted: Profile keeps its original float and
## every reader goes through TrustData. These checks pin the thresholds, the
## no-stacking rule, the offline attitude line and the AI prompt injection.

const TRUST_IDS: Array[StringName] = [&"luchen", &"ayan", &"guru", &"wenjin", &"baiyu"]


func run(t: Callable) -> void:
	_test_thresholds(t)
	_test_benefits(t)
	_test_start_pages(t)
	_test_attitude_lines(t)
	_test_offline_evaluator(t)
	_test_ai_prompt(t)
	_test_old_save_compatibility(t)


func _test_thresholds(t: Callable) -> void:
	var cases := [
		[-5.0, 0, "stranger"],
		[0.0, 0, "stranger"],
		[1.99, 0, "stranger"],
		[2.0, 1, "acquainted"],
		[5.99, 1, "acquainted"],
		[6.0, 2, "trusted"],
		[11.99, 2, "trusted"],
		[12.0, 3, "devoted"],
		[999.0, 3, "devoted"],
	]
	for entry in cases:
		t.call(TrustData.tier_index(float(entry[0])), int(entry[1]),
			"trust_tier_index_%s" % String(entry[2] + "_" + str(entry[0])))
		t.call(String(TrustData.tier_id(float(entry[0]))), String(entry[2]),
			"trust_tier_id_%s" % str(entry[0]))
	t.call(TrustData.tier_index(NAN), 0, "trust_tier_nan_is_stranger")
	t.call(TrustData.tier_index(INF), 0, "trust_tier_inf_is_guarded")
	t.call(TrustData.TIER_NAMES.size(), TrustData.TIER_COUNT, "trust_tier_name_count")
	t.call(TrustData.tier_name(0.0), "陌生", "trust_name_stranger")
	t.call(TrustData.tier_name(2.0), "熟悉", "trust_name_acquainted")
	t.call(TrustData.tier_name(6.0), "信任", "trust_name_trusted")
	t.call(TrustData.tier_name(12.0), "托付", "trust_name_devoted")

	var profile := Profile.new()
	t.call(TrustData.tier_for(profile, &"luchen"), 0, "trust_profile_default_stranger")
	profile.add_npc_trust(&"luchen", 6.5)
	t.call(TrustData.tier_for(profile, &"luchen"), 2, "trust_profile_reads_value")
	t.call(TrustData.tier_name_for(profile, &"luchen"), "信任", "trust_profile_name")
	t.call(TrustData.tier_for(profile, &"guru"), 0, "trust_profile_per_npc")
	t.call(TrustData.tier_for(null, &"luchen"), 0, "trust_null_profile_stranger")
	profile.free()


func _test_benefits(t: Callable) -> void:
	var profile := Profile.new()
	t.call(TrustData.shop_discount(profile), 0.0, "trust_shop_discount_stranger")
	t.call(TrustData.forge_discount(profile), 0.0, "trust_forge_discount_stranger")
	profile.add_npc_trust(&"guru", 2.0)
	t.call(TrustData.shop_discount(profile), 0.05, "trust_shop_discount_acquainted")
	profile.add_npc_trust(&"guru", 4.0)
	t.call(TrustData.shop_discount(profile), 0.10, "trust_shop_discount_trusted")
	profile.add_npc_trust(&"guru", 6.0)
	t.call(TrustData.shop_discount(profile), 0.15, "trust_shop_discount_devoted")

	# A larger authored blessing wins outright; the tier never adds on top.
	profile.add_npc_blessing(&"guru", "shop_discount", 0.18)
	t.call(TrustData.shop_discount(profile), 0.18, "trust_shop_discount_no_stacking")
	profile.add_npc_blessing(&"ayan", "forge_discount", 0.12)
	t.call(TrustData.forge_discount(profile), 0.12, "trust_forge_discount_no_stacking")
	profile.add_npc_trust(&"ayan", 12.0)
	t.call(TrustData.forge_discount(profile), 0.15, "trust_forge_discount_devoted_wins")
	t.call(TrustData.forge_blessing(profile), true, "trust_forge_blessing_devoted")
	profile.add_npc_trust(&"ayan", -0.5)
	t.call(TrustData.forge_blessing(profile), false, "trust_forge_blessing_needs_devoted")

	# A null profile is always neutral rather than an error.
	t.call(TrustData.shop_discount(null), 0.0, "trust_shop_discount_null")
	t.call(TrustData.forge_discount(null), 0.0, "trust_forge_discount_null")
	t.call(TrustData.forge_blessing(null), false, "trust_forge_blessing_null")
	profile.free()


func _test_start_pages(t: Callable) -> void:
	var profile := Profile.new()
	t.call(TrustData.start_pages(profile), 0, "trust_pages_empty")
	profile.add_npc_trust(&"luchen", 2.0)
	t.call(TrustData.start_pages(profile), 1, "trust_pages_acquainted")
	profile.add_npc_trust(&"ayan", 6.0)
	t.call(TrustData.start_pages(profile), 4, "trust_pages_two_npcs")
	profile.add_npc_trust(&"guru", 12.0)
	t.call(TrustData.start_pages(profile), 10, "trust_pages_devoted_adds_six")
	for npc_id in [&"wenjin", &"baiyu"]:
		profile.add_npc_trust(npc_id, 12.0)
	t.call(TrustData.start_pages(profile), TrustData.START_PAGES_CAP,
		"trust_pages_capped")
	t.call(TrustData.start_pages(null), 0, "trust_pages_null")
	profile.free()


func _test_attitude_lines(t: Callable) -> void:
	for npc_id in TRUST_IDS:
		var seen: Dictionary = {}
		for tier in TrustData.TIER_COUNT:
			var line := NPCProfiles.trust_line(npc_id, tier)
			t.call(line.is_empty(), false, "trust_line_%s_%d" % [String(npc_id), tier])
			t.call(seen.has(line), false, "trust_line_%s_%d_unique" % [String(npc_id), tier])
			seen[line] = true
	t.call(NPCProfiles.trust_line(&"missing", 0), "", "trust_line_missing_profile")
	t.call(NPCProfiles.trust_line(&"luchen", -3), NPCProfiles.trust_line(&"luchen", 0),
		"trust_line_clamps_low")
	t.call(NPCProfiles.trust_line(&"luchen", 99), NPCProfiles.trust_line(&"luchen", 3),
		"trust_line_clamps_high")


func _test_offline_evaluator(t: Callable) -> void:
	# The offline path must stay playable with no trust and reflect tiers when
	# they exist, without changing the mechanical effect.
	var plain := NPCProfiles.resolve(&"luchen", "老师，我想听听名字的事")
	t.call(String(plain.get("reply", "")).contains(NPCProfiles.trust_line(&"luchen", 0)), false,
		"trust_offline_stranger_has_no_attitude")
	t.call(String(plain.get("reply", "")).is_empty(), false, "trust_offline_plain_reply")

	var trusted := NPCProfiles.resolve(&"luchen", "老师，我想听听名字的事", 6.0)
	t.call(String(trusted.get("reply", "")).contains(NPCProfiles.trust_line(&"luchen", 2)), true,
		"trust_offline_trusted_attitude")
	t.call(String(trusted.get("mood", "")), "warm", "trust_offline_trusted_mood")
	t.call(float(trusted.get("effect", {}).get("trust", 0.0)),
		float(plain.get("effect", {}).get("trust", 0.0)),
		"trust_offline_effect_unchanged")

	var devoted := NPCProfiles.resolve(&"ayan", "神，我给你带了酒", 12.0)
	t.call(String(devoted.get("reply", "")).contains(NPCProfiles.trust_line(&"ayan", 3)), true,
		"trust_offline_devoted_attitude")
	var abyssal := NPCProfiles.resolve(&"guru", "不可名状的咕噜嘎啦", 12.0)
	t.call(String(abyssal.get("mood", "")), "abyssal", "trust_offline_abyssal_stays_abyssal")


func _test_ai_prompt(t: Callable) -> void:
	var plain := NPCProfiles.get_profile(&"ayan")
	var config := {
		"provider": "openai",
		"endpoint": "http://127.0.0.1:1234/v1/chat/completions",
		"model": "local-model",
		"api_key": "",
	}
	var without := str(AIService.build_npc_request("openai", "你好", plain, config)["body"])
	t.call(without.contains("信任层级"), false, "trust_ai_prompt_absent_by_default")

	var with_trust := NPCProfiles.get_profile(&"ayan")
	with_trust["trust_tier"] = "托付"
	with_trust["trust_attitude"] = NPCProfiles.trust_line(&"ayan", 3)
	var body := str(AIService.build_npc_request("openai", "你好", with_trust, config)["body"])
	t.call(body.contains("信任层级"), true, "trust_ai_prompt_has_tier")
	t.call(body.contains("托付"), true, "trust_ai_prompt_has_tier_name")
	t.call(body.contains(NPCProfiles.trust_line(&"ayan", 3)), true,
		"trust_ai_prompt_has_attitude")
	t.call(body.contains("锻造之神"), true, "trust_ai_prompt_keeps_identity")


func _test_old_save_compatibility(t: Callable) -> void:
	# Old profiles have no tier keys at all; loading them must leave every NPC
	# at 陌生 and every derived benefit at zero.
	var path := "user://test_trust_old_save.cfg"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var config := ConfigFile.new()
	config.set_value("meta", "version", 2)
	config.set_value("progress", "memory_fragments", 11)
	config.set_value("npc", "trust", {"luchen": 3.0})
	config.save(path)
	var profile := Profile.new()
	t.call(profile.load_profile(path), true, "trust_old_save_loads")
	t.call(TrustData.tier_for(profile, &"luchen"), 1, "trust_old_save_value_reads")
	t.call(TrustData.tier_for(profile, &"ayan"), 0, "trust_old_save_missing_npc")
	t.call(TrustData.start_pages(profile), 1, "trust_old_save_pages")
	t.call(TrustData.shop_discount(profile), 0.0, "trust_old_save_shop")
	profile.save_profile(path)
	var reloaded := Profile.new()
	t.call(reloaded.load_profile(path), true, "trust_old_save_roundtrip")
	t.call(TrustData.tier_for(reloaded, &"luchen"), 1, "trust_old_save_roundtrip_value")
	profile.free()
	reloaded.free()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
