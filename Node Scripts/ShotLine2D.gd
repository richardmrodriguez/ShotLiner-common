extends VBoxContainer

class_name ShotLine2DContainer

# FIXME: TODO: Make the x-position RELATIVE to the pageline's width instead of a global absolute value
	# This will enable resizing the font size, line spacing, etc. 
	# but still allow the shotlines to place themselves properly

@onready var shot_number_label: Label = $ShotNumber
@onready var screenplay_page_panel: Panel = get_parent()
@onready var begin_cap_grab_region: ColorRect = %BeginCapGrabRegion
@onready var end_cap_grab_region: ColorRect = %EndCapGrabRegion
@onready var segments_container: VBoxContainer = %SegmentsContainer

@export var color_rect_width: float = 12
@export var click_width: float = 12
@export var hover_line_width: float = 10
@export var line_width: float = 4
@export var cap_grab_region_height: float = 6
@export var cap_grab_region_vertical_position_offset: float = 6


var line_is_hovered_over: bool = false
var last_hovered_segment: ShotLineSegment2D

var shotline_segment_scene: PackedScene = preload("res://Components/ShotlineSegment2D.tscn")
var unfilmed_sections: Array = []
var shotline_length: int
var cur_pageline_label_height: float

var shotline_obj: Shotline
var cap_line_width_offset: float = 8

var begin_cap_open: bool = false
var end_cap_open: bool = false

var true_start_pos: Vector2 = Vector2(0, 0)
var true_end_pos: Vector2 = Vector2(0, 0)

signal mouse_clicked_on_shotline(shotline2D: ShotLine2DContainer, button_index: int)
signal mouse_released_on_shotline(shotline2D: ShotLine2DContainer, button_index: int)

func _init() -> void:
	visible = false

func _ready() -> void:
	if visible == false:
		visible = true
	#line_body_grab_region.mouse_filter = Control.MOUSE_FILTER_PASS
	#print( %BeginCapGrabRegion)
	#print(end_cap_grab_region)

	begin_cap_grab_region.mouse_filter = Control.MOUSE_FILTER_PASS
	end_cap_grab_region.mouse_filter = Control.MOUSE_FILTER_PASS

	if begin_cap_open:
		begin_cap_grab_region.toggle_open_endcap(true)
		pass
	if end_cap_open:
		end_cap_grab_region.toggle_open_endcap(true)
		pass

	await get_tree().process_frame
	
	align_grab_regions()
	align_shot_number_label()
	update_shot_number_label()

	var line_color: Color = Color.hex(0x2aa198)
	update_line_color(line_color)
	update_line_width(line_width)
	
	for ln in begin_cap_grab_region.get_children():
		ln.default_color = ShotLinerColors.line_color
	for ln in end_cap_grab_region.get_children():
		ln.default_color = ShotLinerColors.line_color

	#end_cap_mode = Line2D.LINE_CAP_BOX
	#begin_cap_mode = Line2D.LINE_CAP_BOX
	#line_body_grab_region.color = Color.TRANSPARENT
	begin_cap_grab_region.color = Color.TRANSPARENT
	end_cap_grab_region.color = Color.TRANSPARENT
	#line_body_grab_region.gui_input.connect(_on_line_body_gui_input)
	mouse_clicked_on_shotline.connect(EventStateManager._on_shotline_clicked)
	mouse_released_on_shotline.connect(EventStateManager._on_shotline_released)

func is_hovered_over() -> bool:
	for segment: Node in segments_container.get_children():
		if not segment is ShotLineSegment2D:
			continue
		if segment.is_hovered_over:
			return true
	return false

# ---------------- CONSTRUCT NODE ------------------------
	# TODO: Make the shotlines appear at
