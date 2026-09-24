class_name AgentChatInput
extends RefCounted

## Floating chat input, right-aligned (Margin.ma_12 from the right, Margin.ma_4 from the bottom):
## collapse/expand, styling, and send button.

const COLLAPSED_SIZE: float = 52.0
## Diameter of the round send button. Collapsed offsets are half of it, so the circle lands dead
## center of the wrap; the stylebox corner radius is half of it too, which is what makes it round.
const SEND_BUTTON_SIZE: float = 36.0
## Expanded panel height when empty or one line (wrap grows upward from bottom).
const EXPANDED_HEIGHT_MIN: float = 88.0
## Cap auto-grow so long paste does not cover most of the chat area.
const EXPANDED_HEIGHT_MAX_RATIO: float = 0.55

var input_bar: Control
var input_wrap: PanelContainer
var input_inner: Control
var input_field: TextEdit
var send_button: Button
var border_beam: AccentBorderBeamLayer

var expanded: bool = false
var force_expanded: bool = false
var layout_tween: Tween = null

var tween_start_h: float = 0.0
var tween_target_h: float = 0.0
var tween_start_left: float = 0.0
var tween_target_left: float = 0.0
var tween_bar_size: Vector2 = Vector2.ZERO
var tween_expand_target: bool = false
var drop_focus_guard: bool = false


# ---------------------------------------------------------------------------
# Setup & public API
# ---------------------------------------------------------------------------

func setup(
	p_input_bar: Control,
	p_input_wrap: PanelContainer,
	p_input_inner: Control,
	p_input_field: TextEdit,
	p_send_button: Button
) -> void:
	input_bar = p_input_bar
	input_wrap = p_input_wrap
	input_inner = p_input_inner
	input_field = p_input_field
	send_button = p_send_button

	input_wrap.set_anchor(SIDE_LEFT, 0.0)
	input_wrap.set_anchor(SIDE_TOP, 0.0)
	input_wrap.set_anchor(SIDE_RIGHT, 0.0)
	input_wrap.set_anchor(SIDE_BOTTOM, 0.0)

	# Engine updates TextEdit minimum height from wrapped lines; outer wrap reads it in get_wrap_height().
	input_field.scroll_fit_content_height = true

	send_button.pressed.connect(on_input_action_pressed)
	input_field.gui_input.connect(on_field_gui_input)
	input_field.minimum_size_changed.connect(on_field_minimum_size_changed)
	input_field.text_changed.connect(on_field_text_changed)
	input_field.focus_entered.connect(on_field_focus_entered)
	input_field.focus_exited.connect(on_field_focus_exited)
	input_wrap.gui_input.connect(on_wrap_gui_input)
	input_bar.resized.connect(layout_bar)
	input_bar.get_window().files_dropped.connect(on_files_dropped)
	input_bar.get_window().window_input.connect(on_global_input)
	gdf.events.theme_changed.connect(on_ui_theme_changed)
	gdf.events.theme_color_changed.connect(on_ui_theme_changed)
	AgentEvents.events.session_selected.connect(on_session_selected)
	AgentEvents.events.chat_input_prefill.connect(on_chat_input_prefill)
	setup_border_beam()
	AgentEvents.events.agent_start.connect(on_agent_start)
	AgentEvents.events.session_stop.connect(on_session_stop)
	apply_theme()
	pass


func on_ui_theme_changed() -> void:
	apply_theme()
	refresh_from_active_session()
	refresh_border_beam()
	pass


func setup_border_beam() -> void:
	input_bar.clip_contents = false
	border_beam = AccentBorderBeamLayer.new()
	border_beam.name = "BorderBeam"
	border_beam.z_index = -1
	input_bar.add_child(border_beam)
	input_bar.move_child(border_beam, 0)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		border_beam.set_anchor(side, 0.0)
	send_button.z_index = 2
	send_button.mouse_filter = Control.MOUSE_FILTER_STOP
	layout_border_beam()
	refresh_border_beam()
	pass


func layout_border_beam() -> void:
	if border_beam == null:
		return
	set_border_beam_to_wrap(
		input_wrap.offset_left,
		input_wrap.offset_top,
		input_wrap.offset_right,
		input_wrap.offset_bottom
	)
	pass


func set_border_beam_to_wrap(wrap_left: float, wrap_top: float, wrap_right: float, wrap_bottom: float) -> void:
	var pad: int = Margin.ma_1
	border_beam.offset_left = wrap_left - pad
	border_beam.offset_top = wrap_top - pad
	border_beam.offset_right = wrap_right + pad
	border_beam.offset_bottom = wrap_bottom + pad
	border_beam.sync_shader_uniforms()
	pass


