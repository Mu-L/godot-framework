class_name SessionSidebarTheme
extends Object

## Every stylebox / color override the sidebar uses. All builders read the live palette, so a
## theme switch only has to re-apply them (see [method AgentSessionSidebar.apply_theme]).

const ROW_CORNER_RADIUS: int = 6
const RENAME_CORNER_RADIUS: int = 5


# ---------------------------------------------------------------------------
# Sidebar shell
# ---------------------------------------------------------------------------

## Sidebar background plus the hairline against the chat area.
static func sidebar_panel() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = AgentColors.sidebar
	style.border_color = AgentColors.sidebar_border
	style.set_border_width(SIDE_RIGHT, 1)
	return style


static func pinned_separator() -> StyleBoxLine:
	var accent: Color = AgentColors.theme_accent_solid()
	var line: StyleBoxLine = StyleBoxLine.new()
	line.color = Color(accent.r, accent.g, accent.b, 0.42 if ThemeColor.is_dark_theme() else 0.32)
	line.grow_begin = 2
	line.grow_end = 2
	line.thickness = 1
	return line


## "+ New chat" — outlined in the accent, filled while hovered / pressed.
static func apply_new_session_button(button: Button) -> void:
	var accent: Color = AgentColors.theme_accent_solid()
	button.flat = false
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", accent)
	button.add_theme_color_override("font_hover_color", accent.lightened(0.08))
	button.add_theme_color_override("font_pressed_color", accent.darkened(0.06))
	button.add_theme_color_override("font_disabled_color", AgentColors.sidebar_muted)

	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.55 if ThemeColor.is_dark_theme() else 0.45)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(ROW_CORNER_RADIUS)
	normal.content_margin_left = Margin.ma_3
	normal.content_margin_right = Margin.ma_3
	normal.content_margin_top = Margin.ma_2
	normal.content_margin_bottom = Margin.ma_2

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = AgentColors.theme_selection_bg()
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.85)

	var pressed: StyleBoxFlat = hover.duplicate() as StyleBoxFlat
	if ThemeColor.current_theme == ThemeColor.ThemeEnum.DARK:
		pressed.bg_color = pressed.bg_color.lightened(0.06)
	else:
		pressed.bg_color = pressed.bg_color.darkened(0.04)
	pressed.border_color = accent

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed.duplicate())
	button.add_theme_stylebox_override("focus", hover.duplicate())
	button.add_theme_stylebox_override("disabled", normal.duplicate())
	pass


# ---------------------------------------------------------------------------
# Chat rows
# ---------------------------------------------------------------------------

## Row background — selected beats hovered, transparent otherwise.
static func row(selected: bool, hovered: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_corner_radius_all(ROW_CORNER_RADIUS)
	style.content_margin_left = Margin.ma_3
	style.content_margin_right = Margin.ma_1
	style.content_margin_top = Margin.ma_1
	style.content_margin_bottom = Margin.ma_1
	if selected:
		style.bg_color = AgentColors.theme_selection_bg()
	elif hovered:
		style.bg_color = AgentColors.sidebar_row_hover
	else:
		style.bg_color = Color(0, 0, 0, 0)
	return style


## Title / close button colors for the current row state.
static func apply_row_colors(title_button: Button, delete_button: Button, selected: bool, hovered: bool) -> void:
	var text_color: Color = AgentColors.sidebar_text if selected or hovered else AgentColors.sidebar_muted
	title_button.add_theme_color_override("font_color", text_color)
	title_button.add_theme_color_override("font_hover_color", text_color)
	title_button.add_theme_color_override("font_pressed_color", text_color)
	delete_button.add_theme_color_override("font_color", AgentColors.sidebar_muted)
	delete_button.add_theme_color_override("font_hover_color", AgentColors.error)
	delete_button.add_theme_color_override("font_pressed_color", AgentColors.error)
	pass


## Floating row copy that follows the cursor while dragging.
static func drag_ghost() -> StyleBoxFlat:
	var accent: Color = AgentColors.theme_accent_solid()
	var style: StyleBoxFlat = row(false, false)
	style.bg_color = AgentColors.theme_selection_bg()
	style.border_color = Color(accent.r, accent.g, accent.b, 0.9 if ThemeColor.is_dark_theme() else 0.75)
	style.set_border_width_all(1)
	style.shadow_color = Color(0, 0, 0, 0.35 if ThemeColor.is_dark_theme() else 0.18)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style


# ---------------------------------------------------------------------------
# Inline rename
# ---------------------------------------------------------------------------

## The field takes over the title's slot, so it mirrors the title's resolved font.
static func apply_rename_field(edit: LineEdit, title_button: Button) -> void:
	copy_font(edit, title_button)
	edit.add_theme_color_override("font_color", AgentColors.sidebar_text)
	edit.add_theme_color_override("font_placeholder_color", AgentColors.sidebar_muted)
	edit.add_theme_color_override("caret_color", AgentColors.theme_accent_solid())
	edit.add_theme_color_override("selection_color", AgentColors.theme_selection_bg())
	var field_style: StyleBoxFlat = rename_field()
	edit.add_theme_stylebox_override("normal", field_style)
	edit.add_theme_stylebox_override("focus", field_style)
	pass


static func rename_field() -> StyleBoxFlat:
	var accent: Color = AgentColors.theme_accent_solid()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = AgentColors.chat_input
	style.border_color = Color(accent.r, accent.g, accent.b, 0.75 if ThemeColor.is_dark_theme() else 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(RENAME_CORNER_RADIUS)
	style.content_margin_left = Margin.ma_1
	style.content_margin_right = Margin.ma_1
	return style


## Mirrors a resolved font onto another control (rename field, drag ghost).
static func copy_font(target: Control, source: Control) -> void:
	target.add_theme_font_override("font", source.get_theme_font("font"))
	target.add_theme_font_size_override("font_size", source.get_theme_font_size("font_size"))
	pass
