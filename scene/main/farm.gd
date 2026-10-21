class_name Farm
extends WorldArea
## The surface map: tilling, planting, watering, daily growth and harvesting on the
## farm; chopping trees and breaking rocks; picking berries, apples and mushrooms
## in the woods; fences, gates and the animals in their pens. Also adds collision
## so the player can't walk into the water.

enum Action { NONE, TILL, WATER, PLANT, FISH, COLLECT, CHOP, MINE, CLEAR, BUILD, TAKE_DOWN, GATE, RELEASE }

const CROP_SCENE := preload("res://scene/crops/crop.tscn")
const ANIMAL_SCENE := preload("res://scene/animals/animal.tscn")
## Terrain set and terrain index of "Tilled dirt Terrain" in game_tile_set.tres.
const DIRT_TERRAIN_SET := 0
const DIRT_TERRAIN := 1
## Crops y-sort by the top of their tile, so the player walking through a crop
## is drawn in front of it, and behind the crops in the row below.
const CROP_OFFSET := Vector2(0, -7)
const NATURE_SOURCE := 4

# Tiles in assets/Generated/nature.png ("Basic Grass Biom things 1.png" redrawn in the dead tree style).
const BIG_TREE := Vector2i(1, 0)
## The big dead tree, three tiles square (assets/Objects/dead_tree.png).
const HUGE_TREE := Vector2i(2, 5)
const APPLE_TREE := Vector2i(3, 0)
## An apple tree with its apples picked; it stays alive (ART-3).
const PICKED_APPLE_TREE := Vector2i(0, 5)
const SMALL_TREE := Vector2i(0, 0)
const SMALL_STUMP := Vector2i(3, 2)
const BIG_STUMP := Vector2i(4, 2)
const LOG := Vector2i(5, 2)
const BERRY_BUSH := Vector2i(0, 3)
const BUSH := Vector2i(1, 3)
const SMALL_ROCKS: Array[Vector2i] = [Vector2i(7, 1), Vector2i(6, 4)]
const BIG_ROCKS: Array[Vector2i] = [Vector2i(8, 1), Vector2i(5, 4)]
const MUSHROOMS: Array[Vector2i] = [Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0)]
## The red ones; the purple ones are dusk caps.
const RED_MUSHROOMS: Array[Vector2i] = [Vector2i(5, 0), Vector2i(6, 0)]
## Weeds and flowers: cleared with the hoe or by hand.
const DECOR: Array[Vector2i] = [Vector2i(5, 1), Vector2i(6, 1), Vector2i(6, 2), Vector2i(7, 2), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3)]
## Wild flowers among DECOR that can be picked (MAP-4): tile -> item.
const WILD_FLOWERS := {
	Vector2i(6, 2): preload("res://data/items/buttercup.tres"),
	Vector2i(7, 2): preload("res://data/items/buttercup.tres"),
	Vector2i(6, 3): preload("res://data/items/pink_clover.tres"),
	Vector2i(7, 3): preload("res://data/items/pink_clover.tres"),
	Vector2i(5, 3): preload("res://data/items/cornflower.tres"),
}
## Trees drawn two tiles tall: their trunk stands in the cell below the tile (TOL-4).
const TALL_TREES: Array[Vector2i] = [HUGE_TREE, BIG_TREE, APPLE_TREE, PICKED_APPLE_TREE, SMALL_TREE]
## Walking on a path is quicker than on grass (MOV-7).
const PATH_SPEED := 1.3

## Swings of a basic axe/pickaxe needed (tool_power is taken off per swing).
const TREE_HARDNESS := 3
const STUMP_HARDNESS := 2
const BIG_ROCK_HARDNESS := 3
const SMALL_ROCK_HARDNESS := 1
## Days until a picked bush or apple tree has fruit again.
const BERRY_REGROW_DAYS := 2
const APPLE_REGROW_DAYS := 3
## New mushrooms that come up in the woods each night.
const NIGHTLY_MUSHROOMS := 4

