class_name ModalLayer
extends CanvasLayer

## One shared CanvasLayer above the HUD and every in-world overlay, for
## modal windows that are created on the fly (AI settings and the like).
## Without it, a Control added under the scene root draws below the Hub's
## top bar and the HUD, which then show through the paper page.

const LAYER := 70


## The layer under the current scene, created on first use. Outside the
## tree (headless tests build scenes by hand) the layer goes under `from`.
static func host(from: Node) -> Node:
	if not from.is_inside_tree():
		var local := from.get_node_or_null("ModalLayer")
		if local == null:
			local = ModalLayer.new()
			local.name = "ModalLayer"
			(local as CanvasLayer).layer = LAYER
			from.add_child(local)
		return local
	var tree := from.get_tree()
	var scene := tree.current_scene if tree.current_scene != null else tree.root
	var existing := scene.get_node_or_null("ModalLayer") as CanvasLayer
	if existing != null:
		return existing
	var layer := ModalLayer.new()
	layer.name = "ModalLayer"
	layer.layer = LAYER
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	scene.add_child(layer)
	return layer
