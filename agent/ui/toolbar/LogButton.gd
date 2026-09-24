class_name LogButton
extends RefCounted

## Toolbar button that opens the framework system log window.

## Tailed lines, and window size as percent of screen (1–100).
const LINE_COUNT := 128
const WIDTH_PERCENT := 70
const HEIGHT_PERCENT := 80

var button: Button


func setup(p_button: Button) -> void:
	button = p_button
	button.pressed.connect(on_pressed)
	gdf.events.theme_changed.connect(apply_theme)
	gdf.events.theme_color_changed.connect(apply_theme)
	gdf.events.locale_changed.connect(apply_theme)
	apply_theme()
	pass


func apply_theme() -> void:
	AgentToolbarButton.style(button, I18n.t("agent.toolbar.view_log"))
	button.text = I18n.t("agent.toolbar.log")
	pass


func on_pressed() -> void:
	LogWindow.show_log_window(LINE_COUNT, WIDTH_PERCENT, HEIGHT_PERCENT)
	pass
