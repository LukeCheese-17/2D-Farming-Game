class_name QuestBoard
extends RefCounted
## The village notice board (QST-2). After his first call, the man on the phone
## pins one main quest; the next only goes up once he has paid for the last one.
## Two small daily notes are drawn from the pool every morning and paid at the board.

signal changed

const DAILY_COUNT := 2

## Main quests in order (data/quests/main).
var main_quests: Array[QuestData] = []
## Daily notes to draw from (data/quests).
var pool: Array[QuestData] = []
## Index of the current main quest (main_quests.size() once all are paid).
var main_index := 0
## The current main quest's items were left at the board (ITEMS quests only).
var main_handed_in := false
## False until the man's first call puts the first main quest up.
var main_posted := false
## Today's notes and whether each was handed in.
var daily: Array[QuestData] = []
var daily_done: Array[bool] = []


func _init(main_list: Array[QuestData], daily_pool: Array[QuestData]) -> void:
	main_quests = main_list
	pool = daily_pool


## Every QuestData .tres in a folder, in file order.
static func load_all(folder: String) -> Array[QuestData]:
	var result: Array[QuestData] = []
	var files := Array(ResourceLoader.list_directory(folder))
	files.sort()
	for file: String in files:
		if file.ends_with(".tres"):
			var quest := load(folder.path_join(file)) as QuestData
			if quest:
				result.append(quest)
	return result


## Pins two fresh daily notes.
func new_day() -> void:
	var choices := pool.duplicate()
	choices.shuffle()
	daily.assign(choices.slice(0, DAILY_COUNT))
	daily_done.assign(daily.map(func(_q: QuestData) -> bool: return false))
	changed.emit()


func post_main() -> void:
	main_posted = true
	changed.emit()


## The main quest on the board, or null (not posted yet, or all done).
func get_main() -> QuestData:
	if not main_posted or main_index >= main_quests.size():
		return null
	return main_quests[main_index]


## Whether the current main quest is finished and waiting for the man to pay.
func is_main_done() -> bool:
	var quest := get_main()
	if quest == null:
		return false
	match quest.kind:
		QuestData.Kind.BUILDING:
			return GameState.village.get(quest.building, "ruin") == "open"
		QuestData.Kind.MINE_FLOOR:
			return GameState.deepest_floor >= quest.mine_floor
	return main_handed_in


## Leaves the main quest's items at the board. False if the player doesn't have them.
func hand_in_main(inventory: Inventory) -> bool:
	var quest := get_main()
	if quest == null or quest.kind != QuestData.Kind.ITEMS or main_handed_in:
		return false
	if not inventory.remove(quest.item, quest.amount):
		return false
	main_handed_in = true
	changed.emit()
	return true


## The man pays for the finished main quest and the next one goes up. Returns the reward.
func pay_main() -> int:
	if not is_main_done():
		return 0
	var reward := get_main().reward
	main_index += 1
	main_handed_in = false
	changed.emit()
	return reward


## Hands in today's note at index i and returns the reward (0 if the player doesn't have the items).
func hand_in_daily(i: int, inventory: Inventory) -> int:
	if i < 0 or i >= daily.size() or daily_done[i]:
		return 0
	if not inventory.remove(daily[i].item, daily[i].amount):
		return 0
	daily_done[i] = true
	changed.emit()
	return daily[i].reward
