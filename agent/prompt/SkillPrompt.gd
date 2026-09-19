class_name SkillPrompt
extends RefCounted

## Skill index prompt — loads the skill README once and caches it plus its LLM message.


const README_REL := ".agents/skills/README.md"
const LLM_MESSAGE_HEADER := "Skill index (.agents/skills/README.md):"

static var cached_readme_text: String = ""
static var cached_llm_message: String = ""


static func _static_init() -> void:
	var path := AgentWorkspace.resolve_path(README_REL)
	if not FileAccess.file_exists(path):
		return
	cached_readme_text = FileUtils.read_file_to_string(path)
	if StringUtils.is_not_blank(cached_readme_text):
		cached_llm_message = StringUtils.format("{}\n\n{}", LLM_MESSAGE_HEADER, cached_readme_text.strip_edges())
	pass


static func readme_text() -> String:
	return cached_readme_text


static func llm_message() -> String:
	return cached_llm_message


static func has_readme() -> bool:
	return StringUtils.is_not_blank(cached_readme_text)


static func is_llm_message(msg: ChatMessage) -> bool:
	return msg.role == ChatMessage.ROLE_SYSTEM and msg.content.begins_with(LLM_MESSAGE_HEADER)
