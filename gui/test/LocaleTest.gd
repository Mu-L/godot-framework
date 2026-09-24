## Locale label tests for GraphNodesConfig node definitions.

const LOCALE_EN := "en_US"
const LOCALE_PATHS: Array[String] = [
	"res://gui/locale/en-US.json",
	"res://gui/locale/zh-CN.json",
]


func graph_nodes_locale_test() -> void:
	assert(TranslationJson.register_json_files(LOCALE_PATHS))
	TranslationServer.set_locale(LOCALE_EN)
	assert(GraphNodesConfig.get_def("input-audio").display_label() == TranslationServer.translate("node.input-audio"))
	assert(GraphNodesConfig.category_label(GraphNodesConfig.SOURCE_CATEGORY) == TranslationServer.translate("category.source"))
	pass


func translation_server_locale_test() -> void:
	assert(TranslationJson.register_json_files(LOCALE_PATHS))
	TranslationServer.set_locale(LOCALE_EN)
	assert(TranslationServer.translate("workflow.window_title") == TranslationServer.translate("workflow window_title"))
	pass
