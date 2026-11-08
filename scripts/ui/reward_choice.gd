class_name RewardChoice
extends Control

signal chosen(index: int)
signal reroll_requested

const CARD_NORMAL: StyleBox = preload("res://resources/ui/card_common.tres")
const CARD_HOVER: StyleBox = preload("res://resources/ui/card_hover.tres")
const CARD_SELECTED: StyleBox = preload("res://resources/ui/card_selected.tres")
const CARD_FOCUS: StyleBox = preload("res://resources/ui/card_focus.tres")

var _cards: HBoxContainer
var _reroll: Button
var _claimed := false

func _ready() -> void:
	_build()


func _build() -> void:
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
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)
	var caption := Label.new()
	caption.text = "这间房的档案已经肃清"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_color", UIPalette.CYAN)
	column.add_child(caption)
	var title := Label.new()
	title.text = "留下哪一页记忆？"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", UIPalette.BONE)
	column.add_child(title)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 20)
	column.add_child(_cards)
	_reroll = Button.new()
	_reroll.text = "权柄 · 改写（重掷一次）"
	_reroll.custom_minimum_size = Vector2(360, 48)
	_reroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reroll.add_theme_font_size_override("font_size", 24)
	_reroll.pressed.connect(func(): reroll_requested.emit())
	_reroll.hide()
	column.add_child(_reroll)
	var hint := Label.new()
	var flow := get_node_or_null("/root/Flow") as GameFlow
	hint.text = "战斗已暂停。点一页收下。" if flow != null and flow.using_touch else "战斗已暂停。用方向键挑一页，按确认键收下。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", UIPalette.BONE_DIM)
	column.add_child(hint)
	hide()

func set_reroll_available(available: bool) -> void:
	if _reroll != null:
		_reroll.visible = available
		_reroll.disabled = not available


func open_choices(choices: Array[Dictionary]) -> void:
	_build()
	_claimed = false
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for index in choices.size():
		var choice := choices[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(316, 256)
		button.text = ""
		# Paper cards, always opaque: an unchosen page must stay readable on
		# the dark battlefield instead of dissolving into it.
		button.add_theme_stylebox_override("normal", CARD_NORMAL)
		button.add_theme_stylebox_override("disabled", CARD_NORMAL)
		button.add_theme_stylebox_override("hover", CARD_HOVER)
		button.add_theme_stylebox_override("pressed", CARD_SELECTED)
		button.add_theme_stylebox_override("focus", CARD_FOCUS)
		button.pressed.connect(_choose.bind(index))
		_cards.add_child(button)
		var margin := MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left", "top", "right", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 24)
		button.add_child(margin)
		var column := VBoxContainer.new()
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_theme_constant_override("separation", 20)
		margin.add_child(column)
		for text in [_kind_name(choice.get("kind", &"")), choice["title"], choice["description"]]:
			var label := Label.new()
			label.text = text
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_font_size_override("font_size", 24)
			column.add_child(label)
		(column.get_child(0) as Label).add_theme_color_override("font_color", UIPalette.CINNABAR)
		(column.get_child(1) as Label).add_theme_color_override("font_color", UIPalette.INK)
		(column.get_child(2) as Label).add_theme_color_override("font_color", UIPalette.INK_SOFT)
	show()
	if _cards.get_child_count() > 0 and (_cards.get_child(0) as Button).is_inside_tree():
		(_cards.get_child(0) as Button).grab_focus()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)

func _choose(index: int) -> void:
	if _claimed or not visible:
		return
	_claimed = true
	hide()
	chosen.emit(index)

func _kind_name(kind: StringName) -> String:
	match kind:
		&"relic": return "遗物"
		&"word": return "新词"
		&"weapon": return "武器"
		&"vitality": return "生命"
	return "休整"
