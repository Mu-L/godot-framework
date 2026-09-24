extends Control

const SIDEBAR_WIDTH: int = 300
const PALETTE_TREE_WIDTH: int = 276
const PALETTE_LABEL_MAX: int = 30
const LOCALE_ZH := "zh_CN"
const LOCALE_EN := "en_US"
const LOCALE_PATHS: Array[String] = [
	"res://gui/locale/en-US.json",
	"res://gui/locale/zh-CN.json",
]

@onready var graph_edit: SkillGraphEdit = $Root/Body/SkillGraphEdit
@onready var sidebar: PanelContainer = $Root/Body/Sidebar
@onready var palette_tree: Tree = $Root/Body/Sidebar/PaletteVBox/PaletteScroll/PaletteTree
@onready var workflow_name_label: Label = $Root/Toolbar/TitlePanel/WorkflowName
@onready var palette_title: Label = $Root/Body/Sidebar/PaletteVBox/PaletteTitle
@onready var palette_hint: Label = $Root/Body/Sidebar/PaletteVBox/PaletteHint
@onready var new_button: Button = $Root/Toolbar/Actions/NewButton
@onready var load_button: Button = $Root/Toolbar/Actions/LoadButton
@onready var save_button: Button = $Root/Toolbar/Actions/SaveButton
@onready var delete_button: Button = $Root/Toolbar/Actions/DeleteButton
@onready var locale_button: Button = $Root/Toolbar/Actions/LocaleButton
@onready var log_button: Button = $Root/Toolbar/Actions/LogButton
@onready var run_button: Button = $Root/Toolbar/Actions/RunButton
@onready var save_dialog: FileDialog = $SaveDialog
@onready var load_dialog: FileDialog = $LoadDialog

var pipeline_runner: PipelineRunner  = PipelineRunner.new()

var running_pipeline: bool = false


func _ready() -> void:
	if not TranslationJson.register_json_files(LOCALE_PATHS):
		return
	TranslationServer.set_locale(LOCALE_EN)
	configure_sidebar_layout()
	apply_ui_locale()
	set_workflow_name(WorkflowManager.workflow_name)
	style_run_button()
	build_palette_tree()

	new_button.pressed.connect(on_new_pressed)
	save_button.pressed.connect(on_save_pressed)
	load_button.pressed.connect(on_load_pressed)
	run_button.pressed.connect(on_run_pressed)
	delete_button.pressed.connect(on_delete_pressed)
	locale_button.pressed.connect(on_locale_pressed)
	log_button.pressed.connect(on_log_pressed)

	palette_tree.item_selected.connect(on_palette_item_selected)
	palette_tree.item_activated.connect(on_palette_item_activated)

	save_dialog.file_selected.connect(on_save_file_selected)
	load_dialog.file_selected.connect(on_load_file_selected)

	WorkflowEvents.events.step_started.connect(on_step_started)
	WorkflowEvents.events.step_finished.connect(on_step_finished)
	WorkflowEvents.events.pipeline_finished.connect(on_pipeline_finished)
	WorkflowEvents.events.pipeline_stopped.connect(on_pipeline_stopped)

	WorkflowManager.ensure_workflows_dir()
	pass


func configure_sidebar_layout() -> void:
	sidebar.custom_minimum_size.x = SIDEBAR_WIDTH
	sidebar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sidebar.clip_contents = true
	palette_tree.custom_minimum_size.x = PALETTE_TREE_WIDTH
	palette_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	palette_tree.set_column_expand(0, false)
	palette_tree.set_column_custom_minimum_width(0, PALETTE_TREE_WIDTH)
	pass


func palette_display_label(label: String) -> String:
	return StringUtils.truncate(label, PALETTE_LABEL_MAX)


func set_palette_item_text(item: TreeItem, label: String) -> void:
	item.set_text(0, palette_display_label(label))
	if label.length() > PALETTE_LABEL_MAX:
		item.set_tooltip_text(0, label)
	else:
		item.set_tooltip_text(0, "")
	pass


func apply_ui_locale() -> void:
	new_button.text = tr("ui.toolbar.new")
	load_button.text = tr("ui.toolbar.load")
	save_button.text = tr("ui.toolbar.save")
	delete_button.text = tr("ui.toolbar.delete")
	log_button.text = tr("ui.toolbar.log")
	if running_pipeline:
		run_button.text = tr("ui.toolbar.stop")
	else:
		run_button.text = tr("ui.toolbar.run")
	palette_title.text = tr("ui.palette.title")
	palette_hint.text = tr("ui.palette.hint")
	palette_hint.add_theme_color_override("font_color", WorkflowColors.hint)
	save_dialog.title = tr("ui.dialog.save_title")
	save_dialog.ok_button_text = tr("ui.toolbar.save")
	save_dialog.filters = PackedStringArray([
		"*.workflow.json ; " + tr("ui.dialog.workflow_filter"),
		"* ; " + tr("ui.dialog.all_files"),
	])
	load_dialog.title = tr("ui.dialog.load_title")
	load_dialog.ok_button_text = tr("ui.toolbar.load")
	load_dialog.filters = PackedStringArray([
		"*.workflow.json ; " + tr("ui.dialog.workflow_filter"),
	])
	refresh_locale_button()
	pass


