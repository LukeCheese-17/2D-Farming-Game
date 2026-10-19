class_name ItemData
extends Resource
## One kind of item that can sit in an inventory slot: tools, seeds, produce,
## fish, animal products, materials, food. Create a .tres from this script in data/items to add one.

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
## Money the shipping box pays for one of these. 0 means it can't be shipped.
@export var sell_price := 0
## What shops charge for one (if they stock it).
@export var buy_price := 0
## How many fit in one inventory slot.
@export var max_stack := 99
## Set for tools; the item then does that tool's action when used.
@export var tool := Tools.Type.NONE
## For axes and pickaxes: how much each swing does (better tools need fewer swings).
@export var tool_power := 1
## For weapons (any tool can hit, weapons hit hardest).
@export var damage := 1

@export_group("Eating")
## How much eating one refills the food meter (0 = not food).
@export var food := 0
## How much eating one refills the water meter.
@export var water := 0


func is_edible() -> bool:
	return food > 0 or water > 0
