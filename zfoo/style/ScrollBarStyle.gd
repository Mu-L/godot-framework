class_name ScrollBarStyle
extends Object

## Shared scrollbar palette for popup, transcript and sidebar surfaces.
## Keeps the engine's geometry while replacing only state fill colors.
static func apply(bar: ScrollBar) -> void:
	var scroll := bar.get_theme_stylebox("scroll").duplicate() as StyleBoxFlat
	scroll.bg_color = Color(0, 0, 0, 0)
	bar.add_theme_stylebox_override("scroll", scroll)
	var scroll_focus := bar.get_theme_stylebox("scroll_focus").duplicate() as StyleBoxFlat
	scroll_focus.bg_color = Color(0, 0, 0, 0)
	bar.add_theme_stylebox_override("scroll_focus", scroll_focus)
	var grabber := bar.get_theme_stylebox("grabber").duplicate() as StyleBoxFlat
	grabber.bg_color = ColorCard.body_color
	bar.add_theme_stylebox_override("grabber", grabber)
	var grabber_highlight := bar.get_theme_stylebox("grabber_highlight").duplicate() as StyleBoxFlat
	grabber_highlight.bg_color = ColorCard.accent_color
	bar.add_theme_stylebox_override("grabber_highlight", grabber_highlight)
	var grabber_pressed := bar.get_theme_stylebox("grabber_pressed").duplicate() as StyleBoxFlat
	grabber_pressed.bg_color = ColorCard.accent_color
	bar.add_theme_stylebox_override("grabber_pressed", grabber_pressed)
	pass
