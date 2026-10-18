class_name Animal
extends Node2D
## A farm animal that wanders inside its pen. Once a day it has a product
## (shown above it) that the player collects with the hand.

@export var data: AnimalData
## Area, in world coordinates, the animal wanders in.
@export var wander_rect: Rect2

var has_product := true

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


func _process(delta: float) -> void:
	if _stare_time > 0.0:
		_stare_time -= delta
		return
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_target = Vector2(
				randf_range(wander_rect.position.x, wander_rect.end.x),
				randf_range(wander_rect.position.y, wander_rect.end.y))
		return
	var to_target := _target - global_position
	if to_target.length() < 1.0:
		_wait = randf_range(1.5, 4.5)
		_sprite.play("idle")
		return
	global_position += to_target.normalized() * minf(data.speed * delta, to_target.length())
	_sprite.flip_h = to_target.x < 0.0
	_sprite.play("walk")


func collect() -> void:
	if not has_product:
		return
	has_product = false
	_bubble.hide()
	GameState.add_item(data.product)
	GameState.post_message("+1 %s" % data.product.display_name)


## Stops and stares toward a point for a while (part of the "being watched" atmosphere).
func stare_at(point: Vector2, seconds: float) -> void:
	_stare_time = seconds
	_sprite.play("idle")
	_sprite.flip_h = point.x < global_position.x


func _on_day_changed(_day: int) -> void:
	has_product = true
	_bubble.show()
