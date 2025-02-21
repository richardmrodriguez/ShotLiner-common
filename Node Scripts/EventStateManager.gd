extends Node

const FIELD_CATEGORY = TextInputField.FIELD_CATEGORY
const uuid_util = preload("res://addons/uuid/uuid.gd")

var line_hover_width: float

enum TOOL {
	MOVE,
	SELECT,
	DRAW,
	DRAW_SQUIGGLE,
	ERASE,
}
# ------ NODES -------
@onready var page_node: ScreenplayPage
@onready var inpsector_panel_node: InspectorPanel
@onready var toolbar_node: ToolBar
@onready var editor_view: Node
@onready var selection_box_rect: ColorRect = ColorRect.new()
@onready var toolbar_page_num_field: Node
@onready var shotline_context_menu: PopupMenu = PopupMenu.new()

# ------ STATES ------
var is_drawing: bool = false
var is_erasing: bool = false
var is_inverting_line: bool = false
var is_resizing_shotline: bool = false

var is_dragging_shotline: bool = false

var cur_tool: TOOL = TOOL.DRAW
var buffered_tool: TOOL

var cur_highlighted_pageline_uuids: Array[String] = []
var cur_already_marked_shotline_segments: Dictionary
var cur_segment_change_cmds: Array[ToggleSegmentUnfilmedCommand]

var last_shotline_node_global_pos: Vector2

var last_mouse_click_point: Vector2
var last_mouse_release_point: Vector2
var last_mouse_drag_delta: Vector2

var last_mouse_hover_position: Vector2
var last_mouse_click_above_top_margin: bool = false
var last_mouse_click_below_bottom_margin: bool = false
var last_mouse_click_past_right_margin: bool = false
var last_mouse_click_past_left_margin: bool = false

var last_hovered_line_uuid: String = ""
var last_clicked_line_uuid: String = ""
var last_declicked_line_uuid: String = ""

var last_hovered_shotline_node: ShotLine2DContainer
var last_valid_shotline_position: Vector2

var cur_mouse_global_position_delta: Vector2
var cur_selected_shotline: Shotline
var cur_selected_shotline_container: ShotLine2DContainer
var cur_selected_shotline_endcap: EndcapGrabRegion

# ------ SHOTLINE STATUS ------
var last_selected_scene_num_nominal: String = ""
var last_shot_number: int = 1

# ------ PAGE STATUS ------

var cur_page_idx: int = 0

# ------ SIGNALS ----------

signal page_changed

# ------ READY ------

func _ready() -> void:
	selection_box_rect.color = Color(0.4, 0.4, 0.4, 0.4)

	shotline_context_menu.transient = true
	shotline_context_menu.set_unparent_when_invisible(true)
	for string: String in Array([
		"XWS",
		"WS",
		"MWS",
		"MS",
		"MCU",
		"CU",
		"XCU",
		]):
		shotline_context_menu.add_item(string)
	

# ----- UITIL FUNCS ------

# -------------------- SHOTLINE LOGIC -----------------------------------

func create_and_add_shotline_node_to_page(shotline: Shotline) -> void:
	
	var create_shotline_command: CreateShotLineCommand = CreateShotLineCommand.new([shotline])
	CommandHistory.add_command(create_shotline_command)
	cur_selected_shotline = shotline

