## FileUtils — file read, write, and directory helpers.


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


static func relative_paths(search_root: String, paths: Array[String]) -> Array[String]:
	var relative: Array[String] = []
	var root := search_root.replace("\\", "/").rstrip("/")
	for path in paths:
		var normalized_path := path.replace("\\", "/")
		relative.append(normalized_path.substr(root.length() + 1))
	return relative


static func create_fixture_tree() -> String:
	var root := ProjectSettings.globalize_path("user://fileutils_dirs_" + str(TimeUtils.now()) + "_" + str(randi()))
	DirAccess.make_dir_recursive_absolute(root.path_join("src/nested"))
	DirAccess.make_dir_recursive_absolute(root.path_join(".git/objects"))
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