func refresh_border_beam() -> void:
	if border_beam == null:
		return
	border_beam.set_shape(expanded)
	var strength: float = 0.45
	if input_field.has_focus():
		strength = 1.0
	elif expanded:
		strength = 0.72
	border_beam.set_highlight_strength(strength)
	pass


func on_session_selected(_session_id: int, _previous_session_id: int) -> void:
	refresh_from_active_session()
	pass


func on_agent_start(session_id: int) -> void:
	if not AgentSessionManager.is_active(session_id):
		return
	refresh_from_active_session()
	pass


func on_session_stop(session_id: int) -> void:
	if not AgentSessionManager.is_active(session_id):
		return
	refresh_from_active_session()
	pass


## A deleted / reverted bubble hands its body back here so it can be edited and resent.
func on_chat_input_prefill(text: String) -> void:
	if StringUtils.is_blank(text):
		return
	input_field.text = text
	force_expanded = false
	expand_if_collapsed()
	# Setting .text does not emit text_changed, so ask for the (possibly capped) height by hand.
	relayout_if_height_changed()
	focus_input_field.call_deferred()
	pass


func refresh_from_active_session() -> void:
	var session: AgentSession = AgentSessionStore.load_session(AgentSessionManager.active_session_id)
	var running: bool = AgentSessionManager.is_running(AgentSessionManager.active_session_id)
	var no_history: bool = session != null and not AgentSessionManager.has_chat_history(session.id)
	refresh_state(running, no_history)
	pass


func apply_theme() -> void:
	style_wrap()
	style_field()
	var running: bool = AgentSessionManager.is_running(AgentSessionManager.active_session_id)
	set_send_button_appearance(running)
	pass


func refresh_state(running: bool, no_history: bool = false) -> void:
	force_expanded = no_history and not running
	var enabling: bool = not input_field.editable and not running
	set_send_button_appearance(running)
	input_field.editable = not running
	if force_expanded:
		set_expanded(true, false)
		focus_input_field.call_deferred()
	elif input_field.text.strip_edges().length() > 0 or input_field.has_focus():
		set_expanded(true, false)
	elif can_collapse():
		set_expanded(false, true)
	else:
		layout_bar()
	if enabling and not force_expanded:
		restore_caret.call_deferred()
	pass


func get_trimmed_text() -> String:
	return input_field.text.strip_edges()


func clear_text() -> void:
	input_field.text = ""
	# Setting .text does not emit text_changed, so re-measure by hand. Deferred: a send collapses
	# right after this, and that tween should still start from the current (capped) height.
	relayout_if_height_changed.call_deferred()
	pass


func collapse_after_send() -> void:
	input_field.release_focus()
	force_expanded = false
	set_expanded(false, true)
	pass


func on_global_input(event: InputEvent) -> void:
	if not expanded or drop_focus_guard:
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		# Window input coordinates are not guaranteed to use the same canvas transform as
		# Control.global_rect (for example with viewport stretch/scaling). Query the mouse
		# through the control so both values are in canvas coordinates.
		if is_point_inside(input_wrap.get_global_mouse_position()):
			return
		input_field.release_focus()
		try_collapse()
	pass


# ---------------------------------------------------------------------------
# Event handlers
# ---------------------------------------------------------------------------

func on_input_action_pressed() -> void:
	var session: AgentSession = AgentSessionStore.load_session(AgentSessionManager.active_session_id)
	if session == null:
		return
	if AgentSessionManager.is_running(session.id):
		AgentSessionManager.request_stop(session.id)
		return
	var text: String = get_trimmed_text()
	if text.is_empty():
		expand_if_collapsed()
		focus_input_field.call_deferred()
		return
	if not ensure_git_installed(session.id):
		return
	clear_text()
	collapse_after_send()
	await AgentSessionManager.async_send(session.id, text)
	pass


## Blocks the turn when Git is missing and posts an install hint (clickable link) as an agent bubble.
func ensure_git_installed(session_id: int) -> bool:
	if GitUtils.is_git_installed():
		return true
	var url: String = GitUtils.get_download_url()
	AgentSessionManager.add_chat_entry(
			session_id,
			ChatEntry.KIND_AGENT,
			"Git",
			"Git is not installed. Install it, then restart the app."
					+ FileUtils.NEWLINE_LF + FileUtils.NEWLINE_LF
					+ "The agent uses Git to track and revert code changes and Bash to execute shell commands."
					+ FileUtils.NEWLINE_LF + FileUtils.NEWLINE_LF
					+ StringUtils.format("Git Download: [{}]({})", url, url)
	)
	return false


