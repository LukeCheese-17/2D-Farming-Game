extends StaticBody2D
## The landline. The man who sold the player the land calls on the first morning
## and pins the first main quest on the village board. After that the player calls
## him: he pays for finished main quests and takes supply orders (delivered by
## morning). Some nights it rings with no one on the line.

enum Ring { NONE, INTRO, SILENT }

## When his first call comes; if missed, he tries again the next morning.
const INTRO_CALL := 6 * 60 + 20
const INTRO_GIVE_UP := 21 * 60
const SILENT_CALL_CHANCE := 0.3
const SILENT_CALL_LENGTH := 20

## Questions the player can ask on the phone, each with a few vague answers (PHN-9).
## "Who are you?" must stay first: it leads to naming him.
const QUESTIONS := {
	"Who are you?": [
		["\"Who am I?\"", "\"Nobody you'd know. Call me whatever you like.\""],
		["\"Names don't matter much out here.\"", "\"Call me whatever you like. I'll answer.\""],
	],
	"What happened here?": [
		["\"Oh, people moved on. That happens.\"", "\"Don't go digging for reasons.\""],
		["\"Bad harvests. Bad winters. Bad luck.\"", "\"...Is the field still quiet at night?\""],
		["\"Nothing happened. That's the trouble.\""],
	],
	"Where did everyone go?": [
		["\"Away.\"", "\"Some further than others.\""],
		["\"They're around. Just not where you'd look.\""],
	],
	"Is someone out there?": [
		["(Silence. Then a soft laugh.)", "\"You're tired. Get some sleep.\""],
		["\"Out where?\"", "\"Lock the door if it helps you sleep.\""],
	],
	"Why did you sell the land?": [
		["\"It wanted someone new.\"", "\"I mean, I wanted someone new on it. Someone to look after it.\""],
		["\"I got old. It didn't.\""],
	],
}

const INTRO_LINES: Array[String] = [
	"So you're the one that bought this land.",
	"Well... it's pretty run down. You'll have to liven this place up a bit.",
	"I'll send you some quests on that board in the village center.",
	"Come back to me when you've got a quest done and I'll send you the cash.",
	"Also, call me if you ever need more supplies. I've got the basics, if you need.",
]

var _ring := Ring.NONE
var _intro_call_at := -1
var _silent_call_at := -1
var _ring_started := 0
var _ring_time := 0.0

@onready var _sprite: Sprite2D = $Phone
@onready var _marks: Sprite2D = $RingMarks
@onready var _sound: AudioStreamPlayer2D = $RingSound
@onready var _area: InteractArea = $InteractArea


func _ready() -> void:
	_area.interacted.connect(_on_interacted)
	GameState.day_changed.connect(func(_day: int) -> void: _schedule_calls())
	GameState.time_changed.connect(_on_time_changed)
	_schedule_calls()


func is_ringing() -> bool:
	return _ring != Ring.NONE


func _process(delta: float) -> void:
	if is_ringing():
		# Rattle while ringing: shake every 0.05 s, blink the marks every 0.25 s.
		_ring_time += delta
		_sprite.position.x = -0.5 + float(int(_ring_time / 0.05) % 2)
		_marks.visible = int(_ring_time / 0.25) % 2 == 0


func _schedule_calls() -> void:
	_intro_call_at = -1
	if not GameState.quests.main_posted:
		_intro_call_at = maxi(INTRO_CALL, GameState.minutes + 10)
	_silent_call_at = -1
	if GameState.day > 1 and randf() < SILENT_CALL_CHANCE:
		_silent_call_at = randi_range(22 * 60, 25 * 60)


func _on_time_changed(minutes: int) -> void:
	if _ring == Ring.INTRO and minutes >= INTRO_GIVE_UP:
		_stop_ringing()
	elif _ring == Ring.SILENT and minutes >= _ring_started + SILENT_CALL_LENGTH:
		_stop_ringing()
	elif _ring == Ring.NONE:
		if _intro_call_at >= 0 and minutes >= _intro_call_at and minutes < INTRO_GIVE_UP:
			_intro_call_at = -1
			_start_ringing(Ring.INTRO)
		elif _silent_call_at >= 0 and minutes >= _silent_call_at:
			_silent_call_at = -1
			_start_ringing(Ring.SILENT)


