class_name AgentSetting
extends RefCounted

## Toolbar UI for editing the persisted API connection and notification settings.
## There is no Save button: every field writes straight to [Setting] once editing finishes.

const DIALOG_WIDTH := 580
const DIALOG_HEIGHT := 830
const FOLDER_DIALOG_SIZE := Vector2i(900, 600)
const SETTINGS_ICON_PATH := "res://agent/asset/image/icon/settings.svg"
const SVG_BASE_COLOR := "#8B949E"
## Gap between the description label and its toggle, and between the two toggles.
const LABEL_GAP := 8
const TOGGLE_GAP := 16

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
var toast_toggle_button: CheckButton
var sound_toggle_button: CheckButton
var sound_seconds_group: HBoxContainer
var sound_folder_row: HBoxContainer
var sound_seconds_spin: SpinBox
var sound_folder_edit: LineEdit
var sound_folder_dialog: FileDialog
## True once the path was edited by hand, so a click no longer means "pick a folder".
var folder_field_typing := false
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
	dialog.borderless = true
	dialog.min_size = Vector2i(DIALOG_WIDTH, DIALOG_HEIGHT)
	dialog.max_size = Vector2i(DIALOG_WIDTH, DIALOG_HEIGHT)
	dialog.unresizable = true
	dialog.exclusive = false
	dialog.focus_exited.connect(on_dialog_focus_exited)
	dialog.visibility_changed.connect(on_dialog_visibility_changed)
	button.add_child(dialog)
	# Every field auto-saves, so the default OK / Cancel row would only be noise.
	dialog.get_ok_button().hide()
	dialog.get_cancel_button().hide()

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

	# The rows outgrow a short window, so keep them reachable instead of clipping the last one.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_margin.add_child(scroll)

	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_theme_constant_override("separation", 13)
	scroll.add_child(fields)
	heading_label = Label.new()
	heading_label.text = "AI connection"
	heading_label.add_theme_font_size_override("font_size", 20)
	fields.add_child(heading_label)
	description_label = Label.new()
	description_label.text = "Configure the OpenAI-compatible service and the run notifications."
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
	for edit: LineEdit in [api_url_edit, model_edit, api_token_edit, proxy_address_edit]:
		bind_auto_save(edit, save_api_settings)
	fields.add_child(HSeparator.new())
	add_notify_fields(fields)
	fields.add_child(HSeparator.new())
	build_folder_dialog()
	pass


## Notification options, one row each, every row hugging the left edge: the toast toggle, the
## sound toggle with its duration, then the clip folder. Duration and folder hide with the sound.
func add_notify_fields(parent: VBoxContainer) -> void:
	toast_toggle_button = add_check_button(make_option_row(parent, LABEL_GAP), "Agent end Notification Window", AgentNotifySetting.is_toast_enabled())
	toast_toggle_button.toggled.connect(on_toast_toggled)

	var sound_row := make_option_row(parent, TOGGLE_GAP)
	sound_toggle_button = add_check_button(sound_row, "Notification Sound", AgentNotifySetting.is_sound_enabled())
	sound_toggle_button.toggled.connect(on_sound_toggled)
	sound_seconds_group = add_sound_seconds_group(sound_row)

	sound_folder_row = make_option_row(parent, LABEL_GAP)
	sound_folder_edit = LineEdit.new()
	sound_folder_edit.custom_minimum_size = Vector2(0, 34)
	sound_folder_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sound_folder_edit.placeholder_text = AgentNotifySetting.DEFAULT_SOUND_FOLDER
	sound_folder_edit.text = AgentNotifySetting.get_sound_folder()
	sound_folder_edit.tooltip_text = "Select a folder with musics to play notification sound when agent end."
	sound_folder_edit.gui_input.connect(on_sound_folder_input)
	sound_folder_edit.text_changed.connect(on_sound_folder_text_changed)
	sound_folder_row.add_child(sound_folder_edit)
	bind_auto_save(sound_folder_edit, save_sound_folder)

	update_sound_options_visible(AgentNotifySetting.is_sound_enabled())
	pass