func construct_shotline_node(shotline: Shotline, page_container: ScreenplayPage = EventStateManager.page_node) -> void:
	
	shotline_obj = shotline
	#assert(false, str(ScreenplayDocument.get_pdfline_vector_from_uuid(shotline_obj.end_uuid)))
	var current_page_index: int = EventStateManager.cur_page_idx
	var last_mouse_x_pos: float = shotline_obj.x_position

	var cur_start_uuid: String = shotline_obj.start_uuid
	var cur_end_uuid: String = shotline_obj.end_uuid

	var given_start_page_line_index: Vector2i = ScreenplayDocument.get_pdfline_vector_from_uuid(cur_start_uuid)
	var given_end_page_line_index: Vector2i = ScreenplayDocument.get_pdfline_vector_from_uuid(cur_end_uuid)

	var starts_on_earlier_page: bool = shotline_obj.starts_on_earlier_page(current_page_index)
	var ends_on_later_page: bool = shotline_obj.ends_on_later_page(current_page_index)

	var pageline_start: Label
	var pageline_end: Label

	var pageline_real_start_idx: int
	var pageline_real_end_idx: int
	
	var cur_pagelines: Array[PageLineLabel] = []
	for pageline: Node in EventStateManager.page_node.page_container.get_children():
		if not pageline is PageLineLabel:
			continue
		cur_pagelines.append(pageline)

	var local_end_label: PageLineLabel
	var local_start_label: PageLineLabel
	# FIXME: This whole nasty if else block needs to be really debugged...

	
	var debug_pdfline_str: String = ScreenplayDocument.get_pdfline_from_uuid(cur_end_uuid).GetLineString().substr(0, 10)
	#print("end_fnline_uuid: ", cur_end_uuid, " | ", debug_fnline_str)
	if not (starts_on_earlier_page or ends_on_later_page):
		
		for pageline: PageLineLabel in cur_pagelines:
			if pageline.get_uuid() == cur_start_uuid:
				
				pageline_start = pageline
				pageline_real_start_idx = ScreenplayDocument.get_pdfline_vector_from_uuid(pageline.pdfline.LineUUID).y
				#print("start line: ", spl.fnline.fn_type, " | ", spl.text, )
			if pageline.get_uuid() == cur_end_uuid:
				pageline_end = pageline
				pageline_real_end_idx = ScreenplayDocument.get_pdfline_vector_from_uuid(pageline.pdfline.LineUUID).y
		print_debug("Single page shotline")
		if pageline_real_start_idx > pageline_real_end_idx:
			local_start_label = pageline_end
			local_end_label = pageline_start
		else:
			local_end_label = pageline_end
			local_start_label = pageline_start
	
	elif starts_on_earlier_page and ends_on_later_page:
		
		print_debug("Start earlier and ends later")
		local_start_label = cur_pagelines.front()
		local_end_label = cur_pagelines.back()

	elif starts_on_earlier_page:
		print_debug("Starts on previous page")
		local_start_label = cur_pagelines.front()
		for pageline: PageLineLabel in cur_pagelines:
			if given_start_page_line_index.x < given_end_page_line_index.x:
				if pageline.pdfline.LineUUID == cur_end_uuid:
					local_end_label = pageline
			else:
				if pageline.pdfline.LineUUID == cur_start_uuid:
					local_end_label = pageline
				
	elif ends_on_later_page:
		print_debug("Ends on later page")
		local_end_label = cur_pagelines.back()
		for pageline: PageLineLabel in cur_pagelines:
			if given_start_page_line_index.x < given_end_page_line_index.x:
				if pageline.pdfline.LineUUID == cur_start_uuid:
					local_start_label = pageline
					#var local_idx: Vector2 = ScreenplayDocument.get_pdfline_vector_from_uuid(local_end_label.get_uuid())
					#print_debug("Local end index:  ", local_idx)
					#assert(false, "Ends later block.")
			else:
				if pageline.pdfline.LineUUID == cur_end_uuid:
					local_start_label = pageline

	# ------------ SET POINTS AND POSITION FOR SHOTLINE NODE -------------------
	var screenplay_line_vertical_size: float = cur_pagelines[0].size.y

	print_debug(local_start_label, " | ", local_end_label)
	print_debug(starts_on_earlier_page, " | ", ends_on_later_page)
	#assert(local_start_label and local_end_label, "Missing start or end label")
	if not (local_start_label and local_end_label):
		return
	# TODO: I don't know why the shotlines' vertical position is off by like 3 lines,
	# But it is and so, it needs the following offsets. Must investigate further.
	# However, I do like the effect of having there being 0.5x line height of
	# overhang for the start and end;

	var half_line_height: int = roundi(shot_number_label.size.y / 2)

	var start_pos: Vector2 = Vector2(
		last_mouse_x_pos,
		local_start_label.global_position.y - (shot_number_label.size.y + half_line_height)
		)
	var end_pos: Vector2 = Vector2(
		last_mouse_x_pos,
		(local_end_label.global_position.y + local_end_label.size.y) - (shot_number_label.size.y + half_line_height)
		)

	# TODO: Bug where undoing a shotline resize does not properly update the endcaps open / closed state
	# FIXME: Creating a multipage shotline works, but resizing a single shotline to the next page doesn't...
	if starts_on_earlier_page:
		print("Shotline starts earlier")
		begin_cap_open = true
		begin_cap_grab_region.toggle_open_endcap(begin_cap_open)
	if ends_on_later_page:
		print("Shotline ends later")
		end_cap_open = true
		end_cap_grab_region.toggle_open_endcap(end_cap_open)

	true_start_pos = start_pos
	true_end_pos = end_pos
	#print("pageline end and start: ", local_end_label, " | ", local_start_label)
	
	shotline_length = absi(local_end_label.get_index() - local_start_label.get_index()) + 1 # TODO: deprecate this variable

	update_line_color(ShotLinerColors.line_color)

	cur_pageline_label_height = screenplay_line_vertical_size
	global_position = start_pos
	#print_debug(" -------------- ")
	#shotline_obj.print_segments_and_strings_with_limit()
	_populate_shotline_with_segments(
		local_start_label.get_uuid(),
		local_end_label.get_uuid(),
		cur_pageline_label_height,
		shotline,
		page_container)

