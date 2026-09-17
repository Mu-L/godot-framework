## GlobTool — workspace ignore rules loaded in _static_init.


func glob_static_init_ignore_test() -> void:
	var root := ProjectSettings.globalize_path("user://glob_tool_ignore_" + str(randi()))
	DirAccess.make_dir_recursive_absolute(root)
	FileUtils.write_string_to_file(root.path_join(".gitignore"), "# comment\n.dependency/\n.cursor/skills/humanizer\n!.agent/\n*.tmp\n.idea\n")
	var prior := Setting.get_string(AgentWorkspace.SETTING_KEY)
	Setting.set_string(AgentWorkspace.SETTING_KEY, root)
	GlobTool._static_init()
	assert(FileUtils.glob_match(".dependency/", ".dependency/cache"))
	assert(FileUtils.glob_match(".idea", "tools/.idea/ws"))
	assert(FileUtils.glob_match(".cursor/skills/humanizer", ".cursor/skills/humanizer/skip.gd"))
	assert(GlobTool.workspace_path_skipped(".dependency/vendor"))
	assert(GlobTool.workspace_path_skipped(".cursor/skills/humanizer/extra"))
	assert(not GlobTool.workspace_path_skipped("src/main.gd"))
	assert(not FileUtils.glob_match_any(GlobTool.workspace_skip_glob_rules, "scratch.tmp"))
	Setting.set_string(AgentWorkspace.SETTING_KEY, prior)
	GlobTool._static_init()
	remove_fixture_dir(root)
	pass


static func remove_fixture_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file_name in dir.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for dir_name in dir.get_directories():
		remove_fixture_dir(path.path_join(dir_name))
	DirAccess.remove_absolute(path)
	pass
