extends Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = "1."

	EventStateManager.page_changed.connect(_on_page_changed)

func _on_page_changed() -> void:
	text = str(EventStateManager.cur_page_idx + 1) + "."
