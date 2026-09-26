class_name SearchButton
extends RefCounted

## Searches persisted chat entry bodies and opens a result at its exact transcript bubble.

const DEFAULT_POPUP_SIZE := Vector2i(1080, 840)
const MIN_POPUP_SIZE := Vector2i(860, 680)
const MAX_POPUP_SIZE := Vector2i(1400, 1000)
const VIEWPORT_WIDTH_RATIO := 0.84
const VIEWPORT_HEIGHT_RATIO := 0.92
const MAX_RESULTS := 100
const MAX_SNIPPET_LENGTH := 260
## Typing pause before the scan runs — it walks every entry of every session, so per-keystroke is too heavy.
const SEARCH_DEBOUNCE_MILLIS := 1000
const SEARCH_ICON_PATH := "res://agent/asset/image/icon/search.svg"

var button: Button
var popup: Window
var popup_panel: PanelContainer
var query_edit: LineEdit
var status_label: Label
var results_scroll: ScrollContainer
var results_list: VBoxContainer
var debounce_timer: Timer


func setup(p_button: Button) -> void:
	button = p_button
	build_popup()
	button.pressed.connect(on_button_pressed)
	button.mouse_entered.connect(on_mouse_entered)
	button.mouse_exited.connect(on_mouse_exited)
	gdf.events.theme_changed.connect(apply_theme)
	gdf.events.theme_color_changed.connect(apply_theme)
	gdf.events.locale_changed.connect(apply_locale)
	apply_locale()
	pass


func build_popup() -> void:
	popup = Window.new()
	popup.size = DEFAULT_POPUP_SIZE
	popup.visible = false
	popup.transient = true
	popup.close_requested.connect(popup.hide)
	popup.focus_exited.connect(on_popup_focus_exited)
	popup.window_input.connect(on_popup_window_input)
	button.add_child(popup)
	popup_panel = PanelContainer.new()
	popup_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.add_child(popup_panel)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", Margin.ma_3)
	margin.add_theme_constant_override("margin_right", Margin.ma_3)
	margin.add_theme_constant_override("margin_top", Margin.ma_3)
	margin.add_theme_constant_override("margin_bottom", Margin.ma_3)
	popup_panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", Margin.ma_3)
	margin.add_child(content)
	query_edit = LineEdit.new()
	query_edit.custom_minimum_size = Vector2(0, 42)
	query_edit.clear_button_enabled = true
	query_edit.text_changed.connect(on_query_changed)
	query_edit.text_submitted.connect(on_query_submitted)
	content.add_child(query_edit)
	debounce_timer = Timer.new()
	debounce_timer.one_shot = true
	debounce_timer.wait_time = SEARCH_DEBOUNCE_MILLIS / float(TimeUtils.MILLIS_PER_SECOND)
	debounce_timer.timeout.connect(on_debounce_timeout)
	popup.add_child(debounce_timer)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", TextSize.label_small_size)
	content.add_child(status_label)
	results_scroll = ScrollContainer.new()
	results_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(results_scroll)
	results_list = VBoxContainer.new()
	results_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results_list.add_theme_constant_override("separation", Margin.ma_1)
	results_scroll.add_child(results_list)
	pass


func apply_theme() -> void:
	AgentToolbarButton.style_round(button, I18n.t("agent.search.tooltip"))
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.text = ""
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 16)
	button.add_theme_constant_override("icon_max_height", 16)
	update_icon(button.is_hovered())
	popup.add_theme_stylebox_override("embedded_border", make_embedded_border(PopupWindow.BORDER_ALPHA))
	popup.add_theme_stylebox_override("embedded_unfocused_border", make_embedded_border(PopupWindow.BORDER_ALPHA_UNFOCUSED))
	popup.add_theme_color_override("title_color", ThemeColor.title_color)
	popup.add_theme_font_override("title_font", Fonts.semibold())
	popup.add_theme_font_size_override("title_font_size", TextSize.title_medium_size)
	popup_panel.add_theme_stylebox_override("panel", make_content_style())
	status_label.add_theme_color_override("font_color", Color(ThemeColor.title_color, 0.62))
	ScrollBarStyle.apply(results_scroll.get_v_scroll_bar())
	style_query_edit()
	for child: Node in results_list.get_children():
		if child is Button:
			style_result_button(child as Button)
	pass


func apply_locale() -> void:
	popup.title = I18n.t("agent.search.title")
	query_edit.placeholder_text = I18n.t("agent.search.placeholder")
	if not query_edit.editable:
		status_label.text = I18n.t("agent.search.loading")
	elif StringUtils.is_blank(query_edit.text):
		status_label.text = I18n.t("agent.search.hint")
	apply_theme()
	pass


func on_button_pressed() -> void:
	popup.popup_centered(calculate_popup_size())
	query_edit.grab_focus()
	query_edit.select_all()
	if StringUtils.is_not_blank(query_edit.text):
		debounce_timer.stop()
		search(query_edit.text)
	pass


func on_mouse_entered() -> void:
	update_icon(true)
	pass


func on_mouse_exited() -> void:
	update_icon(false)
	pass


