class_name RepoRoot
extends RefCounted

## Resolves the repository root (folder containing project.godot and .ai/).

static var cached_root: String = ""


static func resolve() -> String:
	if not cached_root.is_empty() and DirAccess.dir_exists_absolute(cached_root):
		return cached_root

	var dir := ProjectSettings.globalize_path("res://")
	for _i in range(8):
		if FileAccess.file_exists(dir.path_join("project.godot")):
			cached_root = dir
			return cached_root
		var parent := dir.get_base_dir()
		if parent == dir:
			break
		dir = parent

	cached_root = ProjectSettings.globalize_path("res://")
	return cached_root