## Sound length, saved on every step.
func add_sound_seconds_group(parent: HBoxContainer) -> HBoxContainer:
	var group := make_option_row(parent, LABEL_GAP)
	group.add_child(make_option_label("Sound Duration"))
	sound_seconds_spin = SpinBox.new()
	sound_seconds_spin.min_value = AgentNotifySetting.MIN_SOUND_SECONDS
	sound_seconds_spin.max_value = AgentNotifySetting.MAX_SOUND_SECONDS
	sound_seconds_spin.step = 1
	sound_seconds_spin.suffix = " s"
	sound_seconds_spin.custom_minimum_size = Vector2(104, 34)
	sound_seconds_spin.value = AgentNotifySetting.get_sound_seconds()
	sound_seconds_spin.value_changed.connect(on_sound_seconds_changed)
	group.add_child(sound_seconds_spin)
	return group


## Options row with its own gap: label-to-control and group-to-group gaps differ.
func make_option_row(parent: Container, separation: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", separation)
	parent.add_child(row)
	return row


## Folder picker behind the path field — no Browse button, clicking the field opens it.
func build_folder_dialog() -> void:
	sound_folder_dialog = FileDialog.new()
	sound_folder_dialog.title = "Select the notification sound folder"
	sound_folder_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	sound_folder_dialog.access = FileDialog.ACCESS_FILESYSTEM
	sound_folder_dialog.ok_button_text = "Select"
	sound_folder_dialog.size = FOLDER_DIALOG_SIZE
	sound_folder_dialog.dir_selected.connect(on_sound_folder_selected)
	dialog.add_child(sound_folder_dialog)
	pass


func make_option_label(label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	field_labels.append(label)
	return label


## Persist a line edit as soon as the user leaves it or presses Enter.
func bind_auto_save(edit: LineEdit, saver: Callable) -> void:
	edit.focus_exited.connect(saver)
	edit.text_submitted.connect(func(_text: String) -> void: saver.call())
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


## Check button with the accent-tinted switch: on / off is the switch itself, no On / Off caption.
func add_check_button(parent: Container, label_text: String, enabled: bool) -> CheckButton:
	var check := CheckButton.new()
	check.text = label_text
	check.button_pressed = enabled
	check.focus_mode = Control.FOCUS_NONE
	check.add_theme_font_size_override("font_size", 13)
	parent.add_child(check)
	return check


## Check button: the switch is the built-in toggle icon, tinted with the CheckButton theme colors.
func style_check_button(check: CheckButton) -> void:
	check.add_theme_color_override("font_color", AgentColors.chat_text)
	check.add_theme_color_override("font_hover_color", AgentColors.chat_text)
	check.add_theme_color_override("font_focus_color", AgentColors.chat_text)
	check.add_theme_color_override("font_pressed_color", AgentColors.chat_text)
	check.add_theme_color_override("font_hover_pressed_color", AgentColors.chat_text)
	# Only the "on" track takes the app accent — the "off" one keeps the theme default.
	check.add_theme_color_override("button_checked_color", AgentColors.theme_accent_solid())
	check.add_theme_constant_override("h_separation", 8)
	# No left inset, so the caption lines up with the labels and fields around it. The margins are
	# the same on every state, otherwise hovering would shift the row.
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 0
	empty.content_margin_right = 6
	empty.content_margin_top = 4
	empty.content_margin_bottom = 4
	var hover := StyleBoxFlat.new()
	hover.bg_color = AgentColors.sidebar_row_hover
	hover.set_corner_radius_all(6)
	hover.content_margin_left = 0
	hover.content_margin_right = 6
	hover.content_margin_top = 4
	hover.content_margin_bottom = 4
	check.add_theme_stylebox_override("normal", empty)
	check.add_theme_stylebox_override("disabled", empty.duplicate())
	check.add_theme_stylebox_override("focus", empty.duplicate())
	check.add_theme_stylebox_override("hover", hover)
	check.add_theme_stylebox_override("pressed", hover.duplicate())
	check.add_theme_stylebox_override("hover_pressed", hover.duplicate())
	pass


## Duration and clip folder only matter while the sound toggle is on: hiding the whole folder row
## drops its gap too, so the block collapses onto the two toggles.
func update_sound_options_visible(enabled: bool) -> void:
	sound_seconds_group.visible = enabled
	sound_folder_row.visible = enabled
	pass


func on_button_pressed() -> void:
	api_url_edit.text = ApiSetting.get_api_url()
	model_edit.text = ApiSetting.get_model()
	provider_select.select(0)
	api_token_edit.text = ApiSetting.get_api_token()
	proxy_address_edit.text = ApiSetting.get_proxy_address()
	api_token_edit.secret = true
	token_visibility_button.text = "Show"
	toast_toggle_button.set_block_signals(true)
	toast_toggle_button.button_pressed = AgentNotifySetting.is_toast_enabled()
	toast_toggle_button.set_block_signals(false)
	sound_toggle_button.set_block_signals(true)
	sound_toggle_button.button_pressed = AgentNotifySetting.is_sound_enabled()
	sound_toggle_button.set_block_signals(false)
	update_sound_options_visible(sound_toggle_button.button_pressed)
	sound_seconds_spin.set_value_no_signal(AgentNotifySetting.get_sound_seconds())
	sound_folder_edit.text = AgentNotifySetting.get_sound_folder()
	folder_field_typing = false
	var dialog_size := Vector2i(DIALOG_WIDTH, DIALOG_HEIGHT)
	dialog.popup_centered(dialog_size)
	dialog.size = dialog_size
	# Deferred: the hidden OK button grabs focus while the dialog pops up.
	provider_select.grab_focus.call_deferred()
	pass


func on_provider_selected(selected_index: int) -> void:
	if selected_index <= 0:
		return
	var provider: ApiProvider = ApiSupport.get_provider(selected_index - 1)
	if provider == null:
		return
	api_url_edit.text = provider.api_url
	model_edit.text = provider.model
	save_api_settings()
	pass


func on_toast_toggled(enabled: bool) -> void:
	AgentNotifySetting.set_toast_enabled(enabled)
	pass


func on_sound_toggled(enabled: bool) -> void:
	AgentNotifySetting.set_sound_enabled(enabled)
	update_sound_options_visible(enabled)
	pass


func on_sound_seconds_changed(seconds: float) -> void:
	AgentNotifySetting.set_sound_seconds(roundi(seconds))
	pass


## A click on the path field opens the folder picker, until the path itself is being typed:
## after a manual edit, clicks place the caret instead of popping the picker back up.
func on_sound_folder_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if folder_field_typing:
		return
	open_sound_folder_dialog()
	pass


func on_sound_folder_text_changed(_text: String) -> void:
	folder_field_typing = true
	pass


func open_sound_folder_dialog() -> void:
	if sound_folder_dialog.visible:
		return
	var folder := AgentNotifySetting.get_sound_folder()
	if not folder.begins_with("res://") and not folder.begins_with("user://") and DirAccess.dir_exists_absolute(folder):
		sound_folder_dialog.current_dir = folder
	sound_folder_dialog.popup_centered(FOLDER_DIALOG_SIZE)
	pass


func on_sound_folder_selected(folder: String) -> void:
	sound_folder_edit.text = folder
	save_sound_folder()
	pass


## Editing finishes when the user leaves a field, presses Enter or the dialog is dismissed.
func save_api_settings() -> void:
	ApiSetting.save(api_url_edit.text, api_token_edit.text, model_edit.text, proxy_address_edit.text)
	pass


func save_sound_folder() -> void:
	AgentNotifySetting.set_sound_folder(sound_folder_edit.text)
	pass


func save_all_settings() -> void:
	save_api_settings()
	save_sound_folder()
	pass


func on_dialog_visibility_changed() -> void:
	# The dialog has no Save button: persist the fields as it closes.
	if dialog.visible or api_url_edit == null:
		return
	save_all_settings()
	pass


func on_dialog_focus_exited() -> void:
	check_dialog_focus.call_deferred()
	pass


func on_provider_popup_hide() -> void:
	check_dialog_focus.call_deferred()
	pass


func check_dialog_focus() -> void:
	if not dialog.visible or provider_select.get_popup().visible or sound_folder_dialog.visible:
		return
	if not dialog.has_focus():
		dialog.hide()
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
	dialog.add_theme_constant_override("buttons_separation", 0)
	content_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	heading_label.add_theme_color_override("font_color", AgentColors.chat_text)
	description_label.add_theme_color_override("font_color", AgentColors.chat_text_muted)
	for label: Label in field_labels:
		label.add_theme_color_override("font_color", AgentColors.chat_text)
	for help: Label in help_labels:
		help.add_theme_color_override("font_color", AgentColors.chat_text_muted)
	for edit: LineEdit in [api_url_edit, model_edit, api_token_edit, proxy_address_edit, sound_folder_edit]:
		style_line_edit(edit)
	style_option_button(provider_select)
	style_spin_box(sound_seconds_spin)
	style_secondary_button(token_visibility_button)
	style_check_button(toast_toggle_button)
	style_check_button(sound_toggle_button)
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
	var normal := make_input_style()
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = AgentColors.theme_accent_solid()
	focus.set_border_width_all(2)
	edit.add_theme_stylebox_override("normal", normal)
	edit.add_theme_stylebox_override("focus", focus)
	edit.add_theme_stylebox_override("read_only", normal.duplicate())
	pass


## Field look shared by the line edits and the spin box buttons.
func make_input_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = AgentColors.chat_input
	style.border_color = AgentColors.chat_input_border
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12
	style.content_margin_right = 12
	return style


## Spin box: accent arrows on the shared field background.
func style_spin_box(spin: SpinBox) -> void:
	style_line_edit(spin.get_line_edit())
	spin.add_theme_color_override("font_color", AgentColors.chat_text)
	spin.add_theme_color_override("font_placeholder_color", AgentColors.chat_text_muted)
	spin.add_theme_color_override("up_icon_modulate", AgentColors.chat_text)
	spin.add_theme_color_override("down_icon_modulate", AgentColors.chat_text)
	spin.add_theme_color_override("up_hover_icon_modulate", AgentColors.theme_accent_solid())
	spin.add_theme_color_override("down_hover_icon_modulate", AgentColors.theme_accent_solid())
	spin.add_theme_color_override("up_pressed_icon_modulate", AgentColors.theme_accent_solid())
	spin.add_theme_color_override("down_pressed_icon_modulate", AgentColors.theme_accent_solid())
	var normal := make_input_style()
	normal.content_margin_left = 0
	normal.content_margin_right = 0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = AgentColors.sidebar_row_hover
	for side: String in ["up", "down"]:
		spin.add_theme_stylebox_override(side + "_background", normal)
		spin.add_theme_stylebox_override(side + "_background_hovered", hover)
		spin.add_theme_stylebox_override(side + "_background_pressed", hover.duplicate())
		spin.add_theme_stylebox_override(side + "_background_disabled", normal.duplicate())
	spin.add_theme_stylebox_override("field_and_buttons_separator", StyleBoxEmpty.new())
	spin.add_theme_stylebox_override("up_down_buttons_separator", StyleBoxEmpty.new())
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


func on_token_visibility_pressed() -> void:
	api_token_edit.secret = not api_token_edit.secret
	token_visibility_button.text = "Show" if api_token_edit.secret else "Hide"
	pass
