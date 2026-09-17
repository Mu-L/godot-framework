class_name AgentTool
extends RefCounted

## Base tool definition. Each tool exposes an OpenAI function schema and async_execute() returning AgentToolResult.

const MAX_OUTPUT := 32_000
const MAX_FILE_RESULTS := 512
const MAX_FILE_BYTES := FileUtils.BYTES_PER_KB * 128


var name: String = ""
var description: String = ""


func get_schema() -> OpenAiToolDef:
	var def := OpenAiToolDef.new()
	def.function.name = name
	def.function.description = description
	def.function.parameters = get_parameters()
	return def


func get_parameters() -> OpenAiToolDef.Parameters:
	return OpenAiToolDef.Parameters.new()


func async_execute(args: Dictionary[String, String]) -> AgentToolResult:
	return AgentToolResult.error("not implemented")


func parse_args(raw: String) -> Dictionary[String, String]:
	var parsed: Dictionary[String, String] = {}
	if StringUtils.is_blank(raw):
		return parsed
	var data = JSON.parse_string(raw.strip_edges())
	if typeof(data) != TYPE_DICTIONARY:
		return parsed
	var dict: Dictionary = data
	for key: Variant in dict.keys():
		var value: Variant = dict[key]
		parsed[str(key)] = "" if value == null else str(value)
	return parsed


func parse_bool(raw: String) -> bool:
	var value := raw.strip_edges().to_lower()
	return value == "true" or value == "1" or value == "yes"


func parse_nonneg_int(raw: String, default_value: int) -> int:
	var value := raw.strip_edges()
	if value.is_empty() or not value.is_valid_int():
		return default_value
	return maxi(0, int(value))
