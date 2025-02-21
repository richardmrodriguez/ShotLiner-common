extends Command

class_name CreateShotLineCommand

var shotline_obj: Shotline
var shotline_uuid: String
var this_shotline_2D: ShotLine2DContainer
var page_panel: Node
var y_drag_delta: float
var prev_global_scene_num_nominal: String
var prev_highest_shot_number: String
var scene_for_shotline: ScreenplayScene
var shot_chooser_popup_menu: PopupMenu

func _init(_params: Array) -> void:
	shotline_obj = _params.front()
	page_panel = EventStateManager.page_node.page_panel
	shotline_uuid = shotline_obj.shotline_uuid
	prev_global_scene_num_nominal = EventStateManager.last_selected_scene_num_nominal
	#shotline_uuid = params.front().shotline_uuid
	scene_for_shotline = ScreenplayDocument.get_scene_from_global_line_idx(shotline_obj.get_start_idx())
	if scene_for_shotline:
		prev_highest_shot_number = scene_for_shotline.get_highest_shot_number_for_scene()
	
	shot_chooser_popup_menu = EventStateManager.shotline_context_menu

func execute() -> bool:
		
	# two steps:
	# 1. Add shotline object to shotlines array
	# 2. Add Shotline container to current page
	if not ScreenplayDocument.shotlines.has(shotline_obj):
		ScreenplayDocument.shotlines.append(shotline_obj)
	
	this_shotline_2D = shotline_obj.shotline_2D_scene.instantiate()
	page_panel.add_child(this_shotline_2D)
	this_shotline_2D.construct_shotline_node(shotline_obj)
	shotline_obj.shotline_node = this_shotline_2D
	EventStateManager.cur_selected_shotline = shotline_obj

	# TODO: create a func in ScreenplayScene to get the current amount of shotlines that start
	# In a particular scene,
	# and especially the highest shot number of those shotlines
	if scene_for_shotline:
		EventStateManager.last_selected_scene_num_nominal = scene_for_shotline.scene_num_nominal
		shotline_obj.scene_number = EventStateManager.last_selected_scene_num_nominal
			
		var highest_shot_num: int = int(prev_highest_shot_number)
		shotline_obj.shot_number = str((highest_shot_num + 1))
	else:
		shotline_obj.shot_number = str(1)
	EventStateManager.inpsector_panel_node.populate_fields_from_shotline(shotline_obj)
	# TODO: Implement a pop-up / dropdown menu whenever a shotline is created, 
	# then the user can simply press a key (probably from the number row by default),
	# to quickly choose a shot type for that shot line
	# W: XWS
	# S: WS
	# X: MLS
	# D: MS
	# R: MCU
	# F: CU
	# V: XCU
	
	if not shotline_obj.initalized:
		var panel_shot_type: TextInputField = EventStateManager.inpsector_panel_node.shot_type

		if not shot_chooser_popup_menu.get_parent():
			EventStateManager.page_node.page_panel.add_child(shot_chooser_popup_menu)

		shot_chooser_popup_menu.index_pressed.connect(func(index: int) -> void:
			var new_text: String = shot_chooser_popup_menu.get_item_text(index)
			panel_shot_type.set_text(new_text)
			panel_shot_type._on_field_text_changed(new_text)
			panel_shot_type.node_next_focus.grab_field_focus()
			)
		shot_chooser_popup_menu.window_input.connect(func(event: InputEvent) -> void:
			var shot_select_input_names: Array = []
			for n: int in range(7):
				shot_select_input_names.append("ShotSelect" + str(n))
				
			for action_name: String in shot_select_input_names:
				if event.is_action(action_name, true):
					shot_chooser_popup_menu.set_focused_item(int(action_name))
			)
		shot_chooser_popup_menu.popup_on_parent(Rect2(this_shotline_2D.position + Vector2(this_shotline_2D.size.x, 0), Vector2.ZERO))
		shotline_obj.initialized = true


	return true
	
func undo() -> bool:
	

	# to undo:
	# 1. get shotline container by uuid, queue free
	# 2. remove shotline obj from array by uuid
	if ScreenplayDocument.shotlines.has(shotline_obj):
		print("removing shotline node...")

		for shotline_container: Node in page_panel.get_children():
			if not shotline_container is ShotLine2DContainer:
				continue
			if shotline_container.shotline_obj.shotline_uuid == shotline_obj.shotline_uuid:
				page_panel.remove_child(shotline_container)
				shotline_container.queue_free()
		ScreenplayDocument.shotlines.erase(shotline_obj)
		EventStateManager.inpsector_panel_node.clear_fields()
		return true
	return false
	#this_shotline_2D.queue_free()
