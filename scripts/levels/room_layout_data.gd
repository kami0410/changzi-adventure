class_name RoomLayoutData
extends Resource

## Tile-based room geometry for the Chapter 1 demo. Rows are 16 px cells:
## row 35 is the floor surface (y=560); the two legal platform rows are 30
## (y=480) and 28 (y=448), both inside the 92.6 px jump height.

@export var floor_row: int = 35
@export var platform_rows: Array[int] = [30, 28]
@export var tile_set: TileSet
