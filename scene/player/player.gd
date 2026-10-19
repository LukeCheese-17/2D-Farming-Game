class_name Player
extends CharacterBody2D
## The farmer: 8-way movement, using the held hotbar item on the tile in front,
## fishing, and using things with the interact key. The origin is at the feet.

## Emitted on every footstep (used by the "being followed" footsteps).
signal stepped

enum Fishing { NONE, WAITING, MINIGAME }

const SPEED := 80.0
## How long tool animations lock movement before the action happens.
const ACTION_TIME := 0.5
const BITE_WAIT_MIN := 1.5
const BITE_WAIT_MAX := 5.0

@export var farm: Farm
@export var tile_highlight: TileHighlight

## True while inside the house.
var indoors := false
var facing := Vector2.DOWN

var _busy := false
var _interactables: Array[InteractArea] = []
var _prompt := ""
var _fishing := Fishing.NONE
var _fishing_timer := 0.0

@onready var _inventory: Inventory = GameState.inventory
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _camera: Camera2D = $Camera2D
@onready var _bobber: Sprite2D = $Bobber
@onready var _line: Line2D = $FishingLine
@onready var _step_sound: AudioStreamPlayer = $StepSound
@onready var _bite_sound: AudioStreamPlayer = $BiteSound
@onready var _splash_sound: AudioStreamPlayer = $SplashSound


func _ready() -> void:
	set_camera_limits(farm.get_map_rect())
	_inventory.selection_changed.connect(_update_highlight)
	_inventory.changed.connect(_update_highlight)
	_sprite.frame_changed.connect(_on_frame_changed)


func _physics_process(delta: float) -> void:
	_update_prompt()
	if _fishing != Fishing.NONE:
		_update_fishing(delta)
		return
	if _busy:
		return
	var input := Vector2.ZERO
	if not UI.is_blocking():
		# get_vector() normalizes diagonals, so all 8 directions move at the same speed.
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * SPEED
	move_and_slide()
	if input != Vector2.ZERO:
		facing = input.normalized()
	_sprite.play(("walk_" if input != Vector2.ZERO else "idle_") + _direction_name())
	_update_highlight()


func _unhandled_input(event: InputEvent) -> void:
	if UI.is_blocking():
		return
	if _fishing != Fishing.NONE:
		if _fishing == Fishing.WAITING and event.is_action_pressed("use_tool"):
			UI.post_message("Too early. Nothing.")
			_stop_fishing()
		return
	for i in Inventory.HOTBAR_SIZE:
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			_inventory.select(i)
			return
	if event.is_action_pressed("hotbar_next"):
		_inventory.select_next(1)
	elif event.is_action_pressed("hotbar_previous"):
		_inventory.select_next(-1)
	elif _busy:
		return
	elif event.is_action_pressed("use_tool") and not indoors:
		_use_held_item()
	elif event.is_action_pressed("interact") and not _interactables.is_empty():
		_interactables.back().interact()


## The tile directly in front of the player, including diagonals.
func get_target_cell() -> Vector2i:
	return farm.world_to_cell(global_position) + Vector2i(roundi(facing.x), roundi(facing.y))


func is_fishing() -> bool:
	return _fishing != Fishing.NONE


func set_camera_limits(rect: Rect2) -> void:
	_camera.limit_left = int(rect.position.x)
	_camera.limit_top = int(rect.position.y)
	_camera.limit_right = int(rect.end.x)
	_camera.limit_bottom = int(rect.end.y)
	_camera.reset_smoothing()


## Size of the area the camera shows, in world pixels.
func get_view_size() -> Vector2:
	return get_viewport_rect().size / _camera.zoom


func teleport(target: Vector2, inside: bool) -> void:
	global_position = target
	indoors = inside
	facing = Vector2.DOWN
	velocity = Vector2.ZERO
	_interactables.clear()
	tile_highlight.visible = not inside
	_camera.reset_smoothing()


func add_interactable(area: InteractArea) -> void:
	_interactables.append(area)


func remove_interactable(area: InteractArea) -> void:
	_interactables.erase(area)


func _update_prompt() -> void:
	var prompt := ""
	if not UI.is_blocking() and not _interactables.is_empty():
		prompt = _interactables.back().prompt
	if prompt != _prompt:
		_prompt = prompt
		UI.set_prompt(prompt)


func _use_held_item() -> void:
	var item := _inventory.get_selected_item()
	var cell := get_target_cell()
	var action := farm.get_action(item)
	if action == Farm.Action.FISH:
		if farm.is_fishable(cell):
			_start_fishing(cell)
		return
	var animation := ""
	match action:
		Farm.Action.TILL:
			animation = "tilling_"
		Farm.Action.WATER:
			animation = "watering_"
	if animation != "" and farm.can_use(item, cell):
		_busy = true
		velocity = Vector2.ZERO
		_sprite.play(animation + _direction_name())
		await get_tree().create_timer(ACTION_TIME).timeout
		_busy = false
	farm.use(item, cell)
	_update_highlight()


# --- Fishing ---

func _start_fishing(cell: Vector2i) -> void:
	_fishing = Fishing.WAITING
	UI.fishing = true
	_fishing_timer = randf_range(BITE_WAIT_MIN, BITE_WAIT_MAX)
	velocity = Vector2.ZERO
	_sprite.play("idle_" + _direction_name())
	_bobber.global_position = farm.cell_to_world(cell)
	_bobber.show()
	_line.show()
	_update_line()


func _update_fishing(delta: float) -> void:
	if _fishing == Fishing.WAITING:
		_fishing_timer -= delta
		if _fishing_timer <= 0.0:
			_hook_fish()
	_update_line()


## A fish bites: play the timing-ring minigame to land it.
func _hook_fish() -> void:
	_fishing = Fishing.MINIGAME
	_bobber.global_position.y += 2
	_bite_sound.play()
	var fish := GameState.pick_fish()
	UI.start_fishing(fish, global_position)
	var caught: bool = await UI.fishing_finished
	if not caught:
		UI.post_message("It got away.")
	elif _inventory.add(fish.item) > 0:
		UI.post_message("Your bag is full. You let the %s go." % fish.item.display_name)
	else:
		UI.post_message("Caught a %s!" % fish.item.display_name)
		_splash_sound.play()
	_stop_fishing()


func _stop_fishing() -> void:
	_fishing = Fishing.NONE
	UI.fishing = false
	_bobber.hide()
	_line.hide()


func _update_line() -> void:
	var rod_tip := global_position + Vector2(facing.x * 6.0, -12.0)
	_line.points = PackedVector2Array([rod_tip, _bobber.global_position + Vector2(0, -1)])


# --- Animation helpers ---

## The sprite sheet has 4 directions, so diagonals use the left/right animations.
func _direction_name() -> String:
	if absf(facing.x) > 0.1:
		return "right" if facing.x > 0 else "left"
	return "front" if facing.y > 0 else "back"


func _on_frame_changed() -> void:
	if String(_sprite.animation).begins_with("walk_"):
		_step_sound.pitch_scale = randf_range(0.85, 1.1)
		_step_sound.play()
		stepped.emit()


func _update_highlight() -> void:
	var cell := get_target_cell()
	tile_highlight.show_at(farm.cell_to_world(cell), farm.can_use(_inventory.get_selected_item(), cell))
