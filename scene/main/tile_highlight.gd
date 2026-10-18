class_name TileHighlight
extends Node2D
## Outlines the tile the player is targeting. Bright when the selected
## tool can be used there, faint when it can't.

const TILE_SIZE := Vector2(16, 16)
const VALID_COLOR := Color(1, 1, 1, 0.9)
const INVALID_COLOR := Color(1, 1, 1, 0.3)

var _valid := false


func show_at(world_center: Vector2, valid: bool) -> void:
	global_position = world_center
	if valid != _valid:
		_valid = valid
		queue_redraw()


func _draw() -> void:
	# Inset by half a pixel so the 1px outline lands on whole pixels.
	var rect := Rect2(-TILE_SIZE / 2 + Vector2(0.5, 0.5), TILE_SIZE - Vector2.ONE)
	draw_rect(rect, VALID_COLOR if _valid else INVALID_COLOR, false, 1.0)
