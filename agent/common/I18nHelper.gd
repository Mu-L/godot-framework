class_name I18nHelper
extends Object


const LOCALE_PATHS: Dictionary[String, String] = {
	"zh": "res://agent/config/locale/zh.json",
	"en": "res://agent/config/locale/en.json",
}

static func init_i18n() -> void:
	var locale := I18n.get_locale()
	if not LOCALE_PATHS.has(locale):
		locale = "en"
	if TranslationServer.has_translation_for_locale(locale, true):
		return
	var locale_path: String = LOCALE_PATHS.get(locale, LOCALE_PATHS["en"])
	I18n.set_locale(locale_path)
	pass
