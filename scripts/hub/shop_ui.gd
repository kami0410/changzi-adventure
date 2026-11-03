class_name ShopUI
extends CanvasLayer

signal purchased(item_id: StringName)
signal purchase_failed(item_id: StringName)
signal closed

var _root: Control = null
var _fragments_label: Label = null
var _items: VBoxContainer = null
var _message_label: Label = null
var _close_button: Button = null
var _nodes_ready := false

var _shop: Shop = null
var _profile: Profile = null
var _message := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_nodes()
	if _root != null:
		_root.visible = false


func bind(shop: Shop, profile: Profile) -> void:
	_shop = shop
	_profile = profile
	if is_open():
		refresh()


func open() -> void:
	_ensure_nodes()
	_message = "滚轮翻货。只收记忆碎片，不赊账。"
	if _root != null:
		_root.visible = true
	refresh()


func close() -> void:
	if _root == null or not _root.visible:
		return
	_root.visible = false
	closed.emit()


func is_open() -> bool:
	return _root != null and _root.visible


func buy(item_id: StringName) -> bool:
	if _shop == null or _profile == null:
		return false
	var entry := _shop.get_entry(item_id)
	var cost := _shop.price_for(item_id)
	var before := _profile.memory_fragments
	if _shop.buy(item_id, _profile):
		var paid := before - _profile.memory_fragments
		var item_name := String(entry.get("display_name", item_id))
		_message = "买下「%s」。记忆碎片 -%d。" % [item_name, paid]
		refresh()
		purchased.emit(item_id)
		return true
	if entry.is_empty():
		_message = "没有这件货。"
	elif _shop.owned_by(entry, _profile):
		_message = "这件货已经在你的手里了。"
	else:
		_message = "记忆碎片不足：需要 %d，你只有 %d。" % [cost, _profile.memory_fragments]
	if _message_label != null:
		_message_label.text = _message
	purchase_failed.emit(item_id)
	return false


func refresh() -> void:
	_ensure_nodes()
	if _fragments_label != null:
		var fragments := _profile.memory_fragments if _profile != null else 0
		_fragments_label.text = "记忆碎片  %d" % fragments
	if _message_label != null:
		_message_label.text = _message
	_rebuild_items()


func announce(text: String) -> void:
	_message = text
	refresh()


func get_message_text() -> String:
	_ensure_nodes()
	return _message_label.text if _message_label != null else ""


func _ensure_nodes() -> void:
	if _nodes_ready:
		return
	_nodes_ready = true
	_root = find_child("Root", true, false) as Control
	_fragments_label = find_child("Fragments", true, false) as Label
	_items = find_child("Items", true, false) as VBoxContainer
	_message_label = find_child("Message", true, false) as Label
	_close_button = find_child("CloseButton", true, false) as Button
	if _close_button != null and not _close_button.pressed.is_connected(close):
		_close_button.pressed.connect(close)


func _rebuild_items() -> void:
	if _items == null or _shop == null:
		return
	for child in _items.get_children():
		_items.remove_child(child)
		child.queue_free()
	for entry in _shop.stock:
		_items.add_child(_make_row(entry))


func _make_row(entry: Dictionary) -> HBoxContainer:
	var item_id := StringName(entry.get("id", &""))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)

	var name_label := Label.new()
	var glyph := String(entry.get("glyph", ""))
	var display_name := String(entry.get("display_name", String(item_id)))
	name_label.text = ("%s  %s" % [glyph, display_name]).strip_edges()
	name_label.add_theme_font_size_override("font_size", 24)
	info.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = String(entry.get("description", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", UIPalette.INK_SOFT)
	desc_label.custom_minimum_size = Vector2(380.0, 0.0)
	info.add_child(desc_label)
	row.add_child(info)

	var cost_label := Label.new()
	cost_label.text = "%d 碎片" % _shop.price_for(item_id)
	cost_label.add_theme_color_override("font_color", UIPalette.SEAL_GOLD)
	cost_label.custom_minimum_size = Vector2(96.0, 0.0)
	row.add_child(cost_label)

	var button := Button.new()
	button.custom_minimum_size = Vector2(104.0, 44.0)
	if _shop != null and _shop.owned_by(entry, _profile):
		button.text = "已拥有"
		button.disabled = true
	else:
		button.text = "购买"
		button.pressed.connect(_on_buy_pressed.bind(item_id))
	row.add_child(button)
	return row


func _on_buy_pressed(item_id: StringName) -> void:
	buy(item_id)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		if is_inside_tree() and get_viewport() != null:
			get_viewport().set_input_as_handled()
