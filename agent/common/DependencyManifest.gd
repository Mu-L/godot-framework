class_name DependencyManifest
extends RefCounted


class DependencyManifestEntry:
	var populated: bool = false
	var bin: String = ""
	pass

## Static manifest loaded from `.dependency/manifest.json`. Do not instantiate.

const MANIFEST_REL_PATH := ".dependency/manifest.json"
const SKILL_DEPENDENCY_MANAGER_PATH := ".agents/skills/skill-dependency-manager.md"
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


## When Python is missing, ask the agent to read the dependency-manager skill first.
static func prepend_python_install_skill(user_text: String) -> String:
	if has_populated_runtime(PYTHON_PATH):
		return user_text
	return (
		"The required Python runtime is not installed. Before handling this request, read and follow the "
		+ "dependency setup instructions in " + SKILL_DEPENDENCY_MANAGER_PATH
		+ ", install the Python runtime, and then complete the original request below."
		+ FileUtils.NEWLINE_LF + FileUtils.NEWLINE_LF
		+ user_text
	)
