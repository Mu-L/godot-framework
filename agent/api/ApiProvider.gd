class_name ApiProvider
extends RefCounted

## OpenAI-compatible provider connection preset.

var name: String
var api_url: String
var model: String


func _init(p_name: String, p_api_url: String, p_model: String) -> void:
	name = p_name
	api_url = p_api_url
	model = p_model
	pass
