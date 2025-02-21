extends Node

const docname: String = "docname"
const characters: String = "characters"
const registered_tags: String = "registered_tags"
const pages: String = "pages"
const scenes: String = "scenes"
const shotlines: String = "shotlines"

signal file_saved(successful: bool)
signal file_loaded(successful: bool)
signal spreadsheet_exported(successful: bool)

func get_default_directory() -> String:

	match OS.get_name():
		"Web":
			return "/"
		_:
			return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)

# TODO: Must do manual serialization / deserialization for the following:
	# Screenplay Document
		# Document name
		# Characters []
		# Registered Tags [] ## hang on do I need to figure out how to do a relational database for this shit
		# Pages[]
			#PageContent - JSON.stringify
				#Lines[]
					# FNLIneGD
						#string
						#UUID
						#line type
		# Shotlines []
			#Shotline- JSON.stringify
				# segments {}
					# uuid: true/false
				# start page idx
				# end page idx
				# start uuid
				# end uuid
				# user metadata ...
		# Scenes []

func save_file(filepath: String) -> bool:
	
	var fa := FileAccess.open(filepath, FileAccess.WRITE)
	if not fa:
		return false
	
	var document_to_save: Dictionary = {
		docname: ScreenplayDocument.document_name,
		characters: ScreenplayDocument.characters,
		registered_tags: ScreenplayDocument.registered_tags,
		scenes: ScreenplayDocument.scenes,
		shotlines: (ScreenplayDocument.shotlines.map(
			func(sl: Shotline) -> Dictionary:
				return sl.get_shotline_as_dict()
				)),
		pages: (ScreenplayDocument.pages.map(
			func(pg: PageContent) -> Dictionary:
				return pg.get_pagecontent_as_dict()
				)),
	}

	var serialized_string: String = JSON.stringify(
		document_to_save,
		'\t',
		false,
		true)
	
	fa.store_string(serialized_string)
	fa.close()
	return true

func load_file(filepath: String) -> bool:
	EventStateManager.cur_page_idx = 0
	var fa := FileAccess.open(filepath, FileAccess.READ)
	if not fa:
		print_debug("Could not open file.")
		return false
	var doc_file_str: String = fa.get_as_text()
	var json := JSON.new()
	var error := json.parse(doc_file_str)

	if error:
		print_debug("Could not parse file.")
		return false

	var doc_as_dict: Dictionary = json.data

	ScreenplayDocument.document_name = doc_as_dict[docname]
	ScreenplayDocument.characters.assign(doc_as_dict[characters])
	ScreenplayDocument.registered_tags.assign(doc_as_dict[registered_tags])
	ScreenplayDocument.scenes.assign(doc_as_dict[scenes])
	ScreenplayDocument.shotlines.assign(shotlines_from_serialized_arr(doc_as_dict[shotlines]))
	ScreenplayDocument.pages.assign(pages_from_serialized_arr(doc_as_dict[pages]))
	fa.close()

	CommandHistory.clear_history()
	EventStateManager.page_node.replace_current_page(ScreenplayDocument.pages[0], 0)
	return true

func export_to_csv(filepath: String) -> bool:
	var cur_shotlines := ScreenplayDocument.shotlines
	if (not cur_shotlines) or cur_shotlines == []:
		return false
	var fa := FileAccess.open(filepath, FileAccess.WRITE)
	if not fa:
		return false
	var csv_lines: Array[PackedStringArray] = generate_csv_lines()
	if (not csv_lines) or csv_lines == []:
		return false
	for ln: PackedStringArray in csv_lines:
		fa.store_csv_line(ln)

	return true

func import_pdf(filepath: String) -> bool:

	var pdfGD_doc: PDFDocGD = PDFIngester.GetDocGD(filepath)
	if not pdfGD_doc:
		return false
	CommandHistory.clear_history()
	ScreenplayDocument.clear()

	var page_node := EventStateManager.page_node
	ScreenplayDocument.pages = ScreenplayDocument.get_pages_from_pdfdocgd(pdfGD_doc)
	page_node.replace_current_page(
		ScreenplayDocument.pages[0],
		0
	)
	EventStateManager.cur_page_idx = 0

	#print_debug("strings from PDFGD doc:")
	#for page: PDFPage in pdfGD_doc.PDFPages:
	#	print("-----------------PAGE-------------")
	#	var table: String = "[table=3]"
	#	# TODO: Handle vertical offset between lines, insert "blank lines" in between for spacing
	#	for line: PDFLineFN in page.PDFLines:
	#		var letter_width: float = line.PDFWords[0].PDFLetters[0].Width
	#		var letter_point_size: float = line.PDFWords[0].PDFLetters[0].PointSize
	#		line.LineState = PDFScreenplayParser.get_PDFLine_body_state(
	#			line,
	#			page.PageSizeInPoints,
	#			letter_point_size,
	#			letter_width
	#			)
	#		var line_string: String = PDFScreenplayParser.get_normalized_body_text(
	#			line,
	#			page.PageSizeInPoints)
	#
	#		table += "[cell]%s[/cell]" % (
	#			PDFScreenplayParser.PDF_LINE_STATE.keys()[line.LineState]
	#			)
	#		table += "[cell]%s[/cell]" % (line.GetLinePosition())
	#		table += "[cell]%s[/cell]" % ("\t" + line_string)
	#		#print(line.GetLineString())
	#		#print(line.GetLinePosition(), " | ", line.GetLineString())
	#	table += "[/table]"
	#	print_rich(table)
	
	return true

