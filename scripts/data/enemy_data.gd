class_name EnemyData
extends Resource
## Something that lives in the mine. Only the mine spawns these (ATM-1).

enum Behavior {
	## Walks straight at the player once it notices them.
	CHASE,
	## Waits, then leaps at the player.
	LUNGE,
	## Only moves while the player is looking away.
	STALK,
	## Vanishes and reappears closer.
	BLINK,
}

@export var display_name: String
## Needs a looping "move" animation.
@export var sprite_frames: SpriteFrames
@export var health := 5
## Damage per touch.
@export var damage := 10
@export var speed := 30.0
@export var behavior := Behavior.CHASE
## How close the player has to be before it notices them.
@export var sight := 90.0
## Sometimes left behind when it dies.
@export var drop: ItemData
@export_range(0.0, 1.0) var drop_chance := 0.3
