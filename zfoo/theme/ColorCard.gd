class_name ColorCard
extends Object

## Card palette derived from `ThemeColor.theme_color`, so floating cards and window bodies
## (`DesktopToast`, `Alert`, `PopupWindow`) pick up the accent the user chose while title/body
## contrast stays stable in either theme.
## Usage: `ThemeColorCard.background_color` (card surface), `inset_color` (a window's body, one
## step below it), `title_color` / `body_color` (text), `accent_color` / `selection_color` (caret,
## selection, highlight). `ThemeColor` calls `refresh()` whenever the accent color or the dark/light
## theme changes; until that first call these hold their neutral fallbacks.

# Hue is always the accent hue; these scale its saturation and set the brightness per theme.
const SURFACE_SATURATION_DARK := 0.30
const SURFACE_SATURATION_LIGHT := 0.12
const SURFACE_VALUE_DARK := 0.15
const SURFACE_VALUE_LIGHT := 0.97
# One step below the card surface, so body text reads as sitting in a well rather than in a second card.
const INSET_SATURATION_DARK := 0.24
const INSET_SATURATION_LIGHT := 0.08
const INSET_VALUE_DARK := 0.10
const INSET_VALUE_LIGHT := 0.93
const TITLE_SATURATION_DARK := 0.12
const TITLE_SATURATION_LIGHT := 0.20
const TITLE_VALUE_DARK := 0.94
const TITLE_VALUE_LIGHT := 0.16
const BODY_SATURATION_DARK := 0.20
const BODY_SATURATION_LIGHT := 0.28
const BODY_VALUE_DARK := 0.68
const BODY_VALUE_LIGHT := 0.42
## How much accent a text selection carries over the surface it sits in.
const SELECTION_MIX := 0.30

## Card surface: the background of a floating card or window (`Alert`, `DesktopToast`, `PopupWindow`).
static var background_color: Color = ColorBase.DARK_SURFACE
## Inset surface one step below the card: a window's body, so its text reads as sitting in a well
## rather than in a second card.
static var inset_color: Color = Color(0.09, 0.10, 0.12)
## Primary text: near-white on the dark surface, near-black on the light one.
static var title_color: Color = ColorBase.DARK_TEXT
## Secondary text: captions, muted labels, and the resting scrollbar grabber.
static var body_color: Color = ColorBase.DARK_MUTED
## The accent at full alpha: caret, scrollbar hover / press and other highlights.
static var accent_color: Color = Color(0.0, 0.84, 0.68)
## [member inset_color] mixed with [member accent_color]: the background of selected text.
static var selection_color: Color = Color(0.12, 0.29, 0.25)


## Recompute every color from the current theme color and dark/light theme.
static func refresh() -> void:
	var dark := ThemeColor.is_dark_theme()
	background_color = derive(SURFACE_SATURATION_DARK if dark else SURFACE_SATURATION_LIGHT, SURFACE_VALUE_DARK if dark else SURFACE_VALUE_LIGHT)
	inset_color = derive(INSET_SATURATION_DARK if dark else INSET_SATURATION_LIGHT, INSET_VALUE_DARK if dark else INSET_VALUE_LIGHT)
	title_color = derive(TITLE_SATURATION_DARK if dark else TITLE_SATURATION_LIGHT, TITLE_VALUE_DARK if dark else TITLE_VALUE_LIGHT)
	body_color = derive(BODY_SATURATION_DARK if dark else BODY_SATURATION_LIGHT, BODY_VALUE_DARK if dark else BODY_VALUE_LIGHT)
	# Theme colors are stored translucent — they also tint the window — while a caret or a highlight
	# wants the solid hue.
	accent_color = Color(ThemeColor.theme_color, 1.0)
	selection_color = inset_color.lerp(accent_color, SELECTION_MIX)
	pass


## Accent hue at the given saturation factor and brightness. Fixed brightness per theme is what
## keeps the contrast ratio the same for every accent color.
static func derive(saturation: float, value: float) -> Color:
	var accent := ThemeColor.theme_color
	return Color.from_hsv(accent.h, clampf(accent.s * saturation, 0.0, 1.0), value, 1.0)
