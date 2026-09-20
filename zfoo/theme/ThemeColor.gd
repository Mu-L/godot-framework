class_name ThemeColor
extends RefCounted

const SETTING_KEY := "dark_theme"
const THEME_COLOR_SETTING_KEY := "theme_color"
const DEFAULT_THEME_COLOR := Color(0.0, 0.84, 0.68, 0.58)

enum ColorScheme {
	DARK,
	LIGHT,
}

static var current_scheme: ColorScheme = ColorScheme.DARK
static var theme_color: Color = DEFAULT_THEME_COLOR


static func is_dark(default_value: bool = true) -> bool:
	return Setting.get_bool(SETTING_KEY, default_value)


static func save_dark(use_dark: bool) -> void:
	Setting.set_bool(SETTING_KEY, use_dark)
	Setting.save()
	pass


static func load_color(default_color: Color = DEFAULT_THEME_COLOR) -> Color:
	var saved := Setting.get_string(THEME_COLOR_SETTING_KEY, "")
	if saved.is_empty():
		return default_color
	return Color.from_string(saved, default_color)


static func save_color(color: Color) -> void:
	Setting.set_string(THEME_COLOR_SETTING_KEY, color.to_html(true))
	Setting.save()
	pass
