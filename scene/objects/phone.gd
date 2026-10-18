extends StaticBody2D
## The landline. The man calls with jobs (see JobData) when the player has none.
## Some nights it rings with no one on the line. When it isn't ringing, the player
## can use it to order seeds.

enum Ring { NONE, JOB, SILENT }

## Earliest and latest time (minutes) a job call can start; day 1 calls soon after waking.
const JOB_CALL_EARLIEST := 7 * 60
const JOB_CALL_LATEST := 10 * 60
const FIRST_DAY_CALL := 6 * 60 + 20
## An unanswered job call stops ringing at this time and tries again tomorrow.
const JOB_CALL_GIVE_UP := 21 * 60
const SILENT_CALL_CHANCE := 0.3
const SILENT_CALL_LENGTH := 20

var _ring := Ring.NONE
var _job_call_at := -1
var _silent_call_at := -1
var _ring_started := 0

@onready var _sprite: Sprite2D = $Phone
@onready var _marks: Sprite2D = $RingMarks
@onready var _sound: AudioStreamPlayer2D = $RingSound
@onready var _area: InteractArea = $InteractArea


func _ready() -> void:
	_area.interacted.connect(_on_interacted)
	GameState.day_changed.connect(func(_day: int) -> void: _schedule_calls())
	GameState.time_changed.connect(_on_time_changed)
	GameState.job_changed.connect(_schedule_job_call)
	_schedule_calls()


func is_ringing() -> bool:
	return _ring != Ring.NONE


func _process(_delta: float) -> void:
	if is_ringing():
		# Rattle while ringing.
		_sprite.position.x = -0.5 + float(Engine.get_process_frames() / 3 % 2)
		_marks.visible = Engine.get_process_frames() / 15 % 2 == 0


func _schedule_calls() -> void:
	_job_call_at = -1
	_schedule_job_call()
	_silent_call_at = -1
	if GameState.day > 1 and randf() < SILENT_CALL_CHANCE:
		_silent_call_at = randi_range(22 * 60, 25 * 60)


func _schedule_job_call() -> void:
	if GameState.active_job or _ring == Ring.JOB:
		_job_call_at = -1
	elif _job_call_at < 0:
		if GameState.day == 1:
			_job_call_at = FIRST_DAY_CALL
		else:
			_job_call_at = maxi(randi_range(JOB_CALL_EARLIEST, JOB_CALL_LATEST), GameState.minutes + 10)


func _on_time_changed(minutes: int) -> void:
	if _ring == Ring.JOB and minutes >= JOB_CALL_GIVE_UP:
		_stop_ringing()
		_job_call_at = -1
	elif _ring == Ring.SILENT and minutes >= _ring_started + SILENT_CALL_LENGTH:
		_stop_ringing()
	elif _ring == Ring.NONE:
		if _job_call_at >= 0 and minutes >= _job_call_at and minutes < JOB_CALL_GIVE_UP:
			_job_call_at = -1
			_start_ringing(Ring.JOB)
		elif _silent_call_at >= 0 and minutes >= _silent_call_at:
			_silent_call_at = -1
			_start_ringing(Ring.SILENT)


func _start_ringing(kind: Ring) -> void:
	_ring = kind
	_ring_started = GameState.minutes
	_area.prompt = "E: Answer the phone"
	_sound.play()
	GameState.post_message("The phone is ringing.")


func _stop_ringing() -> void:
	_ring = Ring.NONE
	_area.prompt = "E: Use the phone"
	_sound.stop()
	_sprite.position.x = 0
	_marks.hide()


func _on_interacted() -> void:
	match _ring:
		Ring.JOB:
			_stop_ringing()
			_give_job()
		Ring.SILENT:
			_stop_ringing()
			GameState.show_dialogue(["...", "(Someone is breathing on the other end.)", "(The line goes dead.)"])
		Ring.NONE:
			_offer_seeds()


func _give_job() -> void:
	var lines: Array[String] = []
	match GameState.last_job_result:
		"done":
			lines.append("You did what I asked. Good.")
		"failed":
			lines.append("You let me down. Don't do it again.")
	GameState.last_job_result = ""
	var job := GameState.get_next_job()
	GameState.accept_job(job)
	lines.append_array(job.get_lines(GameState.job_deadline))
	GameState.show_dialogue(lines)


func _offer_seeds() -> void:
	var seed := GameState.get_selected_crop().seed
	GameState.show_dialogue(
		["A seed catalogue is taped to the wall by the phone.",
		"%d %s, %dg. Delivered by morning." % [GameState.SEED_ORDER_AMOUNT, seed.display_name, GameState.SEED_ORDER_PRICE]],
		["Order", "Hang up"])
	var choice: int = await GameState.dialogue_finished
	if choice != 0:
		return
	if GameState.order_seeds():
		GameState.post_message("Ordered. -%dg" % GameState.SEED_ORDER_PRICE)
	else:
		GameState.post_message("Not enough money.")
