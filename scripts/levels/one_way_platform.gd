class_name OneWayPlatform
extends StaticBody2D

## Reusable one-way platform for the big-map chapters (2–4).
##
## The player lands on it from above and jumps up through it from below.
## Holding the existing down input and pressing jump drops through: player.gd
## adds a short collision exception with this body, so the pipeline never adds
## a new action or changes the jump itself. Every Chapter 1 room uses
## [MDSChapterRoom] ground instead, so the demo's movement is untouched.
##
## [member position] is the top-left corner of the walkable surface, matching
## the room-local coordinates of [BigRoomData]. Authored as a child of an
## [MDSBigRoom], the platform uses the shared terrain layer (1) and adds no
## collision mask of its own.

const GROUP := &"one_way_platforms"

@export var size: Vector2 = Vector2(160, 16)
@export var color: Color = Color("183039")
@export var edge_color: Color = Color("74b3a7")
## When false the top still blocks but down+jump does not drop through.
@export var drop_through: bool = true
## Chapter terrain atlas; set by MDSBigRoom so the ledge matches the tiles.
var tile_texture: Texture2D

var _shape: CollisionShape2D


func _ready() -> void:
	build()


## Builds the collision shape. Safe to call before the node enters the tree,
## which is how the unit tests inspect the pipeline without a physics world.
func build() -> void:
	if not is_in_group(GROUP):
		add_to_group(GROUP)
	collision_layer = 1
	collision_mask = 0
	if _shape == null:
		_shape = get_node_or_null("Shape") as CollisionShape2D
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = "Shape"
		add_child(_shape)
	var box := RectangleShape2D.new()
	box.size = Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
	_shape.shape = box
	_shape.position = box.size * 0.5
	# Godot keeps the body out when it moves up through the shape; the player
	# only ever collides with the top face.
	_shape.one_way_collision = true
	_shape.one_way_collision_margin = 2.0
	queue_redraw()


## Whether player.gd may drop the player through this platform.
func allows_drop_through() -> bool:
	return drop_through


## Y of the walkable top edge in global space.
func surface_y() -> float:
	return global_position.y


func collision_shape() -> CollisionShape2D:
	return _shape


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0)))
	if tile_texture != null:
		TileVariants.draw_platform_strip(self, tile_texture, rect)
	else:
		draw_rect(rect, color)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, minf(4.0, rect.size.y))), edge_color)
	if not drop_through:
		return
	# Three short down-chevrons read as "this surface opens downward" without
	# needing new art or another button.
	var y := minf(rect.size.y - 3.0, 11.0)
	var step := rect.size.x / 4.0
	for index in range(1, 4):
		var x := step * index
		draw_line(Vector2(x - 4.0, y - 4.0), Vector2(x, y), Color(edge_color, 0.55), 1.0)
		draw_line(Vector2(x, y), Vector2(x + 4.0, y - 4.0), Color(edge_color, 0.55), 1.0)
