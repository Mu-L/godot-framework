class_name BatchFolder
extends RefCounted

## List top-level files in a folder that match a simple glob pattern.


static func list_files(folder_path: String, glob_pattern: String) -> Array[String]:
	var result: Array[String] = []
	var normalized := folder_path.replace("\\", "/").strip_edges()
	if normalized.is_empty() or not DirAccess.dir_exists_absolute(normalized):
		return result

	var pattern := glob_pattern.strip_edges()
	if pattern.is_empty():
		pattern = "*.*"

	var dir := DirAccess.open(normalized)
	if dir == null:
		return result

	for file_name in dir.get_files():
		if match_glob(file_name, pattern):
			result.append(normalized.path_join(file_name))

	result.sort()
	return result


static func match_glob(file_name: String, pattern: String) -> bool:
	if pattern == "*" or pattern == "*.*":
		return true
	return glob_match_impl(pattern, file_name, 0, 0)


static func glob_match_impl(pattern: String, name: String, pattern_index: int, name_index: int) -> bool:
	if pattern_index == pattern.length():
		return name_index == name.length()

	var pattern_char := pattern.substr(pattern_index, 1)
	if pattern_char == "*":
		if glob_match_impl(pattern, name, pattern_index + 1, name_index):
			return true
		if name_index < name.length():
			return glob_match_impl(pattern, name, pattern_index, name_index + 1)
		return false

	if name_index >= name.length():
		return false

	if pattern_char == "?" or pattern_char == name.substr(name_index, 1):
		return glob_match_impl(pattern, name, pattern_index + 1, name_index + 1)

	return false
