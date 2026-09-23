extends Control

## Agent main app — multi-session chat UI.

@onready var toolbar_panel: PanelContainer = $Root/Toolbar
@onready var toolbar_title: Label = $Root/Toolbar/ToolbarRow/Title
@onready var sidebar_panel: PanelContainer = $Root/Body/Sidebar
@onready var chat_area_panel: Panel = $Root/Body/ChatArea
@onready var pinned_header: Label = $Root/Body/Sidebar/SidebarVBox/SessionListScroll/SessionList/PinnedHeader
@onready var pinned_list: VBoxContainer = $Root/Body/Sidebar/SidebarVBox/SessionListScroll/SessionList/PinnedList
@onready var pinned_separator: HSeparator = $Root/Body/Sidebar/SidebarVBox/SessionListScroll/SessionList/PinnedSeparator
@onready var normal_header: Label = $Root/Body/Sidebar/SidebarVBox/SessionListScroll/SessionList/NormalHeader
@onready var normal_list: VBoxContainer = $Root/Body/Sidebar/SidebarVBox/SessionListScroll/SessionList/NormalList
@onready var new_session_button: Button = $Root/Body/Sidebar/SidebarVBox/NewSessionButton
@onready var chat_scroll: ScrollContainer = $Root/Body/ChatArea/ChatScroll
@onready var chat_host: MarginContainer = $Root/Body/ChatArea/ChatScroll/ChatMargin
@onready var token_usage_wrap: PanelContainer = $Root/Toolbar/ToolbarRow/TokenUsageWrap
@onready var jarvis_toggle_button: Button = $Root/Toolbar/ToolbarRow/JarvisToggleWrap/JarvisToggleButton
@onready var agent_prompt_toggle_button: Button = $Root/Toolbar/ToolbarRow/AgentPromptToggleWrap/AgentPromptToggleButton
@onready var skill_toggle_button: Button = $Root/Toolbar/ToolbarRow/SkillToggleWrap/SkillToggleButton
@onready var markdown_toggle_button: Button = $Root/Toolbar/ToolbarRow/MarkdownToggleWrap/MarkdownToggleButton
@onready var input_bar: Control = $Root/Body/ChatArea/InputBar
@onready var input_wrap: PanelContainer = $Root/Body/ChatArea/InputBar/InputWrap
@onready var input_inner: Control = $Root/Body/ChatArea/InputBar/InputWrap/InputInner
@onready var input_field: TextEdit = $Root/Body/ChatArea/InputBar/InputWrap/InputInner/InputField
@onready var send_button: Button = $Root/Body/ChatArea/InputBar/InputWrap/InputInner/SendButton
@onready var project_button: Button = $Root/Toolbar/ToolbarRow/ProjectButton
@onready var log_button: Button = $Root/Toolbar/ToolbarRow/LogButtonWrap/LogButton
@onready var theme_color_select: Button = $Root/Toolbar/ToolbarRow/ThemeColorSelectWrap/ThemeColorSelect
@onready var theme_toggle_button: Button = $Root/Toolbar/ToolbarRow/ThemeToggleWrap/ThemeToggleButton
@onready var agent_setting_button: Button = $Root/Toolbar/ToolbarRow/AgentSettingWrap/AgentSettingButton
@onready var workspace_dialog: FileDialog = $WorkspaceDialog

var toolbar: AgentToolbar = AgentToolbar.new()
var workspace_button: WorkspaceButton = WorkspaceButton.new()
var log_button_ctrl: LogButton = LogButton.new()
var chat_input: AgentChatInput = AgentChatInput.new()
var theme_toggle: ThemeToggle = ThemeToggle.new()
var theme_color_select_ctrl: ThemeColorSelect = ThemeColorSelect.new()
var jarvis_toggle: JarvisToggle = JarvisToggle.new()
var skill_toggle: SkillToggle = SkillToggle.new()
var agent_prompt_toggle: AgentPromptToggle = AgentPromptToggle.new()
var token_usage_display: TokenUsageDisplay = TokenUsageDisplay.new()
var markdown_toggle: MarkdownToggle = MarkdownToggle.new()
var agent_setting: AgentSetting = AgentSetting.new()
var session_sidebar: AgentSessionSidebar = AgentSessionSidebar.new()
var chat_view: AgentChatView = AgentChatView.new()
var notification: AgentNotification = AgentNotification.new()


func _ready() -> void:
	AgentColors.load_saved_theme()
	setup_chat_area()
	
	toolbar.setup(toolbar_panel, toolbar_title, project_button)
	notification.setup()
	session_sidebar.setup(pinned_header,pinned_list,pinned_separator
			,normal_header,normal_list,new_session_button,sidebar_panel)
	token_usage_display.setup(token_usage_wrap)
	jarvis_toggle.setup(jarvis_toggle_button)
	skill_toggle.setup(skill_toggle_button)
	agent_prompt_toggle.setup(agent_prompt_toggle_button)
	markdown_toggle.setup(markdown_toggle_button)
	chat_view.setup(chat_scroll, chat_host)

	chat_input.setup(input_bar, input_wrap, input_inner, input_field, send_button)
	theme_color_select_ctrl.setup(theme_color_select)
	theme_toggle.setup(theme_toggle_button)
	agent_setting.setup(agent_setting_button, self)
	workspace_button.setup(project_button, workspace_dialog)
	log_button_ctrl.setup(log_button)

	# session
	session_sidebar.reload_sessions()
	pass


## Chat region and outer shell background colors.
func setup_chat_area() -> void:
	gdf.events.theme_changed.connect(apply_theme)
	apply_theme()
	pass


func apply_theme() -> void:
	var chat_style := StyleBoxFlat.new()
	chat_style.bg_color = AgentColors.chat
	chat_style.content_margin_left = 0
	chat_style.content_margin_top = 0
	chat_style.content_margin_right = 0
	chat_style.content_margin_bottom = 0
	chat_area_panel.add_theme_stylebox_override("panel", chat_style)
	chat_area_panel.queue_redraw()
	var shell_style := StyleBoxFlat.new()
	shell_style.bg_color = AgentColors.chat
	add_theme_stylebox_override("panel", shell_style)
	pass
