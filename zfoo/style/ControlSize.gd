class_name ControlSize
extends Object

## Control size scale: the height a button, a select or an input occupies, in px.
##
## Six tiers, each one 8px ([code]Margin.ma_2[/code]) above the previous, so every value lands on the
## same 4px grid as the rest of the layout and is a [Margin] step: xs 20 ([code]ma_5[/code]),
## sm 28 ([code]ma_7[/code]), md 36 ([code]ma_9[/code]), lg 44 ([code]ma_11[/code]),
## xl 52 ([code]ma_13[/code]), xxl 60 ([code]ma_15[/code]).
##
## The tiers are deliberately sparse: a control picks a tier, it does not pick a number. Sizes between
## two tiers are not a missing constant — they are a sign the control should be sitting on one of them.
##
## The values are ints because theme constants and minimum sizes ask for ints; int to float is a
## lossless conversion, so they also go straight into `custom_minimum_size`. There is no scale factor
## on purpose: the viewport already scales the whole UI (project stretch mode [code]canvas_items[/code]).
##
## Typical use:
## [codeblock]
## button.custom_minimum_size = ControlSize.square(ControlSize.sm)   # 28×28 icon button
## field.custom_minimum_size = Vector2(0, ControlSize.md)            # input that stretches horizontally
## [/codeblock]

## Smallest tier: inline chips, tags and the tiny icon buttons inside a row of text.
const xs: int = 20
## Compact tier: toolbar and row-action buttons, the 28×28 icon button most of the chrome is built on.
const sm: int = 28
## Default tier: the button, select and input of a normal form.
const md: int = 36
## Prominent tier: dialog fields and primary actions that should read above the form around them.
const lg: int = 44
## Hero tier: search bar, send button, collapsed input bar.
const xl: int = 52
## Tallest tier: showcase buttons and large controls that anchor a panel.
const xxl: int = 60


## Both axes at one tier, for the square icon buttons that make up most of the chrome.
static func square(size: int) -> Vector2:
	return Vector2(size, size)
