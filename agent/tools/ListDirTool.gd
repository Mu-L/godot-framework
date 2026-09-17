class_name ListDirTool
extends AgentTool

const NAME := "list_dir"
const ARG_PATH := "path"
const ARG_RECURSIVE := "recursive"

const MAX_ENTRIES := 500


func _init() -> void:
	name = NAME
	description = "List files under a workspace directory (optional recursive listing)."
	pass

# AgentTool-Interface-Implement-Start
func get_parameters() -> OpenAiToolDef.Parameters:
	var params := OpenAiToolDef.Parameters.object()
	params.string_prop(ARG_PATH, "Directory path (default: workspace root)", false)
	params.string_prop(ARG_RECURSIVE, "Set to true to list subdirectories recursively (default false)", false)
	return params


func async_execute(args: Dictionary[String, String]) -> AgentToolResult:
	var search_root := AgentWorkspace.resolve_path(str(args.get(ARG_PATH, "")))
	if not DirAccess.dir_exists_absolute(search_root):
		return AgentToolResult.error("error: directory not found")
	var recursive := parse_bool(str(args.get(ARG_RECURSIVE, "")))
	var all_files := FileUtils.get_all_files_in_folder(search_root, recursive)
	all_files.sort()
	var truncated := all_files.size() > MAX_ENTRIES
	var files := all_files.slice(0, MAX_ENTRIES) if truncated else all_files
	var build := StringBuilder.new()
	for file_path in files:
		build.append(AgentWorkspace.workspace_relative(file_path))
	if truncated:
		build.append(StringUtils.format("... (truncated at {} entries)", MAX_ENTRIES))
	var text := build.build_joined(StringUtils.LS)
	if text.is_empty():
		text = "(empty)"
	text = StringUtils.truncate(text, AgentTool.MAX_OUTPUT)
	return AgentToolResult.ok(text, AgentToolResult.ui_details(NAME, text))
# AgentTool-Interface-Implement-End
