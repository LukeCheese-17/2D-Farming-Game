class_name Player
extends CharacterBody2D
## The farmer: 8-way movement, using the held hotbar item on the tile in front,
## fishing, eating and drinking, fighting in the mine, and using things with the
## interact key. The origin is at the feet.

## Emitted on every footstep (used by the "being followed" footsteps).
signal stepped

enum Fishing { NONE, WAITING, MINIGAME }

const SPEED := 80.0
## How long tool animations lock movement before the action happens.
const ACTION_TIME := 0.5
const SWING_TIME := 0.3
const BITE_WAIT_MIN := 1.5
const BITE_WAIT_MAX := 5.0
## Weapon reach: enemies within this distance of a point just in front get hit.
const REACH := 18.0
const REACH_OFFSET := 12.0
## Seconds of safety after being hit.
const HURT_COOLDOWN := 0.9
const KNOCKBACK := 140.0
## Rows of "Basic Charakter Actions.png" with the axe swing, per direction.
const CHOP_ROWS := {"front": 192, "back": 240, "left": 288, "right": 336}

## The area the player starts in.
@export var farm: Farm
@export var tile_highlight: TileHighlight

## The area the player is in now (the farm or a mine floor).
var area: WorldArea
## True while inside the house.
var indoors := false
## True while down the mine.
var in_mine := false
var facing := Vector2.DOWN

var _busy := false
var _interactables: Array[InteractArea] = []
var _prompt := ""
var _fishing := Fishing.NONE
var _fishing_timer := 0.0
var _fishing_cell := Vector2i.ZERO
var _hurt_time := 0.0
var _knockback := Vector2.ZERO

@onready var _inventory: Inventory = GameState.inventory
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _camera: Camera2D = $Camera2D
@onready var _bobber: Sprite2D = $Bobber
@onready var _line: Line2D = $FishingLine
@onready var _step_sound: AudioStreamPlayer = $StepSound
@onready var _bite_sound: AudioStreamPlayer = $BiteSound
@onready var _splash_sound: AudioStreamPlayer = $SplashSound
var _sounds: Dictionary[String, AudioStreamPlayer] = {}


func _ready() -> void:
	area = farm
	set_camera_limits(farm.get_map_rect())
	_inventory.selection_changed.connect(_update_highlight)
	_inventory.changed.connect(_update_highlight)
	_sprite.frame_changed.connect(_on_frame_changed)
	_add_chopping_animations()
	_apply_look()
	UI.look_changed.connect(func(_look: String) -> void: _apply_look())
	for sound in ["chop", "pick", "swing", "hurt", "eat", "drink", "enemy_hit"]:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://assets/Generated/%s.wav" % sound)
		player.volume_db = -8.0
		player.bus = &"Master"
		add_child(player)
		_sounds[sound] = player


func _physics_process(delta: float) -> void:
	_update_prompt()
	_hurt_time = maxf(_hurt_time - delta, 0.0)
	_sprite.visible = _hurt_time <= 0.0 or int(_hurt_time * 12.0) % 2 == 0
	if _fishing != Fishing.NONE:
		_update_fishing(delta)
		return
	if _knockback.length() > 5.0:
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK * 6.0 * delta)
		move_and_slide()
		return
	if _busy:
		return
	var input := Vector2.ZERO
	if not UI.is_blocking():
		# get_vector() normalizes diagonals, so all 8 directions move at the same speed.
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * SPEED * GameState.get_speed_factor() * area.get_speed_factor(global_position)
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
		use_held_item()
	elif event.is_action_pressed("use_tool") and indoors:
		_eat_held_item()
	elif event.is_action_pressed("interact") and not _interactables.is_empty():
		_interactables.back().interact()


## The tile directly in front of the player, including diagonals.
func get_target_cell() -> Vector2i:
	var from := area.world_to_cell(global_position)
	return area.adjust_target(from, from + Vector2i(roundi(facing.x), roundi(facing.y)))


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


## Moves the player. inside: in the house. new_area: the area they arrive in (null keeps it).
func teleport(target: Vector2, inside: bool, new_area: WorldArea = null) -> void:
	if new_area:
		area = new_area
	in_mine = area is Mine
	global_position = target
	indoors = inside
	facing = Vector2.DOWN
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	_interactables.clear()
	tile_highlight.visible = not inside
	_camera.reset_smoothing()


func add_interactable(interactable: InteractArea) -> void:
	_interactables.append(interactable)


func remove_interactable(interactable: InteractArea) -> void:
	_interactables.erase(interactable)


func _update_prompt() -> void:
	var prompt := ""
	if not UI.is_blocking() and not _interactables.is_empty():
		prompt = _interactables.back().prompt
	if prompt != _prompt:
		_prompt = prompt
		UI.set_prompt(prompt)


