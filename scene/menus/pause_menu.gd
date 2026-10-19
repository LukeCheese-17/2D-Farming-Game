extends CanvasLayer
## Esc pauses the game (UI-3): Resume, Options, Save, Quit to the title screen.

const TITLE_SCENE := "res://scene/menus/title.tscn"

## The main scene, which knows how to save the world.
@export var main: Node

var _dim := ColorRect.new()
var _panel := PanelContainer.new()
var _buttons := VBoxContainer.new()
var _options := OptionsPanel.new()
var _status := Label.new()


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.make()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_dim)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(180, 0)
	root.add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	box.add_child(_buttons)
	_buttons.add_theme_constant_override("separation", 3)
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UITheme.ACCENT)
	_buttons.add_child(title)
	for entry: Array in [["Resume", resume], ["Options", _show_options], ["Save", _save], ["Quit to title", _quit]]:
		var button := Button.new()
		button.text = entry[0]
		button.pressed.connect(entry[1])
		_buttons.add_child(button)
	_status.add_theme_font_size_override("font_size", 8)
	_status.add_theme_color_override("font_color", UITheme.DIM_TEXT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_buttons.add_child(_status)
	_options.closed.connect(_hide_options)
	_options.hide()
	box.add_child(_options)
	_set_open(false)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible_menu():
		get_viewport().set_input_as_handled()
		if _options.visible:
			_hide_options()
		else:
			resume()
	elif not UI.is_blocking() and not UI.fishing:
		get_viewport().set_input_as_handled()
		_set_open(true)


func visible_menu() -> bool:
	return _panel.visible


func resume() -> void:
	_set_open(false)


func _set_open(open: bool) -> void:
	_dim.visible = open
	_panel.visible = open
	get_tree().paused = open
	_status.text = ""
	if open:
		_hide_options()
		await get_tree().process_frame
		_panel.position = ((_dim.size - _panel.size) / 2.0).round()
		(_buttons.get_child(1) as Button).grab_focus()


func _show_options() -> void:
	_buttons.hide()
	_options.show()
	_options.focus()


func _hide_options() -> void:
	_options.hide()
	_buttons.show()
	(_buttons.get_child(2) as Button).grab_focus()


func _save() -> void:
	_status.text = "Saved." if SaveGame.save(main) else "Couldn't save."


func _quit() -> void:
	get_tree().paused = false
	UI.reset()
	get_tree().change_scene_to_file(TITLE_SCENE)