## Re-layout when line count changes (typing, paste, delete). Skip during expand tween.
func on_field_minimum_size_changed() -> void:
	relayout_if_height_changed()
	pass


## While the panel is capped the field keeps the stylebox-only minimum height, so
## minimum_size_changed never fires and a big delete (or clear) would never shrink the panel.
func on_field_text_changed() -> void:
	relayout_if_height_changed()
	pass


func relayout_if_height_changed() -> void:
	if not expanded:
		return
	# Let expand/collapse tweens finish; killing here often freezes the panel at ~collapsed height.
	if layout_tween != null:
		return
	if absf(wrap_offset_height() - get_wrap_height(true)) < 1.0:
		return
	layout_bar()
	pass


func on_field_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if not key.pressed or key.echo:
			return
		var is_enter: bool = key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER
		if not is_enter:
			is_enter = key.physical_keycode == KEY_ENTER or key.physical_keycode == KEY_KP_ENTER
		if not is_enter:
			return
		if key.shift_pressed:
			input_field.insert_text_at_caret(FileUtils.NEWLINE_LF)
			input_field.accept_event()
			input_field.get_viewport().set_input_as_handled()
			return
		on_input_action_pressed()
		input_field.accept_event()
		input_field.get_viewport().set_input_as_handled()
	pass


func on_files_dropped(files: PackedStringArray) -> void:
	if not input_field.editable or files.is_empty() or not input_bar.is_inside_tree():
		return
	var build: StringBuilder = StringBuilder.new()
	for file in files:
		if file.ends_with(".uid"):
			continue
		build.append(file)
	var mouse: Vector2 = input_bar.get_global_mouse_position()
	if not input_wrap.get_global_rect().has_point(mouse) and not input_bar.get_global_rect().has_point(mouse):
		return
	drop_focus_guard = true
	if layout_tween != null:
		layout_tween.kill()
		layout_tween = null
	set_expanded(true, false)
	insert_dropped_files.call_deferred(build.build_joined("  "))
	var guard_timer: SceneTreeTimer = input_bar.get_tree().create_timer(0.4)
	guard_timer.timeout.connect(clear_drop_focus_guard, CONNECT_ONE_SHOT)
	pass


func insert_dropped_files(paths: String) -> void:
	if not input_field.editable or paths.is_empty():
		return
	restore_caret()
	var insert: String = paths
	if input_field.text.length() > 0:
		var line: int = input_field.get_caret_line()
		var col: int = input_field.get_caret_column()
		if col > 0:
			var before: String = input_field.get_line(line).substr(0, col)
			if before.length() > 0 and not before.ends_with(" ") and not before.ends_with(FileUtils.NEWLINE_LF):
				insert = " " + insert
	input_field.insert_text_at_caret(insert)
	focus_input_field.call_deferred()
	var retry_timer: SceneTreeTimer = input_bar.get_tree().create_timer(0.05)
	retry_timer.timeout.connect(focus_input_field, CONNECT_ONE_SHOT)
	pass


func focus_input_field() -> void:
	if not input_field.editable or not input_field.is_inside_tree():
		return
	input_field.visible = true
	var window: Window = input_field.get_window()
	if window != null:
		window.grab_focus()
	input_field.grab_click_focus()
	if not input_field.has_focus():
		input_field.grab_focus()
	restore_caret()
	pass


func clear_drop_focus_guard() -> void:
	drop_focus_guard = false
	pass


func on_field_focus_entered() -> void:
	if not expanded:
		set_expanded(true, true)
	else:
		layout_bar()
	refresh_border_beam()
	restore_caret()
	pass


func on_field_focus_exited() -> void:
	if drop_focus_guard:
		return
	refresh_border_beam()
	try_collapse.call_deferred()
	pass


func on_wrap_gui_input(event: InputEvent) -> void:
	if expanded:
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			expand()
			input_wrap.get_viewport().set_input_as_handled()
	pass


# ---------------------------------------------------------------------------
# Expand / collapse
# ---------------------------------------------------------------------------

func expand_if_collapsed() -> void:
	if not expanded:
		expand()
	pass


