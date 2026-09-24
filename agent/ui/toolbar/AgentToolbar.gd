class_name AgentToolbar
extends RefCounted

## Top toolbar — panel chrome, GAI logo, title, and workspace path button theme.

const LOGO_FONT_SIZE: int = 18
const LOGO_GLYPH_SPACING: int = 2

var toolbar_panel: PanelContainer
var logo_label: Label
var title_label: Label
var project_button: Button


func setup(
	p_toolbar_panel: PanelContainer,
	p_logo_label: Label,
	p_title_label: Label,
	p_project_button: Button
) -> void:
	toolbar_panel = p_toolbar_panel
	logo_label = p_logo_label
	title_label = p_title_label
	project_button = p_project_button
	gdf.events.theme_changed.connect(apply_theme)
	apply_theme()
	pass


func apply_theme() -> void:
	toolbar_panel.add_theme_stylebox_override("panel", build_toolbar_style())
	toolbar_panel.queue_redraw()
	apply_logo_theme()
	title_label.add_theme_color_override("font_color", AgentColors.toolbar_title)
	project_button.add_theme_color_override("font_color", AgentColors.toolbar_muted)
	project_button.add_theme_color_override("font_hover_color", AgentColors.toolbar_title)
	project_button.add_theme_color_override("font_pressed_color", AgentColors.toolbar_title)
	pass


## GAI wordmark on the far left of the toolbar row.
func apply_logo_theme() -> void:
	var accent: Color = AgentColors.theme_accent_solid()
	var logo_font: FontVariation = FontVariation.new()
	logo_font.base_font = Fonts.bold()
	logo_font.spacing_glyph = LOGO_GLYPH_SPACING
	logo_label.text = "GAI"
	logo_label.tooltip_text = "GAI Code Agent"
	logo_label.add_theme_font_override("font", logo_font)
	logo_label.add_theme_font_size_override("font_size", LOGO_FONT_SIZE)
	logo_label.add_theme_color_override("font_color", accent if ThemeColor.is_dark_theme() else accent.darkened(0.08))
	pass


func build_toolbar_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = AgentColors.toolbar
	style.border_color = AgentColors.toolbar_border
	style.content_margin_left = Margin.ma_3
	style.set_border_width(SIDE_BOTTOM, 1)
	if ThemeColor.is_light_theme():
		style.set_border_width(SIDE_TOP, 1)
	return style
