class_name SkillPrompt
extends RefCounted

## Skill index prompt — loads the skill README once and caches its text.
## The index is appended to a session right after the system prompt (messages[0]); it is
## identified by role + position so the auto-generated README text never has to be matched.


const SKILL_README_PATH := ".agents/skills/README.md"

static var skill_context: String = ""


static func _static_init() -> void:
	var path := AgentWorkspace.resolve_path(SKILL_README_PATH)
	if not FileAccess.file_exists(path):
		return
	skill_context = FileUtils.read_file_to_string(path)
	pass


static func get_skill_context() -> String:
	return skill_context

static func has_skill_context() -> bool:
	return StringUtils.is_not_blank(skill_context)


static func is_skill_context_message(msg: ChatMessage) -> bool:
	return msg.role == ChatMessage.ROLE_SYSTEM && msg.content == skill_context
