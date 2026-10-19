class_name WorldArea
extends Node2D
## A place the player can use items in: the surface map (Farm) or a mine floor (Mine).
## The player asks the area it's in what the held item does on the tile in front.

## Water kinds, used to pick fish (FishData.places uses the same bits).
enum Water { NONE = 0, POND = 1, RIVER = 2, LAKE = 4 }


func world_to_cell(_world_position: Vector2) -> Vector2i:
	return Vector2i.ZERO


func cell_to_world(_cell: Vector2i) -> Vector2:
	return Vector2.ZERO


## The area in world coordinates, used for camera limits.
func get_map_rect() -> Rect2:
	return Rect2()


## How fast the player walks here (paths are quicker, MOV-7).
func get_speed_factor(_world_position: Vector2) -> float:
	return 1.0


## Lets the area change which cell the player aims at from the cell they stand in.
func adjust_target(_from: Vector2i, target: Vector2i) -> Vector2i:
	return target


## True if using the item on the cell would do something.
func can_use(_item: ItemData, _cell: Vector2i) -> bool:
	return false


## Uses the item on the cell, if it can be done there.
func use(_item: ItemData, _cell: Vector2i) -> void:
	pass


## The player animation for using the item on the cell ("tilling_", "watering_", "chopping_" or "").
func get_animation(_item: ItemData, _cell: Vector2i) -> String:
	return ""


func get_water(_cell: Vector2i) -> Water:
	return Water.NONE


func is_fishable(cell: Vector2i) -> bool:
	return get_water(cell) != Water.NONE
