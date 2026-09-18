class_name AgentToolResult
extends RefCounted

## Outcome of a tool execution. `content` is sent to the LLM as the tool message body.
## UI uses `details` for the result bubble, including optional changed-line counts.

const DETAIL_TITLE := "title"
const DETAIL_BODY := "body"
const DETAIL_PATH := "path"
const DETAIL_LINES_ADDED := "lines_added"
const DETAIL_LINES_REMOVED := "lines_removed"

var content: String = ""
var is_error: bool = false
var details: Dictionary[String, String] = {}


func _init(_content: String = "", _is_error: bool = false, _details: Dictionary[String, String] = {}) -> void:
	content = _content
	is_error = _is_error
	details = _details
	pass


static func ui_details(
	title: String,
	body: String = StringUtils.EMPTY,
	lines_added: int = -1,
	lines_removed: int = -1,
	path: String = StringUtils.EMPTY
) -> Dictionary[String, String]:
	var result: Dictionary[String, String] = {
		DETAIL_TITLE: title,
		DETAIL_BODY: body,
	}
	if lines_added >= 0:
		result[DETAIL_LINES_ADDED] = str(lines_added)
	if lines_removed >= 0:
		result[DETAIL_LINES_REMOVED] = str(lines_removed)
	if StringUtils.is_not_blank(path):
		result[DETAIL_PATH] = path
	return result


static func ok(text: String, _details: Dictionary[String, String] = {}) -> AgentToolResult:
	if _details.is_empty():
		_details = ui_details(ChatEntry.TITLE_RESULT, text)
	return AgentToolResult.new(text, false, _details)


static func error(text: String, _details: Dictionary[String, String] = {}) -> AgentToolResult:
	if _details.is_empty():
		_details = ui_details(ChatEntry.TITLE_RESULT, text)
	return AgentToolResult.new(text, true, _details)
