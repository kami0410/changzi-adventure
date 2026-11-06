class_name ArchiveUI
extends Control

## The Archive altar: permanent upgrades paid with memory fragments. Opened
## from 陆沉's service list in the hub. Every track stops at
## ArchiveData.MAX_LEVEL in the demo, so a maxed row must say so instead of
## reporting a fragment shortage it can never spend.

signal closed
signal purchased(track_id: StringName)

const THEME = preload("res://resources/ui/theme.tres")

var profile: Profile
var _open := false
var _built := false
var _fragment_label: Label
var _status: Label
var _close_button: Button
var _rows: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()
	_built = true
	_refresh_close_hint()
	var flow := _flow_node()
	if flow != null and not flow.input_device_changed.is_connected(_on_input_device_changed):
		flow.input_device_changed.connect(_on_input_device_changed)


func bind(new_profile: Profile) -> void:
	profile = new_profile
	if not _built:
		_build()
		_built = true
	_refresh()


func open() -> void:
	if not _built:
		_build()
		_built = true
	_open = true
	visible = true
	_refresh_close_hint()
	_refresh()
	_focus_first_pressable()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	closed.emit()


func is_open() -> bool:
	return _open


func _build() -> void:
	if _built:
		return
	var dim := ColorRect.new()
	dim.color = UIPalette.SHADE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 640)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 34)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	margin.add_child(outer)
	var title := Label.new()
	title.text = "档案馆升级"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title)
	var hint := Label.new()
	hint.text = "用记忆碎片永久强化昌子。demo 每个方向上限 %d 级，成本逐级上涨。" % ArchiveData.MAX_LEVEL
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", UIPalette.INK_FAINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(hint)
	_fragment_label = Label.new()
	_fragment_label.add_theme_font_size_override("font_size", 24)
	_fragment_label.add_theme_color_override("font_color", UIPalette.SEAL_GOLD)
	_fragment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(_fragment_label)
	for entry in ArchiveData.TRACKS:
		outer.add_child(_make_track_row(entry))
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", UIPalette.INK_SOFT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_status)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(buttons)
	_close_button = Button.new()
	_close_button.text = "合上档案"
	_close_button.custom_minimum_size = Vector2(260, 44)
	_close_button.add_theme_font_size_override("font_size", 24)
	_close_button.pressed.connect(close)
	buttons.add_child(_close_button)


func _make_track_row(entry: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", preload("res://resources/ui/card_common.tres"))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var name_label := Label.new()
	name_label.text = String(entry.get(&"name", "档案"))
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", UIPalette.INK)
	info.add_child(name_label)
	var desc := Label.new()
	desc.text = String(entry.get(&"description", ""))
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", UIPalette.INK_SOFT)
	info.add_child(desc)
	var level_label := Label.new()
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.add_theme_color_override("font_color", UIPalette.CINNABAR)
	info.add_child(level_label)
	var cost_label := Label.new()
	cost_label.custom_minimum_size = Vector2(110, 0)
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", UIPalette.SEAL_GOLD)
	row.add_child(cost_label)
	var button := Button.new()
	button.custom_minimum_size = Vector2(120, 44)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(func(): _buy(entry))
	row.add_child(button)
	_rows[StringName(entry.get(&"id", &""))] = {
		"level": level_label,
		"cost": cost_label,
		"button": button,
	}
	return card


func _buy(entry: Dictionary) -> void:
	if profile == null or _status == null:
		return
	var track_id := StringName(entry.get(&"id", &""))
	var level := profile.archive_level(track_id)
	if level >= ArchiveData.MAX_LEVEL:
		# The demo cap is a limit, not a price: never answer a maxed row with
		# "记忆碎片不足：需要 X，你只有 Y" when Y is already larger than X.
		_status.text = "「%s」已经修到 demo 上限 Lv.%d。" % [
			String(entry.get(&"name", "档案")), ArchiveData.MAX_LEVEL,
		]
		_refresh()
		return
	var cost := ArchiveData.cost(track_id, level)
	if not profile.buy_archive_level(track_id, cost):
		_status.text = "记忆碎片不足：需要 %d，你只有 %d。" % [cost, profile.memory_fragments]
		_refresh()
		return
	var new_level := profile.archive_level(track_id)
	if new_level >= ArchiveData.MAX_LEVEL:
		# The row now reads 已达上限/已满级, so the status must not quote a
		# "next" price the demo can never charge.
		_status.text = "%s 升至 Lv.%d，已达 demo 上限。" % [
			String(entry.get(&"name", "档案")), new_level,
		]
	else:
		_status.text = "%s 升至 Lv.%d。下次需要 %d 碎片。" % [
			String(entry.get(&"name", "档案")),
			new_level,
			ArchiveData.cost(track_id, new_level),
		]
	purchased.emit(track_id)
	_refresh()


func _refresh() -> void:
	if _fragment_label == null:
		return
	var fragments := profile.memory_fragments if profile != null else 0
	_fragment_label.text = "记忆碎片  %d" % fragments
	for entry in ArchiveData.TRACKS:
		var track_id := StringName(entry.get(&"id", &""))
		var row: Dictionary = _rows.get(track_id, {})
		if row.is_empty():
			continue
		var level := profile.archive_level(track_id) if profile != null else 0
		var cost := ArchiveData.cost(track_id, level)
		var maxed := level >= ArchiveData.MAX_LEVEL
		(row["level"] as Label).text = "Lv.%d" % level
		(row["cost"] as Label).text = "已达上限" if maxed else "%d 碎片" % cost
		var button := row["button"] as Button
		button.text = "已满级" if maxed else "升级"
		# A maxed row can never succeed, so it must not stay pressable (and a
		# disabled row is skipped by _focus_first_pressable).
		button.disabled = maxed or profile == null or profile.memory_fragments < cost
	_keep_focus_pressable()


## A focused disabled Button swallows A, so an early visit with too few
## fragments must not park focus on an unaffordable upgrade row.
func _focus_first_pressable() -> void:
	if not is_inside_tree():
		return
	for entry in ArchiveData.TRACKS:
		var row: Dictionary = _rows.get(StringName(entry.get(&"id", &"")), {})
		var button := row.get("button") as Button
		if button != null and is_instance_valid(button) and not button.disabled:
			button.grab_focus()
			return
	if _close_button != null and is_instance_valid(_close_button):
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
	_close_button.text = "合上档案  [%s]" % key


func _on_input_device_changed(_using_gamepad: bool) -> void:
	_refresh_close_hint()


func _keep_focus_pressable() -> void:
	if not _open or not is_inside_tree():
		return
	var owner := get_viewport().gui_get_focus_owner()
	if owner == null or not is_ancestor_of(owner):
		return
	var button := owner as Button
	if button == null or not button.disabled:
		return
	_focus_first_pressable()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		if is_inside_tree() and get_viewport() != null:
			get_viewport().set_input_as_handled()
