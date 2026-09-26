class_name StyleBoxHelper
extends Object

## [StyleBoxFlat] builders — the box half of the style helpers, split from [ButtonStyle] so a
## plain panel can build a box without pulling in the hover / pressed derivation.
##
## Padding comes from the [Margin] scale, so a box is written in the same 4px steps as the rest of
## the layout: symmetric through [method create_style_box_flat], per-side through
## [method apply_style_box_margin].
##
## Typical use:
## [codeblock]
## var normal := StyleBoxHelper.create_style_box_flat(ThemeColor.card_surface, 6, Margin.ma_2, Margin.ma_1, ThemeColor.accent_theme_color(), ControlSize.border_xs)
## var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
## hover.bg_color = ThemeColor.inset_surface
## [/codeblock]


## [StyleBoxFlat] in one call: fill, corner radius, symmetric padding, optional hairline border.
static func create_style_box_flat(
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
static func apply_style_box_margin(style: StyleBox, left: int, top: int, right: int, bottom: int) -> void:
	style.content_margin_left = left
	style.content_margin_top = top
	style.content_margin_right = right
	style.content_margin_bottom = bottom
	pass
