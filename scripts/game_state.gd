extends Node
## Autoload "GameState": the day and clock, money, the shipping box, what happens
## overnight, the player's food/water/health, village rebuilding and mine progress.
## Also owns the player's inventory, the phone jobs and the village quest board.

signal day_changed(day: int)
signal time_changed(minutes: int)
signal money_changed(money: int)
## Food, water or health changed.
signal needs_changed
## The clock reached PASS_OUT_TIME; the main scene puts the player to bed.
signal passed_out
## The player collapsed (reason: "hunger", "thirst" or "hurt"); the main scene puts them to bed.
signal fainted(reason: String)
## A village building changed state.
signal village_changed

const STARTING_MONEY := 50
const STARTING_SEEDS := 5
## The day starts at 6:00. Times are minutes since midnight of the current day.
const DAY_START := 6 * 60
## 2:00 the next morning.
const PASS_OUT_TIME := 26 * 60
## Fish that only bite at night come out from 19:00.
const NIGHT_START := 19 * 60
const MINUTES_PER_TICK := 10
const SECONDS_PER_TICK := 7.0
## Seeds the player can order by phone; they arrive the next morning.
const SEED_ORDER_AMOUNT := 5
const SEED_ORDER_PRICE := 40

const MAX_NEED := 100.0
## How much food and water drop every 10 in-game minutes, and overnight.
const FOOD_PER_TICK := 0.6
const WATER_PER_TICK := 0.8
const FOOD_OVERNIGHT := 10.0
const WATER_OVERNIGHT := 15.0
## Below this the player is hungry/thirsty and walks slower.
const LOW_NEED := 20.0
## Meters are topped up to this after fainting from hunger or thirst.
const FAINT_REFILL := 35.0
const MAX_HEALTH := 100
## Share of money lost (up to the cap) when carried home hurt.
const HURT_MONEY_LOSS := 0.1
const HURT_MONEY_CAP := 200
## Drinking from a river, pond, well or flask-less mouthful.
const DRINK_AMOUNT := 30.0

## The tools the player starts with, in hotbar order.
const STARTING_TOOLS: Array[ItemData] = [
	preload("res://data/items/hoe.tres"),
	preload("res://data/items/watering_can.tres"),
	null,  # Key 3 holds the starting seeds.
	preload("res://data/items/fishing_rod.tres"),
	preload("res://data/items/axe.tres"),
	preload("res://data/items/pickaxe.tres"),
]
const SWORD: ItemData = preload("res://data/items/rusty_sword.tres")

## Every crop the player can grow. Add a new CropData .tres here to add a crop.
var crops: Array[CropData] = [
	preload("res://data/crops/wheat.tres"),
	preload("res://data/crops/tomato.tres"),
	preload("res://data/crops/carrot.tres"),
	preload("res://data/crops/turnip.tres"),
	preload("res://data/crops/pumpkin.tres"),
	preload("res://data/crops/tulip.tres"),
	preload("res://data/crops/bluebell.tres"),
	preload("res://data/crops/rose.tres"),
	preload("res://data/crops/sunflower.tres"),
]
## Fish that can be caught.
var fish: Array[FishData] = [
	preload("res://data/fish/pale_perch.tres"),
	preload("res://data/fish/mud_eel.tres"),
	preload("res://data/fish/grey_minnow.tres"),
	preload("res://data/fish/bog_carp.tres"),
	preload("res://data/fish/black_koi.tres"),
	preload("res://data/fish/river_trout.tres"),
	preload("res://data/fish/silver_dace.tres"),
	preload("res://data/fish/whisker_cat.tres"),
	preload("res://data/fish/glass_eel.tres"),
	preload("res://data/fish/drowned_pike.tres"),
	preload("res://data/fish/weeping_gar.tres"),
	preload("res://data/fish/bone_fish.tres"),
]
## The village buildings, in the order they appear on the map.
var buildings: Array[BuildingData] = [
	preload("res://data/village/general_store.tres"),
	preload("res://data/village/flower_shop.tres"),
	preload("res://data/village/blacksmith.tres"),
]
## The mine's floors, top to bottom.
var mine_floors: Array[MineFloorData] = [
	preload("res://data/mine/1_damp_tunnels.tres"),
	preload("res://data/mine/2_root_hollow.tres"),
	preload("res://data/mine/3_bone_gallery.tres"),
	preload("res://data/mine/4_frozen_dark.tres"),
	preload("res://data/mine/5_red_deep.tres"),
]

