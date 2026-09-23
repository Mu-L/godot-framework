class_name AgentSessionSidebar
extends RefCounted

## Left sidebar — pinned + normal session lists with select / delete / drag reorder.

## Alpha of the floating row copy that follows the cursor while dragging.
const DRAG_GHOST_ALPHA := 0.92
## Close button and the running wave share this slot, so swapping them while a run
## starts / stops never changes the row width (and never re-ellipsizes the title).
const ROW_ACTION_SIZE := Vector2(28, 28)

var pinned_header: Label
var pinned_list: VBoxContainer
var pinned_separator: HSeparator
var normal_header: Label
var normal_list: VBoxContainer
var new_session_button: Button
var sidebar_panel: PanelContainer

var session_rows: Dictionary[int, PanelContainer] = {}
## 0 = no row hovered; it is never a real session id.
var hover_session_id: int = 0
## Session whose row shows the inline rename field; 0 = none. Only one row edits at a time.
var editing_session_id: int = 0


# ---------------------------------------------------------------------------
# Setup & theme
# ---------------------------------------------------------------------------

func setup(
	p_pinned_header: Label,
	p_pinned_list: VBoxContainer,
	p_pinned_separator: HSeparator,
	p_normal_header: Label,
	p_normal_list: VBoxContainer,
	p_new_session_button: Button,
	p_sidebar_panel: PanelContainer
) -> void:
	pinned_header = p_pinned_header
	pinned_list = p_pinned_list
	pinned_separator = p_pinned_separator
	normal_header = p_normal_header
	normal_list = p_normal_list
	new_session_button = p_new_session_button
	sidebar_panel = p_sidebar_panel
	new_session_button.pressed.connect(on_new_session_pressed)
	gdf.events.theme_changed.connect(apply_theme)
	gdf.events.theme_color_changed.connect(apply_theme)
	AgentEvents.events.session_added.connect(on_session_added)
	AgentEvents.events.session_removed.connect(on_session_removed)
	AgentEvents.events.session_selected.connect(select_item)
	AgentEvents.events.session_title_changed.connect(on_session_refresh)
	AgentEvents.events.agent_start.connect(on_session_refresh)
	AgentEvents.events.session_stop.connect(on_session_refresh)
	AgentEvents.events.workspace_changed.connect(on_workspace_changed)
	pinned_header.mouse_filter = Control.MOUSE_FILTER_PASS
	normal_header.mouse_filter = Control.MOUSE_FILTER_PASS
	bind_list_drop(pinned_list, true)
	bind_list_drop(pinned_header, true)
	bind_list_drop(normal_list, false)
	bind_list_drop(normal_header, false)
	# Dismisses an open rename field on clicks that never move the focus (see the class).
	var click_watcher := RenameClickWatcher.new()
	click_watcher.name = "RenameClickWatcher"
	click_watcher.sidebar = self
	sidebar_panel.add_child(click_watcher)
	apply_theme()
	pass


func on_session_refresh(session_id: int, _arg: Variant = null) -> void:
	refresh_item(session_id)
	pass


func on_workspace_changed(_path: String) -> void:
	reload_sessions()
	pass


func apply_theme() -> void:
	sidebar_panel.add_theme_stylebox_override("panel", build_sidebar_style())
	pinned_header.add_theme_color_override("font_color", AgentColors.sidebar_muted)
	normal_header.add_theme_color_override("font_color", AgentColors.sidebar_muted)
	apply_new_session_button_theme()
	pinned_separator.add_theme_stylebox_override("separator", build_pinned_separator_style())
	refresh_all_row_styles()
	pass


