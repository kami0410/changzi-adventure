class_name AISettingsUI
extends Control

var _ai: AIService
var _enabled: CheckButton
var _provider: OptionButton
var _endpoint: LineEdit
var _model: LineEdit
var _key: LineEdit
var _timeout: SpinBox
var _status: Label
var _ready_built := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _ready_built:
		return
	_ready_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = preload("res://resources/ui/theme.tres")
	var shade := ColorRect.new()
	shade.color = UIPalette.SHADE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var title := Label.new()
	title.text = "AI 言灵"
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	var privacy := Label.new()
	privacy.text = "只有你点“AI 解读”时，当前这句话才会发送到下面配置的服务。密钥只保存在本机 user://，不会打进游戏包。没有配置时游戏仍使用离线推演。"
	privacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	privacy.add_theme_color_override("font_color", UIPalette.INK_SOFT)
	privacy.add_theme_font_size_override("font_size", 12)
	column.add_child(privacy)
	_enabled = CheckButton.new()
	_enabled.text = "启用 AI 解读"
	column.add_child(_enabled)
	var provider_row := HBoxContainer.new()
	provider_row.add_theme_constant_override("separation", 8)
	var provider_label := Label.new()
	provider_label.text = "服务"
	provider_label.custom_minimum_size = Vector2(72, 0)
	provider_row.add_child(provider_label)
	_provider = OptionButton.new()
	_provider.add_item("Ollama（本地）", 0)
	_provider.add_item("OpenAI 兼容接口", 1)
	_provider.add_item("Anthropic", 2)
	_provider.item_selected.connect(_on_provider_selected)
	provider_row.add_child(_provider)
	column.add_child(provider_row)
	_endpoint = _add_field(column, "接口地址", "http://127.0.0.1:11434/api/chat")
	_model = _add_field(column, "模型", "qwen2.5:7b")
	_key = _add_field(column, "密钥（Anthropic 必填）", "")
	_key.secret = true
	var timeout_row := HBoxContainer.new()
	var timeout_label := Label.new()
	timeout_label.text = "超时（秒）"
	timeout_label.custom_minimum_size = Vector2(120, 0)
	timeout_row.add_child(timeout_label)
	_timeout = SpinBox.new()
	_timeout.min_value = 3
	_timeout.max_value = 120
	_timeout.step = 1
	_timeout.value = 25
	timeout_row.add_child(_timeout)
	column.add_child(timeout_row)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	var save := Button.new()
	save.text = "保存"
	save.pressed.connect(_save)
	buttons.add_child(save)
	var test := Button.new()
	test.text = "测试连接"
	test.pressed.connect(_test)
	buttons.add_child(test)
	var close := Button.new()
	close.text = "关闭"
	close.pressed.connect(func(): hide())
	buttons.add_child(close)
	column.add_child(buttons)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_color_override("font_color", UIPalette.SEAL_GOLD)
	_status.add_theme_font_size_override("font_size", 12)
	column.add_child(_status)
	hide()

func open() -> void:
	if not _ready_built:
		_ready()
	_ai = get_node_or_null("/root/AI") as AIService
	if _ai != null:
		var cfg := _ai.config
		_enabled.button_pressed = bool(cfg.get("enabled", false))
		var provider := String(cfg.get("provider", "ollama"))
		_provider.select(maxi(AIService.PROVIDERS.find(provider), 0))
		_endpoint.text = String(cfg.get("endpoint", ""))
		_model.text = String(cfg.get("model", ""))
		_key.text = String(cfg.get("api_key", ""))
		_timeout.value = float(cfg.get("timeout", 25.0))
	show()
	_status.text = "当前：%s" % ("已启用" if _ai != null and _ai.is_configured() else "未启用或缺少配置")
	if _endpoint != null:
		_endpoint.grab_focus()

func _add_field(parent: Node, label_text: String, placeholder: String) -> LineEdit:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_theme_font_size_override("font_size", 12)
	row.add_child(field)
	parent.add_child(row)
	return field

func _on_provider_selected(index: int) -> void:
	var provider := AIService.PROVIDERS[clampi(index, 0, AIService.PROVIDERS.size() - 1)]
	var defaults := AIService.provider_defaults(provider)
	_endpoint.text = String(defaults["endpoint"])
	_model.text = String(defaults["model"])

func _save() -> void:
	if _ai == null:
		_ai = get_node_or_null("/root/AI") as AIService
	if _ai == null:
		_status.text = "AI 服务不可用"
		return
	var cfg := {
		"enabled": _enabled.button_pressed,
		"provider": AIService.PROVIDERS[clampi(_provider.selected, 0, AIService.PROVIDERS.size() - 1)],
		"endpoint": _endpoint.text.strip_edges(),
		"model": _model.text.strip_edges(),
		"api_key": _key.text.strip_edges(),
		"timeout": _timeout.value,
	}
	_ai.save_config(cfg)
	_status.text = "已保存。" + ("点“测试连接”再试一句。" if _ai.is_configured() else "当前未启用，游戏会继续使用离线推演。")

func _test() -> void:
	_save()
	if _ai == null or not _ai.is_configured():
		_status.text = "尚未配置完整：Ollama 需要本地服务与模型；Anthropic 还需要密钥。"
		return
	if not _ai.intent_ready.is_connected(_on_test_ready):
		_ai.intent_ready.connect(_on_test_ready, CONNECT_ONE_SHOT)
	if not _ai.intent_failed.is_connected(_on_test_failed):
		_ai.intent_failed.connect(_on_test_failed, CONNECT_ONE_SHOT)
	_status.text = "正在测试…（只发送示例句）"
	_ai.request_intent("让雷落在火里")

func _on_test_ready(_sentence: String, intent: Dictionary) -> void:
	_status.text = "AI 可用：%s / %s" % [String(intent.get("name", "")), String(intent.get("shape", ""))]
	if _ai != null and _ai.intent_failed.is_connected(_on_test_failed):
		_ai.intent_failed.disconnect(_on_test_failed)

func _on_test_failed(_sentence: String, error: String) -> void:
	_status.text = "连接失败：%s" % error
	if _ai != null and _ai.intent_ready.is_connected(_on_test_ready):
		_ai.intent_ready.disconnect(_on_test_ready)
