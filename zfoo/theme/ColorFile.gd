class_name ColorFile
extends Object

## Semantic colors for resource and file categories. The palette uses restrained jewel tones so
## resource types remain distinct without borrowing red or orange warning colors.
const DARK_AUDIO := Color("#8a6bc2")
const DARK_IMAGE := Color("#3f9477")
const DARK_VIDEO := Color("#397fa8")
const DARK_TEXT := Color("#657d96")
const DARK_FOLDER := Color("#a8843f")

const LIGHT_AUDIO := Color("#67459b")
const LIGHT_IMAGE := Color("#276b57")
const LIGHT_VIDEO := Color("#285e80")
const LIGHT_TEXT := Color("#455b70")
const LIGHT_FOLDER := Color("#7d6026")

static var audio_color: Color = DARK_AUDIO
static var image_color: Color = DARK_IMAGE
static var video_color: Color = DARK_VIDEO
static var text_color: Color = DARK_TEXT
static var folder_color: Color = DARK_FOLDER


## Select resource colors with suitable contrast for the current dark or light theme.
static func refresh() -> void:
	var dark := ThemeColor.is_dark_theme()
	audio_color = DARK_AUDIO if dark else LIGHT_AUDIO
	image_color = DARK_IMAGE if dark else LIGHT_IMAGE
	video_color = DARK_VIDEO if dark else LIGHT_VIDEO
	text_color = DARK_TEXT if dark else LIGHT_TEXT
	folder_color = DARK_FOLDER if dark else LIGHT_FOLDER
	pass
