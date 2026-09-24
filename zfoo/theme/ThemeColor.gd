class_name ThemeColor
extends Object

const THEME_SETTING_KEY := "theme"
const THEME_COLOR_SETTING_KEY := "theme_color"
const DEFAULT_THEME_COLOR := Color(0.0, 0.84, 0.68, 0.58)

enum ThemeEnum {
	DARK,
	LIGHT,
}

static var current_theme: ThemeEnum = ThemeEnum.DARK
static var theme_color: Color = DEFAULT_THEME_COLOR

static func _static_init() -> void:
	load_theme()
	load_theme_color()
	pass

static func load_theme() -> ThemeEnum:
	var use_dark := Setting.get_bool(THEME_SETTING_KEY, true)
	current_theme = ThemeEnum.DARK if use_dark else ThemeEnum.LIGHT
	refresh_derived_colors()
	return current_theme


static func set_theme(_theme: ThemeEnum) -> void:
	current_theme = _theme
	Setting.set_bool(THEME_SETTING_KEY, current_theme == ThemeEnum.DARK)
	Setting.save()
	refresh_derived_colors()
	gdf.events.theme_changed.emit()
	pass


## Everything that paints itself from the accent: the card surfaces. The markdown palette
## switches between its own constant dark/light sets.
static func refresh_derived_colors() -> void:
	ThemeColorCard.refresh()
	ThemeColorMarkdown.refresh()
	ThemeColorFile.refresh()
	pass


static func is_dark_theme() -> bool:
	return current_theme == ThemeColor.ThemeEnum.DARK

static func is_light_theme() -> bool:
	return current_theme == ThemeColor.ThemeEnum.LIGHT
# ----------------------------------------------------------------------------------------------------------------------
static func load_theme_color() -> Color:
	var saved := Setting.get_string(THEME_COLOR_SETTING_KEY)
	theme_color = DEFAULT_THEME_COLOR if saved.is_empty() else Color.from_string(saved, DEFAULT_THEME_COLOR)
	refresh_derived_colors()
	return theme_color


static func set_theme_color(color: Color) -> void:
	theme_color = color
	Setting.set_string(THEME_COLOR_SETTING_KEY, theme_color.to_html(true))
	Setting.save()
	refresh_derived_colors()
	gdf.events.theme_color_changed.emit()
	pass
