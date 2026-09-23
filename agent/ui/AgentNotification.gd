class_name AgentNotification
extends RefCounted

## Desktop notifications for agent runs — a toast pops up bottom-right of the screen
## when a run ends while the app window is in the background.


func setup() -> void:
	# Deferred: AgentSessionManager appends the outcome chat entry in its own agent_end handler.
	AgentEvents.events.agent_end.connect(on_agent_end, CONNECT_DEFERRED)
	pass


## Desktop toast when a run ends — visible outside the app window, bottom-right of the screen.
func on_agent_end(session_id: int, error_message: String) -> void:
	# A stop comes from the app window, so the user is already looking at it.
	if error_message.begins_with("Stop"):
		return
	var session := AgentSessionStore.load_session(session_id)
	if session == null or session.chat_entries.is_empty():
		return
	# The newest chat entry is the outcome: AgentSessionManager already appended the error
	# bubble for a failed run, otherwise it is the agent reply.
	var entry: ChatEntry = session.chat_entries[session.chat_entries.size() - 1]
	var accent := AgentColors.error if entry.kind == ChatEntry.KIND_ERROR else AgentColors.success
	DesktopToast.show_toast(entry.title, entry.body, accent)
	pass