func align_shot_number_label() -> void:
	var x: float = true_start_pos.x
	var y: float = true_start_pos.y
	shot_number_label.position = Vector2(
		x - (0.5 * shot_number_label.size.x),
		y - (shot_number_label.size.y + 16)
		)

func align_grab_regions() -> void:
	var line_length: float = true_end_pos.y - true_start_pos.y

	#line_body_grab_region.position = Vector2(
	#	true_start_pos.x - (0.5 * color_rect_width),
	#	true_start_pos.y
	#	)
	#line_body_grab_region.size = Vector2(
	#	color_rect_width,
	#	line_length
	#	)

	begin_cap_grab_region.position = Vector2(
		true_start_pos.x - (0.5 * color_rect_width),
		true_start_pos.y - (begin_cap_grab_region.size.y + cap_grab_region_vertical_position_offset)
		)
	begin_cap_grab_region.size = Vector2(
		color_rect_width,
		cap_grab_region_height
		)

	end_cap_grab_region.position = Vector2(
		true_start_pos.x - (0.5 * color_rect_width),
		true_end_pos.y - (begin_cap_grab_region.size.y - 0 * cap_grab_region_vertical_position_offset)
		)
	end_cap_grab_region.size = Vector2(
		color_rect_width,
		cap_grab_region_height
		)

