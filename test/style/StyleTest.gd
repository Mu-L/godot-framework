## Unit tests for [BoxStyle], [ButtonStyle], [CardStyle] and the builders that go through them.

const GRAY := Color(0.5, 0.5, 0.5)


func ColorBase_follow_theme_test() -> void:
	var original := ThemeColor.current_theme
	ThemeColor.current_theme = ThemeColor.ThemeEnum.DARK
	ColorBase.refresh()
	assert(ColorBase.background == ColorBase.DARK_BACKGROUND)
	assert(ColorBase.surface == ColorBase.DARK_SURFACE)
	assert(ColorBase.hover_surface == ColorBase.DARK_HOVER_SURFACE)
	assert(ColorBase.elevated_surface == ColorBase.DARK_ELEVATED_SURFACE)
	assert(ColorBase.border == ColorBase.DARK_BORDER)
	assert(ColorBase.text == ColorBase.DARK_TEXT)
	assert(ColorBase.muted == ColorBase.DARK_MUTED)
	assert(ColorBase.error == ColorBase.DARK_ERROR)
	assert(ColorBase.info == ColorBase.DARK_INFO)
	assert(ColorBase.warning == ColorBase.DARK_WARNING)
	assert(ColorBase.success == ColorBase.DARK_SUCCESS)
	assert(ColorBase.teal == ColorBase.DARK_TEAL)

	ThemeColor.current_theme = ThemeColor.ThemeEnum.LIGHT
	ColorBase.refresh()
	assert(ColorBase.background == ColorBase.LIGHT_BACKGROUND)
	assert(ColorBase.surface == ColorBase.LIGHT_SURFACE)
	assert(ColorBase.hover_surface == ColorBase.LIGHT_HOVER_SURFACE)
	assert(ColorBase.elevated_surface == ColorBase.LIGHT_ELEVATED_SURFACE)
	assert(ColorBase.border == ColorBase.LIGHT_BORDER)
	assert(ColorBase.text == ColorBase.LIGHT_TEXT)
	assert(ColorBase.muted == ColorBase.LIGHT_MUTED)
	assert(ColorBase.error == ColorBase.LIGHT_ERROR)
	assert(ColorBase.info == ColorBase.LIGHT_INFO)
	assert(ColorBase.warning == ColorBase.LIGHT_WARNING)
	assert(ColorBase.success == ColorBase.LIGHT_SUCCESS)
	assert(ColorBase.teal == ColorBase.LIGHT_TEAL)

	ThemeColor.current_theme = original
	ColorBase.refresh()
	pass


## The whole point of the helper: the same call keeps contrast on both themes.
func ButtonStyle_color_direction_test() -> void:
	var original: ThemeColor.ThemeEnum = ThemeColor.current_theme

	ThemeColor.current_theme = ThemeColor.ThemeEnum.DARK
	assert(ButtonStyle.hover_color(GRAY, 0.10) == GRAY.lightened(0.10))
	assert(ButtonStyle.press_color(GRAY, 0.06) == GRAY.darkened(0.06))

	ThemeColor.current_theme = ThemeColor.ThemeEnum.LIGHT
	assert(ButtonStyle.hover_color(GRAY, 0.10) == GRAY.darkened(0.10))
	assert(ButtonStyle.press_color(GRAY, 0.06) == GRAY.lightened(0.06))

	# `muted` is the resting counterpart of the pressed step, one bigger default amount.
	assert(ButtonStyle.muted(GRAY) == ButtonStyle.press_color(GRAY, ButtonStyle.MUTED_AMOUNT))
	assert(ButtonStyle.MUTED_AMOUNT > ButtonStyle.PRESS_AMOUNT)

	ThemeColor.current_theme = original
	pass


func ButtonStyle_with_alpha_test() -> void:
	var tinted := ButtonStyle.with_alpha(ColorBase.info, 0.45)
	# `Color` stores 32-bit floats, so compare approximately.
	assert(is_equal_approx(tinted.a, 0.45))
	assert(tinted.r == ColorBase.info.r and tinted.b == ColorBase.info.b)
	pass