func generate_csv_lines() -> Array[PackedStringArray]:
	var new_arr: Array[PackedStringArray] = []
	var header_line: PackedStringArray = PackedStringArray(
		[
		"COMPLETED", "SHOT NUMBER", "SHOT TYPE", "SHOT SUBTYPE", "INT./EXT.", "LOCATION", "TIME", "GROUP", "TAGS", "PROPS"
		]
		)
	new_arr.append(header_line)

	for shotline: Shotline in ScreenplayDocument.shotlines:
		var new_csv_line: PackedStringArray = PackedStringArray(
			[
			" ", str(shotline.scene_number) + "." + str(shotline.shot_number), str(shotline.shot_type), str(shotline.shot_subtype), " ", " ", " ",
			str(shotline.group), str(shotline.tags), " "
			]
		)
		new_arr.append(new_csv_line)

	return new_arr

func pages_from_serialized_arr(page_arr: Array) -> Array[PageContent]:
	assert(page_arr, "No Page Array found.")

	var new_arr: Array[PageContent] = []

	for page_dict: Dictionary in page_arr:
		var new_pc: PageContent = PageContent.new()
		new_pc.set_pagecontent_from_dict(page_dict)
		new_arr.append(new_pc)
	
	return new_arr

func shotlines_from_serialized_arr(arr: Array) -> Array[Shotline]:
	if (not arr) or arr == []:
		return []
	
	var new_arr: Array[Shotline] = []

	for element: Dictionary in arr:
		var new_sl: Shotline = Shotline.new()

		#new_sl.start_page_index = element["start_page_index"]
		#new_sl.end_page_index = element["end_page_index"]
		new_sl.start_uuid = element["start_uuid"]
		new_sl.end_uuid = element["end_uuid"]
		new_sl.x_position = element["x_position"]

		new_sl.segments_filmed_or_unfilmed = element["segments_filmed_or_unfilmed"]

		new_sl.shotline_uuid = element["shotline_uuid"]

		new_sl.scene_number = element["scene_number"]
		new_sl.shot_number = element["shot_number"]
		new_sl.shot_type = element["shot_type"]
		new_sl.shot_subtype = element["shot_subtype"]
		new_sl.setup_number = element["setup_number"]
		new_sl.group = element["group"]
		new_sl.tags = element["tags"]
		new_arr.append(new_sl)
	return new_arr

# TODO: these two funcs just need to be one func tbh
func get_file_dialog(
	file_mode: FileDialog.FileMode,
	sl_fileaction: SLFileAction.FILE_ACTION
	) -> FileDialog:
	assert(file_mode != null, "File Mode not set.")

	var fd := FileDialog.new()
	fd.file_mode = file_mode
	fd.use_native_dialog = true
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.min_size = Vector2i(600, 480)
	fd.max_size = Vector2i(800, 600)
	fd.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	fd.current_dir = get_default_directory()

	
	fd.canceled.connect(EventStateManager._on_file_dialog_cancelled.bind(fd))
	fd.file_selected.connect(EventStateManager._on_file_dialog_file_selected.bind(sl_fileaction, fd))
	return fd

func open_file_dialog(file_mode: FileDialog.FileMode, sl_file_action: SLFileAction.FILE_ACTION) -> void:
	
	var fd: FileDialog = SLFileHandler.get_file_dialog(
		file_mode,
		sl_file_action
		)
	
	match sl_file_action:
		SLFileAction.FILE_ACTION.SAVE_FILE:
			fd.set_filters(PackedStringArray(["*.sl; ShotLiner file"]))
		SLFileAction.FILE_ACTION.LOAD_FILE:
			fd.set_filters(PackedStringArray(["*.sl; ShotLiner file"]))
		SLFileAction.FILE_ACTION.EXPORT_CSV:
			fd.set_filters(PackedStringArray(["*.csv; "]))
		SLFileAction.FILE_ACTION.IMPORT_PDF:
			fd.set_filters(PackedStringArray(["*.pdf; PDF Document"]))
	EventStateManager.page_node.add_child(fd)
	fd.show()
