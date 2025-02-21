extends Control

@onready var toolbar: Node = %ToolBar
@onready var screenplay_page: Node = %ScreenplayPage
@onready var inspector_panel: Node = %InspectorPanel
@onready var page_panel: Node = screenplay_page.page_panel
@onready var page_container: Node = screenplay_page.page_container
@onready var vbox: Node = %VBoxContainer
@onready var background_color_rect: ColorRect = % "Background Color"

signal created_new_shotline(shotline_struct: Shotline)
signal tool_changed

# --------------- READY ------------------------------

func _init() -> void:
	pass

func _ready() -> void:
	EventStateManager.editor_view = self
	DisplayServer.window_set_min_size(Vector2(920, 920))

	# ------------ set colors ------------------
	background_color_rect.color = ShotLinerColors.background_color
	screenplay_page.background_color_rect.color = ShotLinerColors.foreground_color

	# -------------connecting signals-----------
	created_new_shotline.connect(EventStateManager._on_new_shotline_added)
	tool_changed.connect(EventStateManager._on_tool_changed)
	
	screenplay_page.page_lines_populated.connect(EventStateManager._on_page_lines_populated)
	screenplay_page.gui_input.connect(EventStateManager._on_screenplay_page_gui_input)
	
	inspector_panel.field_text_changed.connect(EventStateManager._on_inspector_panel_field_text_changed)
	
	toolbar.toolbar_button_pressed.connect(EventStateManager._on_tool_bar_toolbar_button_pressed)
	#toolbar.layout_test_pressed.connect(EventStateManager._on_layout_change)
