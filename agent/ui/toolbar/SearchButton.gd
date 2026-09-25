class_name SearchButton
extends RefCounted

## Searches persisted chat entry bodies and opens a result at its exact transcript bubble.

const DEFAULT_POPUP_SIZE := Vector2i(1080, 840)
const MIN_POPUP_SIZE := Vector2i(860, 680)
const MAX_POPUP_SIZE := Vector2i(1400, 1000)
const VIEWPORT_WIDTH_RATIO := 0.84
const VIEWPORT_HEIGHT_RATIO := 0.92
const VIEWPORT_MARGIN := 32
const BUTTON_SIZE := 28
const MAX_RESULTS := 100
const MAX_SNIPPET_LENGTH := 260
const SEARCH_ICON_PATH := "res://agent/asset/image/icon/search.svg"
const SVG_ICON_COLOR := "#8B949E"

var button: Button
var popup: PopupPanel
var title_label: Label
var query_edit: LineEdit
var status_label: Label
var results_list: VBoxContainer


func setup(p_button: Button) -> void:
	button = p_button
	build_popup()
	button.pressed.connect(on_button_pressed)
	gdf.events.theme_changed.connect(apply_theme)
	gdf.events.theme_color_changed.connect(apply_theme)
	gdf.events.locale_changed.connect(apply_locale)
	apply_locale()
	pass


func build_popup() -> void:
	popup = PopupPanel.new()
	popup.size = DEFAULT_POPUP_SIZE
	button.add_child(popup)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", Margin.ma_3)
	margin.add_theme_constant_override("margin_right", Margin.ma_3)
	margin.add_theme_constant_override("margin_top", Margin.ma_3)
	margin.add_theme_constant_override("margin_bottom", Margin.ma_3)
	popup.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", Margin.ma_3)
	margin.add_child(content)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", Margin.ma_2)
	content.add_child(header)
	var header_icon := TextureRect.new()
	header_icon.custom_minimum_size = Vector2(22, 22)
	header_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	header_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_icon.texture = make_search_icon(ColorBase.text)
	header.add_child(header_icon)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", TextStyle.title_medium_size)
	header.add_child(title_label)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.flat = true
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.custom_minimum_size = Vector2(28, 28)
	close_button.pressed.connect(popup.hide)
	header.add_child(close_button)
	query_edit = LineEdit.new()
	query_edit.custom_minimum_size = Vector2(0, 42)
	query_edit.clear_button_enabled = true
	query_edit.text_changed.connect(search)
	content.add_child(query_edit)
	status_label = Label.new()
	status_label.add_theme_color_override("font_color", ColorBase.muted)
	status_label.add_theme_font_size_override("font_size", TextStyle.label_small_size)
	content.add_child(status_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	results_list = VBoxContainer.new()
	results_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results_list.add_theme_constant_override("separation", Margin.ma_1)
	scroll.add_child(results_list)
	pass


func apply_theme() -> void:
	AgentToolbarButton.style(button, I18n.t("agent.search.tooltip"), BUTTON_SIZE / 2)
	button.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.text = ""
	button.icon = make_search_icon(ColorBase.muted)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 16)
	button.add_theme_constant_override("icon_max_height", 16)
	popup.add_theme_stylebox_override("panel", make_popup_style())
	style_query_edit()
	pass


func apply_locale() -> void:
	title_label.text = I18n.t("agent.search.title")
	query_edit.placeholder_text = I18n.t("agent.search.placeholder")
	if StringUtils.is_blank(query_edit.text):
		status_label.text = I18n.t("agent.search.hint")
	apply_theme()
	pass


func on_button_pressed() -> void:
	popup.popup_centered(calculate_popup_size())
	query_edit.grab_focus()
	query_edit.select_all()
	if StringUtils.is_not_blank(query_edit.text):
		search(query_edit.text)
	pass


func calculate_popup_size() -> Vector2i:
	var viewport_size := Vector2i(button.get_viewport_rect().size)
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return DEFAULT_POPUP_SIZE
	var available := viewport_size - Vector2i(VIEWPORT_MARGIN * 2, VIEWPORT_MARGIN * 2)
	var target := Vector2i(
		int(viewport_size.x * VIEWPORT_WIDTH_RATIO),
		int(viewport_size.y * VIEWPORT_HEIGHT_RATIO)
	)
	target.x = clampi(target.x, mini(MIN_POPUP_SIZE.x, available.x), mini(MAX_POPUP_SIZE.x, available.x))
	target.y = clampi(target.y, mini(MIN_POPUP_SIZE.y, available.y), mini(MAX_POPUP_SIZE.y, available.y))
	return target


