class_name QuestData
extends Resource
## A quest on the village board (QST-2).
## Daily notes live in data/quests (two are drawn each morning) and are always
## "bring items to the board". Main quests live in data/quests/main, run in file
## order, and are paid for by the man on the phone.

enum Kind { ITEMS, BUILDING, MINE_FLOOR }

@export var kind := Kind.ITEMS
## Short name, shown for main quests.
@export var title := ""
## For ITEMS: what to bring and how many.
@export var item: ItemData
@export var amount := 5
## For BUILDING: the village building id that has to be rebuilt.
@export var building: StringName
## For MINE_FLOOR: the mine floor that has to be reached (1 = the top floor).
@export var mine_floor := 1
@export var reward := 30
## What the note says. {amount}, {item} and {reward} are filled in.
@export_multiline var note := ""


func get_note() -> String:
	return note.format({"amount": amount, "item": item.display_name if item else "", "reward": reward})


## One line saying what has to be done.
func get_goal() -> String:
	match kind:
		Kind.BUILDING:
			for b in GameState.buildings:
				if b.id == building:
					return "Rebuild the %s" % b.display_name.to_lower()
			return "Rebuild %s" % building
		Kind.MINE_FLOOR:
			return "Reach floor %d of the mine" % mine_floor
	return "Bring %d %s to the board" % [amount, item.display_name]