const WOOD := preload("res://data/items/wood.tres")
const STONE := preload("res://data/items/stone.tres")
const BERRIES := preload("res://data/items/berries.tres")
const APPLE := preload("res://data/items/apple.tres")
const DUSK_CAP := preload("res://data/items/dusk_cap.tres")
const RED_CAP := preload("res://data/items/red_cap.tres")
const FENCE := preload("res://data/items/fence.tres")
const GATE := preload("res://data/items/gate.tres")

## Chance, each night, that an animal goes missing from a pen with an open gate
## or a gap in the fence (ANM-7).
const ESCAPE_CHANCE := 0.15
const ESCAPE_LINES: Array[String] = [
	"The pen was left open all night. Your %s is gone. There are no tracks, not even its own.",
	"Your %s is gone. The gate is still open, creaking. You don't remember it creaking before.",
	"One %s is missing. Whatever took it latched the open gate back against the fence. Neatly.",
]

@export var water_layer: TileMapLayer
@export var grass_layer: TileMapLayer
## Dirt paths and bridges; can't be tilled, and bridges cross water.
@export var paths_layer: TileMapLayer
@export var tilled_layer: TileMapLayer
## Same tiles as tilled_layer, drawn darker, for watered soil.
@export var wet_layer: TileMapLayer
@export var nature_layer: TileMapLayer
## Parent for crop nodes; should be y-sorted together with the player.
@export var crops_parent: Node2D
## Fences and gates (ANM-5); the starter pen is painted in the scene.
@export var fences_layer: TileMapLayer
## Where animals are added; y-sorted with the player.
@export var animals_parent: Node2D
## Cells of the pond and the river (other water is the lake around the land).
@export var pond_area: Rect2i
@export var river_area: Rect2i
## Where mushrooms come up overnight.
@export var woods_area: Rect2i

var _watered: Dictionary[Vector2i, bool] = {}
var _crops: Dictionary[Vector2i, Crop] = {}
## Swings so far on a tree, stump or rock.
var _hits: Dictionary[Vector2i, int] = {}
## Picked bushes and trees: cell -> [tile to put back, day it comes back].
var _regrow: Dictionary[Vector2i, Array] = {}
var pens: Pens


func _ready() -> void:
	pens = Pens.new(fences_layer, is_land)
	GameState.day_changed.connect(_on_day_changed)
	GameState.night_passed.connect(_on_night_passed)
	_build_water_collision()
	refresh_pens.call_deferred()


func world_to_cell(world_position: Vector2) -> Vector2i:
	return grass_layer.local_to_map(grass_layer.to_local(world_position))


func cell_to_world(cell: Vector2i) -> Vector2:
	return grass_layer.to_global(grass_layer.map_to_local(cell))


## The whole map in world coordinates, used for camera limits.
func get_map_rect() -> Rect2:
	var used := water_layer.get_used_rect()
	var tile_size := Vector2(water_layer.tile_set.tile_size)
	return Rect2(Vector2(used.position) * tile_size, Vector2(used.size) * tile_size)


func is_tilled(cell: Vector2i) -> bool:
	return tilled_layer.get_cell_source_id(cell) != -1


func is_watered(cell: Vector2i) -> bool:
	return _watered.has(cell)


func get_crop(cell: Vector2i) -> Crop:
	return _crops.get(cell)


func get_nature(cell: Vector2i) -> Vector2i:
	if nature_layer.get_cell_source_id(cell) != NATURE_SOURCE:
		return Vector2i(-1, -1)
	return nature_layer.get_cell_atlas_coords(cell)


func can_till(cell: Vector2i) -> bool:
	if is_tilled(cell) or nature_layer.get_cell_source_id(cell) != -1 or _has_body_at(cell):
		return false
	if paths_layer.get_cell_source_id(cell) != -1:
		return false
	var data := grass_layer.get_cell_tile_data(cell)
	return data != null and data.get_custom_data("can_till")