func apply_new_session_button_theme() -> void:
	var accent := AgentColors.theme_accent_solid()
	new_session_button.flat = false
	new_session_button.focus_mode = Control.FOCUS_NONE
	new_session_button.add_theme_color_override("font_color", accent)
	new_session_button.add_theme_color_override("font_hover_color", accent.lightened(0.08))
	new_session_button.add_theme_color_override("font_pressed_color", accent.darkened(0.06))
	new_session_button.add_theme_color_override("font_disabled_color", AgentColors.sidebar_muted)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.55 if ThemeColor.is_dark_theme() else 0.45)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = AgentColors.theme_selection_bg()
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.85)

	var pressed := hover.duplicate() as StyleBoxFlat
	if ThemeColor.current_theme == ThemeColor.ThemeEnum.DARK:
		pressed.bg_color = pressed.bg_color.lightened(0.06)
	else:
		pressed.bg_color = pressed.bg_color.darkened(0.04)
	pressed.border_color = accent

	new_session_button.add_theme_stylebox_override("normal", normal)
	new_session_button.add_theme_stylebox_override("hover", hover)
	new_session_button.add_theme_stylebox_override("pressed", pressed)
	new_session_button.add_theme_stylebox_override("hover_pressed", pressed.duplicate())
	new_session_button.add_theme_stylebox_override("focus", hover.duplicate())
	new_session_button.add_theme_stylebox_override("disabled", normal.duplicate())
	pass


func build_pinned_separator_style() -> StyleBoxLine:
	var line := StyleBoxLine.new()
	var accent := AgentColors.theme_accent_solid()
	var alpha := 0.42 if ThemeColor.is_dark_theme() else 0.32
	line.color = Color(accent.r, accent.g, accent.b, alpha)
	line.grow_begin = 2
	line.grow_end = 2
	line.thickness = 1
	return line


func build_sidebar_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = AgentColors.sidebar
	style.border_color = AgentColors.sidebar_border
	style.set_border_width(SIDE_RIGHT, 1)
	return style


# ---------------------------------------------------------------------------
# List rebuild & refresh
# ---------------------------------------------------------------------------

## Sessions are stored under the workspace root, so switching workspace swaps the whole set.
func reload_sessions() -> void:
	AgentSessionManager.load_from_disk()
	rebuild()
	pass


func rebuild() -> void:
	clear()
	for session_index: AgentSessionIndexes.SessionIndex in AgentSessionManager.session_indexes.pinned_indexes:
		append_row(session_index.id, session_index.title, true)
	for session_index: AgentSessionIndexes.SessionIndex in AgentSessionManager.session_indexes.indexes:
		append_row(session_index.id, session_index.title, false)
	sync_pinned_section_visibility()
	select_item(AgentSessionManager.active_session_id)
	pass


func refresh_item(session_id: int) -> void:
	var row_panel: PanelContainer = session_rows.get(session_id)
	if row_panel == null:
		return
	var select_button: Button = row_panel.get_meta("select_button")
	# A live rename owns the title until it is committed; the run state still refreshes.
	if select_button != null and session_id != editing_session_id:
		select_button.text = AgentSessionManager.get_title(session_id)
	var run_fx: SessionRowRunFx = row_panel.get_meta("run_fx")
	var delete_button: Button = row_panel.get_meta("delete_button")
	if run_fx != null and delete_button != null:
		apply_run_state(run_fx, delete_button, AgentSessionManager.is_running(session_id))
	pass


## Running sessions show the wave where the close button normally sits — same slot size,
## so the row width (and the title's ellipsis) stays put across run start / stop.
func apply_run_state(run_fx: SessionRowRunFx, delete_button: Button, running: bool) -> void:
	run_fx.set_running(running)
	delete_button.visible = not running
	pass


func refresh_all_row_styles() -> void:
	for session_id: int in session_rows:
		style_session_row(session_id)
	pass


## Only the row that lost the selection and the one that gained it need a restyle —
## the rest are already styled when they are built.
func select_item(session_id: int, previous_session_id: int = 0) -> void:
	# Covers selection changes that no click triggered (e.g. the fallback after a delete).
	if editing_session_id != 0 and editing_session_id != session_id:
		commit_rename()
	refresh_item(session_id)
	style_session_row(previous_session_id)
	style_session_row(session_id)
	pass


