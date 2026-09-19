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


func async_execute(args: Dictionary[String, Variant]) -> AgentToolResult:
	var argv := build_argv_from_args(args)
	if argv.is_empty():
		return AgentToolResult.error("error: command is required")
	var exec_result := await OSUtils.async_execute(argv, false)
	var exit_code := StringUtils.format("exit_code: {}", exec_result.exit_code)
	var exec_output := exec_result.output.build_string()
	
	var build := StringBuilder.new()
	build.append_line(exit_code)
	build.append(StringUtils.truncate_last(exec_output, MAX_OUTPUT, TRUNCATED_SUFFIX + FileUtils.NEWLINE_LF))
	
	var text := build.build_string()
	var is_error := exec_result.exit_code != 0
	return AgentToolResult.new(text, is_error,  AgentToolResult.ui_details(exit_code, exec_output))
# AgentTool-Interface-Implement-End

func build_argv_from_args(args: Dictionary[String, Variant]) -> PackedStringArray:
	var command := str(args.get(ARG_COMMAND, "")).strip_edges()
	if command.is_empty():
		return PackedStringArray()
	return OSUtils.build_shell_argv(command, AgentWorkspace.get_root())
