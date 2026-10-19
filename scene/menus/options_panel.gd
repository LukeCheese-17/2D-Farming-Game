class_name OptionsPanel
extends VBoxContainer
## Volume, fullscreen and the list of controls (UI-4). Used by the title screen and the pause menu.

signal closed

const CONTROLS := [
	["WASD / arrows", "Walk"],
	["Space", "Use the held item"],
	["E", "Talk, open, pick"],
	["1-0 / mouse wheel", "Choose hotbar slot"],
	["Tab / I", "Backpack"],
	["Esc", "Pause"],
]

var _back := Button.new()


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	var title := Label.new()
	title.text = "Options"
	title.add_theme_color_override("font_color", UITheme.ACCENT)
	add_child(title)

	var volume_row := HBoxContainer.new()
	var volume_label := Label.new()
	volume_label.text = "Volume"
	volume_label.custom_minimum_size.x = 70
	volume_row.add_child(volume_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = UI.volume
	slider.custom_minimum_size = Vector2(120, 12)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(value: float) -> void:
		UI.volume = value
		UI.apply_options()
		UI.save_options())
	volume_row.add_child(slider)
	add_child(volume_row)

	var fullscreen := CheckButton.new()
	fullscreen.text = "Fullscreen"
	fullscreen.button_pressed = UI.fullscreen
	fullscreen.toggled.connect(func(on: bool) -> void:
		UI.fullscreen = on
		UI.apply_options()
		UI.save_options())
	add_child(fullscreen)

	var controls := Label.new()
	controls.add_theme_font_size_override("font_size", 8)
	controls.add_theme_color_override("font_color", UITheme.DIM_TEXT)
	var lines: PackedStringArray = ["Controls:"]
	for c: Array in CONTROLS:
		lines.append("  %s - %s" % c)
	controls.text = "\n".join(lines)
	add_child(controls)

	_back.text = "Back"
	_back.pressed.connect(closed.emit)
	add_child(_back)
	slider.focus_neighbor_bottom = fullscreen.get_path()


func focus() -> void:
	_back.grab_focus()
