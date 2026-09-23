class_name AgentSetting
extends RefCounted

## Toolbar UI for editing the persisted API connection settings.

const DIALOG_WIDTH := 580
const DIALOG_HEIGHT := 690
const SETTINGS_ICON_PATH := "res://agent/asset/image/icon/settings.svg"
const SVG_BASE_COLOR := "#8B949E"

var button: Button
var dialog: ConfirmationDialog
var content_panel: PanelContainer
var heading_label: Label
var description_label: Label
var provider_select: OptionButton
var api_url_edit: LineEdit
var model_edit: LineEdit
var api_token_edit: LineEdit
var proxy_address_edit: LineEdit
var token_visibility_button: Button
var field_labels: Array[Label] = []
var help_labels: Array[Label] = []


func setup(p_button: Button) -> void:
	button = p_button
	build_dialog()
	button.text = ""
	button.pressed.connect(on_button_pressed)
	button.mouse_entered.connect(on_button_mouse_entered)
	button.mouse_exited.connect(on_button_mouse_exited)
	gdf.events.theme_changed.connect(apply_theme)
	gdf.events.theme_color_changed.connect(apply_theme)
	apply_theme()
	pass


func build_dialog() -> void:
	dialog = ConfirmationDialog.new()
	dialog.title = ""
	dialog.ok_button_text = "Save"
	dialog.cancel_button_text = "Cancel"
	dialog.borderless = true
	dialog.min_size = Vector2i(DIALOG_WIDTH, DIALOG_HEIGHT)
	dialog.max_size = Vector2i(DIALOG_WIDTH, DIALOG_HEIGHT)
	dialog.unresizable = true
	dialog.exclusive = false
	dialog.confirmed.connect(on_confirmed)
	dialog.focus_exited.connect(on_dialog_focus_exited)
	button.add_child(dialog)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	dialog.add_child(margin)

	content_panel = PanelContainer.new()
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(content_panel)
	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 20)
	card_margin.add_theme_constant_override("margin_right", 20)
	card_margin.add_theme_constant_override("margin_top", 16)
	card_margin.add_theme_constant_override("margin_bottom", 16)
	content_panel.add_child(card_margin)

	var fields := VBoxContainer.new()
	fields.add_theme_constant_override("separation", 13)
	card_margin.add_child(fields)
	heading_label = Label.new()
	heading_label.text = "AI connection"
	heading_label.add_theme_font_size_override("font_size", 20)
	fields.add_child(heading_label)
	description_label = Label.new()
	description_label.text = "Configure the OpenAI-compatible service used by this agent."
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 12)
	fields.add_child(description_label)
	var separator := HSeparator.new()
	fields.add_child(separator)
	provider_select = add_provider_field(fields)
	api_url_edit = add_field(fields, "API endpoint", "https://api.example.com/v1/chat/completions", "Full chat-completions endpoint URL")
	model_edit = add_field(fields, "Model", ApiSetting.DEFAULT_MODEL, "Model sent with each request")
	api_token_edit = add_token_field(fields)
	api_token_edit.secret = true
	api_token_edit.secret_character = "*"
	proxy_address_edit = add_field(fields, "Proxy", "http://127.0.0.1:10809", "Optional HTTP/HTTPS proxy")
	pass


func add_provider_field(parent: VBoxContainer) -> OptionButton:
	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation", 7)
	parent.add_child(group)
	var label := Label.new()
	label.text = "Provider"
	label.add_theme_font_size_override("font_size", 13)
	field_labels.append(label)
	group.add_child(label)
	var select := OptionButton.new()
	select.custom_minimum_size = Vector2(0, 38)
	select.add_item(ApiSupport.CUSTOM_PROVIDER)
	for provider: ApiProvider in ApiSupport.PROVIDERS:
		select.add_item(provider.name)
	select.item_selected.connect(on_provider_selected)
	select.get_popup().popup_hide.connect(on_provider_popup_hide)
	group.add_child(select)
	var help := Label.new()
	help.text = "Selecting a provider fills the endpoint and recommended model"
	help.add_theme_font_size_override("font_size", 11)
	help_labels.append(help)
	group.add_child(help)
	return select


func add_field(parent: Container, label_text: String, placeholder: String, help_text: String) -> LineEdit:
	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation", 7)
	group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(group)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 13)
	field_labels.append(label)
	group.add_child(label)
	var edit := LineEdit.new()
	edit.custom_minimum_size = Vector2(0, 38)
	edit.placeholder_text = placeholder
	edit.clear_button_enabled = true
	group.add_child(edit)
	var help := Label.new()
	help.text = help_text
	help.add_theme_font_size_override("font_size", 11)
	help_labels.append(help)
	group.add_child(help)
	return edit


