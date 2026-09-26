class_name DependencyManifest
extends RefCounted


class DependencyManifestEntry:
	var populated: bool = false
	var bin: String = ""
	pass

## Static manifest loaded from `.dependency/manifest.json`. Do not instantiate.

const MANIFEST_REL_PATH := ".dependency/manifest.json"
const PYTHON_PATH := ".dependency/python/python"

static var entries: Dictionary[String, DependencyManifestEntry] = {}




static func _static_init() -> void:
	reload_manifest()
	pass


static func reload_manifest() -> void:
	entries.clear()
	var text := FileAccess.get_file_as_string(MANIFEST_REL_PATH)
	if text.is_empty():
		Log.error("manifest missing:[{}]", MANIFEST_REL_PATH)
		return

	var data: Variant = JSON.parse_string(text)
	if data == null:
		Log.error("Json pars error:[{}]", MANIFEST_REL_PATH)
		return
	if typeof(data) != TYPE_DICTIONARY:
		Log.error("Json root type error:[{}]", MANIFEST_REL_PATH)
		return

	for runtime in data.keys():
		var value: Variant = data[runtime]
		if value is Dictionary:
			var entry: DependencyManifestEntry = JsonUtils.dict_to_object(value, DependencyManifestEntry)
			if entry != null:
				entries[str(runtime)] = entry
	pass


static func has_populated_runtime(runtime_path: String) -> bool:
	reload_manifest()
	var normalized := runtime_path.replace("\\", "/")
	if not normalized.begins_with(".dependency/"):
		return false

	var key := normalized.trim_prefix(".dependency/").split("/")[0]
	var entry: DependencyManifestEntry = entries.get(key, null)
	return entry != null and entry.populated and not entry.bin.is_empty()
