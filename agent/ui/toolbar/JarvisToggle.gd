class_name JarvisToggle
extends RefCounted

## Toolbar toggle for the Jarvis 3D orb overlay during agent runs.

const BUTTON_SIZE: int = 28
const CORNER_RADIUS: int = 14
const ICON_DRAW_SIZE: int = 24
const ICON_DISPLAY_SIZE: int = 24
const RING_COUNT: int = 3
## Radii on the ICON_DRAW_SIZE canvas. An even-sized canvas has its centre on a half pixel
## ((size - 1) / 2), so the radii stay half integers: an integer radius would push the rings
## one texel to the bottom right of the canvas and off centre inside the round button.
const RING_RADII: Array[float] = [2.5, 7.5, 11.5]

var button: Button


func setup(p_button: Button) -> void:
	button = p_button
	button.text = ""
	button.toggled.connect(on_toggled)
	button.mouse_entered.connect(on_mouse_entered)
	button.mouse_exited.connect(on_mouse_exited)
	gdf.events.theme_changed.connect(apply_theme)
	gdf.events.theme_color_changed.connect(apply_theme)
	gdf.events.locale_changed.connect(apply_theme)
	apply_theme()
	pass


func apply_theme() -> void:
	var jarvis_orb_enabled: bool = AgentSetting.get_jarvis_orb_enabled()
	var tooltip: String = (
		I18n.t("agent.toolbar.hide_animation")
		if jarvis_orb_enabled
		else I18n.t("agent.toolbar.show_animation")
	)
	AgentToolbarButton.style(button, tooltip, CORNER_RADIUS)
	apply_equal_icon_margins(Margin.ma_1)
	button.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.expand_icon = false
	button.add_theme_constant_override("icon_max_width", ICON_DISPLAY_SIZE)
	button.add_theme_constant_override("icon_max_height", ICON_DISPLAY_SIZE)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	update_icon(button.is_hovered())
	button.set_block_signals(true)
	button.button_pressed = jarvis_orb_enabled
	button.set_block_signals(false)
	pass


func apply_equal_icon_margins(margin: int) -> void:
	for state_name: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var box: StyleBoxFlat = button.get_theme_stylebox(state_name) as StyleBoxFlat
		if box == null:
			continue
		box.content_margin_left = margin
		box.content_margin_right = margin
		box.content_margin_top = margin
		box.content_margin_bottom = margin
	pass


func on_mouse_entered() -> void:
	update_icon(true)
	pass


func on_mouse_exited() -> void:
	update_icon(false)
	pass


func update_icon(hovered: bool) -> void:
	var jarvis_orb_enabled: bool = AgentSetting.get_jarvis_orb_enabled()
	var icon_color: Color = ColorBase.muted
	if jarvis_orb_enabled:
		var accent: Color = ThemeColor.accent_solid()
		icon_color = accent if ThemeColor.is_dark_theme() else accent.darkened(0.15)
		if hovered:
			icon_color = icon_color.lightened(0.12)
	elif hovered:
		icon_color = ColorBase.text
	button.icon = make_concentric_rings_icon(ICON_DRAW_SIZE, icon_color)
	pass


func make_concentric_rings_icon(size: int, color: Color) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center: float = (size - 1) / 2.0
	for ring_index in range(RING_COUNT):
		draw_circle_outline(img, center, RING_RADII[ring_index], color)
	return ImageTexture.create_from_image(img)


## 1 px ring: keep every texel whose centre falls inside the radius band. Drawing from the
## texel centre keeps the outline symmetric for both even and odd canvas sizes.
func draw_circle_outline(img: Image, center: float, radius: float, col: Color) -> void:
	if radius <= 0.0:
		return
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var dx: float = x - center
			var dy: float = y - center
			if absf(sqrt(dx * dx + dy * dy) - radius) <= 0.5:
				img.set_pixel(x, y, col)
	pass


func on_toggled(enabled: bool) -> void:
	AgentSetting.set_jarvis_orb_enabled(enabled)
	apply_theme()
	pass
