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
	var image_url := markdown_image.image_url
	label.add_image(create_image_placeholder(), 0, 0, Color.WHITE, 5, Rect2(), image_url, false, markdown_image.alt_text)
	if HttpUtils.is_valid_http_url(image_url):
		var cache_path := remote_image_cache_path(image_url)
		if FileAccess.file_exists(cache_path):
			load_image_into_label(label, image_url, cache_path)
			return
		if is_image_downloading(label, image_url):
			return
		set_image_downloading(label, image_url, true)
		download_remote_image(label, image_url, cache_path)
		return
	load_image_into_label(label, image_url, image_url)
	pass


static func load_image_into_label(label: RichTextLabel, image_url: String, path: String) -> void:
	var texture: Texture2D = await ResourceHelper.async_load(path)
	if texture == null or not is_instance_valid(label):
		return
	label.update_image(image_url, RichTextLabel.UPDATE_TEXTURE | RichTextLabel.UPDATE_SIZE, texture)
	pass


static func download_remote_image(label: RichTextLabel, image_url: String, cache_path: String) -> void:
	var texture := await download_remote_image_texture(image_url, cache_path)
	if not is_instance_valid(label):
		return
	set_image_downloading(label, image_url, false)
	if texture != null:
		label.update_image(image_url, RichTextLabel.UPDATE_TEXTURE | RichTextLabel.UPDATE_SIZE, texture)
	pass


static func download_remote_image_texture(image_url: String, cache_path: String) -> Texture2D:
	var response := await HttpHelper.async_get(image_url)
	if not response.success or response.code < 200 or response.code >= 300 or response.body.is_empty():
		Log.error("markdown image download failed url:[{}] code:[{}]", image_url, response.code)
		return null
	if response.body.size() > MAX_REMOTE_IMAGE_BYTES:
		Log.error("markdown image is too large url:[{}] bytes:[{}]", image_url, response.body.size())
		return null
	var image := decode_image(response.body)
	if image == null:
		Log.error("markdown image decode failed url:[{}]", image_url)
		return null
	var cache_error := save_cached_image(image, cache_path)
	if cache_error != OK:
		Log.error("markdown image cache failed path:[{}] err:[{}]", cache_path, cache_error)
		return null
	var texture: Texture2D = await ResourceHelper.async_load(cache_path)
	return texture


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
