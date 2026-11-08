class_name TouchOverlay
extends CanvasLayer

## On-screen controls for touch screens (1.0.1). One global layer owned by
## GameFlow, so the Hub and every run get the same controls.
##
## - Left half: a floating stick. The first finger that lands there becomes its
##   centre; dragging presses move_left/right/up/down (down + jump drops
##   through ledges).
## - Right side: jump, attack, dodge, interact, the two 言灵 slots and weapon
##   swap; a top-left row opens the bag, codex, map, help and pause.
## - Real multi-touch: every finger is tracked by its index, so the stick and a
##   button work at the same time (the old Button-based controls could not).
## - Shown only while the touch screen is the active device and the player can
##   act (hidden behind pages, dialogue and the title screen); hiding releases
##   every held action.

const LAYER := 15
const STICK_RADIUS := 72.0
const STICK_DEAD := 0.32
const STICK_ZONE_TOP := 230.0
const MENU := [
	["背包", &"inventory"], ["图鉴", &"codex"], ["地图", &"map"], ["说明", &"help"], ["暂停", &"pause"],
]
## The Hub has no fights: jump and interact only, and its own pages.
const HUB_MENU := [["图鉴", &"codex"], ["说明", &"help"], ["设置", &"settings"]]
const HUB_ACTIONS: Array[StringName] = [&"jump", &"interact"]

## Forced on by tests or by the settings toggle; otherwise follows Flow.using_touch.
var force_visible := false
var size_scale := 1.0
var opacity := 0.6

var _root: Control
var _font: Font
var _buttons: Array[Dictionary] = []
var _menu: Array[Dictionary] = []
var _touches: Dictionary = {}
var _stick_index := -1
var _stick_origin := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _held: Dictionary = {}
var _active := false
var _layout_scene: Node
var _panel_bottom := 0.0


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.draw.connect(_draw_controls)
	add_child(_root)
	var theme := load("res://resources/ui/ink_theme.tres") as Theme
	_font = theme.default_font if theme != null and theme.default_font != null else ThemeDB.fallback_font
	_root.visible = false


## Logical screen size (viewport) and safe-area margins in logical units.
func screen_size() -> Vector2:
	return _root.get_viewport_rect().size if _root != null and _root.is_inside_tree() else Vector2(1280, 720)


func safe_margins() -> Vector4:
	if DisplayServer.get_name() == "headless" or not _root.is_inside_tree():
		return Vector4.ZERO
	var safe := DisplayServer.get_display_safe_area()
	var window := DisplayServer.window_get_size()
	if safe.size.x <= 0 or window.x <= 0:
		return Vector4.ZERO
	var scale := screen_size() / Vector2(window)
	var left := maxf(float(safe.position.x), 0.0) * scale.x
	var top := maxf(float(safe.position.y), 0.0) * scale.y
	var right := maxf(float(window.x - safe.end.x), 0.0) * scale.x
	var bottom := maxf(float(window.y - safe.end.y), 0.0) * scale.y
	return Vector4(left, top, right, bottom)


## Rebuilds button positions for the current screen. Public for tests.
func layout() -> void:
	var size := screen_size()
	var m := safe_margins()
	var k := size_scale
	var right := size.x - m.z - 24.0
	var bottom := size.y - m.w - 24.0
	var jump := Vector2(right - 62.0 * k, bottom - 62.0 * k)
	_buttons = [
		_button(&"jump", "跳", jump, 60.0 * k),
		_button(&"attack", "攻", jump + Vector2(-138, 14) * k, 52.0 * k),
		_button(&"dodge", "滚", jump + Vector2(-112, -112) * k, 46.0 * k),
		_button(&"interact", "交互", jump + Vector2(2, -136) * k, 42.0 * k),
		_button(&"cast_1", "言1", jump + Vector2(-252, -18) * k, 44.0 * k),
		_button(&"cast_2", "言2", jump + Vector2(-226, -124) * k, 44.0 * k),
		_button(&"swap", "换武", jump + Vector2(-100, -222) * k, 36.0 * k),
	]
	var in_hub := _in_hub()
	if in_hub:
		var kept: Array[Dictionary] = []
		for item in _buttons:
			if HUB_ACTIONS.has(item["action"]):
				kept.append(item)
		_buttons = kept
	_menu.clear()
	var x := m.x + 16.0
	var y := maxf(m.y + 160.0, _top_panel_bottom() + 10.0)
	for item in (HUB_MENU if in_hub else MENU):
		_menu.append({"action": item[1], "label": item[0], "rect": Rect2(x, y, 58.0, 40.0)})
		x += 64.0