func can_plant(cell: Vector2i) -> bool:
	return is_tilled(cell) and not _crops.has(cell)


func can_water(cell: Vector2i) -> bool:
	return is_tilled(cell) and not is_watered(cell)


func can_harvest(cell: Vector2i) -> bool:
	return _crops.has(cell) and _crops[cell].is_ripe()


## Grass the player and animals can stand on (not water or bridges).
func is_land(cell: Vector2i) -> bool:
	return grass_layer.get_cell_source_id(cell) != -1


## Fences and gates go on open grass or paths, not on soil, plants, tree trunks or animals.
func can_build(cell: Vector2i) -> bool:
	return is_land(cell) and not pens.is_fence(cell) and not is_tilled(cell) \
		and nature_layer.get_cell_source_id(cell) == -1 and _trunk_of(cell) == Vector2i(-1, -1) \
		and not _has_body_at(cell) and get_animal_at(cell, 12.0) == null


func can_release(cell: Vector2i) -> bool:
	return is_land(cell) and not pens.is_fence(cell) and not _has_body_at(cell)


func get_water(cell: Vector2i) -> Water:
	if water_layer.get_cell_source_id(cell) == -1 or grass_layer.get_cell_source_id(cell) != -1:
		return Water.NONE
	if paths_layer.get_cell_source_id(cell) != -1:
		return Water.NONE  # A bridge
	if pond_area.has_point(cell):
		return Water.POND
	if river_area.has_point(cell):
		return Water.RIVER
	return Water.LAKE


func get_speed_factor(world_position: Vector2) -> float:
	return PATH_SPEED if paths_layer.get_cell_source_id(world_to_cell(world_position)) != -1 else 1.0


## Facing up from a tree's trunk cell aims at the trunk, not the canopy above it.
func adjust_target(from: Vector2i, target: Vector2i) -> Vector2i:
	if target == from + Vector2i.UP and _trunk_of(from) != Vector2i(-1, -1):
		return from
	return target


## The tile cell of the tall tree whose trunk is in this cell, or (-1, -1).
func _trunk_of(cell: Vector2i) -> Vector2i:
	var above := cell + Vector2i.UP
	return above if get_nature(above) in TALL_TREES else Vector2i(-1, -1)


## The cell to chop when aiming at this one: a tall tree's tile when aiming at its trunk,
## a stump or log on the cell itself, or (-1, -1) (the canopy can't be chopped).
func _choppable(cell: Vector2i) -> Vector2i:
	var trunk := _trunk_of(cell)
	if trunk != Vector2i(-1, -1):
		return trunk
	var tile := get_nature(cell)
	return cell if is_tree(tile) and not tile in TALL_TREES else Vector2i(-1, -1)


## An animal standing on the cell that has something to collect, or null.
func get_animal_with_product(cell: Vector2i) -> Animal:
	return get_animal_at(cell, 14.0, true)


## An animal within reach of the cell's center, or null.
func get_animal_at(cell: Vector2i, reach: float, with_product := false) -> Animal:
	var center := cell_to_world(cell)
	for animal: Animal in get_tree().get_nodes_in_group("animals"):
		if (animal.has_product or not with_product) and animal.global_position.distance_to(center) < reach:
			return animal
	return null


## Ripe crops, animal products, berries, apples and mushrooms can be collected
## whatever the player is holding (TOL-3).
func can_collect(cell: Vector2i) -> bool:
	var tile := get_nature(cell)
	return can_harvest(cell) or get_animal_with_product(cell) != null \
		or tile == BERRY_BUSH or tile == APPLE_TREE or tile in MUSHROOMS or WILD_FLOWERS.has(tile) \
		or get_nature(cell + Vector2i.UP) == APPLE_TREE


