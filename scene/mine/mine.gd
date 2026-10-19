class_name Mine
extends WorldArea
## The old mine under the hills: five floors, each its own biome with its own
## rocks, ores and things living in the dark (MIN-1..3). A floor is dug out fresh
## every time the player climbs down to it. The enemies never leave the mine (ATM-1).

## The player climbed the ladder back up to the surface.
signal exit_requested
## The player wants the next floor down.
signal descend_requested

## Floor size in cells (plus a wall border around it).
const SIZE := Vector2i(40, 28)
const TILE := 16
## Share of the floor that is open ground.
const OPEN_SHARE := 0.4
const TILES := preload("res://assets/Generated/mine_tiles.png")
const ROCKS := preload("res://assets/Generated/mine_rocks.png")
const LADDER_DOWN := preload("res://assets/Generated/ladder_down.png")
const LADDER_UP := preload("res://assets/Generated/ladder_up.png")
const TORCH := preload("res://assets/Generated/torch.png")
const PHONE := preload("res://assets/Generated/phone.png")
const SWORD := preload("res://data/items/rusty_sword.tres")
const INTERACT := preload("res://scripts/interact_area.gd")
const ENEMY := preload("res://scene/mine/enemy.gd")
const DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

@export var player: Player

## 0-based floor index, or -1 while nobody is down here.
var floor_index := -1
var floor_data: MineFloorData

var _open: Dictionary[Vector2i, bool] = {}
## cell -> the rock's StaticBody2D (with "ore" and "hits" metadata).
var _rocks: Dictionary[Vector2i, StaticBody2D] = {}
var _start := Vector2i.ZERO

var _ground := TileMapLayer.new()
var _walls := TileMapLayer.new()
var _objects := Node2D.new()
var _drone := AudioStreamPlayer.new()


func _ready() -> void:
	y_sort_enabled = true
	var tile_set := _make_tile_set()
	for layer in [_ground, _walls]:
		layer.tile_set = tile_set
		layer.z_index = -1
		add_child(layer)
	_objects.y_sort_enabled = true
	add_child(_objects)
	_drone.stream = preload("res://assets/Generated/mine_drone.wav")
	_drone.volume_db = -14.0
	add_child(_drone)


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(((world_position - global_position) / TILE).floor())


func cell_to_world(cell: Vector2i) -> Vector2:
	return global_position + Vector2(cell) * TILE + Vector2(TILE, TILE) / 2.0


func get_map_rect() -> Rect2:
	return Rect2(global_position - Vector2(TILE, TILE), Vector2(SIZE + Vector2i(2, 2)) * TILE)


func is_open(cell: Vector2i) -> bool:
	return _open.has(cell) and not _rocks.has(cell)


func can_use(item: ItemData, cell: Vector2i) -> bool:
	return item != null and item.tool == Tools.Type.PICKAXE and _rocks.has(cell)


func get_animation(_item: ItemData, _cell: Vector2i) -> String:
	return "chopping_"


func use(item: ItemData, cell: Vector2i) -> void:
	if not can_use(item, cell):
		return
	var rock := _rocks[cell]
	var hits: int = rock.get_meta("hits") + item.tool_power
	rock.set_meta("hits", hits)
	var sprite: Sprite2D = rock.get_child(0)
	var tween := create_tween()
	tween.tween_property(sprite, "position:x", 1.0, 0.05)
	tween.tween_property(sprite, "position:x", 0.0, 0.05)
	var ore: ItemData = rock.get_meta("ore") if rock.has_meta("ore") else null
	var hardness := floor_data.rock_hardness + (1 if ore else 0)
	if hits < hardness:
		return
	_rocks.erase(cell)
	rock.queue_free()
	_give(floor_data.stone, 1)
	if ore:
		_give(ore, 1)


## The arrival point on this floor.
func get_start_position() -> Vector2:
	return cell_to_world(_start) + Vector2(0, TILE)


## Digs out a fresh floor (0-based) and puts the player at its ladder.
func enter_floor(index: int) -> void:
	floor_index = index
	floor_data = GameState.mine_floors[index]
	GameState.deepest_floor = maxi(GameState.deepest_floor, index + 1)
	_generate()
	if not _drone.playing:
		_drone.play()
	_drone.pitch_scale = 1.0 - index * 0.06


