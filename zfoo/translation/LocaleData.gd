class_name LocaleData
extends Object

var locale: String
var i18ns: Dictionary[String, String]


func _init(locale_name: String, locale_i18ns: Dictionary[String, String]) -> void:
	locale = locale_name
	i18ns = locale_i18ns
	pass


## Parses one nested JSON locale file into normalized locale data.
static func parse_json_file(path: String) -> LocaleData:
	var content := FileUtils.read_file_to_string(path)
	if content.is_empty():
		Log.error("translation json is missing or empty:[{}]", path)
		return null
	var json := JSON.new()
	var error := json.parse(content)
	if error != OK:
		Log.error("translation json parse failed path:[{}] line:[{}] error:[{}]", path, json.get_error_line(), json.get_error_message())
		return null
	if not json.data is Dictionary:
		Log.error("translation json root is not an object:[{}]", path)
		return null
	var document := json.data as Dictionary
	var locale_name := TranslationServer.standardize_locale(str(document.get("locale", "")))
	if locale_name.is_empty():
		Log.error("translation locale is missing path:[{}]", path)
		return null
	var locale_i18ns: Dictionary[String, String] = {}
	if not flatten_i18ns(document, [], locale_i18ns):
		return null
	return LocaleData.new(locale_name, locale_i18ns)


static func flatten_i18ns(value: Dictionary, path_parts: Array[String], i18n_map: Dictionary[String, String]) -> bool:
	for raw_key: Variant in value:
		var key := str(raw_key)
		if path_parts.is_empty() and key == "locale":
			continue
		var next_parts := path_parts.duplicate()
		next_parts.append(key)
		var child: Variant = value[raw_key]
		if child is Dictionary:
			if not flatten_i18ns(child as Dictionary, next_parts, i18n_map):
				return false
			continue
		if not child is String:
			Log.error("translation value must be a string key:[{}]", ".".join(next_parts))
			return false
		var dot_key := ".".join(next_parts)
		if i18n_map.has(dot_key):
			Log.error("duplicate translation key:[{}]", dot_key)
			return false
		i18n_map[dot_key] = child
		var space_key := " ".join(next_parts)
		if space_key == dot_key:
			continue
		if i18n_map.has(space_key):
			Log.error("duplicate translation key:[{}]", space_key)
			return false
		i18n_map[space_key] = child
	return true
