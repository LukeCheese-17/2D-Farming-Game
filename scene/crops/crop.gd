class_name Crop
extends Node2D
## A crop planted on one farm tile. Grows one step for each day it was watered.

var data: CropData
var watered_days := 0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_refresh()


## Call before adding the crop to the scene tree.
func setup(crop_data: CropData) -> void:
	data = crop_data


func grow() -> void:
	watered_days = mini(watered_days + 1, data.days_to_grow)
	_refresh()


func is_ripe() -> bool:
	return watered_days >= data.days_to_grow


func _refresh() -> void:
	_sprite.texture = data.stage_textures[data.get_stage(watered_days)]
	# Tall plants (sunflowers) grow upward from the same base.
	_sprite.offset.y = -(_sprite.texture.get_height() - 16) / 2.0
