extends StaticBody2D
## Bed: stand next to it and press the interact key to sleep until the next day.

signal sleep_requested


func _ready() -> void:
	$InteractArea.interacted.connect(sleep_requested.emit)
