class_name PipelineOutputPath
extends RefCounted

## Resolve skill output paths following .ai/ nesting conventions.


static func output_dir_for_input(node_def: GraphNodeDef, primary_input_path: String) -> String:
	if primary_input_path.is_empty():
		return ""

	var normalized := primary_input_path.replace("\\", "/")
	var subdir := node_def.catalog_id()
	if DirAccess.dir_exists_absolute(normalized):
		return normalized.path_join(subdir)
	return normalized.get_base_dir().path_join(subdir)


static func resolve_newest_output(node_def: GraphNodeDef, primary_input_path: String) -> String:
	if primary_input_path.is_empty():
		return ""

	var output_dir := output_dir_for_input(node_def, primary_input_path)
	if output_dir.is_empty():
		return ""

	if node_def.primary_output_is_folder():
		if DirAccess.dir_exists_absolute(output_dir):
			return output_dir
		return ""

	return FileUtils.get_newest_file_in_folder(output_dir)