func restore_caret() -> void:
	if not input_field.editable:
		return
	style_field()
	var line: int = maxi(0, input_field.get_line_count() - 1)
	var col: int = input_field.get_line(line).length()
	input_field.set_caret_line(line)
	input_field.set_caret_column(col)
	input_field.queue_redraw()
	pass


func expand() -> void:
	set_expanded(true, true)
	if input_field.editable:
		focus_input_field.call_deferred()
	pass


func try_collapse() -> void:
	if send_button.is_hovered():
		return
	if not can_collapse():
		return
	set_expanded(false, true)
	pass


func can_collapse() -> bool:
	if force_expanded:
		return false
	if input_field.text.strip_edges().length() > 0:
		return false
	return not input_field.has_focus()


# ---------------------------------------------------------------------------
# Layout
# ---------------------------------------------------------------------------

func is_point_inside(global_pos: Vector2) -> bool:
	return input_wrap.get_global_rect().has_point(global_pos)


func wrap_offset_height() -> float:
	return input_wrap.offset_bottom - input_wrap.offset_top


func prepare_field_for_expand_measure() -> void:
	input_field.visible = true
	input_field.scroll_fit_content_height = true
	pass


func get_wrap_width(is_expanded: bool) -> float:
	var bar_width: float = maxf(input_bar.size.x, 1.0)
	if not is_expanded:
		return minf(COLLAPSED_SIZE, maxf(1.0, bar_width - Margin.ma_12))
	return maxf(1.0, bar_width - Margin.ma_12 * 2.0)


func get_expanded_height_max() -> float:
	var host: Control = input_bar.get_parent() as Control
	if host == null:
		return EXPANDED_HEIGHT_MIN * 3.0
	return maxf(EXPANDED_HEIGHT_MIN, host.size.y * EXPANDED_HEIGHT_MAX_RATIO)


## Fit-content height of the field. The TextEdit only reports its stylebox-only height while
## scroll_fit_content_height is off, so measure with it temporarily enabled. Two calls in a row
## return the same value, which is what keeps layout_bar() / get_wrap_height() idempotent.
func measure_field_content_height() -> float:
	var was_fit: bool = input_field.scroll_fit_content_height
	if not was_fit:
		input_field.scroll_fit_content_height = true
	var content_h: float = float(input_field.get_minimum_size().y)
	if not was_fit:
		input_field.scroll_fit_content_height = false
	return content_h


## Collapsed: fixed circle. Expanded: follow TextEdit min height, clamped; scroll inside when capped.
## Depends only on the text content, never on the previous fit flag, so repeated calls agree.
func get_wrap_height(is_expanded: bool) -> float:
	if not is_expanded:
		return COLLAPSED_SIZE
	# Margin.ma_1 top + bottom on the wrap stylebox is padding, so it is not usable field height.
	var min_inner: float = maxf(0.0, EXPANDED_HEIGHT_MIN - Margin.ma_2)
	var max_inner: float = get_expanded_height_max() - Margin.ma_2
	var content_h: float = measure_field_content_height()
	var at_cap: bool = content_h > max_inner
	# At max height, stop growing the panel and let TextEdit scroll vertically. Fit content must be
	# off there, otherwise the field clamps its own height to the pasted line count and overflows.
	var want_fit: bool = not at_cap
	if input_field.scroll_fit_content_height != want_fit:
		input_field.scroll_fit_content_height = want_fit
	var inner_h: float = minf(maxf(content_h, min_inner), max_inner)
	return maxf(EXPANDED_HEIGHT_MIN, inner_h + Margin.ma_2)


func layout_bar() -> void:
	var bar_size: Vector2 = input_bar.size
	var wrap_w: float = get_wrap_width(expanded)
	var wrap_h: float = get_wrap_height(expanded)
	input_wrap.offset_left = bar_size.x - Margin.ma_12 - wrap_w
	input_wrap.offset_right = bar_size.x - Margin.ma_12
	input_wrap.offset_top = bar_size.y - Margin.ma_4 - wrap_h
	input_wrap.offset_bottom = bar_size.y - Margin.ma_4
	input_inner.custom_minimum_size = Vector2(0, maxf(0.0, wrap_h - Margin.ma_2))
	input_field.visible = expanded
	if not expanded:
		input_field.scroll_fit_content_height = true
	input_wrap.tooltip_text = "" if expanded else "Click to ask gai Code Agent…"
	layout_send_button(expanded)
	style_wrap()
	layout_border_beam()
	refresh_border_beam()
	pass


