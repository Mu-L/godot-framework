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
	var dirs := FileUtils.get_all_directories_in_folder(search_root, recursive)
	var files := FileUtils.get_all_files_in_folder(search_root, recursive)
	dirs.sort()
	files.sort()
	var lines: Array[String] = []
	for dir_path in dirs:
		lines.append(dir_path + "/")
	for file_path in files:
		lines.append(file_path)
	var truncated := lines.size() > MAX_ENTRIES
	lines = lines.slice(0, MAX_ENTRIES)
	var build := StringBuilder.new(lines)
	if truncated:
		build.append(StringUtils.format("... (truncated at {} entries)", MAX_ENTRIES))
	var text := build.build_joined(StringUtils.LS)
	if text.is_empty():
		text = "(empty)"
	text = StringUtils.truncate(text, MAX_OUTPUT)
	return AgentToolResult.ok(text, AgentToolResult.ui_details(NAME, text))
# AgentTool-Interface-Implement-End
