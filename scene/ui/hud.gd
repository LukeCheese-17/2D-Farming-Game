extends CanvasLayer
## On-screen info: day and time, money, the main quest and daily notes, the food,
## water and health meters, the hotbar and backpack, prompts, messages, the
## dialogue box, list menus (shops, the notice board) and the fishing minigame.

const MESSAGE_TIME := 2.0
const METER_SIZE := Vector2(46, 5)
const MENU_WIDTH := 300.0

@onready var _root: Control = $Root
@onready var _status: VBoxContainer = $Root/Status
@onready var _clock_label: Label = $Root/Status/ClockLabel
@onready var _money_label: Label = $Root/Status/MoneyLabel
@onready var _main_label: Label = $Root/Status/JobLabel
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

var _quest_label := Label.new()
var _meters: Dictionary[String, ColorRect] = {}
var _menu := PanelContainer.new()
var _menu_title := Label.new()
var _menu_list := VBoxContainer.new()
var _menu_footer := Label.new()
var _menu_options: Array[String] = []
var _menu_index := 0
var _text_box := PanelContainer.new()
var _text_title := Label.new()
var _text_edit := LineEdit.new()
var _ui_move := AudioStreamPlayer.new()
var _ui_select := AudioStreamPlayer.new()


func _ready() -> void:
	_inventory = GameState.inventory
	_root.theme = UITheme.make()
	_dialogue_box.add_theme_stylebox_override("panel", UITheme.panel(0.9))
	_backpack.add_theme_stylebox_override("panel", UITheme.panel(0.92))
	_build_status()
	_build_meters()
	_build_menu()
	_build_text_box()
	_build_slots()
	_ui_move.stream = preload("res://assets/Generated/ui_move.wav")
	_ui_select.stream = preload("res://assets/Generated/ui_select.wav")
	for sound in [_ui_move, _ui_select]:
		sound.volume_db = -12.0
		add_child(sound)
	GameState.time_changed.connect(func(_minutes: int) -> void: _refresh_clock())
	GameState.day_changed.connect(func(_day: int) -> void: _refresh_clock())
	GameState.day_changed.connect(func(_day: int) -> void: _refresh_quests())
	GameState.money_changed.connect(func(_money: int) -> void: _refresh_money())
	GameState.needs_changed.connect(_refresh_meters)
	GameState.time_changed.connect(func(_minutes: int) -> void: _refresh_main())
	GameState.village_changed.connect(_refresh_main)
	GameState.quests.changed.connect(_refresh_quests)
	GameState.quests.changed.connect(_refresh_main)
	_inventory.changed.connect(_refresh_slots)
	_inventory.changed.connect(_refresh_quests)
	_inventory.changed.connect(_refresh_main)
	_inventory.selection_changed.connect(_refresh_slots)
	UI.message_posted.connect(_show_message)
	UI.prompt_changed.connect(func(text: String) -> void: _prompt_label.text = text)
	UI.dialogue_started.connect(_on_dialogue_started)
	UI.dialogue_finished.connect(_on_dialogue_finished)
	UI.menu_started.connect(_on_menu_started)
	UI.menu_finished.connect(_on_menu_finished)
	UI.backpack_toggled.connect(_on_backpack_toggled)
	UI.text_started.connect(_on_text_started)
	UI.text_finished.connect(func(_text: String) -> void:
		_text_box.hide()
		_set_hotbar_visible(true))
	UI.fishing_started.connect(_on_fishing_started)
	_fishing_ring.finished.connect(UI.end_fishing)
	_prompt_label.text = ""
	_message_label.modulate.a = 0.0
	_dialogue_box.hide()
	_backpack.hide()
	_held_icon.hide()
	_menu.hide()
	_text_box.hide()
	_refresh_clock()
	_refresh_money()
	_refresh_main()
	_refresh_quests()
	_refresh_meters()
	_refresh_slots()


func _process(_delta: float) -> void:
	if _held_icon.visible:
		_held_icon.position = _root.get_local_mouse_position() - Vector2(8, 8)


func _unhandled_input(event: InputEvent) -> void:
	if _text_box.visible:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			UI.end_text()
	elif _menu.visible:
		_handle_menu_input(event)
	elif _dialogue_box.visible:
		_handle_dialogue_input(event)
	elif _backpack.visible:
		if event.is_action_pressed("backpack") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			UI.set_backpack_open(false)
	elif event.is_action_pressed("backpack") and not UI.fishing:
		get_viewport().set_input_as_handled()
		UI.set_backpack_open(true)


