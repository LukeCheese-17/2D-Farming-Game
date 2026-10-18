class_name AnimalData
extends Resource
## Defines one kind of farm animal. To add an animal, create a .tres from this
## script in data/animals and place an Animal scene using it in the pen.

@export var display_name: String
## Needs "idle" and "walk" animations, with the sprites facing right.
@export var sprite_frames: SpriteFrames
## Moves the sprite so the node's origin sits at the animal's feet.
@export var sprite_offset := Vector2(0, -8)
## What the animal gives once per day.
@export var product: ItemData
@export var speed := 14.0
