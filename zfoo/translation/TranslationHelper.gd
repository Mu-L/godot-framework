class_name TranslationHelper
extends Object

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
		var locale_data := LocaleData.parse_json_file(path)
		if locale_data == null:
			return false
		locales.append(locale_data)

	if not validate_keys(locales):
		return false

	for locale_data in locales:
		TranslationServer.add_translation(create_translation(locale_data))
	return true


static func create_translation(locale_data: LocaleData) -> Translation:
	var translation := Translation.new()
	translation.locale = locale_data.locale
	for key in locale_data.i18ns:
		translation.add_message(key, locale_data.i18ns[key])
	return translation


static func validate_keys(locales: Array[LocaleData]) -> bool:
	var reference := locales[0]
	for index in range(1, locales.size()):
		var actual := locales[index]
		var missing := key_difference(reference.i18ns, actual.i18ns)
		var extra := key_difference(actual.i18ns, reference.i18ns)
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
