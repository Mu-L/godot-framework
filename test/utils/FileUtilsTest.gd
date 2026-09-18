## FileUtils — read/write, glob, and glob_match helpers.


func FileUtils_read_write_test() -> void:
	var path: String = "./zfoo_test_temp.txt"
	var content: String = "hello godot!"
	FileUtils.write_string_to_file(path, content)
	var read_content := FileUtils.read_file_to_string(path)
	assert(content == read_content)
	FileUtils.delete_file(path)
	pass


func read_file_to_string_rejects_nul_test() -> void:
	var path := ProjectSettings.globalize_path("user://fileutils_nul_test.bin")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(PackedByteArray([0x61, 0x00, 0x62]))
	file = null
	assert(FileUtils.read_file_to_string(path) == StringUtils.EMPTY)
	assert(FileUtils.read_file_to_lines(path).is_empty())
	FileUtils.delete_file(path)
	pass


func glob_skip_rules_test() -> void:
	var root := create_fixture_tree()
	DirAccess.make_dir_recursive_absolute(root.path_join(".cursor/skills/humanizer"))
	FileUtils.write_string_to_file(root.path_join(".cursor/skills/humanizer/skip.gd"), "extends Node\n")
	var skip: Array[String] = [".git", ".cursor/skills/humanizer"]
	var rel := relative_paths(root, FileUtils.glob(root, "**/*.gd", 1_048_576, skip))
	assert(not rel.has(".cursor/skills/humanizer/skip.gd"))
	remove_fixture_tree(root)
	pass


func glob_pattern_test() -> void:
	var root := create_fixture_tree()
	var gd_files := FileUtils.glob(root, "**/*.gd", 1_048_576, [".git"])
	var rel := relative_paths(root, gd_files)
	assert(rel.size() == 3)
	assert(rel.has("root.gd"))
	assert(rel.has("src/a.gd"))
	assert(rel.has("src/nested/c.gd"))
	assert(not rel.has("src/b.txt"))
	remove_fixture_tree(root)
	pass


func glob_skips_dirs_test() -> void:
	var root := create_fixture_tree()
	var all := FileUtils.glob(root, "**/*", 1_048_576, [".git"])
	var rel := relative_paths(root, all)
	assert(not rel.has(".git/objects/sha"))
	remove_fixture_tree(root)
	pass


func glob_max_file_bytes_test() -> void:
	var root := create_fixture_tree()
	var huge_path := root.path_join("src/huge.bin")
	FileUtils.write_string_to_file(huge_path, "x".repeat(2_000))
	var capped := FileUtils.glob(root, "**/*", 1_000, [".git"])
	var rel := relative_paths(root, capped)
	assert(not rel.has("src/huge.bin"))
	assert(rel.has("src/a.gd"))
	remove_fixture_tree(root)
	pass


func get_all_directories_in_folder_test() -> void:
	var root := create_fixture_tree()
	var top := relative_paths(root, FileUtils.get_all_directories_in_folder(root, false))
	top.sort()
	assert(top.has("src"))
	assert(top.has(".git"))
	assert(not top.has("src/nested"))
	var all := relative_paths(root, FileUtils.get_all_directories_in_folder(root, true))
	all.sort()
	assert(all.has("src/nested"))
	assert(all.has(".git/objects"))
	remove_fixture_tree(root)
	pass


func glob_single_file_test() -> void:
	var root := create_fixture_tree()
	var one := root.path_join("src/a.gd")
	var matched := FileUtils.glob(one, "*.gd", 1_048_576)
	assert(matched.size() == 1)
	assert(matched[0] == one)
	var rejected := FileUtils.glob(one, "*.txt", 1_048_576)
	assert(rejected.is_empty())
	remove_fixture_tree(root)
	pass


func glob_treats_hash_and_bang_as_literal_pattern_test() -> void:
	var root := create_fixture_tree()
	DirAccess.make_dir_recursive_absolute(root.path_join("#cache"))
	DirAccess.make_dir_recursive_absolute(root.path_join("!data"))
	FileUtils.write_string_to_file(root.path_join("#cache/item.txt"), "text\n")
	FileUtils.write_string_to_file(root.path_join("!data/item.json"), "{}\n")
	var hash_matches := relative_paths(root, FileUtils.glob(root, "#cache/*.txt"))
	var bang_matches := relative_paths(root, FileUtils.glob(root, "!data/*.json"))
	assert(hash_matches == ["#cache/item.txt"])
	assert(bang_matches == ["!data/item.json"])
	remove_fixture_tree(root)
	pass


