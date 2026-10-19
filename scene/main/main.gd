extends Node2D
## Main scene glue: moving between the farm, the house and the mine, sleeping and
## waking up, passing out at 2:00 or fainting, and saving/loading the world.

## Size of the room in house_interior.tscn.
const ROOM_SIZE := Vector2(160, 112)

@onready var _player: Player = $Objects/Player
@onready var _farm: Farm = $Farm
@onready var _door: InteractArea = $Objects/HouseExterior/DoorArea
@onready var _interior: Node2D = $Objects/HouseInterior
@onready var _mine: Mine = $Objects/Mine
@onready var _cave: Node2D = $Objects/CaveEntrance
@onready var _door_sound: AudioStreamPlayer = $DoorSound
## Quiet, creepy music under the ambient sounds (ATM-6); slower and lower down the mine.
var _music := AudioStreamPlayer.new()


func _ready() -> void:
	GameState.clock_running = true
	_music.stream = preload("res://assets/Generated/music.wav")
	_music.volume_db = -17.0
	add_child(_music)
	_music.play()
	_door.interacted.connect(enter_house)
	_interior.get_node("ExitArea").interacted.connect(leave_house)
	_interior.get_node("Objects/Bed").sleep_requested.connect(sleep)
	_cave.get_node("InteractArea").interacted.connect(choose_mine_floor)
	_mine.exit_requested.connect(leave_mine)
	_mine.descend_requested.connect(func() -> void: enter_mine(_mine.floor_index + 1))
	GameState.passed_out.connect(_on_passed_out)
	GameState.fainted.connect(_on_fainted)
	# The game starts with the player waking up in the house.
	_move_inside(_interior.get_node("WakeSpawn").global_position)
	if not GameState.pending_load.is_empty():
		_apply_save_data(GameState.pending_load)
		GameState.pending_load = {}
	elif GameState.autosave and not SaveGame.exists():
		# A new game takes its slot right away.
		SaveGame.save.call_deferred(self)


func enter_house() -> void:
	_door_sound.play()
	_move_inside(_interior.get_node("InsideSpawn").global_position)


func leave_house() -> void:
	_door_sound.play()
	_go_outside(_door.global_position + Vector2(0, 8))


## The lift cage goes down to any floor already reached. Boarded up until a main quest opens it (MIN-5).
func choose_mine_floor() -> void:
	if not GameState.quests.is_mine_unlocked() and GameState.deepest_floor == 0:
		UI.show_dialogue(["Planks are nailed across the mouth of the mine. A chain, a padlock.",
			"Something on the other side is breathing slow, or it's just the wind."])
		return
	if GameState.deepest_floor <= 1:
		enter_mine(0)
		return
	var options: Array[String] = []
	for i in GameState.deepest_floor:
		options.append("Floor %d: %s" % [i + 1, GameState.mine_floors[i].display_name])
	options.append("Stay up here")
	UI.show_menu("The mine", options, "The old lift cage still works. Mostly.", GameState.deepest_floor - 1)
	var index: int = await UI.menu_finished
	if index >= 0 and index < GameState.deepest_floor:
		enter_mine(index)


func enter_mine(index: int) -> void:
	_door_sound.play()
	_mine.enter_floor(index)
	_player.teleport(_mine.get_start_position(), false, _mine)
	_player.set_camera_limits(_mine.get_map_rect())
	_music.pitch_scale = 0.85 - index * 0.04
	_music.volume_db = -20.0 - index
	var floor_data := _mine.floor_data
	UI.post_message("Floor %d - %s" % [index + 1, floor_data.display_name])
	var seen := "seen_floor_%d" % index
	if not GameState.flags.get(seen, false) and floor_data.arrival_text != "":
		GameState.flags[seen] = true
		UI.show_dialogue([floor_data.arrival_text])


func leave_mine() -> void:
	_door_sound.play()
	_mine.leave()
	_go_outside(_cave.global_position + Vector2(0, 10))


## Sells the shipping box, starts the next day, and wakes the player by the bed.
func sleep() -> void:
	_wake_up(GameState.sleep())


func _on_passed_out() -> void:
	var report: Array[String] = ["You passed out. You wake up in bed, but you don't remember getting there."]
	report.append_array(GameState.sleep())
	_wake_up(report)


## Hunger, thirst or getting hurt in the mine: the player wakes up at home the next morning.
func _on_fainted(reason: String) -> void:
	var report := GameState.recover_from_faint(reason)
	report.append_array(GameState.sleep())
	_wake_up(report)


func _wake_up(report: Array[String]) -> void:
	if _player.in_mine:
		_mine.leave()
	_move_inside(_interior.get_node("WakeSpawn").global_position)
	if GameState.autosave:
		SaveGame.save(self)
	if not report.is_empty():
		UI.show_dialogue(report)


func _go_outside(target: Vector2) -> void:
	_surface_music()
	_player.teleport(target, false, _farm)
	_player.set_camera_limits(_farm.get_map_rect())


func _surface_music() -> void:
	_music.pitch_scale = 1.0
	_music.volume_db = -17.0


func _move_inside(target: Vector2) -> void:
	_surface_music()
	_player.teleport(target, true, _farm)
	# Center the small room in the camera view.
	var room_center := _interior.global_position + ROOM_SIZE / 2.0
	var view := _player.get_view_size()
	_player.set_camera_limits(Rect2(room_center - view / 2.0, view))


# --- Saving ---

## The world part of the save: farm tiles and crops, animals, where the player is.
func get_save_data() -> Dictionary:
	var animals := {}
	for animal: Animal in get_tree().get_nodes_in_group("animals"):
		animals[String(animal.name)] = animal.has_product
	var where := "house" if _player.indoors else ("mine" if _player.in_mine else "outside")
	return {
		"farm": _farm.get_save_data(),
		"animals": animals,
		"player": {"where": where, "x": _player.global_position.x, "y": _player.global_position.y},
	}


func _apply_save_data(data: Dictionary) -> void:
	_farm.load_save_data(data.get("farm", {}))
	var animals: Dictionary = data.get("animals", {})
	for animal: Animal in get_tree().get_nodes_in_group("animals"):
		if animals.has(String(animal.name)):
			animal.set_has_product(bool(animals[String(animal.name)]))
	var player: Dictionary = data.get("player", {})
	match player.get("where", "house"):
		"outside":
			_go_outside(Vector2(player.x, player.y))
		"mine":
			# Saved underground: you come to at the mouth of the mine.
			_go_outside(_cave.global_position + Vector2(0, 10))