func update_icon(hovered: bool) -> void:
	button.icon = make_search_icon(ColorBase.primary_text if hovered else ColorBase.secondary_text)
	pass


func on_popup_window_input(event: InputEvent) -> void:
	if popup.visible and event.is_action_pressed("ui_cancel"):
		popup.hide()
		popup.set_input_as_handled()
	pass


func on_popup_focus_exited() -> void:
	if popup.visible:
		popup.hide()
	pass


## Restarts the pause on every keystroke, so a typing burst costs one scan instead of one per character.
func on_query_changed(raw_query: String) -> void:
	# An empty box has nothing to scan — answer at once instead of waiting out the pause.
	if StringUtils.is_blank(raw_query):
		debounce_timer.stop()
		search(raw_query)
		return
	debounce_timer.start()
	pass


func on_query_submitted(raw_query: String) -> void:
	debounce_timer.stop()
	search(raw_query)
	pass


func on_debounce_timeout() -> void:
	search(query_edit.text)
	pass


func calculate_popup_size() -> Vector2i:
	var viewport_size := Vector2i(button.get_viewport_rect().size)
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return DEFAULT_POPUP_SIZE
	var available := viewport_size - Vector2i(Margin.ma_8 * 2, Margin.ma_8 * 2)
	var target := Vector2i(
		int(viewport_size.x * VIEWPORT_WIDTH_RATIO),
		int(viewport_size.y * VIEWPORT_HEIGHT_RATIO)
	)
	target.x = clampi(target.x, mini(MIN_POPUP_SIZE.x, available.x), mini(MAX_POPUP_SIZE.x, available.x))
	target.y = clampi(target.y, mini(MIN_POPUP_SIZE.y, available.y), mini(MAX_POPUP_SIZE.y, available.y))
	return target


func search(raw_query: String) -> void:
	var query := raw_query.strip_edges().to_lower()
	if query.is_empty():
		clear_results()
		status_label.text = I18n.t("agent.search.hint")
		return
	var session_indexes := AgentSessionManager.session_indexes
	if session_indexes.size() == 0:
		clear_results()
		status_label.text = I18n.t("agent.search.empty")
		return
	var session_ids := session_indexes.collect_session_ids()
	# Returns at once on a warm cache; while it decodes, the read-only box keeps this the only search in
	# flight, and clearing afterwards drops rows an older search may have left behind.
	query_edit.editable = false
	status_label.text = I18n.t("agent.search.loading")
	await AgentSessionStore.async_load_sessions()
	query_edit.editable = true
	clear_results()
	var match_count := 0
	for session_id: int in session_ids:
		if match_count >= MAX_RESULTS:
			break
		var session := AgentSessionStore.load_session(session_id)
		if session == null:
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
	result.add_theme_font_override("font", Fonts.light())
	result.add_theme_font_size_override("font_size", TextSize.label_large_size)
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
	svg = svg.replace("#" + Color.WHITE.to_html(false), "#" + color.to_html(false))
	var image := Image.new()
	if image.load_svg_from_string(svg, 2.0) != OK:
		return ImageTexture.new()
	return ImageTexture.create_from_image(image)


func make_embedded_border(border_alpha: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = popup.get_theme_stylebox("embedded_border").duplicate() as StyleBoxFlat
	style.bg_color = ThemeColor.accent_surface
	style.set_corner_radius_all(ControlSize.radius_md)
	style.border_color = Color(ThemeColor.title_color, border_alpha)
	style.set_border_width_all(ControlSize.border_xs)
	return style


func make_content_style() -> StyleBoxFlat:
	var style := StyleBoxHelper.create_style_box_flat(ThemeColor.inset_surface, 0)
	return style


func style_query_edit() -> void:
	var normal := StyleBoxHelper.create_style_box_flat(ThemeColor.accent_surface, 8, Margin.ma_3, Margin.ma_2, Color(ThemeColor.title_color, PopupWindow.BORDER_ALPHA), ControlSize.border_xs)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = ThemeColor.accent_theme_color()
	focus.set_border_width_all(ControlSize.border_sm)
	query_edit.add_theme_stylebox_override("normal", normal)
	query_edit.add_theme_stylebox_override("focus", focus)
	query_edit.add_theme_color_override("font_color", ThemeColor.title_color)
	query_edit.add_theme_color_override("font_placeholder_color", Color(ThemeColor.title_color, 0.62))
	query_edit.add_theme_color_override("selection_color", ThemeColor.selection_color)
	pass


func style_result_button(result: Button) -> void:
	var normal := StyleBoxHelper.create_style_box_flat(ThemeColor.accent_surface, 8, Margin.ma_3, Margin.ma_2, Color(ThemeColor.title_color, PopupWindow.BORDER_ALPHA), ControlSize.border_xs)
	ButtonStyle.apply(result, normal,
		ButtonStyle.filled(normal, ThemeColor.accent_surface.lerp(ThemeColor.accent_theme_color(), 0.12), ThemeColor.accent_theme_color()),
		ButtonStyle.filled(normal, ThemeColor.selected_surface))
	ButtonStyle.apply_font_colors(result, ThemeColor.title_color, ThemeColor.title_color, ThemeColor.title_color)
	pass
