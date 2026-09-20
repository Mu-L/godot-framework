class_name AgentPrompt
extends RefCounted

## Project prompt — loads the workspace-root AGENTS.md once and caches its text.
## The file text is appended to a session right after the system prompt (messages[0]); it is
## identified by role + content so the AGENTS.md text never has to be re-read for matching.


const PROMPT_REL := "AGENTS.md"

static var agent_context: String = ""


static func _static_init() -> void:
	var path := AgentWorkspace.resolve_path(PROMPT_REL)
	if not FileAccess.file_exists(path):
		return
	agent_context = FileUtils.read_file_to_string(path)
	pass


static func get_agent_context() -> String:
	return agent_context

static func has_agent_context() -> bool:
	return StringUtils.is_not_blank(agent_context)


static func is_agent_context_message(msg: ChatMessage) -> bool:
	return msg.role == ChatMessage.ROLE_SYSTEM && msg.content == agent_context
