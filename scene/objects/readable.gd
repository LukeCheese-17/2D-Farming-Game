extends StaticBody2D
## A sign or well: interact to read its lines. A well also lets the player drink.

@export var lines: Array[String] = []
## Drinking here fills the water meter.
@export var drinkable := false


func _ready() -> void:
	$InteractArea.interacted.connect(_on_interacted)


func _on_interacted() -> void:
	if drinkable:
		GameState.drink(GameState.MAX_NEED)
		UI.post_message("You drink. The water is very cold, and very deep.")
		return
	UI.show_dialogue(lines)
