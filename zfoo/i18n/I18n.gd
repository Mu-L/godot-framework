class_name I18n
extends Object

const LOCALE_SETTING_KEY := "locale"


static func get_locale() -> String:
	return Setting.get_string(LOCALE_SETTING_KEY)


static func is_initialized() -> bool:
	var locale := get_locale()
	return not locale.is_empty() and TranslationServer.has_translation_for_locale(locale, true)


static func t(key: String) -> String:
	return TranslationServer.translate(key)


## Loads the translation at path when needed, then switches to its declared locale.
static func set_locale(locale_path: String) -> void:
	var locale_data := LocaleData.parse_json_file(locale_path)
	if locale_data == null:
		return
	remove_old_locale()
	if not TranslationServer.has_translation_for_locale(locale_data.locale, true):
		TranslationServer.add_translation(create_translation(locale_data))
	TranslationServer.set_locale(locale_data.locale)
	Setting.set_string(LOCALE_SETTING_KEY, locale_data.locale)
	Setting.save()
	gdf.events.locale_changed.emit()
	pass


static func remove_old_locale() -> void:
	var old_locale := get_locale()
	if old_locale.is_empty():
		return
	var standardized_locale := TranslationServer.standardize_locale(old_locale)
	for translation: Translation in TranslationServer.get_translations():
		if TranslationServer.standardize_locale(translation.locale) == standardized_locale:
			TranslationServer.remove_translation(translation)
	pass


static func create_translation(locale_data: LocaleData) -> Translation:
	var translation := Translation.new()
	translation.locale = locale_data.locale
	for key in locale_data.data:
		translation.add_message(key, locale_data.data[key])
	return translation
