class_name I18nCheck
extends Object


## Checks that locale configuration files are valid and contain matching keys.
static func check_configs(paths: Array[String]) -> bool:
	if paths.is_empty():
		Log.error("translation json paths are empty")
		return false
	var locales: Array[LocaleData] = []
	for path in paths:
		var locale_data := LocaleData.parse_json_file(path)
		if locale_data == null:
			return false
		locales.append(locale_data)
	return validate_keys(locales)


static func validate_keys(locales: Array[LocaleData]) -> bool:
	var reference := locales[0]
	for index in range(1, locales.size()):
		var actual := locales[index]
		var missing := key_difference(reference.data, actual.data)
		var extra := key_difference(actual.data, reference.data)
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