func add_token_field(parent: VBoxContainer) -> LineEdit:
	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation", 7)
	parent.add_child(group)
	var label := Label.new()
	label.text = "API token"
	label.add_theme_font_size_override("font_size", 13)
	field_labels.append(label)
	group.add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	group.add_child(row)
	var edit := LineEdit.new()
	edit.custom_minimum_size = Vector2(0, 38)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.placeholder_text = "sk-..."
	edit.clear_button_enabled = true
	row.add_child(edit)
	token_visibility_button = Button.new()
	token_visibility_button.custom_minimum_size = Vector2(64, 38)
	token_visibility_button.text = "Show"
	token_visibility_button.focus_mode = Control.FOCUS_NONE
	token_visibility_button.pressed.connect(on_token_visibility_pressed)
	row.add_child(token_visibility_button)
	var help := Label.new()
	help.text = "Stored locally in user://setting.config"
	help.add_theme_font_size_override("font_size", 11)
	help_labels.append(help)
	group.add_child(help)
	return edit


func on_button_pressed() -> void:
	api_url_edit.text = ApiSetting.get_api_url()
	model_edit.text = ApiSetting.get_model()
	provider_select.select(0)
	api_token_edit.text = ApiSetting.get_api_token()
	proxy_address_edit.text = ApiSetting.get_proxy_address()
	api_token_edit.secret = true
	token_visibility_button.text = "Show"
	var dialog_size := Vector2i(DIALOG_WIDTH, DIALOG_HEIGHT)
	dialog.popup_centered(dialog_size)
	dialog.size = dialog_size
	provider_select.grab_focus()
	pass


func on_provider_selected(selected_index: int) -> void:
	if selected_index <= 0:
		return
	var provider: ApiProvider = ApiSupport.get_provider(selected_index - 1)
	if provider == null:
		return
	api_url_edit.text = provider.api_url
	model_edit.text = provider.model
	pass


func on_dialog_focus_exited() -> void:
	check_dialog_focus.call_deferred()
	pass


func on_provider_popup_hide() -> void:
	check_dialog_focus.call_deferred()
	pass


func check_dialog_focus() -> void:
	if not dialog.visible or provider_select.get_popup().visible:
		return
	if not dialog.has_focus():
		dialog.hide()
	pass


func on_confirmed() -> void:
	ApiSetting.save(api_url_edit.text, api_token_edit.text, model_edit.text, proxy_address_edit.text)
	Alert.alert("AI settings saved", Colors.success)
	pass


func apply_theme() -> void:
	AgentToolbarButton.style(button, "AI settings", 14)
	button.custom_minimum_size = Vector2(28, 28)
	button.add_theme_constant_override("icon_max_width", 16)
	button.add_theme_constant_override("icon_max_height", 16)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	update_button_icon(button.is_hovered())
	style_dialog()
	pass


func update_button_icon(hovered: bool) -> void:
	var icon_color := AgentColors.toolbar_title if hovered else AgentColors.toolbar_muted
	button.icon = make_settings_icon(icon_color)
	pass


func make_settings_icon(color: Color) -> Texture2D:
	var svg := FileAccess.get_file_as_string(SETTINGS_ICON_PATH)
	svg = svg.replace(SVG_BASE_COLOR, "#" + color.to_html(false))
	var image := Image.new()
	var error := image.load_svg_from_string(svg, 2.0)
	if error != OK:
		return ImageTexture.new()
	return ImageTexture.create_from_image(image)


func on_button_mouse_entered() -> void:
	update_button_icon(true)
	pass


func on_button_mouse_exited() -> void:
	update_button_icon(false)
	pass


func style_dialog() -> void:
	if dialog == null:
		return
	var dialog_style := StyleBoxFlat.new()
	dialog_style.bg_color = AgentColors.panel
	dialog_style.set_corner_radius_all(0)
	dialog_style.expand_margin_right = 2.0
	dialog_style.expand_margin_bottom = 2.0
	dialog_style.content_margin_bottom = 14.0
	dialog.add_theme_stylebox_override("panel", dialog_style)
	dialog.add_theme_stylebox_override("embedded_border", StyleBoxEmpty.new())
	dialog.add_theme_stylebox_override("embedded_unfocused_border", StyleBoxEmpty.new())
	dialog.add_theme_constant_override("resize_margin", 0)
	dialog.add_theme_constant_override("buttons_min_width", 116)
	dialog.add_theme_constant_override("buttons_min_height", 44)
	dialog.add_theme_constant_override("buttons_separation", 16)
	content_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	heading_label.add_theme_color_override("font_color", AgentColors.chat_text)
	description_label.add_theme_color_override("font_color", AgentColors.chat_text_muted)
	for label: Label in field_labels:
		label.add_theme_color_override("font_color", AgentColors.chat_text)
	for help: Label in help_labels:
		help.add_theme_color_override("font_color", AgentColors.chat_text_muted)
	for edit: LineEdit in [api_url_edit, model_edit, api_token_edit, proxy_address_edit]:
		style_line_edit(edit)
	style_option_button(provider_select)
	style_secondary_button(token_visibility_button)
	style_secondary_button(dialog.get_cancel_button())
	style_primary_button(dialog.get_ok_button())
	pass


