class_name SaveGame
## Saving and loading (SAV-1): one JSON file with the day, money, needs, inventory,
## shipping box, phone job, board quests, village, mine progress, the farm's tiles
## and crops, and the animals. The main scene adds and applies the farm part.

## Where the save lives (tests point this somewhere else).
static var path := "user://save.json"
const VERSION := 1


static func exists() -> bool:
	return FileAccess.file_exists(path)


## Writes everything to disk. main is the main scene (for the farm, animals and player).
static func save(main: Node) -> bool:
	var gs := GameState
	var slots := []
	for i in Inventory.SIZE:
		var stack := gs.inventory.get_slot(i)
		slots.append([stack.item.resource_path, stack.count] if stack else null)
	var shipping := []
	var box := gs.get_shipping()
	for item in box:
		shipping.append([item.resource_path, box[item]])
	var jobs := gs.jobs
	var quests := []
	for a in gs.quests.active:
		quests.append([a.quest.resource_path, a.deadline])
	var data := {
		"version": VERSION,
		"day": gs.day, "minutes": gs.minutes, "money": gs.money,
		"food": gs.food, "water": gs.water, "health": gs.health,
		"inventory": slots, "selected": gs.inventory.selected,
		"shipping": shipping, "seed_order": gs.get_seed_order(),
		"jobs": {"next": jobs.next_index, "active": jobs.active.resource_path if jobs.active else "",
			"deadline": jobs.deadline, "progress": jobs.progress, "last_result": jobs.last_result},
		"quests": {"offers": gs.quests.offers.map(func(q: QuestData) -> String: return q.resource_path), "active": quests},
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
	var shipping: Dictionary[ItemData, int] = {}
	for entry: Array in data.get("shipping", []):
		var item := load(entry[0]) as ItemData
		if item:
			shipping[item] = int(entry[1])
	gs.restore_shipping(shipping, int(data.get("seed_order", 0)))

	var jobs: Dictionary = data.get("jobs", {})
	gs.jobs.next_index = int(jobs.get("next", 0))
	gs.jobs.active = load(jobs.active) as JobData if String(jobs.get("active", "")) != "" else null
	gs.jobs.deadline = int(jobs.get("deadline", 0))
	gs.jobs.progress = int(jobs.get("progress", 0))
	gs.jobs.last_result = String(jobs.get("last_result", ""))

	var quests: Dictionary = data.get("quests", {})
	gs.quests.offers.clear()
	for quest_path: String in quests.get("offers", []):
		var quest := load(quest_path) as QuestData
		if quest:
			gs.quests.offers.append(quest)
	gs.quests.active.clear()
	for entry: Array in quests.get("active", []):
		var quest := load(entry[0]) as QuestData
		if quest:
			gs.quests.active.append(QuestBoard.Active.new(quest, int(entry[1])))
	gs.pending_load = data.get("world", {})
	return true
