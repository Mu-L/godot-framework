class_name AgentToolbarButton
extends Object

## Shared styling for compact Code Agent toolbar buttons (Log, Markdown, …).


static func style(button: Button, tooltip: String, corner_radius: int = 6) -> void:
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(28, 28)
	button.flat = false
	button.add_theme_font_size_override("font_size", TextStyle.label_small_size)
	ButtonStyle.apply_font_colors(button, AgentColors.toolbar_muted, AgentColors.toolbar_title, AgentColors.theme_accent_solid())

	var normal := BoxStyle.make(AgentColors.toolbar_button, corner_radius, Margin.ma_2, Margin.ma_1, AgentColors.toolbar_border, 1)
	var hover := BoxStyle.with_bg(normal, AgentColors.sidebar_row_hover)
	var pressed := BoxStyle.with_bg(normal, AgentColors.theme_selection_bg())
	var hover_pressed := BoxStyle.with_bg(pressed, ButtonStyle.hover_color(pressed.bg_color, 0.06))
	ButtonStyle.apply_states(button, normal, hover, pressed, null, hover_pressed)
	pass
