class_name DeleteTool
extends AgentTool

const NAME := "delete"
const ARG_PATH := "path"


func _init() -> void:
	name = NAME
	description = "Delete a file in the project workspace. Does not remove directories."
	pass

# AgentTool-Interface-Implement-Start
func get_parameters() -> OpenAiToolDef.Parameters:
	return OpenAiToolDef.Parameters.object().string_prop(ARG_PATH, "Absolute or project-relative file path", true)


func async_execute(args: Dictionary[String, Variant]) -> AgentToolResult:
	var path := AgentWorkspace.resolve_path(str(args.get(ARG_PATH, "")))
	if StringUtils.is_blank(path):
		return AgentToolResult.error("error: path is required")
	if DirAccess.dir_exists_absolute(path):
		return AgentToolResult.error(StringUtils.format("error: path is a directory (not deleted): {}", path))
	if not FileAccess.file_exists(path):
		return AgentToolResult.error(StringUtils.format("error: file not found: {}", path))
	FileUtils.delete_file(path)
	var message := StringUtils.format("deleted {}", path)
	return AgentToolResult.ok(message, AgentToolResult.ui_details(ChatEntry.TITLE_RESULT, message))
# AgentTool-Interface-Implement-End
