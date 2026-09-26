class_name ControlSize
extends Object

## Control size scale: control heights, square sizes and shared corner radii, in px.
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

## Smallest radius: subtle rounding for compact indicators and hairline surfaces.
const radius_xs: int = 2
## Compact radius: chips, tags and tightly packed row controls.
const radius_sm: int = 4
## Default radius: buttons, selects, inputs and selectable rows.
const radius_md: int = 6
## Prominent radius: nodes, dialogs and medium cards.
const radius_lg: int = 8
## Hero radius: search bars, input bars and large floating surfaces.
const radius_xl: int = 12
## Largest radius: showcase controls and prominent floating containers.
const radius_xxl: int = 16

## Hairline border: separators, subtle outlines and ordinary control frames.
const border_xs: int = 1
## Emphasized border: focus rings and selected control outlines.
const border_sm: int = 2
## Accent border: semantic stripes and prominent edge markers.
const border_md: int = 3
## Prominent border: strong selection frames and compact decorative bands.
const border_lg: int = 4
## Wide border: large control accents and display outlines.
const border_xl: int = 5
## Widest border: hero surfaces and highly emphasized decorative frames.
const border_xxl: int = 6


## Both axes at one tier, for the square icon buttons that make up most of the chrome.
static func square(size: int) -> Vector2:
	return Vector2(size, size)
