class_name ItemData
extends Resource
## One kind of inventory item (seeds, produce, fish, animal products).
## To add an item, create a .tres from this script in data/items and list it in GameState.items.

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
## Money the shipping box pays for one of these. 0 means it can't be shipped.
@export var sell_price := 0
