class_name ImageToTextTool
extends AgentTool

const NAME := "image_to_text"
const ARG_PATH := "path"
const ARG_PROMPT := "prompt"

const COMMAND := ".dependency/python/python.exe .ai/image-to-text/image_to_text.py --images {} --prompt '{}'"
const MAX_PROMPT_LENGTH := 4000
const TIMEOUT_MILLIS := TimeUtils.MILLIS_PER_MINUTE * 10


func _init() -> void:
	name = NAME
	description = "Describe an image or extract its visible text with the local MiniCPM-V vision model. Requires an image path and an instruction prompt."
	pass


# AgentTool-Interface-Implement-Start
func get_parameters() -> OpenAiToolDef.Parameters:
	var params := OpenAiToolDef.Parameters.object()
	params.string_prop(ARG_PATH, "Absolute or project-relative image path", true)
	params.string_prop(ARG_PROMPT, "Image instruction, such as OCR, description, or structured extraction", true)
	return params


func async_execute(args: Dictionary[String, Variant]) -> AgentToolResult:
	var path := AgentWorkspace.resolve_path(str(args.get(ARG_PATH, "")))
	if StringUtils.is_blank(path):
		return AgentToolResult.error("error: path is required")
	if not FileAccess.file_exists(path):
		return AgentToolResult.error(StringUtils.format("error: image not found: {}", path))
	if StringUtils.is_blank(ImageHelper.get_image_format(path, StringUtils.EMPTY)):
		return AgentToolResult.error(StringUtils.format("error: unsupported image format: {}", path))

	var prompt := StringUtils.truncate(str(args.get(ARG_PROMPT, "")).strip_edges(), MAX_PROMPT_LENGTH)

	var command := StringUtils.format(COMMAND, path, prompt)
	var argv := BashTool.build_argv_from_command(command)
	var exec_result := await OSUtils.async_execute(argv, false, TIMEOUT_MILLIS)
	var output := exec_result.output.build_string().strip_edges()
	if exec_result.exit_code != 0:
		var error_text := StringUtils.format("error: image-to-text failed with exit code {}", exec_result.exit_code)
		if StringUtils.is_not_blank(output):
			error_text += FileUtils.NEWLINE_LF + StringUtils.truncate_last(output, MAX_OUTPUT, TRUNCATED_SUFFIX)
		return AgentToolResult.error(error_text)
	if StringUtils.is_blank(output):
		return AgentToolResult.error("error: image-to-text returned no text", AgentToolResult.ui_file_details_message(path, "no text returned"))

	var exit_code := StringUtils.format("exit_code: {}", exec_result.exit_code)
	var text := StringUtils.truncate(output, MAX_OUTPUT, TRUNCATED_SUFFIX)
	return AgentToolResult.ok(text, AgentToolResult.ui_details(exit_code, text))
# AgentTool-Interface-Implement-End