var day := 1
var minutes := DAY_START
var money := STARTING_MONEY
var food := MAX_NEED
var water := MAX_NEED
var health := MAX_HEALTH
## Set false to stop time and hunger (used by tests).
var clock_running := true
## Save every morning when the player wakes up (tests turn this off).
var autosave := true

var inventory: Inventory
var jobs: JobBoard
var quests: QuestBoard
## Building id -> "ruin", "building" (finished overnight) or "open".
var village: Dictionary[StringName, String] = {}
## Deepest mine floor reached (0 = never been down).
var deepest_floor := 0
## One-off events: "found_sword", "deep_call", ...
var flags: Dictionary[String, bool] = {}
## Set by SaveGame.load_game(); the main scene applies the farm part when it loads.
var pending_load: Dictionary = {}

var _shipping: Dictionary[ItemData, int] = {}
var _seed_order := 0
var _tick_time := 0.0
var _fainting := false


func _ready() -> void:
	new_game()


## Resets everything to the first morning.
func new_game() -> void:
	day = 1
	minutes = DAY_START
	money = STARTING_MONEY
	food = MAX_NEED
	water = MAX_NEED
	health = MAX_HEALTH
	clock_running = true
	_shipping.clear()
	_seed_order = 0
	_tick_time = 0.0
	_fainting = false
	deepest_floor = 0
	flags.clear()
	pending_load = {}
	inventory = Inventory.new()
	for i in STARTING_TOOLS.size():
		if STARTING_TOOLS[i]:
			inventory.put(i, Inventory.ItemStack.new(STARTING_TOOLS[i], 1))
	inventory.put(2, Inventory.ItemStack.new(crops[0].seed, STARTING_SEEDS))
	jobs = JobBoard.new([
		preload("res://data/jobs/01_wheat.tres"),
		preload("res://data/jobs/02_perch.tres"),
		preload("res://data/jobs/03_eggs.tres"),
		preload("res://data/jobs/04_milk.tres"),
		preload("res://data/jobs/05_eel.tres"),
		preload("res://data/jobs/06_wheat.tres"),
		preload("res://data/jobs/07_carp.tres"),
		preload("res://data/jobs/08_milk.tres"),
		preload("res://data/jobs/09_carrots.tres"),
		preload("res://data/jobs/10_eggs.tres"),
		preload("res://data/jobs/11_glass_eel.tres"),
		preload("res://data/jobs/12_pumpkins.tres"),
	])
	quests = QuestBoard.new(QuestBoard.load_all("res://data/quests"))
	quests.new_day(day)
	village.clear()
	for building in buildings:
		village[building.id] = "ruin"


func _process(delta: float) -> void:
	if not clock_running or UI.is_blocking() or minutes >= PASS_OUT_TIME:
		return
	_tick_time += delta
	if _tick_time < SECONDS_PER_TICK:
		return
	_tick_time -= SECONDS_PER_TICK
	minutes += MINUTES_PER_TICK
	time_changed.emit(minutes)
	use_needs(FOOD_PER_TICK, WATER_PER_TICK)
	if minutes >= PASS_OUT_TIME:
		passed_out.emit()


## "14:20"-style text for the current time.
func get_time_text() -> String:
	return "%02d:%02d" % [(minutes / 60) % 24, minutes % 60]


## 0 at noon, 1 in the middle of the night; used for lighting and how often creepy things happen.
func get_darkness() -> float:
	if minutes < 17 * 60:
		return clampf(1.0 - float(minutes - DAY_START) / 120.0, 0.0, 1.0) * 0.4
	return clampf(float(minutes - 17 * 60) / (4.0 * 60.0), 0.0, 1.0)


