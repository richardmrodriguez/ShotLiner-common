extends Label

class_name PageLineLabel
var pdfline: PDFLineFN
var line_index: int

var label_highlight: ColorRect

func get_uuid() -> String:
	assert(pdfline, "No PDFLine assigned to this label.")
	return pdfline.LineUUID
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
