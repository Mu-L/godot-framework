class_name TokenUsageDisplay
extends RefCounted

## Toolbar badge — current context length from the latest LLM request (left of the skill toggle).
##
## Shows [member OpenAiUsage.prompt_tokens] from the last API call (input context size, not session total).
## Panel matches [member ColorBase.selection_surface]. Label text uses the theme color until
## [constant THRESHOLD_WARN], then a traffic-light scale against [constant MAX_CONTEXT_TOKENS]:
##
## ```
## 50% ── yellow ──► 75% ── orange ──► 90% ── red
## ```

## Reference context window for badge color / percentage. Update when switching to a model with a different limit (e.g. GPT-4o 128k vs DeepSeek V4 1M).
const MAX_CONTEXT_TOKENS: int = 1_000_000
const THRESHOLD_WARN: float = 0.50
const THRESHOLD_CAUTION: float = 0.75
const THRESHOLD_CRITICAL: float = 0.90

var wrap: PanelContainer
var label: Label


func setup(p_wrap: PanelContainer) -> void:
	wrap = p_wrap
	label = wrap.get_child(0) as Label
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	gdf.events.theme_changed.connect(apply_theme)
	gdf.events.theme_color_changed.connect(apply_theme)
	gdf.events.locale_changed.connect(apply_theme)
	AgentEvents.events.session_selected.connect(refresh)
	AgentEvents.events.message_complete.connect(on_message_complete)
	label.text = StringUtils.format(I18n.t("agent.tokens.label"), "0")
	apply_theme()
	pass


func on_message_complete(session_id: int, _usage: OpenAiUsage) -> void:
	if session_id == AgentSessionManager.active_session_id:
		refresh()
	pass


func refresh(_session_id: int = 0, _previous_session_id: int = 0) -> void:
	if label == null or wrap == null:
		return
	var session: AgentSession = AgentSessionStore.load_session(AgentSessionManager.active_session_id)
	if session == null:
		return
	var usage: OpenAiUsage = session.usage
	var n: int = usage.prompt_tokens
	var ratio: float = token_ratio(n)
	label.text = StringUtils.format(I18n.t("agent.tokens.label"), format_count(n))
	wrap.tooltip_text = StringUtils.format(
		I18n.t("agent.tokens.tooltip"),
		n,
		int(round(ratio * 100.0)),
		usage.completion_tokens,
		usage.total_tokens
	)
	label.add_theme_color_override("font_color", text_color_for_tokens(n))
	wrap.add_theme_stylebox_override("panel", BoxStyle.make(ColorBase.selection_surface, 6, Margin.ma_2, Margin.ma_1, ColorBase.subtle_border, 1))
	pass


func apply_theme() -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", TextSize.label_medium_size)
	refresh()
	pass


## Compact badge text: 999 → "999", 1500 → "1.5k", 12000 → "12k", 2M+ → "2M".
static func format_count(n: int) -> String:
	if n >= 1_000_000:
		return StringUtils.format("{}M", n / 1_000_000)
	if n >= 10_000:
		return StringUtils.format("{}k", n / 1000)
	if n >= 1000:
		return StringUtils.format("{}k", snappedf(float(n) / 1000.0, 0.1))
	return str(n)


static func token_ratio(n: int) -> float:
	return clampf(float(n) / float(MAX_CONTEXT_TOKENS), 0.0, 1.0)


static func text_color_for_tokens(n: int) -> Color:
	var ratio: float = token_ratio(n)
	if ratio >= THRESHOLD_CRITICAL:
		return ColorBase.error
	if ratio >= THRESHOLD_CAUTION:
		return ColorBase.warning
	if ratio >= THRESHOLD_WARN:
		return Color(0.94, 0.84, 0.35) if ThemeColor.is_dark_theme() else Color("#CA8A04")
	return ThemeColor.theme_color_full_alpha()
