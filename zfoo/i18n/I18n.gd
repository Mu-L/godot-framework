class_name I18n
extends Object


static func register_json_files(paths: Array[String]) -> bool:
	var registered := TranslationServer.get_translations()
	if not registered.is_empty():
		return false

	if not I18nCheck.check_configs(paths):
		return false

	for path in paths:
		var locale_data := LocaleData.parse_json_file(path)
		if locale_data == null:
			return false
		TranslationServer.add_translation(create_translation(locale_data))
	return true


static func create_translation(locale_data: LocaleData) -> Translation:
	var translation := Translation.new()
	translation.locale = locale_data.locale
	for key in locale_data.data:
		translation.add_message(key, locale_data.data[key])
	return translation
