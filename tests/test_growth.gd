extends RefCounted

## Permanent growth, difficulty tiers and the bounded authority AI has over NPCs.

func run(t: Callable) -> void:
	_test_difficulty(t)
	_test_archive(t)
	_test_word_mastery(t)
	_test_ai_actions(t)


func _test_difficulty(t: Callable) -> void:
	t.call(Difficulty.count(), 4, "difficulty_has_four_tiers")
	t.call(Difficulty.display_name(0), "平静", "difficulty_first_name")
	t.call(Difficulty.display_name(3), "噩梦", "difficulty_last_name")
	t.call(Difficulty.enemy_health(3) > Difficulty.enemy_health(0), true, "difficulty_health_rises")
	t.call(Difficulty.enemy_damage(3) > Difficulty.enemy_damage(1), true, "difficulty_damage_rises")
	t.call(Difficulty.reward_multiplier(3) > 1.0, true, "difficulty_rewards_rise")
	t.call(Difficulty.corruption_multiplier(3) > Difficulty.corruption_multiplier(0), true, "difficulty_corruption_rises")
	t.call(Difficulty.display_name(99), "噩梦", "difficulty_clamps_high")


func _test_archive(t: Callable) -> void:
	var profile := Profile.new()
	profile.memory_fragments = 1000
	var first := ArchiveData.cost(&"vitality", 0)
	var second := ArchiveData.cost(&"vitality", 1)
	t.call(first > 0, true, "archive_cost_positive")
	t.call(second > first, true, "archive_cost_grows")
	t.call(profile.buy_archive_level(&"vitality", 999999), false, "archive_rejects_insufficient_fragments")
	t.call(profile.buy_archive_level(&"vitality", first), true, "archive_buys_level")
	t.call(profile.archive_level(&"vitality"), 1, "archive_level_rises")
	t.call(profile.memory_fragments, 1000 - first, "archive_deducts_fragments")
	t.call(profile.buy_archive_level(&"missing", first), false, "archive_rejects_unknown_track")
	profile.memory_fragments = 0
	t.call(profile.buy_archive_level(&"ink", 1), false, "archive_rejects_empty_purse")
	profile.free()


func _test_word_mastery(t: Callable) -> void:
	var profile := Profile.new()
	profile.add_word_mastery(&"yan", 25)
	t.call(profile.word_mastery_level(&"yan"), 5, "mastery_level_from_xp")
	t.call(profile.word_mastery_power_bonus(&"yan") > 0.0, true, "mastery_grants_power")
	t.call(profile.word_mastery_ink_discount(&"yan") > 0.0, true, "mastery_discounts_ink")
	profile.add_word_mastery(&"__concept_fire", 50)
	t.call(profile.word_mastery_level(&"__concept_fire"), 0, "mastery_ignores_borrowed_words")
	profile.add_word_mastery(&"yan", 1000)
	var high := profile.word_mastery_ink_discount(&"yan")
	t.call(high <= 0.3, true, "mastery_discount_is_capped")
	t.call(high > 0.2, true, "mastery_keeps_growing")
	profile.free()


func _test_ai_actions(t: Callable) -> void:
	var shop := NPCProfiles.validate_action(&"guru", {"id": "shop", "discount": 0.2})
	t.call(String(shop.get("id", "")), "shop", "ai_action_accepts_npc_function")
	t.call(is_equal_approx(float(shop.get("discount", 0.0)), 0.2), true, "ai_action_keeps_discount")
	var capped := NPCProfiles.validate_action(&"ayan", {"id": "forge", "discount": 9.0})
	t.call(is_equal_approx(float(capped.get("discount", 0.0)), 0.35), true, "ai_action_clamps_discount")
	var wrong_npc := NPCProfiles.validate_action(&"guru", {"id": "forge"})
	t.call(wrong_npc.is_empty(), true, "ai_action_rejects_other_npc_function")
	var unknown := NPCProfiles.validate_action(&"guru", {"id": "delete_save"})
	t.call(unknown.is_empty(), true, "ai_action_rejects_unknown_function")
	var parsed := AIService.parse_npc_response("ollama", JSON.stringify({
		"message": {"content": "{\"reply\":\"好说\",\"mood\":\"warm\",\"action\":{\"id\":\"shop\",\"discount\":0.2}}"},
	}))
	t.call(String(parsed.get("action", {}).get("id", "")), "shop", "ai_parse_action")
