## Read-only text popup. Dismiss with Esc, the close button, or a click outside (window loses focus).
##
## The popup paints itself from the app theme: the embedded frame and title take the accent-derived
## card colors of [ThemeColorCard] — the same surface the snackbar and the desktop toast use, with the
## card radius from [CardStyle] — and the text area takes [member ThemeColorCard.inset_color], with the
## accent on the caret, the selection and the scrollbar grabber. [method apply_theme] runs on open and
## on every theme change.
## The frame overrides only apply while subwindows are embedded, which is the project default; with
## `embed_subwindows` off the OS draws the chrome and only the text area stays themed.
class_name PopupWindow
extends Window

## Hairline around the frame, so the popup separates from the app in either theme.
const BORDER_ALPHA: float = 0.18
const BORDER_ALPHA_UNFOCUSED: float = 0.08

var text_edit: TextEdit


func _init() -> void:
	# Child of the main window: follows it, and usually has no taskbar entry.
	transient = true
	# Hide until popup_centered(), otherwise add_child flashes a default-sized window.
	visible = false
	close_requested.connect(on_close_requested)
	window_input.connect(on_window_input)
	# Freed with the window, so the connections need no teardown.
	gdf.events.theme_changed.connect(apply_theme)
	gdf.events.theme_color_changed.connect(apply_theme)

	text_edit = TextEdit.new()
	text_edit.editable = false
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text_edit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(text_edit)
	apply_theme()
	pass


## Paint the popup for the current theme; safe to run again on every theme or accent change.
func apply_theme() -> void:
	add_theme_stylebox_override("embedded_border", make_embedded_border(BORDER_ALPHA))
	add_theme_stylebox_override("embedded_unfocused_border", make_embedded_border(BORDER_ALPHA_UNFOCUSED))
	add_theme_color_override("title_color", ColorCard.title_color)
	add_theme_font_override("title_font", Fonts.semibold())
	add_theme_font_size_override("title_font_size", TextStyle.title_medium_size)
	style_text_edit()
	pass


## The engine's own frame with only its fills swapped, so the 32px title band, the close button and
## the resize margins keep the geometry the engine positions them by. The content panel inside it stays
## square, so its corners can never open a gap against the frame's inner edge.
func make_embedded_border(border_alpha: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = get_theme_stylebox("embedded_border").duplicate() as StyleBoxFlat
	style.bg_color = ColorCard.background_color
	style.set_corner_radius_all(CardStyle.CORNER_RADIUS)
	style.border_color = Color(ColorCard.title_color, border_alpha)
	style.set_border_width_all(1)
	return style


## Read-only text area on the card's inset surface: padding from [Margin], accent caret and
## selection, themed scrollbars.
func style_text_edit() -> void:
	var style := BoxStyle.make(ColorCard.inset_color, 0, Margin.ma_4, Margin.ma_3)
	# A read-only TextEdit paints `read_only`, not `normal`; all three get the box so any state matches.
	text_edit.add_theme_stylebox_override("normal", style)
	text_edit.add_theme_stylebox_override("focus", style.duplicate())
	text_edit.add_theme_stylebox_override("read_only", style.duplicate())
	text_edit.add_theme_color_override("background_color", ColorCard.inset_color)
	text_edit.add_theme_color_override("font_color", ColorCard.title_color)
	text_edit.add_theme_color_override("font_readonly_color", ColorCard.title_color)
	text_edit.add_theme_color_override("font_selected_color", ColorCard.title_color)
	text_edit.add_theme_color_override("caret_color", ColorCard.accent_color)
	text_edit.add_theme_color_override("selection_color", ColorCard.selection_color)
	text_edit.add_theme_color_override("current_line_color", Color(ColorCard.accent_color, 0.10))
	text_edit.add_theme_font_override("font", Fonts.regular())
	text_edit.add_theme_font_size_override("font_size", TextStyle.body_large_size)
	style_scroll_bar(text_edit.get_v_scroll_bar())
	style_scroll_bar(text_edit.get_h_scroll_bar())
	pass


## Transparent track, muted grabber, accent on hover and press — recolored engine boxes, so the bar
## keeps its 8px width and pill radius.
func style_scroll_bar(bar: ScrollBar) -> void:
	recolor(bar, "scroll", Color(0, 0, 0, 0))
	recolor(bar, "scroll_focus", Color(0, 0, 0, 0))
	recolor(bar, "grabber", ColorCard.body_color)
	recolor(bar, "grabber_highlight", ColorCard.accent_color)
	recolor(bar, "grabber_pressed", ColorCard.accent_color)
	pass


## [param item] with only its fill exchanged.
func recolor(control: Control, item: String, color: Color) -> void:
	var style: StyleBoxFlat = control.get_theme_stylebox(item).duplicate() as StyleBoxFlat
	style.bg_color = color
	control.add_theme_stylebox_override(item, style)
	pass


## Open a centered read-only window. Width/height are percent of the screen (1–100).
## [param i18n_title] and [param i18n_text] may be translation keys; text without a registered
## translation is displayed unchanged.
## Example: `PopupWindow.show_window("Full view", body, 76, 78)`
static func show_window(i18n_title: String, i18n_text: String, width_percent: int, height_percent: int) -> void:
	var window := PopupWindow.new()
	window.title = str(I18n.t(i18n_title))
	gdf.gdf_node.add_child(window)
	# Size against the root viewport; this Window is itself a Viewport.
	var viewport := gdf.gdf_node.get_tree().root.get_visible_rect().size
	window.size = Vector2i(
		int(viewport.x * clampf(width_percent, 1.0, 100.0) / 100.0),
		int(viewport.y * clampf(height_percent, 1.0, 100.0) / 100.0),
	)
	window.set_body(str(I18n.t(i18n_text)))
	window.popup_centered()
	pass


func set_body(text: String) -> void:
	text_edit.text = text
	text_edit.scroll_vertical = text_edit.get_line_count()
	pass


func _notification(what: int) -> void:
	# Clicking outside moves focus back to the main window.
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and visible:
		queue_free()
	pass


func on_close_requested() -> void:
	queue_free()
	pass


func on_window_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		queue_free()
		set_input_as_handled()
	pass
