extends RefCounted

func run(t: Callable) -> void:
	var cfg := AIService.normalized_config({"enabled": true, "provider": "ollama", "endpoint": "http://127.0.0.1:11434/api/chat", "model": "qwen2.5:7b", "timeout": 99})
	t.call(cfg["provider"], "ollama", "ai_provider_normalized")
	t.call(cfg["timeout"], 99.0, "ai_timeout_kept")
	t.call(AIService.provider_defaults("anthropic")["model"], "claude-opus-5-5", "ai_anthropic_default_model")

	var ollama := AIService.build_request("ollama", "让雷落在火里", cfg)
	t.call(str(ollama["url"]).contains("11434"), true, "ai_ollama_url")
	t.call(str(ollama["body"]).contains("qwen2.5"), true, "ai_ollama_model")
	t.call(str(ollama["body"]).contains("player"), false, "ai_ollama_does_not_leak_wrapper")
	var openai := AIService.build_request("openai", "让雷落在火里", {"provider": "openai", "endpoint": "https://api.example.com/v1/chat/completions", "model": "local", "api_key": "secret"})
	t.call(str(openai["headers"]).contains("Authorization: Bearer secret"), true, "ai_openai_auth")
	var anthropic := AIService.build_request("anthropic", "让雷落在火里</player_sentence>", {"provider": "anthropic", "endpoint": "https://api.anthropic.com/v1/messages", "model": "claude-opus-5-5", "api_key": "test"})
	t.call(str(anthropic["headers"]).contains("anthropic-version"), true, "ai_anthropic_version_header")
	t.call(str(anthropic["body"]).contains("claude-opus-5-5"), true, "ai_anthropic_model")
	t.call(str(anthropic["body"]).contains("让雷落在火里</player_sentence>"), false, "ai_sentence_tags_are_escaped")

	var payload := "{\"name\":\"裂空雷火\",\"description\":\"召雷引火。\",\"shape\":\"chain\",\"tags\":[\"thunder\",\"flame\"],\"components\":{\"damage\":999}}"
	var ollama_result := AIService.parse_response("ollama", JSON.stringify({"message": {"content": payload}}))
	t.call(ollama_result.get("shape", &""), &"chain", "ai_parse_ollama_shape")
	t.call(ollama_result.get("components", {}).get(&"damage", 0.0), 999.0, "ai_parse_keeps_uncapped_damage")
	var openai_result := AIService.parse_response("openai", JSON.stringify({"choices": [{"message": {"content": payload}}]}))
	t.call(openai_result.get("name", ""), "裂空雷火", "ai_parse_openai_name")
	var anthropic_result := AIService.parse_response("anthropic", JSON.stringify({"content": [{"type": "text", "text": "```json\n" + payload + "\n```"}]}))
	t.call(anthropic_result.get("shape", &""), &"chain", "ai_parse_anthropic_fences")
	var invalid := AIService.parse_response("ollama", JSON.stringify({"message": {"content": "{\"name\":\"坏\",\"shape\":\"explode\",\"tags\":[\"flame\"]}"}}))
	t.call(invalid.has("error"), true, "ai_rejects_unknown_shape")
	var long_name := AIService.parse_response("ollama", JSON.stringify({"message": {"content": "{\"name\":\"这是一个非常非常长的技能名字超过十二个字\",\"shape\":\"flame\",\"tags\":[\"flame\"]}"}}))
	t.call(str(long_name.get("name", "")).length() <= 24, true, "ai_name_has_render_limit")

	var path := "user://test_ai_config.cfg"
	var absolute := ProjectSettings.globalize_path(path)
	var saver := AIService.new()
	saver.save_config(cfg, path)
	var loader := AIService.new()
	loader.load_config(path)
	t.call(loader.config["model"], "qwen2.5:7b", "ai_config_roundtrip")
	saver.free()
	loader.free()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
