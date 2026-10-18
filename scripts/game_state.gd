extends Node
## Global game state (autoload "GameState"): day and clock, inventory, money,
## shipping box, phone jobs, dialogue and on-screen messages.

signal day_changed(day: int)
signal time_changed(minutes: int)
signal inventory_changed
signal money_changed(money: int)
signal tool_changed
signal job_changed
signal message_posted(text: String)
signal prompt_changed(text: String)
signal dialogue_started(lines: Array[String], choices: Array[String])
## choice is the picked option's index, or -1 if there were no choices.
signal dialogue_finished(choice: int)
## The clock reached PASS_OUT_TIME; the main scene puts the player to bed.
signal passed_out

const STARTING_SEEDS := 5
const STARTING_MONEY := 50
## The day starts at 6:00. Times are minutes since midnight of the current day.
const DAY_START := 6 * 60
## 2:00 the next morning.
const PASS_OUT_TIME := 26 * 60
const MINUTES_PER_TICK := 10
const SECONDS_PER_TICK := 7.0
## Seeds the player can order by phone; they arrive the next morning.
const SEED_ORDER_AMOUNT := 5
const SEED_ORDER_PRICE := 40

## Every crop the player can grow. Add a new CropData .tres here to add a crop.
var crops: Array[CropData] = [
	preload("res://data/crops/wheat.tres"),
]
## Fish that can be caught.
var fish: Array[FishData] = [
	preload("res://data/fish/pale_perch.tres"),
	preload("res://data/fish/mud_eel.tres"),
]
## Jobs the man on the phone gives, in order. After the last one he repeats them.
var jobs: Array[JobData] = [
	preload("res://data/jobs/01_wheat.tres"),
	preload("res://data/jobs/02_perch.tres"),
	preload("res://data/jobs/03_eggs.tres"),
	preload("res://data/jobs/04_milk.tres"),
	preload("res://data/jobs/05_eel.tres"),
	preload("res://data/jobs/06_wheat.tres"),
]

var day := 1
var minutes := DAY_START
var money := STARTING_MONEY
var current_tool := Tools.Type.HOE
var in_dialogue := false
## Set false to stop time (used by tests).
var clock_running := true

var active_job: JobData
var job_deadline := 0
var job_progress := 0
## Result of the last finished job: "", "done" or "failed". The caller mentions it on his next call.
var last_job_result := ""

var _items: Dictionary[ItemData, int] = {}
var _shipping: Dictionary[ItemData, int] = {}
var _next_job_index := 0
var _seed_order := 0
var _tick_time := 0.0


func _ready() -> void:
	add_item(crops[0].seed, STARTING_SEEDS)


func _process(delta: float) -> void:
	if not clock_running or in_dialogue or minutes >= PASS_OUT_TIME:
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


func get_selected_crop() -> CropData:
	return crops[0]


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


func select_tool(tool: Tools.Type) -> void:
	current_tool = tool
	tool_changed.emit()


# --- Inventory ---

func get_item_count(item: ItemData) -> int:
	return _items.get(item, 0)


## All items the player has at least one of.
func get_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in _items:
		if _items[item] > 0:
			result.append(item)
	return result


func add_item(item: ItemData, amount := 1) -> void:
	_items[item] = get_item_count(item) + amount
	inventory_changed.emit()


## Returns false (and changes nothing) if there are not enough of the item.
func remove_item(item: ItemData, amount := 1) -> bool:
	if get_item_count(item) < amount:
		return false
	_items[item] -= amount
	inventory_changed.emit()
	return true


# --- Shipping box and money ---

## Moves every sellable item from the inventory into the shipping box.
## Returns what was moved (item -> count).
func ship_all() -> Dictionary[ItemData, int]:
	var shipped: Dictionary[ItemData, int] = {}
	for item in get_items():
		if item.sell_price > 0:
			shipped[item] = _items[item]
			_shipping[item] = _shipping.get(item, 0) + _items[item]
			_items[item] = 0
	if not shipped.is_empty():
		inventory_changed.emit()
	return shipped


func get_shipping_count() -> int:
	var total := 0
	for item in _shipping:
		total += _shipping[item]
	return total


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


## Pays for a seed order that arrives tomorrow morning. Returns false if the player can't afford it.
func order_seeds() -> bool:
	if money < SEED_ORDER_PRICE:
		return false
	add_money(-SEED_ORDER_PRICE)
	_seed_order += SEED_ORDER_AMOUNT
	return true


# --- Phone jobs ---

func get_next_job() -> JobData:
	return jobs[_next_job_index % jobs.size()]


func accept_job(job: JobData) -> void:
	active_job = job
	job_deadline = day + job.days - 1
	job_progress = 0
	_next_job_index += 1
	job_changed.emit()


func _finish_job(result: String) -> void:
	active_job = null
	last_job_result = result
	job_changed.emit()


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
		if active_job and item == active_job.item:
			job_progress += count
	_shipping.clear()
	if active_job and job_progress >= active_job.amount:
		earned += active_job.reward
		report.append("An envelope under the door: %dg for the job." % active_job.reward)
		_finish_job("done")
	if earned > 0:
		add_money(earned)

	day += 1
	minutes = DAY_START
	_tick_time = 0.0
	if active_job and day > job_deadline:
		report.append("You missed the deadline. The phone is silent.")
		_finish_job("failed")
	if _seed_order > 0:
		add_item(crops[0].seed, _seed_order)
		report.append("A package was left by the door: %d %s." % [_seed_order, crops[0].seed.display_name])
		_seed_order = 0
	job_changed.emit()
	day_changed.emit(day)
	time_changed.emit(minutes)
	return report


# --- Messages and dialogue ---

func post_message(text: String) -> void:
	message_posted.emit(text)


## Shows a hint such as "E: Sleep"; pass "" to hide it.
func set_prompt(text: String) -> void:
	prompt_changed.emit(text)


## Shows lines of dialogue one after another; with choices, the last line asks the player to pick one.
## Await dialogue_finished for the result.
func show_dialogue(lines: Array, choices: Array = []) -> void:
	var typed_lines: Array[String] = []
	typed_lines.assign(lines)
	var typed_choices: Array[String] = []
	typed_choices.assign(choices)
	in_dialogue = true
	dialogue_started.emit(typed_lines, typed_choices)


## Called by the HUD when the player closes the dialogue.
func end_dialogue(choice := -1) -> void:
	in_dialogue = false
	dialogue_finished.emit(choice)
