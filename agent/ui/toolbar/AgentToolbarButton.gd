class_name AgentToolbarButton
extends Object

## Shared styling for compact Code Agent toolbar buttons (Log, Markdown, …).


static func style(button: Button, tooltip: String) -> void:
	button.tooltip_text = tooltip
	button.custom_minimum_size = ControlSize.square(ControlSize.sm)
	button.flat = false
	button.add_theme_font_size_override("font_size", TextSize.label_small_size)
	ButtonStyle.apply_font_colors(button, ColorBase.muted, ColorBase.text, ThemeColor.theme_color_full_alpha())

	var normal := BoxStyle.make(ColorBase.control_surface, ControlSize.radius_md, Margin.ma_2, Margin.ma_1, ColorBase.subtle_border, 1)
	var hover := BoxStyle.with_bg(normal, ColorBase.hover_surface)
	var pressed := BoxStyle.with_bg(normal, ColorBase.selection_surface)
	var hover_pressed := BoxStyle.with_bg(pressed, ButtonStyle.hover_color(pressed.bg_color, 0.06))
	ButtonStyle.apply_states(button, normal, hover, pressed, null, hover_pressed)
	pass


static func style_round(button: Button, tooltip: String) -> void:
	button.tooltip_text = tooltip
	button.custom_minimum_size = ControlSize.square(ControlSize.sm)
	button.flat = false
	button.add_theme_font_size_override("font_size", TextSize.label_small_size)
	ButtonStyle.apply_font_colors(button, ColorBase.muted, ColorBase.text, ThemeColor.theme_color_full_alpha())

	var normal := BoxStyle.make(ColorBase.control_surface, ControlSize.sm / 2, Margin.ma_2, Margin.ma_1, ColorBase.subtle_border, 1)
	var hover := BoxStyle.with_bg(normal, ColorBase.hover_surface)
	var pressed := BoxStyle.with_bg(normal, ColorBase.selection_surface)
	var hover_pressed := BoxStyle.with_bg(pressed, ButtonStyle.hover_color(pressed.bg_color, 0.06))
	ButtonStyle.apply_states(button, normal, hover, pressed, null, hover_pressed)
	pass