## What happens when the player presses the use key, in order: hit an enemy in
## reach, cast the rod, use the item on the tile (a sword can still harvest and
## collect), swing a sword at nothing, eat it, or drink from water.
func use_held_item() -> void:
	var item := _inventory.get_selected_item()
	var cell := get_target_cell()
	var is_weapon := item != null and item.tool == Tools.Type.SWORD
	if not _enemies_in_reach().is_empty() or (is_weapon and not area.can_use(item, cell)):
		_attack(item)
		return
	if item and item.tool == Tools.Type.FISHING_ROD:
		if area.is_fishable(cell):
			_start_fishing(cell)
		return
	if area.can_use(item, cell):
		var animation := area.get_animation(item, cell)
		if animation != "":
			_busy = true
			velocity = Vector2.ZERO
			_sprite.play(animation + _direction_name())
			await get_tree().create_timer(ACTION_TIME).timeout
			_busy = false
		if animation == "chopping_" and item:
			_sounds["chop" if item.tool == Tools.Type.AXE else "pick"].play()
		area.use(item, cell)
		_update_highlight()
		return
	if _eat_held_item():
		return
	if area.is_fishable(cell):
		GameState.drink()
		_sounds["drink"].play()
		UI.post_message("You drink. The water tastes of iron.")


func _eat_held_item() -> bool:
	var item := _inventory.get_selected_item()
	if item == null or not item.is_edible():
		return false
	if GameState.eat(item):
		_sounds["drink" if item.water > item.food else "eat"].play()
		UI.post_message("You eat the %s." % item.display_name.to_lower() if item.food >= item.water else "You drink the %s." % item.display_name.to_lower())
	else:
		UI.post_message("You're not hungry.")
	return true


# --- Fighting (only the mine has anything to fight) ---

func _enemies_in_reach() -> Array[Node]:
	var point := global_position + facing * REACH_OFFSET + Vector2(0, -4)
	var result: Array[Node] = []
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(point) < REACH + 4.0:
			result.append(enemy)
	return result


func _attack(item: ItemData) -> void:
	_busy = true
	velocity = Vector2.ZERO
	_sprite.play("chopping_" + _direction_name())
	_sounds["swing"].play()
	await get_tree().create_timer(SWING_TIME * 0.5).timeout
	var damage := item.damage if item else 1
	var hit := false
	for enemy in _enemies_in_reach():
		enemy.take_hit(damage, global_position)
		hit = true
	if hit:
		_sounds["enemy_hit"].play()
	await get_tree().create_timer(SWING_TIME * 0.5).timeout
	_busy = false


## Called by enemies that touch the player.
func hurt(amount: int, from: Vector2) -> void:
	if _hurt_time > 0.0 or UI.is_blocking():
		return
	_hurt_time = HURT_COOLDOWN
	_knockback = (global_position - from).normalized() * KNOCKBACK
	if is_fishing():
		_stop_fishing()
	_sounds["hurt"].play()
	GameState.hurt(amount)


func is_invulnerable() -> bool:
	return _hurt_time > 0.0


# --- Fishing ---

func _start_fishing(cell: Vector2i) -> void:
	_fishing = Fishing.WAITING
	_fishing_cell = cell
	UI.fishing = true
	_fishing_timer = randf_range(BITE_WAIT_MIN, BITE_WAIT_MAX)
	velocity = Vector2.ZERO
	_sprite.play("idle_" + _direction_name())
	_bobber.global_position = area.cell_to_world(cell)
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
	var fish := GameState.pick_fish(area.get_water(_fishing_cell))
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


## The scene only has the front-facing axe swing; the other directions come from the same sheet.
func _add_chopping_animations() -> void:
	var frames := _sprite.sprite_frames
	var sheet := (frames.get_frame_texture("chopping_front", 0) as AtlasTexture).atlas
	for direction: String in CHOP_ROWS:
		var animation := "chopping_" + direction
		if frames.has_animation(animation):
			continue
		frames.add_animation(animation)
		frames.set_animation_loop(animation, false)
		frames.set_animation_speed(animation, 4.0)
		for i in 2:
			var texture := AtlasTexture.new()
			texture.atlas = sheet
			texture.region = Rect2(i * 48, CHOP_ROWS[direction], 48, 48)
			frames.add_frame(animation, texture)


## Points every frame at the sprite sheet of the chosen look (ART-1).
func _apply_look() -> void:
	var sheet := UI.get_look_texture("sheet")
	var actions := UI.get_look_texture("actions")
	var frames := _sprite.sprite_frames
	for animation in frames.get_animation_names():
		for i in frames.get_frame_count(animation):
			var texture := frames.get_frame_texture(animation, i) as AtlasTexture
			if texture:
				var is_actions := texture.atlas.resource_path.contains("ctions")
				texture.atlas = actions if is_actions else sheet


func _on_frame_changed() -> void:
	if String(_sprite.animation).begins_with("walk_"):
		_step_sound.pitch_scale = randf_range(0.85, 1.1)
		_step_sound.play()
		stepped.emit()


func _update_highlight() -> void:
	var cell := get_target_cell()
	tile_highlight.show_at(area.cell_to_world(cell), area.can_use(_inventory.get_selected_item(), cell))
