extends SceneTree
## Paints the surface map into scene/main/main.tscn: the farm in the middle, woods and
## a pond to the north, a river with bridges to the east, the abandoned village to
## the west and the rocky way to the mine to the south. Only the tile layers'
## tile_map_data lines are rewritten, so everything else in the scene is kept.
##   godot --headless --path . -s tools/build_world.gd
## Re-running it repaints the map from scratch (same seed, same map).

const SCENE := "res://scene/main/main.tscn"
const W := 112
const H := 84

const WATER_SOURCE := 0
const GRASS_SET := 0
const GRASS_TERRAIN := 0
const GRASS_SOURCE := 1
const CENTER := Vector2i(1, 1)
## Alternative of the center grass tile that can't be tilled (outside the farm).
const WILD_GRASS := 1
const NATURE := 4
const PATH_SOURCE := 6
const BRIDGE_SOURCE := 7

const BIG_TREE := Vector2i(1, 0)
const APPLE_TREE := Vector2i(3, 0)
const SMALL_TREE := Vector2i(0, 0)
const HUGE_TREE := Vector2i(2, 5)
const BERRY_BUSH := Vector2i(0, 3)
const BUSH := Vector2i(1, 3)
const ROCKS: Array[Vector2i] = [Vector2i(7, 1), Vector2i(8, 1), Vector2i(5, 4), Vector2i(6, 4)]
const STUMPS: Array[Vector2i] = [Vector2i(3, 2), Vector2i(4, 2)]
const MUSHROOMS: Array[Vector2i] = [Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0)]
const WEEDS: Array[Vector2i] = [Vector2i(5, 1), Vector2i(6, 1)]
const FLOWERS: Array[Vector2i] = [Vector2i(6, 2), Vector2i(7, 2), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3)]

## Areas, in cells. Keep in sync with Farm's exports in main.tscn.
const FARM := Rect2i(42, 28, 40, 34)
const POND_CENTER := Vector2(24, 13)
const POND_RADIUS := Vector2(6.5, 4.5)
const VILLAGE := Rect2i(8, 34, 28, 26)
const MINE_AREA := Rect2i(44, 63, 26, 16)
const CLEARING := Vector2(60, 17)
const BRIDGE_ROWS: Array[int] = [14, 44]
const PEN := Rect2i(68, 34, 8, 6)

var _land := {}
var _paths := {}
var _taken := {}
var _noise := FastNoiseLite.new()


func _initialize() -> void:
	seed(20261019)
	_noise.seed = 7
	_noise.frequency = 0.15
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	var water: TileMapLayer = scene.get_node("Ground/Water")
	var grass: TileMapLayer = scene.get_node("Ground/Grass")
	var paths: TileMapLayer = scene.get_node("Ground/Paths")
	var tilled: TileMapLayer = scene.get_node("Ground/TilledDirt")
	var wet: TileMapLayer = scene.get_node("Ground/WetSoil")
	var nature: TileMapLayer = scene.get_node("Objects/Nature")
	var fences: TileMapLayer = scene.get_node("Objects/Fences")

	# Keep the pen's fence layout, moved to PEN.
	var old_fences := {}
	var fence_origin := fences.get_used_rect().position
	for cell in fences.get_used_cells():
		old_fences[cell] = [fences.get_cell_source_id(cell), fences.get_cell_atlas_coords(cell)]
	for layer in [water, grass, paths, tilled, wet, nature, fences]:
		layer.clear()
	for cell: Vector2i in old_fences:
		fences.set_cell(cell - fence_origin + PEN.position, old_fences[cell][0], old_fences[cell][1])
		_take(cell - fence_origin + PEN.position, 0)

	_shape_land()
	for x in W:
		for y in H:
			water.set_cell(Vector2i(x, y), WATER_SOURCE, Vector2i.ZERO)
	var land_cells: Array[Vector2i] = []
	for cell: Vector2i in _land:
		land_cells.append(cell)
	grass.set_cells_terrain_connect(land_cells, GRASS_SET, GRASS_TERRAIN, false)
	# Only farmland can be tilled.
	for cell in land_cells:
		if grass.get_cell_atlas_coords(cell) == CENTER and not is_farmland(cell):
			grass.set_cell(cell, GRASS_SOURCE, CENTER, WILD_GRASS)

	_lay_paths(paths)
	_decorate(nature, grass)

	var text := FileAccess.get_file_as_string(SCENE)
	for layer: TileMapLayer in [water, grass, paths, tilled, wet, nature, fences]:
		text = _set_tile_data(text, layer.name, layer.get_parent().name, layer.tile_map_data)
	FileAccess.open(SCENE, FileAccess.WRITE).store_string(text)
	print("World painted: %d land cells, %d nature tiles." % [land_cells.size(), nature.get_used_cells().size()])
	quit()


# --- Land and water ---

