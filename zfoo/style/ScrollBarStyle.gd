class_name ScrollBarStyle
extends Object

const THICKNESS: float = 6.0

## Shared thin scrollbar for popup, transcript and sidebar surfaces.
## Keeps the engine's shape while replacing its thickness and state fill colors.
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
	grabber_highlight.bg_color = ThemeColor.theme_color_full_alpha()
	bar.add_theme_stylebox_override("grabber_highlight", grabber_highlight)
	var grabber_pressed := bar.get_theme_stylebox("grabber_pressed").duplicate() as StyleBoxFlat
	grabber_pressed.bg_color = ThemeColor.theme_color_full_alpha()
	bar.add_theme_stylebox_override("grabber_pressed", grabber_pressed)
	var half_thickness := THICKNESS * 0.5
	if bar is VScrollBar:
		scroll.content_margin_left = half_thickness
		scroll.content_margin_right = half_thickness
		scroll_focus.content_margin_left = half_thickness
		scroll_focus.content_margin_right = half_thickness
		grabber.content_margin_left = half_thickness
		grabber.content_margin_right = half_thickness
		grabber_highlight.content_margin_left = half_thickness
		grabber_highlight.content_margin_right = half_thickness
		grabber_pressed.content_margin_left = half_thickness
		grabber_pressed.content_margin_right = half_thickness
	else:
		scroll.content_margin_top = half_thickness
		scroll.content_margin_bottom = half_thickness
		scroll_focus.content_margin_top = half_thickness
		scroll_focus.content_margin_bottom = half_thickness
		grabber.content_margin_top = half_thickness
		grabber.content_margin_bottom = half_thickness
		grabber_highlight.content_margin_top = half_thickness
		grabber_highlight.content_margin_bottom = half_thickness
		grabber_pressed.content_margin_top = half_thickness
		grabber_pressed.content_margin_bottom = half_thickness
	pass