func create_new_shotline_obj(start_uuid: String, end_uuid: String, last_mouse_pos: Vector2) -> Shotline:

	var new_shotline: Shotline = Shotline.new()

	var start_idx: Vector2i = ScreenplayDocument.get_pdfline_vector_from_uuid(start_uuid)
	var end_idx: Vector2i = ScreenplayDocument.get_pdfline_vector_from_uuid(end_uuid)

	
	#assert(false, "start and end of current shotline: " + str(start_idx) + " | " + str(end_idx))

	assert(start_idx.x != -1, "Start line page index for shotline does not exist.")
	assert(end_idx.x != -1, "End line page index for shotline does not exist.")

	new_shotline.shotline_uuid = uuid_util.v4()
	
	if start_idx.x < end_idx.x:
	#	new_shotline.start_page_index = start_line_page_idx
	#	new_shotline.end_page_index = end_line_page_idx
		new_shotline.start_uuid = start_uuid
		new_shotline.end_uuid = end_uuid
	else:
	#	new_shotline.start_page_index = end_line_page_idx
	#	new_shotline.end_page_index = start_line_page_idx
		new_shotline.start_uuid = end_uuid
		new_shotline.end_uuid = start_uuid

	# NOTE: The above block always assigns something, but really it shouldn't assign anything
	# right now, the following block relies on the previous block assigning something

	# The right thing to to is fix both blocks... but it seems tricky.... idk lmao
	if start_idx.x == end_idx.x:
		var old_start_uuid: String = new_shotline.start_uuid
		var old_end_uuid: String = new_shotline.end_uuid

		var old_start_idx: Vector2i = ScreenplayDocument.get_pdfline_vector_from_uuid(old_start_uuid)
		var old_end_idx: Vector2i = ScreenplayDocument.get_pdfline_vector_from_uuid(old_end_uuid)
		if old_start_idx.y > old_end_idx.y:
			print("rearranged!!!!!!!!!!!!!!!!!")
			new_shotline.start_uuid = old_end_uuid
			new_shotline.end_uuid = old_start_uuid
	new_shotline.x_position = last_mouse_pos.x

	print("Start and end page indices: ", new_shotline.get_start_idx(), " | ", new_shotline.get_end_idx())

	# pre-populate the shotline.segments_filmed_or_unfilmed Dict with default values of true

	var pdflines_in_range: Array[PDFLineFN] = ScreenplayDocument.get_array_of_pdflines_from_start_and_end_uuids(new_shotline.start_uuid, new_shotline.end_uuid)

	for fnl: PDFLineFN in pdflines_in_range:
		new_shotline.segments_filmed_or_unfilmed[fnl.LineUUID] = true
	
	return new_shotline

#
#
# -------------------- SIGNAL HANDLING -----------------------------
#
#

func _on_tool_changed() -> void:
	pass

func _on_tool_bar_toolbar_button_pressed(toolbar_button: int) -> void:
	await get_tree().process_frame
	match toolbar_button:
		toolbar_node.TOOLBAR_BUTTON.NEXT_PAGE:
			var next_page_idx: int = cur_page_idx + 1
			var page_nav_command: PageNavigateCommand = PageNavigateCommand.new(
				[next_page_idx,
				cur_page_idx
				])
			CommandHistory.add_command(page_nav_command)
			page_changed.emit()

		toolbar_node.TOOLBAR_BUTTON.PREV_PAGE:
			var prev_page_idx: int = cur_page_idx - 1
			var page_nav_command: PageNavigateCommand = PageNavigateCommand.new(
				[prev_page_idx,
				cur_page_idx
				])
			CommandHistory.add_command(page_nav_command)
			page_changed.emit()
		toolbar_node.TOOLBAR_BUTTON.IMPORT_PDF:
			SLFileHandler.open_file_dialog(
				FileDialog.FILE_MODE_OPEN_FILE,
				SLFileAction.FILE_ACTION.IMPORT_PDF
			)
		toolbar_node.TOOLBAR_BUTTON.SAVE_SHOTLINE_FILE:
			SLFileHandler.open_file_dialog(
				FileDialog.FILE_MODE_SAVE_FILE,
				SLFileAction.FILE_ACTION.SAVE_FILE)

		toolbar_node.TOOLBAR_BUTTON.LOAD_SHOTLINE_FILE:
			SLFileHandler.open_file_dialog(
				FileDialog.FILE_MODE_OPEN_FILE,
				SLFileAction.FILE_ACTION.LOAD_FILE
			)
		toolbar_node.TOOLBAR_BUTTON.EXPORT_SPREADSHEET:
			SLFileHandler.open_file_dialog(
				FileDialog.FILE_MODE_SAVE_FILE,
				SLFileAction.FILE_ACTION.EXPORT_CSV
			)

		# TOOL SELECTION
		toolbar_node.TOOLBAR_BUTTON.MOVE:
			cur_tool = TOOL.MOVE
		toolbar_node.TOOLBAR_BUTTON.DRAW:
			cur_tool = TOOL.DRAW
		toolbar_node.TOOLBAR_BUTTON.DRAW_SQUIGGLE:
			cur_tool = TOOL.DRAW_SQUIGGLE
		toolbar_node.TOOLBAR_BUTTON.ERASE:
			cur_tool = TOOL.ERASE

