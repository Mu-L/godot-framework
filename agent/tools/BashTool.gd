class_name BashTool
extends AgentTool

const NAME := "bash"
const ARG_COMMAND := "command"


func _init() -> void:
	name = NAME
	description = "Run a shell command in the project root. Returns stdout/stderr and exit code."
	pass

# AgentTool-Interface-Implement-Start
func get_parameters() -> OpenAiToolDef.Parameters:
	return OpenAiToolDef.Parameters.object().string_prop(ARG_COMMAND, "Shell command to execute", true)


func async_execute(args: Dictionary[String, String]) -> AgentToolResult:
	var argv := build_argv_from_args(args)
	if argv.is_empty():
		return AgentToolResult.error("error: command is required")
	var exec_result := await OSUtils.async_execute(argv, false)
	var exit_code := StringUtils.format("exit_code: {}", exec_result.exit_code)
	var exec_output := exec_result.output.build_string()
	
	var build := StringBuilder.new()
	build.append_line(exit_code)
	build.append(StringUtils.truncate(exec_output, AgentTool.MAX_OUTPUT))
	
	var text := build.build_string()
	var is_error := exec_result.exit_code != 0
	return AgentToolResult.new(text, is_error,  AgentToolResult.ui_details(exit_code, exec_output))
# AgentTool-Interface-Implement-End

func build_argv_from_args(args: Dictionary[String, String]) -> PackedStringArray:
	var command := str(args.get(ARG_COMMAND, "")).strip_edges()
	if command.is_empty():
		return PackedStringArray()
	return build_argv(wrap_command(command))


static func build_argv(command: String) -> PackedStringArray:
	if OSUtils.is_windows():
		return PackedStringArray(["cmd.exe", "/c", command])
	return PackedStringArray(["/bin/sh", "-c", command])


static func wrap_command(command: String) -> String:
	var workspace_root := AgentWorkspace.get_root()
	if StringUtils.is_blank(workspace_root):
		return command
	if OSUtils.is_windows():
		return StringUtils.format('cd /d "{}" && {}', workspace_root, command)
	return StringUtils.format('cd "{}" && {}', workspace_root, command)
