extends Control

class_name ScreenplayPage

@export_multiline var raw_screenplay_content: String = "INT. HOUSE - DAY"
@export var SP_ACTION_WIDTH: int = 61
@export var SP_DIALOGUE_WIDTH: int = 36
@export var SP_FONT_SIZE: int = 20
@export var font_ratio: float = 0.725

@onready var SP_CHARACTER_SPACING: float = SP_FONT_SIZE * font_ratio * 10
@onready var SP_PARENTHETICAL_SPACING: float = SP_FONT_SIZE * font_ratio * 5
@onready var page_panel: Panel = %ScreenplayPagePanel
@onready var page_container: Node = %ScreenplayPageContentVBox
@onready var left_page_margin: Node = %LeftPageMarginRegion
@onready var right_page_margin: Node = %RightPageMarginRegion
@onready var bottom_page_margin: Node = %BottomPageMarginRegion
@onready var top_page_margin: Node = %TopPageMarginRegion
@onready var background_color_rect: ColorRect = %PageBackground

const uuid_util = preload("res://addons/uuid/uuid.gd")
const page_margin_region: PackedScene = preload("res://Components/PageMarginRegion.tscn")

var current_page_number: int = 0
var shotlines_for_pages: Dictionary = {}

#signal created_new_shotline(shotline_struct: Shotline)
#signal shotline_clicked
signal page_lines_populated

# TODO - Extract Parser Logic
# - Fountain Parsing logic should be in a different file, probably an autoload

## EMPHASIS is not handled here -- asterisks need to be removed from the fountain screenplay.

# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	EventStateManager.page_node = self
	#left_page_margin.color = Color.TRANSPARENT
	#right_page_margin.color = Color.TRANSPARENT
	#top_page_margin.color = Color.TRANSPARENT
	#bottom_page_margin.color = Color.TRANSPARENT
	
func replace_current_page(page_content: PageContent, new_page_number: int = 0) -> void:
	for child in page_container.get_children():
		if child is PageLineLabel:
			page_container.remove_child(child)
	for shotline_container: Node in page_panel.get_children():
		if shotline_container is ShotLine2DContainer:
			page_panel.remove_child(shotline_container)
			shotline_container.queue_free()
	await get_tree().process_frame
	populate_page_container_with_page_lines(page_content, new_page_number)
	populate_page_panel_with_shotlines_for_page()

func populate_page_container_with_page_lines(cur_page_content: PageContent, page_number: int = 0) -> void:
	current_page_number = page_number
	var pdf_height: float = cur_page_content.page_size.y

	for pageline: PDFLineFN in cur_page_content.pdflines:
		var line_height: float = cur_page_content.dpi * (12.0 / 72.0)
		var raw_pdf_pos: Vector2 = pageline.GetLinePosition()
		var screenplay_line: PageLineLabel = construct_pdfline_label(pageline)
		page_container.add_child(screenplay_line)
		var new_pdf_pos: Vector2 = Vector2(
			raw_pdf_pos.x,
			(pdf_height - raw_pdf_pos.y) - line_height
		)
		screenplay_line.set_position(
			new_pdf_pos
		) # TODO: The positions y-coordinate will be wrong; must subtract y coord from the pageheight

		# adds a toggleable highlight to text lines
		var line_bg := ColorRect.new()
		screenplay_line.add_child(line_bg)
		line_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line_bg.color = ShotLinerColors.text_highlight_color
		line_bg.set_size(line_bg.get_parent_area_size())
		line_bg.set_size(
			Vector2(
				screenplay_line.size.x,
				(13.0 / 72.0) * cur_page_content.dpi # highlighter rect will be a little over 1 char tall
				)
			)
		line_bg.set_position(Vector2(0, 0))
		
		screenplay_line.label_highlight = line_bg

		screenplay_line.z_index = 0
		line_bg.z_index = 1
		line_bg.visible = false

		match pageline.LineElement:
			PDFScreenplayParser.ELEMENT.SCENE_HEADING:
				pass
				#screenplay_line.text = "SCENE NUMBER: " + pageline.NominalSceneNum
			#PDFScreenplayParser.ELEMENT.

	page_lines_populated.emit()

func construct_pdfline_label(pageline: PDFLineFN, line_idx: int = 0) -> Label:
	assert(pageline, "Pageline not passed through.")

	var new_label: PageLineLabel = PageLineLabel.new()
	print(typeof(pageline), " | ", pageline)
	new_label.text = pageline.GetLineString()
	new_label.pdfline = pageline
	new_label.line_index = line_idx
	new_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	new_label.add_theme_font_size_override("font_size", SP_FONT_SIZE)
	new_label.add_theme_color_override("font_color", ShotLinerColors.text_color)
	
	return new_label

func populate_page_panel_with_shotlines_for_page() -> void:
	await get_tree().process_frame
	var cur_page_idx: int = EventStateManager.cur_page_idx
	var shotlines_in_page: Array[Shotline] = []

	for sl: Shotline in ScreenplayDocument.shotlines:
		if (
			sl.get_start_idx().x == cur_page_idx # starts on this page
			or sl.get_end_idx().x == cur_page_idx # ends on this page
			) or (
				sl.get_start_idx().x < cur_page_idx
				and sl.get_end_idx().x > cur_page_idx
			): # Starts before this page and ends after this page
				if sl.get_end_idx().x < cur_page_idx:
					break
				shotlines_in_page.append(sl)

	for sl: Shotline in shotlines_in_page:
		var create_shotline_command: CreateShotLineCommand = CreateShotLineCommand.new([sl])
		create_shotline_command.execute()

func set_color_of_all_page_margins(color: Color = Color.TRANSPARENT) -> void:
	left_page_margin.color = color
	right_page_margin.color = color
	bottom_page_margin.color = color
	top_page_margin.color = color

func get_pageline_from_lineuuid(uuid: String) -> PageLineLabel:
	for pll: Node in page_container.get_children():
		if not pll is PageLineLabel:
			continue
		if pll.get_uuid() == uuid:
			return pll

	print_debug("UUID: ", uuid)
	print_debug("UUID Vec :", ScreenplayDocument.get_pdfline_vector_from_uuid(uuid))
	assert(false, "Could not find pageline label.")
	return null

func recursive_line_splitter(line: String, max_length: int) -> Array:
	var final_arr: Array = []
	if line.length() <= max_length:
			final_arr.append(line)
	else:
		var words := line.split(" ")
		var cur_substring := ""
		var next_substring := ""
		var cur_line_full: bool = false
		for word: String in words:
			if word.length() + cur_substring.length() <= max_length and not cur_line_full:
					cur_substring += word + " "
			else:
				cur_line_full = true
				next_substring += word + " "

		final_arr.append(cur_substring)
		var new_arr := recursive_line_splitter(next_substring, max_length)
		for nl: String in new_arr:
			final_arr.append(nl)
		 
	return final_arr
