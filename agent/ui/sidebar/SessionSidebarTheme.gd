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
	var style := BoxStyle.make(ColorBase.inset_surface)
	style.border_color = ColorBase.medium_border
	style.set_border_width(SIDE_RIGHT, 1)
	return style


static func pinned_separator() -> StyleBoxLine:
	var accent: Color = ThemeColor.accent_solid()
	var line: StyleBoxLine = StyleBoxLine.new()
	line.color = ButtonStyle.with_alpha(accent, 0.42 if ThemeColor.is_dark_theme() else 0.32)
	line.grow_begin = 2
	line.grow_end = 2
	line.thickness = 1
	return line


## "+ New chat" — outlined in the accent, filled while hovered / pressed.
static func apply_new_session_button(button: Button) -> void:
	var accent: Color = ThemeColor.accent_solid()
	button.flat = false
	button.focus_mode = Control.FOCUS_NONE
	ButtonStyle.apply_font_colors(button, accent, ButtonStyle.hover_color(accent, 0.08), ButtonStyle.press_color(accent, 0.06), ColorBase.muted)

	var border := ButtonStyle.with_alpha(accent, 0.55 if ThemeColor.is_dark_theme() else 0.45)
	var normal := BoxStyle.make(Color.TRANSPARENT, ROW_CORNER_RADIUS, Margin.ma_3, Margin.ma_2, border, 1)
	var hover := BoxStyle.with_bg(normal, ColorBase.selection_surface)
	hover.border_color = ButtonStyle.with_alpha(accent, 0.85)
	var pressed := BoxStyle.with_bg(hover, ButtonStyle.hover_color(ColorBase.selection_surface, 0.06))
	pressed.border_color = accent
	ButtonStyle.apply_states(button, normal, hover, pressed)
	pass


# ---------------------------------------------------------------------------
# Chat rows
# ---------------------------------------------------------------------------

## Row background — selected beats hovered, transparent otherwise.
static func row(selected: bool, hovered: bool) -> StyleBoxFlat:
	var style := BoxStyle.make(Color.TRANSPARENT, ROW_CORNER_RADIUS)
	BoxStyle.pad(style, Margin.ma_3, Margin.ma_1, Margin.ma_1, Margin.ma_1)
	if selected:
		style.bg_color = ColorBase.selection_surface
	elif hovered:
		style.bg_color = ColorBase.hover_surface
	return style


## Title / close button colors for the current row state.
static func apply_row_colors(title_button: Button, delete_button: Button, selected: bool, hovered: bool) -> void:
	var text_color: Color = ColorBase.text if selected or hovered else ColorBase.muted
	title_button.add_theme_color_override("font_color", text_color)
	title_button.add_theme_color_override("font_hover_color", text_color)
	title_button.add_theme_color_override("font_pressed_color", text_color)
	delete_button.add_theme_color_override("font_color", ColorBase.muted)
	delete_button.add_theme_color_override("font_hover_color", ColorBase.error)
	delete_button.add_theme_color_override("font_pressed_color", ColorBase.error)
	pass


## Floating row copy that follows the cursor while dragging.
static func drag_ghost() -> StyleBoxFlat:
	var accent: Color = ThemeColor.accent_solid()
	var style: StyleBoxFlat = row(false, false)
	style.bg_color = ColorBase.selection_surface
	style.border_color = ButtonStyle.with_alpha(accent, 0.9 if ThemeColor.is_dark_theme() else 0.75)
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
	edit.add_theme_color_override("font_color", ColorBase.text)
	edit.add_theme_color_override("font_placeholder_color", ColorBase.muted)
	edit.add_theme_color_override("caret_color", ThemeColor.accent_solid())
	edit.add_theme_color_override("selection_color", ColorBase.selection_surface)
	var field_style: StyleBoxFlat = rename_field()
	edit.add_theme_stylebox_override("normal", field_style)
	edit.add_theme_stylebox_override("focus", field_style)
	pass


static func rename_field() -> StyleBoxFlat:
	var accent: Color = ThemeColor.accent_solid()
	var border := ButtonStyle.with_alpha(accent, 0.75 if ThemeColor.is_dark_theme() else 0.55)
	return BoxStyle.make(ColorBase.surface, RENAME_CORNER_RADIUS, Margin.ma_1, Margin.ma_0, border, 1)


## Mirrors a resolved font onto another control (rename field, drag ghost).
static func copy_font(target: Control, source: Control) -> void:
	target.add_theme_font_override("font", source.get_theme_font("font"))
	target.add_theme_font_size_override("font_size", source.get_theme_font_size("font_size"))
	pass
