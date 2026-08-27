class_name PipelineJob
extends RefCounted

var node_id: String = ""
var label: String = ""
var skill_id: String = ""
var argv: PackedStringArray = PackedStringArray()
var predicted_output: String = ""
var output_port_id: String = GraphNodesConfig.PORT_OUTPUT
