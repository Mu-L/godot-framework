class_name TextSize
extends Object

## Material Design text scale: font size in px and letter spacing in px.
##
## The size constants are ints because theme font size overrides ask for ints; the letter spacing
## constants are floats because glyph spacing is fractional (apply to [code]FontVariation.spacing_glyph[/code]).
## Naming is [code]<role>_<scale>_<property>[/code], so a later weight / line height addition stays flat:
## [code]TextStyle.title_medium_weight[/code].
## Typical use:
## [codeblock]
## label.add_theme_font_size_override("font_size", TextStyle.title_medium_size)
##
## var variation := FontVariation.new()
## variation.spacing_glyph = TextStyle.title_medium_letter_spacing
## label.add_theme_font_override("font", variation)
## [/codeblock]

# ----------------------------------------------------------------------------------------------------------------------
# display
const display_large_size: int = 57
const display_large_letter_spacing: float = -0.25
const display_medium_size: int = 45
const display_medium_letter_spacing: float = 0.0
const display_small_size: int = 36
const display_small_letter_spacing: float = 0.0

# ----------------------------------------------------------------------------------------------------------------------
# headline
const headline_large_size: int = 32
const headline_large_letter_spacing: float = 0.0
const headline_medium_size: int = 28
const headline_medium_letter_spacing: float = 0.0
const headline_small_size: int = 24
const headline_small_letter_spacing: float = 0.0

# ----------------------------------------------------------------------------------------------------------------------
# title
const title_large_size: int = 22
const title_large_letter_spacing: float = 0.0
const title_medium_size: int = 16
const title_medium_letter_spacing: float = 0.15
const title_small_size: int = 14
const title_small_letter_spacing: float = 0.1

# ----------------------------------------------------------------------------------------------------------------------
# body
const body_large_size: int = 16
const body_large_letter_spacing: float = 0.5
const body_medium_size: int = 14
const body_medium_letter_spacing: float = 0.25
const body_small_size: int = 12
const body_small_letter_spacing: float = 0.4

# ----------------------------------------------------------------------------------------------------------------------
# label
const label_large_size: int = 14
const label_large_letter_spacing: float = 0.1
const label_medium_size: int = 12
const label_medium_letter_spacing: float = 0.5
const label_small_size: int = 11
const label_small_letter_spacing: float = 0.5