func _shape_land() -> void:
	for x in W:
		for y in H:
			var edge := mini(mini(x, W - 1 - x), mini(y, H - 1 - y))
			if edge < 3 + roundi(_noise.get_noise_2d(x, y) * 1.5 + 0.5):
				continue
			if _is_river(Vector2i(x, y)) or _is_pond(Vector2i(x, y)):
				continue
			_land[Vector2i(x, y)] = true


func river_center(y: int) -> float:
	return 89.0 + 1.6 * sin(y * 0.14)


func _is_river(cell: Vector2i) -> bool:
	return absf(cell.x + 0.5 - river_center(cell.y)) <= 1.8


func _is_pond(cell: Vector2i) -> bool:
	var d := (Vector2(cell) + Vector2(0.5, 0.5) - POND_CENTER) / POND_RADIUS
	return d.length() <= 1.0 + _noise.get_noise_2d(cell.x * 3, cell.y * 3) * 0.15


# --- Paths and bridges ---

func _path_rect(x: int, y: int, w: int, h: int) -> void:
	for xx in range(x, x + w):
		for yy in range(y, y + h):
			_paths[Vector2i(xx, yy)] = true


func _lay_paths(layer: TileMapLayer) -> void:
	_path_rect(14, 44, 87, 2)            # Main road: village to the east bank
	_path_rect(51, 36, 2, 8)             # House door down to the road
	_path_rect(56, 46, 2, 31)            # South to the mine...
	_path_rect(56, 75, 6, 2)             # ...and round to its mouth
	_path_rect(19, 41, 6, 8)             # Village square
	_path_rect(21, 36, 2, 23)            # Village street
	_path_rect(14, 43, 2, 1)             # Doorsteps
	_path_rect(26, 43, 2, 1)
	_path_rect(12, 57, 18, 2)            # Lane in front of the south houses
	_path_rect(60, 18, 2, 18)            # North trail into the woods
	_path_rect(31, 18, 30, 2)            # ...and west to the pond
	_path_rect(71, 40, 2, 4)             # Pen gate to the road
	_path_rect(60, 14, 2, 4)             # North trail on to the woods bridge
	# Bridges (MAP-3): the end pieces with the posts stand on the banks and the
	# planks cover all the water, so there's no gap; a path leads off each end.
	var bridges := {}
	for row in BRIDGE_ROWS:
		var cells: Array[int] = []
		for x in range(80, 100):
			if _is_river(Vector2i(x, row)):
				cells.append(x)
		var west: int = cells.front() - 1
		var east: int = cells.back() + 1
		bridges[Vector2i(west, row)] = 2
		bridges[Vector2i(east, row)] = 4
		for x in cells:
			bridges[Vector2i(x, row)] = 3
		_path_rect(east + 1, row, 4, 1)
		if row == BRIDGE_ROWS[0]:
			_path_rect(62, row, west - 62, 1)
	for cell: Vector2i in _paths.keys():
		if not _land.has(cell):
			_paths.erase(cell)
	for cell: Vector2i in _paths:
		var variant := 3 if randf() < 0.06 else randi_range(0, 2)
		layer.set_cell(cell, PATH_SOURCE, Vector2i(variant, 0))
		_take(cell, 0)
	for cell: Vector2i in bridges:
		layer.set_cell(cell, BRIDGE_SOURCE, Vector2i(bridges[cell], 0))
		_paths[cell] = true
		_take(cell + Vector2i.UP, 0)
		_take(cell + Vector2i.DOWN, 0)


# --- Trees, rocks and the rest ---

## The tillable part of the farm, with a ragged edge.
func is_farmland(cell: Vector2i) -> bool:
	if FARM.grow(-2).has_point(cell):
		return true
	return FARM.grow(1).has_point(cell) and _noise.get_noise_2d(cell.x * 2, cell.y * 2) > 0.0


func _try_tree(layer: TileMapLayer, cell: Vector2i) -> void:
	if randf() >= _tree_density(cell):
		return
	var roll := randf()
	var tile := APPLE_TREE if roll < 0.06 else (SMALL_TREE if roll < 0.3 else (HUGE_TREE if roll < 0.5 else BIG_TREE))
	# Woods trees may stand close together; elsewhere they keep their distance.
	var dense := cell.y < 27 or cell.x > 92
	_place(layer, cell, tile, 1 if tile == HUGE_TREE or not (dense or tile == SMALL_TREE) else 0)


func _take(cell: Vector2i, radius: int) -> void:
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			_taken[cell + Vector2i(x, y)] = true


func _free(cell: Vector2i, radius: int) -> bool:
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var c := cell + Vector2i(x, y)
			if _taken.has(c) or not _land.has(c) or _paths.has(c):
				return false
	return true


func _place(layer: TileMapLayer, cell: Vector2i, tile: Vector2i, radius := 0) -> bool:
	if not _free(cell, radius):
		return false
	layer.set_cell(cell, NATURE, tile)
	_take(cell, radius)
	return true