func search(raw_query: String) -> void:
	clear_results()
	var query := raw_query.strip_edges().to_lower()
	if query.is_empty():
		status_label.text = I18n.t("agent.search.hint")
		return
	var match_count := 0
	var dir_path := AgentSessionStore.get_sessions_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		status_label.text = I18n.t("agent.search.empty")
		return
	var file_paths := FileUtils.get_all_files_in_folder(dir_path, false)
	for file_path: String in file_paths:
		if match_count >= MAX_RESULTS:
			break
		if not file_path.ends_with(AgentSessionStore.FILE_SUFFIX) or file_path.get_file() == AgentSessionIndexes.INDEX_FILE:
			continue
		var session := AgentSessionStore.load_session_file(file_path)
		if session == null or not AgentSessionManager.has_index(session.id):
			continue
		for entry_index: int in session.chat_entries.size():
			var entry: ChatEntry = session.chat_entries[entry_index]
			if query not in entry.body.to_lower():
				continue
			append_result(session.id, entry_index, entry, query)
			match_count += 1
			if match_count >= MAX_RESULTS:
				break
	var result_key := "agent.search.limited_results" if match_count >= MAX_RESULTS else "agent.search.results"
	status_label.text = StringUtils.format(I18n.t(result_key), match_count)
	pass


func append_result(session_id: int, entry_index: int, entry: ChatEntry, query: String) -> void:
	var result := Button.new()
	result.alignment = HORIZONTAL_ALIGNMENT_LEFT
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.text = StringUtils.format(
		"{}  -  {}\n{}",
		AgentSessionManager.get_title(session_id),
		entry.title,
		make_snippet(entry.body, query)
	)
	result.custom_minimum_size = Vector2(0, 72)
	result.add_theme_font_size_override("font_size", TextStyle.label_medium_size)
	style_result_button(result)
	result.pressed.connect(on_result_pressed.bind(session_id, entry_index))
	results_list.add_child(result)
	pass


func make_snippet(body: String, query: String) -> String:
	var one_line := body.replace("\r", " ").replace("\n", " ").replace("\t", " ").strip_edges()
	var match_index := one_line.to_lower().find(query)
	var start := maxi(0, match_index - 48)
	var snippet := one_line.substr(start, MAX_SNIPPET_LENGTH)
	if start > 0:
		snippet = "..." + snippet
	if start + MAX_SNIPPET_LENGTH < one_line.length():
		snippet += "..."
	return snippet


func on_result_pressed(session_id: int, entry_index: int) -> void:
	popup.hide()
	if not AgentSessionManager.is_active(session_id):
		AgentSessionManager.select_session(session_id)
	AgentEvents.events.chat_search_result_selected.emit(session_id, entry_index)
	pass


func clear_results() -> void:
	for child: Node in results_list.get_children():
		child.queue_free()
	pass


func make_search_icon(color: Color) -> ImageTexture:
	var svg := FileAccess.get_file_as_string(SEARCH_ICON_PATH)
	svg = svg.replace(SVG_ICON_COLOR, "#" + color.to_html(false))
	var image := Image.new()
	if image.load_svg_from_string(svg, 2.0) != OK:
		return ImageTexture.new()
	return ImageTexture.create_from_image(image)


func make_popup_style() -> StyleBoxFlat:
	var style := BoxStyle.make(ColorBase.background, 12, Margin.ma_4, Margin.ma_4, ColorBase.border, 1)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


func style_query_edit() -> void:
	var normal := BoxStyle.make(ColorBase.control_surface, 8, Margin.ma_3, Margin.ma_2, ColorBase.subtle_border, 1)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = ThemeColor.theme_color_full_alpha()
	focus.set_border_width_all(2)
	query_edit.add_theme_stylebox_override("normal", normal)
	query_edit.add_theme_stylebox_override("focus", focus)
	query_edit.add_theme_color_override("font_color", ColorBase.text)
	query_edit.add_theme_color_override("font_placeholder_color", ColorBase.muted)
	pass


func style_result_button(result: Button) -> void:
	var normal := BoxStyle.make(ColorBase.surface, 8, Margin.ma_3, Margin.ma_2, ColorBase.subtle_border, 1)
	var hover := BoxStyle.with_bg(normal, ColorBase.hover_surface)
	hover.border_color = ThemeColor.theme_color_full_alpha()
	var pressed := BoxStyle.with_bg(normal, ColorBase.selection_surface)
	ButtonStyle.apply_states(result, normal, hover, pressed)
	ButtonStyle.apply_font_colors(result, ColorBase.text, ColorBase.text, ColorBase.text)
	pass
