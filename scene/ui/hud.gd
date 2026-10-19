extends CanvasLayer
## On-screen info: day and time, money, the current phone job, the hotbar and
## backpack, prompts, messages, the dialogue box and the fishing minigame.

const FONT_SIZE := 10
const MESSAGE_TIME := 2.0

@onready var _root: Control = $Root
@onready var _clock_label: Label = $Root/Status/ClockLabel
@onready var _money_label: Label = $Root/Status/MoneyLabel
@onready var _job_label: Label = $Root/Status/JobLabel
@onready var _hotbar: HBoxContainer = $Root/Hotbar
@onready var _item_label: Label = $Root/ItemLabel
@onready var _prompt_label: Label = $Root/PromptLabel
@onready var _message_label: Label = $Root/MessageLabel
@onready var _dialogue_box: PanelContainer = $Root/DialogueBox
@onready var _dialogue_text: Label = $Root/DialogueBox/VBox/Text
@onready var _dialogue_choices: Label = $Root/DialogueBox/VBox/Choices
@onready var _backpack: PanelContainer = $Root/Backpack
@onready var _backpack_hotbar: GridContainer = $Root/Backpack/VBox/HotbarGrid
@onready var _backpack_grid: GridContainer = $Root/Backpack/VBox/BackpackGrid
@onready var _item_info: Label = $Root/Backpack/VBox/ItemInfo
@onready var _held_icon: TextureRect = $Root/HeldIcon
@onready var _fishing_ring: FishingRing = $Root/FishingRing

var _inventory: Inventory
var _hotbar_slots: Array[InventorySlot] = []
var _backpack_slots: Array[InventorySlot] = []
## Stack picked up with the mouse while the backpack is open.
var _held: Inventory.ItemStack
var _message_tween: Tween
var _lines: Array[String] = []
var _choices: Array[String] = []
var _line_index := 0
var _choice_index := 0
var _opened_frame := -1


func _ready() -> void:
	_inventory = GameState.inventory
	_root.theme = _make_theme()
	_dialogue_box.add_theme_stylebox_override("panel", _panel_style(0.85))
	_backpack.add_theme_stylebox_override("panel", _panel_style(0.9))
	_build_slots()
	GameState.time_changed.connect(func(_minutes: int) -> void: _refresh_clock())
	GameState.day_changed.connect(func(_day: int) -> void: _refresh_clock())
	GameState.money_changed.connect(func(_money: int) -> void: _refresh_money())
	GameState.jobs.changed.connect(_refresh_job)
	_inventory.changed.connect(_refresh_slots)
	_inventory.selection_changed.connect(_refresh_slots)
	UI.message_posted.connect(_show_message)
	UI.prompt_changed.connect(func(text: String) -> void: _prompt_label.text = text)
	UI.dialogue_started.connect(_on_dialogue_started)
	UI.dialogue_finished.connect(_on_dialogue_finished)
	UI.backpack_toggled.connect(_on_backpack_toggled)
	UI.fishing_started.connect(_on_fishing_started)
	_fishing_ring.finished.connect(UI.end_fishing)
	_prompt_label.text = ""
	_message_label.modulate.a = 0.0
	_dialogue_box.hide()
	_backpack.hide()
	_held_icon.hide()
	_refresh_clock()
	_refresh_money()
	_refresh_job()
	_refresh_slots()


func _process(_delta: float) -> void:
	if _held_icon.visible:
		_held_icon.position = _root.get_local_mouse_position() - Vector2(8, 8)


func _unhandled_input(event: InputEvent) -> void:
	if _dialogue_box.visible:
		_handle_dialogue_input(event)
	elif _backpack.visible:
		if event.is_action_pressed("backpack") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			UI.set_backpack_open(false)
	elif event.is_action_pressed("backpack") and not UI.fishing:
		get_viewport().set_input_as_handled()
		UI.set_backpack_open(true)


func _make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = FONT_SIZE
	theme.set_color("font_outline_color", "Label", Color.BLACK)
	theme.set_constant("outline_size", "Label", 3)
	return theme


func _panel_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.05, alpha)
	style.border_color = Color(0.5, 0.45, 0.45)
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	return style


# --- Status ---

func _refresh_clock() -> void:
	_clock_label.text = "Day %d   %s" % [GameState.day, GameState.get_time_text()]


func _refresh_money() -> void:
	_money_label.text = "%dg" % GameState.money


func _refresh_job() -> void:
	var board := GameState.jobs
	_job_label.visible = board.active != null
	if board.active:
		_job_label.text = "Job: %d/%d %s by day %d (%dg)" % [
			mini(board.progress, board.active.amount), board.active.amount,
			board.active.item.display_name, board.deadline, board.active.reward]


# --- Hotbar and backpack ---

