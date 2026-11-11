class_name SurfaceEdge
extends Node2D

## Lit top edge for walkable tiles (1.1 readability). A dark platform in a dark
## room reads as background; one pale line along the top of each run of surface
## tiles says "you can stand here" in every chapter, whatever the tile art.
##
## Child of the surface TileMapLayer. Runs are merged per row, so a whole room
## is a few dozen lines drawn once and cached by the canvas.

@export var edge_color := Color(0.78, 0.95, 0.92, 0.8)
@export var under_color := Color(0.78, 0.95, 0.92, 0.28)

var _layer: TileMapLayer


## Traces [param layer]'s cells. Safe to call before the cells are painted.
static func trace(layer: TileMapLayer) -> SurfaceEdge:
	var edge := SurfaceEdge.new()
	edge.name = "SurfaceEdge"
	layer.add_child(edge)
	return edge


func _ready() -> void:
	_layer = get_parent() as TileMapLayer
	if _layer != null and not _layer.changed.is_connected(queue_redraw):
		_layer.changed.connect(queue_redraw)


## Horizontal runs of the layer's cells: [first cell, length in cells].
func runs() -> Array[Array]:
	if _layer == null:
		return []
	return merge(_layer.get_used_cells())


static func merge(cells: Array[Vector2i]) -> Array[Array]:
	var result: Array[Array] = []
	var sorted := cells.duplicate()
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	var start := Vector2i.ZERO
	var length := 0
	for cell: Vector2i in sorted:
		if length > 0 and cell.y == start.y and cell.x == start.x + length:
			length += 1
			continue
		if length > 0:
			result.append([start, length])
		start = cell
		length = 1
	if length > 0:
		result.append([start, length])
	return result


func _draw() -> void:
	if _layer == null or _layer.tile_set == null:
		return
	var size := Vector2(_layer.tile_set.tile_size)
	for run in runs():
		var cell: Vector2i = run[0]
		var from := Vector2(cell) * size
		var width := float(run[1]) * size.x
		draw_rect(Rect2(from, Vector2(width, 1.0)), edge_color)
		draw_rect(Rect2(from + Vector2(0.0, 1.0), Vector2(width, 1.0)), under_color)
