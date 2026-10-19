class_name BuildingData
extends Resource
## A ruined village building the player can rebuild by handing in materials (VIL-1).

@export var id: StringName
@export var display_name: String
## Shown while it's still a ruin.
@export_multiline var ruin_text := ""
@export var materials: Array[ItemData] = []
## How many of each material (same order as materials).
@export var amounts: Array[int] = []
@export var price := 0
## What it offers once rebuilt.
@export var shop: ShopData