func _start_ringing(kind: Ring) -> void:
	_ring = kind
	_ring_started = GameState.minutes
	_area.prompt = "E: Answer the phone"
	_sound.play()
	UI.post_message("The phone is ringing.")


func _stop_ringing() -> void:
	_ring = Ring.NONE
	_area.prompt = "E: Use the phone"
	_sound.stop()
	_sprite.position.x = 0
	_marks.hide()


func _on_interacted() -> void:
	match _ring:
		Ring.INTRO:
			_stop_ringing()
			GameState.quests.post_main()
			UI.show_dialogue(INTRO_LINES)
		Ring.SILENT:
			_stop_ringing()
			UI.show_dialogue(["...", "(Someone is breathing on the other end.)", "(The line goes dead.)"])
		Ring.NONE:
			_call()


## The player calls him: he pays for a finished main quest, then the player can
## order supplies or ask him things (PHN-4/5/9).
func _call() -> void:
	var board := GameState.quests
	if not board.main_posted:
		UI.show_dialogue(["(Only a dial tone. You don't know anyone to call yet.)"])
		return
	if board.is_main_done():
		var quest := board.get_main()
		var reward := board.pay_main()
		GameState.add_money(reward)
		var lines: Array[String] = ["\"%s. I saw. Good work.\"" % quest.title, "\"%dg. It's already in your pocket. Don't ask how.\"" % reward]
		lines.append("\"There's a new note on the board.\"" if board.get_main() else "\"That's everything I needed. The place looks alive again.\"")
		if board.get_main() and board.get_main().unlocks_mine:
			lines.append("\"I had the boards taken off the old mine. Mind the dark.\"")
		UI.show_dialogue(lines)
		await UI.dialogue_finished
		UI.post_message("+%dg" % reward)
	var index := 0
	while true:
		var title := "On the line" if GameState.caller_name == "" else "On the line: %s" % GameState.caller_name
		UI.show_menu(title,["Order supplies", "Ask something", "Hang up"], "\"...Yes?\"", index)
		index = await UI.menu_finished
		match index:
			0:
				await _order_supplies()
			1:
				await _ask()
			_:
				return


func _order_supplies() -> void:
	var shop := GameState.SUPPLIES
	# Start on "Back" so mashing E through a call can't spend the player's money (UI-7).
	var index := shop.stock.size()
	while true:
		var options: Array[String] = []
		for item in shop.stock:
			options.append("%s - %dg" % [item.display_name, item.buy_price])
		options.append("Back")
		var ordered := 0
		for count: int in GameState.get_supply_order().values():
			ordered += count
		UI.show_menu("\"What do you need?\"", options, "You have %dg. Ordered: %d. The rest is in the village." % [GameState.money, ordered], index)
		index = await UI.menu_finished
		if index < 0 or index == options.size() - 1:
			return
		var item := shop.stock[index]
		if GameState.order_supply(item):
			UI.post_message("Ordered %s. It'll be by the door in the morning." % item.display_name)
		else:
			UI.post_message("Not enough money.")


## PHN-9: he never gives a straight answer. Asking who he is lets the player name him (PHN-10).
func _ask() -> void:
	var options: Array[String] = []
	options.assign(QUESTIONS.keys())
	options.append("Back")
	UI.show_menu("Ask %s..." % GameState.get_caller(), options, "")
	var index: int = await UI.menu_finished
	if index < 0 or index == options.size() - 1:
		return
	var answers: Array = QUESTIONS[options[index]]
	UI.show_dialogue(answers.pick_random())
	await UI.dialogue_finished
	if index == 0:
		await _name_caller()


func _name_caller() -> void:
	UI.ask_text("Call him...", GameState.caller_name)
	var text: String = await UI.text_finished
	if text == "":
		UI.show_dialogue(["\"No? Suit yourself.\""])
	else:
		GameState.caller_name = text
		UI.show_dialogue(["\"%s.\"" % text, "(A long pause. You think you hear him smile.)", "\"That'll do.\""])
	await UI.dialogue_finished