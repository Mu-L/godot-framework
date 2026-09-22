class_name DesktopToast
extends Window

## Desktop toast — a native, borderless, always-on-top OS window pinned to the bottom-right of
## the screen, so a message stays readable while the app window is behind other apps.
## `force_native` makes it a real system window without turning the app's dialogs into ones.
##
## Example: `DesktopToast.show_toast("Run finished", summary, Colors.success)`
## The card follows the app accent through `ThemeColorCard`; the accent color is passed per toast.

const CARD_WIDTH := 380.0
const CARD_PADDING := 18.0
const ACCENT_WIDTH := 3
const TITLE_FONT_SIZE := 15
const BODY_FONT_SIZE := 13
const TITLE_BODY_GAP := 8.0
const MAX_BODY_LINES := 4
const SCREEN_MARGIN := 24.0
const STACK_GAP := 12.0
const SHOW_SECONDS := 4.5

## Live toasts, oldest first — the newest one hugs the screen corner.
static var toasts: Array[DesktopToast] = []
## Main-window pixels per viewport unit, so the toast matches the app's UI scale.
static var ui_scale := 1.0

var card: PanelContainer
var body_label: Label
var heading := ""
var message := ""
var accent: Color = Colors.info
var closing := false


func _init() -> void:
	# A window must be hidden before `force_native` is assigned.
	visible = false
	force_native = true
	borderless = true
	unresizable = true
	always_on_top = true
	# Never steal focus, and stay out of the taskbar / alt-tab list.
	unfocusable = true
	popup_window = true
	# Square card: Windows 11 would otherwise round (and clip) the window corners.
	sharp_corners = true
	pass


## Pop a toast in the bottom-right corner of the screen.
static func show_toast(title: String, body: String, color: Color) -> void:
	if gdf.gdf_node == null or not gdf.gdf_node.is_inside_tree():
		return
	ui_scale = compute_ui_scale()
	var toast := DesktopToast.new()
	toast.heading = title
	toast.message = body.strip_edges()
	toast.accent = color
	toasts.append(toast)
	gdf.gdf_node.add_child(toast)
	pass


## App UI scale, i.e. how many screen pixels one viewport unit takes on the main window.
static func compute_ui_scale() -> float:
	var viewport := gdf.gdf_node.get_viewport()
	if viewport == null:
		return 1.0
	var unit := viewport.get_visible_rect().size
	if unit.x <= 0.0 or unit.y <= 0.0:
		return 1.0
	var pixels := Vector2(DisplayServer.window_get_size())
	return clampf(minf(pixels.x / unit.x, pixels.y / unit.y), 0.5, 4.0)


## Bottom-right anchor of the usable screen area (taskbar excluded).
static func corner_position(window_size: Vector2i) -> Vector2i:
	var screen := DisplayServer.window_get_current_screen(DisplayServer.MAIN_WINDOW_ID)
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var margin := roundi(SCREEN_MARGIN * ui_scale)
	return Vector2i(
		usable.position.x + usable.size.x - window_size.x - margin,
		usable.position.y + usable.size.y - window_size.y - margin,
	)


## Stack live toasts from the screen corner upward.
static func relayout() -> void:
	var lift := 0
	for i in range(toasts.size() - 1, -1, -1):
		var toast := toasts[i]
		if not is_instance_valid(toast) or toast.closing:
			continue
		var corner := corner_position(toast.size)
		toast.position = Vector2i(corner.x, corner.y - lift)
		lift += toast.size.y + roundi(STACK_GAP * ui_scale)
	pass


func _ready() -> void:
	build_card()
	# Controls only lay out inside a visible window, and the font-metric estimate cannot know how
	# the body wraps, so let the wrapping settle and then fit the window to the card.
	visible = true
	for _i in 3:
		if is_layout_settled():
			break
		await get_tree().process_frame
	fit_window_size()
	relayout()
	# Auto-dismiss. A connection, unlike an await, is dropped if the card is clicked first.
	get_tree().create_timer(SHOW_SECONDS).timeout.connect(close_toast)
	pass


## Body wrapping is done once the label got its real width from the container.
func is_layout_settled() -> bool:
	return body_label == null or body_label.size.x > 1.0


## Fit the window to the card, so a wrapped body is never clipped.
func fit_window_size() -> void:
	if not is_layout_settled():
		return
	size = Vector2i(size.x, roundi(card.get_combined_minimum_size().y))
	pass


func build_card() -> void:
	var unit := ui_scale
	var pad := CARD_PADDING * unit
	var card_width := CARD_WIDTH * unit
	var text_width := card_width - pad * 2.0
	var title_font := Fonts.semibold()
	var body_font := Fonts.regular()
	var title_size := roundi(TITLE_FONT_SIZE * unit)
	var body_size := roundi(BODY_FONT_SIZE * unit)
	var gap := TITLE_BODY_GAP * unit
	# First guess from font metrics; `fit_window_size` corrects it once the labels wrapped.
	var body_height := 0.0
	if StringUtils.is_not_blank(message):
		body_height = body_font.get_multiline_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, text_width, body_size, MAX_BODY_LINES).y
	var card_height := pad * 2.0 + title_font.get_height(title_size) + (gap + body_height if body_height > 0.0 else 0.0)
	size = Vector2i(roundi(card_width), roundi(card_height))
	# Place it while it is still invisible, so the window never flashes at the tree origin.
	position = corner_position(size)

	card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", make_card_style(pad, unit))
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.gui_input.connect(on_card_input)
	add_child(card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", roundi(gap))
	card.add_child(column)

	var title_label := Label.new()
	title_label.text = heading
	title_label.add_theme_font_override("font", title_font)
	title_label.add_theme_font_size_override("font_size", title_size)
	title_label.add_theme_color_override("font_color", ThemeColorCard.title_color)
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(title_label)

	if body_height > 0.0:
		body_label = Label.new()
		body_label.text = message
		body_label.add_theme_font_override("font", body_font)
		body_label.add_theme_font_size_override("font_size", body_size)
		body_label.add_theme_color_override("font_color", ThemeColorCard.body_color)
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_label.max_lines_visible = MAX_BODY_LINES
		body_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(body_label)
	pass


## Flat rectangle: card background plus an accent stripe down the left edge.
func make_card_style(pad: float, unit: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeColorCard.background_color
	style.border_color = accent
	style.border_width_left = roundi(ACCENT_WIDTH * unit)
	style.content_margin_left = pad
	style.content_margin_right = pad
	style.content_margin_top = pad
	style.content_margin_bottom = pad
	return style


func close_toast() -> void:
	if closing:
		return
	closing = true
	toasts.erase(self)
	queue_free()
	DesktopToast.relayout()
	pass


func on_card_input(event: InputEvent) -> void:
	# Click anywhere on the card to dismiss it early.
	if event is InputEventMouseButton and event.pressed:
		close_toast()
	pass
