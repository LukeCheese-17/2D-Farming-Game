class_name UITheme
## The one look shared by the HUD, dialogue, menus, the title screen and the pause
## menu (UI-1): dark, slightly warm panels with a thin worn border.

const FONT_SIZE := 10
const TEXT := Color(0.9, 0.86, 0.8)
const DIM_TEXT := Color(0.62, 0.58, 0.55)
const ACCENT := Color(0.85, 0.72, 0.5)
const PANEL := Color(0.05, 0.04, 0.06, 0.88)
const BORDER := Color(0.48, 0.42, 0.4)


static func make() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = FONT_SIZE
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_outline_color", "Label", Color.BLACK)
	theme.set_constant("outline_size", "Label", 3)
	theme.set_stylebox("panel", "PanelContainer", panel())
	theme.set_stylebox("panel", "Panel", panel())

	var normal := _box(Color(0.1, 0.08, 0.1, 0.9), BORDER.darkened(0.3))
	var hover := _box(Color(0.18, 0.14, 0.14, 0.95), ACCENT)
	var pressed := _box(Color(0.25, 0.18, 0.15, 1.0), ACCENT)
	var disabled := _box(Color(0.06, 0.05, 0.06, 0.7), BORDER.darkened(0.5))
	for type in ["Button", "CheckButton"]:
		theme.set_stylebox("normal", type, normal)
		theme.set_stylebox("hover", type, hover)
		theme.set_stylebox("pressed", type, pressed)
		theme.set_stylebox("focus", type, hover)
		theme.set_stylebox("disabled", type, disabled)
		theme.set_color("font_color", type, TEXT)
		theme.set_color("font_hover_color", type, ACCENT)
		theme.set_color("font_focus_color", type, ACCENT)
		theme.set_color("font_pressed_color", type, ACCENT)
		theme.set_color("font_disabled_color", type, DIM_TEXT.darkened(0.3))
	var track := _box(Color(0.12, 0.1, 0.11), BORDER.darkened(0.3))
	track.set_content_margin_all(2)
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", _box(ACCENT.darkened(0.4), ACCENT.darkened(0.4)))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _box(ACCENT.darkened(0.2), ACCENT))
	return theme


static func panel(alpha := PANEL.a) -> StyleBoxFlat:
	var style := _box(Color(PANEL, alpha), BORDER)
	style.set_content_margin_all(6)
	return style


static func _box(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(3)
	return style
