class_name FishData
extends Resource
## One kind of fish that can be caught. To add a fish, create a .tres from
## this script in data/fish and list it in GameState.fish.

enum BiteTime { ANY, DAY, NIGHT }

## The inventory item the player gets.
@export var item: ItemData
## Relative chance of catching this fish (higher = more common).
@export var weight := 1
## Which waters it lives in.
@export_flags("Pond", "River", "Lake") var places := 7
## When it bites. Night is from 19:00.
@export var time := BiteTime.ANY

@export_group("Minigame")
## Size of the target zone on the dial, in degrees (smaller = harder).
@export_range(10.0, 180.0) var zone_degrees := 70.0
## How fast the needle sweeps, in degrees per second.
@export var needle_speed := 200.0
## Hits in a row needed to land the fish.
@export_range(1, 5) var hits_needed := 2


## place is one of Farm.Water (POND = 1, RIVER = 2, LAKE = 4).
func can_bite(place: int, night: bool) -> bool:
	if not places & place:
		return false
	return time == BiteTime.ANY or (time == BiteTime.NIGHT) == night
