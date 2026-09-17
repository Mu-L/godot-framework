class_name GlobTool
extends AgentTool

const NAME := "glob"
const ARG_PATTERN := "pattern"
const ARG_PATH := "path"


func _init() -> void:
	name = NAME
	description = "Find files under the workspace by glob pattern, e.g. **/*.gd or agent/tools/*.gd."
	pass

# AgentTool-Interface-Implement-Start
func get_parameters() -> OpenAiToolDef.Parameters:
	var params := OpenAiToolDef.Parameters.object()
	params.string_prop(ARG_PATTERN, "Glob pattern (*, ?, ** supported)", true)
	params.string_prop(ARG_PATH, "Directory to search from (default: workspace root)", false)
	return params


func async_execute(args: Dictionary[String, String]) -> AgentToolResult:
	var pattern := str(args.get(ARG_PATTERN, "")).strip_edges()
	if pattern.is_empty():
		return AgentToolResult.error("error: pattern is required")
	var search_root := AgentWorkspace.resolve_path(str(args.get(ARG_PATH, "")))
	var all_files := collect_files(search_root, pattern)
	var truncated := all_files.size() > MAX_GLOB_RESULTS
	var files := all_files.slice(0, MAX_GLOB_RESULTS) if truncated else all_files
	var lines: Array[String] = []
	for file_path in files:
		lines.append(AgentWorkspace.workspace_relative(file_path))
	var text := "\n".join(lines)
	if truncated:
		text += StringUtils.format("\n... (truncated at {} files)", MAX_GLOB_RESULTS)
	if text.is_empty():
		text = "No files matched"
	text = StringUtils.truncate(text, AgentTool.MAX_OUTPUT)
	return AgentToolResult.ok(text, AgentToolResult.ui_details(NAME, text))
# AgentTool-Interface-Implement-End


# ---------------------------------------------------------------------------
# Workspace file collection — shared by glob / grep (FileUtils.collect_files_glob)
# ---------------------------------------------------------------------------

## Always skipped during agent repo search; merged with rules from workspace ignore files.
static var SKIP_DIR_NAMES: PackedStringArray = PackedStringArray([
	".git",
	"node_modules",
	".godot",
])

static var WORKSPACE_IGNORE_FILES: PackedStringArray = PackedStringArray([
	".gitignore",
	".cursorignore",
	".agentignore",
	".aiignore",
])

## Result caps applied by GlobTool / GrepTool after [method collect_files] (not in FileUtils).
const MAX_GLOB_RESULTS := 2_000
const MAX_GREP_FILES := 8_000
const MAX_FILE_BYTES := 1_048_576

static var merged_skip_dir_names: PackedStringArray = PackedStringArray()
static var merged_skip_path_prefixes: Array[String] = []


static func _static_init() -> void:
	var dir_names: Array[String] = []
	var path_prefixes: Array[String] = []
	for file_name in WORKSPACE_IGNORE_FILES:
		var path := AgentWorkspace.resolve_path(file_name)
		if not FileAccess.file_exists(path):
			continue
		for line in FileUtils.read_file_to_string(path).split(StringUtils.LS, false):
			var rule := line.strip_edges()
			if rule.is_empty() or rule.begins_with("#"):
				continue
			if rule.begins_with("!"):
				continue
			if rule.contains("*") or rule.contains("?") or rule.contains("["):
				continue
			if rule.ends_with("/"):
				rule = rule.substr(0, rule.length() - 1)
			rule = rule.replace("\\", "/").strip_edges()
			if rule.is_empty():
				continue
			if rule.contains("/"):
				if not path_prefixes.has(rule):
					path_prefixes.append(rule)
			elif not dir_names.has(rule):
				dir_names.append(rule)
	merged_skip_dir_names = PackedStringArray()
	for _name in SKIP_DIR_NAMES:
		if not merged_skip_dir_names.has(_name):
			merged_skip_dir_names.append(_name)
	for _name in dir_names:
		if not merged_skip_dir_names.has(_name):
			merged_skip_dir_names.append(_name)
	merged_skip_path_prefixes = path_prefixes
	pass


## All matching files under [param search_root]; caller may slice to [constant MAX_GLOB_RESULTS] or [constant MAX_GREP_FILES].
static func collect_files(search_root: String, glob_filter: String) -> Array[String]:
	return FileUtils.collect_files_glob(search_root, glob_filter, merged_skip_dir_names, MAX_FILE_BYTES, merged_skip_path_prefixes)
