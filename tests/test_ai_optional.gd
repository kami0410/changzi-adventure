extends RefCounted

## AI is an optional enhancement: off by default, no embedded key, clean
## failure when unconfigured or when the provider returns garbage.

func run(t: Callable) -> void:
	_test_defaults(t)
	_test_unconfigured_request(t)
	_test_configuration_gates(t)
	_test_response_parsing(t)
	_test_settings_reachable_from_title(t)


func _test_defaults(t: Callable) -> void:
	t.call(bool(AIService.DEFAULT_CONFIG.get("enabled", true)), false, "ai_disabled_by_default")
	t.call(String(AIService.DEFAULT_CONFIG.get("api_key", "x")).is_empty(), true, "ai_has_no_embedded_key")
	var normalized := AIService.normalized_config({})
	t.call(bool(normalized.get("enabled", true)), false, "normalized_config_defaults_off")


func _test_unconfigured_request(t: Callable) -> void:
	var ai := AIService.new()
	var failures: Array[String] = []
	ai.intent_failed.connect(func(_sentence: String, error: String): failures.append(error))
	ai.request_intent("让雷落在火里")
	t.call(ai.is_configured(), false, "unconfigured_service")
	t.call(failures.size(), 1, "unconfigured_request_fails_cleanly")
	ai.free()


func _test_configuration_gates(t: Callable) -> void:
	var ai := AIService.new()
	ai.config = AIService.normalized_config({"enabled": false, "endpoint": "http://x", "model": "m"})
	t.call(ai.is_configured(), false, "disabled_service_is_not_configured")
	ai.config = AIService.normalized_config({"enabled": true, "provider": "ollama", "endpoint": "http://127.0.0.1:11434/api/chat", "model": "qwen"})
	t.call(ai.is_configured(), true, "ollama_with_endpoint_is_configured")
	ai.config = AIService.normalized_config({"enabled": true, "provider": "anthropic", "endpoint": "https://x", "model": "m", "api_key": ""})
	t.call(ai.is_configured(), false, "anthropic_without_key_is_not_configured")
	ai.free()


func _test_response_parsing(t: Callable) -> void:
	var bad := AIService.parse_response("ollama", "not json")
	t.call(bad.has("error"), true, "bad_json_is_rejected")
	var content := JSON.stringify({"name": "测试言灵", "shape": "flame", "tags": ["flame"], "components": {"damage": 10}})
	var raw := JSON.stringify({"message": {"content": content}})
	var good := AIService.parse_response("ollama", raw)
	t.call(not good.has("error"), true, "valid_json_is_accepted")
	t.call(good.get("shape", &""), &"flame", "valid_json_shape")


func _test_settings_reachable_from_title(t: Callable) -> void:
	var hub := Hub.new()
	hub.profile = Profile.new()
	var title := TitleScreen.new()
	hub.add_child(title)
	title._build()
	hub._connect_title_settings()
	var button := title.find_child("SettingsButton", true, false)
	t.call(button != null, true, "title_has_settings_button")
	if button != null:
		button.pressed.emit()
		t.call(hub.settings_menu != null, true, "hub_creates_settings_menu")
		if hub.settings_menu != null:
			t.call(hub.settings_menu.visible, true, "settings_open_from_title")
			hub.settings_menu.close()
	hub.free()
