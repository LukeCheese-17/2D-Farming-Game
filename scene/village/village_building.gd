class_name VillageBuilding
extends StaticBody2D
## A building in the abandoned village (VIL-1). While it's a ruin, the player can
## hand in its materials; it's finished overnight and then opens its shop.
## Without data it's a house that stays boarded up.

const ROOF := preload("res://assets/Tilesets/Wooden_House_Roof_Tilset.png")
const WALLS := preload("res://assets/Tilesets/Wooden_House_Walls_Tilset.png")
const DOORS := preload("res://assets/Tilesets/Doors.png")
const SCAFFOLD := preload("res://assets/Generated/scaffold.png")
const RUBBLE := preload("res://assets/Generated/rubble.png")
const SIGNPOST := preload("res://assets/Generated/signpost.png")
const INTERACT := preload("res://scripts/interact_area.gd")

@export var data: BuildingData
## Shown on the sign once the shop is open.
@export var sign_icon: Texture2D

var _building := Node2D.new()
var _ruin := Node2D.new()
var _scaffold := Sprite2D.new()
var _sign := Node2D.new()
var _area: InteractArea


func _ready() -> void:
	_build()
	GameState.village_changed.connect(_refresh)
	_refresh()


func get_state() -> String:
	return GameState.get_building_state(data.id) if data else "ruin"


func _sprite(parent: Node, texture: Texture2D, region: Rect2, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	sprite.texture = atlas
	sprite.position = at
	parent.add_child(sprite)
	return sprite


func _rect(parent: Node, rect: Rect2, color: Color) -> void:
	var shape := ColorRect.new()
	shape.position = rect.position
	shape.size = rect.size
	shape.color = color
	shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shape)


func _board(parent: Node, from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from, to])
	line.width = 2.0
	line.default_color = Color(0.42, 0.28, 0.19)
	parent.add_child(line)


## Same pieces as the farmhouse (house_exterior.tscn), plus the ruined parts on top.
func _build() -> void:
	add_child(_building)
	_sprite(_building, WALLS, Rect2(48, 16, 32, 16), Vector2(-16, -24))
	_sprite(_building, WALLS, Rect2(48, 16, 32, 16), Vector2(16, -24))
	_sprite(_building, WALLS, Rect2(48, 32, 16, 16), Vector2(-24, -8))
	_sprite(_building, WALLS, Rect2(48, 16, 16, 16), Vector2(-8, -8))
	_sprite(_building, DOORS, Rect2(0, 16, 16, 16), Vector2(8, -8))
	_sprite(_building, WALLS, Rect2(48, 16, 16, 16), Vector2(24, -8))
	_sprite(_building, ROOF, Rect2(48, 32, 64, 48), Vector2(0, -56))

	add_child(_ruin)
	# Holes in the roof, a dark window, boarded door and window, rubble.
	_rect(_ruin, Rect2(-22, -70, 14, 9), Color(0.08, 0.06, 0.07))
	_rect(_ruin, Rect2(4, -52, 10, 6), Color(0.08, 0.06, 0.07))
	_rect(_ruin, Rect2(16, -76, 8, 5), Color(0.08, 0.06, 0.07))
	_rect(_ruin, Rect2(-29, -12, 10, 6), Color(0.05, 0.04, 0.05))
	_board(_ruin, Vector2(-31, -13), Vector2(-17, -5))
	_board(_ruin, Vector2(-31, -5), Vector2(-17, -13))
	_board(_ruin, Vector2(1, -12), Vector2(15, -6))
	_board(_ruin, Vector2(1, -5), Vector2(15, -11))
	for at: Vector2 in [Vector2(-34, 2), Vector2(30, 4)]:
		var rubble := Sprite2D.new()
		rubble.texture = RUBBLE
		rubble.position = at
		_ruin.add_child(rubble)

	_scaffold.texture = SCAFFOLD
	_scaffold.position = Vector2(-14, -18)
	add_child(_scaffold)

	_sign.position = Vector2(-40, 2)
	var post := Sprite2D.new()
	post.texture = SIGNPOST
	post.offset = Vector2(0, -8)
	_sign.add_child(post)
	if sign_icon:
		var icon := Sprite2D.new()
		icon.texture = sign_icon
		icon.scale = Vector2(0.5, 0.5)
		icon.position = Vector2(0, -11)
		_sign.add_child(icon)
	add_child(_sign)

	var body := CollisionShape2D.new()
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(64, 60)
	body.shape = body_shape
	body.position = Vector2(0, -30)
	add_child(body)

	_area = INTERACT.new()
	_area.position = Vector2(8, 5)
	var door := CollisionShape2D.new()
	var door_shape := RectangleShape2D.new()
	door_shape.size = Vector2(18, 14)
	door.shape = door_shape
	_area.add_child(door)
	_area.interacted.connect(_on_interacted)
	add_child(_area)


func _refresh() -> void:
	var state := get_state()
	var open := state == "open"
	_building.modulate = Color(0.86, 0.8, 0.76) if open else Color(0.5, 0.46, 0.46)
	_ruin.visible = not open
	_scaffold.visible = state == "building"
	_sign.visible = open
	if data == null:
		_area.prompt = "E: Look"
	else:
		_area.prompt = "E: Go in" if open else "E: Look at the %s" % data.display_name.to_lower()


func _on_interacted() -> void:
	if data == null:
		UI.show_dialogue(["The door is nailed shut. From the inside."])
		return
	match get_state():
		"ruin":
			_offer_rebuild()
		"building":
			UI.show_dialogue(["Your materials are stacked by the door.", "Some of the boards are already up. You didn't put them there."])
		"open":
			Shop.open(data.shop)


func _offer_rebuild() -> void:
	var parts: PackedStringArray = []
	for i in data.materials.size():
		var item := data.materials[i]
		parts.append("%s %d/%d" % [item.display_name, mini(GameState.inventory.count(item), data.amounts[i]), data.amounts[i]])
	parts.append("%dg" % data.price)
	UI.show_dialogue([data.ruin_text, "To rebuild the %s: %s." % [data.display_name.to_lower(), ", ".join(parts)]], ["Rebuild", "Leave"])
	var choice: int = await UI.dialogue_finished
	if choice != 0:
		return
	if GameState.rebuild(data):
		UI.show_dialogue(["You stack everything by the door and leave the money on the step.",
			"It will be finished by morning. You don't know how you know that."])
	else:
		UI.post_message("You don't have everything yet.")
