class_name ThemeColorMarkdown
extends Object

## Markdown palette for `MarkdownUtils`: code blocks, inline code chips, tables, quotes, links.
## Two hand-written sets — one per theme — instead of colors derived from `ThemeColor.theme_color`:
## every value is a literal you can read, tune and review in a screenshot, and a link always lands
## on a contrast that was picked by hand instead of on whatever the current accent implies.
## Usage: `ThemeColorMarkdown.code_block_bg` / `table_grid_color` / … ; `MarkdownUtils` turns each
## one into a BBCode argument at conversion time.
## `ThemeColor` calls `refresh()` whenever the dark/light theme changes.

## The dark set doubles as the fallback until `refresh()` runs for the first time (see `ThemeColor`).
static var code_block_bg: Color = Color(0.07, 0.08, 0.10)
static var table_grid_color: Color = Color(0.35, 0.36, 0.41)
static var table_header_bg: Color = Color(1.0, 1.0, 1.0, 0.08)
static var inline_code_bg: Color = Color(0.45, 0.47, 0.52, 0.18)
static var link_color: Color = Color(0.35, 0.65, 0.95)
static var blockquote_bar_color: Color = Color(0.35, 0.65, 0.95)
static var blockquote_text_color: Color = Color(0.55, 0.57, 0.62)


## Assignment only — pick the set for the current dark/light theme, no accent maths.
static func refresh() -> void:
	if ThemeColor.is_dark_theme():
		apply_dark_palette()
	else:
		apply_light_palette()
	pass


# ---------------------------------------------------------------------------
# Dark palette
# ---------------------------------------------------------------------------

## Fills sit a hair darker than the chat surface (#0d0f12) so a code block or a table grid now
## reads as a recess rather than as a colored block; the marks carry the accent brightness —
## link 5.9:1 on the assistant bubble, quote body 4.8:1, i.e. dimmer than the bubble text
## (0.90, 0.91, 0.93) without reading as disabled.
static func apply_dark_palette() -> void:
	code_block_bg = Color(0.07, 0.08, 0.10)
	table_grid_color = Color(0.35, 0.36, 0.41)
	table_header_bg = Color(1.0, 1.0, 1.0, 0.08)
	inline_code_bg = Color(0.45, 0.47, 0.52, 0.18)
	link_color = Color(0.35, 0.65, 0.95)
	blockquote_bar_color = link_color
	blockquote_text_color = Color(0.55, 0.57, 0.62)
	pass


# ---------------------------------------------------------------------------
# Light palette
# ---------------------------------------------------------------------------

## Same roles on a near-white surface: the fills drop to a whisper of gray (a saturated tint on
## white turns a code block into a color swatch) and the marks darken until they read against
## white — link 5.2:1, quote body 4.9:1.
static func apply_light_palette() -> void:
	code_block_bg = Color(0.45, 0.47, 0.52, 0.18)
	table_grid_color = Color(0.78, 0.79, 0.82)
	table_header_bg = Color(0.0, 0.0, 0.0, 0.05)
	inline_code_bg = Color(0.96, 0.965, 0.97)
	link_color = Color(0.15, 0.39, 0.92)
	blockquote_bar_color = link_color
	blockquote_text_color = Color(0.44, 0.44, 0.48)
	pass
