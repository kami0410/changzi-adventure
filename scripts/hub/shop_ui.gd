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
var _return_focus: Control = null


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
	var viewport := get_viewport() if is_inside_tree() else null
	_return_focus = viewport.gui_get_focus_owner() if viewport != null else null
	if _root != null:
		_root.visible = true
	refresh()
	# A controller must land on a real purchase row; without this the page opens
	# with no focus and A/B appear dead until the player uses the mouse.
	_focus_first_item()


func close() -> void:
	if _root == null or not _root.visible:
		return
	_root.visible = false
	var previous := _return_focus
	_return_focus = null
	closed.emit()
	if previous != null and is_instance_valid(previous) and previous.is_inside_tree() and previous.is_visible_in_tree():
		previous.grab_focus()


func _focus_first_item() -> void:
	if not is_inside_tree():
		return
	if _items != null:
		for child in _items.find_children("*", "Button", true, false):
			var button := child as Button
			if button != null and not button.disabled:
				button.grab_focus()
				return
	if _close_button != null:
		_close_button.grab_focus()


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
		_message = ShopFailData.format(ShopFailData.pick(&"missing", item_id))
	elif _shop.owned_by(entry, _profile):
		_message = ShopFailData.format(ShopFailData.pick(&"owned", item_id))
	else:
		_message = ShopFailData.format(
			ShopFailData.pick(&"insufficient", item_id), cost, _profile.memory_fragments)
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
	# Buying rebuilds every row, which frees the button that had focus. Keep the
	# focused item id so A can be pressed again without touching the mouse.
	var focused_id: StringName = &""
	var viewport := get_viewport() if is_inside_tree() else null
	var owner := viewport.gui_get_focus_owner() if viewport != null else null
	if owner != null and _items.is_ancestor_of(owner):
		focused_id = StringName(owner.get_meta(&"shop_item_id", &""))
	for child in _items.get_children():
		_items.remove_child(child)
		child.queue_free()
	for entry in _shop.stock:
		_items.add_child(_make_row(entry))
	if _root != null and _root.visible:
		_focus_item(focused_id)


func _focus_item(item_id: StringName) -> void:
	if not is_inside_tree():
		return
	if item_id != &"":
		for child in _items.find_children("*", "Button", true, false):
			var button := child as Button
			if button != null and not button.disabled and StringName(button.get_meta(&"shop_item_id", &"")) == item_id:
				button.grab_focus()
				return
	_focus_first_item()


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
	button.set_meta(&"shop_item_id", item_id)
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