func sync_pinned_section_visibility() -> void:
	var has_pinned := pinned_list.get_child_count() > 0
	var has_normal := normal_list.get_child_count() > 0
	pinned_separator.visible = has_pinned and has_normal
	pinned_list.custom_minimum_size = Vector2.ZERO
	# Empty Chats list has no row hit target — keep a small drop pad when unpinning is possible.
	normal_list.custom_minimum_size = Vector2(0, 40) if has_pinned and not has_normal else Vector2.ZERO
	pass


# ---------------------------------------------------------------------------
# Event handlers
# ---------------------------------------------------------------------------

func on_session_added(session_id: int, title: String) -> void:
	append_row(session_id, title, false)
	normal_list.move_child(session_rows[session_id], 0)
	pass


func on_session_removed(session_id: int) -> void:
	remove_row(session_id)
	sync_pinned_section_visibility()
	pass


func on_new_session_pressed() -> void:
	var session := AgentSessionManager.create_session()
	AgentSessionManager.select_session(session.id)
	pass


func on_session_row_pressed(session_id: int) -> void:
	# Clicking the chat that is already open starts renaming it instead of re-opening it.
	if AgentSessionManager.is_active(session_id):
		begin_rename(session_id)
		return
	AgentSessionManager.select_session(session_id)
	pass


func on_session_delete_pressed(session_id: int) -> void:
	AgentSessionManager.delete_session(session_id)
	pass


# ---------------------------------------------------------------------------
# Row build & remove
# ---------------------------------------------------------------------------

func clear() -> void:
	for list: VBoxContainer in [pinned_list, normal_list]:
		for child in list.get_children():
			child.queue_free()
	session_rows.clear()
	editing_session_id = 0
	pass


func list_for_pinned(pinned: bool) -> VBoxContainer:
	return pinned_list if pinned else normal_list


func append_row(session_id: int, title: String, pinned: bool) -> void:
	var row_panel := PanelContainer.new()
	row_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	row_panel.mouse_default_cursor_shape = Control.CURSOR_MOVE
	bind_row_hover(row_panel, session_id)

	var fx := SessionRowSciFiFx.new()
	fx.name = "SciFiFx"
	row_panel.add_child(fx)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	row_panel.add_child(row)

	var select_button := Button.new()
	select_button.text = title
	select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	select_button.focus_mode = Control.FOCUS_NONE
	select_button.flat = true
	select_button.mouse_default_cursor_shape = Control.CURSOR_MOVE
	select_button.pressed.connect(on_session_row_pressed.bind(session_id))
	bind_row_hover(select_button, session_id)
	# Cut at the row width, character by character, without an ellipsis.
	select_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR

	# The wave takes the close button's slot while this session runs.
	var run_fx := SessionRowRunFx.new()
	run_fx.custom_minimum_size = ROW_ACTION_SIZE

	var delete_button := Button.new()
	delete_button.text = "×"
	delete_button.tooltip_text = "Delete chat"
	delete_button.custom_minimum_size = ROW_ACTION_SIZE
	delete_button.focus_mode = Control.FOCUS_NONE
	delete_button.flat = true
	delete_button.pressed.connect(on_session_delete_pressed.bind(session_id))
	bind_row_hover(delete_button, session_id)
	apply_run_state(run_fx, delete_button, AgentSessionManager.is_running(session_id))

	# Whole row (padding, title, close button) is a drag handle and a drop target.
	bind_row_drag(row_panel, session_id)
	bind_row_drag(select_button, session_id)
	bind_row_drag(delete_button, session_id)

	row.add_child(select_button)
	row.add_child(run_fx)
	row.add_child(delete_button)
	row_panel.set_meta("select_button", select_button)
	row_panel.set_meta("delete_button", delete_button)
	row_panel.set_meta("run_fx", run_fx)
	row_panel.set_meta("scifi_fx", fx)
	row_panel.set_meta("pinned", pinned)
	list_for_pinned(pinned).add_child(row_panel)
	session_rows[session_id] = row_panel
	style_session_row(session_id)
	pass


