class_name Animal
extends Node2D
## A farm animal that wanders around its pen, a cell at a time so it never walks
## through a fence. Once a day it has a product (shown above it) that the player
## collects with the hand.

@export var data: AnimalData

var has_product := true
## Cells it may wander over (its pen), and how to turn a cell into a position.
var _cells: Dictionary[Vector2i, bool] = {}
var _area: WorldArea

var _target := Vector2.ZERO
var _wait := 0.0
var _stare_time := 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _bubble: Sprite2D = $ProductBubble


func _ready() -> void:
	add_to_group("animals")
	_sprite.sprite_frames = data.sprite_frames
	_sprite.position = data.sprite_offset
	_sprite.play("idle")
	var height := data.sprite_frames.get_frame_texture("idle", 0).get_size().y
	_bubble.texture = data.product.icon
	_bubble.position = Vector2(0, data.sprite_offset.y - height / 2.0 - 4.0)
	GameState.day_changed.connect(_on_day_changed)
	_target = global_position
	_wait = randf_range(0.5, 3.0)
	_bubble.visible = has_product


## Where it may wander: the cells of its pen.
func set_pen(area: WorldArea, cells: Array[Vector2i]) -> void:
	_area = area
	_cells.clear()
	for cell in cells:
		_cells[cell] = true
	_target = global_position


func _process(delta: float) -> void:
	if _stare_time > 0.0:
		_stare_time -= delta
		return
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_target = _next_target()
		return
	var to_target := _target - global_position
	if to_target.length() < 1.0:
		# Sometimes it keeps going, sometimes it stops to peck or chew.
		_wait = randf_range(0.0, 0.4) if randf() < 0.4 else randf_range(1.5, 4.5)
		_sprite.play("idle")
		return
	global_position += to_target.normalized() * minf(data.speed * delta, to_target.length())
	_sprite.flip_h = to_target.x < 0.0
	_sprite.play("walk")


## A spot in a neighbouring cell of the pen (or back into the pen if it's outside it).
func _next_target() -> Vector2:
	if _area == null or _cells.is_empty():
		return global_position
	var here := _area.world_to_cell(global_position)
	var choices: Array[Vector2i] = []
	if _cells.has(here):
		choices.append(here)
		for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if _cells.has(here + side):
				choices.append(here + side)
	else:
		choices.assign(_cells.keys())
	var cell: Vector2i = choices.pick_random()
	return _area.cell_to_world(cell) + Vector2(randf_range(-5.0, 5.0), randf_range(-4.0, 5.0))


func collect() -> void:
	if not has_product:
		return
	if not GameState.inventory.has_room_for(data.product):
		UI.post_message("Your bag is full")
		return
	has_product = false
	_bubble.hide()
	GameState.inventory.add(data.product)
	UI.post_message("+1 %s" % data.product.display_name)


## Stops and stares toward a point for a while (part of the "being watched" atmosphere).
func stare_at(point: Vector2, seconds: float) -> void:
	_stare_time = seconds
	_sprite.play("idle")
	_sprite.flip_h = point.x < global_position.x


func set_has_product(value: bool) -> void:
	has_product = value
	if is_node_ready():
		_bubble.visible = value


func _on_day_changed(_day: int) -> void:
	has_product = true
	_bubble.show()
