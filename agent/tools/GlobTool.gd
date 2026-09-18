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
	var all_files := GlobUtils.glob(search_root, pattern, true, MAX_FILE_BYTES, workspace_skip_glob_rules)
	var truncated := all_files.size() > MAX_FILE_RESULTS
	var files := all_files.slice(0, MAX_FILE_RESULTS) if truncated else all_files
	var lines: Array[String] = []
	for file_path in files:
		lines.append(file_path)
	var text := "\n".join(lines)
	if truncated:
		text += StringUtils.format("\n... (truncated at {} files)", MAX_FILE_RESULTS)
	if text.is_empty():
		text = "No files matched"
	text = StringUtils.truncate_last(text, MAX_OUTPUT)
	return AgentToolResult.ok(text, AgentToolResult.ui_details(NAME, text))
# AgentTool-Interface-Implement-End


# ---------------------------------------------------------------------------
# Workspace file collection — shared by glob / grep (FileUtils.glob)
# ---------------------------------------------------------------------------

## Always applied as skip globs during agent repo search (see [method workspace_path_skipped]).
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

## Literal ignore lines (no [code]*[/code] / [code]?[/code] / [code][[/code]) from [constant WORKSPACE_IGNORE_FILES], plus [constant SKIP_DIR_NAMES].
static var workspace_skip_glob_rules: Array[String] = []


static func _static_init() -> void:
	workspace_skip_glob_rules = _load_workspace_skip_glob_rules()
	pass


## True when [param relative_path] matches any [member workspace_skip_glob_rules] entry ([method GlobUtils.glob_match_any]).
static func workspace_path_skipped(relative_path: String) -> bool:
	return GlobUtils.glob_match_any(workspace_skip_glob_rules, relative_path)


static func _load_workspace_skip_glob_rules() -> Array[String]:
	var rules: Array[String] = []
	for dir_name in SKIP_DIR_NAMES:
		rules.append(dir_name)
	for file_name in WORKSPACE_IGNORE_FILES:
		var path := AgentWorkspace.resolve_path(file_name)
		if not FileAccess.file_exists(path):
			continue
		for line in FileUtils.read_file_to_lines(path):
			if not _include_ignore_line_in_skip_rules(line):
				continue
			rules.append(line)
	return rules


## Ignore lines that participate in workspace directory skip (comments, negation, and wildcards excluded — same as before).
static func _include_ignore_line_in_skip_rules(line: String) -> bool:
	var trimmed := line.strip_edges()
	if trimmed.is_empty() or trimmed.begins_with("#"):
		return false
	if trimmed.begins_with("!"):
		return false
	if trimmed.contains("*") or trimmed.contains("?") or trimmed.contains("["):
		return false
	return true
