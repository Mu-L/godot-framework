class_name AgentSessionStore
extends RefCounted

## Persists agent chat sessions as JSON files under the workspace `.agent/sessions/` folder.

const SESSIONS_SUBDIR := ".gai/sessions"
const FILE_SUFFIX := ".json"

# Dictionary[int, AgentSession]
static var sessions: ConcurrentMapInt = ConcurrentMapInt.new()


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

static func get_sessions_dir() -> String:
	return AgentWorkspace.get_root().path_join(SESSIONS_SUBDIR)


static func get_session_path(session_id: int) -> String:
	return get_sessions_dir().path_join(str(session_id) + FILE_SUFFIX)


static func ensure_sessions_dir() -> bool:
	var dir_path := get_sessions_dir()
	if DirAccess.dir_exists_absolute(dir_path):
		return true
	var err := DirAccess.make_dir_recursive_absolute(dir_path)
	return err == OK


# ---------------------------------------------------------------------------
# Create
# ---------------------------------------------------------------------------

static func create_session() -> AgentSession:
	var session_id := IdUtils.short_uuid()
	var session := AgentSession.new(session_id)
	sessions.put(session.id, session)
	return session

# ---------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------

static func save_session(session_id: int) -> void:
	var session: AgentSession = load_session(session_id)
	if session == null:
		return
	if not ensure_sessions_dir():
		Log.error("agent chat save failed, cannot create dir:[{}]", get_sessions_dir())
		return
	var json := JsonUtils.object_to_json(session)
	FileUtils.write_string_to_file(get_session_path(session.id), json)
	pass


static func delete_session(session_id: int) -> void:
	if session_id < 0:
		return
	sessions.remove(session_id)
	FileUtils.delete_file_or_directory(get_session_path(session_id))
	pass


# ---------------------------------------------------------------------------
# Load
# ---------------------------------------------------------------------------



static func load_session(session_id: int) -> AgentSession:
	var session := sessions.get_value(session_id) as AgentSession
	if session != null:
		return session
	session = load_session_file(get_session_path(session_id))
	if session != null:
		var existing := sessions.put_if_absent(session_id, session) as AgentSession
		if existing != null:
			return existing
	return session


static func load_session_file(file_path: String) -> AgentSession:
	var text := FileUtils.read_file_to_string(file_path)
	if StringUtils.is_blank(text):
		return null
	var session: AgentSession = JsonUtils.json_to_object(text, AgentSession)
	if session == null:
		Log.error("agent chat load failed, invalid json:[{}]", file_path)
		return null
	session.id = int(file_path.get_file().trim_suffix(FILE_SUFFIX))
	return session
