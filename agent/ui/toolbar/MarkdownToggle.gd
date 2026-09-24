class_name MarkdownToggle
extends RefCounted

## Toolbar toggle for chat bubble Markdown rendering.

## Respect toolbar setting; tool and user bubbles always stay plain text.
## A user prompt is echoed exactly as typed — never Markdown-rendered.
static func markdown_enabled_for_entry(entry: ChatEntry) -> bool:
	if entry.kind == ChatEntry.KIND_TOOL or entry.kind == ChatEntry.KIND_USER:
		return false
	return AgentSetting.get_markdown_enabled()


var button: Button


func setup(p_button: Button) -> void:
	button = p_button
	button.toggled.connect(on_toggled)
	gdf.events.theme_changed.connect(apply_theme)
	gdf.events.theme_color_changed.connect(apply_theme)
	apply_theme()
	pass


func apply_theme() -> void:
	var markdown_enabled := AgentSetting.get_markdown_enabled()
	AgentToolbarButton.style(
			button,
			I18nHelper.translate("agent.toolbar.raw_text") if markdown_enabled else I18nHelper.translate("agent.toolbar.markdown")
	)
	button.set_block_signals(true)
	button.button_pressed = markdown_enabled
	button.set_block_signals(false)
	pass


func on_toggled(enabled: bool) -> void:
	AgentSetting.set_markdown_enabled(enabled)
	apply_theme()
	pass
