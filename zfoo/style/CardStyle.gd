class_name CardStyle
extends Object

## The card geometry the floating feedback surfaces share: corner radius and the semantic accent
## stripe. [Alert] and [DesktopToast] build their card through [method make], [PopupWindow] takes the
## radius for its frame, so a snackbar, a desktop toast and a popup stay one card design instead of
## three copies of the same numbers.
##
## Only values two or more of them need live here. What a single component owns stays on it — its
## shadow, its hairline, its card width, its lifetime — and so does anything that already has a home
## ([TextStyle] sizes, [Margin] steps).
##
## Typical use:
## [codeblock]
## var snackbar := CardStyle.make(Colors.success, CardStyle.CORNER_RADIUS, Margin.ma_4, Margin.ma_3)
##
## var toast := CardStyle.make(Colors.info, 0, 0.0, 0.0, CardStyle.STRIPE_LEFT, roundi(CardStyle.ACCENT_STRIPE_WIDTH * unit))
## [/codeblock]

## Corner radius of a floating card. A native window passes 0 instead: the OS decides its corners.
const CORNER_RADIUS: int = 6
## Accent stripe edges: [Alert] frames its text with [constant STRIPE_BOTH], [DesktopToast] marks the
## leading edge with [constant STRIPE_LEFT].
const STRIPE_LEFT: int = 1
const STRIPE_RIGHT: int = 2
const STRIPE_BOTH: int = STRIPE_LEFT | STRIPE_RIGHT
## Width of that stripe.
const ACCENT_STRIPE_WIDTH: int = 3


## Card box: [member ThemeColorCard.background_color] fill, [param stripe_color] painted down the edges
## named by [param stripe], rounded by [param radius], padded by [param margin_h] / [param margin_v].
## The paddings are floats because [DesktopToast] scales its whole card by the app UI scale.
static func make(
	stripe_color: Color,
	radius: int = CORNER_RADIUS,
	margin_h: float = 0.0,
	margin_v: float = 0.0,
	stripe: int = STRIPE_BOTH,
	stripe_width: int = ACCENT_STRIPE_WIDTH
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ColorCard.background_color
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin_h
	style.content_margin_right = margin_h
	style.content_margin_top = margin_v
	style.content_margin_bottom = margin_v
	style.border_color = stripe_color
	style.set_border_width(SIDE_LEFT, stripe_width if (stripe & STRIPE_LEFT) != 0 else 0)
	style.set_border_width(SIDE_RIGHT, stripe_width if (stripe & STRIPE_RIGHT) != 0 else 0)
	return style