func is_night() -> bool:
	return minutes >= NIGHT_START


## The crop an item plants, or null if it isn't a seed.
func get_crop_for_seed(item: ItemData) -> CropData:
	if item == null:
		return null
	for crop in crops:
		if crop.seed == item:
			return crop
	return null


## Picks a random fish that bites in this kind of water at this time, weighted by FishData.weight.
## place is a Farm.Water value.
func pick_fish(place := 7) -> FishData:
	var candidates := fish.filter(func(f: FishData) -> bool: return f.can_bite(place, is_night()))
	if candidates.is_empty():
		candidates = fish
	var total := 0
	for f: FishData in candidates:
		total += f.weight
	var roll := randi_range(1, total)
	for f: FishData in candidates:
		roll -= f.weight
		if roll <= 0:
			return f
	return candidates[0]


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


# --- Food, water and health ---

func use_needs(food_amount: float, water_amount: float) -> void:
	food = maxf(food - food_amount, 0.0)
	water = maxf(water - water_amount, 0.0)
	needs_changed.emit()
	if not _fainting and (food <= 0.0 or water <= 0.0):
		_fainting = true
		fainted.emit("hunger" if food <= 0.0 else "thirst")


## Eats one of the item from the inventory. Returns false if it isn't food or the player is full.
func eat(item: ItemData) -> bool:
	if item == null or not item.is_edible():
		return false
	if (item.food == 0 or food >= MAX_NEED) and (item.water == 0 or water >= MAX_NEED):
		return false
	if not inventory.remove(item):
		return false
	food = minf(food + item.food, MAX_NEED)
	water = minf(water + item.water, MAX_NEED)
	needs_changed.emit()
	return true


func drink(amount := DRINK_AMOUNT) -> void:
	water = minf(water + amount, MAX_NEED)
	needs_changed.emit()


## Slower walking when hungry or thirsty (NED-3).
func get_speed_factor() -> float:
	return 0.7 if food < LOW_NEED or water < LOW_NEED else 1.0


