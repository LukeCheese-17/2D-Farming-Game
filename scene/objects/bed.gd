extends StaticBody2D
## Bed: stand next to it and press the interact key to sleep until the next day.

const PROMPT := "E: Sleep"

@onready var _area: Area2D = $InteractArea


func _ready() -> void:
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)


func interact() -> void:
	GameState.advance_day()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("set_interactable"):
		body.set_interactable(self)
		GameState.set_prompt(PROMPT)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("clear_interactable"):
		body.clear_interactable(self)
		GameState.set_prompt("")