func _in_hub() -> bool:
	# By script path, not `is Hub`: the overlay is built by the Flow autoload,
	# and naming the Hub class here would make Flow depend on itself.
	if not is_inside_tree() or get_tree().current_scene == null:
		return false
	var script := get_tree().current_scene.get_script() as Script
	return script != null and script.resource_path == "res://scripts/hub/hub.gd"


## Bottom edge of the top-left info panel (run HUD or Hub label), so the menu
## row never covers it whatever text size is chosen.
func _top_panel_bottom() -> float:
	if not is_inside_tree():
		return 150.0
	var hud := get_tree().get_first_node_in_group(&"hud")
	var panel: Control = null
	if hud != null:
		panel = hud.find_child("TopLeft", true, false) as Control
	if panel == null and get_tree().current_scene != null:
		panel = get_tree().current_scene.find_child("TopLeft", true, false) as Control
	if panel == null or not panel.is_visible_in_tree():
		return 150.0
	return panel.get_global_rect().end.y


func _button(action: StringName, label: String, center: Vector2, radius: float) -> Dictionary:
	return {"action": action, "label": label, "center": center, "radius": radius}


func buttons() -> Array[Dictionary]:
	return _buttons


func menu_buttons() -> Array[Dictionary]:
	return _menu


func is_active() -> bool:
	return _active


func _process(_delta: float) -> void:
	var show := _should_show()
	var scene := get_tree().current_scene
	if show != _active or scene != _layout_scene:
		_active = show
		_layout_scene = scene
		_root.visible = show
		if not show:
			release_all()
		else:
			layout()
	if _active:
		# The info panel grows as relics/authorities appear: keep the menu
		# row below it.
		var panel_bottom := _top_panel_bottom()
		if absf(panel_bottom - _panel_bottom) > 1.0:
			_panel_bottom = panel_bottom
			layout()
		_root.queue_redraw()


func _should_show() -> bool:
	var flow := get_parent() as GameFlow
	var wanted := force_visible or (flow != null and flow.using_touch)
	if not wanted or not is_inside_tree() or get_tree().paused:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node
	return player != null and player.is_physics_processing() and player.is_visible_in_tree()


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _begin_touch(touch.index, touch.position):
				get_viewport().set_input_as_handled()
		else:
			if _end_touch(touch.index):
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _stick_index:
			_move_stick(drag.position)
			get_viewport().set_input_as_handled()
		elif _touches.has(drag.index):
			_slide_button(drag.index, drag.position)


## A finger landed at [param at]. Returns true when the overlay owns it.
func _begin_touch(index: int, at: Vector2) -> bool:
	if _buttons.is_empty():
		layout()
	for item in _menu:
		if (item["rect"] as Rect2).has_point(at):
			_tap(StringName(item["action"]))
			_touches[index] = {"kind": "menu"}
			return true
	var hit := _button_at(at)
	if not hit.is_empty():
		_touches[index] = {"kind": "button", "action": hit["action"]}
		_press_button(StringName(hit["action"]))
		return true
	if _stick_index < 0 and at.x < screen_size().x * 0.45 and at.y > STICK_ZONE_TOP:
		_stick_index = index
		_stick_origin = at
		_stick_pos = at
		_touches[index] = {"kind": "stick"}
		return true
	return false


func _end_touch(index: int) -> bool:
	if not _touches.has(index):
		return false
	var info: Dictionary = _touches[index]
	_touches.erase(index)
	match String(info.get("kind", "")):
		"stick":
			_stick_index = -1
			for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
				_set_held(action, false)
		"button":
			_release_button(StringName(info["action"]))
	return true


## Sliding a finger from one button onto another (attack → jump) hands over.
func _slide_button(index: int, at: Vector2) -> void:
	var info: Dictionary = _touches[index]
	if String(info.get("kind", "")) != "button":
		return
	var hit := _button_at(at)
	if hit.is_empty() or hit["action"] == info["action"]:
		return
	_release_button(StringName(info["action"]))
	info["action"] = hit["action"]
	_press_button(StringName(hit["action"]))


func _button_at(at: Vector2) -> Dictionary:
	for item in _buttons:
		# Generous hit area: 15% beyond the drawn circle.
		if at.distance_to(item["center"]) <= float(item["radius"]) * 1.15:
			return item
	return {}


