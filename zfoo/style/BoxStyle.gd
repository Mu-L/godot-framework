class_name BoxStyle
extends Object

## [StyleBoxFlat] builders — the box half of the style helpers, split from [ButtonStyle] so a
## plain panel can build a box without pulling in the hover / pressed derivation.
##
## Padding comes from the [Margin] scale, so a box is written in the same 4px steps as the rest of
## the layout: symmetric through [method make], per-side through [method Margin.apply_style].
##
## Typical use:
## [codeblock]
## var normal := BoxStyle.make(ThemeColor.card_surface, 6, Margin.ma_2, Margin.ma_1, ThemeColor.accent_theme_color(), 1)
## var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
## hover.bg_color = ThemeColor.inset_surface
## [/codeblock]


## [StyleBoxFlat] in one call: fill, corner radius, symmetric padding, optional hairline border.
static func make(
	bg: Color,
	radius: int = 0,
	margin_h: int = 0,
	margin_v: int = 0,
	border_color: Color = Color(0, 0, 0, 0),
	border_width: int = 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin_h
	style.content_margin_right = margin_h
	style.content_margin_top = margin_v
	style.content_margin_bottom = margin_v
	if border_width > 0:
		style.border_color = border_color
		style.set_border_width_all(border_width)
	return style