func _highlight_pageline_if_hovered(pageline_labels: Array, event_global_pos: Vector2) -> void:
	for pageline: PageLineLabel in pageline_labels:
		if not pageline is PageLineLabel:
			continue
		var y_pos: float = pageline.global_position.y
		var y_size: float = pageline.size.y
		if (y_pos <= event_global_pos.y) and ((y_pos + y_size) >= event_global_pos.y):
			pageline.label_highlight.visible = true
			var cur_child_uuid: String = pageline.get_uuid()
			if EventStateManager.last_hovered_line_uuid != cur_child_uuid:
				EventStateManager.last_hovered_line_uuid = cur_child_uuid
				#screenplay_line_hovered_over.emit(cur_child_uuid)
				#print(screenplay_line.get_index(), "   ", screenplay_line.fnline.fn_type)
		else:
			if not (is_drawing or is_inverting_line):
				pageline.label_highlight.visible = false

func _get_top_and_bottom_margins_from_current_page() -> Array[float]:
	var bottom_margin: float = 0
	var top_margin: float = 20000
	var pageline_height: float
	var height_set: bool = false
	for pll: Node in page_node.page_container.get_children():
		if not pll is PageLineLabel:
			continue
		if not height_set:
			pageline_height = pll.size.y
		if pll.global_position.y > bottom_margin:
			bottom_margin = pll.global_position.y
		if pll.global_position.y < top_margin:
			top_margin = pll.global_position.y

	return [top_margin, bottom_margin, pageline_height]


# ----------------- GLOBAL INPUTS (KEYBOARD SHORTCUTS) ----------------
func _unhandled_input(event: InputEvent) -> void:

	if event.is_action_pressed("Save", false, true):
		SLFileHandler.open_file_dialog(
			FileDialog.FILE_MODE_SAVE_FILE,
			SLFileAction.FILE_ACTION.SAVE_FILE)
	
	if event.is_action_pressed("ImportPDF", false, true):
		SLFileHandler.open_file_dialog(
			FileDialog.FILE_MODE_OPEN_FILE,
			SLFileAction.FILE_ACTION.IMPORT_PDF
		)

	if event.is_action_pressed("Open", false, true):
		SLFileHandler.open_file_dialog(
			FileDialog.FILE_MODE_OPEN_FILE,
			SLFileAction.FILE_ACTION.LOAD_FILE
		)
	if event.is_action_pressed("ExportCSV", false, true):
		SLFileHandler.open_file_dialog(
			FileDialog.FILE_MODE_SAVE_FILE,
			SLFileAction.FILE_ACTION.EXPORT_CSV
		)

	if event.is_action_pressed("ui_undo", false, true):
		CommandHistory.undo()
	elif event.is_action_pressed("ui_redo", false, true):
		CommandHistory.redo()