func hurt(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(health - amount, 0)
	needs_changed.emit()
	if health <= 0 and not _fainting:
		_fainting = true
		fainted.emit("hurt")


## Called when waking up after fainting. Returns lines for the morning report.
func recover_from_faint(reason: String) -> Array[String]:
	var lines: Array[String] = []
	match reason:
		"hunger", "thirst":
			lines.append("Everything went dark. You wake up in bed with dirt under your nails.")
			food = maxf(food, FAINT_REFILL)
			water = maxf(water, FAINT_REFILL)
		"hurt":
			var lost := mini(int(money * HURT_MONEY_LOSS), HURT_MONEY_CAP)
			lines.append("Something carried you out of the dark. You wake up in bed.")
			if lost > 0:
				add_money(-lost)
				lines.append("Your purse is %dg lighter." % lost)
	needs_changed.emit()
	return lines


# --- Village ---

func get_building_state(id: StringName) -> String:
	return village.get(id, "ruin")


## Hands in the materials and money for a building. It's finished overnight.
func rebuild(building: BuildingData) -> bool:
	if not can_rebuild(building):
		return false
	for i in building.materials.size():
		inventory.remove(building.materials[i], building.amounts[i])
	add_money(-building.price)
	village[building.id] = "building"
	village_changed.emit()
	return true


func can_rebuild(building: BuildingData) -> bool:
	if get_building_state(building.id) != "ruin" or money < building.price:
		return false
	for i in building.materials.size():
		if inventory.count(building.materials[i]) < building.amounts[i]:
			return false
	return true


func is_open(id: StringName) -> bool:
	return get_building_state(id) == "open"


# --- Shops ---

## Buys one item at its buy price. Returns false if the player can't pay or has no room.
func buy(item: ItemData) -> bool:
	if money < item.buy_price or not inventory.has_room_for(item):
		return false
	add_money(-item.buy_price)
	inventory.add(item)
	return true


func can_make(recipe: RecipeData) -> bool:
	if money < recipe.price or (recipe.replaces and inventory.count(recipe.replaces) == 0):
		return false
	for i in recipe.inputs.size():
		if inventory.count(recipe.inputs[i]) < recipe.amounts[i]:
			return false
	return recipe.replaces != null or inventory.has_room_for(recipe.result)


## Makes a recipe; an upgraded tool takes the old tool's slot.
func make(recipe: RecipeData) -> bool:
	if not can_make(recipe):
		return false
	for i in recipe.inputs.size():
		inventory.remove(recipe.inputs[i], recipe.amounts[i])
	add_money(-recipe.price)
	if recipe.replaces:
		inventory.replace(recipe.replaces, recipe.result)
	else:
		inventory.add(recipe.result)
	return true


# --- Shipping box ---

## Puts the whole selected hotbar stack in the shipping box if it can be sold.
## Returns how many were shipped (0 if the selected item can't be sold).
func ship_selected() -> int:
	var stack := inventory.get_slot(inventory.selected)
	if stack == null or stack.item.sell_price <= 0:
		return 0
	inventory.take(inventory.selected)
	_shipping[stack.item] = _shipping.get(stack.item, 0) + stack.count
	return stack.count


func get_shipping_count() -> int:
	var total := 0
	for item in _shipping:
		total += _shipping[item]
	return total


func get_shipping() -> Dictionary[ItemData, int]:
	return _shipping


func get_seed_order() -> int:
	return _seed_order


## Used when loading a save.
func restore_shipping(shipping: Dictionary[ItemData, int], seed_order: int) -> void:
	_shipping = shipping
	_seed_order = seed_order


## Pays for a seed order that arrives tomorrow morning. Returns false if the player can't afford it.
func order_seeds() -> bool:
	if money < SEED_ORDER_PRICE:
		return false
	add_money(-SEED_ORDER_PRICE)
	_seed_order += SEED_ORDER_AMOUNT
	return true


# --- Sleeping ---

## Ends the day: sells everything in the shipping box, pays finished jobs,
## finishes village building, and starts the next morning at 6:00.
## Returns lines describing what happened.
func sleep() -> Array[String]:
	var report: Array[String] = []
	var earned := 0
	for item in _shipping:
		var count: int = _shipping[item]
		earned += count * item.sell_price
		report.append("Sold %d %s for %dg." % [count, item.display_name, count * item.sell_price])
		jobs.record_sold(item, count)
	_shipping.clear()
	if jobs.is_complete():
		earned += jobs.active.reward
		report.append("An envelope under the door: %dg for the job." % jobs.active.reward)
		jobs.finish("done")
	if earned > 0:
		add_money(earned)

	day += 1
	minutes = DAY_START
	_tick_time = 0.0
	_fainting = false
	health = MAX_HEALTH
	# The night makes you hungry, but never faints you in your sleep.
	food = maxf(food - FOOD_OVERNIGHT, 1.0)
	water = maxf(water - WATER_OVERNIGHT, 1.0)
	needs_changed.emit()
	if jobs.active and day > jobs.deadline:
		report.append("You missed the deadline. The phone is silent.")
		jobs.finish("failed")
	for building in buildings:
		if village[building.id] == "building":
			village[building.id] = "open"
			report.append("The %s in the village was finished overnight. Nobody heard any hammering." % building.display_name.to_lower())
	village_changed.emit()
	report.append_array(quests.new_day(day))
	if _seed_order > 0:
		var seed := crops[0].seed
		var delivered := _seed_order - inventory.add(seed, _seed_order)
		_seed_order -= delivered
		if delivered > 0:
			report.append("A package was left by the door: %d %s." % [delivered, seed.display_name])
		if _seed_order > 0:
			report.append("Your bag is full. The rest of the seeds are still waiting by the door.")
	if food < LOW_NEED:
		report.append("Your stomach hurts. You need to eat something.")
	if water < LOW_NEED:
		report.append("Your throat is dry. You need water.")
	day_changed.emit(day)
	time_changed.emit(minutes)
	return report
