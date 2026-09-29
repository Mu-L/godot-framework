class_name MarkdownHelper
extends Object

## RichTextLabel construction and interaction helpers for rendered Markdown bodies.

# ---------------------------------------------------------------------------
# RichTextLabel body (markdown UI)
# ---------------------------------------------------------------------------

const BODY_LABEL_MIN_HEIGHT := 24
const TABLE_H_SEPARATION := 0
const TABLE_V_SEPARATION := 0
# Inline chip box (`[bgcolor]`): RichTextLabel draws it `line_height + 2 * padding` tall
# (`_draw_line`), so the engine default of 3 spills 3px over the line above and below and
# paints on their text. 0 already fits the line box; the negative value hugs the glyphs so
# the box reads as a chip instead of a full-height row. Padding is plain arithmetic in the
# draw code, and a future clamp to 0 would only make the box line-height again.
const HIGHLIGHT_H_PADDING := 3
const HIGHLIGHT_V_PADDING := -3


## RichTextLabel that also drops its highlight when a click lands outside it.
##
## `deselect_on_focus_loss_enabled` only fires when focus moves to another *focusable*
## control, and a click on a bubble background never moves focus at all (chat lists and
## their panels are not focusable), so the highlight outlived the click that was meant to
## clear it. The label therefore watches presses itself: [method _input] runs before GUI
## routing, so pressing outside clears the highlight before the click reaches whatever is
## underneath. Watch starts on the press that selects and ends with the highlight, so
## labels without one stay out of the input path.
class SelectableRichTextLabel extends RichTextLabel:
	var outside_press_watch: bool = false

	func _init() -> void:
		# selection_enabled already forces FOCUS_ALL; focus loss stays as the cheap path
		# for clicks that do land on another focusable control.
		selection_enabled = true
		deselect_on_focus_loss_enabled = true
		gui_input.connect(on_body_gui_input)
		focus_exited.connect(stop_outside_press_watch)

	## A script `_input` is auto-enabled on ready; only a highlight needs it here.
	func _ready() -> void:
		stop_outside_press_watch()
		pass

	## Left press inside — RichTextLabel starts (or clears) a highlight from here.
	func on_body_gui_input(event: InputEvent) -> void:
		if not event is InputEventMouseButton:
			return
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			start_outside_press_watch()
		pass

	func start_outside_press_watch() -> void:
		outside_press_watch = true
		set_process_input(true)
		pass

	func stop_outside_press_watch() -> void:
		outside_press_watch = false
		set_process_input(false)
		pass

	## Right click opens the copy menu and the wheel only scrolls the transcript — both
	## read the highlight, so a left press outside is the one that clears it.
	func _input(event: InputEvent) -> void:
		if not outside_press_watch:
			return
		if not event is InputEventMouseButton:
			return
		var mouse := event as InputEventMouseButton
		if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if get_global_rect().has_point(mouse.position):
			return
		stop_outside_press_watch()
		deselect()
		pass


## Highlight colors of a selectable body: the card palette's accent-tinted selection plus its
## primary text for the highlighted glyphs. Both come from [ThemeColor], so a bubble keeps
## readable contrast in either theme and re-tints when the user picks another accent color.
static func apply_selection_theme(label: RichTextLabel) -> void:
	label.add_theme_color_override("selection_color", ThemeColor.selection_color)
	label.add_theme_color_override("font_selected_color", ThemeColor.title_color)
	pass


static func create_rich_text_label(text_color: Color, raw_text: String, markdown_enabled: bool) -> RichTextLabel:
	var label := SelectableRichTextLabel.new()
	label.scroll_active = false
	label.fit_content = true
	label.clip_contents = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("default_color", text_color)
	apply_selection_theme(label)
	label.add_theme_font_override("normal_font", Fonts.regular())
	label.add_theme_font_override("bold_font", Fonts.bold())
	label.add_theme_font_override("italics_font", Fonts.semibold())
	label.add_theme_font_override("bold_italics_font", Fonts.bold())
	label.add_theme_font_override("mono_font", Fonts.regular())
	label.add_theme_constant_override("table_h_separation", TABLE_H_SEPARATION)
	label.add_theme_constant_override("table_v_separation", TABLE_V_SEPARATION)
	label.add_theme_constant_override("text_highlight_h_padding", HIGHLIGHT_H_PADDING)
	label.add_theme_constant_override("text_highlight_v_padding", HIGHLIGHT_V_PADDING)
	label.custom_minimum_size = Vector2(0, BODY_LABEL_MIN_HEIGHT)
	# RichTextLabel copies what it draws, so a selection carries `[code]` NBSPs and
	# inline-chip thin margins; restore the source characters before copying.
	label.gui_input.connect(
			func(event: InputEvent) -> void:
				if not event.is_action_pressed("ui_copy"):
					return
				label.accept_event()
				copy_to_clipboard(label.get_selected_text())
	)
	label.meta_clicked.connect(handle_meta_clicked)
	set_rich_text_label_text(label, raw_text, markdown_enabled)
	return label


## Bare selectable label for plain-text bodies (thinking / result previews) — no markdown
## pass, same click-outside deselect as [method create_rich_text_label].
static func create_plain_rich_text_label(text_color: Color) -> RichTextLabel:
	var label := SelectableRichTextLabel.new()
	label.scroll_active = false
	label.fit_content = true
	label.bbcode_enabled = false
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("default_color", text_color)
	apply_selection_theme(label)
	label.add_theme_font_override("normal_font", Fonts.regular())
	return label


## Put [param text] on the clipboard without markdown's rendering-only spacing.
static func copy_to_clipboard(text: String) -> void:
	if StringUtils.is_blank(text):
		return
	DisplayServer.clipboard_set(text.replace(MarkdownParser.NBSP, StringUtils.SPACE).replace(MarkdownParser.INLINE_CODE_MARGIN, StringUtils.EMPTY).strip_edges())
	pass

static func set_rich_text_label_text(label: RichTextLabel, raw_text: String, markdown_enabled: bool) -> void:
	if markdown_enabled:
		var bbcode := MarkdownParser.to_bbcode(raw_text)
		# Enabling bbcode re-parses existing text; raw markdown may contain literal
		# `[cell]` / `[table]` (e.g. in backticks) and crash RichTextLabel.
		if label.bbcode_enabled:
			label.text = bbcode
		else:
			label.bbcode_enabled = false
			label.text = bbcode
			label.bbcode_enabled = true
	else:
		if label.bbcode_enabled:
			label.bbcode_enabled = false
		label.text = raw_text
	pass


static func handle_meta_clicked(meta: Variant) -> void:
	var url := str(meta).strip_edges()
	if StringUtils.is_blank(url):
		return
	var lower := url.to_lower()
	if lower.begins_with("javascript:") or lower.begins_with("data:"):
		Log.info("blocked unsafe link:[{}]", url)
		return
	if not lower.begins_with("http://") and not lower.begins_with("https://") and not lower.begins_with("mailto:"):
		if url.begins_with("//"):
			url = "https:" + url
		elif url.contains(".") and not url.contains(" "):
			url = "https://" + url
		else:
			Log.info("unsupported link:[{}]", url)
			return
	var err := OS.shell_open(url)
	if err != OK:
		Log.error("open link failed url:[{}] err:[{}]", url, err)
	pass
