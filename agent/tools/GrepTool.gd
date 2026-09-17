class_name GrepTool
extends AgentTool

const NAME := "grep"
const ARG_PATTERN := "pattern"
const ARG_PATH := "path"
const ARG_GLOB := "glob"

const HEAD_LIMIT := 200


func _init() -> void:
	name = NAME
	description = "Search file contents in the workspace using a regular expression (case-sensitive; use (?i) in the pattern if needed). Returns up to 200 matching lines (path:line:content); use read for surrounding code."
	pass

# AgentTool-Interface-Implement-Start
func get_parameters() -> OpenAiToolDef.Parameters:
	var params := OpenAiToolDef.Parameters.object()
	params.string_prop(ARG_PATTERN, "Regular expression pattern to search for", true)
	params.string_prop(ARG_PATH, "File or directory to search (default: workspace root)", false)
	params.string_prop(ARG_GLOB, "Optional glob filter, e.g. *.gd or **/*.gd", false)
	return params


func async_execute(args: Dictionary[String, String]) -> AgentToolResult:
	var pattern := str(args.get(ARG_PATTERN, "")).strip_edges()
	if pattern.is_empty():
		return AgentToolResult.error("error: pattern is required")
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return AgentToolResult.error(StringUtils.format("error: invalid regex: {}", pattern))
	var search_root := AgentWorkspace.resolve_path(str(args.get(ARG_PATH, "")))
	var glob_filter := str(args.get(ARG_GLOB, "")).strip_edges()
	var all_files := GlobTool.collect_files(search_root, glob_filter)
	if all_files.is_empty():
		return AgentToolResult.ok("No files to search")
	var truncated_files := all_files.size() > GlobTool.MAX_GREP_FILES
	var files := all_files.slice(0, GlobTool.MAX_GREP_FILES) if truncated_files else all_files
	var build := StringBuilder.new()
	var match_count := 0
	for file_path in files:
		if match_count >= HEAD_LIMIT:
			break
		match_count += append_file_matches(build, file_path, regex, HEAD_LIMIT - match_count)
	if truncated_files:
		build.append_line(StringUtils.format("... (file list capped at {} files)", GlobTool.MAX_GREP_FILES))
	var text := build.build_string()
	if build.is_empty():
		text = "No matches found"
	text = StringUtils.truncate(text, AgentTool.MAX_OUTPUT)
	return AgentToolResult.ok(text, AgentToolResult.ui_details(NAME, text))


static func append_file_matches(build: StringBuilder, file_path: String, regex: RegEx, remaining: int) -> int:
	var lines := FileUtils.read_file_to_lines(file_path)
	if lines.is_empty():
		return 0
	var rel := AgentWorkspace.workspace_relative(file_path)
	var matches_out := 0
	for i in lines.size():
		if matches_out >= remaining:
			break
		if regex.search(lines[i]) == null:
			continue
		build.append_line(rel + ":" + str(i + 1) + ":" + lines[i])
		matches_out += 1
	return matches_out
# AgentTool-Interface-Implement-End
