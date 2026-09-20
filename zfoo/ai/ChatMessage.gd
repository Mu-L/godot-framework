class_name ChatMessage
extends RefCounted

const ROLE_SYSTEM := "system"
const ROLE_USER := "user"
const ROLE_ASSISTANT := "assistant"
const ROLE_TOOL := "tool"

var role: String = ""
var content: String = ""
var tool_call_id: String = ""
var tool_calls: Array[OpenAiToolCall] = []
## Thinking-mode output. Thinking models reject a tool-call turn that drops it.
var reasoning_content: String = ""


func _init(_role: String = "", _content: String = "") -> void:
	role = _role
	content = _content
	pass


static func system(text: String) -> ChatMessage:
	return ChatMessage.new(ROLE_SYSTEM, text)


static func user(text: String) -> ChatMessage:
	return ChatMessage.new(ROLE_USER, text)


static func assistant(text: String, reasoning: String = "") -> ChatMessage:
	var msg := ChatMessage.new(ROLE_ASSISTANT, text)
	msg.reasoning_content = reasoning
	return msg


static func tool_result(call_id: String, text: String) -> ChatMessage:
	var msg := ChatMessage.new(ROLE_TOOL, text)
	msg.tool_call_id = call_id
	return msg


static func assistant_tool_calls(calls: Array[OpenAiToolCall], text: String = "", reasoning: String = "") -> ChatMessage:
	var msg := ChatMessage.new(ROLE_ASSISTANT, text)
	msg.tool_calls = calls
	msg.reasoning_content = reasoning
	return msg


## OpenAI wire shape
func to_api_dict() -> Dictionary:
	if role == ROLE_TOOL:
		return {
			"role": role,
			"content": content,
			"tool_call_id": tool_call_id,
		}
	if not tool_calls.is_empty():
		var wire := {
			"role": role,
			"content": StringUtils.trim(content),
			"reasoning_content": StringUtils.trim(reasoning_content),
			"tool_calls": tool_calls,
		}
		return wire
	var wire := {
		"role": role,
		"content": content,
	}
	if role == ROLE_ASSISTANT and StringUtils.is_not_blank(reasoning_content):
		wire["reasoning_content"] = StringUtils.trim(reasoning_content)
	return wire
