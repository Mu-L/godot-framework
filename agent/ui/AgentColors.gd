class_name AgentColors
extends RefCounted

## Cursor / Codex inspired palettes for Code Agent UI (dark + light).

static var user_bubble: Color
static var system_bubble: Color
static var thinking_bubble: Color
static var tool_bubble: Color
static var file_tool_bubble: Color
static var result_bubble: Color


# ---------------------------------------------------------------------------
# Theme API
# ---------------------------------------------------------------------------

static func _static_init() -> void:
	load_saved_theme()
	pass


static func load_saved_theme() -> void:
	if ThemeColor.is_dark_theme():
		apply_dark_palette()
	else:
		apply_light_palette()
	pass


## Theme swatch RGB for UI fills and text; alpha forced to 1.
static func theme_accent_solid() -> Color:
	var c := ThemeColor.theme_color
	return Color(c.r, c.g, c.b, 1.0)


static func theme_selection_bg() -> Color:
	var mix := 0.14 if ThemeColor.is_dark_theme() else 0.10
	return ColorBase.elevated_surface.lerp(theme_accent_solid(), mix)


static func toggle_theme() -> void:
	var _theme := ThemeColor.ThemeEnum.LIGHT if ThemeColor.is_dark_theme() else ThemeColor.ThemeEnum.DARK
	if _theme == ThemeColor.ThemeEnum.DARK:
		apply_dark_palette()
	else:
		apply_light_palette()
	ThemeColor.set_theme(_theme)
	pass


# ---------------------------------------------------------------------------
# Dark palette
# ---------------------------------------------------------------------------

## Component-specific colors that intentionally differ from the shared [ColorBase] neutrals.
static func apply_dark_palette() -> void:
	user_bubble = Color(0.16, 0.22, 0.32)
	system_bubble = Color(0.10, 0.13, 0.19)
	thinking_bubble = Color(0.17, 0.13, 0.22)
	tool_bubble = Color(0.14, 0.20, 0.16)
	file_tool_bubble = Color(0.22, 0.16, 0.10)
	result_bubble = Color(0.13, 0.16, 0.20)
	pass


# ---------------------------------------------------------------------------
# Light palette
# ---------------------------------------------------------------------------

static func apply_light_palette() -> void:
	const SOFT := ColorBase.LIGHT_CONTROL_SURFACE

	user_bubble = Color(0.94, 0.96, 1.00)
	system_bubble = SOFT
	thinking_bubble = Color(0.96, 0.95, 1.00)
	tool_bubble = Color(0.94, 0.99, 0.96)
	file_tool_bubble = Color(1.00, 0.97, 0.93)
	result_bubble = SOFT
	pass
