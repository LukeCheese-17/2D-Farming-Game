class_name Enemy
extends CharacterBody2D
## Something living in the mine (EnemyData). Hurts the player on touch and can be
## fought with any tool (swords hit hardest). Created by Mine; never above ground.

const TOUCH_DISTANCE := 11.0
const WANDER_SPEED := 10.0
const LUNGE_WINDUP := 0.6
const LUNGE_TIME := 0.35
const LUNGE_REST := 1.2
## The stalker freezes while the player faces it this directly.
const LOOK_DOT := 0.35
const BLINK_GAP := Vector2(3.0, 5.0)
const BLINK_DISTANCE := 44.0

var data: EnemyData
var health := 1

var _player: Player
var _mine: Mine
var _sprite := AnimatedSprite2D.new()
var _growl := AudioStreamPlayer2D.new()
var _phase := "idle"
var _phase_time := 0.0
var _lunge_direction := Vector2.ZERO
var _wander_target := Vector2.ZERO
var _knockback := Vector2.ZERO
var _growl_time := 0.0
var _dying := false


## Call before adding to the tree.
func setup(enemy_data: EnemyData, player: Player, mine: Mine) -> void:
	data = enemy_data
	health = data.health
	_player = player
	_mine = mine


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 0
	collision_mask = 1
	_sprite.sprite_frames = data.sprite_frames
	var height := data.sprite_frames.get_frame_texture("move", 0).get_height()
	_sprite.offset = Vector2(0, -height / 2.0 + 2.0)
	_sprite.play("move")
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)
	_growl.stream = preload("res://assets/Generated/growl.wav")
	_growl.max_distance = 220.0
	_growl.pitch_scale = randf_range(0.6, 1.1)
	_growl.volume_db = -6.0
	add_child(_growl)
	_wander_target = position
	_phase_time = randf_range(BLINK_GAP.x, BLINK_GAP.y)
	_growl_time = randf_range(2.0, 6.0)


func _physics_process(delta: float) -> void:
	if _dying or UI.is_blocking() or _player.area != _mine:
		return
	var to_player := _player.global_position - global_position
	var distance := to_player.length()
	var awake := distance < data.sight
	velocity = Vector2.ZERO
	match data.behavior:
		EnemyData.Behavior.CHASE:
			velocity = to_player.normalized() * data.speed if awake else _wander(delta)
		EnemyData.Behavior.LUNGE:
			_lunge(delta, to_player, awake)
		EnemyData.Behavior.STALK:
			var watched := _player.facing.dot(-to_player.normalized()) > LOOK_DOT
			if awake and not watched:
				velocity = to_player.normalized() * data.speed
				_sprite.play("move")
			else:
				_sprite.pause()
		EnemyData.Behavior.BLINK:
			velocity = to_player.normalized() * data.speed if awake else _wander(delta)
			if awake:
				_phase_time -= delta
				if _phase_time <= 0.0:
					_phase_time = randf_range(BLINK_GAP.x, BLINK_GAP.y)
					_blink()
	if _knockback.length() > 5.0:
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, 600.0 * delta)
	move_and_slide()
	if velocity.x != 0.0:
		_sprite.flip_h = velocity.x < 0.0
	if awake:
		_growl_time -= delta
		if _growl_time <= 0.0:
			_growl_time = randf_range(4.0, 9.0)
			_growl.play()
	if distance < TOUCH_DISTANCE:
		_player.hurt(data.damage, global_position)


func _wander(delta: float) -> Vector2:
	_phase_time -= delta
	if _phase_time <= 0.0 or position.distance_to(_wander_target) < 2.0:
		_phase_time = randf_range(2.0, 4.0)
		_wander_target = position + Vector2(randf_range(-32, 32), randf_range(-32, 32))
	return (_wander_target - position).normalized() * WANDER_SPEED


## Waits, shivers, then leaps.
func _lunge(delta: float, to_player: Vector2, awake: bool) -> void:
	_phase_time -= delta
	match _phase:
		"idle":
			_sprite.position = Vector2.ZERO
			if awake:
				_phase = "windup"
				_phase_time = LUNGE_WINDUP
		"windup":
			_sprite.position.x = randf_range(-1.0, 1.0)
			if _phase_time <= 0.0:
				_phase = "dash"
				_phase_time = LUNGE_TIME
				_lunge_direction = to_player.normalized()
		"dash":
			_sprite.position = Vector2.ZERO
			velocity = _lunge_direction * data.speed
			if _phase_time <= 0.0:
				_phase = "rest"
				_phase_time = LUNGE_REST
		"rest":
			if _phase_time <= 0.0:
				_phase = "idle"


## Fades out and comes back somewhere closer.
func _blink() -> void:
	var angle := randf() * TAU
	var target := _player.global_position + Vector2.from_angle(angle) * BLINK_DISTANCE
	if not _mine.is_open(_mine.world_to_cell(target)):
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void: global_position = target)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)


func take_hit(damage: int, from: Vector2) -> void:
	if _dying:
		return
	health -= damage
	_knockback = (global_position - from).normalized() * 160.0
	_phase = "rest"
	_phase_time = LUNGE_REST * 0.5
	var tween := create_tween()
	_sprite.modulate = Color(2.0, 1.4, 1.4)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.2)
	if health <= 0:
		_die()


func _die() -> void:
	_dying = true
	remove_from_group("enemies")
	if data.drop and randf() < data.drop_chance and GameState.inventory.add(data.drop) == 0:
		UI.post_message("+1 %s" % data.drop.display_name)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(0, 0, 0, 0), 0.5)
	tween.tween_callback(queue_free)
