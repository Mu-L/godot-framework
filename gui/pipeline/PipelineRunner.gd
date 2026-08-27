class_name PipelineRunner
extends Object

var command_builder := SkillCommandBuilder.new()
var stop_requested: bool = false


func request_stop() -> void:
	stop_requested = true
	ProcessRunner.stop_current()
	pass


func run(document: WorkflowDocument) -> void:
	stop_requested = false
	var order: Array[WorkflowNodeData] = topological_sort(document)
	if order.is_empty():
		WorkflowEvents.events.pipeline_finished.emit(false, "Workflow is empty or contains a cycle")
		return

	var batch_index := find_batch_index(order)
	var outputs_by_node: Dictionary[String, String] = {}

	var pre_count := order.size() if batch_index < 0 else batch_index
	var pre_nodes: Array[WorkflowNodeData] = order.slice(0, pre_count)
	var pre_jobs: Variant = plan_nodes(pre_nodes, document, outputs_by_node)
	if pre_jobs == null:
		return
	if stop_requested:
		WorkflowEvents.events.pipeline_stopped.emit()
		return

	if not pre_jobs.is_empty():
		if not await run_jobs(pre_jobs, outputs_by_node):
			return

	if batch_index < 0:
		if stop_requested:
			WorkflowEvents.events.pipeline_stopped.emit()
			return
		WorkflowEvents.events.pipeline_finished.emit(true, "Pipeline completed")
		return

	var batch_node_data: WorkflowNodeData = order[batch_index]
	var batch_node: GraphNodeDef = GraphNodesConfig.get_def(batch_node_data.skill_id)
	if batch_node == null or not batch_node.is_batch():
		WorkflowEvents.events.pipeline_finished.emit(false, "Unknown batch node")
		return

	var batch_resolved: Dictionary[String, String] = resolve_inputs(
		batch_node_data,
		batch_node,
		document,
		outputs_by_node,
	)
	var folder_path: String = batch_resolved.get(GraphNodesConfig.CONTROL_PORT_FOLDER, "")
	if folder_path.is_empty():
		WorkflowEvents.events.pipeline_finished.emit(false, "Batch node requires a connected folder input")
		return

	var glob_pattern: String = batch_node_data.manual_inputs.get(GraphNodesConfig.CONTROL_FIELD_GLOB, "*.*")
	var files: Array[String] = BatchFolder.list_files(folder_path, glob_pattern)
	if files.is_empty():
		WorkflowEvents.events.pipeline_finished.emit(false, StringUtils.format("No matching files in batch folder ({})", glob_pattern))
		return

	var post_nodes: Array[WorkflowNodeData] = order.slice(batch_index + 1)
	var total := files.size()
	for i in range(total):
		if stop_requested:
			WorkflowEvents.events.pipeline_stopped.emit()
			return
		var file_path: String = files[i]
		store_node_output(outputs_by_node, batch_node_data.id, batch_node, file_path)

		var iter_jobs: Variant = plan_nodes(post_nodes, document, outputs_by_node)
		if iter_jobs == null:
			return
		if iter_jobs.is_empty():
			continue

		var batch_context: String = StringUtils.format("{} ({}/{})", file_path.get_file(), i + 1, total)
		if not await run_jobs(iter_jobs, outputs_by_node, batch_context):
			return

	if stop_requested:
		WorkflowEvents.events.pipeline_stopped.emit()
		return
	WorkflowEvents.events.pipeline_finished.emit(true, StringUtils.format("Batch completed ({} files)", total))


