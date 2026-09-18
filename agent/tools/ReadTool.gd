class_name ReadTool
extends AgentTool

const NAME := "read"
const ARG_PATH := "path"
const ARG_OFFSET := "offset"
const ARG_LIMIT := "limit"

const DEFAULT_LIMIT := 500
const MAX_LIMIT := 2000


func _init() -> void:
	name = NAME
	description = "Read a text file from the project workspace. Supports line-based pagination using offset and limit."
	pass

# AgentTool-Interface-Implement-Start
func get_parameters() -> OpenAiToolDef.Parameters:
	var params := OpenAiToolDef.Parameters.object()
	params.string_prop(ARG_PATH, "Absolute or project-relative file path", true)
	params.integer_prop(ARG_OFFSET, "Zero-based line offset to start reading from (default 0)", false)
	params.integer_prop(ARG_LIMIT, "Maximum number of lines to return (default 500, max 2000)", false)
	return params


func async_execute(args: Dictionary[String, Variant]) -> AgentToolResult:
	var path := AgentWorkspace.resolve_path(str(args.get(ARG_PATH, "")))
	if StringUtils.is_blank(path):
		return AgentToolResult.error("error: path is required")
	if not FileAccess.file_exists(path):
		return AgentToolResult.error(StringUtils.format("error: file not found: {}", path))
	var lines := FileUtils.read_file_to_lines(path, true)
	if lines.is_empty():
		if FileAccess.get_size(path) > 0:
			return AgentToolResult.error(StringUtils.format("error: file is binary or not valid UTF-8: {}", path))
		return AgentToolResult.ok(StringUtils.EMPTY)

	var offset := maxi(0, parse_int(args.get(ARG_OFFSET, 0), 0))
	var limit := clampi(parse_int(args.get(ARG_LIMIT, DEFAULT_LIMIT), DEFAULT_LIMIT), 1, MAX_LIMIT)
	var total_lines := lines.size()
	if offset >= total_lines:
		return AgentToolResult.error(StringUtils.format("error: offset {} exceeds file line count {}", offset, total_lines))

	var end := mini(offset + limit, total_lines)
	var text := FileUtils.NEWLINE_LF.join(lines.slice(offset, end))
	return AgentToolResult.ok(StringUtils.truncate(text, MAX_OUTPUT))
# AgentTool-Interface-Implement-End
