## Tails `{user_data}/logs/godot.log` in a centered window. Esc, the close button, or a click outside the window dismisses it.
class_name LogWindow
extends Window

const TEXT_MARGIN := 8

static var current: LogWindow

var text_edit: TextEdit


func _init() -> void:
	transient = true
	visible = false
	title = "Log"
	close_requested.connect(on_close_requested)
	window_input.connect(on_window_input)

	text_edit = TextEdit.new()
	text_edit.editable = false
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text_edit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text_edit.offset_left = TEXT_MARGIN
	text_edit.offset_top = TEXT_MARGIN
	text_edit.offset_right = -TEXT_MARGIN
	text_edit.offset_bottom = -TEXT_MARGIN
	text_edit.grow_horizontal = Control.GROW_DIRECTION_BOTH
	text_edit.grow_vertical = Control.GROW_DIRECTION_BOTH
	text_edit.add_theme_font_override("font", Fonts.regular())
	add_child(text_edit)
	pass


## Show the last `line_count` lines. `width_percent` / `height_percent` are 1–100 of the screen.
## Example: `LogWindow.show_log(128, 70, 80)`
static func show_log(line_count: int, width_percent: int, height_percent: int) -> void:
	if gdf.gdf_node == null:
		Log.error("LogWindow.show_log called before GodotFramework ready")
		return
	if current != null and is_instance_valid(current):
		current.close_window()

	var window := LogWindow.new()
	current = window
	gdf.gdf_node.add_child(window)
	window.apply_size(width_percent, height_percent)
	window.set_log_text(LoggerHelper.tail_log(maxi(line_count, 1)))
	window.popup_centered()
	pass


func apply_size(width_percent: int, height_percent: int) -> void:
	var viewport_size := gdf.gdf_node.get_tree().root.get_visible_rect().size
	var width_ratio := clampf(float(width_percent), 1.0, 100.0) / 100.0
	var height_ratio := clampf(float(height_percent), 1.0, 100.0) / 100.0
	size = Vector2i(
		maxi(int(viewport_size.x * width_ratio), 1),
		maxi(int(viewport_size.y * height_ratio), 1),
	)
	pass


func set_log_text(text: String) -> void:
	text_edit.text = text
	text_edit.scroll_vertical = text_edit.get_line_count()
	pass


func close_window() -> void:
	if current == self:
		current = null
	queue_free()
	pass


func on_close_requested() -> void:
	close_window()
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and visible:
		close_window()
	pass


func on_window_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			close_window()
			set_input_as_handled()
	pass