func glob_match_any_test() -> void:
	var rules: Array[String] = ["# AI", ".dependency/", "*.tmp", ".cursor/skills/humanizer"]
	assert(FileUtils.glob_match_any(rules, "vendor/out.tmp"))
	assert(FileUtils.glob_match_any(rules, ".dependency/cache/x"))
	assert(FileUtils.glob_match_any(rules, ".cursor/skills/humanizer/a.gd"))
	assert(not FileUtils.glob_match_any(rules, "src/main.gd"))
	assert(not FileUtils.glob_match_any([], "any/path"))
	assert(not FileUtils.glob_match_any(["# only comment"], "foo"))
	pass


func glob_match_comments_and_empty_test() -> void:
	assert(not FileUtils.glob_match("", "any/path"))
	assert(not FileUtils.glob_match("   ", "any/path"))
	assert(not FileUtils.glob_match("# AI", ".dependency/cache"))
	assert(not FileUtils.glob_match("  # comment", "foo"))
	assert(not FileUtils.glob_match("# .dependency/", ".dependency/x"))
	assert(not FileUtils.glob_match("", ""))
	pass


func glob_match_empty_path_test() -> void:
	assert(not FileUtils.glob_match(".dependency/", ""))
	assert(not FileUtils.glob_match("*.tmp", ""))
	assert(not FileUtils.glob_match("foo", "   "))
	pass


func glob_match_whitespace_and_negation_test() -> void:
	assert(FileUtils.glob_match("  .dependency/  ", ".dependency/x"))
	assert(FileUtils.glob_match("!.agent/", ".agent/session.json"))
	assert(FileUtils.glob_match("  ! .idea  ", "editor/.idea/ws"))
	assert(not FileUtils.glob_match("!", "foo"))
	assert(not FileUtils.glob_match("!   ", "foo"))
	pass


func glob_match_trailing_slash_directory_test() -> void:
	assert(FileUtils.glob_match(".dependency/", ".dependency"))
	assert(FileUtils.glob_match(".dependency/", ".dependency/cache/bin"))
	assert(FileUtils.glob_match(".godot/", ".godot/imported"))
	assert(FileUtils.glob_match(".import/", ".import/foo"))
	assert(FileUtils.glob_match("data_*/", "data_foo"))
	assert(FileUtils.glob_match("data_*/", "data_foo/bar/baz"))
	# Directory-name rules match that segment at any depth (same as GlobTool skip dir names).
	assert(FileUtils.glob_match(".dependency/", "other/.dependency/x"))
	pass


func glob_match_literal_path_prefix_test() -> void:
	assert(FileUtils.glob_match(".cursor/skills/humanizer", ".cursor/skills/humanizer"))
	assert(FileUtils.glob_match(".cursor/skills/humanizer", ".cursor/skills/humanizer/skip.gd"))
	assert(FileUtils.glob_match(".cursor/skills/humanizer-zh", ".cursor/skills/humanizer-zh/readme.md"))
	assert(not FileUtils.glob_match(".cursor/skills/humanizer", ".cursor/skills/humanizer_extra/x"))
	assert(not FileUtils.glob_match(".cursor/skills/humanizer", ".cursor/skills/other/x"))
	assert(not FileUtils.glob_match(".cursor/skills/humanizer", "prefix/.cursor/skills/humanizer/x"))
	pass


func glob_match_literal_name_any_level_test() -> void:
	assert(FileUtils.glob_match(".idea", ".idea"))
	assert(FileUtils.glob_match(".idea", "editor/.idea"))
	assert(FileUtils.glob_match(".idea", "editor/.idea/workspace.xml"))
	assert(FileUtils.glob_match(".vscode", "tools/.vscode/settings.json"))
	assert(FileUtils.glob_match("export.cfg", "export.cfg"))
	assert(FileUtils.glob_match("export.cfg", "sub/export.cfg"))
	assert(FileUtils.glob_match(".nomedia", "assets/.nomedia"))
	assert(FileUtils.glob_match(".agent", ".agent/foo"))
	assert(not FileUtils.glob_match(".idea", "notidea"))
	assert(not FileUtils.glob_match("export.cfg", "export.cfg.bak"))
	pass


