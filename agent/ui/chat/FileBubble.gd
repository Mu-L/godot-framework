class_name FileBubble
extends Object

## File-change result bubble with added/removed line counts.


static func append(chat_list: VBoxContainer, entry: ChatEntry, panel_style: StyleBoxFlat) -> RichTextLabel:
	var wrapper := PanelContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	wrapper.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var title_label := Label.new()
	title_label.text = entry.title
	title_label.add_theme_color_override("font_color", AgentColors.file_tool_title)
	title_label.add_theme_font_size_override("font_size", 12)
	header.add_child(title_label)

	var lines_added := int(entry.details.get(AgentToolResult.DETAIL_LINES_ADDED, "0"))
	var lines_removed := int(entry.details.get(AgentToolResult.DETAIL_LINES_REMOVED, "0"))
	if lines_added > 0:
		header.add_child(create_line_count_label(StringUtils.format("+{}", lines_added), AgentColors.success))
	if lines_removed > 0:
		header.add_child(create_line_count_label(StringUtils.format("-{}", lines_removed), AgentColors.error))
	vbox.add_child(header)

	var rich_text := ResultBubble.create_rich_text(entry.body)
	rich_text.meta_clicked.connect(open_file)
	rich_text.tooltip_text = "Open file"
	vbox.add_child(rich_text)
	wrapper.set_meta(AgentChatView.META_BUBBLE_RICH_TEXT, rich_text)

	chat_list.add_child(wrapper)
	refresh(rich_text, entry)
	return rich_text


static func refresh(rich_text: RichTextLabel, entry: ChatEntry) -> void:
	rich_text.clear()
	rich_text.push_meta(entry.body)
	rich_text.add_text(entry.body)
	rich_text.pop()
	rich_text.visible = StringUtils.is_not_blank(entry.body)
	pass


static func open_file(meta: Variant) -> void:
	var path := str(meta)
	if not FileAccess.file_exists(path):
		Alert.alert(StringUtils.format("File not found: {}", path), Colors.error)
		return
	var error := OS.shell_open(path)
	if error != OK:
		Alert.alert(StringUtils.format("Failed to open file: {}", path), Colors.error)
	pass


static func create_line_count_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 11)
	return label
