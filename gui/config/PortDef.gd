class_name PortDef
extends RefCounted

## Input/output port metadata for catalog nodes and GraphEdit slot matching.

const TYPE_AUDIO := 100
const TYPE_IMAGE := 101
const TYPE_VIDEO := 102
const TYPE_TEXT := 103
const TYPE_FOLDER := 104
const TYPE_STRING := 105

const TYPE_NAME_AUDIO := "audio"
const TYPE_NAME_IMAGE := "image"
const TYPE_NAME_VIDEO := "video"
const TYPE_NAME_TEXT := "text"
const TYPE_NAME_FOLDER := "folder"
const TYPE_NAME_STRING := "string"

var id: String = ""
var type: String = TYPE_NAME_STRING


func display_label(catalog_id: String) -> String:
	return GuiLocale.node_port_label(catalog_id, id, type)


var port_type: int:
	get:
		return type_from_string(type)


static func type_from_string(type_name: String) -> int:
	match type_name:
		TYPE_NAME_AUDIO:
			return TYPE_AUDIO
		TYPE_NAME_IMAGE:
			return TYPE_IMAGE
		TYPE_NAME_VIDEO:
			return TYPE_VIDEO
		TYPE_NAME_TEXT:
			return TYPE_TEXT
		TYPE_NAME_FOLDER:
			return TYPE_FOLDER
		_:
			return TYPE_STRING


static func type_to_string(port_type: int) -> String:
	match port_type:
		TYPE_AUDIO:
			return TYPE_NAME_AUDIO
		TYPE_IMAGE:
			return TYPE_NAME_IMAGE
		TYPE_VIDEO:
			return TYPE_NAME_VIDEO
		TYPE_TEXT:
			return TYPE_NAME_TEXT
		TYPE_FOLDER:
			return TYPE_NAME_FOLDER
		_:
			return TYPE_NAME_STRING


static func type_color(port_type: int) -> Color:
	match port_type:
		TYPE_AUDIO:
			return Color(0.95, 0.55, 0.2)
		TYPE_IMAGE:
			return Color(0.3, 0.85, 0.45)
		TYPE_VIDEO:
			return Color(0.65, 0.45, 0.95)
		TYPE_TEXT:
			return Color(0.95, 0.85, 0.25)
		TYPE_FOLDER:
			return Color(0.35, 0.65, 0.95)
		_:
			return Color(0.7, 0.7, 0.7)
