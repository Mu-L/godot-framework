class_name BoxStyle
extends Object

## [StyleBoxFlat] builders — the box half of the style helpers, split from [ButtonStyle] so a
## plain panel can build a box without pulling in the hover / pressed derivation.
##
## Padding comes from the [Margin] scale, so a box is written in the same 4px steps as the rest of
## the layout: symmetric through [method make], per-side through [method pad]. [method with_bg]
## derives a hover / pressed box from the normal one.
##
## Typical use:
## [codeblock]
## var normal := BoxStyle.make(ThemeColor.card_surface, 6, Margin.ma_2, Margin.ma_1, ThemeColor.accent_theme_color(), 1)
## var hover := BoxStyle.with_bg(normal, ThemeColor.inset_surface)
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


## All four padding sides in one call (left, top, right, bottom) — for asymmetrical boxes.
## Edits [param style] in place; takes the [StyleBox] base class, so an empty box or a line box
## gets the same treatment.
static func pad(style: StyleBox, left: int, top: int, right: int, bottom: int) -> void:
	style.content_margin_left = left
	style.content_margin_top = top
	style.content_margin_right = right
	style.content_margin_bottom = bottom
	pass


## [param base] with a new fill — how a hover / pressed box is built from the normal one.
static func with_bg(base: StyleBoxFlat, bg: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = base.duplicate() as StyleBoxFlat
	style.bg_color = bg
	return style