## Clears the floor when the player leaves.
func leave() -> void:
	floor_index = -1
	_drone.stop()
	_clear()


func is_last_floor() -> bool:
	return floor_index == GameState.mine_floors.size() - 1


# --- Building a floor ---

func _make_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	var source := TileSetAtlasSource.new()
	source.texture = TILES
	source.texture_region_size = Vector2i(TILE, TILE)
	tile_set.add_source(source, 0)
	var half := TILE / 2.0
	for biome in 5:
		for row in 3:
			source.create_tile(Vector2i(biome, row))
		var wall := source.get_tile_data(Vector2i(biome, 2), 0)
		wall.add_collision_polygon(0)
		wall.set_collision_polygon_points(0, 0, PackedVector2Array([
			Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]))
	return tile_set


func _clear() -> void:
	_ground.clear()
	_walls.clear()
	_open.clear()
	_rocks.clear()
	for child in _objects.get_children():
		child.queue_free()


func _generate() -> void:
	_clear()
	_carve()
	var distances := _distances_from(_start)
	var farthest := _start
	for cell: Vector2i in distances:
		if distances[cell] > distances[farthest]:
			farthest = cell

	var biome := floor_data.biome
	for x in range(-1, SIZE.x + 1):
		for y in range(-1, SIZE.y + 1):
			var cell := Vector2i(x, y)
			if _open.has(cell):
				_ground.set_cell(cell, 0, Vector2i(biome, 1 if randf() < 0.2 else 0))
			else:
				_walls.set_cell(cell, 0, Vector2i(biome, 2))

	_add_ladder(_start, LADDER_UP, "E: Climb up", exit_requested.emit)
	if is_last_floor():
		if not GameState.flags.get("deep_call", false):
			_add_deep_phone(farthest)
	else:
		_add_ladder(farthest, LADDER_DOWN, "E: Climb down", descend_requested.emit)
	if floor_index == 0 and not GameState.flags.get("found_sword", false):
		_add_sword(_start + Vector2i(2, 0) if _open.has(_start + Vector2i(2, 0)) else _start + Vector2i(0, 1))

	var cells: Array[Vector2i] = []
	for cell: Vector2i in distances:
		cells.append(cell)
	cells.shuffle()
	var placed := 0
	for cell in cells:
		if placed >= floor_data.rock_count:
			break
		if distances[cell] < 3 or cell.distance_to(farthest) < 2.0:
			continue
		_add_rock(cell)
		placed += 1
	for i in 4:
		var torch_cells := cells.filter(func(c: Vector2i) -> bool: return distances[c] >= 2 and distances[c] <= 7 and not _rocks.has(c))
		if not torch_cells.is_empty():
			var sprite := Sprite2D.new()
			sprite.texture = TORCH
			sprite.position = cell_to_world(torch_cells.pick_random()) - global_position
			_objects.add_child(sprite)
	var spawn_cells := cells.filter(func(c: Vector2i) -> bool: return distances[c] >= 10 and not _rocks.has(c))
	for i in mini(floor_data.enemy_count, spawn_cells.size()):
		_add_enemy(spawn_cells[i])


## Random walk from the middle, smoothed, keeping only what connects to the start.
func _carve() -> void:
	_start = SIZE / 2
	var cell := _start
	_open[cell] = true
	var target := int(SIZE.x * SIZE.y * OPEN_SHARE)
	var steps := 0
	while _open.size() < target and steps < 20000:
		steps += 1
		cell += DIRECTIONS.pick_random()
		cell = cell.clamp(Vector2i(1, 1), SIZE - Vector2i(2, 2))
		_open[cell] = true
		if randf() < 0.35:
			_open[(cell + Vector2i(1, 0)).clamp(Vector2i(1, 1), SIZE - Vector2i(2, 2))] = true
	for pass_index in 2:
		var next: Dictionary[Vector2i, bool] = {}
		for x in range(1, SIZE.x - 1):
			for y in range(1, SIZE.y - 1):
				var c := Vector2i(x, y)
				var around := 0
				for ox in range(-1, 2):
					for oy in range(-1, 2):
						if (ox != 0 or oy != 0) and _open.has(c + Vector2i(ox, oy)):
							around += 1
				if (_open.has(c) and around >= 3) or around >= 6:
					next[c] = true
		_open = next
	# Make sure there's room to arrive.
	for ox in range(-1, 2):
		for oy in range(-1, 3):
			_open[_start + Vector2i(ox, oy)] = true
	var reachable := _distances_from(_start)
	for c in _open.keys():
		if not reachable.has(c):
			_open.erase(c)