# --- Status ---

func _build_status() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(4, 4)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UITheme.panel(0.6))
	_root.add_child(panel)
	_root.move_child(panel, 0)
	_status.reparent(panel)
	_money_label.add_theme_color_override("font_color", UITheme.ACCENT)
	for label: Label in [_main_label, _quest_label]:
		label.add_theme_font_size_override("font_size", 8)
		label.custom_minimum_size.x = 200
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_child(_quest_label)


func _build_meters() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel(0.6))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-4 - 70, 4)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	panel.add_child(list)
	var meters := {"health": Color(0.75, 0.22, 0.24), "food": Color(0.82, 0.6, 0.32), "water": Color(0.4, 0.62, 0.88)}
	for name: String in meters:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var icon := TextureRect.new()
		icon.texture = load("res://assets/Generated/icon_%s.png" % name)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.custom_minimum_size = Vector2(9, 8)
		row.add_child(icon)
		var back := ColorRect.new()
		back.color = Color(0.08, 0.06, 0.07)
		back.custom_minimum_size = METER_SIZE
		back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var fill := ColorRect.new()
		fill.color = meters[name]
		fill.size = METER_SIZE
		back.add_child(fill)
		row.add_child(back)
		list.add_child(row)
		_meters[name] = fill
	_root.add_child(panel)
	_root.move_child(panel, 1)


func _refresh_meters() -> void:
	_set_meter("health", float(GameState.health) / GameState.MAX_HEALTH)
	_set_meter("food", GameState.food / GameState.MAX_NEED)
	_set_meter("water", GameState.water / GameState.MAX_NEED)


func _set_meter(name: String, share: float) -> void:
	var fill := _meters[name]
	fill.size.x = roundf(METER_SIZE.x * clampf(share, 0.0, 1.0))
	# Low meters blink faintly.
	fill.modulate.a = 0.55 if share < GameState.LOW_NEED / GameState.MAX_NEED else 1.0


func _refresh_clock() -> void:
	_clock_label.text = "Day %d   %s" % [GameState.day, GameState.get_time_text()]


func _refresh_money() -> void:
	_money_label.text = "%dg" % GameState.money


func _refresh_main() -> void:
	var board := GameState.quests
	var quest := board.get_main()
	_main_label.visible = quest != null
	if quest == null:
		return
	if board.is_main_done():
		_main_label.text = "Main: %s - done. Call %s." % [quest.title, GameState.get_caller()]
	elif quest.kind == QuestData.Kind.ITEMS:
		_main_label.text = "Main: %s - %d/%d %s to the board (%dg)" % [quest.title,
			mini(_inventory.count(quest.item), quest.amount), quest.amount, quest.item.display_name, quest.reward]
	else:
		_main_label.text = "Main: %s - %s (%dg)" % [quest.title, quest.get_goal(), quest.reward]


func _refresh_quests() -> void:
	var lines: PackedStringArray = []
	var board := GameState.quests
	for i in board.daily.size():
		var quest := board.daily[i]
		if not board.daily_done[i]:
			lines.append("Today: %d/%d %s (%dg)" % [mini(_inventory.count(quest.item), quest.amount),
				quest.amount, quest.item.display_name, quest.reward])
	_quest_label.text = "\n".join(lines)
	_quest_label.visible = not lines.is_empty()


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
		return
	var parts: PackedStringArray = ["%s x%d" % [stack.item.display_name, stack.count]]
	if stack.item.sell_price > 0:
		parts.append("sells for %dg each" % stack.item.sell_price)
	if stack.item.is_edible():
		parts.append("food +%d, water +%d, health +%d" % [stack.item.food, stack.item.water, stack.item.health])
	_item_info.text = " - ".join(parts)


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
	_set_hotbar_visible(false)
	_dialogue_box.show()
	_show_line()


func _on_dialogue_finished(_choice: int) -> void:
	_dialogue_box.hide()
	_set_hotbar_visible(not _menu.visible)


func _set_hotbar_visible(shown: bool) -> void:
	_hotbar.visible = shown
	_item_label.visible = shown


