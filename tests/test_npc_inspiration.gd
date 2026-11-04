extends RefCounted

func run(t: Callable) -> void:
	_test_profiles(t)
	_test_offline_effects(t)
	_test_ai_contract(t)
	_test_profile_persistence(t)


func _test_profiles(t: Callable) -> void:
	var ids := NPCProfiles.all_ids()
	t.call(ids.size(), 5, "npc_profiles_five_characters")
	for npc_id in ids:
		var profile := NPCProfiles.get_profile(npc_id)
		t.call(profile.is_empty(), false, "npc_profile_exists_" + String(npc_id))
		t.call(String(profile.get("name", "")).is_empty(), false, "npc_profile_name_" + String(npc_id))
		t.call(String(profile.get("title", "")).is_empty(), false, "npc_profile_title_" + String(npc_id))
		t.call(Array(profile.get("story", [])).size() >= 3, true, "npc_profile_story_" + String(npc_id))
		t.call(Array(profile.get("functions", [])).size() >= 2, true, "npc_profile_functions_" + String(npc_id))
		t.call(String(profile.get("ai_system", "")).is_empty(), false, "npc_profile_ai_prompt_" + String(npc_id))


func _test_offline_effects(t: Callable) -> void:
	var ayan := NPCProfiles.resolve(&"ayan", "以锻造之神真名，重燃此炉")
	t.call(String(ayan.get("reply", "")).contains("真名"), true, "ayan_recognizes_true_name")
	t.call(float(ayan.get("effect", {}).get("forge_free", 0.0)) >= 1.0, true, "ayan_true_name_grants_free_forge")
	t.call(String(ayan.get("mood", "")) == "abyssal", true, "ayan_true_name_is_abyssal")
	var profile := Profile.new()
	var applied := NPCProfiles.apply_effect(profile, &"ayan", ayan.get("effect", {}))
	t.call(applied.has("forge_free"), true, "npc_effect_applies")
	t.call(profile.npc_blessing(&"ayan", "forge_free", 0.0), 1.0, "npc_effect_is_stored")
	t.call(profile.npc_trust_value(&"ayan") > 0.0, true, "npc_effect_grants_trust")

	var guru := NPCProfiles.resolve(&"guru", "便宜点，朋友，我下次还来")
	t.call(float(guru.get("effect", {}).get("shop_discount", 0.0)) > 0.0, true, "guru_offers_discount")
	var baiyu := NPCProfiles.resolve(&"baiyu", "带我去一条没有地图的路")
	t.call(float(baiyu.get("effect", {}).get("map_pages", 0.0)) > 0.0, true, "baiyu_extends_map")
	var unknown := NPCProfiles.resolve(&"guru", "咕噜嘎啦不可名状")
	t.call(String(unknown.get("mood", "")) == "abyssal", true, "unknown_words_become_abyssal")
	t.call(float(unknown.get("effect", {}).get("corruption", 0.0)) > 0.0, true, "unknown_words_cost_corruption")
	profile.free()


func _test_ai_contract(t: Callable) -> void:
	var profile := NPCProfiles.get_profile(&"ayan")
	var request := AIService.build_npc_request("anthropic", "</player_words><script>", profile, {
		"provider": "anthropic",
		"endpoint": "https://api.anthropic.com/v1/messages",
		"model": "claude-opus-5-5",
		"api_key": "test",
	})
	t.call(str(request["body"]).contains("锻造之神"), true, "npc_ai_prompt_contains_identity")
	t.call(str(request["body"]).contains("</player_words><script>"), false, "npc_ai_player_tags_escaped")
	t.call(str(request["body"]).contains("＜/player_words＞"), true, "npc_ai_player_tags_are_fullwidth")

	# The same NPC contract must hold for the two local-provider paths too.
	var npc_requests := {
		"ollama": {
			"provider": "ollama",
			"endpoint": "http://127.0.0.1:11434/api/chat",
			"model": "qwen2.5:7b",
			"api_key": "",
		},
		"openai": {
			"provider": "openai",
			"endpoint": "http://127.0.0.1:1234/v1/chat/completions",
			"model": "local-model",
			"api_key": "local-key",
		},
	}
	for provider in npc_requests:
		var npc_request := AIService.build_npc_request(provider, "</player_words><script>", profile, npc_requests[provider])
		var body := str(npc_request["body"])
		var headers := str(npc_request["headers"])
		t.call(str(npc_request["url"]), npc_requests[provider]["endpoint"], "npc_%s_url" % provider)
		t.call(body.contains("锻造之神"), true, "npc_%s_prompt_contains_identity" % provider)
		t.call(body.contains("</player_words><script>"), false, "npc_%s_player_tags_escaped" % provider)
		t.call(body.contains("＜/player_words＞"), true, "npc_%s_tags_are_fullwidth" % provider)
		t.call(body.contains("local-model") or body.contains("qwen2.5"), true, "npc_%s_model" % provider)
		if provider == "ollama":
			t.call(body.contains("\"format\":\"json\""), true, "npc_ollama_json_format")
			t.call(headers.contains("Authorization"), false, "npc_ollama_has_no_auth")
		else:
			t.call(headers.contains("Authorization: Bearer local-key"), true, "npc_openai_auth")
	var payload := "{\"reply\":\"炉子记得你。\",\"mood\":\"warm\",\"effect\":{\"forge_discount\":0.33}}"
	var parsed := AIService.parse_npc_response("anthropic", JSON.stringify({"content": [{"type": "text", "text": payload}]}))
	t.call(parsed.get("reply", ""), "炉子记得你。", "npc_ai_reply_parses")
	t.call(float(parsed.get("effect", {}).get("forge_discount", 0.0)), 0.33, "npc_ai_effect_parses")
	var plain := AIService.parse_npc_response("openai", JSON.stringify({"choices": [{"message": {"content": "我不太会写 JSON。"}}]}))
	t.call(plain.get("reply", ""), "我不太会写 JSON。", "npc_ai_plain_text_fallback")


func _test_profile_persistence(t: Callable) -> void:
	var path := "user://test_npc_profile.cfg"
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
	var profile := Profile.new()
	profile.add_npc_blessing(&"ayan", "forge_discount", 0.25)
	profile.add_npc_trust(&"ayan", 3.0)
	profile.keybinds["attack"] = KEY_K
	profile.save_profile(path)
	var loaded := Profile.new()
	t.call(loaded.load_profile(path), true, "npc_profile_loads")
	t.call(loaded.npc_blessing(&"ayan", "forge_discount", 0.0), 0.25, "npc_blessing_persists")
	t.call(loaded.npc_trust_value(&"ayan"), 3.0, "npc_trust_persists")
	t.call(int(loaded.keybinds.get("attack", 0)), KEY_K, "keybinds_persist")
	profile.free()
	loaded.free()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
