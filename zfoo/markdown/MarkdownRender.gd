class_name MarkdownRender
extends Object

const IMAGE_CACHE_DIR := "user://markdown-images"
const MAX_REMOTE_IMAGE_BYTES := 20 * FileUtils.BYTES_PER_MB


## Appends parsed BBCode and image tags in source order. Local images are inserted
## immediately; remote images use a keyed placeholder that is replaced after download.
static func render_markdown_with_images(label: RichTextLabel, result: MarkdownParseResult) -> void:
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


static func append_markdown_image(label: RichTextLabel, markdown_image: MarkdownParseResult.MarkdownImage) -> void:
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
