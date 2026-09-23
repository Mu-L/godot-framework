## Unit tests for [Alert]. Loaded with the other scripts in this folder by [code]test/feedback/FeedbackTest.tscn[/code] ([UnitTest]).

## [method Alert.create_alert_label] builds a centered label that carries the [Alert] script and the accent color.
func Alert_create_label_test() -> void:
	var alert := Alert.create_alert_label("feedback", Colors.success) as Alert
	assert(alert != null)
	assert(alert.text == "feedback")
	assert(alert.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER)
	assert(alert.vertical_alignment == VERTICAL_ALIGNMENT_CENTER)
	assert(alert.get_theme_font_size("font_size") == Alert.default_font_size)
	assert(alert.z_index == 1024)
	var style := alert.get_theme_stylebox("normal") as StyleBoxFlat
	assert(style.bg_color == Colors.success)
	assert(style.corner_radius_top_left == Alert.default_corner_radius)
	assert(style.content_margin_left == 16)
	alert.free()
	pass


## [method Alert._process] drifts the toast down by [member Alert.default_speed] pixels per second.
func Alert_drift_test() -> void:
	var alert := Alert.create_alert_label("feedback", Colors.info) as Alert
	alert.position = Vector2.ZERO
	alert._process(1.0)
	assert(is_equal_approx(alert.position.y, Alert.default_speed))
	alert._process(0.5)
	assert(is_equal_approx(alert.position.y, Alert.default_speed * 1.5))
	assert(is_equal_approx(alert.position.x, 0.0))
	alert.free()
	pass


## [method Alert.alert] mounts the toast on `gdf_layer`, centers it horizontally, then frees it on timeout.
func Alert_alert_test() -> void:
	var existing := alert_labels()
	Alert.alert("feedback alert test", Colors.success)
	await gdf.gdf_node.get_tree().process_frame
	# One extra frame: the toast is only sized after its first layout pass.
	await gdf.gdf_node.get_tree().process_frame
	var created := alert_labels()
	assert(created.size() == existing.size() + 1)
	var alert := created[created.size() - 1]
	assert(!existing.has(alert))
	assert(alert.text == "feedback alert test")
	var viewport_size := alert.get_viewport().get_visible_rect().size
	assert(is_equal_approx(alert.position.x, (viewport_size.x - alert.size.x) / 2.0))
	await ThreadUtils.async_sleep(Alert.default_wait_time + 200)
	await gdf.gdf_node.get_tree().process_frame
	assert(!is_instance_valid(alert))
	pass


func alert_labels() -> Array[Alert]:
	var labels: Array[Alert] = []
	for child in gdf.gdf_layer.get_children():
		if child is Alert:
			labels.push_back(child)
	return labels
