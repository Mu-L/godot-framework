class_name TranslationHelper
extends Object

class LocaleData:
	var locale: String
	var dot_messages: Dictionary[String, String]
	var space_messages: Dictionary[String, String]

	func _init(locale_name: String, locale_dot_messages: Dictionary[String, String], locale_space_messages: Dictionary[String, String]) -> void:
		locale = locale_name
		dot_messages = locale_dot_messages
		space_messages = locale_space_messages
		pass

## Loads nested JSON locale files, validates that every locale has the same leaf keys,
## and registers both dot-joined and space-joined message IDs with TranslationServer.
##
## Supported JSON format (all leaf values must be strings):
## [codeblock]
## {
##   "locale": "en-US",
##   "workflow": {
##     "window_title": "Skills Workflow — {}",
##     "toolbar": {
##       "save": "Save"
##     }
##   }
## }
## [/codeblock]
## This registers both `workflow.window_title` and `workflow window_title`,
## as well as `workflow.toolbar.save` and `workflow toolbar save`.
static func register_json_files(paths: Array[String]) -> bool:
	var registered := TranslationServer.get_translations()
	if not registered.is_empty():
		return false
	if paths.is_empty():
		Log.error("translation json paths are empty")
		return false

	var locales: Array[LocaleData] = []
	for path in paths:
		var document := parse_json_file(path)
		if document.is_empty():
			return false
		var locale := TranslationServer.standardize_locale(str(document.get("locale", "")))
		if locale.is_empty():
			Log.error("translation locale is missing path:[{}]", path)
			return false
		var dot_messages: Dictionary[String, String] = {}
		var space_messages: Dictionary[String, String] = {}
		if not flatten_messages(document, [], dot_messages, space_messages):
			return false
		locales.append(LocaleData.new(locale, dot_messages, space_messages))

	if not validate_keys(locales):
		return false

	for locale_data in locales:
		TranslationServer.add_translation(create_translation(locale_data.locale, locale_data.dot_messages))
		TranslationServer.add_translation(create_translation(locale_data.locale, locale_data.space_messages))
	return true


static func create_translation(locale: String, messages: Dictionary[String, String]) -> Translation:
	var translation := Translation.new()
	translation.locale = locale
	for key in messages:
		translation.add_message(key, messages[key])
	return translation


static func parse_json_file(path: String) -> Dictionary:
	var content := FileUtils.read_file_to_string(path)
	if content.is_empty():
		Log.error("translation json is missing or empty:[{}]", path)
		return {}
	var json := JSON.new()
	var error := json.parse(content)
	if error != OK:
		Log.error("translation json parse failed path:[{}] line:[{}] error:[{}]", path, json.get_error_line(), json.get_error_message())
		return {}
	if not json.data is Dictionary:
		Log.error("translation json root is not an object:[{}]", path)
		return {}
	return json.data as Dictionary


static func flatten_messages(value: Dictionary, path_parts: Array[String], dot_output: Dictionary[String, String], space_output: Dictionary[String, String]) -> bool:
	for raw_key: Variant in value:
		var key := str(raw_key)
		if path_parts.is_empty() and key == "locale":
			continue
		var next_parts := path_parts.duplicate()
		next_parts.append(key)
		var child: Variant = value[raw_key]
		if child is Dictionary:
			if not flatten_messages(child as Dictionary, next_parts, dot_output, space_output):
				return false
			continue
		if not child is String:
			Log.error("translation value must be a string key:[{}]", ".".join(next_parts))
			return false
		var dot_key := ".".join(next_parts)
		if dot_output.has(dot_key):
			Log.error("duplicate dot translation key:[{}]", dot_key)
			return false
		dot_output[dot_key] = child
		var space_key := " ".join(next_parts)
		if space_output.has(space_key):
			Log.error("duplicate space translation key:[{}]", space_key)
			return false
		space_output[space_key] = child
	return true


static func validate_keys(locales: Array[LocaleData]) -> bool:
	var reference := locales[0]
	for index in range(1, locales.size()):
		var actual := locales[index]
		var missing := key_difference(reference.dot_messages, actual.dot_messages)
		var extra := key_difference(actual.dot_messages, reference.dot_messages)
		if not missing.is_empty() or not extra.is_empty():
			Log.error("translation keys do not match locale:[{}] reference:[{}] missing:[{}] extra:[{}]", actual.locale, reference.locale, ", ".join(missing), ", ".join(extra))
			return false
	return true


static func key_difference(left: Dictionary[String, String], right: Dictionary[String, String]) -> Array[String]:
	var difference: Array[String] = []
	for key: String in left:
		if not right.has(key):
			difference.append(key)
	difference.sort()
	return difference
