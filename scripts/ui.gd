extends Node
## Autoload "UI": lets game code talk to the HUD without knowing about it —
## messages, the interact prompt, dialogue, list menus (shops, the notice board),
## the backpack, and the fishing minigame. Also loads and applies the options.

signal message_posted(text: String)
signal prompt_changed(text: String)
signal dialogue_started(lines: Array[String], choices: Array[String])
## choice is the picked option's index, or -1 if there were no choices.
signal dialogue_finished(choice: int)
signal menu_started(title: String, options: Array[String], footer: String, selected: int)
## index is the picked option, or -1 if the menu was closed.
signal menu_finished(index: int)
signal backpack_toggled(open: bool)
## at is the world position the minigame appears above (the player).
signal fishing_started(fish: FishData, at: Vector2)
signal fishing_finished(success: bool)

const OPTIONS_PATH := "user://options.cfg"

var in_dialogue := false
var in_menu := false
var backpack_open := false
## True while the player has a line in the water (the backpack can't open).
var fishing := false

var volume := 0.8
var fullscreen := false


func _ready() -> void:
	load_options()


## True while a dialogue, menu or the backpack is open: the player can't move and time stops.
func is_blocking() -> bool:
	return in_dialogue or in_menu or backpack_open


func post_message(text: String) -> void:
	message_posted.emit(text)


## Shows a hint such as "E: Sleep"; pass "" to hide it.
func set_prompt(text: String) -> void:
	prompt_changed.emit(text)


## Shows lines one after another; with choices, the last line asks the player to pick one.
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


## A vertical list to pick from. Await menu_finished for the index (-1 = closed).
func show_menu(title: String, options: Array[String], footer := "", selected := 0) -> void:
	in_menu = true
	menu_started.emit(title, options, footer, clampi(selected, 0, options.size() - 1))


func end_menu(index := -1) -> void:
	in_menu = false
	menu_finished.emit(index)


func set_backpack_open(open: bool) -> void:
	if open == backpack_open:
		return
	backpack_open = open
	backpack_toggled.emit(open)


## Starts the timing-ring minigame for a hooked fish. Await fishing_finished for the result.
func start_fishing(fish: FishData, at: Vector2) -> void:
	fishing_started.emit(fish, at)


## Called by the minigame when it ends.
func end_fishing(success: bool) -> void:
	fishing_finished.emit(success)


## Clears everything left open (when leaving the game for the title screen).
func reset() -> void:
	in_dialogue = false
	in_menu = false
	backpack_open = false
	fishing = false


# --- Options (UI-4) ---

func load_options() -> void:
	var config := ConfigFile.new()
	if config.load(OPTIONS_PATH) == OK:
		volume = config.get_value("audio", "volume", volume)
		fullscreen = config.get_value("video", "fullscreen", fullscreen)
	apply_options()


func save_options() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.save(OPTIONS_PATH)


func apply_options() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(0, volume <= 0.001)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
