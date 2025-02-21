class_name PageContent

var pdflines: Array[PDFLineFN] # TODO: Refactor page construction to add PDFLineFNs instead of FNLineGDs
var page_size: Vector2 = Vector2(72 * 8.5, 72 * 11)
var dpi: float = 72.0

func get_pagecontent_as_dict() -> Dictionary:
	return {
		"lines": pdflines.map(
			func(line: PDFLineFN) -> Dictionary:
				return line.GetLineAsDict()
				),
		"page_size": page_size,
		"dpi": dpi
	}

func set_pagecontent_from_dict(pc_dict: Dictionary) -> void:
	pdflines = []
	# FIXME: This inner block shows an error in the Godot editor view (presumably) every time it is run. This does not crash or show other bugs (yet), but I don't understand why

	# there are so many error messages for this block...
	for line_dict: Dictionary in pc_dict["lines"]:
		var new_pdfline: PDFLineFN = PDFLineFN.new()
		new_pdfline.SetLineFromDict(line_dict)
		pdflines.append(new_pdfline)