func layout_send_button(is_expanded: bool) -> void:
	send_button.visible = true
	# Control grows towards GROW_DIRECTION_BEGIN when a stylebox/content margin pushes the minimum
	# size past the offsets above, which silently shifts the circle. Grow both ways instead.
	send_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	send_button.grow_vertical = Control.GROW_DIRECTION_BOTH
	var half: float = SEND_BUTTON_SIZE * 0.5
	if is_expanded:
		send_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		send_button.offset_left = -SEND_BUTTON_SIZE - Margin.ma_2
		send_button.offset_top = -SEND_BUTTON_SIZE - Margin.ma_2
		send_button.offset_right = -Margin.ma_2
		send_button.offset_bottom = -Margin.ma_2
	else:
		send_button.set_anchors_preset(Control.PRESET_CENTER)
		send_button.offset_left = -half
		send_button.offset_top = -half
		send_button.offset_right = half
		send_button.offset_bottom = half
	send_button.z_index = 2
	pass


func set_expanded(is_expanded: bool, animate: bool) -> void:
	if expanded == is_expanded:
		layout_bar()
		return
	expanded = is_expanded
	if is_expanded:
		prepare_field_for_expand_measure()
	else:
		input_field.visible = false
	if not animate or not input_bar.is_inside_tree():
		layout_bar()
		return

	if layout_tween != null:
		layout_tween.kill()
		layout_tween = null
	layout_tween = input_bar.create_tween()
	layout_tween.set_trans(Tween.TRANS_CUBIC)
	layout_tween.set_ease(Tween.EASE_OUT)

	tween_start_h = wrap_offset_height()
	if tween_start_h <= 1.0:
		tween_start_h = get_wrap_height(not is_expanded)
	tween_target_h = get_wrap_height(is_expanded)
	tween_bar_size = input_bar.size
	tween_start_left = input_wrap.offset_left
	tween_target_left = tween_bar_size.x - Margin.ma_12 - get_wrap_width(is_expanded)
	tween_expand_target = is_expanded

	layout_tween.tween_method(apply_input_tween_step, 0.0, 1.0, 0.22)
	layout_tween.finished.connect(on_input_tween_finished, CONNECT_ONE_SHOT)
	pass


func apply_input_tween_step(value: float) -> void:
	var height: float = lerpf(tween_start_h, tween_target_h, value)
	input_wrap.offset_left = lerpf(tween_start_left, tween_target_left, value)
	input_wrap.offset_right = tween_bar_size.x - Margin.ma_12
	input_wrap.offset_top = tween_bar_size.y - Margin.ma_4 - height
	input_wrap.offset_bottom = tween_bar_size.y - Margin.ma_4
	input_inner.custom_minimum_size.y = maxf(0.0, height - Margin.ma_2)
	# Bottom-right until tween ends; center preset mid-shrink looks like the button slides left.
	layout_send_button(true)
	if border_beam != null:
		set_border_beam_to_wrap(
			lerpf(tween_start_left, tween_target_left, value),
			tween_bar_size.y - Margin.ma_4 - height,
			tween_bar_size.x - Margin.ma_12,
			tween_bar_size.y - Margin.ma_4
		)
		border_beam.set_shape(tween_expand_target)
	pass


func on_input_tween_finished() -> void:
	layout_tween = null
	layout_bar()
	if tween_expand_target:
		sync_expanded_height_after_layout.call_deferred()
	if tween_expand_target and input_field.editable:
		focus_input_field()
	pass


func sync_expanded_height_after_layout() -> void:
	if not expanded:
		return
	prepare_field_for_expand_measure()
	var target_h: float = get_wrap_height(true)
	if absf(wrap_offset_height() - target_h) > 1.0:
		layout_bar()
	pass


# ---------------------------------------------------------------------------
# Theme
# ---------------------------------------------------------------------------

func style_wrap() -> void:
	input_wrap.add_theme_stylebox_override("panel", build_wrap_style(expanded))
	pass


