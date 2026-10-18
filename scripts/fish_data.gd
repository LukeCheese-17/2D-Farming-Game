class_name FishData
extends Resource
## One kind of fish that can be caught. To add a fish, create a .tres from
## this script in data/fish and list it in GameState.fish.

## The inventory item the player gets.
@export var item: ItemData
## Relative chance of catching this fish (higher = more common).
@export var weight := 1
