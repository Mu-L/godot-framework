class_name MarkdownParseResult
extends RefCounted

class MarkdownImage extends RefCounted:
	var alt_text: String
	var image_url: String

	func _init(p_alt_text: String, p_image_url: String) -> void:
		alt_text = p_alt_text
		image_url = p_image_url
		pass

var bbcode: String = ""
var images: Array[MarkdownImage] = []
