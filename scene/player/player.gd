extends CharacterBody2D
## The farmer: 8-way movement, and using the selected tool on the tile in front.
## The node's origin is at the character's feet.

const SPEED := 80.0
## How long tool animations lock movement before the action happens.
const ACTION_TIME := 0.5

@export var farm: Farm
@export var tile_highlight: TileHighlight

var _facing := Vector2.DOWN
var _busy := false
var _interactable: Node = null

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	var map_rect := farm.get_map_rect()
	_camera.limit_left = int(map_rect.position.x)
	_camera.limit_top = int(map_rect.position.y)
	_camera.limit_right = int(map_rect.end.x)
	_camera.limit_bottom = int(map_rect.end.y)
	GameState.tool_changed.connect(_update_highlight)


func _physics_process(_delta: float) -> void:
	if _busy:
		return
	# get_vector() normalizes diagonals, so all 8 directions move at the same speed.
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * SPEED
	move_and_slide()
	if input != Vector2.ZERO:
		_facing = input.normalized()
	_sprite.play(("walk_" if input != Vector2.ZERO else "idle_") + _direction_name())
	_update_highlight()


func _unhandled_input(event: InputEvent) -> void:
	for i in Tools.Type.size():
		if event.is_action_pressed("tool_%d" % (i + 1)):
			GameState.select_tool(i as Tools.Type)
			return
	if _busy:
		return
	if event.is_action_pressed("use_tool"):
		_use_tool()
	elif event.is_action_pressed("interact") and _interactable:
		_interactable.interact()


## The tile directly in front of the player, including diagonals.
func get_target_cell() -> Vector2i:
	return farm.world_to_cell(global_position) + Vector2i(roundi(_facing.x), roundi(_facing.y))


func set_interactable(node: Node) -> void:
	_interactable = node


func clear_interactable(node: Node) -> void:
	if _interactable == node:
		_interactable = null


func _use_tool() -> void:
	var tool := GameState.current_tool
	var cell := get_target_cell()
	var animation := ""
	match tool:
		Tools.Type.HOE:
			animation = "tilling_"
		Tools.Type.WATERING_CAN:
			animation = "watering_"
	if animation != "" and farm.can_use_tool(tool, cell):
		_busy = true
		velocity = Vector2.ZERO
		_sprite.play(animation + _direction_name())
		await get_tree().create_timer(ACTION_TIME).timeout
		_busy = false
	farm.use_tool(tool, cell)
	_update_highlight()


## The sprite sheet has 4 directions, so diagonals use the left/right animations.
func _direction_name() -> String:
	if absf(_facing.x) > 0.1:
		return "right" if _facing.x > 0 else "left"
	return "front" if _facing.y > 0 else "back"


func _update_highlight() -> void:
	var cell := get_target_cell()
	tile_highlight.show_at(farm.cell_to_world(cell), farm.can_use_tool(GameState.current_tool, cell))
