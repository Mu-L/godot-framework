class_name AgentToolbarButton
extends Object

## Shared styling for compact Code Agent toolbar buttons (Log, Markdown, …).


static func style(button: Button, tooltip: String) -> void:
	button.tooltip_text = tooltip
	button.custom_minimum_size = ControlSize.square(ControlSize.sm)
	button.flat = false
	button.add_theme_font_size_override("font_size", TextSize.label_small_size)
	ButtonStyle.apply_font_colors(button, ColorBase.secondary_text, ColorBase.primary_text, ThemeColor.accent_theme_color())

	var normal := StyleBoxHelper.create_style_box_flat(ColorBase.control_surface, ControlSize.radius_md, Margin.ma_2, Margin.ma_1, ColorBase.subtle_border, ControlSize.border_xs)
	ButtonStyle.apply(button, normal,
		ButtonStyle.filled(normal, ColorBase.hover_surface),
		ButtonStyle.filled(normal, ThemeColor.selected_surface),
		null, ButtonStyle.filled(normal, ButtonStyle.hover_color(ThemeColor.selected_surface, 0.06)))
	pass


static func style_round(button: Button, tooltip: String) -> void:
	button.tooltip_text = tooltip
	button.custom_minimum_size = ControlSize.square(ControlSize.sm)
	button.flat = false
	button.add_theme_font_size_override("font_size", TextSize.label_small_size)
	ButtonStyle.apply_font_colors(button, ColorBase.secondary_text, ColorBase.primary_text, ThemeColor.accent_theme_color())

	var normal := StyleBoxHelper.create_style_box_flat(ColorBase.control_surface, ControlSize.sm / 2, Margin.ma_2, Margin.ma_1, ColorBase.subtle_border, ControlSize.border_xs)
	ButtonStyle.apply(button, normal,
		ButtonStyle.filled(normal, ColorBase.hover_surface),
		ButtonStyle.filled(normal, ThemeColor.selected_surface),
		null, ButtonStyle.filled(normal, ButtonStyle.hover_color(ThemeColor.selected_surface, 0.06)))
	pass