func plan_nodes(
	nodes: Array[WorkflowNodeData],
	document: WorkflowDocument,
	outputs_by_node: Dictionary[String, String],
) -> Variant:
	var jobs: Array[PipelineJob] = []

	for node_data in nodes:
		var node_def: GraphNodeDef = GraphNodesConfig.get_def(node_data.skill_id)
		if node_def == null:
			WorkflowEvents.events.pipeline_finished.emit(false, StringUtils.format("Unknown node: {}", node_data.skill_id))
			return null

		if node_def.is_source():
			var source_resolved: Dictionary[String, String] = resolve_inputs(
				node_data,
				node_def,
				document,
				outputs_by_node,
			)
			var out_key: String = node_def.outputs[0].id if node_def.outputs.size() > 0 else GraphNodesConfig.PORT_OUTPUT
			var source_out: String = source_resolved.get(out_key, "")
			if source_out.is_empty():
				WorkflowEvents.events.pipeline_finished.emit(false, StringUtils.format("Source node {} has no path set", node_data.id))
				return null
			store_node_output(outputs_by_node, node_data.id, node_def, source_out)
			continue

		if node_def.is_batch():
			continue

		if node_def is not SkillDef:
			WorkflowEvents.events.pipeline_finished.emit(false, StringUtils.format("Node {} is not an executable skill", node_data.id))
			return null

		var skill := node_def as SkillDef
		var resolved: Dictionary[String, String] = resolve_inputs(
			node_data,
			node_def,
			document,
			outputs_by_node,
		)
		if resolved.is_empty():
			WorkflowEvents.events.pipeline_finished.emit(false, StringUtils.format("Node {} is missing input", node_data.id))
			return null

		var argv: PackedStringArray = command_builder.build_argv(skill, resolved)
		if argv.is_empty():
			WorkflowEvents.events.pipeline_finished.emit(false, StringUtils.format("Failed to build command: {}", node_def.display_label()))
			return null

		var primary_input: String = first_input_path(node_def, resolved)
		var predicted: String = PipelineOutputPath.predict(node_def, primary_input, resolved)
		var out_port_id := primary_output_port_id(node_def)

		var job := PipelineJob.new()
		job.node_id = node_data.id
		job.skill_id = node_data.skill_id
		job.label = node_def.display_label()
		job.argv = argv
		job.predicted_output = predicted
		job.output_port_id = out_port_id
		store_node_output(outputs_by_node, node_data.id, node_def, predicted, out_port_id)
		jobs.append(job)

	return jobs


func find_batch_index(order: Array[WorkflowNodeData]) -> int:
	for i in range(order.size()):
		var node_def: GraphNodeDef = GraphNodesConfig.get_def(order[i].skill_id)
		if node_def != null and node_def.is_batch():
			return i
	return -1


func resolve_inputs(
	node_data: WorkflowNodeData,
	node_def: GraphNodeDef,
	document: WorkflowDocument,
	outputs_by_node: Dictionary[String, String],
) -> Dictionary[String, String]:
	var resolved: Dictionary[String, String] = {}

	for port in node_def.inputs:
		var port_index: int = node_def.input_port_index_for_id(port.id)
		var connected: WorkflowConnection = find_connection_to_port(document, node_data.id, port_index)
		if connected != null:
			var upstream_path: String = read_upstream_output(connected, document, outputs_by_node)
			if upstream_path.is_empty():
				return {}
			resolved[port.id] = upstream_path
			continue

		if node_def.is_batch():
			return {}

		var manual: String = node_data.manual_inputs.get(port.id, "")
		if manual.is_empty():
			return {}
		resolved[port.id] = manual

	if node_def.is_source() and node_def.outputs.size() > 0:
		var out_id: String = node_def.outputs[0].id
		var manual_out: String = node_data.manual_inputs.get(out_id, "")
		if not manual_out.is_empty():
			resolved[out_id] = manual_out

	return resolved


func read_upstream_output(
	conn: WorkflowConnection,
	document: WorkflowDocument,
	outputs_by_node: Dictionary[String, String],
) -> String:
	var from_data := find_node_data(document, conn.from_node)
	if from_data == null:
		return outputs_by_node.get(conn.from_node, "")

	var from_def: GraphNodeDef = GraphNodesConfig.get_def(from_data.skill_id)
	if from_def == null:
		return outputs_by_node.get(conn.from_node, "")

	var out_port := from_def.output_port_at_port_index(conn.from_port)
	if out_port == null:
		return outputs_by_node.get(conn.from_node, "")

	return get_node_output(outputs_by_node, conn.from_node, out_port.id)


func find_node_data(document: WorkflowDocument, node_id: String) -> WorkflowNodeData:
	for node in document.nodes:
		if node.id == node_id:
			return node
	return null


func find_connection_to_port(document: WorkflowDocument, node_id: String, port_index: int) -> WorkflowConnection:
	for conn in document.connections:
		if conn.to_node == node_id and conn.to_port == port_index:
			return conn
	return null


func first_input_path(node_def: GraphNodeDef, resolved: Dictionary[String, String]) -> String:
	for port in node_def.inputs:
		if resolved.has(port.id):
			return resolved[port.id]
	if resolved.size() > 0:
		return resolved.values()[0]
	return ""


