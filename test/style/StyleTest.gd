## Unit tests for [BoxStyle], [ButtonStyle] and the builders that go through them.

const GRAY := Color(0.5, 0.5, 0.5)


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
	var tinted := ButtonStyle.with_alpha(Colors.info, 0.45)
	# `Color` stores 32-bit floats, so compare approximately.
	assert(is_equal_approx(tinted.a, 0.45))
	assert(tinted.r == Colors.info.r and tinted.b == Colors.info.b)
	pass


func BoxStyle_make_test() -> void:
	var style := BoxStyle.make(Color(0.1, 0.2, 0.3), 8, Margin.ma_2, Margin.ma_1, Colors.info, 1)
	assert(style.bg_color == Color(0.1, 0.2, 0.3))
	assert(style.corner_radius_top_left == 8 and style.corner_radius_bottom_right == 8)
	assert(style.get_margin(SIDE_LEFT) == Margin.ma_2 and style.get_margin(SIDE_RIGHT) == Margin.ma_2)
	assert(style.get_margin(SIDE_TOP) == Margin.ma_1 and style.get_margin(SIDE_BOTTOM) == Margin.ma_1)
	assert(style.border_width_left == 1 and style.border_color == Colors.info)

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


## Every bubble header button goes through the helper, so all of them now carry six states.
func ChatBubble_buttons_have_all_states_test() -> void:
	var builders: Array[Callable] = [ThinkingBubble.style_view_button, ResultBubble.style_view_button, SkillBubble.style_expand_button, ErrorBubble.style_resume_button]
	for builder in builders:
		var button := Button.new()
		builder.call(button)
		for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			assert(button.has_theme_stylebox_override(state))
		var hover_pressed := button.get_theme_stylebox("hover_pressed") as StyleBoxFlat
		assert(hover_pressed.bg_color.a >= 0.0)
		button.free()
	pass


func ToolbarButton_states_test() -> void:
	var button := Button.new()
	AgentToolbarButton.style(button, "Log")
	var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
	assert(normal.bg_color == AgentColors.toolbar_button)
	assert(normal.border_color == AgentColors.toolbar_border)
	assert(normal.corner_radius_top_left == 6)
	assert(normal.get_margin(SIDE_LEFT) == Margin.ma_2)
	var hover_pressed := button.get_theme_stylebox("hover_pressed") as StyleBoxFlat
	assert(hover_pressed.bg_color != normal.bg_color)
	button.free()
	pass


func SessionSidebarTheme_row_test() -> void:
	assert(SessionSidebarTheme.row(true, false).bg_color == AgentColors.theme_selection_bg())
	assert(SessionSidebarTheme.row(false, true).bg_color == AgentColors.sidebar_row_hover)
	assert(SessionSidebarTheme.row(false, false).bg_color.a == 0.0)
	var style := SessionSidebarTheme.row(true, false)
	assert(style.get_margin(SIDE_LEFT) == Margin.ma_3 and style.get_margin(SIDE_RIGHT) == Margin.ma_1)
	assert(style.get_margin(SIDE_TOP) == Margin.ma_1 and style.get_margin(SIDE_BOTTOM) == Margin.ma_1)
	assert(style.corner_radius_top_left == SessionSidebarTheme.ROW_CORNER_RADIUS)
	pass


func SessionSidebarTheme_new_session_button_test() -> void:
	var button := Button.new()
	SessionSidebarTheme.apply_new_session_button(button)
	var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
	assert(normal.border_width_left == 1)
	assert(normal.border_color.a > 0.4)
	assert(button.has_theme_stylebox_override("hover_pressed"))
	button.free()
	pass


## [AgentColors] points each group of roles that share a tone at one local constant, so a tone
## tweak is one edit. These are the groups; if one of them drifts, the palette has two sources
## for the same color again.
func AgentColors_shared_tones_test() -> void:
	AgentColors.apply_light_palette()
	assert(AgentColors.sidebar == AgentColors.toolbar)
	assert(AgentColors.sidebar_border == AgentColors.toolbar_border)
	assert(AgentColors.toolbar_border == AgentColors.chat_bubble_border)
	assert(AgentColors.chat_bubble_border == AgentColors.chat_input_border)
	assert(AgentColors.sidebar_title == AgentColors.sidebar_muted)
	assert(AgentColors.sidebar_muted == AgentColors.toolbar_muted)
	assert(AgentColors.toolbar_muted == AgentColors.chat_text_muted)
	assert(AgentColors.sidebar_text == AgentColors.toolbar_title)
	assert(AgentColors.toolbar_title == AgentColors.chat_text)
	assert(AgentColors.sidebar_row_selected == AgentColors.chat_input)
	assert(AgentColors.chat_input == AgentColors.panel)
	assert(AgentColors.panel == AgentColors.assistant_bubble)
	assert(AgentColors.toolbar_button == AgentColors.system_bubble)
	assert(AgentColors.system_bubble == AgentColors.result_bubble)
	assert(AgentColors.accent == AgentColors.sidebar_row_accent)

	AgentColors.apply_dark_palette()
	assert(AgentColors.sidebar_text == AgentColors.chat_text)
	assert(AgentColors.sidebar_muted == AgentColors.chat_text_muted)
	assert(AgentColors.sidebar_row_hover == AgentColors.chat_input)
	assert(AgentColors.chat_input == AgentColors.panel)
	assert(AgentColors.sidebar_row_selected == AgentColors.assistant_bubble)
	assert(AgentColors.chat_bubble_border == AgentColors.chat_input_border)
	assert(AgentColors.accent == AgentColors.sidebar_row_accent)

	# Leave the palette as the rest of the suite expects to find it.
	AgentColors.load_saved_theme()
	pass
