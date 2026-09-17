class_name AgentToolResult
extends RefCounted

## Outcome of a tool execution. `content` is sent to the LLM as the tool message body.
## UI uses `details` keys [member DETAIL_TITLE] and [member DETAIL_BODY]; omit both to skip a result bubble.

const DETAIL_TITLE := "title"
const DETAIL_BODY := "body"

var content: String = ""
var is_error: bool = false
var details: Dictionary[String, String] = {}


func _init(_content: String = "", _is_error: bool = false, _details: Dictionary[String, String] = {}) -> void:
	content = _content
	is_error = _is_error
	details = _details
	pass


static func ui_details(title: String, body: String = StringUtils.EMPTY) -> Dictionary[String, String]:
	return {
		DETAIL_TITLE: title,
		DETAIL_BODY: body,
	}


static func ok(text: String, _details: Dictionary[String, String] = {}) -> AgentToolResult:
	if _details.is_empty():
		_details = ui_details(ChatEntry.TITLE_RESULT, text)
	return AgentToolResult.new(text, false, _details)


static func error(text: String, _details: Dictionary[String, String] = {}) -> AgentToolResult:
	if _details.is_empty():
		_details = ui_details(ChatEntry.TITLE_RESULT, text)
	return AgentToolResult.new(text, true, _details)
