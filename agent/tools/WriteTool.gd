class_name WriteTool
extends AgentTool

const NAME := "write"
const ARG_PATH := "path"
const ARG_CONTENT := "content"


func _init() -> void:
	name = NAME
	description = "Create or overwrite a text file in the project workspace."
	pass

# AgentTool-Interface-Implement-Start
func get_parameters() -> OpenAiToolDef.Parameters:
	var params := OpenAiToolDef.Parameters.object()
	params.string_prop(ARG_PATH, "Absolute or project-relative file path", true)
	params.string_prop(ARG_CONTENT, "Full file content to write", true)
	return params


func async_execute(args: Dictionary[String, Variant]) -> AgentToolResult:
	var path := AgentWorkspace.resolve_path(str(args.get(ARG_PATH, "")))
	if StringUtils.is_blank(path):
		return AgentToolResult.error("error: path is required")
	var content := str(args.get(ARG_CONTENT, ""))
	var dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	if not FileUtils.write_string_to_file(path, content):
		return AgentToolResult.error(StringUtils.format("error: failed to write file: {}", path))
	var message := StringUtils.format("wrote {} bytes to {}", content.length(), path)
	return AgentToolResult.ok(message, AgentToolResult.ui_details(ChatEntry.TITLE_RESULT))
# AgentTool-Interface-Implement-End
