class_name AgentSetting
extends RefCounted

## Persisted notification preferences for agent runs — the toast and the sound played when a run
## ends. Behavior lives in [AgentNotification]; the fields are edited by [AgentSettingDialog].

const NOTIFICATION_WINDOW_ENABLED_KEY := "agent_notification_window"
const NOTIFICATION_SOUND_ENABLED_KEY := "agent_notification_sound"
const NOTIFICATION_SOUND_SECONDS_KEY := "agent_notification_sound_seconds"
const NOTIFICATION_SOUND_FOLDER_KEY := "agent_notification_sound_folder"

const DEFAULT_SOUND_FOLDER := "res://test/asset/"
const DEFAULT_SOUND_SECONDS := 5
const MIN_SOUND_SECONDS := 1
const MAX_SOUND_SECONDS := 120


static func get_notification_window() -> bool:
	return Setting.get_bool(NOTIFICATION_WINDOW_ENABLED_KEY, true)


static func set_notification_window(enabled: bool) -> void:
	Setting.set_bool(NOTIFICATION_WINDOW_ENABLED_KEY, enabled)
	Setting.save()
	pass


static func get_notification_sound() -> bool:
	return Setting.get_bool(NOTIFICATION_SOUND_ENABLED_KEY, true)


static func set_notification_sound(enabled: bool) -> void:
	Setting.set_bool(NOTIFICATION_SOUND_ENABLED_KEY, enabled)
	Setting.save()
	pass


## Playback length in seconds — the clip is silenced once it elapses.
static func get_notification_sound_seconds() -> int:
	return clampi(Setting.get_int(NOTIFICATION_SOUND_SECONDS_KEY, DEFAULT_SOUND_SECONDS), MIN_SOUND_SECONDS, MAX_SOUND_SECONDS)


static func set_notification_sound_seconds(seconds: int) -> void:
	Setting.set_int(NOTIFICATION_SOUND_SECONDS_KEY, clampi(seconds, MIN_SOUND_SECONDS, MAX_SOUND_SECONDS))
	Setting.save()
	pass


## Folder holding the notification clips — a `res://` folder or any OS folder.
static func get_notification_sound_folder() -> String:
	return Setting.get_string(NOTIFICATION_SOUND_FOLDER_KEY, DEFAULT_SOUND_FOLDER).strip_edges()


static func set_notification_sound_folder(folder: String) -> void:
	Setting.set_string(NOTIFICATION_SOUND_FOLDER_KEY, folder.strip_edges())
	Setting.save()
	pass
