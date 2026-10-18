extends Node2D
## Main scene glue: moving between the farm and the house, sleeping and
## waking up, and passing out if the player stays up until 2:00.

## Size of the room in house_interior.tscn.
const ROOM_SIZE := Vector2(160, 112)

@onready var _player: Player = $Objects/Player
@onready var _farm: Farm = $Farm
@onready var _door: InteractArea = $Objects/HouseExterior/DoorArea
@onready var _interior: Node2D = $Objects/HouseInterior
@onready var _door_sound: AudioStreamPlayer = $DoorSound


func _ready() -> void:
	_door.interacted.connect(enter_house)
	_interior.get_node("ExitArea").interacted.connect(leave_house)
	_interior.get_node("Objects/Bed").sleep_requested.connect(sleep)
	GameState.passed_out.connect(_on_passed_out)
	# The game starts with the player waking up in the house.
	_move_inside(_interior.get_node("WakeSpawn").global_position)


func enter_house() -> void:
	_door_sound.play()
	_move_inside(_interior.get_node("InsideSpawn").global_position)


func leave_house() -> void:
	_door_sound.play()
	_player.teleport(_door.global_position + Vector2(0, 8), false)
	_player.set_camera_limits(_farm.get_map_rect())


## Sells the shipping box, starts the next day, and wakes the player by the bed.
func sleep() -> void:
	_wake_up(GameState.sleep())


func _on_passed_out() -> void:
	var report: Array[String] = ["You passed out. You wake up in bed, but you don't remember getting there."]
	report.append_array(GameState.sleep())
	_wake_up(report)


func _wake_up(report: Array[String]) -> void:
	_move_inside(_interior.get_node("WakeSpawn").global_position)
	if not report.is_empty():
		GameState.show_dialogue(report)


func _move_inside(target: Vector2) -> void:
	_player.teleport(target, true)
	# Center the small room in the camera view.
	var room_center := _interior.global_position + ROOM_SIZE / 2.0
	var view := _player.get_view_size()
	_player.set_camera_limits(Rect2(room_center - view / 2.0, view))