func primary_output_port_id(node_def: GraphNodeDef) -> String:
	if node_def.outputs.is_empty():
		return GraphNodesConfig.PORT_OUTPUT
	return node_def.outputs[0].id


func store_node_output(
	outputs_by_node: Dictionary[String, String],
	node_id: String,
	node_def: GraphNodeDef,
	path: String,
	port_id: String = "",
) -> void:
	outputs_by_node[node_id] = path
	if port_id.is_empty():
		port_id = primary_output_port_id(node_def)
	outputs_by_node[output_key(node_id, port_id)] = path


func get_node_output(outputs_by_node: Dictionary[String, String], node_id: String, port_id: String) -> String:
	var keyed: String = outputs_by_node.get(output_key(node_id, port_id), "")
	if not keyed.is_empty():
		return keyed
	return outputs_by_node.get(node_id, "")


func output_key(node_id: String, port_id: String) -> String:
	return StringUtils.format("{}:{}", node_id, port_id)


func topological_sort(document: WorkflowDocument) -> Array[WorkflowNodeData]:
	var node_map: Dictionary[String, WorkflowNodeData] = {}
	for node in document.nodes:
		node_map[node.id] = node

	var indegree: Dictionary[String, int] = {}
	var adj: Dictionary = {}
	for node in document.nodes:
		indegree[node.id] = 0
		adj[node.id] = [] as Array[String]

	for conn in document.connections:
		if not node_map.has(conn.from_node) or not node_map.has(conn.to_node):
			continue
		adj[conn.from_node].append(conn.to_node)
		indegree[conn.to_node] = indegree.get(conn.to_node, 0) + 1

	var queue: Array[String] = []
	for node_id in indegree.keys():
		if indegree[node_id] == 0:
			queue.append(node_id)

	var order: Array[WorkflowNodeData] = []
	while not queue.is_empty():
		var current: String = queue.pop_front()
		order.append(node_map[current])
		for next_id: String in adj[current]:
			indegree[next_id] = indegree[next_id] - 1
			if indegree[next_id] == 0:
				queue.append(next_id)

	if order.size() != document.nodes.size():
		return []
	return order


func run_jobs(
	jobs: Array[PipelineJob],
	outputs_by_node: Dictionary[String, String],
	batch_context: String = "",
) -> bool:
	for job in jobs:
		if stop_requested:
			WorkflowEvents.events.pipeline_stopped.emit()
			return false
		var step_label := job.label
		if not batch_context.is_empty():
			step_label = StringUtils.format("{} {}", job.label, batch_context)
		WorkflowEvents.events.step_started.emit(job.node_id, step_label)
		Log.info("[Command] {}", SkillCommandBuilder.format_command_line(job.argv))

		var on_output_line := func(line: String) -> void:
			WorkflowEvents.events.process_output.emit(line)
		var exec_result := await ProcessRunner.async_execute(job.argv, on_output_line)
		if stop_requested:
			WorkflowEvents.events.pipeline_stopped.emit()
			return false
		var exit_code: int = exec_result.exit_code
		var output: Array[String] = exec_result.output
		if exit_code != 0:
			log_job_failure(job, exit_code, output)
			WorkflowEvents.events.step_finished.emit(job.node_id, exit_code, "")
			WorkflowEvents.events.pipeline_finished.emit(false, StringUtils.format("Step failed: {} (exit {})", job.label, exit_code))
			return false

		var node_def: GraphNodeDef = GraphNodesConfig.get_def(job.skill_id)
		if node_def != null:
			store_node_output(outputs_by_node, job.node_id, node_def, job.predicted_output, job.output_port_id)
		else:
			outputs_by_node[job.node_id] = job.predicted_output
		WorkflowEvents.events.step_finished.emit(job.node_id, exit_code, job.predicted_output)

	return true


func log_job_failure(job: PipelineJob, exit_code: int, output: Array[String]) -> void:
	Log.error("[Failed] {} (exit {})", job.label, exit_code)
	Log.error("[Command] {}", SkillCommandBuilder.format_command_line(job.argv))
	if exit_code < 0:
		Log.error("[Output] Failed to start process; check that the runtime exists: {}", job.argv[0])
		return
	if output.is_empty():
		Log.error("[Output] (no process output)")
	pass