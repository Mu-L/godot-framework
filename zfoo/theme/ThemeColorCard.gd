class_name ThemeColorCard
extends Object

## Card palette derived from `ThemeColor.theme_color`, so floating cards (`DesktopToast`, dialogs)
## pick up the accent the user chose while title/body contrast stays stable in either theme.
## Usage: `ThemeColorCard.background_color` / `title_color` / `body_color`.
## `ThemeColor` calls `refresh()` whenever the accent color or the dark/light theme changes.

# Hue is always the accent hue; these scale its saturation and set the brightness per theme.
const SURFACE_SATURATION_DARK := 0.30
const SURFACE_SATURATION_LIGHT := 0.12
const SURFACE_VALUE_DARK := 0.15
const SURFACE_VALUE_LIGHT := 0.97
const TITLE_SATURATION_DARK := 0.12
const TITLE_SATURATION_LIGHT := 0.20
const TITLE_VALUE_DARK := 0.94
const TITLE_VALUE_LIGHT := 0.16
const BODY_SATURATION_DARK := 0.20
const BODY_SATURATION_LIGHT := 0.28
const BODY_VALUE_DARK := 0.68
const BODY_VALUE_LIGHT := 0.42

## Neutral fallbacks until `refresh()` runs for the first time (see `ThemeColor`).
static var background_color: Color = Color(0.12, 0.13, 0.16)
static var title_color: Color = Color(0.90, 0.91, 0.93)
static var body_color: Color = Color(0.55, 0.57, 0.62)


## Recompute the three colors from the current theme color and dark/light theme.
static func refresh() -> void:
	var dark := ThemeColor.is_dark_theme()
	background_color = derive(SURFACE_SATURATION_DARK if dark else SURFACE_SATURATION_LIGHT, SURFACE_VALUE_DARK if dark else SURFACE_VALUE_LIGHT)
	title_color = derive(TITLE_SATURATION_DARK if dark else TITLE_SATURATION_LIGHT, TITLE_VALUE_DARK if dark else TITLE_VALUE_LIGHT)
	body_color = derive(BODY_SATURATION_DARK if dark else BODY_SATURATION_LIGHT, BODY_VALUE_DARK if dark else BODY_VALUE_LIGHT)
	pass


## Accent hue at the given saturation factor and brightness. Fixed brightness per theme is what
## keeps the contrast ratio the same for every accent color.
static func derive(saturation: float, value: float) -> Color:
	var accent := ThemeColor.theme_color
	return Color.from_hsv(accent.h, clampf(accent.s * saturation, 0.0, 1.0), value, 1.0)