func _distances_from(from: Vector2i) -> Dictionary[Vector2i, int]:
	var distances: Dictionary[Vector2i, int] = {from: 0}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for d in DIRECTIONS:
			var n := c + d
			if _open.has(n) and not distances.has(n):
				distances[n] = distances[c] + 1
				queue.append(n)
	return distances


func _add_interactable(node: Node2D, prompt: String, size: Vector2, action: Callable) -> InteractArea:
	var area: InteractArea = INTERACT.new()
	area.prompt = prompt
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	area.add_child(shape)
	area.interacted.connect(action)
	node.add_child(area)
	return area


func _add_ladder(cell: Vector2i, texture: Texture2D, prompt: String, action: Callable) -> void:
	var ladder := Node2D.new()
	ladder.position = cell_to_world(cell) - global_position
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.z_index = -1
	ladder.add_child(sprite)
	_add_interactable(ladder, prompt, Vector2(22, 22), action)
	_objects.add_child(ladder)


func _add_rock(cell: Vector2i) -> void:
	var ore: ItemData = null
	if randf() < floor_data.ore_chance:
		ore = floor_data.ore
	elif floor_data.rare_ore and randf() < floor_data.rare_chance:
		ore = floor_data.rare_ore
	var rock := StaticBody2D.new()
	rock.position = cell_to_world(cell) - global_position
	rock.set_meta("ore", ore)
	rock.set_meta("hits", 0)
	var sprite := Sprite2D.new()
	var texture := AtlasTexture.new()
	texture.atlas = ROCKS
	texture.region = Rect2(floor_data.biome * TILE, TILE if ore else 0, TILE, TILE)
	sprite.texture = texture
	sprite.offset = Vector2(0, -2)
	rock.add_child(sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 8)
	shape.shape = rect
	shape.position = Vector2(0, 2)
	rock.add_child(shape)
	_objects.add_child(rock)
	_rocks[cell] = rock


func _add_enemy(cell: Vector2i) -> void:
	var enemy: Enemy = ENEMY.new()
	enemy.setup(floor_data.enemies.pick_random(), player, self)
	enemy.position = cell_to_world(cell) - global_position
	_objects.add_child(enemy)


## The first time down, an old sword is stuck in the ground by the ladder.
func _add_sword(cell: Vector2i) -> void:
	var node := Node2D.new()
	node.position = cell_to_world(cell) - global_position
	var sprite := Sprite2D.new()
	sprite.texture = SWORD.icon
	sprite.rotation = -0.6
	node.add_child(sprite)
	_add_interactable(node, "E: Take the sword", Vector2(22, 22), func() -> void:
		if GameState.inventory.add(SWORD) > 0:
			UI.post_message("Your bag is full")
			return
		GameState.flags["found_sword"] = true
		UI.show_dialogue(["An old sword, stuck in the ground. The blade is rusted, the handle is warm.", "You take it."])
		node.queue_free())
	_objects.add_child(node)


## At the very bottom there's a telephone. It rings.
func _add_deep_phone(cell: Vector2i) -> void:
	var node := Node2D.new()
	node.position = cell_to_world(cell) - global_position
	var sprite := Sprite2D.new()
	sprite.texture = PHONE
	node.add_child(sprite)
	var sound := AudioStreamPlayer2D.new()
	sound.stream = preload("res://assets/Generated/phone_ring.wav")
	sound.max_distance = 260.0
	sound.autoplay = true
	node.add_child(sound)
	_add_interactable(node, "E: Answer the phone", Vector2(24, 24), func() -> void:
		sound.stop()
		GameState.flags["deep_call"] = true
		GameState.add_money(500)
		UI.show_dialogue(["...", "You came all the way down here.", "Go home. I'll call you there.",
			"(The line goes dead. An envelope sits beside the phone: 500g.)"])
		node.queue_free())
	_objects.add_child(node)


func _give(item: ItemData, amount: int) -> void:
	if GameState.inventory.add(item, amount) > 0:
		UI.post_message("Your bag is full")
	else:
		UI.post_message("+%d %s" % [amount, item.display_name])
