class_name ScreenFX
extends CanvasLayer

## Lightweight cinematic layer: impact flashes and letterbox for boss entrances.
## Deliberately avoids full-screen flashing more than a few times per second.

var _flash_rect: ColorRect
var _top: ColorRect
var _bottom: ColorRect
var _flash_tween: Tween

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_top = ColorRect.new()
	_top.color = Color(0.01, 0.015, 0.025, 1.0)
	_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top.offset_bottom = 0
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_top)
	_bottom = ColorRect.new()
	_bottom.color = Color(0.01, 0.015, 0.025, 1.0)
	_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom.offset_top = 0
	_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_bottom)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash_rect)

func flash(color: Color, duration: float = 0.16) -> void:
	var flash_scale := 1.0
	var flow := get_node_or_null("/root/Flow") as GameFlow
	if flow != null:
		flash_scale = flow.flash_scale
	color = Color(color.r, color.g, color.b, color.a * flash_scale)
	_flash_rect.color = Color(color.r, color.g, color.b, 0.0)
	if _flash_tween != null:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_rect, "color:a", color.a, duration * 0.25)
	_flash_tween.tween_property(_flash_rect, "color:a", 0.0, duration * 0.75)

func letterbox(amount: float, duration: float = 0.35) -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_top, "offset_bottom", amount, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_bottom, "offset_top", -amount, duration).set_trans(Tween.TRANS_SINE)
