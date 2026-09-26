## Unit tests for the agent-side style classes: [SessionSidebarTheme], the toolbar button,
## the chat-bubble header buttons and the chat input's text colors.
## Loaded by [code]test/agent/AgentStyleTest.tscn[/code] ([UnitTest]).


## Caret and highlight of the chat input follow the theme color, the same pair the bubbles and
## the sidebar rename field use ([ThemeColor]); the engine default would be a fixed green.
func AgentChatInput_text_colors_follow_theme_test() -> void:
	var input := AgentChatInput.new()
	input.input_field = TextEdit.new()
	input.style_field()
	assert(input.input_field.get_theme_color("caret_color") == ThemeColor.accent_theme_color())
	assert(input.input_field.get_theme_color("selection_color") == ThemeColor.selection_color)
	assert(input.input_field.get_theme_color("font_selected_color") == ThemeColor.title_color)
	input.input_field.free()
	pass


## The shared scrollbar style supplies the popup, transcript and session sidebar palette.
func ScrollBarStyle_apply_test() -> void:
	var scroll := ScrollContainer.new()
	var bar := scroll.get_v_scroll_bar()
	ScrollBarStyle.apply(bar)
	assert((bar.get_theme_stylebox("scroll") as StyleBoxFlat).bg_color.a == 0.0)
	assert((bar.get_theme_stylebox("grabber") as StyleBoxFlat).bg_color == ThemeColor.body_color)
	assert((bar.get_theme_stylebox("grabber") as StyleBoxFlat).get_minimum_size().x == ScrollBarStyle.THICKNESS)
	assert((bar.get_theme_stylebox("grabber_highlight") as StyleBoxFlat).bg_color == ThemeColor.accent_theme_color())
	assert((bar.get_theme_stylebox("grabber_pressed") as StyleBoxFlat).bg_color == ThemeColor.accent_theme_color())
	scroll.free()
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
	assert(normal.bg_color == ColorBase.control_surface)
	assert(normal.border_color == ColorBase.subtle_border)
	assert(normal.corner_radius_top_left == 6)
	assert(normal.get_margin(SIDE_LEFT) == Margin.ma_2)
	var hover_pressed := button.get_theme_stylebox("hover_pressed") as StyleBoxFlat
	assert(hover_pressed.bg_color != normal.bg_color)
	button.free()
	pass


func SessionSidebarTheme_row_test() -> void:
	assert(SessionSidebarTheme.row(true, false).bg_color == ThemeColor.selected_surface)
	assert(SessionSidebarTheme.row(false, true).bg_color == ColorBase.hover_surface)
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


## Shared neutral and semantic surface roles all follow the active theme through [ColorBase].
func ColorBase_shared_tones_test() -> void:
	var original := ThemeColor.current_theme
	ThemeColor.current_theme = ThemeColor.ThemeEnum.LIGHT
	ColorBase.refresh()
	assert(ColorBase.app_background == ColorBase.LIGHT_BACKGROUND)
	assert(ColorBase.text == ColorBase.LIGHT_TEXT)
	assert(ColorBase.muted == ColorBase.LIGHT_MUTED)
	assert(ColorBase.surface == ColorBase.LIGHT_SURFACE)
	assert(ColorBase.chrome_surface != ColorBase.deep_surface)
	assert(ColorBase.deep_surface.get_luminance() < ColorBase.chrome_surface.get_luminance())
	assert(ColorBase.hover_surface.get_luminance() < ColorBase.chrome_surface.get_luminance())
	assert(ColorBase.hover_surface.get_luminance() < ColorBase.control_surface.get_luminance())
	assert(ColorBase.border.get_luminance() < ColorBase.muted_border.get_luminance())
	assert(ColorBase.muted_border.get_luminance() < ColorBase.subtle_border.get_luminance())
	assert(ColorBase.elevated_surface == ColorBase.surface)
	assert(ColorBase.control_surface != ColorBase.info_surface)
	assert(ColorBase.info_surface != ColorBase.neutral_surface)
	assert(ColorBase.strong_info_surface != ColorBase.info_surface)
	assert(ColorBase.strong_info_surface.b - ColorBase.strong_info_surface.r > ColorBase.info_surface.b - ColorBase.info_surface.r)

	ThemeColor.current_theme = ThemeColor.ThemeEnum.DARK
	ColorBase.refresh()
	assert(ColorBase.app_background == ColorBase.DARK_BACKGROUND)
	assert(ColorBase.text == ColorBase.DARK_TEXT)
	assert(ColorBase.muted == ColorBase.DARK_MUTED)
	assert(ColorBase.surface == ColorBase.DARK_SURFACE)
	assert(ColorBase.hover_surface == ColorBase.surface)
	assert(ColorBase.elevated_surface != ColorBase.surface)

	# Leave the palette as the rest of the suite expects to find it.
	ThemeColor.current_theme = original
	ColorBase.refresh()
	pass