func _populate_shotline_with_segments(
	local_start_uuid: String,
	local_end_uuid: String,
	#total_shotline_length: int,
	line_label_height: float,
	shotline_obj: Shotline,
	page_container: ScreenplayPage) -> void:
	
	#assert(segments_size == total_shotline_length, "Shotline length mismatch: " + str(segments_size) + " | " + str(total_shotline_length))

	var cur_page_idx: int = EventStateManager.cur_page_idx

	#total_shotline_length = shotline_obj.segments_filmed_or_unfilmed.keys().size()

	if not segments_container:
		for child: Node in get_children():
			if child is VBoxContainer:
				segments_container = child

	for segment: Node in segments_container.get_children():
		segments_container.remove_child(segment)
		segment.queue_free()

	
	# TODO: use the start and end vec to determine if this shotline is multipage, and if any of these
	# segments should be added to the container


	# Update the shotline_obj.segments_filmed_or_unfilmed dict

	var new_segments_pdflines: Array[PDFLineFN] = ScreenplayDocument.get_array_of_pdflines_from_start_and_end_uuids(
		local_start_uuid, local_end_uuid
		)

	var new_segments_ids: Array[String] = []
	for pdfl: PDFLineFN in new_segments_pdflines:
		new_segments_ids.append(pdfl.LineUUID)

	var old_segments: Dictionary = shotline_obj.segments_filmed_or_unfilmed.duplicate()
	shotline_obj.segments_filmed_or_unfilmed.clear()
	
	var segment_heights: Dictionary = {}

	var prev_line_y_pos: float = -1.0
	for pdfl: PDFLineFN in new_segments_pdflines:
		var cur_pageline: PageLineLabel = page_container.get_pageline_from_lineuuid(pdfl.LineUUID) # FIXME: MAKE MULTIPAGE SHOTLINES WORK AGAIN
		var cur_segment_height: float = cur_pageline.size.y
		var cur_segment_y_pos: float = cur_pageline.position.y
		if prev_line_y_pos != -1.0:
			#print("y positions: ", prev_line_y_pos, " | ", cur_segment_y_pos)
			cur_segment_height = abs(prev_line_y_pos - cur_segment_y_pos)
		
		segment_heights[pdfl.LineUUID] = cur_segment_height

		prev_line_y_pos = cur_segment_y_pos

		# --- FIXME: This block is supposed to catch previously squiggled segments, but I'm not sure that it's actually working...

		if old_segments.keys().has(pdfl.LineUUID):
			shotline_obj.segments_filmed_or_unfilmed[pdfl.LineUUID] = old_segments[pdfl.LineUUID]
			continue
		shotline_obj.segments_filmed_or_unfilmed[pdfl.LineUUID] = true

	# This for loop creates the segments and adds them to the container
	for segment_uuid: String in shotline_obj.segments_filmed_or_unfilmed:
		if not new_segments_ids.has(segment_uuid):
			continue

		var cur_pagelines: Array[PDFLineFN] = ScreenplayDocument.pages[EventStateManager.cur_page_idx].pdflines
		var segment_in_cur_page: bool = false
		for line: PDFLineFN in cur_pagelines:

			if line.LineUUID == segment_uuid:
				segment_in_cur_page = true
				break
		if not segment_in_cur_page:
			continue

		var cur_segment_height: float = segment_heights[segment_uuid] # FIXME: Pre-calculate all the heights upon DOC IMPORT instead of calculating on the fly
		
		var new_segment: ShotLineSegment2D = shotline_segment_scene.instantiate()
		segments_container.add_child(new_segment)
		new_segment.pageline_uuid = segment_uuid
		new_segment.set_straight_or_jagged(shotline_obj.segments_filmed_or_unfilmed[segment_uuid])
		new_segment.set_segment_height(cur_segment_height)

		#print_debug("segments AFTER populate with segments")
		#shotline_obj.print_segments_and_strings_with_limit()
		
# ----------------- UPDATE NODE ---------------------
func update_line_width(width: float) -> void:
	for node: Node in get_children():
		if node is ShotLineSegment2D:
			node.line.width = width

func update_line_color(color: Color) -> void:
	for node: Node in get_children():
		if node is ShotLineSegment2D:
			node.line.color = color

func update_shot_number_label() -> void:
	if shotline_obj.scene_number == null:
		print("funny null shot numbers")
		return
	var shotnumber_string: String = str(shotline_obj.scene_number) + "." + str(shotline_obj.shot_number) + "\n" + str(shotline_obj.shot_type)
	shot_number_label.text = shotnumber_string

func resize_line_width_on_hover() -> void:
	if is_hovered_over():
		update_line_width(hover_line_width)
	else:
		update_line_width(line_width)

