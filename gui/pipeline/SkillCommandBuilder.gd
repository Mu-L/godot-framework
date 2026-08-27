class_name SkillCommandBuilder
extends RefCounted

var repo_root: String = ""
var manifest: DependencyManifest = DependencyManifest.new()


func _init(root: String = "") -> void:
	repo_root = (root if not root.is_empty() else RepoRoot.resolve()).replace("\\", "/")
	manifest = load_manifest()


func load_manifest() -> DependencyManifest:
	var manifest_path := repo_root.path_join(".dependency/manifest.json")
	var text := FileAccess.get_file_as_string(manifest_path)
	if text.is_empty():
		Log.error("manifest missing:[{}]", manifest_path)
		return DependencyManifest.new()
	return DependencyManifest.from_json(text)


const RUNTIME_OVERRIDES := {
	"image-remove-background": "rembg",
}


func resolve_runtime_key(skill: SkillDef) -> String:
	if RUNTIME_OVERRIDES.has(skill.skill):
		return RUNTIME_OVERRIDES[skill.skill]

	var entry := manifest.get_entry(skill.skill)
	if entry != null and entry.populated and not entry.bin.is_empty():
		return skill.skill

	return "python"


func resolve_runtime_bin(runtime_key: String) -> String:
	if manifest == null:
		return ""
	return manifest.resolve_bin(runtime_key, repo_root)


func build_argv(skill: SkillDef, resolved_inputs: Dictionary[String, String]) -> PackedStringArray:
	var argv := PackedStringArray()
	if skill.cli.is_empty():
		return argv

	var expanded := expand_cli(skill, resolved_inputs)
	if has_unexpanded_placeholders(expanded):
		Log.error(
			"cli has unexpanded placeholders skill:[{}] cli:[{}] inputs:[{}]",
			skill.catalog_id(),
			expanded,
			resolved_inputs,
		)
		return argv

	var parts := split_cli_args(expanded)
	if parts.is_empty():
		Log.error("cli expanded to empty argv for skill:[{}]", skill.catalog_id())
		return argv

	if uses_embedded_runtime(parts[0]):
		for part in parts:
			argv.append(resolve_repo_relative_path(part))
		return argv

	var runtime_key := resolve_runtime_key(skill)
	var runtime_bin := resolve_runtime_bin(runtime_key)
	if runtime_bin.is_empty():
		Log.error("runtime bin not found for skill:[{}] runtime:[{}]", skill.catalog_id(), runtime_key)
		return argv

	argv.append(runtime_bin)
	for part in parts:
		argv.append(resolve_repo_relative_path(part))
	return argv


func uses_embedded_runtime(first_arg: String) -> bool:
	return first_arg.begins_with(".dependency/")


func resolve_repo_relative_path(part: String) -> String:
	var normalized := part.replace("\\", "/")
	if normalized.begins_with(".dependency/") or normalized.begins_with(".ai/"):
		return repo_root.path_join(normalized)
	return part


static func expand_cli(
	skill: SkillDef,
	resolved_inputs: Dictionary[String, String],
) -> String:
	var result := skill.cli

	for port_id in resolved_inputs.keys():
		result = result.replace(placeholder_for(port_id), resolved_inputs[port_id])

	for port in skill.inputs:
		var placeholder := placeholder_for(port.id)
		if not result.contains(placeholder):
			continue
		var value: String = resolved_inputs.get(port.id, "")
		result = result.replace(placeholder, value)

	return result.strip_edges()


static func placeholder_for(port_id: String) -> String:
	return "{" + port_id + "}"


static func has_unexpanded_placeholders(text: String) -> bool:
	var start := text.find("{")
	while start >= 0:
		var end := text.find("}", start + 1)
		if end < 0:
			return false
		var token := text.substr(start, end - start + 1)
		if token.length() > 2:
			return true
		start = text.find("{", end + 1)
	return false


static func split_cli_args(line: String) -> PackedStringArray:
	var args := PackedStringArray()
	var current := ""
	var in_quote := false
	var quote_char := '"'

	for i in line.length():
		var c: String = line[i]
		if in_quote:
			if c == quote_char:
				in_quote = false
			else:
				current += c
		elif c == '"' or c == "'":
			in_quote = true
			quote_char = c
		elif c == " " or c == "\t":
			if not current.is_empty():
				args.append(current)
				current = ""
		else:
			current += c

	if not current.is_empty():
		args.append(current)

	return args


static func format_command_line(argv: PackedStringArray) -> String:
	var parts: Array[String] = []
	for arg in argv:
		parts.append(quote_cli_arg(arg))
	return " ".join(parts)


static func quote_cli_arg(arg: String) -> String:
	if arg.is_empty():
		return "\"\""
	if arg.find(" ") >= 0 or arg.find("\t") >= 0:
		return StringUtils.format("\"{}\"", arg.replace("\"", "\\\""))
	return arg