func BoxStyle_make_test() -> void:
	var style := BoxStyle.make(Color(0.1, 0.2, 0.3), 8, Margin.ma_2, Margin.ma_1, ColorBase.info, 1)
	assert(style.bg_color == Color(0.1, 0.2, 0.3))
	assert(style.corner_radius_top_left == 8 and style.corner_radius_bottom_right == 8)
	assert(style.get_margin(SIDE_LEFT) == Margin.ma_2 and style.get_margin(SIDE_RIGHT) == Margin.ma_2)
	assert(style.get_margin(SIDE_TOP) == Margin.ma_1 and style.get_margin(SIDE_BOTTOM) == Margin.ma_1)
	assert(style.border_width_left == 1 and style.border_color == ColorBase.info)

	# No border width means no border at all, so a caller that does not want one keeps the default.
	var plain := BoxStyle.make(Color.WHITE, 4)
	assert(plain.border_width_left == 0 and plain.get_margin(SIDE_LEFT) == 0.0)
	pass


func BoxStyle_pad_test() -> void:
	var style := BoxStyle.make(Color.WHITE, 4)
	BoxStyle.pad(style, Margin.ma_3, Margin.ma_2, Margin.ma_1, Margin.ma_0)
	assert(style.get_margin(SIDE_LEFT) == Margin.ma_3 and style.get_margin(SIDE_RIGHT) == Margin.ma_1)
	assert(style.get_margin(SIDE_TOP) == Margin.ma_2 and style.get_margin(SIDE_BOTTOM) == Margin.ma_0)

	# Base class on purpose: an empty box takes the same padding as a filled one.
	var empty := StyleBoxEmpty.new()
	BoxStyle.pad(empty, Margin.ma_1, Margin.ma_1, Margin.ma_1, Margin.ma_1)
	assert(empty.get_margin(SIDE_LEFT) == Margin.ma_1)
	pass


## Accent-striped cards: the snackbar frames its text with a stripe on both edges, the desktop toast
## only marks the leading one.
func CardStyle_make_test() -> void:
	var snackbar := CardStyle.make(ColorBase.success, CardStyle.CORNER_RADIUS, Margin.ma_4, Margin.ma_3)
	assert(snackbar.bg_color == ColorCard.background_color)
	assert(snackbar.border_color == ColorBase.success)
	assert(snackbar.border_width_left == CardStyle.ACCENT_STRIPE_WIDTH)
	assert(snackbar.border_width_right == CardStyle.ACCENT_STRIPE_WIDTH)
	assert(snackbar.border_width_top == 0 and snackbar.border_width_bottom == 0)
	assert(snackbar.corner_radius_top_left == CardStyle.CORNER_RADIUS)
	assert(snackbar.get_margin(SIDE_LEFT) == Margin.ma_4 and snackbar.get_margin(SIDE_TOP) == Margin.ma_3)

	# Leading-edge stripe, square corners and a padding scaled by the app UI scale: the desktop toast card.
	var toast := CardStyle.make(ColorBase.error, 0, 10.0, 10.0, CardStyle.STRIPE_LEFT, roundi(CardStyle.ACCENT_STRIPE_WIDTH * 2.0))
	assert(toast.border_width_left == CardStyle.ACCENT_STRIPE_WIDTH * 2)
	assert(toast.border_width_right == 0)
	assert(toast.corner_radius_top_left == 0)
	assert(toast.get_margin(SIDE_RIGHT) == 10.0)
	pass


## The snackbar shadow is the one card value that cannot be a plain token: the same alpha over a dark
## surface and over a light one reads as either nothing or a smudge.
func Alert_card_shadow_test() -> void:
	var original: ThemeColor.ThemeEnum = ThemeColor.current_theme

	ThemeColor.current_theme = ThemeColor.ThemeEnum.DARK
	var dark := Alert.make_card_style(ColorBase.info)
	ThemeColor.current_theme = ThemeColor.ThemeEnum.LIGHT
	var light := Alert.make_card_style(ColorBase.info)
	assert(is_equal_approx(dark.shadow_color.a, Alert.shadow_alpha_dark))
	assert(is_equal_approx(light.shadow_color.a, Alert.shadow_alpha_light))
	assert(dark.shadow_color.a > light.shadow_color.a)
	assert(light.shadow_size == Alert.shadow_size)
	assert(light.shadow_offset == Alert.shadow_offset)

	ThemeColor.current_theme = original
	pass