func refresh_locale_button() -> void:
	if TranslationServer.get_locale() == LOCALE_ZH:
		locale_button.text = tr("ui.locale_switch.to_en")
	else:
		locale_button.text = tr("ui.locale_switch.to_zh")
	pass


func apply_locale_change() -> void:
	TranslationServer.set_locale(LOCALE_EN if TranslationServer.get_locale() == LOCALE_ZH else LOCALE_ZH)
	apply_ui_locale()
	build_palette_tree()
	set_workflow_name(WorkflowManager.workflow_name)
	graph_edit.reload_locale(WorkflowManager.workflow_name)
	pass


func on_locale_pressed() -> void:
	apply_locale_change()
	pass


func build_palette_tree() -> void:
	palette_tree.clear()
	palette_tree.hide_root = true
	palette_tree.column_titles_visible = false
	var root: TreeItem = palette_tree.create_item()

	for category_id in GraphNodesConfig.CATEGORY_IDS:
		var skills: Array[GraphNodeDef] = GraphNodesConfig.list_skills_in_category(category_id)
		if skills.is_empty():
			continue

		var category_item: TreeItem = palette_tree.create_item(root)
		set_palette_item_text(category_item, GraphNodesConfig.category_label(category_id))
		category_item.set_collapsed(true)
		category_item.set_selectable(0, true)

		for skill in skills:
			var skill_item: TreeItem = palette_tree.create_item(category_item)
			set_palette_item_text(skill_item, skill.display_label())
			skill_item.set_metadata(0, {"kind": "skill", "id": skill.catalog_id()})
			skill_item.set_selectable(0, true)

	var workflows_item: TreeItem = palette_tree.create_item(root)
	set_palette_item_text(workflows_item, tr("ui.palette.my_workflows"))
	workflows_item.set_collapsed(false)
	workflows_item.set_selectable(0, true)

	for workflow_path in WorkflowManager.list_saved_workflows():
		var workflow_item: TreeItem = palette_tree.create_item(workflows_item)
		var label: String = WorkflowManager.workflow_name_from_path(workflow_path)
		set_palette_item_text(workflow_item, label)
		workflow_item.set_metadata(0, {"kind": "workflow", "path": workflow_path})
		workflow_item.set_selectable(0, true)
	pass


func on_palette_item_selected() -> void:
	var item: TreeItem = palette_tree.get_selected()
	if item == null:
		return
	var meta: Variant = item.get_metadata(0)
	if meta == null:
		item.set_collapsed(false)
	pass


func on_palette_item_activated() -> void:
	var item: TreeItem = palette_tree.get_selected()
	if item == null:
		return
	var meta: Variant = item.get_metadata(0)
	if meta == null or not meta is Dictionary:
		return
	var kind: String = str(meta.get("kind", ""))
	if kind == "workflow":
		open_workflow_at_path(str(meta.get("path", "")))
	elif kind == "skill":
		var spawn_pos: Vector2 = Vector2(120 + graph_edit.node_seq * 24, 120 + graph_edit.node_seq * 18)
		graph_edit.add_skill_node(str(meta.get("id", "")), spawn_pos)
	pass


func on_new_pressed() -> void:
	graph_edit.clear_graph()
	WorkflowManager.new_workflow()
	set_workflow_name(WorkflowManager.workflow_name)
	pass


func on_save_pressed() -> void:
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.current_dir = WorkflowManager.globalized_workflows_dir()
	if not WorkflowManager.current_path.is_empty():
		save_dialog.current_path = WorkflowManager.current_path
	else:
		save_dialog.current_file = StringUtils.format(
			"{}{}", WorkflowManager.workflow_name, WorkflowManager.WORKFLOW_EXT
		)
	save_dialog.popup_centered()
	pass


func on_load_pressed() -> void:
	load_dialog.current_dir = WorkflowManager.globalized_workflows_dir()
	load_dialog.popup_centered()
	pass


func on_save_file_selected(path: String) -> void:
	var doc: WorkflowDocument = graph_edit.build_document(WorkflowManager.workflow_name_from_path(path))
	WorkflowManager.save(path, doc)
	set_workflow_name(WorkflowManager.workflow_name)
	build_palette_tree()
	pass


func on_load_file_selected(path: String) -> void:
	open_workflow_at_path(path)
	pass


