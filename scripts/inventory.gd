class_name Inventory
extends RefCounted
## The player's items in numbered slots. Slots 0-9 are the hotbar (keys 1-0),
## the rest are the backpack. Each slot is empty (null) or holds one ItemStack.

signal changed
signal selection_changed

const HOTBAR_SIZE := 10
const SIZE := 30


class ItemStack:
	var item: ItemData
	var count: int

	func _init(stack_item: ItemData, stack_count: int) -> void:
		item = stack_item
		count = stack_count


## Index of the selected hotbar slot.
var selected := 0

var _slots: Array[ItemStack] = []


func _init() -> void:
	_slots.resize(SIZE)


func get_slot(index: int) -> ItemStack:
	return _slots[index]


func get_selected_item() -> ItemData:
	var stack := _slots[selected]
	return stack.item if stack else null


func select(index: int) -> void:
	selected = clampi(index, 0, HOTBAR_SIZE - 1)
	selection_changed.emit()


## Moves the selection along the hotbar, wrapping around (mouse wheel).
func select_next(direction: int) -> void:
	select(wrapi(selected + direction, 0, HOTBAR_SIZE))


## Total count of an item across all slots.
func count(item: ItemData) -> int:
	var total := 0
	for stack in _slots:
		if stack and stack.item == item:
			total += stack.count
	return total


## Every different item the player has.
func get_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for stack in _slots:
		if stack and stack.item not in result:
			result.append(stack.item)
	return result


func has_room_for(item: ItemData, amount := 1) -> bool:
	var room := 0
	for stack in _slots:
		if stack == null:
			room += item.max_stack
		elif stack.item == item:
			room += item.max_stack - stack.count
		if room >= amount:
			return true
	return false


## Adds items, topping up existing stacks first, then filling empty slots (hotbar first).
## Returns how many didn't fit.
func add(item: ItemData, amount := 1) -> int:
	var left := amount
	for stack in _slots:
		if left > 0 and stack and stack.item == item and stack.count < item.max_stack:
			var moved := mini(left, item.max_stack - stack.count)
			stack.count += moved
			left -= moved
	for i in SIZE:
		if left > 0 and _slots[i] == null:
			var moved := mini(left, item.max_stack)
			_slots[i] = ItemStack.new(item, moved)
			left -= moved
	if left != amount:
		changed.emit()
	return left


## Removes items, taking from the selected slot first. Returns false (and changes nothing)
## if there aren't enough.
func remove(item: ItemData, amount := 1) -> bool:
	if count(item) < amount:
		return false
	var left := amount
	var order: Array[int] = [selected]
	for i in SIZE:
		if i != selected:
			order.append(i)
	for i in order:
		var stack := _slots[i]
		if left > 0 and stack and stack.item == item:
			var taken := mini(left, stack.count)
			stack.count -= taken
			left -= taken
			if stack.count == 0:
				_slots[i] = null
	changed.emit()
	return true


## Empties a slot and returns what was in it (for picking items up with the mouse).
func take(index: int) -> ItemStack:
	var stack := _slots[index]
	_slots[index] = null
	if stack:
		changed.emit()
	return stack


## Puts a stack into a slot. Same items merge (up to max_stack); otherwise the stacks swap.
## Returns whatever is left over or was displaced (or null).
func put(index: int, stack: ItemStack) -> ItemStack:
	var current := _slots[index]
	if stack == null:
		return current
	if current and current.item == stack.item:
		var moved := mini(stack.count, stack.item.max_stack - current.count)
		current.count += moved
		stack.count -= moved
		changed.emit()
		return stack if stack.count > 0 else null
	_slots[index] = stack
	changed.emit()
	return current


## Swaps one item for another in the same slot (tool upgrades).
func replace(old_item: ItemData, new_item: ItemData) -> void:
	for i in SIZE:
		if _slots[i] and _slots[i].item == old_item:
			_slots[i] = ItemStack.new(new_item, 1)
			changed.emit()
			return
	add(new_item)


## Empties every slot (used when loading a save).
func clear() -> void:
	_slots.fill(null)
	changed.emit()
