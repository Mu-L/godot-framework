## Unit tests for the agent-side style classes: [AgentColors], [SessionSidebarTheme], the toolbar button,
## the chat-bubble header buttons and the chat input's text colors.
## Loaded by [code]test/agent/AgentStyleTest.tscn[/code] ([UnitTest]).


## Caret and highlight of the chat input follow the theme color, the same pair the bubbles and
## the sidebar rename field use ([ThemeColorCard]); the engine default would be a fixed green.
func AgentChatInput_text_colors_follow_theme_test() -> void:
	var input := AgentChatInput.new()
	input.input_field = TextEdit.new()
	input.style_field()
	assert(input.input_field.get_theme_color("caret_color") == AgentColors.theme_accent_solid())
	assert(input.input_field.get_theme_color("selection_color") == ColorCard.selection_color)
	assert(input.input_field.get_theme_color("font_selected_color") == ColorCard.title_color)
	input.input_field.free()
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
	assert(AgentColors.chat == ColorBase.LIGHT_BACKGROUND)
	assert(AgentColors.chat_text == ColorBase.LIGHT_TEXT)
	assert(AgentColors.chat_text_muted == ColorBase.LIGHT_MUTED)
	assert(AgentColors.panel == ColorBase.LIGHT_SURFACE)
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

	AgentColors.apply_dark_palette()
	assert(AgentColors.chat == ColorBase.DARK_BACKGROUND)
	assert(AgentColors.chat_text == ColorBase.DARK_TEXT)
	assert(AgentColors.chat_text_muted == ColorBase.DARK_MUTED)
	assert(AgentColors.panel == ColorBase.DARK_SURFACE)
	assert(AgentColors.sidebar_text == AgentColors.chat_text)
	assert(AgentColors.sidebar_muted == AgentColors.chat_text_muted)
	assert(AgentColors.sidebar_row_hover == AgentColors.chat_input)
	assert(AgentColors.chat_input == AgentColors.panel)
	assert(AgentColors.sidebar_row_selected == AgentColors.assistant_bubble)
	assert(AgentColors.chat_bubble_border == AgentColors.chat_input_border)

	# Leave the palette as the rest of the suite expects to find it.
	AgentColors.load_saved_theme()
	pass
