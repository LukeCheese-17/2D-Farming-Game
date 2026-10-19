class_name QuestBoard
extends RefCounted
## The village notice board (QST-2). Each morning it offers a few notes from the
## quest pool; the player takes some and brings the items back to the board.

signal changed

const OFFERS_PER_DAY := 3
const MAX_ACTIVE := 3


class Active:
	var quest: QuestData
	## Last day it can be handed in.
	var deadline: int

	func _init(active_quest: QuestData, last_day: int) -> void:
		quest = active_quest
		deadline = last_day


var pool: Array[QuestData] = []
## Notes pinned on the board today.
var offers: Array[QuestData] = []
var active: Array[Active] = []


func _init(quest_pool: Array[QuestData]) -> void:
	pool = quest_pool


## Every QuestData .tres in a folder.
static func load_all(folder: String) -> Array[QuestData]:
	var result: Array[QuestData] = []
	for file in ResourceLoader.list_directory(folder):
		if file.ends_with(".tres"):
			var quest := load(folder.path_join(file)) as QuestData
			if quest:
				result.append(quest)
	return result


## Drops expired quests and pins new notes. Returns lines for the morning report.
func new_day(day: int) -> Array[String]:
	var report: Array[String] = []
	for a in active.duplicate():
		if day > a.deadline:
			active.erase(a)
			report.append("The note asking for %s has been torn down." % a.quest.item.display_name)
	offers.clear()
	var choices := pool.filter(func(q: QuestData) -> bool: return not is_active(q))
	choices.shuffle()
	for i in mini(OFFERS_PER_DAY, choices.size()):
		offers.append(choices[i])
	changed.emit()
	return report


func is_active(quest: QuestData) -> bool:
	return active.any(func(a: Active) -> bool: return a.quest == quest)


func can_take() -> bool:
	return active.size() < MAX_ACTIVE


func take(quest: QuestData, day: int) -> bool:
	if not can_take() or quest not in offers:
		return false
	offers.erase(quest)
	active.append(Active.new(quest, day + quest.days - 1))
	changed.emit()
	return true


## Hands in the items for an active quest and returns the reward (0 if the player doesn't have them).
func hand_in(a: Active, inventory: Inventory) -> int:
	if a not in active or not inventory.remove(a.quest.item, a.quest.amount):
		return 0
	active.erase(a)
	changed.emit()
	return a.quest.reward