func glob_match_wildcard_basename_test() -> void:
	assert(FileUtils.glob_match("*.tmp", "scratch.tmp"))
	assert(FileUtils.glob_match("*.tmp", "build/out.tmp"))
	assert(not FileUtils.glob_match("*.tmp", "build/out.txt"))
	assert(FileUtils.glob_match("*.translation", "ui/menu.translation"))
	assert(not FileUtils.glob_match("*.translation", "ui/menu.csv"))
	assert(FileUtils.glob_match("mono_crash.*.json", "logs/mono_crash.abc.json"))
	assert(not FileUtils.glob_match("mono_crash.*.json", "logs/crash.json"))
	assert(FileUtils.glob_match("*.suo", "proj/foo.suo"))
	assert(FileUtils.glob_match("*.njsproj", "app/bar.njsproj"))
	assert(FileUtils.glob_match("*.sln", "game.sln"))
	pass


func glob_match_wildcard_single_char_test() -> void:
	# Godot String.match: ? does not match '.'
	assert(FileUtils.glob_match("*.sw?", "lib.swf"))
	assert(not FileUtils.glob_match("*.sw?", "lib.sw"))
	pass


func glob_match_wildcard_path_segment_test() -> void:
	assert(FileUtils.glob_match("data_*", "data_foo"))
	assert(FileUtils.glob_match("data_*", "data_foo/bar"))
	assert(FileUtils.glob_match("data_*", "src/data_bar/baz"))
	assert(not FileUtils.glob_match("data_*", "nodata_foo"))
	pass


func glob_match_wildcard_with_slash_test() -> void:
	assert(FileUtils.glob_match("agent/*.gd", "agent/ReadTool.gd"))
	assert(not FileUtils.glob_match("agent/*.gd", "agent/tools/ReadTool.gd"))
	assert(FileUtils.glob_match("**/*.gd", "agent/tools/ReadTool.gd"))
	assert(FileUtils.glob_match("**/*.gd", "ReadTool.gd"))
	assert(not FileUtils.glob_match("**/*.gd", "agent/tools/ReadTool.txt"))
	assert(FileUtils.glob_match("foo/*/", "foo/bar/file.txt"))
	assert(not FileUtils.glob_match("foo/*/", "other/bar/file.txt"))
	pass


func glob_match_backslash_normalization_test() -> void:
	assert(FileUtils.glob_match(".dependency\\", ".dependency\\cache\\x"))
	assert(FileUtils.glob_match(".cursor/skills/humanizer", ".cursor\\skills\\humanizer\\a.gd"))
	pass


func glob_match_repo_gitignore_smoke_test() -> void:
	# Lines mirrored from project .gitignore — spot-check representative paths.
	var lines_and_paths: Array = [
		[".dependency/", ".dependency/vendor/x", true],
		[".agent/", ".agent/run/log", true],
		[".godot/", ".godot/editor", true],
		["*.tmp", "obj/debug.tmp", true],
		[".mono/", ".mono/metadata", true],
		["export_credentials.cfg", "export_credentials.cfg", true],
		[".dependency/", "src/.dependency/x", true],
		["*.tmp", "readme.tmp.md", false],
	]
	for row in lines_and_paths:
		var line: String = row[0]
		var path: String = row[1]
		var want: bool = row[2]
		assert(FileUtils.glob_match(line, path) == want)
	pass


static func relative_paths(search_root: String, files: Array[String]) -> Array[String]:
	var rel: Array[String] = []
	var root := search_root.replace("\\", "/").rstrip("/")
	for file_path in files:
		var normalized_path := file_path.replace("\\", "/")
		rel.append(normalized_path.substr(root.length() + 1))
	return rel


static func create_fixture_tree() -> String:
	var root := ProjectSettings.globalize_path("user://fileutils_glob_" + str(TimeUtils.now()) + "_" + str(randi()))
	DirAccess.make_dir_recursive_absolute(root.path_join("src/nested"))
	DirAccess.make_dir_recursive_absolute(root.path_join(".git/objects"))
	FileUtils.write_string_to_file(root.path_join("root.gd"), "extends Node\n")
	FileUtils.write_string_to_file(root.path_join("src/a.gd"), "extends Node\n")
	FileUtils.write_string_to_file(root.path_join("src/b.txt"), "text\n")
	FileUtils.write_string_to_file(root.path_join("src/nested/c.gd"), "extends Node\n")
	FileUtils.write_string_to_file(root.path_join(".git/objects/sha"), "git\n")
	return root


static func remove_fixture_tree(root: String) -> void:
	remove_dir_recursive(root)
	pass


static func remove_dir_recursive(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file_name in dir.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for dir_name in dir.get_directories():
		remove_dir_recursive(path.path_join(dir_name))
	DirAccess.remove_absolute(path)
	pass
