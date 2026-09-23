class_name AgentNotification
extends RefCounted

## Desktop notifications for agent runs — a toast pops up bottom-right of the screen when a run
## ends while the app window is in the background, plus an optional sound clip. Both are toggled
## in [AgentSettingDialog] and persisted through [AgentNotifySetting].


## Fade of the notification sound when it starts and when its configured duration elapses.
const START_FADE_SECONDS := 0.3
const STOP_FADE_SECONDS := 0.5


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
	var entry: ChatEntry = session.chat_entries.back()
	if AgentSetting.get_notification_window():
		var accent := AgentColors.error if entry.kind == ChatEntry.KIND_ERROR else AgentColors.success
		DesktopToast.show_toast(entry.title, entry.body, accent)
	if AgentSetting.get_notification_sound():
		play_sound_notifications()
	pass


## Play the configured folder as one continuous playlist, silenced after the configured seconds.
## A playlist that is still running keeps going and a paused one is resumed, so a second run does
## not restart the same beep — only a different folder starts a fresh playlist.
func play_sound_notifications() -> void:
	var audios := ResourceHelper.get_all_audio_files(AgentSetting.get_notification_sound_folder())
	if audios.is_empty():
		return
	if has_playlist(audios):
		Audio.resume_musics(START_FADE_SECONDS)
	else:
		Audio.play_musics(audios, 1.0, START_FADE_SECONDS)
	SchedulerBus.schedule(stop_sound_notifications, AgentSetting.get_notification_sound_seconds() * 1000)
	pass


## True while the music player already runs (or holds) exactly these clips. The playlist rotates as
## it plays, so the order is ignored.
func has_playlist(clips: Array[String]) -> bool:
	if not Audio.is_playing_music() and not Audio.is_music_paused():
		return false
	var loaded := Audio.musics.duplicate()
	loaded.sort()
	return loaded == clips


## Fade the music out and pause it, so the next run picks the sound up where this one left it.
func stop_sound_notifications() -> void:
	Audio.pause_musics(STOP_FADE_SECONDS)
	pass
