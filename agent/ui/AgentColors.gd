class_name AgentColors
extends RefCounted

## Cursor / Codex inspired palettes for Code Agent UI (dark + light).

static var sidebar: Color
static var sidebar_border: Color
static var sidebar_title: Color
static var sidebar_text: Color
static var sidebar_muted: Color
static var sidebar_row_selected: Color
static var sidebar_row_hover: Color
static var sidebar_row_accent: Color
static var toolbar: Color
static var toolbar_border: Color
static var toolbar_title: Color
static var toolbar_muted: Color
static var toolbar_button: Color
static var chat: Color
static var chat_text: Color
static var chat_text_muted: Color
static var chat_bubble_border: Color
static var chat_input: Color
static var chat_input_border: Color
static var panel: Color
static var accent: Color
static var user_bubble: Color
static var assistant_bubble: Color
static var system_bubble: Color
static var thinking_bubble: Color
static var tool_bubble: Color
static var file_tool_bubble: Color
static var file_tool_title: Color
static var result_bubble: Color
static var success: Color
static var error: Color
static var system_title: Color
static var thinking_title: Color


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


static func set_theme_color(new_color: Color) -> void:
	ThemeColor.set_theme_color(new_color)
	pass


## Theme swatch RGB for UI fills and text; alpha forced to 1.
static func theme_accent_solid() -> Color:
	var c := ThemeColor.theme_color
	return Color(c.r, c.g, c.b, 1.0)


static func theme_selection_bg() -> Color:
	var mix := 0.14 if ThemeColor.is_dark_theme() else 0.10
	return sidebar_row_selected.lerp(theme_accent_solid(), mix)


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

## Roles that share a tone point at one local constant: changing a border greys all four
## outlines at once, and the constant says which tone it is (`HAIRLINE`, not a hex).
static func apply_dark_palette() -> void:
	const TEXT := Color(0.90, 0.91, 0.93)
	const MUTED := Color(0.55, 0.57, 0.62)
	const PANEL := Color(0.12, 0.13, 0.16)
	const SURFACE := Color(0.14, 0.15, 0.18)
	const HAIRLINE := Color(0.22, 0.24, 0.28)
	const ACCENT := Color(0.35, 0.65, 0.95)

	sidebar = Color(0.10, 0.11, 0.13)
	sidebar_border = Color(0.18, 0.20, 0.24)
	sidebar_title = Color(0.50, 0.52, 0.58)
	sidebar_text = TEXT
	sidebar_muted = MUTED
	sidebar_row_selected = SURFACE
	sidebar_row_hover = PANEL
	sidebar_row_accent = ACCENT
	toolbar = Color(0.06, 0.07, 0.09)
	toolbar_border = Color(0.16, 0.18, 0.22)
	toolbar_title = Color(0.93, 0.94, 0.96)
	toolbar_muted = Color(0.52, 0.54, 0.60)
	toolbar_button = Color(0.11, 0.12, 0.15)
	chat = Color(0.07, 0.08, 0.10)
	chat_text = TEXT
	chat_text_muted = MUTED
	chat_bubble_border = HAIRLINE
	chat_input = PANEL
	chat_input_border = HAIRLINE
	panel = PANEL
	accent = ACCENT
	user_bubble = Color(0.16, 0.22, 0.32)
	assistant_bubble = SURFACE
	system_bubble = Color(0.10, 0.13, 0.19)
	thinking_bubble = Color(0.17, 0.13, 0.22)
	tool_bubble = Color(0.14, 0.20, 0.16)
	file_tool_bubble = Color(0.22, 0.16, 0.10)
	file_tool_title = Color(0.95, 0.72, 0.38)
	result_bubble = Color(0.13, 0.16, 0.20)
	success = Color(0.30, 0.78, 0.45)
	error = Color(0.85, 0.30, 0.30)
	system_title = Color(0.55, 0.68, 0.88)
	thinking_title = Color(0.72, 0.58, 0.88)
	pass


# ---------------------------------------------------------------------------
# Light palette
# ---------------------------------------------------------------------------

static func apply_light_palette() -> void:
	const TEXT := Color(0.09, 0.09, 0.11)
	const MUTED := Color(0.44, 0.44, 0.48)
	const PANEL := Color(1.00, 1.00, 1.00)
	const SOFT := Color(0.96, 0.96, 0.96)
	const CHROME := Color(0.95, 0.95, 0.96)
	const HAIRLINE := Color(0.89, 0.89, 0.91)
	const ACCENT := Color(0.15, 0.39, 0.92)

	sidebar = CHROME
	sidebar_border = HAIRLINE
	sidebar_title = MUTED
	sidebar_text = TEXT
	sidebar_muted = MUTED
	sidebar_row_selected = PANEL
	sidebar_row_hover = Color(0.93, 0.93, 0.94)
	sidebar_row_accent = ACCENT
	toolbar = CHROME
	toolbar_border = HAIRLINE
	toolbar_title = TEXT
	toolbar_muted = MUTED
	toolbar_button = SOFT
	chat = Color(0.98, 0.98, 0.98)
	chat_text = TEXT
	chat_text_muted = MUTED
	chat_bubble_border = HAIRLINE
	chat_input = PANEL
	chat_input_border = HAIRLINE
	panel = PANEL
	accent = ACCENT
	user_bubble = Color(0.94, 0.96, 1.00)
	assistant_bubble = PANEL
	system_bubble = SOFT
	thinking_bubble = Color(0.96, 0.95, 1.00)
	tool_bubble = Color(0.94, 0.99, 0.96)
	file_tool_bubble = Color(1.00, 0.97, 0.93)
	file_tool_title = Color(0.92, 0.35, 0.05)
	result_bubble = SOFT
	success = Color(0.09, 0.64, 0.29)
	error = Color(0.86, 0.15, 0.15)
	system_title = Color(0.31, 0.27, 0.90)
	thinking_title = Color(0.49, 0.23, 0.93)
	pass
