class_name AgentPromptToggle
extends RefCounted

## Toolbar toggle for the AGENTS.md project prompt (session append/remove).

var button: Button


func setup(p_button: Button) -> void:
	button = p_button
	button.toggled.connect(on_toggled)
	gdf.events.theme_changed.connect(refresh_toggle_button)
	gdf.events.theme_color_changed.connect(refresh_toggle_button)
	AgentEvents.events.session_added.connect(on_session_added)
	refresh_toggle_button()
	pass

static func on_session_added(session_id: int, _title: String) -> void:
	if not AgentSetting.get_agent_prompt_in_prompt_enabled():
		return
	append_agent_context(session_id)
	pass


static func has_agent_context_in(session: AgentSession) -> bool:
	if session == null:
		return false
	for entry: ChatEntry in session.chat_entries:
		if entry.kind == ChatEntry.KIND_AGENT_PROMPT:
			return true
	return false


static func append_agent_context(session_id: int) -> void:
	var session := AgentSessionStore.load_session(session_id)
	if session == null or has_agent_context_in(session):
		return
	if not AgentPrompt.has_agent_context():
		return
	session.messages.append(ChatMessage.system(AgentPrompt.get_agent_context()))
	AgentSessionManager.add_chat_entry(session_id, ChatEntry.KIND_AGENT_PROMPT, ChatEntry.TITLE_AGENT_PROMPT, AgentPrompt.get_agent_context())
	pass


static func remove_agent_context(session_id: int) -> void:
	var session := AgentSessionStore.load_session(session_id)
	if session == null:
		return

	var kept_messages: Array[ChatMessage] = []
	for msg in session.messages:
		if not AgentPrompt.is_agent_context_message(msg):
			kept_messages.append(msg)
	session.messages = kept_messages

	var kept_entries: Array[ChatEntry] = []
	for entry: ChatEntry in session.chat_entries:
		if entry.kind != ChatEntry.KIND_AGENT_PROMPT:
			kept_entries.append(entry)
	session.chat_entries = kept_entries
	pass


func refresh_toggle_button() -> void:
	var enabled := AgentSetting.get_agent_prompt_in_prompt_enabled()
	var tooltip := I18n.t("agent.toolbar.add_agents") if not enabled else I18n.t("agent.toolbar.remove_agents")
	AgentToolbarButton.style(button, tooltip)
	button.set_block_signals(true)
	button.button_pressed = enabled
	button.set_block_signals(false)
	pass


func on_toggled(enabled: bool) -> void:
	AgentSetting.set_agent_prompt_in_prompt_enabled(enabled)

	refresh_toggle_button()

	var session_id := AgentSessionManager.active_session_id
	if AgentSessionManager.has_chat_history(session_id):
		return

	if enabled:
		append_agent_context(session_id)
	else:
		remove_agent_context(session_id)
	AgentSessionManager.persist_session(session_id)
	AgentEvents.events.agent_context_changed.emit(session_id)
	pass
