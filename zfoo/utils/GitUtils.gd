class_name GitUtils
extends Object


# ----------------------------------------------------------------------------------------------------------------------
static var windows_git_bash_path := ""

static func find_windows_git_bash() -> String:
	if StringUtils.is_not_blank(windows_git_bash_path):
		return windows_git_bash_path

	var where_result := OSUtils.execute(PackedStringArray(["where.exe", "git"]), false)
	if where_result.exit_code == 0:
		var output := FileUtils.normalize_line_endings_to_lf(where_result.output.build_string())
		for line in output.split("\n", false):
			var git_path := line.strip_edges().replace("\\", "/")
			var git_directory := git_path.get_base_dir()
			var candidates: PackedStringArray = [
				git_directory.path_join("bash.exe"),
				git_directory.get_base_dir().path_join("bin/bash.exe"),
				]
			for candidate in candidates:
				if FileAccess.file_exists(candidate):
					windows_git_bash_path = candidate
					return windows_git_bash_path

	const other_paths: PackedStringArray = [
		"C:/Program Files/Git/bin/bash.exe",
		"C:/Program Files (x86)/Git/bin/bash.exe",
		]
	for path in other_paths:
		if FileAccess.file_exists(path):
			windows_git_bash_path = path
			return windows_git_bash_path
	windows_git_bash_path = "bash.exe"
	return windows_git_bash_path