func update_length_from_endcap_drag(
	is_dragging_from_topcap: bool,
	last_declicked_pdfline_uuid: String = "",
	old_segments: Dictionary = {}
	) -> void:

	var cur_page_idx: int = EventStateManager.cur_page_idx
	if last_declicked_pdfline_uuid == "": # FIXME: This if block is a questionable catch at best, why have this?
		assert(false, "no last declicked.")
		return
	
	# if this is the middle of a multipage shotline, 
	# don't do anything to update the vertical position ;
	# Might change this behavior in the future
	if (
		shotline_obj.starts_on_earlier_page(cur_page_idx)
		and shotline_obj.ends_on_later_page(cur_page_idx)):
		assert(false, "Undefined resizing behavior.")
		return

	# This code assumes only EITHER  the start or end endcap is being dragged
	# Therefore, only change either the start or end index, not both
	var old_start_idx: Vector2i = ScreenplayDocument.get_pdfline_vector_from_uuid(shotline_obj.start_uuid)
	var old_end_idx: Vector2i = ScreenplayDocument.get_pdfline_vector_from_uuid(shotline_obj.end_uuid)
	var last_declicked_pdfline_idx: Vector2i = ScreenplayDocument.get_pdfline_vector_from_uuid(last_declicked_pdfline_uuid)

	var above_old_start: bool = last_declicked_pdfline_idx.x < old_start_idx.x or (last_declicked_pdfline_idx.x == old_start_idx.x and last_declicked_pdfline_idx.y < old_start_idx.y)
	var below_old_end: bool = last_declicked_pdfline_idx.x > old_end_idx.x or (last_declicked_pdfline_idx.x == old_end_idx.x and last_declicked_pdfline_idx.y > old_end_idx.y)
	
	# resize from top of line
	if is_dragging_from_topcap:
		if below_old_end:
			shotline_obj.start_uuid = shotline_obj.end_uuid
			shotline_obj.end_uuid = last_declicked_pdfline_uuid
		else:
			shotline_obj.start_uuid = last_declicked_pdfline_uuid
	# resize from bottom of line
	else:
		if above_old_start:
			shotline_obj.end_uuid = shotline_obj.start_uuid
			shotline_obj.start_uuid = last_declicked_pdfline_uuid
		else:
			shotline_obj.end_uuid = last_declicked_pdfline_uuid
	
	# If the new shotline positions don't include this page, just delete this shotline node
	var new_start_later: bool = shotline_obj.starts_on_later_page(cur_page_idx)
	var new_start_earlier: bool = shotline_obj.starts_on_earlier_page(cur_page_idx)
	var new_end_later: bool = shotline_obj.ends_on_later_page(cur_page_idx)
	var new_end_earlier: bool = shotline_obj.ends_on_earlier_page(cur_page_idx)
	print(new_start_earlier, new_start_later, new_end_earlier, new_end_later)
	if (new_start_earlier and new_end_earlier) or (new_start_later and new_end_later):
			print_debug("Shotline not on page, removing....")
			queue_free()
			return
	#var new_start_idx: Vector2 = ScreenplayDocument.get_pdfline_vector_from_uuid(shotline_obj.start_uuid)
	#var new_end_idx: Vector2 = ScreenplayDocument.get_pdfline_vector_from_uuid(shotline_obj.end_uuid)
	#assert(false, str(new_start_idx) + " | " + str(new_end_idx))
	# Finally, the new shotline positions do include somewhere on this page, reconstruct
	if old_segments != {}:
		shotline_obj.segments_filmed_or_unfilmed = old_segments
	construct_shotline_node(shotline_obj, EventStateManager.page_node)

# ------------- SIGNAL CALLBACKS ----------------------

# -------------LOCAL INPUT ------------------

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		if is_hovered_over():
				EventStateManager.last_hovered_shotline_node = self

	if event.is_action("TouchDown", true):
		if is_hovered_over():
			if event.pressed:
				mouse_clicked_on_shotline.emit(self, event.button_index)
			else:
				mouse_released_on_shotline.emit(self, event.button_index)
