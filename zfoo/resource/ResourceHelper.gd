class_name ResourceHelper
extends Object

static var loader: AsyncResourceLoader = AsyncResourceLoader.new()

## Load a resource or a plain file by path. Project resources go through the threaded loader,
## a file that is not a resource (an OS folder, or a raw file under `user://`) through
## [method load_external_file]:
##     var texture := await ResourceHelper.async_load("res://agent/asset/image/icon/settings.svg")
##     var clip := await ResourceHelper.async_load("C:/clips/notify.mp3") as AudioStream
static func async_load(path: String) -> Resource:
	if ResourceLoader.exists(path):
		return await loader.async_load(path)
	return load_external_file(path)


# ----------------------------------------------------------------------------------------------------------------------
## Loaders for the file types that can also be read from outside the project — [ResourceLoader]
## only opens resources, so a plain file needs the loader of its own format.
const AUDIO_EXTENSIONS: PackedStringArray = ["wav", "mp3", "ogg"]
const IMAGE_EXTENSIONS: PackedStringArray = ["png", "jpg", "jpeg", "webp", "bmp", "tga", "svg"]
const FONT_EXTENSIONS: PackedStringArray = ["ttf", "otf", "woff", "woff2"]

## Godot has no format-agnostic loader for a file that is not a project resource, so the loader is
## picked by extension. Images come back as an [Image], wrap them with [method ImageTexture.create_from_image].
static func load_external_file(path: String) -> Resource:
	if not FileAccess.file_exists(path):
		Log.error("external file not found:[{}]", path)
		return null
	var extension := path.get_extension().to_lower()
	if AUDIO_EXTENSIONS.has(extension):
		return load_external_audio(extension, path)
	if IMAGE_EXTENSIONS.has(extension):
		return Image.load_from_file(path)
	if FONT_EXTENSIONS.has(extension):
		var font := FontFile.new()
		return font if font.load_dynamic_font(path) == OK else null
	Log.error("external file format not supported:[{}]", path)
	return null


static func load_external_audio(extension: String, path: String) -> AudioStream:
	match extension:
		"wav":
			return AudioStreamWAV.load_from_file(path)
		"mp3":
			return AudioStreamMP3.load_from_file(path)
		"ogg":
			return AudioStreamOggVorbis.load_from_file(path)
	return null
