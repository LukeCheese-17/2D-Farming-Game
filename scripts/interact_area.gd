class_name InteractArea
extends Area2D
## Add as a child of anything the player can use with the interact key (bed, doors,
## phone, shipping box). While the player stands inside it, the prompt is shown and
## pressing interact emits `interacted`.

signal interacted

## Hint shown while the player is in range, e.g. "E: Sleep". Empty shows nothing.
@export var prompt := "E: Use"


func _ready() -> void:
	collision_layer = 0
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func interact() -> void:
	interacted.emit()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("add_interactable"):
		body.add_interactable(self)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("remove_interactable"):
		body.remove_interactable(self)
