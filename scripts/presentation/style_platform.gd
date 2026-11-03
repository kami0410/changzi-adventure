class_name StylePlatform
extends RefCounted

static func apply(platform: Node) -> void:
	if platform == null:
		return
	var visual := platform.get_node_or_null("Visual") as ColorRect
	if visual != null:
		visual.color = Color("183039")
	var edge := platform.get_node_or_null("Edge") as ColorRect
	if edge == null:
		edge = ColorRect.new()
		edge.name = "Edge"
		platform.add_child(edge)
	edge.position = Vector2(-120, -12)
	edge.size = Vector2(240, 4)
	edge.color = Color("74b3a7")
	var lamp := platform.get_node_or_null("Lamp") as Node2D
	if lamp == null:
		lamp = Node2D.new()
		lamp.name = "Lamp"
		platform.add_child(lamp)
		lamp.set_script(preload("res://scripts/presentation/platform_lamp.gd"))