func is_tree(tile: Vector2i) -> bool:
	return tile in [HUGE_TREE, BIG_TREE, APPLE_TREE, PICKED_APPLE_TREE, SMALL_TREE, SMALL_STUMP, BIG_STUMP, LOG]


func is_rock(tile: Vector2i) -> bool:
	return tile in SMALL_ROCKS or tile in BIG_ROCKS


## What using an item on a cell does.
func get_action(item: ItemData, cell: Vector2i) -> Action:
	if can_collect(cell):
		return Action.COLLECT
	var tool := item.tool if item else Tools.Type.NONE
	var tile := get_nature(cell)
	if pens.is_fence(cell):
		# The axe takes a fence down; anything else opens or shuts a gate.
		if tool == Tools.Type.AXE:
			return Action.TAKE_DOWN
		return Action.GATE if pens.is_gate(cell) else Action.NONE
	if item and item.placeable != ItemData.Placeable.NONE:
		return Action.BUILD if can_build(cell) else Action.NONE
	if item and item.animal:
		return Action.RELEASE if can_release(cell) else Action.NONE
	match tool:
		Tools.Type.HOE:
			if tile in DECOR:
				return Action.CLEAR
			return Action.TILL if can_till(cell) else Action.NONE
		Tools.Type.WATERING_CAN:
			return Action.WATER if can_water(cell) else Action.NONE
		Tools.Type.FISHING_ROD:
			return Action.FISH if is_fishable(cell) else Action.NONE
		Tools.Type.AXE:
			return Action.CHOP if _choppable(cell) != Vector2i(-1, -1) else Action.NONE
		Tools.Type.PICKAXE:
			return Action.MINE if is_rock(tile) else Action.NONE
	if GameState.get_crop_for_seed(item):
		return Action.PLANT if can_plant(cell) else Action.NONE
	if item == null and tile in DECOR:
		return Action.CLEAR
	return Action.NONE


func can_use(item: ItemData, cell: Vector2i) -> bool:
	return get_action(item, cell) != Action.NONE


func get_animation(item: ItemData, cell: Vector2i) -> String:
	match get_action(item, cell):
		Action.TILL, Action.CLEAR:
			return "tilling_" if item else ""
		Action.WATER:
			return "watering_"
		Action.CHOP, Action.MINE, Action.TAKE_DOWN:
			return "chopping_"
	return ""


## Uses the item on the cell, if it can be done there. Fishing is handled by the player.
func use(item: ItemData, cell: Vector2i) -> void:
	match get_action(item, cell):
		Action.COLLECT:
			_collect(cell)
		Action.TILL:
			tilled_layer.set_cells_terrain_connect([cell], DIRT_TERRAIN_SET, DIRT_TERRAIN)
			_refresh_wet()
		Action.WATER:
			_watered[cell] = true
			_refresh_wet()
		Action.PLANT:
			_plant(cell, item)
		Action.CHOP:
			_chop(cell, item)
		Action.MINE:
			_break_rock(cell, item)
		Action.CLEAR:
			nature_layer.erase_cell(cell)
		Action.BUILD:
			if GameState.inventory.remove(item):
				pens.place(cell, item.placeable)
				refresh_pens()
		Action.TAKE_DOWN:
			_take_down(cell)
		Action.GATE:
			_toggle_gate(cell)
		Action.RELEASE:
			_release(cell, item)


## Watered soil is drawn with the same tile as the tilled soil under it, so it
## keeps the patch's shape instead of making blobs of its own.
func _refresh_wet() -> void:
	wet_layer.clear()
	for cell in _watered:
		wet_layer.set_cell(cell, tilled_layer.get_cell_source_id(cell), tilled_layer.get_cell_atlas_coords(cell))