func build_wrap_style(is_expanded: bool) -> StyleBoxFlat:
	var wrap_style: StyleBoxFlat = StyleBoxFlat.new()
	wrap_style.bg_color = AgentColors.chat_input
	wrap_style.set_border_width_all(0)
	var radius: int = 16 if is_expanded else int(COLLAPSED_SIZE / 2)
	wrap_style.set_corner_radius_all(radius)
	if ThemeColor.is_dark_theme():
		wrap_style.shadow_color = Color(0, 0, 0, 0.40)
		wrap_style.shadow_size = 16 if is_expanded else 10
		wrap_style.shadow_offset = Vector2(0, 6 if is_expanded else 4)
	else:
		wrap_style.shadow_color = Color(0, 0, 0, 0.08)
		wrap_style.shadow_size = 12 if is_expanded else 8
		wrap_style.shadow_offset = Vector2(0, 4 if is_expanded else 2)
	wrap_style.content_margin_left = Margin.ma_1
	wrap_style.content_margin_right = Margin.ma_1
	wrap_style.content_margin_top = Margin.ma_1
	wrap_style.content_margin_bottom = Margin.ma_1
	return wrap_style


func build_field_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	style.content_margin_left = Margin.ma_3
	style.content_margin_right = Margin.ma_13
	style.content_margin_top = Margin.ma_3
	style.content_margin_bottom = Margin.ma_3
	return style


func style_field() -> void:
	var input_style: StyleBoxFlat = build_field_style()
	input_field.add_theme_stylebox_override("normal", input_style)
	input_field.add_theme_stylebox_override("focus", input_style.duplicate())
	input_field.add_theme_stylebox_override("read_only", input_style.duplicate())
	input_field.add_theme_font_override("font", Fonts.regular())
	input_field.add_theme_color_override("font_color", AgentColors.chat_text)
	input_field.add_theme_color_override("font_placeholder_color", AgentColors.chat_text_muted)
	input_field.add_theme_color_override("font_readonly_color", AgentColors.chat_text_muted)
	input_field.add_theme_color_override("caret_color", AgentColors.chat_text)
	# Default theme selection (avoid accent-tinted green highlight on chat text).
	input_field.remove_theme_color_override("selection_color")
	input_field.caret_blink = true
	pass


# ---------------------------------------------------------------------------
# Send button & icons
# ---------------------------------------------------------------------------

func configure_send_button(icon: ImageTexture, tooltip: String, base_color: Color) -> void:
	send_button.tooltip_text = tooltip
	send_button.icon = icon
	send_button.add_theme_constant_override("icon_max_width", 16)
	send_button.add_theme_constant_override("icon_max_height", 16)
	apply_send_button_style(base_color)
	pass


func set_send_button_appearance(running: bool) -> void:
	if running:
		configure_send_button(make_stop_icon(16, Color.WHITE), "Stop", AgentColors.error)
	else:
		configure_send_button(
				make_arrow_up_icon(16, Color.WHITE),
				"Send (Enter)",
				AgentColors.theme_accent_solid()
		)
	pass


func apply_send_button_style(base_color: Color) -> void:
	# Radius = half the diameter, and small content margins so the stylebox minimum size
	# (margin + 16px icon + margin) stays below SEND_BUTTON_SIZE, keeping the box a real square.
	var radius: int = int(SEND_BUTTON_SIZE * 0.5)
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(radius)
	normal.content_margin_left = Margin.ma_1
	normal.content_margin_right = Margin.ma_1
	normal.content_margin_top = Margin.ma_1
	normal.content_margin_bottom = Margin.ma_1

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = base_color.lightened(0.10)

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = base_color.darkened(0.08)

	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	disabled.bg_color = base_color.darkened(0.25)

	send_button.add_theme_stylebox_override("normal", normal)
	send_button.add_theme_stylebox_override("hover", hover)
	send_button.add_theme_stylebox_override("pressed", pressed)
	send_button.add_theme_stylebox_override("disabled", disabled)
	send_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pass


func make_arrow_up_icon(size: int, color: Color) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: int = size / 2
	var top: int = int(size * 0.12)
	var bottom: int = int(size * 0.72)
	var half_w: int = int(size * 0.34)
	for y in range(top, bottom + 1):
		var progress: float = float(y - top) / float(bottom - top)
		var half_width: int = int(float(half_w) * progress)
		for x in range(cx - half_width, cx + half_width + 1):
			img.set_pixel(x, y, color)
	var stem_w: int = maxi(1, int(size * 0.12))
	var stem_left: int = cx - stem_w / 2
	var stem_right: int = stem_left + stem_w - 1
	for y in range(bottom, size):
		for x in range(stem_left, stem_right + 1):
			img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


func make_stop_icon(size: int, color: Color) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var square_size: int = maxi(4, int(size * 0.56))
	var left: int = (size - square_size) / 2
	var top: int = (size - square_size) / 2
	for y in range(top, top + square_size):
		for x in range(left, left + square_size):
			img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)
