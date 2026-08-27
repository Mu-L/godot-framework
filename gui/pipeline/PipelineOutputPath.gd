class_name PipelineOutputPath
extends RefCounted

## Predict default skill output paths following .ai/ nesting conventions.


static func predict(
	node_def: GraphNodeDef,
	primary_input_path: String,
	resolved: Dictionary[String, String] = {},
) -> String:
	if node_def.is_source():
		return primary_input_path

	if primary_input_path.is_empty() and resolved.is_empty():
		return ""

	if primary_input_path.is_empty():
		return ""

	if node_def.primary_output_is_folder():
		return predict_output_dir(node_def, primary_input_path)

	var source := primary_input_path
	if DirAccess.dir_exists_absolute(source):
		return predict_output_dir(node_def, source)

	return predict_output_file(node_def, source)


static func predict_output_file(node_def: GraphNodeDef, source_file: String) -> String:
	var source_path := source_file.replace("\\", "/")
	var dir := source_path.get_base_dir()
	var stem := source_path.get_file().get_basename()
	var ext := source_path.get_extension()
	if not ext.is_empty():
		ext = "." + ext
	var subdir := skill_output_dir(node_def)
	return dir.path_join(subdir).path_join(stem + ext)


static func predict_output_dir(node_def: GraphNodeDef, source_path: String) -> String:
	var normalized := source_path.replace("\\", "/")
	var subdir := skill_output_dir(node_def)

	if DirAccess.dir_exists_absolute(normalized):
		return normalized.path_join(subdir)

	return normalized.get_base_dir().path_join(subdir)


static func skill_output_dir(node_def: GraphNodeDef) -> String:
	return node_def.catalog_id()