func _tree_density(cell: Vector2i) -> float:
	if FARM.grow(-2).has_point(cell) or VILLAGE.has_point(cell) or MINE_AREA.has_point(cell):
		return 0.0
	if Vector2(cell).distance_to(CLEARING) < 4.5:
		return 0.0
	if cell.y < 27:
		return 0.5  # The woods
	if cell.x > 92:
		return 0.35  # East bank
	return 0.22


func _decorate(layer: TileMapLayer, _grass: TileMapLayer) -> void:
	# Keep space clear around the buildings placed in main.tscn.
	for r: Rect2i in [Rect2i(46, 30, 12, 7), Rect2i(53, 33, 4, 3), Rect2i(11, 37, 8, 7), Rect2i(23, 37, 8, 7),
			Rect2i(11, 50, 8, 7), Rect2i(23, 50, 8, 7), Rect2i(17, 46, 10, 4), Rect2i(53, 70, 12, 8),
			Rect2i(55, 41, 6, 3), Rect2i(34, 41, 4, 3)]:
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				_taken[Vector2i(x, y)] = true

	# Trees, on a jittered 2-cell grid so the big ones don't overlap.
	for bx in range(0, W, 2):
		for by in range(0, H, 2):
			for attempt in 2:
				_try_tree(layer, Vector2i(bx + randi_range(0, 1), by + randi_range(0, 1)))

	# Woods floor: berry bushes, mushrooms, weeds.
	for i in 900:
		var cell := Vector2i(randi_range(4, W - 5), randi_range(4, H - 5))
		var in_woods := cell.y < 27 or cell.x > 92
		var in_farm := FARM.has_point(cell)
		var in_village := VILLAGE.has_point(cell)
		var in_mine := MINE_AREA.has_point(cell)
		var roll := randf()
		if in_mine:
			_place(layer, cell, ROCKS.pick_random() if roll < 0.7 else STUMPS.pick_random())
		elif in_village:
			if roll < 0.25:
				_place(layer, cell, WEEDS.pick_random())
			elif roll < 0.35:
				_place(layer, cell, ROCKS.pick_random())
			elif roll < 0.42:
				_place(layer, cell, FLOWERS.pick_random())
		elif in_farm:
			# A few things to clear from the field.
			if roll < 0.03:
				_place(layer, cell, ROCKS.pick_random())
			elif roll < 0.05:
				_place(layer, cell, STUMPS.pick_random())
			elif roll < 0.1:
				_place(layer, cell, WEEDS.pick_random())
		elif in_woods:
			if roll < 0.18:
				_place(layer, cell, BERRY_BUSH if randf() < 0.6 else BUSH)
			elif roll < 0.36:
				_place(layer, cell, MUSHROOMS.pick_random())
			elif roll < 0.5:
				_place(layer, cell, WEEDS.pick_random())
			elif roll < 0.58:
				_place(layer, cell, ROCKS.pick_random())
			elif roll < 0.66:
				_place(layer, cell, FLOWERS.pick_random())
		else:
			if roll < 0.12:
				_place(layer, cell, FLOWERS.pick_random())
			elif roll < 0.22:
				_place(layer, cell, WEEDS.pick_random())
			elif roll < 0.27:
				_place(layer, cell, ROCKS.pick_random())
			elif roll < 0.3:
				_place(layer, cell, BERRY_BUSH)
	# The mine approach is properly rocky.
	for i in 60:
		_place(layer, Vector2i(randi_range(MINE_AREA.position.x, MINE_AREA.end.x), randi_range(MINE_AREA.position.y, MINE_AREA.end.y)), ROCKS.pick_random())


# --- Writing the scene ---

func _set_tile_data(text: String, node_name: String, parent: String, data: PackedByteArray) -> String:
	var header := '[node name="%s" type="TileMapLayer" parent="%s"]' % [node_name, parent]
	var start := text.find(header)
	assert(start >= 0, "Layer %s not found" % node_name)
	var body_start := start + header.length()
	var next := text.find("\n[", body_start)
	if next < 0:
		next = text.length()
	var lines := text.substr(body_start, next - body_start).split("\n")
	var out: PackedStringArray = []
	for line in lines:
		if not line.begins_with("tile_map_data = "):
			out.append(line)
	if data.is_empty():
		return text.substr(0, body_start) + "\n".join(out) + text.substr(next)
	var value := 'tile_map_data = PackedByteArray("%s")' % Marshalls.raw_to_base64(data)
	# Insert before tile_set so the order matches what the editor writes.
	var at := out.size()
	for i in out.size():
		if out[i].begins_with("tile_set = "):
			at = i
	out.insert(at, value)
	return text.substr(0, body_start) + "\n".join(out) + text.substr(next)
