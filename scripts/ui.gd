extends Node
## Autoload "UI": lets game code talk to the HUD without knowing about it —
## messages, the interact prompt, dialogue, the backpack, and the fishing minigame.

signal message_posted(text: String)
signal prompt_changed(text: String)
signal dialogue_started(lines: Array[String], choices: Array[String])
## choice is the picked option's index, or -1 if there were no choices.
signal dialogue_finished(choice: int)
signal backpack_toggled(open: bool)
## at is the world position the minigame appears above (the player).
signal fishing_started(fish: FishData, at: Vector2)
signal fishing_finished(success: bool)

var in_dialogue := false
var backpack_open := false
## True while the player has a line in the water (the backpack can't open).
var fishing := false


## True while a dialogue or the backpack is open: the player can't move and time stops.
func is_blocking() -> bool:
	return in_dialogue or backpack_open


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