func style_option_button(select: OptionButton) -> void:
	select.add_theme_color_override("font_color", AgentColors.chat_text)
	select.add_theme_color_override("font_hover_color", AgentColors.chat_text)
	select.add_theme_color_override("font_pressed_color", AgentColors.chat_text)
	var normal := StyleBoxFlat.new()
	normal.bg_color = AgentColors.chat_input
	normal.border_color = AgentColors.chat_input_border
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(7)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = AgentColors.theme_accent_solid()
	select.add_theme_stylebox_override("normal", normal)
	select.add_theme_stylebox_override("hover", hover)
	select.add_theme_stylebox_override("pressed", hover.duplicate())
	select.add_theme_stylebox_override("focus", hover.duplicate())
	style_provider_popup(select.get_popup())
	pass


func style_provider_popup(popup: PopupMenu) -> void:
	popup.add_theme_color_override("font_color", AgentColors.chat_text)
	popup.add_theme_color_override("font_hover_color", AgentColors.chat_text)
	popup.add_theme_color_override("font_accelerator_color", AgentColors.chat_text_muted)
	popup.add_theme_color_override("font_disabled_color", AgentColors.chat_text_muted)
	popup.add_theme_color_override("font_separator_color", AgentColors.chat_text_muted)
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_constant_override("v_separation", 6)
	popup.add_theme_constant_override("item_start_padding", 12)
	popup.add_theme_constant_override("item_end_padding", 12)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = AgentColors.panel
	panel_style.border_color = AgentColors.chat_input_border
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(7)
	panel_style.content_margin_left = 4
	panel_style.content_margin_right = 4
	panel_style.content_margin_top = 5
	panel_style.content_margin_bottom = 5
	popup.add_theme_stylebox_override("panel", panel_style)
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = AgentColors.theme_selection_bg()
	hover_style.set_corner_radius_all(5)
	hover_style.content_margin_left = 8
	hover_style.content_margin_right = 8
	popup.add_theme_stylebox_override("hover", hover_style)
	var empty_icon := ImageTexture.new()
	popup.add_theme_icon_override("radio_checked", empty_icon)
	popup.add_theme_icon_override("radio_unchecked", empty_icon)
	popup.add_theme_icon_override("checked", empty_icon)
	popup.add_theme_icon_override("unchecked", empty_icon)
	pass


func style_line_edit(edit: LineEdit) -> void:
	edit.add_theme_color_override("font_color", AgentColors.chat_text)
	edit.add_theme_color_override("font_placeholder_color", AgentColors.chat_text_muted.darkened(0.08))
	edit.add_theme_color_override("caret_color", AgentColors.theme_accent_solid())
	var normal := StyleBoxFlat.new()
	normal.bg_color = AgentColors.chat_input
	normal.border_color = AgentColors.chat_input_border
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(7)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = AgentColors.theme_accent_solid()
	focus.set_border_width_all(2)
	edit.add_theme_stylebox_override("normal", normal)
	edit.add_theme_stylebox_override("focus", focus)
	edit.add_theme_stylebox_override("read_only", normal.duplicate())
	pass


func style_secondary_button(target: Button) -> void:
	target.add_theme_color_override("font_color", AgentColors.chat_text)
	var normal := StyleBoxFlat.new()
	normal.bg_color = AgentColors.toolbar_button
	normal.border_color = AgentColors.chat_input_border
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(7)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = AgentColors.sidebar_row_hover
	target.add_theme_stylebox_override("normal", normal)
	target.add_theme_stylebox_override("hover", hover)
	target.add_theme_stylebox_override("pressed", hover.duplicate())
	target.add_theme_stylebox_override("focus", hover.duplicate())
	pass


func style_primary_button(target: Button) -> void:
	target.add_theme_color_override("font_color", Color.WHITE)
	target.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = AgentColors.theme_accent_solid()
	normal.set_corner_radius_all(7)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = hover.bg_color.lightened(0.08)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = pressed.bg_color.darkened(0.08)
	target.add_theme_stylebox_override("normal", normal)
	target.add_theme_stylebox_override("hover", hover)
	target.add_theme_stylebox_override("pressed", pressed)
	target.add_theme_stylebox_override("focus", hover.duplicate())
	pass


func on_token_visibility_pressed() -> void:
	api_token_edit.secret = not api_token_edit.secret
	token_visibility_button.text = "Show" if api_token_edit.secret else "Hide"
	pass
