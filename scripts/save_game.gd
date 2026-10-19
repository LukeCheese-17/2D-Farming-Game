class_name SaveGame
## Saving and loading (SAV-1): three save slots, each one JSON file with the day,
## money, needs, inventory, shipping box, phone orders, board quests, village,
## mine progress, the farm's tiles and crops, and the animals. The main scene adds
## and applies the farm part.

const SLOTS := 3
const VERSION := 2

## The file the current game saves to (use_slot() sets it; tests point it somewhere else).
static var path := slot_path(0)


static func slot_path(slot: int) -> String:
	return "user://save_%d.json" % (slot + 1)


static func use_slot(slot: int) -> void:
	path = slot_path(slot)


static func exists() -> bool:
	return FileAccess.file_exists(path)


static func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


static func delete_slot(slot: int) -> void:
	if slot_exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))


## A short line for the slot menu, like "Day 4 - 230g", or "Empty".
static func describe_slot(slot: int) -> String:
	if not slot_exists(slot):
		return "Empty"
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
	if not data is Dictionary:
		return "Damaged"
	return "Day %d - %dg" % [int(data.get("day", 1)), int(data.get("money", 0))]


## Saves from before slots existed become slot 1.
static func migrate_old_save() -> void:
	const OLD := "user://save.json"
	if FileAccess.file_exists(OLD) and not slot_exists(0):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(OLD), ProjectSettings.globalize_path(slot_path(0)))


static func _items_to_list(items: Dictionary[ItemData, int]) -> Array:
	var list := []
	for item in items:
		list.append([item.resource_path, items[item]])
	return list


static func _list_to_items(list: Array) -> Dictionary[ItemData, int]:
	var items: Dictionary[ItemData, int] = {}
	for entry: Array in list:
		var item := load(entry[0]) as ItemData
		if item:
			items[item] = int(entry[1])
	return items


## Writes everything to disk. main is the main scene (for the farm, animals and player).
static func save(main: Node) -> bool:
	var gs := GameState
	var slots := []
	for i in Inventory.SIZE:
		var stack := gs.inventory.get_slot(i)
		slots.append([stack.item.resource_path, stack.count] if stack else null)
	var board := gs.quests
	var data := {
		"version": VERSION,
		"day": gs.day, "minutes": gs.minutes, "money": gs.money,
		"food": gs.food, "water": gs.water, "health": gs.health,
		"inventory": slots, "selected": gs.inventory.selected,
		"shipping": _items_to_list(gs.get_shipping()), "supplies": _items_to_list(gs.get_supply_order()),
		"quests": {"main": board.main_index, "main_handed_in": board.main_handed_in, "main_posted": board.main_posted,
			"daily": board.daily.map(func(q: QuestData) -> String: return q.resource_path), "daily_done": board.daily_done},
		"village": gs.village,
		"deepest_floor": gs.deepest_floor,
		"flags": gs.flags,
		"world": main.get_save_data(),
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


## Reads the save into GameState. The main scene applies GameState.pending_load.world when it starts.
static func load_game() -> bool:
	if not exists():
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		return false
	var gs := GameState
	gs.new_game()
	gs.day = int(data.get("day", 1))
	gs.minutes = int(data.get("minutes", gs.DAY_START))
	gs.money = int(data.get("money", gs.STARTING_MONEY))
	gs.food = float(data.get("food", gs.MAX_NEED))
	gs.water = float(data.get("water", gs.MAX_NEED))
	gs.health = int(data.get("health", gs.MAX_HEALTH))
	gs.deepest_floor = int(data.get("deepest_floor", 0))
	for key: String in data.get("flags", {}):
		gs.flags[key] = bool(data.flags[key])
	for id: String in data.get("village", {}):
		gs.village[StringName(id)] = String(data.village[id])

	gs.inventory.clear()
	var slots: Array = data.get("inventory", [])
	for i in mini(slots.size(), Inventory.SIZE):
		if slots[i] is Array:
			var item := load(slots[i][0]) as ItemData
			if item:
				gs.inventory.put(i, Inventory.ItemStack.new(item, int(slots[i][1])))
	gs.inventory.select(int(data.get("selected", 0)))
	gs.restore_shipping(_list_to_items(data.get("shipping", [])), _list_to_items(data.get("supplies", [])))

	var quests: Dictionary = data.get("quests", {})
	var board := gs.quests
	board.main_index = int(quests.get("main", 0))
	board.main_handed_in = bool(quests.get("main_handed_in", false))
	# Saves from before main quests: he has already called.
	board.main_posted = bool(quests.get("main_posted", gs.day > 1))
	var daily: Array[QuestData] = []
	var done: Array[bool] = []
	var saved_done: Array = quests.get("daily_done", [])
	for i in quests.get("daily", []).size():
		var quest := load(quests.daily[i]) as QuestData
		if quest:
			daily.append(quest)
			done.append(i < saved_done.size() and bool(saved_done[i]))
	if not daily.is_empty():
		board.daily = daily
		board.daily_done = done
	gs.pending_load = data.get("world", {})
	return true
