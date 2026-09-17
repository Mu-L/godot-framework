class_name FileUtils
extends Object

# ---------------------------------------------------------------------------
# Constants — byte/bit units and line endings
# ---------------------------------------------------------------------------

# Bytes
const ONE_BYTE: int = 1
const BYTES_PER_KB: int = 1024
const BYTES_PER_MB: int = BYTES_PER_KB * 1024
const BYTES_PER_GB: int = BYTES_PER_MB * 1024

# Bits
const BITS_PER_BYTE: int = 8
const BITS_PER_KB: int = BYTES_PER_KB * 8
const BITS_PER_MB: int = BYTES_PER_MB * 8
const BITS_PER_GB: int = BYTES_PER_GB * 8

# Line endings (text files)
const NEWLINE_LF: String = "\n"
const NEWLINE_CR: String = "\r"
const NEWLINE_CRLF: String = "\r\n"


# ---------------------------------------------------------------------------
# Line endings
# ---------------------------------------------------------------------------

static func normalize_line_endings_to_lf(s: String) -> String:
	return s.replace(NEWLINE_CRLF, NEWLINE_LF).replace(NEWLINE_CR, NEWLINE_LF)


# ---------------------------------------------------------------------------
# Project root
# ---------------------------------------------------------------------------

## Returns the absolute path to the folder containing project.godot.
static func get_project_root_path() -> String:
	var dir := ProjectSettings.globalize_path("res://")
	for _i in range(8):
		if FileAccess.file_exists(dir.path_join("project.godot")):
			return dir
		var parent := dir.get_base_dir()
		if parent == dir:
			break
		dir = parent
	return ProjectSettings.globalize_path("res://")


# ---------------------------------------------------------------------------
# File read / write / delete
# ---------------------------------------------------------------------------

# Append content to the file.
static func write_string_to_file(filePath: String, content: String) -> void:
	var file := FileAccess.open(filePath, FileAccess.WRITE)
	# bread and butter
	file.store_string(content)
	file = null
	pass


static func read_file_to_string(filePath: String) -> String:
	if not FileAccess.file_exists(filePath):
		return StringUtils.EMPTY
	var bytes := read_file_to_byte_array(filePath)
	if bytes.is_empty():
		return StringUtils.EMPTY
	# Avoid get_as_text() — NUL bytes log "Unexpected NUL character" and become U+FFFD.
	if bytes.find(0) >= 0:
		return StringUtils.EMPTY
	var text := bytes.get_string_from_utf8()
	if text.is_empty() and bytes.size() > 0:
		return StringUtils.EMPTY
	return text


static func read_file_to_byte_array(filePath: String) -> PackedByteArray:
	# make sure our file exists on users system
	if !FileAccess.file_exists(filePath):
		return PackedByteArray()

	# allow reading only for file
	var file := FileAccess.open(filePath, FileAccess.READ)

	var buffer := file.get_buffer(file.get_length())
	file = null
	return buffer


## Reads a text file as lines; empty array for missing, binary, or non-UTF-8 files.
static func read_file_to_lines(abs_path: String) -> Array[String]:
	var text := read_file_to_string(abs_path)
	if text.is_empty() and FileAccess.file_exists(abs_path) and FileAccess.get_size(abs_path) > 0:
		return []
	return text.split(StringUtils.LS, false)


static func delete_file(filePath: String) -> void:
	if !FileAccess.file_exists(filePath):
		return
	DirAccess.remove_absolute(filePath)
	pass


# ---------------------------------------------------------------------------
# Directory listing
# ---------------------------------------------------------------------------

# Returns absolute paths of all files in the given folder.
# Set recursive to true to include files in subfolders.
static func get_all_files_in_folder(folderPath: String, recursive: bool = false) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(folderPath)
	if dir == null:
		return files

	for file_name in dir.get_files():
		files.append(folderPath.path_join(file_name))

	if recursive:
		for dir_name in dir.get_directories():
			files.append_array(get_all_files_in_folder(folderPath.path_join(dir_name), true))

	return files


# Returns absolute paths of subdirectories in the given folder.
# Set recursive to true to include nested subdirectories (not the root folder itself).
static func get_all_directories_in_folder(folderPath: String, recursive: bool = false) -> Array[String]:
	var dirs: Array[String] = []
	var dir := DirAccess.open(folderPath)
	if dir == null:
		return dirs
	for dir_name in dir.get_directories():
		var abs := folderPath.path_join(dir_name)
		dirs.append(abs)
		if recursive:
			dirs.append_array(get_all_directories_in_folder(abs, true))
	return dirs


