extends Control
## The home screen (UI-2): New Game, Continue, Options and Quit, over a dark
## field where something occasionally opens its eyes. New Game and Continue pick
## one of the three save slots; New Game then plays the intro.

const MAIN_SCENE := "res://scene/main/main.tscn"
const INTRO_SCENE := "res://scene/menus/intro.tscn"
const EYES := preload("res://assets/Generated/eyes.png")

var _heading := Label.new()
var _buttons := VBoxContainer.new()
var _options := OptionsPanel.new()
var _eyes := TextureRect.new()
var _eyes_time := 3.0


func _ready() -> void:
	# Nothing ticks behind the title screen.
	GameState.clock_running = false
	SaveGame.migrate_old_save()
	theme = UITheme.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var back := ColorRect.new()
	back.color = Color(0.03, 0.03, 0.045)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	# A tree line along the bottom.
	var trees := Polygon2D.new()
	var points := PackedVector2Array([Vector2(0, 360), Vector2(0, 280)])
	for i in 33:
		points.append(Vector2(i * 20, 262 + (i * 37 % 23) - (14 if i % 3 == 0 else 0)))
	points.append_array([Vector2(640, 280), Vector2(640, 360)])
	trees.polygon = points
	trees.color = Color(0.015, 0.02, 0.025)
	add_child(trees)
	_eyes.texture = EYES
	_eyes.modulate = Color(1, 0.9, 0.7, 0.0)
	add_child(_eyes)

	# Placeholder name until the game has a real one.
	var title := Label.new()
	title.text = "GAME"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", UITheme.TEXT)
	title.add_theme_constant_override("outline_size", 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-160, 56)
	title.size = Vector2(320, 44)
	add_child(title)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-80, -30)
	panel.custom_minimum_size = Vector2(160, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_heading.add_theme_color_override("font_color", UITheme.DIM_TEXT)
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_heading)
	_buttons.add_theme_constant_override("separation", 3)
	box.add_child(_buttons)
	_options.closed.connect(_hide_options)
	_options.hide()
	box.add_child(_options)
	_show_main_menu()

	var wind := AudioStreamPlayer.new()
	wind.stream = preload("res://assets/Generated/wind.wav")
	wind.volume_db = -16.0
	wind.autoplay = true
	add_child(wind)


func _process(delta: float) -> void:
	_eyes_time -= delta
	if _eyes_time > 0.0:
		return
	_eyes_time = randf_range(6.0, 14.0)
	_eyes.position = Vector2(randf_range(40, 600), randf_range(268, 300))
	var tween := create_tween()
	tween.tween_property(_eyes, "modulate:a", 0.8, 1.2)
	tween.tween_interval(randf_range(0.8, 2.0))
	tween.tween_property(_eyes, "modulate:a", 0.0, 0.15)


## Replaces the buttons. entries are [text, callable] or [text, callable, disabled].
func _set_buttons(heading: String, entries: Array, focus := 0) -> void:
	_heading.text = heading
	_heading.visible = heading != ""
	for child in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	for entry: Array in entries:
		var button := Button.new()
		button.text = entry[0]
		button.pressed.connect(entry[1])
		button.disabled = entry.size() > 2 and entry[2]
		_buttons.add_child(button)
	var first := _buttons.get_child(focus) as Button
	if first.disabled:
		for button: Button in _buttons.get_children():
			if not button.disabled:
				first = button
				break
	first.grab_focus()


func _show_main_menu(focus := -1) -> void:
	var any_save := range(SaveGame.SLOTS).any(func(slot: int) -> bool: return SaveGame.slot_exists(slot))
	if focus < 0:
		focus = 1 if any_save else 0
	var entries := [
		["New Game", _show_slots.bind(true)],
		["Continue", _show_slots.bind(false), not any_save],
		["Options", _show_options],
	]
	# A browser tab can't be closed by the game, so Quit only exists on desktop.
	if not OS.has_feature("web"):
		entries.append(["Quit", get_tree().quit])
	_set_buttons("", entries, focus)


## Lists the three slots, for a new game or for loading.
func _show_slots(new_game: bool) -> void:
	var entries := []
	for slot in SaveGame.SLOTS:
		var text := "Slot %d: %s" % [slot + 1, SaveGame.describe_slot(slot)]
		if new_game:
			entries.append([text, _pick_new_slot.bind(slot)])
		else:
			entries.append([text, _load_slot.bind(slot), not SaveGame.slot_exists(slot)])
	entries.append(["Back", _show_main_menu.bind(0 if new_game else 1)])
	_set_buttons("New game in..." if new_game else "Continue from...", entries)


func _pick_new_slot(slot: int) -> void:
	if not SaveGame.slot_exists(slot):
		_start_new_game(slot)
		return
	_set_buttons("Erase slot %d?" % (slot + 1), [
		["No", _show_slots.bind(true)],
		["Yes, start over", _start_new_game.bind(slot)],
	])


func _start_new_game(slot: int) -> void:
	SaveGame.delete_slot(slot)
	SaveGame.use_slot(slot)
	GameState.new_game()
	GameState.clock_running = false
	get_tree().change_scene_to_file(INTRO_SCENE)


func _load_slot(slot: int) -> void:
	SaveGame.use_slot(slot)
	if SaveGame.load_game():
		get_tree().change_scene_to_file(MAIN_SCENE)
	else:
		_heading.text = "That save is damaged."


func _show_options() -> void:
	_buttons.hide()
	_heading.hide()
	_options.show()
	_options.focus()


func _hide_options() -> void:
	_options.hide()
	_buttons.show()
	_show_main_menu(2)
