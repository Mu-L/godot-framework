class_name AgentBubble
extends Object

## Agent reply bubble — markdown body; header copy puts ChatEntry.body on the clipboard.


static func append(
	chat_list: VBoxContainer,
	entry: ChatEntry,
	panel_style: StyleBoxFlat,
	text_color: Color,
	title_color: Color = AgentColors.chat_text_muted
) -> RichTextLabel:
	var wrapper: PanelContainer = PanelContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_theme_stylebox_override("panel", panel_style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", Margin.ma_2)
	wrapper.add_child(vbox)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", Margin.ma_2)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var title_label: Label = Label.new()
	title_label.text = entry.title
	title_label.add_theme_color_override("font_color", title_color)
	title_label.add_theme_font_size_override("font_size", TextStyle.label_medium_size)
	header.add_child(title_label)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(spacer)

	var copy_button: Button = Button.new()
	copy_button.text = "Copy"
	style_copy_button(copy_button, panel_style.bg_color)
	copy_button.pressed.connect(on_copy_pressed.bind(entry))
	header.add_child(copy_button)

	vbox.add_child(header)

	var rich_text: RichTextLabel = MarkdownUtils.create_rich_text_label(
		text_color,
		entry.body,
		MarkdownToggle.markdown_enabled_for_entry(entry)
	)
	rich_text.visible = StringUtils.is_not_blank(entry.body)
	vbox.add_child(rich_text)
	wrapper.set_meta(AgentChatView.META_BUBBLE_RICH_TEXT, rich_text)

	chat_list.add_child(wrapper)
	return rich_text


static func on_copy_pressed(entry: ChatEntry) -> void:
	if entry == null or StringUtils.is_blank(entry.body):
		return
	MarkdownUtils.copy_to_clipboard(entry.body)
	Alert.alert("Copied", Colors.success)
	pass


static func style_copy_button(button: Button, bubble_bg: Color) -> void:
	style_header_button(button, bubble_bg, "Copy message", 40.0)
	pass


## Header actions (Copy / Delete / Revert) are tinted with the user accent, so picking a new
## theme color re-renders them with the transcript (see AgentChatView.on_theme_color_changed).
static func style_header_button(button: Button, bubble_bg: Color, tooltip: String, min_width: float) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(min_width, 18)
	button.add_theme_font_size_override("font_size", TextStyle.label_small_size)

	var accent: Color = AgentColors.theme_accent_solid()
	ButtonStyle.apply_font_colors(button, accent, ButtonStyle.hover_color(accent, 0.12), ButtonStyle.press_color(accent, 0.10))

	var normal := BoxStyle.make(ButtonStyle.hover_color(bubble_bg, 0.08), 4, Margin.ma_2, Margin.ma_0, ButtonStyle.with_alpha(accent, 0.45), 1)
	var hover := BoxStyle.with_bg(normal, AgentColors.theme_selection_bg())
	hover.border_color = ButtonStyle.with_alpha(accent, 0.85)
	var pressed := BoxStyle.with_bg(hover, ButtonStyle.hover_color(AgentColors.theme_selection_bg(), 0.06))
	pressed.border_color = accent
	ButtonStyle.apply_states(button, normal, hover, pressed)
	pass
