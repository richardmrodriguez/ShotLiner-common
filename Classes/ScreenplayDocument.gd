extends Node

# TODO: Add support for more document wide metadata:
# - Scenes
# - Registered Tags
# - etc.

var document_name: String = ""
var characters: Array = [] # list of character names
var registered_tags: Array[String] = []

var pages: Array[PageContent] = []
var scenes: Array[ScreenplayScene] = []
var shotlines: Array[Shotline] = []

@onready var page_node: ScreenplayPage

# This Struct could also have some functions to retrieve data such as:
#   - How many Scenes or Shots contain a certain element:
#       - Character
#       - Prop
#       - Location 
func load_screenplay(filename: String) -> String:
	var file := FileAccess.open(filename, FileAccess.READ)
	var content := file.get_as_text()
	return content

func get_pages_from_pdfdocgd(pdf: PDFDocGD) -> Array[PageContent]:
	var pagearray: Array[PageContent] = []
	
	var last_scene_num_nominal: String = ""
	var last_scene_num_counter: int = 1
	for page: PDFPage in pdf.PDFPages:
		var cur_page: PageContent = PageContent.new()
		var pagesize_points: Vector2 = page.PageSizeInPoints
		
		# Do PDF PARSING in this for loop, for each line
		for line: PDFLineFN in page.PDFLines:
			if line.LineUUID == "": # only reassign the UUID if it hasn't been assigned yet;
				# 	This is important so that a script can be re-parsed by the user 
				#	even if the entire document has shotlines on it
				line.LineUUID = EventStateManager.uuid_util.v4()
			line.LineElement = PDFScreenplayParser.parse_pdfline(line, pagesize_points)
			match line.LineElement:
				PDFScreenplayParser.ELEMENT.SCENE_HEADING:
					# TODO: Abstract this logic into a separate func to be used upon .sl file loading (also, just save the scenes as a struct with the file.)
					var scene_num_result: String = PDFScreenplayParser.get_nominal_scene_num(line, pagesize_points)
					if scene_num_result != "":
						line.NominalSceneNum = scene_num_result
						last_scene_num_nominal = scene_num_result
					else: # no scene num in line
						if last_scene_num_nominal == "":
							last_scene_num_nominal = str(last_scene_num_counter)
							line.NominalSceneNum = last_scene_num_nominal
							last_scene_num_counter += 1
						else:
							last_scene_num_counter = int(last_scene_num_nominal) + 1
							last_scene_num_nominal = str(last_scene_num_counter)
							line.NominalSceneNum = last_scene_num_nominal
							last_scene_num_counter += 1
					var new_scene: ScreenplayScene = ScreenplayScene.new()
					new_scene.scene_line_id = line.LineUUID
					new_scene.scene_num_nominal = last_scene_num_nominal
					# TODO: assign other metadata to scene
					scenes.append(new_scene)


			cur_page.pdflines.append(line)
		
		pagearray.append(cur_page)
	
	return pagearray

func get_pdfline_from_uuid(uuid: String) -> PDFLineFN:
	var index: Vector2i = get_pdfline_vector_from_uuid(uuid)
	return pages[index.x].pdflines[index.y]

func get_pdfline_vector_from_uuid(uuid: String) -> Vector2i:
	for page: PageContent in pages:
		if page.pdflines:
			for line: PDFLineFN in page.pdflines:
				if line.LineUUID == uuid:
					var result: Vector2i = Vector2i(pages.find(page), page.pdflines.find(line))
					assert((result.x != -1 and result.y != -1), "A - Could not find PDFLine Vector: " + str(result))
					return Vector2i(pages.find(page), page.pdflines.find(line))
	assert(false, "B - Could not find PDFLine Vector.")
	return Vector2i()

func get_scene_num_from_global_line_idx(pdfline_idx: Vector2i) -> String:
	var result := get_scene_from_global_line_idx(pdfline_idx)
	if result:
		return result.scene_num_nominal
	else:
		return ""
		

func get_scene_from_global_line_idx(pdfline_idx: Vector2i) -> ScreenplayScene:
	var last_valid_scene: ScreenplayScene
	assert(not scenes.is_empty(), "No scenes yet.")
	for scene: ScreenplayScene in scenes:
		print_debug("Current scene num: ", scene.scene_num_nominal)
		var scene_idx: Vector2i = get_pdfline_vector_from_uuid(scene.scene_line_id)
		if scene_idx == pdfline_idx:
			return scene
		if (scene_idx.x < pdfline_idx.x):
			last_valid_scene = scene
		elif scene_idx.x == pdfline_idx.x:
			if scene_idx.y < pdfline_idx.y:
				last_valid_scene = scene

			else:
				return last_valid_scene
		else:
			return last_valid_scene
		
	# this should never escape past the for loop, but for some reason it does sometimes
	assert(false, "Could not find scene for selected pageline at index: " + str(pdfline_idx))
	return null

func get_shotline_from_uuid(uuid: String) -> Shotline:
	for shotline: Shotline in shotlines:
		if shotline.shotline_uuid == uuid:
			return shotline
	assert(false, "Could not find shotline with this UUID: " + uuid)
	return null

func get_array_of_pdflines_from_start_and_end_uuids(start: String, end: String) -> Array[PDFLineFN]:
	var found_start: bool = false
	var found_end: bool = false

	var array: Array[PDFLineFN] = []

	for page: PageContent in pages:
		if found_end:
			break
		
		for line: PDFLineFN in page.pdflines:
			if line.LineUUID == start:
				found_start = true
			if not found_start:
				continue
			array.append(line)
			if line.LineUUID == end:
				found_end = true
				break
	
	return array

func clear() -> void:
	document_name = ""
	characters = [] # list of character names
	registered_tags = []
	pages = []
	scenes = []
	shotlines = []