func _plant(cell: Vector2i, seed: ItemData) -> void:
	if not GameState.inventory.remove(seed):
		return
	var crop: Crop = CROP_SCENE.instantiate()
	crop.setup(GameState.get_crop_for_seed(seed))
	crop.position = crops_parent.to_local(cell_to_world(cell) + CROP_OFFSET)
	crops_parent.add_child(crop)
	_crops[cell] = crop


func _give(item: ItemData, amount: int) -> bool:
	if not GameState.inventory.has_room_for(item, amount):
		UI.post_message("Your bag is full")
		return false
	GameState.inventory.add(item, amount)
	UI.post_message("+%d %s" % [amount, item.display_name])
	return true


func _collect(cell: Vector2i) -> void:
	var animal := get_animal_with_product(cell)
	if animal:
		animal.collect()
		return
	var tile := get_nature(cell)
	if get_nature(cell + Vector2i.UP) == APPLE_TREE:
		# Reaching up from under the apple tree.
		cell += Vector2i.UP
		tile = APPLE_TREE
	if WILD_FLOWERS.has(tile):
		if _give(WILD_FLOWERS[tile], 1):
			nature_layer.erase_cell(cell)
		return
	if tile == BERRY_BUSH:
		if _give(BERRIES, randi_range(2, 3)):
			nature_layer.set_cell(cell, NATURE_SOURCE, BUSH)
			_regrow[cell] = [BERRY_BUSH, GameState.day + BERRY_REGROW_DAYS]
		return
	if tile == APPLE_TREE:
		if _give(APPLE, randi_range(1, 2)):
			nature_layer.set_cell(cell, NATURE_SOURCE, PICKED_APPLE_TREE)
			_regrow[cell] = [APPLE_TREE, GameState.day + APPLE_REGROW_DAYS]
		return
	if tile in MUSHROOMS:
		if _give(RED_CAP if tile in RED_MUSHROOMS else DUSK_CAP, 1):
			nature_layer.erase_cell(cell)
		return
	var crop: Crop = _crops.get(cell)
	if crop == null:
		return
	if not crop.is_ripe():
		UI.post_message("Not ripe yet")
		return
	if _give(crop.data.produce, crop.data.harvest_amount):
		_crops.erase(cell)
		crop.queue_free()


# --- Fences, gates and animals (ANM-5..ANM-8) ---

func _take_down(cell: Vector2i) -> void:
	var item := GATE if pens.is_gate(cell) else FENCE
	if not GameState.inventory.has_room_for(item):
		UI.post_message("Your bag is full")
		return
	pens.remove(cell)
	_give(item, 1)
	refresh_pens()


func _toggle_gate(cell: Vector2i) -> void:
	var open := pens.is_gate_open(cell)
	if open and _has_body_at(cell):
		UI.post_message("Something is in the way")
		return
	pens.set_gate_open(cell, not open)


## Lets a crated animal out, as long as the spot is inside a fenced-in pen.
func _release(cell: Vector2i, item: ItemData) -> void:
	var pen := pens.find_pen(cell)
	if not pen.closed:
		UI.post_message("It needs a fenced-in pen")
		return
	if not GameState.inventory.remove(item):
		return
	var animal := spawn_animal(item.animal, cell_to_world(cell), false)
	animal.set_pen(self, pen.cells)
	UI.post_message("The %s noses around its new pen" % item.animal.display_name.to_lower())
	if pen.gate_open:
		UI.post_message("The gate is open")


func spawn_animal(animal_data: AnimalData, at: Vector2, has_product := true, animal_name := "") -> Animal:
	var animal: Animal = ANIMAL_SCENE.instantiate()
	animal.name = animal_name if animal_name != "" else animal_data.display_name
	animal.data = animal_data
	animal.has_product = has_product
	animals_parent.add_child(animal, true)
	animal.global_position = at
	return animal


