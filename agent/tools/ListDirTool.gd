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
	for i in dirs.size():
		dirs[i] += "/"
	var entries: Array[String] = []
	entries.append_array(dirs)
	entries.append_array(files)
	var truncated_files := entries.size() > MAX_ENTRIES
	entries = entries.slice(0, MAX_ENTRIES)
	var build := StringBuilder.new(entries)
	
	var truncated := build.truncate_by_part(MAX_OUTPUT)
	if truncated_files || truncated:
		build.append("... (truncated)")
	var text := build.build_joined(StringUtils.LS)
	return AgentToolResult.ok(text, AgentToolResult.ui_details(NAME, text))
# AgentTool-Interface-Implement-End