# Returns absolute paths of files in the given folder whose names match a glob pattern.
# Supports * and ? wildcards (Godot String.match). Set recursive to true to search subfolders.
# For path globs (`**/*.gd`), use [method glob] instead.
static func get_files_in_folder_matching(folderPath: String, globPattern: String, recursive: bool = false) -> Array[String]:
	var pattern := globPattern.strip_edges()
	if pattern.is_empty():
		pattern = "*.*"

	var all_files := get_all_files_in_folder(folderPath, recursive)
	if pattern == "*" or pattern == "*.*":
		all_files.sort()
		return all_files

	var matched: Array[String] = []
	for file_path in all_files:
		if file_path.get_file().match(pattern):
			matched.append(file_path)
	matched.sort()
	return matched


# ---------------------------------------------------------------------------
# Recursive glob file discovery
# ---------------------------------------------------------------------------

## Finds files under [param search_root] whose relative path matches [param glob_pattern] (`*`, `?`, `**`, `/`).
## [param max_file_bytes]: omit larger files; [code]0[/code] disables. [param skip_glob_rules]: skip descending into dirs matched by [method glob_match_any].
static func glob(search_root: String, glob_pattern: String, max_file_bytes: int = 1_048_576, skip_glob_rules: Array[String] = []) -> Array[String]:
	var files: Array[String] = []
	if FileAccess.file_exists(search_root):
		if _glob_accepts_file(search_root, search_root, glob_pattern, max_file_bytes):
			files.append(search_root)
	elif DirAccess.dir_exists_absolute(search_root):
		_glob_walk(search_root, search_root, glob_pattern, max_file_bytes, skip_glob_rules, files)
	files.sort()
	return files


## Path of [param abs_path] relative to [param base_dir], using forward slashes (for glob matching).
static func path_relative_to(base_dir: String, abs_path: String) -> String:
	var base := base_dir.replace("\\", "/").rstrip("/")
	var norm := abs_path.replace("\\", "/")
	if norm.begins_with(base + "/"):
		return norm.substr(base.length() + 1)
	return "." if norm == base else abs_path


## True when [param relative_path] matches [param glob_pattern] (`*`, `?`, optional `/` and `**`).
static func path_matches_glob(relative_path: String, glob_pattern: String) -> bool:
	var pattern := glob_pattern.strip_edges().replace("\\", "/")
	if pattern.is_empty():
		return true
	var path := relative_path.replace("\\", "/")
	# `*.gd` — filename only, same as get_files_in_folder_matching.
	if not pattern.contains("/") and not pattern.contains("**"):
		return path.get_file().match(pattern)
	var regex := RegEx.new()
	if regex.compile(_glob_pattern_to_regex(pattern)) != OK:
		return path.get_file().match(pattern)
	return regex.search(path) != null


## Exists, within size limit, and matches glob (empty glob matches all).
static func _glob_accepts_file(search_root: String, abs_path: String, glob_pattern: String, max_file_bytes: int) -> bool:
	if not FileAccess.file_exists(abs_path):
		return false
	if max_file_bytes > 0 and FileAccess.get_size(abs_path) > max_file_bytes:
		return false
	if glob_pattern.strip_edges().is_empty():
		return true
	return _path_matches_glob(_glob_relative_path_for_match(search_root, abs_path), glob_pattern)


## When [param search_root] is a single file, [method path_relative_to] yields `"."` — use the basename for glob.
static func _glob_relative_path_for_match(search_root: String, abs_path: String) -> String:
	var rel := path_relative_to(search_root, abs_path)
	if rel == ".":
		return abs_path.replace("\\", "/").get_file()
	return rel


static func _glob_walk(search_root: String, folder_path: String, glob_pattern: String, max_file_bytes: int, skip_glob_rules: Array[String], files: Array[String]) -> void:
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return
	for file_name in dir.get_files():
		var full := folder_path.path_join(file_name)
		if _glob_accepts_file(search_root, full, glob_pattern, max_file_bytes):
			files.append(full)
	for dir_name in dir.get_directories():
		if not skip_glob_rules.is_empty():
			var child_rel := path_relative_to(search_root, folder_path.path_join(dir_name)).replace("\\", "/")
			if glob_match_any(skip_glob_rules, child_rel):
				continue
		_glob_walk(search_root, folder_path.path_join(dir_name), glob_pattern, max_file_bytes, skip_glob_rules, files)
	pass


