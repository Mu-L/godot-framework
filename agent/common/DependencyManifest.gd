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


## When the bundled Python runtime is missing, prepend the dependency-manager skill to the
## user message so the agent installs Python before continuing with the original request.
static func prepend_python_install_skill(user_text: String) -> String:
	if has_populated_runtime(PYTHON_PATH):
		return user_text
	var skill_path := AgentWorkspace.resolve_path(SKILL_DEPENDENCY_MANAGER_PATH)
	if not FileAccess.file_exists(skill_path):
		Log.error("python install skill missing:[{}]", skill_path)
		return user_text
	var skill_text := FileUtils.read_file_to_string(skill_path).strip_edges()
	if skill_text.is_empty():
		Log.error("python install skill empty:[{}]", skill_path)
		return user_text
	return (
		"Python is not installed in .dependency/. Before handling the user request, "
		+ "follow the dependency-manager skill below to install the default Python runtime. "
		+ "After Python is installed, continue with the original user request."
		+ FileUtils.NEWLINE_LF + FileUtils.NEWLINE_LF
		+ skill_text
		+ FileUtils.NEWLINE_LF + FileUtils.NEWLINE_LF
		+ "Original user request:"
		+ FileUtils.NEWLINE_LF
		+ user_text
	)
