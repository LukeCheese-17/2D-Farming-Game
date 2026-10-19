class_name Pens
extends RefCounted
## The fences and gates the player puts up on the farm (ANM-5) and the pens they
## close off. Fences join up with their neighbours by themselves; a gate turns to
## match the fence it sits in. A pen is the grass a fence line closes off.

const FENCE_SOURCE := 5
## Gate tiles in gate.png: x is closed (0) or open (1), y is across (0) or up-down (1).
const GATE_SOURCE := 8
## Anything bigger than this isn't a pen, it's the outdoors.
const MAX_PEN_CELLS := 300

const NORTH := 1
const EAST := 2
const SOUTH := 4
const WEST := 8
const SIDES := {NORTH: Vector2i.UP, EAST: Vector2i.RIGHT, SOUTH: Vector2i.DOWN, WEST: Vector2i.LEFT}
## Tiles in Fences.png by which sides they join up on.
const FENCE_TILES := {
	0: Vector2i(0, 3), NORTH: Vector2i(0, 2), SOUTH: Vector2i(0, 0), NORTH | SOUTH: Vector2i(0, 1),
	EAST: Vector2i(1, 3), WEST: Vector2i(3, 3), EAST | WEST: Vector2i(2, 3),
	EAST | SOUTH: Vector2i(1, 0), SOUTH | WEST: Vector2i(3, 0), EAST | SOUTH | WEST: Vector2i(2, 0),
	NORTH | EAST: Vector2i(1, 2), NORTH | WEST: Vector2i(3, 2), NORTH | EAST | WEST: Vector2i(2, 2),
	NORTH | EAST | SOUTH: Vector2i(1, 1), NORTH | SOUTH | WEST: Vector2i(3, 1), 15: Vector2i(2, 1),
}

var layer: TileMapLayer
## Cells animals can stand on (grass, not water).
var _is_land: Callable


func _init(fence_layer: TileMapLayer, is_land: Callable) -> void:
	layer = fence_layer
	_is_land = is_land


func is_fence(cell: Vector2i) -> bool:
	return layer.get_cell_source_id(cell) != -1


func is_gate(cell: Vector2i) -> bool:
	return layer.get_cell_source_id(cell) == GATE_SOURCE


func is_gate_open(cell: Vector2i) -> bool:
	return is_gate(cell) and layer.get_cell_atlas_coords(cell).x == 1


func place(cell: Vector2i, kind: ItemData.Placeable) -> void:
	if kind == ItemData.Placeable.GATE:
		layer.set_cell(cell, GATE_SOURCE, Vector2i.ZERO)
	else:
		layer.set_cell(cell, FENCE_SOURCE, Vector2i.ZERO)
	_join_around(cell)


## Takes the fence or gate down; returns what it was.
func remove(cell: Vector2i) -> ItemData.Placeable:
	var kind := ItemData.Placeable.GATE if is_gate(cell) else ItemData.Placeable.FENCE
	layer.erase_cell(cell)
	_join_around(cell)
	return kind


func set_gate_open(cell: Vector2i, open: bool) -> void:
	var tile := layer.get_cell_atlas_coords(cell)
	layer.set_cell(cell, GATE_SOURCE, Vector2i(1 if open else 0, tile.y))


func _join_around(cell: Vector2i) -> void:
	_join(cell)
	for side: int in SIDES:
		_join(cell + SIDES[side])


## Picks the tile that joins this fence to its neighbours, or turns a gate to fit.
func _join(cell: Vector2i) -> void:
	if not is_fence(cell):
		return
	var sides := 0
	for side: int in SIDES:
		if is_fence(cell + SIDES[side]):
			sides |= side
	if is_gate(cell):
		var across := sides & (EAST | WEST) != 0 or sides & (NORTH | SOUTH) == 0
		layer.set_cell(cell, GATE_SOURCE, Vector2i(layer.get_cell_atlas_coords(cell).x, 0 if across else 1))
	else:
		layer.set_cell(cell, FENCE_SOURCE, FENCE_TILES[sides])


## The pen around a cell: {"closed": the fences close it off, "cells": its grass
## cells, "gate_open": one of its gates is open}. Gates count as fence either way.
func find_pen(start: Vector2i) -> Dictionary:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	var gate_open := false
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for side: int in SIDES:
			var next: Vector2i = cell + SIDES[side]
			if seen.has(next):
				continue
			if is_fence(next):
				gate_open = gate_open or is_gate_open(next)
				continue
			if not _is_land.call(next):
				continue
			seen[next] = true
			if seen.size() > MAX_PEN_CELLS:
				return {"closed": false, "cells": [], "gate_open": false}
			queue.append(next)
	var cells: Array[Vector2i] = []
	cells.assign(seen.keys())
	return {"closed": true, "cells": cells, "gate_open": gate_open}


## Open ground near a cell, for an animal that has no pen to wander in.
func cells_near(start: Vector2i, steps: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [start]
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var cell := start + Vector2i(x, y)
			if cell != start and absi(x) + absi(y) <= steps and not is_fence(cell) and _is_land.call(cell):
				cells.append(cell)
	return cells


# --- Saving ---

func get_save_data() -> Array:
	var list := []
	for cell in layer.get_used_cells():
		var tile := layer.get_cell_atlas_coords(cell)
		list.append([cell.x, cell.y, layer.get_cell_source_id(cell), tile.x, tile.y])
	return list


func load_save_data(list: Array) -> void:
	layer.clear()
	for entry: Array in list:
		layer.set_cell(Vector2i(entry[0], entry[1]), int(entry[2]), Vector2i(entry[3], entry[4]))