func remove_row(session_id: int) -> void:
	var row_panel: PanelContainer = session_rows.get(session_id)
	if row_panel == null:
		return
	if hover_session_id == session_id:
		hover_session_id = 0
	if editing_session_id == session_id:
		# The rename field is freed together with the row it lives in.
		editing_session_id = 0
	row_panel.queue_free()
	session_rows.erase(session_id)
	pass


# ---------------------------------------------------------------------------
# Row styling
# ---------------------------------------------------------------------------

func bind_row_hover(control: Control, session_id: int) -> void:
	control.mouse_entered.connect(on_session_row_mouse_entered.bind(session_id))
	control.mouse_exited.connect(on_session_row_mouse_exited.bind(session_id))
	pass


func on_session_row_mouse_entered(session_id: int) -> void:
	hover_session_id = session_id
	style_session_row(session_id)
	pass


func on_session_row_mouse_exited(session_id: int) -> void:
	var row_panel: PanelContainer = session_rows.get(session_id)
	if row_panel != null and row_panel.get_global_rect().has_point(row_panel.get_global_mouse_position()):
		return
	if hover_session_id == session_id:
		hover_session_id = 0
	style_session_row(session_id)
	pass


func build_session_row_style(selected: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	if selected:
		style.bg_color = AgentColors.theme_selection_bg()
	elif hovered:
		style.bg_color = AgentColors.sidebar_row_hover
	else:
		style.bg_color = Color(0, 0, 0, 0)
	return style


func style_session_row(session_id: int) -> void:
	var row_panel: PanelContainer = session_rows.get(session_id)
	if row_panel == null:
		return
	var select_button: Button = row_panel.get_meta("select_button")
	if select_button == null:
		return

	var selected := session_id == AgentSessionManager.active_session_id
	var hovered := hover_session_id == session_id
	row_panel.add_theme_stylebox_override("panel", build_session_row_style(selected, hovered))

	var text_color := AgentColors.sidebar_text if selected or hovered else AgentColors.sidebar_muted
	select_button.add_theme_color_override("font_color", text_color)
	select_button.add_theme_color_override("font_hover_color", text_color)
	select_button.add_theme_color_override("font_pressed_color", text_color)

	var delete_button: Button = row_panel.get_meta("delete_button")
	if delete_button != null:
		delete_button.add_theme_color_override("font_color", AgentColors.sidebar_muted)
		delete_button.add_theme_color_override("font_hover_color", AgentColors.error)
		delete_button.add_theme_color_override("font_pressed_color", AgentColors.error)

	var fx: SessionRowSciFiFx = row_panel.get_meta("scifi_fx")
	if fx != null:
		fx.set_highlight(selected)
	# Re-apply the field's theme overrides while a rename is open.
	var edit := rename_edit_of(row_panel)
	if edit != null:
		style_rename_edit(edit, session_id)
	pass


# ---------------------------------------------------------------------------
# Inline rename — click the open chat again to edit its title where the title sits
# ---------------------------------------------------------------------------

## Closes an open rename field when the click landed outside it. Needed because row buttons are
## [constant Control.FOCUS_NONE] — a click on another row never blurs the field, so focus loss
## alone cannot dismiss it. The position comes straight from the input event, so it is in the
## same space as [method Control.get_global_rect].
func close_rename_if_clicked_outside(click_position: Vector2) -> void:
	var edit := rename_edit_of(session_rows.get(editing_session_id))
	if edit == null or edit.get_global_rect().has_point(click_position):
		return
	commit_rename()
	pass


## Swaps the row's title button for a LineEdit in the same slot, so the row neither grows nor
## jumps. Enter / focus loss commit, Esc discards, a blank title keeps the previous name.
func begin_rename(session_id: int) -> void:
	if editing_session_id == session_id:
		return
	commit_rename()
	var row_panel: PanelContainer = session_rows.get(session_id)
	if row_panel == null:
		return
	var select_button: Button = row_panel.get_meta("select_button")
	var edit := LineEdit.new()
	edit.text = AgentSessionManager.get_title(session_id)
	edit.placeholder_text = "Chat title"
	edit.max_length = AgentSessionManager.MAX_TITLE_LENGTH
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if select_button.size.y > 0.0:
		edit.custom_minimum_size.y = select_button.size.y
	edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	edit.select_all_on_focus = true
	edit.drag_and_drop_selection_enabled = false
	edit.mouse_default_cursor_shape = Control.CURSOR_IBEAM
	edit.text_submitted.connect(on_rename_submitted.bind(session_id))
	edit.focus_exited.connect(on_rename_focus_exited.bind(session_id))
	edit.gui_input.connect(on_rename_gui_input.bind(session_id))
	style_rename_edit(edit, session_id)

	select_button.visible = false
	select_button.get_parent().add_child(edit)
	edit.get_parent().move_child(edit, select_button.get_index())
	row_panel.set_meta("rename_edit", edit)
	editing_session_id = session_id
	# Deferred: the click that opened the field is still being handled here.
	edit.call_deferred("grab_focus")
	pass


## Stores the typed title and puts the row back to its normal state. Idempotent, so the
## commit handlers can all call it.
func commit_rename() -> void:
	var session_id := editing_session_id
	if session_id == 0:
		return
	var edit := rename_edit_of(session_rows.get(session_id))
	var title := StringUtils.EMPTY if edit == null else edit.text
	end_rename()
	# A blank title is rejected by the manager, so the row falls back to its previous name.
	AgentSessionManager.set_title(session_id, title)
	pass


func cancel_rename() -> void:
	var session_id := editing_session_id
	if session_id == 0:
		return
	end_rename()
	refresh_item(session_id)
	pass


## Drops the edit field (and the id guard first, so the focus loss it causes cannot recurse).
func end_rename() -> void:
	var row_panel: PanelContainer = session_rows.get(editing_session_id)
	editing_session_id = 0
	if row_panel == null:
		return
	var edit := rename_edit_of(row_panel)
	if edit != null:
		row_panel.remove_meta("rename_edit")
		# Hidden right away: the slot is handed back to the title button before the free lands.
		edit.visible = false
		edit.queue_free()
	var select_button: Button = row_panel.get_meta("select_button")
	if select_button != null:
		select_button.visible = true
	pass


## The field only exists in the row's meta while it is open, so absence means "not editing".
func rename_edit_of(row_panel: PanelContainer) -> LineEdit:
	if row_panel == null or not row_panel.has_meta("rename_edit"):
		return null
	return row_panel.get_meta("rename_edit")


func on_rename_submitted(_text: String, session_id: int) -> void:
	if editing_session_id != session_id:
		return
	commit_rename()
	pass


## Clicking anywhere else (another row, the chat input, …) keeps what was typed.
func on_rename_focus_exited(session_id: int) -> void:
	if editing_session_id != session_id:
		return
	commit_rename()
	pass


## Esc discards the edit; swallowing the event also stops the chat input's Esc handling.
func on_rename_gui_input(event: InputEvent, session_id: int) -> void:
	if editing_session_id != session_id or not event.is_action_pressed("ui_cancel"):
		return
	var edit: LineEdit = rename_edit_of(session_rows[editing_session_id])
	cancel_rename()
	if edit != null:
		edit.accept_event()
	pass


func style_rename_edit(edit: LineEdit, session_id: int) -> void:
	var row_panel: PanelContainer = session_rows.get(session_id)
	var select_button: Button = null if row_panel == null else row_panel.get_meta("select_button")
	if select_button != null:
		copy_title_font(edit, select_button)
	edit.add_theme_color_override("font_color", AgentColors.sidebar_text)
	edit.add_theme_color_override("font_placeholder_color", AgentColors.sidebar_muted)
	edit.add_theme_color_override("caret_color", AgentColors.theme_accent_solid())
	edit.add_theme_color_override("selection_color", AgentColors.theme_selection_bg())
	edit.add_theme_stylebox_override("normal", build_rename_edit_style())
	edit.add_theme_stylebox_override("focus", build_rename_edit_style())
	pass


func build_rename_edit_style() -> StyleBoxFlat:
	var accent := AgentColors.theme_accent_solid()
	var style := StyleBoxFlat.new()
	style.bg_color = AgentColors.chat_input
	style.border_color = Color(accent.r, accent.g, accent.b, 0.75 if ThemeColor.is_dark_theme() else 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 5
	style.content_margin_right = 5
	return style


## Watches the whole viewport so any click outside the open rename field closes it — row buttons,
## toolbar buttons and empty areas included, since none of them take the focus away.
class RenameClickWatcher extends Node:
	var sidebar: AgentSessionSidebar


	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			sidebar.close_rename_if_clicked_outside(event.position)
		pass


# ---------------------------------------------------------------------------
# Drag reorder & pin / unpin
# ---------------------------------------------------------------------------

func get_row_drag_data(_at_position: Vector2, session_id: int) -> Variant:
	var row_panel: PanelContainer = session_rows.get(session_id)
	# While the row is being renamed the drag must not steal the click and move it away.
	if row_panel == null or session_id == editing_session_id:
		return null
	row_panel.set_drag_preview(build_drag_ghost(session_id, row_panel))
	return session_id


## Floating copy of the row that follows the cursor until the mouse is released.
func build_drag_ghost(session_id: int, row_panel: PanelContainer) -> Control:
	var row_size := row_panel.size
	if row_size.x < 1.0 or row_size.y < 1.0:
		row_size = row_panel.get_combined_minimum_size()

	var preview := Control.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.custom_minimum_size = row_size
	preview.size = row_size
	preview.modulate.a = DRAG_GHOST_ALPHA

	var ghost := PanelContainer.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.size = row_size
	ghost.add_theme_stylebox_override("panel", build_drag_ghost_style())
	preview.add_child(ghost)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = AgentSessionManager.get_title(session_id)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy_row_font(label, row_panel)
	ghost.add_child(label)

	# The engine moves `preview` to the cursor, so offset the ghost by the grab point.
	ghost.position = -clamp_to_row(row_panel.get_local_mouse_position(), row_size)
	return preview


## The cursor can already sit a few pixels outside the row once the drag starts.
func clamp_to_row(point: Vector2, row_size: Vector2) -> Vector2:
	return Vector2(clampf(point.x, 0.0, row_size.x), clampf(point.y, 0.0, row_size.y))


## Reuse the row button's resolved font so the ghost matches the sidebar styling.
func copy_row_font(label: Label, row_panel: PanelContainer) -> void:
	var source: Button = row_panel.get_meta("select_button")
	if source == null:
		return
	copy_title_font(label, source)
	label.add_theme_color_override("font_color", AgentColors.sidebar_text)
	pass


## The rename field takes over the title's slot, so it mirrors the title's resolved font.
func copy_title_font(target: Control, source: Button) -> void:
	target.add_theme_font_override("font", source.get_theme_font("font"))
	target.add_theme_font_size_override("font_size", source.get_theme_font_size("font_size"))
	pass


func build_drag_ghost_style() -> StyleBoxFlat:
	var style := build_session_row_style(false, false)
	style.bg_color = AgentColors.theme_selection_bg()
	var accent := AgentColors.theme_accent_solid()
	style.border_color = Color(accent.r, accent.g, accent.b, 0.9 if ThemeColor.is_dark_theme() else 0.75)
	style.set_border_width_all(1)
	style.shadow_color = Color(0, 0, 0, 0.35 if ThemeColor.is_dark_theme() else 0.18)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style


func bind_row_drag(host: Control, session_id: int) -> void:
	host.set_drag_forwarding(get_row_drag_data.bind(session_id), can_drop_on_row.bind(session_id), drop_on_row.bind(session_id))
	pass


func row_is_pinned(session_id: int) -> bool:
	var row_panel: PanelContainer = session_rows.get(session_id)
	if row_panel == null:
		return AgentSessionManager.is_pinned(session_id)
	return row_panel.get_meta("pinned", false)


func clamp_move_index(from_row: PanelContainer, target_list: VBoxContainer, to_index: int) -> int:
	var max_index := maxi(0, target_list.get_child_count() - 1)
	return clampi(to_index, 0, max_index)


func apply_row_move(session_id: int, from_row: PanelContainer, target_list: VBoxContainer, to_index: int, to_pinned: bool) -> void:
	var need_section_change := AgentSessionManager.is_pinned(session_id) != to_pinned
	if from_row.get_parent() != target_list:
		from_row.reparent(target_list)
		from_row.set_meta("pinned", to_pinned)
		sync_pinned_section_visibility()

	to_index = clamp_move_index(from_row, target_list, to_index)
	var from_index := from_row.get_index()
	if not need_section_change and from_index == to_index:
		return

	if from_index != to_index:
		target_list.move_child(from_row, to_index)

	if need_section_change:
		AgentSessionManager.transfer_session_index(session_id, to_pinned, from_row.get_index())
	elif from_index != to_index:
		AgentSessionManager.move_index_in_list(session_id, from_row.get_index(), to_pinned)
	pass


## Query only — the reorder is applied in `drop_on_row` when the mouse is released.
func can_drop_on_row(_at_position: Vector2, data: Variant, target_id: int) -> bool:
	if typeof(data) != TYPE_INT:
		return false
	return session_rows.has(data) and session_rows.has(target_id)


func drop_on_row(_at_position: Vector2, data: Variant, target_id: int) -> bool:
	if typeof(data) != TYPE_INT:
		return false
	var session_id: int = data
	var from_row: PanelContainer = session_rows.get(session_id)
	var target_row: PanelContainer = session_rows.get(target_id)
	if from_row == null or target_row == null:
		return false
	var to_pinned := row_is_pinned(target_id)
	apply_row_move(session_id, from_row, list_for_pinned(to_pinned), target_row.get_index(), to_pinned)
	return true


func bind_list_drop(host: Control, pinned: bool) -> void:
	host.set_drag_forwarding(
		func(_at: Vector2) -> Variant: return null,
		can_drop_on_list.bind(pinned),
		drop_on_list.bind(pinned)
	)
	pass


## Query only — the reorder is applied in `drop_on_list` when the mouse is released.
func can_drop_on_list(_at_position: Vector2, data: Variant, _pinned: bool) -> bool:
	if typeof(data) != TYPE_INT:
		return false
	return session_rows.has(data)


## Dropping on the list background appends the row to the end of that list.
func drop_on_list(_at_position: Vector2, data: Variant, pinned: bool) -> bool:
	if typeof(data) != TYPE_INT:
		return false
	var session_id: int = data
	var from_row: PanelContainer = session_rows.get(session_id)
	if from_row == null:
		return false
	var target_list := list_for_pinned(pinned)
	var to_index := target_list.get_child_count()
	if from_row.get_parent() == target_list and to_index > 0:
		to_index -= 1
	apply_row_move(session_id, from_row, target_list, to_index, pinned)
	return true


# ---------------------------------------------------------------------------
# Selected row overlay (shader: sidebar_session_row.gdshader)
# ---------------------------------------------------------------------------

class SessionRowSciFiFx extends ColorRect:
	const SHADER := preload("res://agent/ui/shaders/sidebar_session_row.gdshader")
	const CORNER_RADIUS := 6.0

	var fx_material: ShaderMaterial


	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		color = Color(1.0, 1.0, 1.0, 0.0)
		set_anchors_preset(PRESET_FULL_RECT)
		fx_material = ShaderMaterial.new()
		fx_material.shader = SHADER
		material = fx_material
		visible = false
		pass


	func _ready() -> void:
		var parent_row := get_parent() as Control
		if parent_row != null:
			parent_row.resized.connect(sync_uniforms)
		resized.connect(sync_uniforms)
		sync_uniforms()
		pass


	func set_highlight(active: bool) -> void:
		visible = active
		color.a = 1.0 if active else 0.0
		if fx_material == null:
			return
		fx_material.set_shader_parameter("strength", 1.0 if active else 0.0)
		sync_uniforms()
		queue_redraw()
		pass


	func sync_uniforms() -> void:
		if fx_material == null:
			return
		var sz := size
		if sz.x < 1.0 or sz.y < 1.0:
			var parent_row := get_parent() as Control
			if parent_row != null:
				sz = parent_row.size
		fx_material.set_shader_parameter("rect_size", sz)
		fx_material.set_shader_parameter("corner_radius", CORNER_RADIUS)
		fx_material.set_shader_parameter("accent_color", AgentColors.theme_accent_solid())
		fx_material.set_shader_parameter("is_dark", 1.0 if ThemeColor.is_dark_theme() else 0.0)
		pass


# ---------------------------------------------------------------------------
# Running wave (drawn, animated; color follows the theme accent)
# ---------------------------------------------------------------------------

## Small flowing sine wave shown in place of the close button while a session runs.
## Drawn in code so it always reflects the live theme accent.
## It shares the close button's slot size, so the swap costs no extra row width.
class SessionRowRunFx extends Control:
	## Horizontal distance between samples, and the padding that keeps the stroked
	## line inside the control rect.
	const SAMPLE_STEP := 1.0
	const PAD := 1.6
	## Wave shape: radians per pixel and the base amplitude in pixels.
	const WAVE_SCALE := 0.72
	const AMPLITUDE := 5.5
	## Scroll speed in radians per second (about one wavelength per second).
	const FLOW_SPEED := 6.0
	## Amplitude breathing, so the stream does not look like a static graph.
	const BREATH_SPEED := 2.1
	const BREATH_DEPTH := 0.08
	## Beading along the wave reads as packets travelling downstream.
	const PACKET_STEP := 3
	const PACKET_RADIUS := 0.6

	var phase := 0.0


	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		visible = false
		pass


	## The engine auto-enables `_process` for any script that defines it (after `_init`),
	## so the real state has to be re-applied once the node is in the tree.
	func _ready() -> void:
		set_process(visible)
		pass


	## `visible` doubles as the state — repeated calls (refresh, title change, select) must
	## not restart the wave, only an actual start does.
	func set_running(value: bool) -> void:
		if visible == value:
			return
		visible = value
		set_process(value)
		if value:
			phase = 0.0
		queue_redraw()
		pass


	func _process(delta: float) -> void:
		phase = fposmod(phase + delta * FLOW_SPEED, TAU * 512.0)
		queue_redraw()
		pass


	func _draw() -> void:
		if size.x - PAD * 2.0 <= 2.0 or size.y <= PAD * 2.0:
			return
		var accent := AgentColors.theme_accent_solid()
		var points := wave_points()
		# Glow pass keeps the thin stroke readable on either theme.
		draw_polyline(points, Color(accent, 0.30 if ThemeColor.is_dark_theme() else 0.22), 1.6, true)
		draw_polyline(points, accent, 0.8, true)
		# Bright beads on the samples, giving the wave a sense of flow.
		for index in range(0, points.size(), PACKET_STEP):
			draw_circle(points[index], PACKET_RADIUS, Color(accent.lightened(0.35), 0.55))
		pass


	## Traveling sine sampled across the whole control width.
	func wave_points() -> PackedVector2Array:
		var amplitude := AMPLITUDE * (1.0 + BREATH_DEPTH * sin(phase * BREATH_SPEED))
		var center_y := size.y * 0.5
		var points := PackedVector2Array()
		var x := PAD
		while x <= size.x - PAD:
			points.append(Vector2(x, center_y + sin(x * WAVE_SCALE - phase) * amplitude))
			x += SAMPLE_STEP
		return points
