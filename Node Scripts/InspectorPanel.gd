extends Control

class_name InspectorPanel

@onready var scene_num: Control = %SceneNum
@onready var shot_subtype: Control = % "Shot Subtype"
@onready var shot_num: Control = % "ShotNum"
@onready var shot_type: Control = % "Shot Type"
@onready var setup_num: Control = % "Setup #"
@onready var lens: Control = % "Lens"
@onready var group: Control = % "Group"
@onready var tags: Control = % "Tags"

@onready var fields: Array[Control] = [
	scene_num,
	shot_num,
	shot_type,
	shot_subtype,
	setup_num,
	lens,
	group,
	tags
]

signal field_text_changed(new_text: String, field_category: TextInputField.FIELD_CATEGORY)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventStateManager.inpsector_panel_node = self
	for field in fields:
		field.text_changed.connect(on_field_text_changed)

func populate_fields_from_shotline(shotline: Shotline) -> void:
	shot_subtype.set_text(shotline.shot_subtype)
	scene_num.set_text(shotline.scene_number)
	shot_num.set_text(shotline.shot_number)
	shot_type.set_text(shotline.shot_type)
	setup_num.set_text(shotline.setup_number)
	group.set_text(shotline.group)
	#tags.set_text(shotline.tags)

func clear_fields() -> void:
	for field: Control in fields:
		field.set_text()

func on_field_text_changed(new_text: String, field_category: TextInputField.FIELD_CATEGORY) -> void:
	#print(new_text, " | ", TextInputField.FIELD_CATEGORY.keys()[field_category])
	field_text_changed.emit(new_text, field_category)
