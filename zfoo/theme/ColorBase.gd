class_name ColorBase
extends Object

## Shared foundation for neutral and semantic colors used by framework palettes and application
## themes. Component and business-specific colors belong in their own palette.
const DARK_BACKGROUND := Color(0.07, 0.08, 0.10)
const DARK_RECESSED_SURFACE := Color(0.06, 0.07, 0.09)
const DARK_INSET_SURFACE := Color(0.10, 0.11, 0.13)
const DARK_CONTROL_SURFACE := Color(0.11, 0.12, 0.15)
const DARK_SURFACE := Color(0.12, 0.13, 0.16)
const DARK_HOVER_SURFACE := DARK_SURFACE
const DARK_ELEVATED_SURFACE := Color(0.14, 0.15, 0.18)
const DARK_BORDER := Color(0.22, 0.24, 0.28)
const DARK_MEDIUM_BORDER := Color(0.18, 0.20, 0.24)
const DARK_SUBTLE_BORDER := Color(0.16, 0.18, 0.22)
const DARK_TEXT := Color(0.90, 0.91, 0.93)
const DARK_MUTED := Color(0.55, 0.57, 0.62)

const LIGHT_BACKGROUND := Color(0.98, 0.98, 0.98)
const LIGHT_RECESSED_SURFACE := Color(0.95, 0.95, 0.96)
const LIGHT_INSET_SURFACE := LIGHT_RECESSED_SURFACE
const LIGHT_CONTROL_SURFACE := Color(0.96, 0.96, 0.96)
const LIGHT_SURFACE := Color(1.00, 1.00, 1.00)
const LIGHT_HOVER_SURFACE := Color(0.93, 0.93, 0.94)
const LIGHT_ELEVATED_SURFACE := LIGHT_SURFACE
const LIGHT_BORDER := Color(0.89, 0.89, 0.91)
const LIGHT_MEDIUM_BORDER := LIGHT_BORDER
const LIGHT_SUBTLE_BORDER := LIGHT_BORDER
const LIGHT_TEXT := Color(0.09, 0.09, 0.11)
const LIGHT_MUTED := Color(0.44, 0.44, 0.48)

## Semantic colors are brighter on dark surfaces and darker on pale surfaces.
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
const DARK_PURPLE := Color(0.72, 0.58, 0.88)
const LIGHT_PURPLE := Color(0.49, 0.23, 0.93)

## Semantic surfaces keep status/category fills readable without using strong text colors as fills.
const DARK_STRONG_INFO_SURFACE := Color(0.16, 0.22, 0.32)
const DARK_INFO_SURFACE := Color(0.10, 0.13, 0.19)
const DARK_PURPLE_SURFACE := Color(0.17, 0.13, 0.22)
const DARK_SUCCESS_SURFACE := Color(0.14, 0.20, 0.16)
const DARK_WARNING_SURFACE := Color(0.22, 0.16, 0.10)
const DARK_NEUTRAL_SURFACE := Color(0.13, 0.16, 0.20)

const LIGHT_STRONG_INFO_SURFACE := Color(0.94, 0.96, 1.00)
const LIGHT_INFO_SURFACE := LIGHT_CONTROL_SURFACE
const LIGHT_PURPLE_SURFACE := Color(0.96, 0.95, 1.00)
const LIGHT_SUCCESS_SURFACE := Color(0.94, 0.99, 0.96)
const LIGHT_WARNING_SURFACE := Color(1.00, 0.97, 0.93)
const LIGHT_NEUTRAL_SURFACE := LIGHT_CONTROL_SURFACE

static var error: Color = DARK_ERROR
static var info: Color = DARK_INFO
static var warning: Color = DARK_WARNING
static var success: Color = DARK_SUCCESS
static var teal: Color = DARK_TEAL
static var purple: Color = DARK_PURPLE
static var background: Color = DARK_BACKGROUND
static var recessed_surface: Color = DARK_RECESSED_SURFACE
static var inset_surface: Color = DARK_INSET_SURFACE
static var control_surface: Color = DARK_CONTROL_SURFACE
static var surface: Color = DARK_SURFACE
static var hover_surface: Color = DARK_HOVER_SURFACE
static var elevated_surface: Color = DARK_ELEVATED_SURFACE
static var border: Color = DARK_BORDER
static var medium_border: Color = DARK_MEDIUM_BORDER
static var subtle_border: Color = DARK_SUBTLE_BORDER
static var text: Color = DARK_TEXT
static var muted: Color = DARK_MUTED
static var strong_info_surface: Color = DARK_STRONG_INFO_SURFACE
static var info_surface: Color = DARK_INFO_SURFACE
static var purple_surface: Color = DARK_PURPLE_SURFACE
static var success_surface: Color = DARK_SUCCESS_SURFACE
static var warning_surface: Color = DARK_WARNING_SURFACE
static var neutral_surface: Color = DARK_NEUTRAL_SURFACE
static var selection_surface: Color = DARK_ELEVATED_SURFACE


## Select neutral and semantic colors with suitable contrast for the current theme.
static func refresh() -> void:
	var dark := ThemeColor.is_dark_theme()
	background = DARK_BACKGROUND if dark else LIGHT_BACKGROUND
	recessed_surface = DARK_RECESSED_SURFACE if dark else LIGHT_RECESSED_SURFACE
	inset_surface = DARK_INSET_SURFACE if dark else LIGHT_INSET_SURFACE
	control_surface = DARK_CONTROL_SURFACE if dark else LIGHT_CONTROL_SURFACE
	surface = DARK_SURFACE if dark else LIGHT_SURFACE
	hover_surface = DARK_HOVER_SURFACE if dark else LIGHT_HOVER_SURFACE
	elevated_surface = DARK_ELEVATED_SURFACE if dark else LIGHT_ELEVATED_SURFACE
	border = DARK_BORDER if dark else LIGHT_BORDER
	medium_border = DARK_MEDIUM_BORDER if dark else LIGHT_MEDIUM_BORDER
	subtle_border = DARK_SUBTLE_BORDER if dark else LIGHT_SUBTLE_BORDER
	text = DARK_TEXT if dark else LIGHT_TEXT
	muted = DARK_MUTED if dark else LIGHT_MUTED
	error = DARK_ERROR if dark else LIGHT_ERROR
	info = DARK_INFO if dark else LIGHT_INFO
	warning = DARK_WARNING if dark else LIGHT_WARNING
	success = DARK_SUCCESS if dark else LIGHT_SUCCESS
	teal = DARK_TEAL if dark else LIGHT_TEAL
	purple = DARK_PURPLE if dark else LIGHT_PURPLE
	strong_info_surface = DARK_STRONG_INFO_SURFACE if dark else LIGHT_STRONG_INFO_SURFACE
	info_surface = DARK_INFO_SURFACE if dark else LIGHT_INFO_SURFACE
	purple_surface = DARK_PURPLE_SURFACE if dark else LIGHT_PURPLE_SURFACE
	success_surface = DARK_SUCCESS_SURFACE if dark else LIGHT_SUCCESS_SURFACE
	warning_surface = DARK_WARNING_SURFACE if dark else LIGHT_WARNING_SURFACE
	neutral_surface = DARK_NEUTRAL_SURFACE if dark else LIGHT_NEUTRAL_SURFACE
	selection_surface = elevated_surface.lerp(ThemeColor.accent_solid(), 0.14 if dark else 0.10)
	pass
