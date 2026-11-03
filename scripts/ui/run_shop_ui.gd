class_name RunShopUI
extends Control

signal buy(index: int)
signal closed

var _cards: VBoxContainer
var _pages_label: Label
var _error_label: Label
var _offers: Array[Dictionary] = []
var _buttons: Array[Button] = []

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
	var subtitle := Label.new()
	subtitle.text = "纸人只收残页。买完这一页，它就会翻过去。"
	subtitle.add_theme_color_override("font_color", UIPalette.INK_SOFT)
	subtitle.add_theme_font_size_override("font_size", 12)
	column.add_child(subtitle)
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
	var close := Button.new()
	close.text = "离开交易所 [Esc]"
	close.pressed.connect(close_shop)
	column.add_child(close)
	hide()

func open_shop(offers: Array[Dictionary], pages: int) -> void:
	if _cards == null:
		_ready()
	_offers = offers.duplicate()
	_error_label.text = ""
	_rebuild(pages)
	show()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	if _buttons.size() > 0 and is_inside_tree():
		_buttons[0].grab_focus()

func set_pages(pages: int) -> void:
	_pages_label.text = "持有残页：%d" % pages
	for index in _buttons.size():
		if index < _offers.size():
			_buttons[index].disabled = bool(_offers[index].get("bought", false)) or pages < int(_offers[index].get("cost", 0))

func mark_bought(index: int, pages: int) -> void:
	if index < _offers.size():
		_offers[index]["bought"] = true
		_buttons[index].text = "已带走：" + String(_offers[index]["title"])
		_buttons[index].disabled = true
	_error_label.text = "成交。"
	set_pages(pages)

func show_error(text: String) -> void:
	_error_label.text = text

func close_shop() -> void:
	hide()
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		close_shop()
		get_viewport().set_input_as_handled()

func _rebuild(pages: int) -> void:
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	_buttons.clear()
	for index in _offers.size():
		var offer := _offers[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 64)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var bought := bool(offer.get("bought", false))
		button.text = "%s（%d 残页）\n%s" % [offer["title"], int(offer["cost"]), offer["description"]]
		button.disabled = bought or pages < int(offer["cost"])
		button.pressed.connect(func(): buy.emit(index))
		_cards.add_child(button)
		_buttons.append(button)
	set_pages(pages)
