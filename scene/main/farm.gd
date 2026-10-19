class_name Farm
extends Node
## Owns the farm tiles: tilling, planting, watering, daily growth and harvesting.
## Also adds collision so the player can't walk off the grass into the water.

enum Action { TILL, WATER, PLANT, FISH, HAND }

const CROP_SCENE := preload("res://scene/crops/crop.tscn")
## Terrain set and terrain index of "Tilled dirt Terrain" in game_tile_set.tres.
const DIRT_TERRAIN_SET := 0
const DIRT_TERRAIN := 1
## Crops are placed slightly below the tile center so they y-sort by their base.
const CROP_OFFSET := Vector2(0, 6)

@export var water_layer: TileMapLayer
@export var grass_layer: TileMapLayer
@export var tilled_layer: TileMapLayer
## Same tiles as tilled_layer, drawn darker, for watered soil.
@export var wet_layer: TileMapLayer
@export var nature_layer: TileMapLayer
## Parent for crop nodes; should be y-sorted together with the player.
@export var crops_parent: Node2D

var _watered: Dictionary[Vector2i, bool] = {}
var _crops: Dictionary[Vector2i, Crop] = {}


func _ready() -> void:
	GameState.day_changed.connect(_on_day_changed)
	_build_water_collision()


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


func can_till(cell: Vector2i) -> bool:
	if is_tilled(cell) or nature_layer.get_cell_source_id(cell) != -1 or _has_body_at(cell):
		return false
	var data := grass_layer.get_cell_tile_data(cell)
	return data != null and data.get_custom_data("can_till")


func can_plant(cell: Vector2i) -> bool:
	return is_tilled(cell) and not _crops.has(cell)


func can_water(cell: Vector2i) -> bool:
	return is_tilled(cell) and not is_watered(cell)


func can_harvest(cell: Vector2i) -> bool:
	return _crops.has(cell) and _crops[cell].is_ripe()


## Open water (no grass on top) that the player can fish in.
func is_fishable(cell: Vector2i) -> bool:
	return water_layer.get_cell_source_id(cell) != -1 and grass_layer.get_cell_source_id(cell) == -1


## An animal standing on the cell that has something to collect, or null.
func get_animal_with_product(cell: Vector2i) -> Animal:
	var center := cell_to_world(cell)
	for animal: Animal in get_tree().get_nodes_in_group("animals"):
		if animal.has_product and animal.global_position.distance_to(center) < 14.0:
			return animal
	return null


## What using an item does: tools do their job, seeds are planted, anything else is an empty hand.
func get_action(item: ItemData) -> Action:
	if item == null:
		return Action.HAND
	match item.tool:
		Tools.Type.HOE:
			return Action.TILL
		Tools.Type.WATERING_CAN:
			return Action.WATER
		Tools.Type.FISHING_ROD:
			return Action.FISH
	if GameState.get_crop_for_seed(item):
		return Action.PLANT
	return Action.HAND


func can_use(item: ItemData, cell: Vector2i) -> bool:
	match get_action(item):
		Action.TILL:
			return can_till(cell)
		Action.WATER:
			return can_water(cell)
		Action.PLANT:
			return can_plant(cell)
		Action.FISH:
			return is_fishable(cell)
		Action.HAND:
			return can_harvest(cell) or get_animal_with_product(cell) != null
	return false


## Uses the item on the cell, if it can be done there. Fishing is handled by the player.
func use(item: ItemData, cell: Vector2i) -> void:
	match get_action(item):
		Action.TILL:
			_till(cell)
		Action.WATER:
			_water(cell)
		Action.PLANT:
			_plant(cell, item)
		Action.HAND:
			_harvest(cell)


func _till(cell: Vector2i) -> void:
	if not can_till(cell):
		return
	tilled_layer.set_cells_terrain_connect([cell], DIRT_TERRAIN_SET, DIRT_TERRAIN)


func _water(cell: Vector2i) -> void:
	if not can_water(cell):
		return
	_watered[cell] = true
	wet_layer.set_cells_terrain_connect([cell], DIRT_TERRAIN_SET, DIRT_TERRAIN)


func _plant(cell: Vector2i, seed: ItemData) -> void:
	if not can_plant(cell) or not GameState.inventory.remove(seed):
		return
	var crop: Crop = CROP_SCENE.instantiate()
	crop.setup(GameState.get_crop_for_seed(seed))
	crop.position = crops_parent.to_local(cell_to_world(cell) + CROP_OFFSET)
	crops_parent.add_child(crop)
	_crops[cell] = crop


func _harvest(cell: Vector2i) -> void:
	var animal := get_animal_with_product(cell)
	if animal:
		animal.collect()
		return
	var crop: Crop = _crops.get(cell)
	if crop == null:
		return
	if not crop.is_ripe():
		UI.post_message("Not ripe yet")
		return
	var produce := crop.data.produce
	if not GameState.inventory.has_room_for(produce, crop.data.harvest_amount):
		UI.post_message("Your bag is full")
		return
	GameState.inventory.add(produce, crop.data.harvest_amount)
	UI.post_message("+%d %s" % [crop.data.harvest_amount, produce.display_name])
	_crops.erase(cell)
	crop.queue_free()

## Crops watered today grow one step; then all soil dries out.
func _on_day_changed(_day: int) -> void:
	for cell in _crops:
		if is_watered(cell):
			_crops[cell].grow()
	_watered.clear()
	wet_layer.clear()


## True if a physics body (bed, tree, rock...) covers the center of the cell.
func _has_body_at(cell: Vector2i) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = cell_to_world(cell)
	return not grass_layer.get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()


## Blocks every water tile that has no grass on top of it.
func _build_water_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "WaterCollision"
	var tile_size := Vector2(water_layer.tile_set.tile_size)
	for cell in water_layer.get_used_cells():
		if grass_layer.get_cell_source_id(cell) != -1:
			continue
		var shape := RectangleShape2D.new()
		shape.size = tile_size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = cell_to_world(cell)
		body.add_child(collision)
	add_child(body)
