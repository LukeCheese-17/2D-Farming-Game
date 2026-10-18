class_name CropData
extends Resource
## Defines one crop type. To add a crop, create a new .tres from this
## script in data/crops and list it in GameState.crops.

@export var id: StringName
@export var display_name: String
## Sprites for each growth stage, from just planted to ripe.
@export var stage_textures: Array[Texture2D] = []
## Number of watered days needed to go from planted to ripe.
@export var days_to_grow := 3
@export var harvest_amount := 1
@export var seed_icon: Texture2D
@export var produce_icon: Texture2D

## Inventory item id for this crop's seeds.
var seed_item: StringName:
	get:
		return StringName("%s_seeds" % id)

## Inventory item id for this crop's harvested produce.
var produce_item: StringName:
	get:
		return id


## Growth stage (index into stage_textures) after the given number of watered days.
func get_stage(watered_days: int) -> int:
	var last_stage := stage_textures.size() - 1
	if watered_days >= days_to_grow:
		return last_stage
	return mini(floori(float(watered_days) * last_stage / days_to_grow), last_stage - 1)