# --------------- SCREENPLAY PAGE INPUTS --------------------
func _on_screenplay_page_gui_input(event: InputEvent) -> void:
	
	var top_bottom_plh: Array[float] = _get_top_and_bottom_margins_from_current_page()
	var top_margin: float = top_bottom_plh[0]
	var bottom_margin: float = top_bottom_plh[1]
	var pageline_height: float = top_bottom_plh[2]
	
	# --- handle touch input positions ---
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if not event.is_pressed():
			last_mouse_click_above_top_margin = event.position.y < top_margin
			last_mouse_click_below_bottom_margin = event.position.y > bottom_margin + pageline_height


	if event.is_action("TouchDown", true):
		_handle_pointer_touch(event)
	if event.is_action("TouchContext", true):
		_handle_pointer_touch_context(event)
	if event.is_action("DrawInvert", true):
		_handle_draw_inverted(event)

	if event is InputEventMouseMotion:
		var pageline_labels: Array = page_node.page_container.get_children().filter(
			func(child: Node) -> bool:
				return child is PageLineLabel
		)
		var cur_global_mouse_pos: Vector2 = editor_view.get_global_mouse_position()

		# highlight a pageline if the mouse is hovering over it
		# TODO: If is_drawing, this should highlight the labels between the currently hovered pageline and the
		# Last clicked pageline, and de-highlight any lines that aren't in that range
		
		_highlight_pageline_if_hovered(pageline_labels, event.global_position)

		#Highlight the margins if mouse is over a margin rect
		if is_drawing:
			if page_node.top_page_margin and page_node.bottom_page_margin and page_node.left_page_margin and page_node.right_page_margin:
				if page_node.top_page_margin.get_global_rect().has_point(cur_global_mouse_pos):
					if cur_page_idx == 0:
						page_node.top_page_margin.color = Color.DARK_RED
					else:
						page_node.top_page_margin.color = ShotLinerColors.content_color
				else:
					page_node.top_page_margin.color = Color.TRANSPARENT
				if page_node.bottom_page_margin.get_global_rect().has_point(cur_global_mouse_pos):
					if cur_page_idx == ScreenplayDocument.pages.size() - 1:
						page_node.bottom_page_margin.color = Color.DARK_RED
					else:
						page_node.bottom_page_margin.color = ShotLinerColors.content_color
				else:
					page_node.bottom_page_margin.color = Color.TRANSPARENT

		if is_inverting_line:
			if is_instance_valid(last_hovered_shotline_node):
				for segment: ShotLineSegment2D in last_hovered_shotline_node.segments_container.get_children():
					if not ShotLineSegment2D:
						continue
					var cur_segment_uuid: String = segment.pageline_uuid
					var cur_shotline_ref: Shotline = last_hovered_shotline_node.shotline_obj
					var dbg_pageline_str_for_segment: String = ScreenplayDocument.get_pdfline_from_uuid(cur_segment_uuid).GetLineString().substr(0, 10)
					if not cur_shotline_ref.segments_filmed_or_unfilmed.keys().has(cur_segment_uuid):
						print_debug("Current Shotline segments: ", cur_shotline_ref.segments_filmed_or_unfilmed)
						print_debug("Attempted segment to get: ", segment.pageline_uuid, " | ", dbg_pageline_str_for_segment)
						continue
					
					var cur_segment_state: bool = cur_shotline_ref.segments_filmed_or_unfilmed[segment.pageline_uuid]
					var cur_shotline_uuid: String = last_hovered_shotline_node.shotline_obj.shotline_uuid
					
					if cur_already_marked_shotline_segments.keys().has(
						last_hovered_shotline_node.shotline_obj.shotline_uuid
						):
						if cur_already_marked_shotline_segments[cur_shotline_uuid].has(
							segment.pageline_uuid
							):
							continue
					
					if segment.is_hovered_over:
						# Store the current state of the segments before modifying them
						cur_already_marked_shotline_segments[cur_shotline_uuid] = {
							segment.pageline_uuid: cur_segment_state
						}
						
						var toggle_segment_cmd: ToggleSegmentUnfilmedCommand = ToggleSegmentUnfilmedCommand.new([segment])
						toggle_segment_cmd.execute()
						cur_segment_change_cmds.append(toggle_segment_cmd)
				if page_node.page_panel.get_children().has(selection_box_rect):
					selection_box_rect.size = page_node.get_global_mouse_position() - selection_box_rect.global_position

		match cur_tool:
			# Handle dragging shotlines
			TOOL.MOVE:
				if is_dragging_shotline:
					var new_x_pos: float = (
						cur_mouse_global_position_delta.x
						+ editor_view.get_global_mouse_position().x
					)
					cur_selected_shotline.shotline_node.global_position = Vector2(
						new_x_pos,
						last_shotline_node_global_pos.y
					)
					# TODO: This func block which handles highlighting filmed/unfilmed pagelines per the current selected shotline
					# BUT This seems to just not fucking work at all on a page that isn't the first page...????
					if cur_selected_shotline:
						#print(cur_selected_shotline.segments_filmed_or_unfilmed)
						for pageline_uuid: String in cur_selected_shotline.segments_filmed_or_unfilmed.keys():
							for pageline in page_node.page_container.get_children():
								if not pageline is PageLineLabel:
									continue

								if pageline.get_uuid() == pageline_uuid:
									#print("Pageline Label Highlight: ", pageline.label_highlight)
									if cur_selected_shotline.segments_filmed_or_unfilmed[pageline_uuid] == true:
										pageline.label_highlight.visible = true
									else:
										pageline.label_highlight.visible = false
								#print("This didn't match: ", pageline.fnline.uuid, " | ", pageline_uuid)

