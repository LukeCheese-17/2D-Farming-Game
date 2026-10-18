extends CanvasLayer
## On-screen info: day, toolbar, inventory, prompts, messages and the sleep fade.

const TOOL_ICONS_TEXTURE := preload("res://assets/Objects/Basic_tools_and_meterials.png")
const FONT_SIZE := 10
const SLOT_SIZE := Vector2(22, 22)
const MESSAGE_TIME := 1.5

@onready var _root: Control = $Root
@onready var _day_label: Label = $Root/DayLabel
@onready var _inventory: VBoxContainer = $Root/Inventory
@onready var _toolbar: HBoxContainer = $Root/Toolbar
@onready var _tool_label: Label = $Root/ToolLabel
@onready var _prompt_label: Label = $Root/PromptLabel
@onready var _message_label: Label = $Root/MessageLabel

var _slots: Array[Panel] = []
var _seeds_slot_icon: TextureRect
var _count_labels: Dictionary[StringName, Label] = {}
var _message_tween: Tween


func _ready() -> void:
	_root.theme = _make_theme()
	_build_toolbar()
	_build_inventory()
	GameState.day_changed.connect(_on_day_changed)
	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.tool_changed.connect(_refresh_toolbar)
	GameState.message_posted.connect(_show_message)
	GameState.prompt_changed.connect(func(text: String) -> void: _prompt_label.text = text)
	_day_label.text = "Day %d" % GameState.day
	_prompt_label.text = ""
	_message_label.modulate.a = 0.0
	_refresh_inventory()
	_refresh_toolbar()


func _make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = FONT_SIZE
	theme.set_color("font_outline_color", "Label", Color.BLACK)
	theme.set_constant("outline_size", "Label", 3)
	return theme


func _build_toolbar() -> void:
	var icons := {
		Tools.Type.HOE: _atlas_icon(Rect2(32, 0, 16, 16)),
		Tools.Type.WATERING_CAN: _atlas_icon(Rect2(0, 0, 16, 16)),
		Tools.Type.SEEDS: null,  # Set from the selected crop in _refresh_toolbar().
		Tools.Type.HAND: null,
	}
	for tool in Tools.Type.values():
		var slot := Panel.new()
		slot.custom_minimum_size = SLOT_SIZE
		var icon := TextureRect.new()
		icon.texture = icons[tool]
		icon.position = Vector2(3, 3)
		icon.size = Vector2(16, 16)
		slot.add_child(icon)
		var key := Label.new()
		key.text = str(tool + 1)
		key.add_theme_font_size_override("font_size", 8)
		key.position = Vector2(1, -3)
		slot.add_child(key)
		if tool == Tools.Type.SEEDS:
			_seeds_slot_icon = icon
		_toolbar.add_child(slot)
		_slots.append(slot)


func _build_inventory() -> void:
	for crop in GameState.crops:
		_add_inventory_row(crop.seed_item, crop.seed_icon)
		_add_inventory_row(crop.produce_item, crop.produce_icon)


func _add_inventory_row(item: StringName, icon_texture: Texture2D) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	var icon := TextureRect.new()
	icon.texture = icon_texture
	row.add_child(icon)
	var label := Label.new()
	label.custom_minimum_size.x = 22
	row.add_child(label)
	_inventory.add_child(row)
	_count_labels[item] = label


func _refresh_inventory() -> void:
	for item in _count_labels:
		_count_labels[item].text = "x%d" % GameState.get_item_count(item)
	_refresh_toolbar()


func _refresh_toolbar() -> void:
	var crop := GameState.get_selected_crop()
	_seeds_slot_icon.texture = crop.seed_icon
	for i in _slots.size():
		_slots[i].add_theme_stylebox_override("panel", _slot_style(i == GameState.current_tool))
	var tool_name: String = Tools.NAMES[GameState.current_tool]
	match GameState.current_tool:
		Tools.Type.SEEDS:
			tool_name = "%s seeds (%d)" % [crop.display_name, GameState.get_item_count(crop.seed_item)]
		Tools.Type.HAND:
			tool_name = "Hand - harvest ripe crops"
	_tool_label.text = tool_name


func _slot_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.45)
	style.set_corner_radius_all(2)
	if selected:
		style.border_color = Color.WHITE
		style.set_border_width_all(1)
	return style


func _atlas_icon(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = TOOL_ICONS_TEXTURE
	texture.region = region
	return texture


func _show_message(text: String) -> void:
	_message_label.text = text
	if _message_tween:
		_message_tween.kill()
	_message_label.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(MESSAGE_TIME)
	_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.4)


func _on_day_changed(day: int) -> void:
	_day_label.text = "Day %d" % day
