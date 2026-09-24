## Locale label tests for GraphNodesConfig node definitions.


func graph_nodes_locale_test() -> void:
	assert(GuiLocale.node_label("input-audio") == GuiLocale.resolve("node.input-audio"))
	assert(GuiLocale.category_label(GraphNodesConfig.SOURCE_CATEGORY) == GuiLocale.resolve("category.source"))
	assert(
		GraphNodesConfig.get_def("input-audio").display_label()
		== GuiLocale.node_label("input-audio")
	)
	pass


func translation_server_locale_test() -> void:
	TranslationServer.set_locale(GuiLocale.LOCALE_EN)
	assert(TranslationServer.translate("ui.window_title") == GuiLocale.resolve("ui.window_title"))
	assert(TranslationServer.translate("ui window_title") == GuiLocale.resolve("ui.window_title"))
	TranslationServer.set_locale(GuiLocale.current_locale)
	pass
