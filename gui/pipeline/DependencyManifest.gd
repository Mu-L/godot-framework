class_name DependencyManifest
extends RefCounted

var entries: Dictionary[String, DependencyManifestEntry] = {}


static func from_json(text: String) -> DependencyManifest:
	var manifest := DependencyManifest.new()
	if StringUtils.is_blank(text):
		return manifest

	var data: Variant = JSON.parse_string(text)
	if data == null:
		Log.error("Json pars error:[{}]", text)
		return manifest
	if typeof(data) != TYPE_DICTIONARY:
		Log.error("Json root type error:[{}]", text)
		return manifest

	var raw := data as Dictionary
	for runtime in raw.keys():
		var value: Variant = raw[runtime]
		if value is Dictionary:
			var entry: DependencyManifestEntry = JsonUtils.dict_to_object(
				value,
				DependencyManifestEntry,
			)
			if entry != null:
				manifest.entries[str(runtime)] = entry

	return manifest


func get_entry(runtime: String) -> DependencyManifestEntry:
	return entries.get(runtime, null)


func resolve_bin(runtime: String, repo_root: String) -> String:
	if runtime.is_empty():
		return ""
	var entry := get_entry(runtime)
	if entry == null or entry.bin.is_empty():
		return ""
	return repo_root.path_join(entry.bin.replace("\\", "/"))
