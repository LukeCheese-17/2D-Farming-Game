extends Node
## Autoload "GameState": the day and clock, money, the shipping box, and what
## happens overnight. Also owns the player's inventory and the phone jobs.

signal day_changed(day: int)
signal time_changed(minutes: int)
signal money_changed(money: int)
## The clock reached PASS_OUT_TIME; the main scene puts the player to bed.
signal passed_out

const STARTING_MONEY := 50
const STARTING_SEEDS := 5
## The day starts at 6:00. Times are minutes since midnight of the current day.
const DAY_START := 6 * 60
## 2:00 the next morning.
const PASS_OUT_TIME := 26 * 60
const MINUTES_PER_TICK := 10
const SECONDS_PER_TICK := 7.0
## Seeds the player can order by phone; they arrive the next morning.
const SEED_ORDER_AMOUNT := 5
const SEED_ORDER_PRICE := 40

## The tools the player starts with, in hotbar order.
const STARTING_TOOLS: Array[ItemData] = [
	preload("res://data/items/hoe.tres"),
	preload("res://data/items/watering_can.tres"),
	null,  # Key 3 holds the starting seeds.
	preload("res://data/items/fishing_rod.tres"),
]

## Every crop the player can grow. Add a new CropData .tres here to add a crop.
var crops: Array[CropData] = [
	preload("res://data/crops/wheat.tres"),
]
## Fish that can be caught.
var fish: Array[FishData] = [
	preload("res://data/fish/pale_perch.tres"),
	preload("res://data/fish/mud_eel.tres"),
]

var day := 1
var minutes := DAY_START
var money := STARTING_MONEY
## Set false to stop time (used by tests).
var clock_running := true

var inventory := Inventory.new()
var jobs := JobBoard.new([
	preload("res://data/jobs/01_wheat.tres"),
	preload("res://data/jobs/02_perch.tres"),
	preload("res://data/jobs/03_eggs.tres"),
	preload("res://data/jobs/04_milk.tres"),
	preload("res://data/jobs/05_eel.tres"),
	preload("res://data/jobs/06_wheat.tres"),
])

var _shipping: Dictionary[ItemData, int] = {}
var _seed_order := 0
var _tick_time := 0.0


func _ready() -> void:
	for i in STARTING_TOOLS.size():
		if STARTING_TOOLS[i]:
			inventory.put(i, Inventory.ItemStack.new(STARTING_TOOLS[i], 1))
	inventory.put(2, Inventory.ItemStack.new(crops[0].seed, STARTING_SEEDS))


func _process(delta: float) -> void:
	if not clock_running or UI.is_blocking() or minutes >= PASS_OUT_TIME:
		return
	_tick_time += delta
	if _tick_time < SECONDS_PER_TICK:
		return
	_tick_time -= SECONDS_PER_TICK
	minutes += MINUTES_PER_TICK
	time_changed.emit(minutes)
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


## The crop an item plants, or null if it isn't a seed.
func get_crop_for_seed(item: ItemData) -> CropData:
	for crop in crops:
		if crop.seed == item:
			return crop
	return null


## Picks a random fish, weighted by FishData.weight.
func pick_fish() -> FishData:
	var total := 0
	for f in fish:
		total += f.weight
	var roll := randi_range(1, total)
	for f in fish:
		roll -= f.weight
		if roll <= 0:
			return f
	return fish[0]


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


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


## Pays for a seed order that arrives tomorrow morning. Returns false if the player can't afford it.
func order_seeds() -> bool:
	if money < SEED_ORDER_PRICE:
		return false
	add_money(-SEED_ORDER_PRICE)
	_seed_order += SEED_ORDER_AMOUNT
	return true


# --- Sleeping ---

## Ends the day: sells everything in the shipping box, pays finished jobs,
## and starts the next morning at 6:00. Returns lines describing what happened.
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
	if jobs.active and day > jobs.deadline:
		report.append("You missed the deadline. The phone is silent.")
		jobs.finish("failed")
	if _seed_order > 0:
		var seed := crops[0].seed
		var delivered := _seed_order - inventory.add(seed, _seed_order)
		_seed_order -= delivered
		if delivered > 0:
			report.append("A package was left by the door: %d %s." % [delivered, seed.display_name])
		if _seed_order > 0:
			report.append("Your bag is full. The rest of the seeds are still waiting by the door.")
	day_changed.emit(day)
	time_changed.emit(minutes)
	return report
