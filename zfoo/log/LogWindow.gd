## Tails `{user_data}/logs/godot.log` via PopupWindow.
class_name LogWindow
extends Object


## Show the last `line_count` lines. Width/height are percent of the screen (1–100).
## Example: `LogWindow.show_log(128, 70, 80)`
static func show_log(line_count: int, width_percent: int, height_percent: int) -> void:
	PopupWindow.show_text("System Log", LoggerHelper.tail_log(maxi(line_count, 1)), width_percent, height_percent)
	pass
