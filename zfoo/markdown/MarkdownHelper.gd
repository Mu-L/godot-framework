class_name MarkdownHelper
extends Object

const IMAGE_CACHE_DIR := "user://markdown-images"
const MAX_REMOTE_IMAGE_BYTES := 20 * FileUtils.BYTES_PER_MB

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
	update_rich_text_label_text(label, raw_text, markdown_enabled)
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

static func update_rich_text_label_text(label: RichTextLabel, raw_text: String, markdown_enabled: bool) -> void:
	if markdown_enabled:
		var parse_result := MarkdownParser.to_bbcode(raw_text)
		# Enabling bbcode re-parses existing text; raw markdown may contain literal
		# `[cell]` / `[table]` (e.g. in backticks) and crash RichTextLabel.
		if parse_result.images.is_empty() and label.bbcode_enabled:
			label.text = parse_result.bbcode
		elif parse_result.images.is_empty():
			label.bbcode_enabled = false
			label.text = parse_result.bbcode
			label.bbcode_enabled = true
		else:
			label.bbcode_enabled = true
			render_markdown_with_images(label, parse_result)
	else:
		if label.bbcode_enabled:
			label.bbcode_enabled = false
		label.text = raw_text
	pass


## Appends parsed BBCode and image tags in source order. Local images are inserted
## immediately; remote images use a keyed placeholder that is replaced after download.
static func render_markdown_with_images(
		label: RichTextLabel,
		result: MarkdownParseResult
) -> void:
	label.clear()
	var cursor := 0
	for index in result.images.size():
		var image_start := result.bbcode.find("[img]", cursor)
		var image_end := result.bbcode.find("[/img]", image_start + 5)
		if image_start < 0 or image_end < 0:
			break
		label.append_text(result.bbcode.substr(cursor, image_start - cursor))
		append_markdown_image(label, result.images[index])
		cursor = image_end + 6
	label.append_text(result.bbcode.substr(cursor))
	pass


static func append_markdown_image(
		label: RichTextLabel,
		markdown_image: MarkdownParseResult.MarkdownImage
) -> void:
	if HttpUtils.is_valid_http_url(markdown_image.image_url):
		var cache_path := remote_image_cache_path(markdown_image.image_url)
		var cached_texture := load_local_image(cache_path)
		if cached_texture != null:
			add_image(label, cached_texture, markdown_image, cache_path)
			return
		label.add_image(create_image_placeholder(), 0, 0, Color.WHITE, 5, Rect2(), markdown_image.image_url, false, markdown_image.alt_text)
		if is_image_downloading(label, markdown_image.image_url):
			return
		set_image_downloading(label, markdown_image.image_url, true)
		download_remote_image(label, markdown_image, cache_path)
		return
	var texture := load_local_image(markdown_image.image_url)
	if texture != null:
		add_image(label, texture, markdown_image, markdown_image.image_url)
	else:
		append_image_error(label, markdown_image)
	pass


static func add_image(
		label: RichTextLabel,
		texture: Texture2D,
		markdown_image: MarkdownParseResult.MarkdownImage,
		tooltip: String
) -> void:
	label.add_image(texture, 0, 0, Color.WHITE, 5, Rect2(), markdown_image.image_url, false, tooltip)
	pass


static func load_local_image(path: String) -> ImageTexture:
	var absolute_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") or path.begins_with("user://") else path
	if not FileAccess.file_exists(absolute_path):
		return null
	var image := Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


static func download_remote_image(
		label: RichTextLabel,
		markdown_image: MarkdownParseResult.MarkdownImage,
		cache_path: String
) -> void:
	var response := await HttpHelper.async_get(markdown_image.image_url)
	if not is_instance_valid(label):
		return
	if not response.success or response.code < 200 or response.code >= 300 or response.body.is_empty():
		Log.error("markdown image download failed url:[{}] code:[{}]", markdown_image.image_url, response.code)
		set_image_downloading(label, markdown_image.image_url, false)
		return
	if response.body.size() > MAX_REMOTE_IMAGE_BYTES:
		Log.error("markdown image is too large url:[{}] bytes:[{}]", markdown_image.image_url, response.body.size())
		set_image_downloading(label, markdown_image.image_url, false)
		return
	var image := decode_image(response.body)
	if image == null:
		Log.error("markdown image decode failed url:[{}]", markdown_image.image_url)
		set_image_downloading(label, markdown_image.image_url, false)
		return
	var cache_error := save_cached_image(image, cache_path)
	if cache_error != OK:
		Log.error("markdown image cache failed path:[{}] err:[{}]", cache_path, cache_error)
		set_image_downloading(label, markdown_image.image_url, false)
		return
	var texture := load_local_image(cache_path)
	if texture == null:
		set_image_downloading(label, markdown_image.image_url, false)
		return
	if not is_instance_valid(label):
		return
	label.update_image(markdown_image.image_url, RichTextLabel.UPDATE_TEXTURE | RichTextLabel.UPDATE_SIZE, texture)
	set_image_downloading(label, markdown_image.image_url, false)
	pass


static func decode_image(bytes: PackedByteArray) -> Image:
	var image := Image.new()
	if image.load_png_from_buffer(bytes) == OK:
		return image
	image = Image.new()
	if image.load_jpg_from_buffer(bytes) == OK:
		return image
	image = Image.new()
	if image.load_webp_from_buffer(bytes) == OK:
		return image
	image = Image.new()
	if image.load_svg_from_buffer(bytes) == OK:
		return image
	return null


static func save_cached_image(image: Image, cache_path: String) -> int:
	var absolute_dir := ProjectSettings.globalize_path(IMAGE_CACHE_DIR)
	var error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if error != OK and error != ERR_ALREADY_EXISTS:
		return error
	return image.save_png(ProjectSettings.globalize_path(cache_path))


static func remote_image_cache_path(url: String) -> String:
	return IMAGE_CACHE_DIR.path_join(url.sha256_text() + ".png")


static func create_image_placeholder() -> ImageTexture:
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	return ImageTexture.create_from_image(image)


static func is_image_downloading(label: RichTextLabel, image_url: String) -> bool:
	return label.has_meta(image_download_meta_key(image_url))


static func set_image_downloading(label: RichTextLabel, image_url: String, downloading: bool) -> void:
	var meta_key := image_download_meta_key(image_url)
	if downloading:
		label.set_meta(meta_key, true)
		return
	label.remove_meta(meta_key)
	pass


static func image_download_meta_key(image_url: String) -> StringName:
	return StringName("image_" + image_url.sha256_text())


static func append_image_error(label: RichTextLabel, markdown_image: MarkdownParseResult.MarkdownImage) -> void:
	var description := markdown_image.alt_text if StringUtils.is_not_blank(markdown_image.alt_text) else markdown_image.image_url
	label.add_text("[%s]" % description)
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