## The card surfaces come from one place, so [Alert] and [DesktopToast] differ in where the stripe sits,
## not in surface, stripe width or radius.
func CardStyle_card_components_test() -> void:
	var snackbar := Alert.make_card_style(ColorBase.success)
	assert(snackbar.corner_radius_top_left == CardStyle.CORNER_RADIUS)
	assert(snackbar.border_width_left == CardStyle.ACCENT_STRIPE_WIDTH)
	assert(snackbar.shadow_size == Alert.shadow_size)

	DesktopToast.ui_scale = 1.0
	var toast: DesktopToast = DesktopToast.new()
	toast.accent = ColorBase.success
	toast.build_card()
	var toast_card: StyleBoxFlat = toast.card.get_theme_stylebox("panel") as StyleBoxFlat
	assert(toast_card.bg_color == snackbar.bg_color)
	assert(toast_card.border_color == snackbar.border_color)
	assert(toast_card.border_width_left == snackbar.border_width_left)
	assert(toast_card.border_width_right == 0)
	assert(toast_card.get_margin(SIDE_RIGHT) == Margin.ma_5)
	toast.free()
	pass


func BoxStyle_with_bg_test() -> void:
	var normal := BoxStyle.make(Color(0.2, 0.2, 0.2), 6, Margin.ma_2, Margin.ma_1, Color.WHITE, 1)
	var hover := BoxStyle.with_bg(normal, Color(0.3, 0.3, 0.3))
	assert(hover.bg_color == Color(0.3, 0.3, 0.3))
	assert(hover.border_color == normal.border_color and hover.get_margin(SIDE_LEFT) == Margin.ma_2)
	assert(hover.corner_radius_top_left == 6)
	assert(normal.bg_color == Color(0.2, 0.2, 0.2))
	pass


## A missed `hover_pressed` override resolves to the *default theme* box, not to `pressed`,
## so the helper has to set it. This is what that regression looked like.
func ButtonStyle_apply_states_test() -> void:
	var normal := BoxStyle.make(Color(0.2, 0.2, 0.2), 6, Margin.ma_2, Margin.ma_1, Color.WHITE, 1)
	var hover := BoxStyle.with_bg(normal, Color(0.3, 0.3, 0.3))
	var pressed := BoxStyle.with_bg(normal, Color(0.1, 0.1, 0.1))

	var button := Button.new()
	ButtonStyle.apply_states(button, normal, hover, pressed)
	assert(button.get_theme_stylebox("normal") == normal)
	assert(button.get_theme_stylebox("hover") == hover)
	assert(button.get_theme_stylebox("pressed") == pressed)
	assert((button.get_theme_stylebox("focus") as StyleBoxFlat).bg_color == hover.bg_color)
	assert((button.get_theme_stylebox("disabled") as StyleBoxFlat).bg_color == normal.bg_color)
	assert((button.get_theme_stylebox("hover_pressed") as StyleBoxFlat).bg_color == pressed.bg_color)

	var bare := Button.new()
	bare.add_theme_stylebox_override("pressed", pressed)
	assert(bare.get_theme_stylebox("hover_pressed") != pressed)

	button.free()
	bare.free()
	pass


## Same hole on the text side: the default theme paints focus and hover-pressed text near white,
## so a button that only overrides normal / hover / pressed goes blank on a light surface.
func ButtonStyle_apply_font_colors_test() -> void:
	var button := Button.new()
	ButtonStyle.apply_font_colors(button, Color.BLACK, Color.RED, Color.GREEN)
	assert(button.get_theme_color("font_color") == Color.BLACK)
	assert(button.get_theme_color("font_hover_color") == Color.RED)
	assert(button.get_theme_color("font_pressed_color") == Color.GREEN)
	assert(button.get_theme_color("font_focus_color") == Color.RED)
	assert(button.get_theme_color("font_hover_pressed_color") == Color.GREEN)
	assert(button.get_theme_color("font_disabled_color") == ButtonStyle.with_alpha(Color.BLACK, 0.5))
	button.free()
	pass