func _build_slots() -> void:
	for i in Inventory.HOTBAR_SIZE:
		var key := str((i + 1) % 10)
		var slot := _make_slot(i, _hotbar, key)
		slot.clicked.connect(_inventory.select)
		_hotbar_slots.append(slot)
	for i in Inventory.SIZE:
		var grid := _backpack_hotbar if i < Inventory.HOTBAR_SIZE else _backpack_grid
		var slot := _make_slot(i, grid, str((i + 1) % 10) if i < Inventory.HOTBAR_SIZE else "")
		slot.clicked.connect(_on_backpack_slot_clicked)
		slot.hovered.connect(_on_backpack_slot_hovered)
		_backpack_slots.append(slot)


func _make_slot(index: int, parent: Control, key: String) -> InventorySlot:
	var slot := InventorySlot.new()
	slot.index = index
	slot.set_key_label(key)
	parent.add_child(slot)
	return slot


func _refresh_slots() -> void:
	for slot in _hotbar_slots:
		slot.show_stack(_inventory.get_slot(slot.index))
		slot.set_selected(slot.index == _inventory.selected)
	for slot in _backpack_slots:
		slot.show_stack(_inventory.get_slot(slot.index))
		slot.set_selected(slot.index == _inventory.selected)
	var item := _inventory.get_selected_item()
	_item_label.text = item.display_name if item else "Empty hand"


## Click to pick up a stack, click again to put it down (merging or swapping).
func _on_backpack_slot_clicked(index: int) -> void:
	if _held == null:
		_held = _inventory.take(index)
	else:
		_held = _inventory.put(index, _held)
	_held_icon.visible = _held != null
	_held_icon.texture = _held.item.icon if _held else null


func _on_backpack_slot_hovered(index: int) -> void:
	var stack := _inventory.get_slot(index)
	if stack == null:
		_item_info.text = ""
	elif stack.item.sell_price > 0:
		_item_info.text = "%s x%d - sells for %dg each" % [stack.item.display_name, stack.count, stack.item.sell_price]
	else:
		_item_info.text = "%s x%d" % [stack.item.display_name, stack.count]


func _on_backpack_toggled(open: bool) -> void:
	_backpack.visible = open
	_item_info.text = "Click an item to pick it up, click a slot to put it down."
	if not open and _held:
		# Put a carried stack back rather than losing it.
		_inventory.add(_held.item, _held.count)
		_held = null
		_held_icon.hide()


## Shows the timing ring just above the player.
func _on_fishing_started(fish: FishData, at: Vector2) -> void:
	var on_screen := get_viewport().get_canvas_transform() * at
	_fishing_ring.position = (on_screen - Vector2(_fishing_ring.size.x / 2.0, _fishing_ring.size.y + 36.0)).round()
	_fishing_ring.start(fish)


# --- Messages and dialogue ---

func _show_message(text: String) -> void:
	_message_label.text = text
	if _message_tween:
		_message_tween.kill()
	_message_label.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(MESSAGE_TIME)
	_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.4)


func _on_dialogue_started(lines: Array[String], choices: Array[String]) -> void:
	_lines = lines
	_choices = choices
	_line_index = 0
	_choice_index = 0
	_opened_frame = Engine.get_process_frames()
	_hotbar.hide()
	_item_label.hide()
	_dialogue_box.show()
	_show_line()


func _on_dialogue_finished(_choice: int) -> void:
	_dialogue_box.hide()
	_hotbar.show()
	_item_label.show()


func _handle_dialogue_input(event: InputEvent) -> void:
	# Ignore the key press that opened the dialogue.
	if Engine.get_process_frames() == _opened_frame:
		return
	var choosing := _is_choosing()
	if choosing and (event.is_action_pressed("move_left") or event.is_action_pressed("move_up")):
		_choice_index = wrapi(_choice_index - 1, 0, _choices.size())
		_show_line()
		get_viewport().set_input_as_handled()
	elif choosing and (event.is_action_pressed("move_right") or event.is_action_pressed("move_down")):
		_choice_index = wrapi(_choice_index + 1, 0, _choices.size())
		_show_line()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("use_tool"):
		get_viewport().set_input_as_handled()
		if _line_index < _lines.size() - 1:
			_line_index += 1
			_show_line()
		else:
			UI.end_dialogue(_choice_index if choosing else -1)


func _is_choosing() -> bool:
	return not _choices.is_empty() and _line_index == _lines.size() - 1


func _show_line() -> void:
	_dialogue_text.text = _lines[_line_index]
	if _is_choosing():
		var parts: PackedStringArray = []
		for i in _choices.size():
			parts.append(("> %s <" if i == _choice_index else "  %s  ") % _choices[i])
		_dialogue_choices.text = "   ".join(parts) + "      (arrows, E)"
		_dialogue_choices.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		_dialogue_choices.text = "E"
		_dialogue_choices.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
