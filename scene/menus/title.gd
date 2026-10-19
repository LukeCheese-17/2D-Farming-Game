extends Control
## The home screen (UI-2): New Game, Continue, Options and Quit, over a dark
## field where something occasionally opens its eyes.

const MAIN_SCENE := "res://scene/main/main.tscn"
const EYES := preload("res://assets/Generated/eyes.png")

var _buttons := VBoxContainer.new()
var _options := OptionsPanel.new()
var _eyes := TextureRect.new()
var _eyes_time := 3.0


func _ready() -> void:
	# Nothing ticks behind the title screen.
	GameState.clock_running = false
	theme = UITheme.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var back := ColorRect.new()
	back.color = Color(0.03, 0.03, 0.045)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	# A tree line along the bottom.
	var trees := Polygon2D.new()
	var points := PackedVector2Array([Vector2(0, 360), Vector2(0, 280)])
	for i in 33:
		points.append(Vector2(i * 20, 262 + (i * 37 % 23) - (14 if i % 3 == 0 else 0)))
	points.append_array([Vector2(640, 280), Vector2(640, 360)])
	trees.polygon = points
	trees.color = Color(0.015, 0.02, 0.025)
	add_child(trees)
	_eyes.texture = EYES
	_eyes.modulate = Color(1, 0.9, 0.7, 0.0)
	add_child(_eyes)

	var title := Label.new()
	title.text = "Creepy Cozy Farm"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", UITheme.TEXT)
	title.add_theme_constant_override("outline_size", 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-160, 60)
	title.size = Vector2(320, 40)
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "You live alone. The phone still rings."
	subtitle.add_theme_color_override("font_color", UITheme.DIM_TEXT)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.position = Vector2(-160, 98)
	subtitle.size = Vector2(320, 16)
	add_child(subtitle)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-80, -20)
	panel.custom_minimum_size = Vector2(160, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_buttons.add_theme_constant_override("separation", 3)
	box.add_child(_buttons)
	for entry: Array in [["New Game", _new_game], ["Continue", _continue], ["Options", _show_options], ["Quit", get_tree().quit]]:
		var button := Button.new()
		button.text = entry[0]
		button.pressed.connect(entry[1])
		_buttons.add_child(button)
	var continue_button: Button = _buttons.get_child(1)
	continue_button.disabled = not SaveGame.exists()
	_options.closed.connect(_hide_options)
	_options.hide()
	box.add_child(_options)
	(continue_button if not continue_button.disabled else _buttons.get_child(0) as Button).grab_focus()

	var wind := AudioStreamPlayer.new()
	wind.stream = preload("res://assets/Generated/wind.wav")
	wind.volume_db = -16.0
	wind.autoplay = true
	add_child(wind)


func _process(delta: float) -> void:
	_eyes_time -= delta
	if _eyes_time > 0.0:
		return
	_eyes_time = randf_range(6.0, 14.0)
	_eyes.position = Vector2(randf_range(40, 600), randf_range(268, 300))
	var tween := create_tween()
	tween.tween_property(_eyes, "modulate:a", 0.8, 1.2)
	tween.tween_interval(randf_range(0.8, 2.0))
	tween.tween_property(_eyes, "modulate:a", 0.0, 0.15)


func _new_game() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _continue() -> void:
	if SaveGame.load_game():
		get_tree().change_scene_to_file(MAIN_SCENE)


func _show_options() -> void:
	_buttons.hide()
	_options.show()
	_options.focus()


func _hide_options() -> void:
	_options.hide()
	_buttons.show()
	(_buttons.get_child(2) as Button).grab_focus()
