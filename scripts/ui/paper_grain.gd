class_name PaperGrain
extends RefCounted

## Adds the paper grain overlay (resources/shaders/paper_grain.gdshader) under
## the contents of an archive-page panel. PanelContainer lays every child over
## its full rect, so a first child sits behind the text without a layout change.

const SHADER := preload("res://resources/shaders/paper_grain.gdshader")
const NODE_NAME := "PaperGrain"


static func apply(panel: Control, strength: float = 0.5) -> ColorRect:
	if panel == null:
		return null
	var existing := panel.get_node_or_null(NODE_NAME) as ColorRect
	if existing != null:
		return existing
	var grain := ColorRect.new()
	grain.name = NODE_NAME
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grain.color = Color.WHITE
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"strength", strength)
	material.set_shader_parameter(&"seed", float(absi(panel.name.hash()) % 97))
	grain.material = material
	if not panel is Container:
		grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(grain)
	panel.move_child(grain, 0)
	return grain
