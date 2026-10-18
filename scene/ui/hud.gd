extends CanvasLayer
## On-screen info: day and time, money, the current phone job, inventory,
## toolbar, prompts, messages, and the dialogue box.

const TOOL_ICONS_TEXTURE := preload("res://assets/Objects/Basic_tools_and_meterials.png")
const FISHING_ROD_ICON := preload("res://assets/Generated/fishing_rod.png")
const FONT_SIZE := 10
const SLOT_SIZE := Vector2(22, 22)
const MESSAGE_TIME := 2.0

@onready var _root: Control = $Root
@onready var _clock_label: Label = $Root/Status/ClockLabel
@onready var _money_label: Label = $Root/Status/MoneyLabel
@onready var _job_label: Label = $Root/Status/JobLabel
@onready var _inventory: VBoxContainer = $Root/Inventory
@onready var _toolbar: HBoxContainer = $Root/Toolbar
@onready var _tool_label: Label = $Root/ToolLabel
@onready var _prompt_label: Label = $Root/PromptLabel
@onready var _message_label: Label = $Root/MessageLabel
@onready var _dialogue_box: PanelContainer = $Root/DialogueBox
@onready var _dialogue_text: Label = $Root/DialogueBox/VBox/Text
@onready var _dialogue_choices: Label = $Root/DialogueBox/VBox/Choices

var _slots: Array[Panel] = []
var _seeds_slot_icon: TextureRect
var _message_tween: Tween
var _lines: Array[String] = []
var _choices: Array[String] = []
var _line_index := 0
var _choice_index := 0
var _opened_frame := -1


func _ready() -> void:
	_root.theme = _make_theme()
	_dialogue_box.add_theme_stylebox_override("panel", _panel_style(0.8))
	_build_toolbar()
	GameState.time_changed.connect(func(_minutes: int) -> void: _refresh_clock())
	GameState.day_changed.connect(func(_day: int) -> void: _refresh_clock())
	GameState.money_changed.connect(func(_money: int) -> void: _refresh_money())
	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.tool_changed.connect(_refresh_toolbar)
	GameState.job_changed.connect(_refresh_job)
	GameState.message_posted.connect(_show_message)
	GameState.prompt_changed.connect(func(text: String) -> void: _prompt_label.text = text)
	GameState.dialogue_started.connect(_on_dialogue_started)
	GameState.dialogue_finished.connect(_on_dialogue_finished)
	_prompt_label.text = ""
	_message_label.modulate.a = 0.0
	_dialogue_box.hide()
	_refresh_clock()
	_refresh_money()
	_refresh_job()
	_refresh_inventory()


func _unhandled_input(event: InputEvent) -> void:
	# Ignore the key press that opened the dialogue.
	if not _dialogue_box.visible or Engine.get_process_frames() == _opened_frame:
		return
	var choosing := not _choices.is_empty() and _line_index == _lines.size() - 1
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
			GameState.end_dialogue(_choice_index if choosing else -1)


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
	var job := GameState.active_job
	_job_label.visible = job != null
	if job:
		_job_label.text = "Job: %d/%d %s by day %d (%dg)" % [
			mini(GameState.job_progress, job.amount), job.amount, job.item.display_name,
			GameState.job_deadline, job.reward]


func _refresh_inventory() -> void:
	for child in _inventory.get_children():
		child.queue_free()
	for item in GameState.get_items():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		var icon := TextureRect.new()
		icon.texture = item.icon
		row.add_child(icon)
		var label := Label.new()
		label.text = "x%d" % GameState.get_item_count(item)
		label.custom_minimum_size.x = 22
		row.add_child(label)
		_inventory.add_child(row)
	_refresh_toolbar()


# --- Toolbar ---

func _build_toolbar() -> void:
	var icons := {
		Tools.Type.HOE: _atlas_icon(Rect2(32, 0, 16, 16)),
		Tools.Type.WATERING_CAN: _atlas_icon(Rect2(0, 0, 16, 16)),
		Tools.Type.SEEDS: null,  # Set from the crop in _refresh_toolbar().
		Tools.Type.FISHING_ROD: FISHING_ROD_ICON,
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


func _refresh_toolbar() -> void:
	var crop := GameState.get_selected_crop()
	_seeds_slot_icon.texture = crop.seed.icon
	for i in _slots.size():
		_slots[i].add_theme_stylebox_override("panel", _slot_style(i == GameState.current_tool))
	var tool_name: String = Tools.NAMES[GameState.current_tool]
	match GameState.current_tool:
		Tools.Type.SEEDS:
			tool_name = "%s (%d)" % [crop.seed.display_name, GameState.get_item_count(crop.seed)]
		Tools.Type.HAND:
			tool_name = "Hand - harvest crops, collect from animals"
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
	_toolbar.hide()
	_tool_label.hide()
	_dialogue_box.show()
	_show_line()


func _on_dialogue_finished(_choice: int) -> void:
	_dialogue_box.hide()
	_toolbar.show()
	_tool_label.show()


func _show_line() -> void:
	_dialogue_text.text = _lines[_line_index]
	var choosing := not _choices.is_empty() and _line_index == _lines.size() - 1
	if choosing:
		var parts: PackedStringArray = []
		for i in _choices.size():
			parts.append(("> %s <" if i == _choice_index else "  %s  ") % _choices[i])
		_dialogue_choices.text = "   ".join(parts) + "      (arrows, E)"
	else:
		_dialogue_choices.text = "E"
	_dialogue_choices.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if not choosing else HORIZONTAL_ALIGNMENT_CENTER