## Tells every animal which cells it may wander over: its pen, or the ground
## around it when the fence no longer closes it in.
func refresh_pens() -> void:
	var known: Dictionary[Vector2i, Array] = {}
	for animal: Animal in get_tree().get_nodes_in_group("animals"):
		var cell := world_to_cell(animal.global_position)
		if not known.has(cell):
			var pen := pens.find_pen(cell)
			if pen.closed:
				for pen_cell: Vector2i in pen.cells:
					known[pen_cell] = pen.cells
			else:
				known[cell] = pens.cells_near(cell, 3)
		var cells: Array[Vector2i] = []
		cells.assign(known[cell])
		animal.set_pen(self, cells)


## Animals in a pen with an open gate (or a gap in the fence) may be gone by morning.
func _on_night_passed(report: Array[String]) -> void:
	for animal: Animal in get_tree().get_nodes_in_group("animals"):
		var pen := pens.find_pen(world_to_cell(animal.global_position))
		if (pen.closed and not pen.gate_open) or randf() >= ESCAPE_CHANCE:
			continue
		report.append(ESCAPE_LINES.pick_random() % animal.data.display_name.to_lower())
		animal.remove_from_group("animals")
		animal.queue_free()


## One swing at a tree or stump. Trees fall into stumps (left where the trunk stood),
## stumps come out of the ground.
func _chop(target: Vector2i, axe: ItemData) -> void:
	var cell := _choppable(target)
	var tile := get_nature(cell)
	var stump := tile in [SMALL_STUMP, BIG_STUMP, LOG]
	if not _swing(cell, axe, STUMP_HARDNESS if stump else TREE_HARDNESS):
		return
	match tile:
		SMALL_TREE:
			_give(WOOD, 2)
			nature_layer.erase_cell(cell)
			nature_layer.set_cell(cell + Vector2i.DOWN, NATURE_SOURCE, SMALL_STUMP)
		HUGE_TREE, BIG_TREE, APPLE_TREE, PICKED_APPLE_TREE:
			_give(WOOD, 6 if tile == HUGE_TREE else 4)
			_regrow.erase(cell)
			nature_layer.erase_cell(cell)
			nature_layer.set_cell(cell + Vector2i.DOWN, NATURE_SOURCE, BIG_STUMP)
		_:
			_give(WOOD, 2 if tile == LOG else 1)
			nature_layer.erase_cell(cell)


func _break_rock(cell: Vector2i, pickaxe: ItemData) -> void:
	var big := get_nature(cell) in BIG_ROCKS
	if not _swing(cell, pickaxe, BIG_ROCK_HARDNESS if big else SMALL_ROCK_HARDNESS):
		return
	_give(STONE, 3 if big else 1)
	nature_layer.erase_cell(cell)


## Counts a swing; true once the thing breaks.
func _swing(cell: Vector2i, tool: ItemData, hardness: int) -> bool:
	_hits[cell] = _hits.get(cell, 0) + tool.tool_power
	if _hits[cell] < hardness:
		return false
	_hits.erase(cell)
	return true


## Crops watered today grow one step; then all soil dries out. Bushes and
## trees grow fruit back, and mushrooms come up in the woods.
func _on_day_changed(day: int) -> void:
	for cell in _crops:
		if is_watered(cell):
			_crops[cell].grow()
	_watered.clear()
	wet_layer.clear()
	_hits.clear()
	for cell in _regrow.keys():
		if day >= _regrow[cell][1]:
			if get_nature(cell) in [BUSH, BIG_TREE, PICKED_APPLE_TREE]:
				nature_layer.set_cell(cell, NATURE_SOURCE, _regrow[cell][0])
			_regrow.erase(cell)
	for i in NIGHTLY_MUSHROOMS:
		var cell := Vector2i(randi_range(woods_area.position.x, woods_area.end.x), randi_range(woods_area.position.y, woods_area.end.y))
		if nature_layer.get_cell_source_id(cell) == -1 and grass_layer.get_cell_source_id(cell) != -1 \
				and paths_layer.get_cell_source_id(cell) == -1 and not _has_body_at(cell):
			nature_layer.set_cell(cell, NATURE_SOURCE, MUSHROOMS.pick_random())


