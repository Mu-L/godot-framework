class_name OpenAiCompletion
extends RefCounted

## Result of a chat completion that may include tool calls.

var content: String = ""
## Thinking-mode output. Must be sent back with assistant tool-call messages.
var reasoning_content: String = ""
var tool_calls: Array[OpenAiToolCall] = []
var finish_reason: String = ""
var error: String = ""
var usage: OpenAiUsage = OpenAiUsage.new()


func has_error() -> bool:
	return StringUtils.is_not_blank(error)
