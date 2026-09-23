## Unit tests for [PopupWindow]. Loaded with the other scripts in this folder by [code]test/feedback/FeedbackTest.tscn[/code] ([UnitTest]).

## [method PopupWindow.show_window] opens a centered, read-only window sized as a percent of the screen.
func PopupWindow_show_window_test() -> void:
	close_open_windows()
	PopupWindow.show_window("feedback popup", "feedback popup body", 50, 60)
	var windows := open_windows()
	assert(windows.size() == 1)
	var window := windows[0]
	assert(window.visible)
	assert(window.title == "feedback popup")
	assert(window.text_edit.editable == false)
	assert(window.text_edit.text == "feedback popup body")
	if has_display():
		var viewport := gdf.gdf_node.get_tree().root.get_visible_rect().size
		assert(window.size.x == int(viewport.x * 0.5))
		assert(window.size.y == int(viewport.y * 0.6))
	# Hold the window open so a run with a display shows the popup.
	await ThreadUtils.async_sleep(1500)
	await close_window(window)
	pass


## Width and height percents are clamped to 1–100.
func PopupWindow_clamp_percent_test() -> void:
	close_open_windows()
	PopupWindow.show_window("feedback popup", "body", 0, 200)
	var windows := open_windows()
	assert(windows.size() == 1)
	if has_display():
		var viewport := gdf.gdf_node.get_tree().root.get_visible_rect().size
		assert(windows[0].size.x == int(viewport.x * 0.01))
		assert(windows[0].size.y == int(viewport.y))
	# Hold the window open so a run with a display shows the clamped popup.
	await ThreadUtils.async_sleep(1500)
	await close_window(windows[0])
	pass


## [method PopupWindow.set_body] replaces the text and scrolls the read-only view to the last line.
func PopupWindow_set_body_test() -> void:
	var window := PopupWindow.new()
	gdf.gdf_node.add_child(window)
	window.size = Vector2i(400, 300)
	window.popup_centered()
	var body := ""
	for i in 200:
		body += "line-%d\n" % i
	window.set_body(body)
	assert(window.text_edit.text == body)
	# Scrolled to the end: the last line sits at the bottom of the view.
	var scroll_bar := window.text_edit.get_v_scroll_bar()
	assert(scroll_bar.max_value > 0.0)
	assert(is_equal_approx(window.text_edit.scroll_vertical, scroll_bar.max_value - scroll_bar.page))
	window.set_body("short body")
	assert(window.text_edit.text == "short body")
	assert(window.text_edit.scroll_vertical == 0.0)
	window.free()
	pass


## Esc dismisses the popup through [method PopupWindow.on_window_input].
func PopupWindow_cancel_input_test() -> void:
	close_open_windows()
	PopupWindow.show_window("feedback popup", "body", 40, 40)
	var windows := open_windows()
	assert(windows.size() == 1)
	var window := windows[0]
	# Hold the window open so a run with a display shows the popup before Esc.
	await ThreadUtils.async_sleep(1500)
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	if is_instance_valid(window):
		window.on_window_input(event)
	await gdf.gdf_node.get_tree().process_frame
	assert(!is_instance_valid(window))
	pass


## A fresh popup is a transient child window that stays hidden until [method PopupWindow.show_window] pops it.
func PopupWindow_transient_test() -> void:
	var window := PopupWindow.new()
	assert(window.transient)
	assert(!window.visible)
	assert(window.text_edit.editable == false)
	window.free()
	pass


## The popup lives under `gdf_node`, so it follows the app window and closes with it.
func PopupWindow_parent_test() -> void:
	close_open_windows()
	PopupWindow.show_window("feedback popup", "body", 40, 40)
	var windows := open_windows()
	assert(windows.size() == 1)
	assert(windows[0].get_parent() == gdf.gdf_node)
	# Hold the window open so a run with a display shows the popup.
	await ThreadUtils.async_sleep(1500)
	await close_window(windows[0])
	pass


## The headless dummy display clamps embedded windows to 1×1, so percent sizing is only measurable with a real one.
func has_display() -> bool:
	return DisplayServer.get_name() != "headless"


func open_windows() -> Array[PopupWindow]:
	var windows: Array[PopupWindow] = []
	for child in gdf.gdf_node.get_children():
		if child is PopupWindow:
			windows.push_back(child)
	return windows


func close_open_windows() -> void:
	for window in open_windows():
		window.on_close_requested()
	pass


func close_window(window: PopupWindow) -> void:
	if is_instance_valid(window):
		window.on_close_requested()
	await gdf.gdf_node.get_tree().process_frame
	pass
