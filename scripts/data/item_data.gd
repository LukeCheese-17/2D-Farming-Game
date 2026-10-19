class_name ItemData
extends Resource
## One kind of item that can sit in an inventory slot: tools, seeds, produce,
## fish, animal products. Create a .tres from this script in data/items to add one.

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
## Money the shipping box pays for one of these. 0 means it can't be shipped.
@export var sell_price := 0
## How many fit in one inventory slot.
@export var max_stack := 99
## Set for tools; the item then does that tool's action when used.
@export var tool := Tools.Type.NONE
