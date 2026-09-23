class_name ThemeColorMarkdown
extends Object

## Markdown palette derived from `ThemeColor.theme_color`, so every color `MarkdownUtils`
## paints (code blocks, inline code chips, tables, quotes, links, rules) follows the accent
## the user picked and the dark/light theme, instead of carrying its own hex constants.
## Usage: `ThemeColorMarkdown.code_block_bg` / `table_grid_color` / … ; BBCode takes strings,
## so tags are built through [method to_hex].
## `ThemeColor` calls `refresh()` whenever the accent color or the dark/light theme changes.

## Neutral fallbacks until `refresh()` runs for the first time (see `ThemeColor`).
const FALLBACK_GRID_COLOR := Color(0.35, 0.36, 0.41)

static var code_block_bg: Color = Color(0.07, 0.08, 0.10)
static var table_grid_color: Color = FALLBACK_GRID_COLOR
static var table_header_bg: Color = Color(1.0, 1.0, 1.0, 0.08)
static var inline_code_bg: Color = Color(0.45, 0.47, 0.52, 0.18)
static var link_color: Color = Color(0.35, 0.65, 0.95)
static var blockquote_bar_color: Color = Color(0.35, 0.65, 0.95)
static var blockquote_text_color: Color = Color(0.55, 0.57, 0.62)
## `[hr]` tag for `---`; shares the table grid color so rules and table lines match.
static var horizontal_rule_line: String = build_horizontal_rule_line(FALLBACK_GRID_COLOR)


## Recompute the palette from the current accent color and dark/light theme.
static func refresh() -> void:
	if ThemeColor.is_dark_theme():
		apply_dark_palette()
	else:
		apply_light_palette()
	pass


# ---------------------------------------------------------------------------
# Dark palette
# ---------------------------------------------------------------------------

## Fills are the accent hue pulled most of the way to black, so a code block or a table
## grid reads as a surface with the theme's tint rather than a colored block; text marks
## (links, the quote bar) ride the same hue at text brightness instead.
static func apply_dark_palette() -> void:
	code_block_bg = derive(0.30, 0.06)
	table_grid_color = derive(0.25, 0.42)
	inline_code_bg = derive(0.35, 0.52, 0.12)
	table_header_bg = Color(1.0, 1.0, 1.0, 0.08)
	link_color = derive(1.0, 0.90)
	blockquote_bar_color = link_color
	# Quote body is dimmer than the bubble text (#e6e8ee) but not so dim it reads as disabled.
	blockquote_text_color = derive(0.12, 0.80)
	horizontal_rule_line = build_horizontal_rule_line(table_grid_color)
	pass


# ---------------------------------------------------------------------------
# Light palette
# ---------------------------------------------------------------------------

## Same accent, a light touch of its hue: a saturated tint on white turns a code block
## into a color swatch, so the fills take far less accent and stay near-white. Text marks
## keep the hue and drop in brightness until they read against the light surface.
static func apply_light_palette() -> void:
	code_block_bg = derive(0.10, 0.96)
	table_grid_color = derive(0.10, 0.78)
	inline_code_bg = derive(0.15, 0.30, 0.08)
	table_header_bg = Color(0.0, 0.0, 0.0, 0.05)
	link_color = derive(1.0, 0.52)
	blockquote_bar_color = link_color
	# Kept near the muted gray the light bubbles used before, only tinted by the accent.
	blockquote_text_color = derive(0.12, 0.52)
	horizontal_rule_line = build_horizontal_rule_line(table_grid_color)
	pass


# ---------------------------------------------------------------------------
# Derivation
# ---------------------------------------------------------------------------

## Accent hue at a saturation factor of the accent's own saturation, at the given
## brightness — fixed brightness per theme is what keeps the contrast ratio the same for
## every accent color.
static func derive(saturation: float, value: float, alpha: float = 1.0) -> Color:
	var accent := ThemeColor.theme_color
	return Color.from_hsv(accent.h, clampf(accent.s * saturation, 0.0, 1.0), value, alpha)


## Full-width rule for `---`; one place so the tag and the fill cannot drift apart.
static func build_horizontal_rule_line(color: Color) -> String:
	return "[hr width=100% height=1 color=" + to_hex(color) + "]"


## BBCode wants `#rrggbbaa`, and the palette changes at runtime, so tags are formatted per
## conversion instead of cached as strings.
static func to_hex(color: Color) -> String:
	return "#" + color.to_html(true)