func _handle_draw_inverted(event: InputEvent) -> void:
	if event.is_pressed():
		match cur_tool:
			TOOL.DRAW:
				if not is_inverting_line:
					is_inverting_line = true
					selection_box_rect.global_position = page_node.get_global_mouse_position()
					selection_box_rect.size = Vector2(100, 100)
	if event.is_released():
		match cur_tool:
			TOOL.DRAW:
				if is_inverting_line:
					is_inverting_line = false
					var bulk_segments_cmd := BulkSegmentsChangedCommand.new(
						[
							cur_segment_change_cmds.duplicate(true),
							cur_already_marked_shotline_segments.duplicate(true)
						]
					)
					CommandHistory.add_command(bulk_segments_cmd)

					cur_already_marked_shotline_segments.clear()
					cur_segment_change_cmds.clear()
	print("Is inverting_line: ", is_inverting_line)


func _handle_pointer_touch_context(event: InputEvent) -> void:
	pass # TODO: handle right clicks
	# When right-clicking:
		# Get the UI element that was right clicked
		# handle each case in a long match case or if-else block

# TODO: make these "left_click" and "right_click" funcs more abstract
func _handle_pointer_touch(event: InputEvent) -> void:
	var pages: Array[PageContent] = ScreenplayDocument.pages
	if event.is_action_pressed("TouchDown", false, true):
		last_mouse_click_point = event.position
		match cur_tool:
			TOOL.DRAW:
				#print("imma clicking")
				if not is_drawing:
					is_drawing = true
					last_mouse_hover_position = event.position
					last_clicked_line_uuid = last_hovered_line_uuid
					#print("last hovered line: ", last_hovered_line_uuid)
					#print(event.position)
	if event.is_action_released("TouchDown", true):
		last_mouse_release_point = event.position
		last_mouse_drag_delta = last_mouse_release_point - last_mouse_click_point
		match cur_tool:
			TOOL.DRAW:
				if not is_drawing:
					return
				is_drawing = false
				
				if (not last_clicked_line_uuid) or (not last_hovered_line_uuid):
					return

				var new_shotline: Shotline
				

				if not (last_mouse_click_below_bottom_margin or last_mouse_click_above_top_margin):
					new_shotline = create_new_shotline_obj(
						last_clicked_line_uuid,
						last_hovered_line_uuid,
						event.position)
					
				elif last_mouse_click_above_top_margin:
					#assert(false, "Mouse above top?.")
					# click released past top or bottom margin
					# give the add_new_shotline the last line of prev page or first line of next page

					var start_uuid: String
					if cur_page_idx - 1 >= 0:
						start_uuid = pages[cur_page_idx - 1].pdflines.back().LineUUID
					else:
						start_uuid = pages[cur_page_idx].pdflines.front().LineUUID
					new_shotline = create_new_shotline_obj(start_uuid, last_hovered_line_uuid, event.position)
				elif last_mouse_click_below_bottom_margin:
					#assert(false, "Mouse below bottom?")
					var end_uuid: String
					if cur_page_idx + 1 < pages.size():
						end_uuid = pages[cur_page_idx + 1].pdflines.front().LineUUID
					else:
						end_uuid = pages[cur_page_idx].pdflines.back().LineUUID
					new_shotline = create_new_shotline_obj(
						last_clicked_line_uuid,
						end_uuid,
						event.position)

					#print("Clicked and hovered: ", last_clicked_line_idx, ",   ", last_hovered_line_idx)
				create_and_add_shotline_node_to_page(new_shotline)
								
			TOOL.MOVE:
				if is_resizing_shotline:
					is_resizing_shotline = false
					# FIXME: This is bad, because the resize shotline command reaches out to get the last_declicked line
					# when instead we should just pass this variable to the resize command
					if (not last_mouse_click_above_top_margin) and (not last_mouse_click_below_bottom_margin):
						last_declicked_line_uuid = last_hovered_line_uuid
					elif last_mouse_click_above_top_margin:
						if cur_page_idx > 0:
							var prev_page_lines := ScreenplayDocument.pages[cur_page_idx - 1].pdflines
							last_declicked_line_uuid = prev_page_lines.back().LineUUID
							assert(prev_page_lines.back().LineUUID, "Couldn't get last line of previous page.")
						else:
							last_declicked_line_uuid = ScreenplayDocument.pages[cur_page_idx].pdflines.front().LineUUID
					elif last_mouse_click_below_bottom_margin:
						if cur_page_idx < ScreenplayDocument.pages.size():
							var next_page_lines := ScreenplayDocument.pages[cur_page_idx + 1].pdflines
							last_declicked_line_uuid = next_page_lines.front().LineUUID
						else:
							last_declicked_line_uuid = ScreenplayDocument.pages[cur_page_idx].pdflines.back().LineUUID


					var resize_shotline_cmd: ResizeShotlineCommand = ResizeShotlineCommand.new(
						[
							cur_selected_shotline_endcap.is_begin_cap,
							cur_selected_shotline,
							last_declicked_line_uuid
						]
					)
					CommandHistory.add_command(resize_shotline_cmd)

