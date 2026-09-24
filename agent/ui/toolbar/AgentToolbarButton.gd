class_name AgentToolbarButton
extends Object

## Shared styling for compact Code Agent toolbar buttons (Log, Markdown, …).


static func style(button: Button, tooltip: String, corner_radius: int = 6) -> void:
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(28, 28)
	button.flat = false
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", AgentColors.toolbar_muted)
	button.add_theme_color_override("font_hover_color", AgentColors.toolbar_title)
	button.add_theme_color_override("font_pressed_color", AgentColors.theme_accent_solid())

	var radius: int = corner_radius
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = AgentColors.toolbar_button
	normal.border_color = AgentColors.toolbar_border
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(radius)
	normal.content_margin_left = Margin.ma_2
	normal.content_margin_right = Margin.ma_2
	normal.content_margin_top = Margin.ma_1
	normal.content_margin_bottom = Margin.ma_1

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = AgentColors.sidebar_row_hover
	hover.border_color = AgentColors.toolbar_border

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = AgentColors.theme_selection_bg()
	pressed.border_color = AgentColors.toolbar_border

	var hover_pressed: StyleBoxFlat = pressed.duplicate() as StyleBoxFlat
	hover_pressed.bg_color = AgentColors.theme_selection_bg()
	if ThemeColor.is_dark_theme():
		hover_pressed.bg_color = hover_pressed.bg_color.lightened(0.06)
	else:
		hover_pressed.bg_color = hover_pressed.bg_color.darkened(0.04)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", hover_pressed)
	button.add_theme_stylebox_override("focus", hover.duplicate())
	button.add_theme_stylebox_override("disabled", normal.duplicate())
	pass
