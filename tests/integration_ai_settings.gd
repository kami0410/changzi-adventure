extends SceneTree

## AI settings page: provider switching, saving, config gating and the
## status/error text. No test opens a network connection; request building and
## response parsing are covered by the unit suite.

var failures: int = 0
var assertions: int = 0

const AI_PATH := "user://test_ai_settings.cfg"


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("AI SETTINGS FAIL: " + label)


func _initialize() -> void:
	_run.call_deferred()


func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = AI_PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _press_button(button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame


func _release_button(button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	await process_frame


func _run() -> void:
	_cleanup()
	var ai := root.get_node("AI") as AIService
	ai.config_path = AI_PATH
	ai.load_config()
	check(ai.config == AIService.normalized_config(AIService.DEFAULT_CONFIG), "ai_settings_starts_with_defaults")

	# Entry focus: keyboard lands on the endpoint field, a pad lands on the
	# enable switch instead of a text box it cannot type into.
	var flow := root.get_node("Flow") as GameFlow
	check(not flow.using_gamepad, "ai_settings_starts_keyboard")
	var focus_ui := AISettingsUI.new()
	root.add_child(focus_ui)
	await process_frame
	focus_ui.open()
	await process_frame
	check(root.gui_get_focus_owner() == focus_ui._endpoint, "ai_settings_keyboard_entry_focus")
	focus_ui.close_page()
	await process_frame
	await _press_button(JOY_BUTTON_DPAD_DOWN)
	await _release_button(JOY_BUTTON_DPAD_DOWN)
	check(flow.using_gamepad, "ai_settings_pad_detected")
	focus_ui.open()
	await process_frame
	check(root.gui_get_focus_owner() == focus_ui._enabled, "ai_settings_pad_entry_focus")
	await _press_button(JOY_BUTTON_A)
	await _release_button(JOY_BUTTON_A)
	check(focus_ui._enabled.button_pressed, "ai_settings_pad_a_toggles_enable")
	focus_ui._enabled.button_pressed = false
	focus_ui.close_page()
	root.remove_child(focus_ui)
	focus_ui.free()
	await process_frame

	var ui := AISettingsUI.new()
	root.add_child(ui)
	await process_frame
	var closed_events: Array[int] = []
	ui.closed.connect(func(): closed_events.append(1))
	ui.open()
	await process_frame

	# Defaults shown in the form.
	check(ui._provider.selected == 0, "ai_settings_default_provider_ollama")
	check(ui._endpoint.text == "http://127.0.0.1:11434/api/chat", "ai_settings_default_endpoint")
	check(ui._model.text == "qwen2.5:7b", "ai_settings_default_model")
	check(not ui._enabled.button_pressed, "ai_settings_default_disabled")
	check(String(ui._status.text).contains("未启用"), "ai_settings_status_unconfigured")

	# Provider switching fills that provider's defaults.
	ui._provider.select(1)
	ui._provider.item_selected.emit(1)
	await process_frame
	check(ui._provider.selected == 1, "ai_settings_provider_openai_selected")
	check(ui._endpoint.text == "http://127.0.0.1:1234/v1/chat/completions", "ai_settings_openai_endpoint")
	check(ui._model.text == "local-model", "ai_settings_openai_model")
	ui._provider.select(2)
	ui._provider.item_selected.emit(2)
	await process_frame
	check(ui._provider.selected == 2, "ai_settings_provider_anthropic_selected")
	check(ui._endpoint.text == "https://api.anthropic.com/v1/messages", "ai_settings_anthropic_endpoint")
	check(ui._model.text == "claude-opus-5-5", "ai_settings_anthropic_model")
	ui._provider.select(0)
	ui._provider.item_selected.emit(0)
	await process_frame
	check(ui._endpoint.text == "http://127.0.0.1:11434/api/chat", "ai_settings_ollama_endpoint_restored")

	# Anthropic without a key is enabled but not configured; test connection
	# must stop at the local gate instead of calling the endpoint.
	ui._provider.select(2)
	ui._provider.item_selected.emit(2)
	await process_frame
	ui._enabled.button_pressed = true
	ui._key.text = ""
	ui._save()
	await process_frame
	check(ai.config["provider"] == "anthropic", "ai_settings_save_provider")
	check(bool(ai.config["enabled"]), "ai_settings_save_enabled")
	check(not ai.is_configured(), "ai_settings_anthropic_without_key_not_configured")
	check(String(ui._status.text).contains("离线推演"), "ai_settings_save_unconfigured_status")
	ui._test()
	await process_frame
	check(String(ui._status.text).contains("尚未配置完整"), "ai_settings_test_blocks_unconfigured")
	check(String(ui._status.text).contains("Anthropic"), "ai_settings_test_mentions_anthropic_key")

	# Saving a complete Anthropic config persists to the configured path.
	ui._key.text = "test-key-not-a-real-secret"
	ui._save()
	await process_frame
	check(ai.is_configured(), "ai_settings_anthropic_with_key_configured")
	check(String(ui._status.text).contains("已保存"), "ai_settings_save_status")
	check(FileAccess.file_exists(AI_PATH), "ai_settings_writes_config_file")
	var reloaded := AIService.new()
	reloaded.config_path = AI_PATH
	reloaded.load_config()
	check(reloaded.config["provider"] == "anthropic", "ai_settings_persisted_provider")
	check(reloaded.config["api_key"] == "test-key-not-a-real-secret", "ai_settings_persisted_key")
	check(reloaded.config["endpoint"] == "https://api.anthropic.com/v1/messages", "ai_settings_persisted_endpoint")
	check(reloaded.config["model"] == "claude-opus-5-5", "ai_settings_persisted_model")
	reloaded.free()

	# Reopening the page reflects the saved config.
	ui.close_page()
	await process_frame
	check(closed_events.size() == 1, "ai_settings_close_emits")
	check(not ui.visible, "ai_settings_close_hides")
	ui.open()
	await process_frame
	check(ui._provider.selected == 2, "ai_settings_reopen_provider")
	check(ui._key.text == "test-key-not-a-real-secret", "ai_settings_reopen_key")
	check(ui._enabled.button_pressed, "ai_settings_reopen_enabled")
	check(String(ui._status.text).contains("已启用"), "ai_settings_reopen_status_enabled")

	# Status lines for a successful and a failed test (no HTTP involved).
	ui._on_test_ready("让雷落在火里", {"name": "雷落", "shape": "blade"})
	check(String(ui._status.text).contains("AI 可用：雷落 / blade"), "ai_settings_ready_status")
	ui._on_test_failed("让雷落在火里", "网络失败（1）")
	check(String(ui._status.text).contains("连接失败：网络失败（1）"), "ai_settings_failed_status")

	# Real controller B closes the standalone page.
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(not ui.visible, "ai_settings_b_closes")
	check(closed_events.size() == 2, "ai_settings_b_emits_close")
	await _press_button(JOY_BUTTON_B)
	await _release_button(JOY_BUTTON_B)
	check(closed_events.size() == 2, "ai_settings_b_closed_is_noop")

	# Ollama and OpenAI both work without a key.
	ui.open()
	await process_frame
	ui._provider.select(1)
	ui._provider.item_selected.emit(1)
	await process_frame
	ui._enabled.button_pressed = true
	ui._key.text = ""
	ui._save()
	await process_frame
	check(ai.is_configured(), "ai_settings_openai_without_key_configured")
	ui._provider.select(0)
	ui._provider.item_selected.emit(0)
	await process_frame
	ui._save()
	await process_frame
	check(ai.config["provider"] == "ollama", "ai_settings_ollama_saved")
	check(ai.is_configured(), "ai_settings_ollama_without_key_configured")

	root.remove_child(ui)
	ui.free()
	_cleanup()
	print("AI SETTINGS INTEGRATION: %d checks, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
