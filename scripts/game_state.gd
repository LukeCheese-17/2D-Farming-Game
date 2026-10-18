extends Node
## Global game state (autoload "GameState"): current day, inventory,
## selected tool and on-screen messages.

signal day_changed(day: int)
signal inventory_changed
signal tool_changed
signal message_posted(text: String)
signal prompt_changed(text: String)

const STARTING_SEEDS := 5

## Every crop the player can grow. Add a new CropData .tres here to add a crop.
var crops: Array[CropData] = [
	preload("res://data/crops/wheat.tres"),
	preload("res://data/crops/tomato.tres"),
]

var day := 1
var current_tool := Tools.Type.HOE
var selected_crop_index := 0

var _items: Dictionary[StringName, int] = {}


func _ready() -> void:
	for crop in crops:
		add_item(crop.seed_item, STARTING_SEEDS)


func get_selected_crop() -> CropData:
	return crops[selected_crop_index]


## Selecting the seeds tool again cycles through the crop types.
func select_tool(tool: Tools.Type) -> void:
	if tool == Tools.Type.SEEDS and current_tool == Tools.Type.SEEDS:
		selected_crop_index = (selected_crop_index + 1) % crops.size()
	current_tool = tool
	tool_changed.emit()


func get_item_count(item: StringName) -> int:
	return _items.get(item, 0)


func add_item(item: StringName, amount := 1) -> void:
	_items[item] = get_item_count(item) + amount
	inventory_changed.emit()


## Returns false (and changes nothing) if there are not enough of the item.
func remove_item(item: StringName, amount := 1) -> bool:
	if get_item_count(item) < amount:
		return false
	_items[item] -= amount
	inventory_changed.emit()
	return true


func advance_day() -> void:
	day += 1
	day_changed.emit(day)


func post_message(text: String) -> void:
	message_posted.emit(text)


## Shows a hint such as "E: Sleep"; pass "" to hide it.
func set_prompt(text: String) -> void:
	prompt_changed.emit(text)
