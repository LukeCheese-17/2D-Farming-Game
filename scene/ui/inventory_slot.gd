class_name InventorySlot
extends Panel
## One inventory slot in the hotbar or backpack: item icon, stack count and an
## optional key number. Emits `clicked` on left click and `hovered` when the mouse enters.

signal clicked(index: int)
signal hovered(index: int)

const SLOT_SIZE := Vector2(20, 20)

var index := 0

var _icon := TextureRect.new()
var _count := Label.new()
var _key := Label.new()
var _style := StyleBoxFlat.new()


func _init() -> void:
	custom_minimum_size = SLOT_SIZE
	_style.bg_color = Color(0, 0, 0, 0.5)
	_style.border_color = Color(0.45, 0.4, 0.4, 0.8)
	_style.set_border_width_all(1)
	_style.set_corner_radius_all(2)
	add_theme_stylebox_override("panel", _style)
	_icon.position = Vector2(2, 2)
	_icon.size = Vector2(16, 16)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_count.position = Vector2(4, 7)
	_count.size = Vector2(16, 12)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count.add_theme_font_size_override("font_size", 8)
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count)
	_key.position = Vector2(1, -4)
	_key.add_theme_font_size_override("font_size", 7)
	_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_key)
	mouse_entered.connect(func() -> void: hovered.emit(index))


func show_stack(stack: Inventory.ItemStack) -> void:
	_icon.texture = stack.item.icon if stack else null
	_count.text = str(stack.count) if stack and stack.count > 1 else ""


func set_key_label(text: String) -> void:
	_key.text = text


func set_selected(selected: bool) -> void:
	_style.border_color = Color.WHITE if selected else Color(0.45, 0.4, 0.4, 0.8)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(index)
		accept_event()