func _on_new_shotline_added(shotline_struct: Shotline) -> void:
	inpsector_panel_node.scene_num.line_edit.grab_focus()
	inpsector_panel_node.populate_fields_from_shotline(shotline_struct)
	cur_selected_shotline = shotline_struct

# ------------------------ INSPECTOR PANEL -------------------------
func _on_inspector_panel_field_text_changed(new_text: String, field_category: TextInputField.FIELD_CATEGORY) -> void:
	if (not is_instance_valid(cur_selected_shotline)) or ScreenplayDocument.shotlines == [] or (not cur_selected_shotline.shotline_node):
		return
	await get_tree().process_frame
	match field_category:
		FIELD_CATEGORY.SCENE_NUM:
			cur_selected_shotline.scene_number = new_text
		FIELD_CATEGORY.SHOT_NUM:
			cur_selected_shotline.shot_number = new_text
		FIELD_CATEGORY.SHOT_TYPE:
			cur_selected_shotline.shot_type = new_text
		FIELD_CATEGORY.SHOT_SUBTYPE:
			cur_selected_shotline.shot_subtype = new_text
		FIELD_CATEGORY.SETUP_NUM:
			cur_selected_shotline.setup_number = new_text
		FIELD_CATEGORY.GROUP:
			cur_selected_shotline.group = new_text
		FIELD_CATEGORY.TAGS:
			cur_selected_shotline.tags = new_text
	cur_selected_shotline.shotline_node.update_shot_number_label()

