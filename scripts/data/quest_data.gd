class_name QuestData
extends Resource
## A note pinned to the village quest board: bring items to the board for money.
## Add one by creating a .tres from this script in data/quests (GameState loads them all).

@export var item: ItemData
@export var amount := 5
@export var reward := 80
## Days to hand it in, counting the day it was taken.
@export var days := 3
## What the note says. {amount}, {item} and {reward} are filled in.
@export_multiline var note := ""


func get_note() -> String:
	return note.format({"amount": amount, "item": item.display_name, "reward": reward})
