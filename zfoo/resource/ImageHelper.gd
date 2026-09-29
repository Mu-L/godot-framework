class_name ImageHelper
extends Object

const EXTENSIONS: PackedStringArray = ["bmp", "dds", "exr", "jpg", "jpeg", "ktx", "png", "svg", "tga", "webp"]


static func load_external_image(path: String) -> ImageTexture:
	var image := Image.load_from_file(path)
	return ImageTexture.create_from_image(image) if image != null and not image.is_empty() else null


static func decode_image(bytes: PackedByteArray) -> Image:
	var image := Image.new()
	if image.load_jpg_from_buffer(bytes) == OK:
		return image
	image = Image.new()
	if image.load_png_from_buffer(bytes) == OK:
		return image
	image = Image.new()
	if image.load_webp_from_buffer(bytes) == OK:
		return image
	image = Image.new()
	if image.load_svg_from_buffer(bytes) == OK:
		return image
	image = Image.new()
	if image.load_bmp_from_buffer(bytes) == OK:
		return image
	image = Image.new()
	if image.load_tga_from_buffer(bytes) == OK:
		return image
	image = Image.new()
	if image.load_dds_from_buffer(bytes) == OK:
		return image
	image = Image.new()
	if image.load_exr_from_buffer(bytes) == OK:
		return image
	image = Image.new()
	if image.load_ktx_from_buffer(bytes) == OK:
		return image
	return null
