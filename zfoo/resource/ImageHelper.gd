class_name ImageHelper
extends Object

const bmp := "bmp"
const dds := "dds"
const exr := "exr"
const jpg := "jpg"
const jpeg := "jpeg"
const ktx := "ktx"
const png := "png"
const svg := "svg"
const tga := "tga"
const webp := "webp"
const EXTENSIONS: PackedStringArray = [bmp, dds, exr, jpg, jpeg, ktx, png, svg, tga, webp]


static func load_external_image(path: String) -> ImageTexture:
	var image := Image.load_from_file(path)
	return ImageTexture.create_from_image(image) if image != null and not image.is_empty() else null


static func get_image_format(path: String) -> String:
	var extension := StringUtils.substring_after_last(path.to_lower(), ".")
	return extension if EXTENSIONS.has(extension) else png


static func detect_image_format(bytes: PackedByteArray) -> String:
	if bytes.size() >= 3 and bytes[0] == 0xff and bytes[1] == 0xd8 and bytes[2] == 0xff:
		return jpg
	if bytes.size() >= 8 and bytes.slice(0, 8) == PackedByteArray([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]):
		return png
	if bytes.size() >= 12 and bytes.slice(0, 4).get_string_from_ascii() == "RIFF" and bytes.slice(8, 12).get_string_from_ascii() == "WEBP":
		return webp
	var header := bytes.slice(0, mini(bytes.size(), 4096)).get_string_from_utf8().strip_edges()
	if header.trim_prefix("\ufeff").find("<svg") >= 0:
		return svg
	return ""


static func decode_image(bytes: PackedByteArray) -> Image:
	var image := Image.new()
	var error := ERR_FILE_UNRECOGNIZED
	match detect_image_format(bytes):
		jpg: error = image.load_jpg_from_buffer(bytes)
		png: error = image.load_png_from_buffer(bytes)
		webp: error = image.load_webp_from_buffer(bytes)
		svg: error = image.load_svg_from_buffer(bytes)
	if error == OK:
		return image

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
