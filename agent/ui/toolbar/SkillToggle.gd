class_name SkillToggle
extends RefCounted

## Toolbar toggle for the skill index prompt (session append/remove).

const SETTING_KEY := "agent_skill_in_prompt_enabled"

var button: Button


func setup(p_button: Button) -> void:
	button = p_button
	button.toggled.connect(on_toggled)
	AgentEvents.events.theme_changed.connect(on_ui_theme_changed)
	AgentEvents.events.theme_color_changed.connect(on_ui_theme_changed)
	AgentEvents.events.session_selected.connect(refresh_toggle_button)
	AgentEvents.events.session_added.connect(on_session_added)
	refresh_toggle_button(AgentSessionManager.active_session_id)
	pass

static func on_session_added(session_id: int, _title: String) -> void:
	if not Setting.get_bool(SETTING_KEY, true):
		return
	append_skill_context(session_id)
	pass


static func has_skill_context_in(session: AgentSession) -> bool:
	if session == null:
		return false
	for entry: ChatEntry in session.chat_entries:
		if entry.kind == ChatEntry.KIND_SKILL:
			return true
	return false


static func append_skill_context(session_id: int) -> void:
	var session := AgentSessionStore.load_session(session_id)
	if session == null or has_skill_context_in(session):
		return
	if not SkillPrompt.has_readme():
		return
	session.messages.append(ChatMessage.system(SkillPrompt.llm_message()))
	AgentSessionManager.add_chat_entry(session_id, ChatEntry.KIND_SKILL, ChatEntry.TITLE_SKILL, SkillPrompt.readme_text())
	pass


static func remove_skill_context(session_id: int) -> void:
	var session := AgentSessionStore.load_session(session_id)
	if session == null:
		return

	var kept_messages: Array[ChatMessage] = []
	for msg: ChatMessage in session.messages:
		if not SkillPrompt.is_llm_message(msg):
			kept_messages.append(msg)
	session.messages = kept_messages

	var kept_entries: Array[ChatEntry] = []
	for entry: ChatEntry in session.chat_entries:
		if entry.kind != ChatEntry.KIND_SKILL:
			kept_entries.append(entry)
	session.chat_entries = kept_entries
	pass


func on_ui_theme_changed() -> void:
	refresh_toggle_button(AgentSessionManager.active_session_id)
	pass


func refresh_toggle_button(session_id: int) -> void:
	if button == null:
		return
	var enabled := Setting.get_bool(SETTING_KEY, true)
	if session_id != AgentSessionManager.INVALID_SESSION_ID:
		enabled = has_skill_context_in(AgentSessionStore.load_session(session_id))
	var tooltip := "Add skill index to this chat" if not enabled else "Remove skill index from this chat"
	AgentToolbarButton.style(button, tooltip)
	button.set_block_signals(true)
	button.button_pressed = enabled
	button.set_block_signals(false)
	pass


func on_toggled(enabled: bool) -> void:
	Setting.set_bool(SETTING_KEY, enabled)
	Setting.save()

	var session_id := AgentSessionManager.active_session_id
	if session_id == AgentSessionManager.INVALID_SESSION_ID:
		refresh_toggle_button(session_id)
		return

	if enabled:
		append_skill_context(session_id)
	else:
		remove_skill_context(session_id)

	AgentSessionManager.persist_session(session_id)
	AgentEvents.events.skill_context_changed.emit(session_id)
	refresh_toggle_button(session_id)
	pass