static func _glob_pattern_to_regex(glob: String) -> String:
	var build := StringBuilder.new()
	build.append("^")
	var i := 0
	while i < glob.length():
		var two := glob.substr(i, 2) if i + 1 < glob.length() else glob.substr(i, 1)
		if two == "**":
			# `**/` or `**` at end — zero or more path segments.
			build.append("(?:.*/)?")
			i += 2
			if i < glob.length() and glob[i] == "/":
				i += 1
			continue
		var ch := glob[i]
		match ch:
			"*":
				build.append("[^/]*")
			"?":
				build.append("[^/]")
			".":
				build.append("\\.")
			"+", "(", ")", "|", "^", "$", "[", "]", "{", "}", "\\":
				build.append("\\")
				build.append(ch)
			_:
				build.append(ch)
		i += 1
	build.append("$")
	return build.build_string()


# ---------------------------------------------------------------------------
# Ignore-file glob rules (.gitignore, .cursorignore, …)
# ---------------------------------------------------------------------------

## True when [param glob_rule] matches [param path_or_file] (relative path, forward slashes).
##
## [param glob_rule]: One line from an ignore file ([code].dependency/[/code], [code]*.tmp[/code], …). Blank and [code]#[/code] lines → [code]false[/code].
## Leading [code]![/code] is stripped (negation is for the caller). [code]\[/code] normalized to [code]/[/code].
##
## Wildcards use [method String.match] or internal path glob logic; not a full Git ignore engine.
static func glob_match(glob_rule: String, path_or_file: String) -> bool:
	# Raw ignore line → pattern (see class doc above).
	var rule := glob_rule.strip_edges()
	if rule.is_empty() or rule.begins_with("#"):
		return false
	# Negation marker; caller decides whether a matching line un-ignores the path.
	if rule.begins_with("!"):
		rule = rule.substr(1).strip_edges()
		if rule.is_empty():
			return false

	rule = rule.replace("\\", "/").strip_edges()
	if rule.is_empty():
		return false

	var path := path_or_file.replace("\\", "/").strip_edges()
	if path.is_empty():
		return false

	# Trailing slash = directory rule; strip before compare (same as GlobTool._static_init).
	if rule.ends_with("/"):
		rule = rule.substr(0, rule.length() - 1)
	rule = rule.strip_edges()
	if rule.is_empty():
		return false

	# Glob branch: * ? [ — path-shaped rules use path_matches_glob (** supported).
	if rule.contains("*") or rule.contains("?") or rule.contains("["):
		if rule.contains("/"):
			return path_matches_glob(path, rule)
		# No slash: match basename (e.g. *.tmp) or any directory segment (e.g. data_*).
		if path.get_file().match(rule):
			return true
		for segment in path.split("/"):
			if segment.match(rule):
				return true
		return false

	# Literal path prefix (e.g. .cursor/skills/humanizer/...).
	if rule.contains("/"):
		return path == rule or path.begins_with(rule + "/")

	# Literal name without slash: root, prefix, basename, or any segment (.idea, export.cfg).
	if path == rule or path.begins_with(rule + "/"):
		return true
	if path.get_file() == rule:
		return true
	for segment in path.split("/"):
		if segment == rule:
			return true
	return false


## True when [param path_or_file] matches any line in [param glob_rules] ([method glob_match]). Empty [param glob_rules] → [code]false[/code].
static func glob_match_any(glob_rules: Array[String], path_or_file: String) -> bool:
	for glob_rule in glob_rules:
		if glob_match(glob_rule, path_or_file):
			return true
	return false


# ---------------------------------------------------------------------------
# Folder file queries
# ---------------------------------------------------------------------------

# Returns the absolute path of the newest file in folderPath (non-recursive).
static func get_newest_file_in_folder(folder_path: String) -> String:
	if not DirAccess.dir_exists_absolute(folder_path):
		return ""

	var newest_path := ""
	var newest_time := -1
	for file_path in get_all_files_in_folder(folder_path, false):
		var modified := FileAccess.get_modified_time(file_path)
		if modified > newest_time:
			newest_time = modified
			newest_path = file_path
	return newest_path


# ---------------------------------------------------------------------------
# Filename sanitization
# ---------------------------------------------------------------------------

# Convert a string into a valid filename using underscores as separators.
# aa bb cc dd -> aa_bb_cc
static func sanitize_filename(name: String) -> String:
	var regex := RegEx.new()

	# Replace all non-alphanumeric characters with '_'
	regex.compile("[^a-zA-Z0-9_-]")

	var result := regex.sub(name, "_", true)

	regex.compile("_+")
	result = regex.sub(result, "_", true)

	result = result.strip_edges()
	result = result.trim_prefix("_")
	result = result.trim_suffix("_")

	if StringUtils.is_blank(result):
		result = "unnamed"

	return result
