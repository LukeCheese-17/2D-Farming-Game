extends Node2D
## Makes the farm feel watched without ever showing anything: eyes in the dark
## that vanish when you look at them, footsteps that follow you and stop when you
## stop, animals all staring at the same spot, and small things moved overnight.
## Nothing here can ever touch or hurt the player.

## Seconds between cues, at noon and in the middle of the night.
const DAY_GAP := Vector2(100.0, 170.0)
const NIGHT_GAP := Vector2(25.0, 55.0)
const EYES_MAX_TIME := 7.0
## Eyes vanish if the player gets this close or looks toward them.
const EYES_VANISH_DISTANCE := 70.0
const EYES_LOOK_DOT := 0.85
const ECHO_DELAY := 0.3
const ECHO_DISTANCE := 30.0
## Decorations without collision (flowers, mushrooms, sprouts) that can move overnight.
const MOVABLE_DECOR: Array[Vector2i] = [
	Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0), Vector2i(5, 1), Vector2i(6, 1),
	Vector2i(6, 2), Vector2i(7, 2), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3),
]
const NATURE_SOURCE := 4
const NEIGHBORS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

@export var player: Player
@export var farm: Farm

var _next_cue := 0.0
var _eyes_time := 0.0
var _echo_time := 0.0
var _since_player_step := 0.0

## Drawn on a layer above the night shader so the eyes glow in the dark.
@onready var _eyes: Sprite2D = $Glow/Eyes
@onready var _echo_step: AudioStreamPlayer2D = $EchoStep


func _ready() -> void:
	_eyes.hide()
	player.stepped.connect(_on_player_stepped)
	GameState.day_changed.connect(_on_day_changed)
	_next_cue = randf_range(40.0, 80.0)


func _process(delta: float) -> void:
	_update_eyes(delta)
	_update_echo(delta)
	if UI.is_blocking() or player.in_mine:
		return
	_next_cue -= delta
	if _next_cue > 0.0:
		return
	var darkness := GameState.get_darkness()
	var day_gap := randf_range(DAY_GAP.x, DAY_GAP.y)
	var night_gap := randf_range(NIGHT_GAP.x, NIGHT_GAP.y)
	_next_cue = lerpf(day_gap, night_gap, darkness)
	_play_random_cue(darkness)


func _play_random_cue(darkness: float) -> void:
	if player.indoors:
		_play_steps_outside()
		return
	var cues: Array[Callable] = [_start_following_steps]
	if darkness > 0.3:
		cues.append_array([show_eyes, show_eyes])
	if _animals_near_player():
		cues.append(make_animals_stare)
	cues.pick_random().call()


# --- Eyes in the dark ---

## Shows a pair of eyes somewhere dark near the edge of the view. Returns false if there's no spot.
func show_eyes() -> bool:
	var spot := _find_eyes_spot()
	if spot == Vector2.INF:
		return false
	_eyes.global_position = spot
	_eyes.modulate.a = 0.0
	_eyes.show()
	_eyes_time = EYES_MAX_TIME
	create_tween().tween_property(_eyes, "modulate:a", 1.0, 1.5)
	return true


func _update_eyes(delta: float) -> void:
	if not _eyes.visible:
		return
	_eyes_time -= delta
	var to_eyes := _eyes.global_position - player.global_position
	var looking := to_eyes.normalized().dot(player.facing) > EYES_LOOK_DOT and _eyes_time < EYES_MAX_TIME - 1.0
	if _eyes_time <= 0.0 or to_eyes.length() < EYES_VANISH_DISTANCE or looking or player.indoors or player.in_mine:
		_eyes.hide()


## A tree, bush or shoreline tile in the outer part of the visible area.
func _find_eyes_spot() -> Vector2:
	var view := get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()
	var inner := view.grow(-view.size.y * 0.25)
	var candidates: Array[Vector2] = []
	var top_left := farm.world_to_cell(view.position)
	var bottom_right := farm.world_to_cell(view.end)
	for x in range(top_left.x, bottom_right.x + 1):
		for y in range(top_left.y, bottom_right.y + 1):
			var cell := Vector2i(x, y)
			var center := farm.cell_to_world(cell)
			if inner.has_point(center) or not view.has_point(center):
				continue
			if _is_dark_cover(cell):
				candidates.append(center + Vector2(0, -6))
	return candidates.pick_random() if not candidates.is_empty() else Vector2.INF


func _is_dark_cover(cell: Vector2i) -> bool:
	var nature := farm.nature_layer.get_cell_tile_data(cell)
	if nature and nature.get_collision_polygons_count(0) > 0:
		return true
	if not farm.is_fishable(cell):
		return false
	for offset in NEIGHBORS:
		if farm.grass_layer.get_cell_source_id(cell + offset) != -1:
			return true
	return false


# --- Footsteps ---

func _start_following_steps() -> void:
	_echo_time = randf_range(6.0, 10.0)
	_since_player_step = 0.0


func _on_player_stepped() -> void:
	_since_player_step = 0.0
	if _echo_time <= 0.0:
		return
	await get_tree().create_timer(ECHO_DELAY).timeout
	_play_step(player.global_position - player.facing * ECHO_DISTANCE)


## The follower stops one step after the player does, then the cue ends.
func _update_echo(delta: float) -> void:
	_since_player_step += delta
	if _echo_time <= 0.0:
		return
	_echo_time -= delta
	if _since_player_step > ECHO_DELAY + 0.25 and _since_player_step < 1.0:
		_play_step(player.global_position - player.facing * ECHO_DISTANCE)
		_echo_time = 0.0


## Slow footsteps walking past outside the house walls.
func _play_steps_outside() -> void:
	var start := player.global_position + Vector2(-90, randf_range(-40, 40))
	for i in 5:
		_play_step(start + Vector2(i * 36, 0))
		await get_tree().create_timer(0.7).timeout


func _play_step(at: Vector2) -> void:
	_echo_step.global_position = at
	_echo_step.pitch_scale = randf_range(0.7, 0.85)
	_echo_step.play()


# --- Animals ---

func _animals_near_player() -> bool:
	for animal: Animal in get_tree().get_nodes_in_group("animals"):
		if animal.global_position.distance_to(player.global_position) < 220.0:
			return true
	return false


## Every animal stops and stares toward the same spot in the tree line.
func make_animals_stare() -> void:
	var map := farm.get_map_rect()
	var point := Vector2(randf_range(map.position.x, map.end.x), map.position.y)
	for animal: Animal in get_tree().get_nodes_in_group("animals"):
		animal.stare_at(point, randf_range(5.0, 7.0))


# --- Overnight ---

## Some nights a small decoration ends up one tile from where it was.
func _on_day_changed(_day: int) -> void:
	if randf() < 0.5:
		move_random_decoration()


func move_random_decoration() -> bool:
	var layer := farm.nature_layer
	var cells := layer.get_used_cells().filter(func(c: Vector2i) -> bool:
		return layer.get_cell_source_id(c) == NATURE_SOURCE and layer.get_cell_atlas_coords(c) in MOVABLE_DECOR)
	cells.shuffle()
	for cell: Vector2i in cells:
		for offset in NEIGHBORS:
			var target := cell + offset
			if farm.can_till(target):
				layer.set_cell(target, NATURE_SOURCE, layer.get_cell_atlas_coords(cell))
				layer.erase_cell(cell)
				return true
	return false
