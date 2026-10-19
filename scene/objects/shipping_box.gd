extends StaticBody2D
## Shipping box: hold an item in the hotbar and press interact to put the whole
## stack in. Everything inside is sold when the player sleeps (see GameState.sleep).

const OPEN_TIME := 0.6

@onready var _closed: Sprite2D = $Closed
@onready var _open: Sprite2D = $Open


func _ready() -> void:
	$InteractArea.interacted.connect(_on_interacted)


func _on_interacted() -> void:
	var item := GameState.inventory.get_selected_item()
	var shipped := GameState.ship_selected()
	if shipped == 0:
		UI.post_message("Hold something you can sell, then press E")
		return
	UI.post_message("Shipped %d %s" % [shipped, item.display_name])
	_closed.hide()
	_open.show()
	await get_tree().create_timer(OPEN_TIME).timeout
	_open.hide()
	_closed.show()
