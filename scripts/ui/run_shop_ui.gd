class_name RunShopUI
extends Control

signal buy(index: int)
signal closed

const DEFAULT_SUBTITLE := "纸人只收残页。买完这一页，它就会翻过去。"

var _cards: VBoxContainer
var _pages_label: Label
var _subtitle: Label
var _error_label: Label
var _close_button: Button
var _offers: Array[Dictionary] = []
var _buttons: Array[Button] = []
## Cards are reused across opens: adding a Button with text to the tree makes
## Godot shape it during ENTER_TREE (~10 ms per card measured); adding it empty
## and setting the text afterwards is near-free.
var _pool: Array[Button] = []

func _ready() -> void:
	if _cards != null:
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title := Label.new()
	title.text = "残页交易所"
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	_subtitle = Label.new()
	_subtitle.text = DEFAULT_SUBTITLE
	_subtitle.add_theme_color_override("font_color", UIPalette.INK_SOFT)
	_subtitle.add_theme_font_size_override("font_size", 12)
	column.add_child(_subtitle)
	_pages_label = Label.new()
	_pages_label.add_theme_color_override("font_color", UIPalette.SEAL_GOLD)
	_pages_label.add_theme_font_size_override("font_size", 12)
	column.add_child(_pages_label)
	_cards = VBoxContainer.new()
	_cards.add_theme_constant_override("separation", 8)
	column.add_child(_cards)
	_error_label = Label.new()
	_error_label.add_theme_color_override("font_color", UIPalette.CINNABAR)
	_error_label.add_theme_font_size_override("font_size", 12)
	column.add_child(_error_label)
	_close_button = Button.new()
	_close_button.pressed.connect(close_shop)
	column.add_child(_close_button)
	_refresh_close_hint()
	var flow := _flow_node()
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)
	hide()

func open_shop(offers: Array[Dictionary], pages: int, paper_line := "") -> void:
	if _cards == null:
		_ready()
	_refresh_close_hint()
	_offers = offers.duplicate()
	_subtitle.text = paper_line if not paper_line.is_empty() else DEFAULT_SUBTITLE
	_error_label.text = ""
	_rebuild(pages)
	show()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	_focus_first_pressable()

func set_pages(pages: int) -> void:
	_pages_label.text = "持有残页：%d" % pages
	for index in _buttons.size():
		if index < _offers.size():
			_buttons[index].disabled = bool(_offers[index].get("bought", false)) or pages < int(_offers[index].get("cost", 0))

func mark_bought(index: int, pages: int, sale_line := "") -> void:
	if index < _offers.size():
		_offers[index]["bought"] = true
		_buttons[index].text = "已带走：" + String(_offers[index]["title"])
		_buttons[index].disabled = true
	_error_label.add_theme_color_override("font_color", UIPalette.SEAL_GOLD)
	_error_label.text = sale_line if not sale_line.is_empty() else "成交。"
	set_pages(pages)
	# Buying can also drop the remaining pages below another row's price. Move
	# focus off the disabled row so a controller can keep shopping with A.
	_focus_next_pressable(index)

## A focused disabled Button swallows A, which reads as a frozen shop. Land on
## the first affordable row instead, and on the close button when nothing is
## affordable.
func _focus_first_pressable() -> void:
	if not is_inside_tree():
		return
	for button in _buttons:
		if not button.disabled:
			button.grab_focus()
			return
	if _close_button != null:
		_close_button.grab_focus()


func _focus_next_pressable(from_index: int) -> void:
	if not is_inside_tree() or not visible:
		return
	if not _buttons.is_empty():
		for offset in range(1, _buttons.size() + 1):
			var index := (from_index + offset) % _buttons.size()
			if not _buttons[index].disabled:
				_buttons[index].grab_focus()
				return
	if _close_button != null:
		_close_button.grab_focus()


func _flow_node() -> GameFlow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("Flow") as GameFlow
	return null


func _refresh_close_hint() -> void:
	if _close_button == null:
		return
	var flow := _flow_node()
	var key := flow.close_prompt() if flow != null else "Esc"
	_close_button.text = "离开交易所 [%s]" % key


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_close_hint()


func show_error(text: String) -> void:
	_error_label.add_theme_color_override("font_color", UIPalette.CINNABAR)
	_error_label.text = text

func close_shop() -> void:
	hide()
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()

func _rebuild(pages: int) -> void:
	_buttons.clear()
	for index in _offers.size():
		var offer := _offers[index]
		var button: Button
		if index < _pool.size():
			button = _pool[index]
		else:
			button = Button.new()
			button.custom_minimum_size = Vector2(0, 64)
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.pressed.connect(_on_card_pressed.bind(index))
			# Enter the tree before assigning text; see _pool.
			_cards.add_child(button)
			_pool.append(button)
		button.visible = true
		var bought := bool(offer.get("bought", false))
		button.text = "%s（%d 残页）\n%s" % [offer["title"], int(offer["cost"]), offer["description"]]
		button.disabled = bought or pages < int(offer["cost"])
		_buttons.append(button)
	for index in range(_offers.size(), _pool.size()):
		_pool[index].visible = false
		_pool[index].disabled = true
	set_pages(pages)


func _on_card_pressed(index: int) -> void:
	buy.emit(index)
