class_name DependencyManifest
extends RefCounted

var entries: Dictionary[String, DependencyManifestEntry] = {}


static func from_json(text: String) -> DependencyManifest:
	if StringUtils.is_blank(text):
		return DependencyManifest.new()

	var data: Variant = JSON.parse_string(text)
	if data == null:
		Log.error("Json pars error:[{}]", text)
		return DependencyManifest.new()
	if typeof(data) != TYPE_DICTIONARY:
		Log.error("Json root type error:[{}]", text)
		return DependencyManifest.new()

	var manifest: DependencyManifest = JsonUtils.dict_to_object(
		{"entries": data},
		DependencyManifest,
	)
	return manifest if manifest != null else DependencyManifest.new()


func get_entry(runtime: String) -> DependencyManifestEntry:
	return entries.get(runtime, null)


func has_populated_runtime(runtime_path: String) -> bool:
	var normalized := runtime_path.replace("\\", "/")
	if not normalized.begins_with(".dependency/"):
		return false

	var key := normalized.trim_prefix(".dependency/").split("/")[0]
	var entry := get_entry(key)
	return entry != null and entry.populated and not entry.bin.is_empty()