## True if a physics body (bed, tree, rock...) covers the center of the cell.
func _has_body_at(cell: Vector2i) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = cell_to_world(cell)
	return not grass_layer.get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()


## Blocks water along the shores (the player can't get any further out than that).
func _build_water_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "WaterCollision"
	var tile_size := Vector2(water_layer.tile_set.tile_size)
	for cell in water_layer.get_used_cells():
		if get_water(cell) == Water.NONE or not _is_shore(cell):
			continue
		var shape := RectangleShape2D.new()
		shape.size = tile_size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = cell_to_world(cell)
		body.add_child(collision)
	add_child(body)


func _is_shore(cell: Vector2i) -> bool:
	for x in range(-1, 2):
		for y in range(-1, 2):
			var c := cell + Vector2i(x, y)
			if grass_layer.get_cell_source_id(c) != -1 or paths_layer.get_cell_source_id(c) != -1:
				return true
	return false


# --- Saving ---

func get_save_data() -> Dictionary:
	var crops := []
	for cell in _crops:
		crops.append([cell.x, cell.y, _crops[cell].data.resource_path, _crops[cell].watered_days])
	var nature := []
	for cell in nature_layer.get_used_cells():
		var tile := nature_layer.get_cell_atlas_coords(cell)
		nature.append([cell.x, cell.y, nature_layer.get_cell_source_id(cell), tile.x, tile.y])
	var regrow := []
	for cell in _regrow:
		regrow.append([cell.x, cell.y, _regrow[cell][0].x, _regrow[cell][0].y, _regrow[cell][1]])
	return {
		"tilled": _cells_to_list(tilled_layer.get_used_cells()),
		"watered": _cells_to_list(_watered.keys()),
		"crops": crops,
		"nature": nature,
		"regrow": regrow,
		"fences": pens.get_save_data(),
	}


func load_save_data(data: Dictionary) -> void:
	for crop in _crops.values():
		crop.queue_free()
	_crops.clear()
	_watered.clear()
	tilled_layer.clear()
	wet_layer.clear()
	var tilled: Array[Vector2i] = _list_to_cells(data.get("tilled", []))
	if not tilled.is_empty():
		tilled_layer.set_cells_terrain_connect(tilled, DIRT_TERRAIN_SET, DIRT_TERRAIN)
	var watered: Array[Vector2i] = _list_to_cells(data.get("watered", []))
	for cell in watered:
		_watered[cell] = true
	_refresh_wet()
	for entry: Array in data.get("crops", []):
		var crop_data := load(entry[2]) as CropData
		if crop_data == null:
			continue
		var cell := Vector2i(entry[0], entry[1])
		var crop: Crop = CROP_SCENE.instantiate()
		crop.setup(crop_data)
		crop.watered_days = int(entry[3])
		crop.position = crops_parent.to_local(cell_to_world(cell) + CROP_OFFSET)
		crops_parent.add_child(crop)
		_crops[cell] = crop
	if data.has("nature"):
		nature_layer.clear()
		for entry: Array in data.nature:
			nature_layer.set_cell(Vector2i(entry[0], entry[1]), int(entry[2]), Vector2i(entry[3], entry[4]))
	_regrow.clear()
	for entry: Array in data.get("regrow", []):
		_regrow[Vector2i(entry[0], entry[1])] = [Vector2i(entry[2], entry[3]), int(entry[4])]
	# Saves from before pens keep the starter pen from the scene.
	if data.has("fences"):
		pens.load_save_data(data.fences)


func _cells_to_list(cells: Array) -> Array:
	return cells.map(func(c: Vector2i) -> Array: return [c.x, c.y])


func _list_to_cells(list: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for entry: Array in list:
		cells.append(Vector2i(entry[0], entry[1]))
	return cells