func _on_shotline_clicked(shotline_node: ShotLine2DContainer, button_index: int) -> void:
	match cur_tool:
		TOOL.MOVE:
	
			inpsector_panel_node.populate_fields_from_shotline(shotline_node.shotline_obj)
			cur_selected_shotline = shotline_node.shotline_obj
			is_dragging_shotline = true
			cur_mouse_global_position_delta = shotline_node.global_position - editor_view.get_global_mouse_position()
			last_shotline_node_global_pos = shotline_node.global_position
			print(is_dragging_shotline)

# TODO: simulate a mouse button release whenever the mouse leaves the window

func _on_shotline_released(shotline_node: ShotLine2DContainer, button_index: int) -> void:
	print("shotline released!!!")
	match cur_tool:
		TOOL.MOVE:
			if button_index != 1:
				return
			if shotline_node.shotline_obj == cur_selected_shotline:
				if is_dragging_shotline:
					
					is_dragging_shotline = false
					
					var move_shotline_cmd := MoveShotLineCommand.new(
						[
							cur_selected_shotline,
							editor_view.get_global_mouse_position().x + cur_mouse_global_position_delta.x
						]
					)
					print(CommandHistory.add_command(move_shotline_cmd))
		
		TOOL.ERASE:
			if button_index != 1:
				return
			if shotline_node == last_hovered_shotline_node:
				print("Erasing...?")
				if last_hovered_shotline_node.is_hovered_over:
					var erase_command: EraseShotLineCommand = EraseShotLineCommand.new(
						[
							shotline_node.shotline_obj,
							page_node.page_panel
						]
					)
					CommandHistory.add_command(erase_command)

func _on_shotline_hovered_over(shotline_container: ShotLine2DContainer) -> void:
	last_hovered_shotline_node = shotline_container

func _on_shotline_endcap_clicked(
	shotline_endcap: EndcapGrabRegion,
	shotline_container: ShotLine2DContainer,
	button_index: int) -> void:
	if cur_tool == TOOL.MOVE:
		if not is_resizing_shotline:
			print("Resizing...")
			is_resizing_shotline = true
			cur_selected_shotline = shotline_container.shotline_obj
			cur_selected_shotline_container = shotline_container
			cur_selected_shotline_endcap = shotline_endcap

func _on_shotline_endcap_released(
	shotline_endcap: EndcapGrabRegion,
	shotline_container: ShotLine2DContainer,
	button_index: int) -> void:
	if cur_tool == TOOL.MOVE:
		pass

func _on_page_lines_populated() -> void:
	pass
	#page_node.populate_page_panel_with_shotlines_for_page()

func _on_page_num_field_entered(text: String) -> void:
	pass # TODO: support entering the page number, catch false entries, and especially support nominal page numbers

func _on_file_dialog_cancelled(fd: FileDialog) -> void:
	fd.queue_free()

func _on_file_dialog_file_selected(path: String, sl_fileaction: SLFileAction.FILE_ACTION, fd: FileDialog) -> void:
	match sl_fileaction:
		SLFileAction.FILE_ACTION.SAVE_FILE:
			if not path.ends_with(".sl"):
				path = path + ".sl"
			if SLFileHandler.save_file(path):
				print("Saved to: ", path)
		SLFileAction.FILE_ACTION.EXPORT_CSV:
			if SLFileHandler.export_to_csv(path):
				print("Exported")
		SLFileAction.FILE_ACTION.LOAD_FILE:
			if SLFileHandler.load_file(path):
				print("Loaded....")
		SLFileAction.FILE_ACTION.IMPORT_PDF:
			if SLFileHandler.import_pdf(path):
				print_debug("PDF Imported...")
				pass

	fd.queue_free()