func _handle_dialogue_input(event: InputEvent) -> void:
	# Ignore the key press that opened the dialogue.
	if Engine.get_process_frames() == _opened_frame:
		return
	var choosing := _is_choosing()
	if choosing and (event.is_action_pressed("move_left") or event.is_action_pressed("move_up")):
		_choice_index = wrapi(_choice_index - 1, 0, _choices.size())
		_ui_move.play()
		_show_line()
		get_viewport().set_input_as_handled()
	elif choosing and (event.is_action_pressed("move_right") or event.is_action_pressed("move_down")):
		_choice_index = wrapi(_choice_index + 1, 0, _choices.size())
		_ui_move.play()
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


# --- List menus ---

func _build_menu() -> void:
	_menu.add_theme_stylebox_override("panel", UITheme.panel(0.94))
	_menu.set_anchors_preset(Control.PRESET_CENTER)
	_menu.custom_minimum_size = Vector2(MENU_WIDTH, 0)
	_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	_menu_title.add_theme_color_override("font_color", UITheme.ACCENT)
	box.add_child(_menu_title)
	_menu_list.add_theme_constant_override("separation", 0)
	box.add_child(_menu_list)
	_menu_footer.add_theme_font_size_override("font_size", 8)
	_menu_footer.add_theme_color_override("font_color", UITheme.DIM_TEXT)
	box.add_child(_menu_footer)
	_menu.add_child(box)
	_root.add_child(_menu)


func _on_menu_started(title: String, options: Array[String], footer: String, selected: int) -> void:
	_menu_title.text = title
	_menu_footer.text = footer + "      W/S: choose   E: pick   Esc: leave"
	_menu_options = options
	_menu_index = selected
	_opened_frame = Engine.get_process_frames()
	for child in _menu_list.get_children():
		_menu_list.remove_child(child)
		child.queue_free()
	for i in options.size():
		var label := Label.new()
		label.text = options[i]
		label.custom_minimum_size.x = MENU_WIDTH - 12
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_menu_list.add_child(label)
	_refresh_menu()
	_set_hotbar_visible(false)
	_menu.show()
	# Re-center after the size changes.
	await get_tree().process_frame
	_menu.position = ((_root.size - _menu.size) / 2.0).round() - Vector2(0, 20)


func _on_menu_finished(_index: int) -> void:
	_menu.hide()
	_set_hotbar_visible(not _dialogue_box.visible)


func _refresh_menu() -> void:
	var labels := _menu_list.get_children()
	for i in labels.size():
		var label: Label = labels[i]
		var selected := i == _menu_index
		label.text = ("> " if selected else "  ") + _menu_options[i]
		label.add_theme_color_override("font_color", UITheme.ACCENT if selected else UITheme.TEXT)


func _handle_menu_input(event: InputEvent) -> void:
	if Engine.get_process_frames() == _opened_frame:
		return
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_menu_index = wrapi(_menu_index - 1, 0, _menu_options.size())
		_ui_move.play()
		_refresh_menu()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_menu_index = wrapi(_menu_index + 1, 0, _menu_options.size())
		_ui_move.play()
		_refresh_menu()
	elif event.is_action_pressed("interact") or event.is_action_pressed("use_tool") or event.is_action_pressed("ui_accept"):
		_ui_select.play()
		get_viewport().set_input_as_handled()
		UI.end_menu(_menu_index)
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("backpack"):
		get_viewport().set_input_as_handled()
		UI.end_menu(-1)
	else:
		return
	get_viewport().set_input_as_handled()


# --- Text box ---

func _build_text_box() -> void:
	_text_box.add_theme_stylebox_override("panel", UITheme.panel(0.94))
	_text_box.custom_minimum_size = Vector2(220, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_text_title.add_theme_color_override("font_color", UITheme.ACCENT)
	box.add_child(_text_title)
	_text_edit.max_length = 16
	_text_edit.text_submitted.connect(func(text: String) -> void: UI.end_text(text))
	_text_edit.gui_input.connect(func(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel") and _text_box.visible:
			_text_edit.accept_event()
			UI.end_text())
	box.add_child(_text_edit)
	var hint := Label.new()
	hint.text = "Type, then Enter.   Esc: never mind"
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", UITheme.DIM_TEXT)
	box.add_child(hint)
	_text_box.add_child(box)
	_root.add_child(_text_box)


func _on_text_started(title: String, text: String) -> void:
	_text_title.text = title
	_text_edit.text = text
	_set_hotbar_visible(false)
	_text_box.show()
	await get_tree().process_frame
	_text_box.position = ((_root.size - _text_box.size) / 2.0).round() - Vector2(0, 20)
	_text_edit.grab_focus()
	_text_edit.caret_column = text.length()