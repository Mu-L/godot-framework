class_name BashTool
extends AgentTool

const NAME := "bash"
const ARG_COMMAND := "command"
const WINDOWS_GIT_BASH_PATHS: PackedStringArray = [
	"C:/Program Files/Git/bin/bash.exe",
	"C:/Program Files (x86)/Git/bin/bash.exe",
]


func _init() -> void:
	name = NAME
	description = "Run a Bash command in the project root (Git Bash on Windows). Returns stdout/stderr and exit code."
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
	var bash := "/bin/bash"
	if OSUtils.is_windows():
		bash = "bash.exe"
		for path in WINDOWS_GIT_BASH_PATHS:
			if FileAccess.file_exists(path):
				bash = path
				break
	var working_directory := AgentWorkspace.get_root()
	var bash_command := StringUtils.format("cd -- '{}' && {}", working_directory, command)
	if OSUtils.is_windows():
		var encoded_command := Marshalls.raw_to_base64(command.to_utf8_buffer())
		bash_command = StringUtils.format("cd -- '{}' && /bin/bash --noprofile --norc <(printf %s {} | /usr/bin/base64 --decode)", working_directory, encoded_command)
	return PackedStringArray([bash, "--noprofile", "--norc", "-c", bash_command])