func open_workflow_at_path(path: String) -> void:
	if path.is_empty():
		return
	var doc: WorkflowDocument = WorkflowManager.load(path)
	if doc == null:
		return
	graph_edit.load_document(doc)
	set_workflow_name(WorkflowManager.workflow_name)
	pass


func set_workflow_name(name: String) -> void:
	if StringUtils.is_blank(name):
		return
	WorkflowManager.workflow_name = name.strip_edges()
	var display_name: String = WorkflowManager.workflow_name
	if display_name == "Untitled":
		display_name = tr("ui.untitled")
	workflow_name_label.text = display_name
	get_window().title = tr("ui.window_title").format([display_name], StringUtils.EMPTY_JSON)
	pass


func on_log_pressed() -> void:
	LogWindow.show_log_window(128, 70, 80)
	pass


func on_delete_pressed() -> void:
	graph_edit.remove_selected_nodes()
	pass


func on_run_pressed() -> void:
	if running_pipeline:
		pipeline_runner.request_stop()
		return
	running_pipeline = true
	set_run_button_running(true)
	var doc: WorkflowDocument = graph_edit.build_document(WorkflowManager.workflow_name)
	Log.info("--- Starting workflow ---")
	await pipeline_runner.run(doc)
	pass


func on_step_started(node_id: String, label: String) -> void:
	Log.info("step started label:[{}] node:[{}]", label, node_id)
	pass


func on_step_finished(node_id: String, exit_code: int, output_path: String) -> void:
	if exit_code == 0:
		Log.info("step finished node:[{}] output:[{}]", node_id, output_path)
	else:
		Log.error("step failed node:[{}] exit:[{}]", node_id, exit_code)
	pass


func on_pipeline_stopped() -> void:
	running_pipeline = false
	set_run_button_running(false)
	var message := tr("pipeline.stopped")
	Log.info(message)
	Alert.alert(message, WorkflowColors.warning)
	pass


func on_pipeline_finished(success: bool, message: String) -> void:
	running_pipeline = false
	set_run_button_running(false)
	if success:
		Log.info(message)
		Alert.alert(message, WorkflowColors.success)
	else:
		Log.error(message)
		Alert.alert(message, WorkflowColors.error)
	pass


# ----------------------------------------------------------------------------------------------------------------------
func set_run_button_running(running: bool) -> void:
	if running:
		apply_run_button_style(WorkflowColors.error)
		run_button.icon = make_stop_icon(14, WorkflowColors.button_text)
		run_button.text = tr("ui.toolbar.stop")
	else:
		apply_run_button_style(WorkflowColors.success)
		run_button.icon = make_play_icon(14, WorkflowColors.button_text)
		run_button.text = tr("ui.toolbar.run")
	pass


func style_run_button() -> void:
	apply_run_button_style(WorkflowColors.success)
	run_button.add_theme_color_override("font_color", WorkflowColors.button_text)
	run_button.add_theme_color_override("font_hover_color", WorkflowColors.button_text)
	run_button.add_theme_color_override("font_pressed_color", WorkflowColors.button_text)
	run_button.icon = make_play_icon(14, WorkflowColors.button_text)
	run_button.text = tr("ui.toolbar.run")
	run_button.add_theme_constant_override("icon_max_width", 14)
	run_button.add_theme_constant_override("icon_max_height", 14)
	run_button.add_theme_constant_override("h_separation", Margin.ma_2)
	pass


func apply_run_button_style(base_color: Color) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(4)
	normal.content_margin_top = Margin.ma_1
	normal.content_margin_bottom = Margin.ma_1
	normal.content_margin_left = Margin.ma_3
	normal.content_margin_right = Margin.ma_4

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = base_color.lightened(0.12)

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = base_color.darkened(0.08)

	run_button.add_theme_stylebox_override("normal", normal)
	run_button.add_theme_stylebox_override("hover", hover)
	run_button.add_theme_stylebox_override("pressed", pressed)
	pass


func make_play_icon(size: int, color: Color) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var left: int = int(size * 0.25)
	var right: int = int(size * 0.92)
	var top: int = int(size * 0.18)
	var bottom: int = int(size * 0.82)
	var mid_y: int = (top + bottom) / 2
	for y in range(top, bottom + 1):
		var x_max: int
		if y <= mid_y:
			x_max = left + int(float(right - left) * float(y - top) / float(mid_y - top))
		else:
			x_max = left + int(float(right - left) * float(bottom - y) / float(bottom - mid_y))
		for x in range(left, x_max + 1):
			img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


func make_stop_icon(size: int, color: Color) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var margin: int = int(size * 0.22)
	for y in range(margin, size - margin):
		for x in range(margin, size - margin):
			img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)
# ----------------------------------------------------------------------------------------------------------------------
