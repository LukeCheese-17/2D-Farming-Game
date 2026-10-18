extends StaticBody2D
## Shipping box: press interact to put every sellable item in it.
## Everything inside is sold when the player sleeps (see GameState.sleep).

const OPEN_TIME := 0.6

@onready var _closed: Sprite2D = $Closed
@onready var _open: Sprite2D = $Open


func _ready() -> void:
	$InteractArea.interacted.connect(_on_interacted)


func _on_interacted() -> void:
	var shipped := GameState.ship_all()
	if shipped.is_empty():
		GameState.post_message("Nothing to ship")
		return
	var parts: PackedStringArray = []
	for item in shipped:
		parts.append("%d %s" % [shipped[item], item.display_name])
	GameState.post_message("Shipped " + ", ".join(parts))
	_closed.hide()
	_open.show()
	await get_tree().create_timer(OPEN_TIME).timeout
	_open.hide()
	_closed.show()
