class_name Colors
extends Object

## Theme-aware semantic colors. Dark variants are brighter for dark surfaces; light variants are
## darker so text, borders and status marks retain contrast on pale surfaces.
const DARK_ERROR := Color(0.85, 0.30, 0.30)
const DARK_INFO := Color(0.35, 0.65, 0.95)
const DARK_WARNING := Color(1.00, 0.65, 0.30)
const DARK_SUCCESS := Color(0.30, 0.78, 0.45)
const DARK_TEAL := Color(0.15, 0.78, 0.85)

const LIGHT_ERROR := Color(0.86, 0.15, 0.15)
const LIGHT_INFO := Color(0.15, 0.39, 0.92)
const LIGHT_WARNING := Color(0.85, 0.36, 0.05)
const LIGHT_SUCCESS := Color(0.09, 0.64, 0.29)
const LIGHT_TEAL := Color(0.00, 0.48, 0.43)

static var error: Color = DARK_ERROR
static var info: Color = DARK_INFO
static var warning: Color = DARK_WARNING
static var success: Color = DARK_SUCCESS
static var teal: Color = DARK_TEAL


## Select semantic colors with suitable contrast for the current dark or light theme.
static func refresh() -> void:
	var dark := ThemeColor.is_dark_theme()
	error = DARK_ERROR if dark else LIGHT_ERROR
	info = DARK_INFO if dark else LIGHT_INFO
	warning = DARK_WARNING if dark else LIGHT_WARNING
	success = DARK_SUCCESS if dark else LIGHT_SUCCESS
	teal = DARK_TEAL if dark else LIGHT_TEAL
	pass
