func external_image_test() -> void:
	var path := ProjectSettings.globalize_path("res://icon.svg")
	var texture := ResourceHelper.load_external_file(path) as ImageTexture
	assert(texture != null)
	assert(texture.get_width() > 0)
	assert(texture.get_height() > 0)
	pass


func image_buffer_decode_test() -> void:
	var source := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	source.fill(Color.RED)
	var decoded := ImageHelper.decode_image(source.save_jpg_to_buffer())
	assert(decoded != null)
	assert(decoded.get_size() == Vector2i(2, 2))
	pass


func get_image_format_test() -> void:
	assert(ImageHelper.get_image_format("res://image/photo.PNG") == ImageHelper.png)
	assert(ImageHelper.get_image_format("https://example.com/photo.webp") == ImageHelper.webp)
	assert(ImageHelper.get_image_format("https://example.com/photo") == ImageHelper.png)
	assert(ImageHelper.get_image_format("res://document.txt") == ImageHelper.png)
	pass


func detect_image_format_test() -> void:
	var source := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	assert(ImageHelper.detect_image_format(source.save_jpg_to_buffer()) == ImageHelper.jpg)
	assert(ImageHelper.detect_image_format(source.save_png_to_buffer()) == ImageHelper.png)
	assert(ImageHelper.detect_image_format(source.save_webp_to_buffer()) == ImageHelper.webp)
	assert(ImageHelper.detect_image_format("<?xml version=\"1.0\"?><svg xmlns=\"http://www.w3.org/2000/svg\"/>".to_utf8_buffer()) == ImageHelper.svg)
	assert(ImageHelper.detect_image_format(PackedByteArray([0x01, 0x02, 0x03])) == "")
	pass