func _move_stick(at: Vector2) -> void:
	var offset := at - _stick_origin
	if offset.length() > STICK_RADIUS:
		# The base follows a finger that drifts too far, so the stick never "sticks".
		_stick_origin = at - offset.normalized() * STICK_RADIUS
		offset = at - _stick_origin
	_stick_pos = at
	var v := offset / STICK_RADIUS
	_set_held(&"move_left", v.x < -STICK_DEAD)
	_set_held(&"move_right", v.x > STICK_DEAD)
	_set_held(&"move_up", v.y < -0.6)
	_set_held(&"move_down", v.y > 0.6)


func stick_vector() -> Vector2:
	if _stick_index < 0:
		return Vector2.ZERO
	return (_stick_pos - _stick_origin) / STICK_RADIUS


func _press_button(action: StringName) -> void:
	if action == &"swap":
		var player := get_tree().get_first_node_in_group("player") as Player
		if player != null:
			_tap(&"weapon_2" if player.active_weapon_slot == 0 else &"weapon_1")
		return
	_set_held(action, true)


func _release_button(action: StringName) -> void:
	if action != &"swap":
		_set_held(action, false)


## A one-frame press for toggles (menus, weapon slots). Sent as real input
## events: pages listen in _unhandled_input, gameplay polls the action state.
func _tap(action: StringName) -> void:
	if not InputMap.has_action(action):
		return
	_send(action, true)
	if is_inside_tree():
		await get_tree().process_frame
		await get_tree().physics_frame
	_send(action, false)


func _send(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _set_held(action: StringName, down: bool) -> void:
	if not InputMap.has_action(action):
		return
	var was := bool(_held.get(action, false))
	if down == was:
		return
	_held[action] = down
	_send(action, down)


func is_held(action: StringName) -> bool:
	return bool(_held.get(action, false))


func release_all() -> void:
	for action in _held.keys():
		if _held[action]:
			_send(action, false)
	_held.clear()
	_touches.clear()
	_stick_index = -1


## Phrase slot readiness from the running game, so a 言灵 button dims while it
## cools down or ink runs short.
func _slot_ready(slot: int) -> bool:
	var scene := get_tree().current_scene
	if scene == null or not "phrase_caster" in scene:
		return true
	var caster = scene.get("phrase_caster")
	return caster == null or not caster.has_method("is_ready") or caster.is_ready(slot)


func _draw_controls() -> void:
	var ink := Color(UIPalette.INK_NIGHT, opacity * 0.75)
	var edge := Color(UIPalette.BONE_DIM, opacity)
	var lit := Color(Color("8fe8dc"), minf(opacity + 0.25, 1.0))
	if _stick_index >= 0:
		_root.draw_circle(_stick_origin, STICK_RADIUS, Color(ink, opacity * 0.5))
		_root.draw_arc(_stick_origin, STICK_RADIUS, 0.0, TAU, 40, edge, 2.0)
		var knob := _stick_origin + (_stick_pos - _stick_origin).limit_length(STICK_RADIUS)
		_root.draw_circle(knob, 30.0, Color(lit, opacity * 0.8))
	else:
		# Resting hint where the stick appears.
		var hint := Vector2(130.0 + safe_margins().x, screen_size().y - 130.0 - safe_margins().w)
		_root.draw_arc(hint, STICK_RADIUS, 0.0, TAU, 40, Color(edge, opacity * 0.5), 2.0)
		_draw_text("移动", hint, Color(edge, opacity * 0.7), 12)
	for item in _buttons:
		var action := StringName(item["action"])
		var held := is_held(action)
		var ready := true
		if action == &"cast_1":
			ready = _slot_ready(0)
		elif action == &"cast_2":
			ready = _slot_ready(1)
		var center: Vector2 = item["center"]
		var radius: float = item["radius"]
		_root.draw_circle(center, radius, Color(lit, opacity * 0.55) if held else ink)
		_root.draw_arc(center, radius, 0.0, TAU, 36, lit if held else edge, 2.0)
		var text_color := Color(UIPalette.BONE, opacity + 0.3) if ready else Color(UIPalette.BONE_DIM, opacity * 0.6)
		_draw_text(String(item["label"]), center, text_color, 16 if radius >= 44.0 else 12)
	for item in _menu:
		var rect: Rect2 = item["rect"]
		_root.draw_rect(rect, ink)
		_root.draw_rect(rect, edge, false, 1.5)
		_draw_text(String(item["label"]), rect.get_center(), Color(UIPalette.BONE, opacity + 0.3), 12)


func _draw_text(text: String, center: Vector2, color: Color, font_size: int) -> void:
	if _font == null:
		return
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_root.draw_string(_font, center + Vector2(-width * 0.5, font_size * 0.35), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
