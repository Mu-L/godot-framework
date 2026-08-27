class_name SourceDef
extends GraphNodeDef

var id: String = ""


func catalog_id() -> String:
	return id


func is_source() -> bool:
	return true
