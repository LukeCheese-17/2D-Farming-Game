class_name RecipeData
extends Resource
## Something a village shop makes from materials (better tools, bouquets).

@export var result: ItemData
@export var inputs: Array[ItemData] = []
## How many of each input (same order as inputs).
@export var amounts: Array[int] = []
@export var price := 0
## Taken from the player when the recipe is made (the old tool being upgraded).
@export var replaces: ItemData


func get_cost_text() -> String:
	var parts: PackedStringArray = []
	if replaces:
		parts.append(replaces.display_name)
	for i in inputs.size():
		parts.append("%d %s" % [amounts[i], inputs[i].display_name])
	if price > 0:
		parts.append("%dg" % price)
	return ", ".join(parts)
