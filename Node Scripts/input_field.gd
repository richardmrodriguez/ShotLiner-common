extends Control

class_name TextInputField

@export var field_label: String
@export var field_placeholder: String
@export var field_text: String
@export var field_category: FIELD_CATEGORY
@export var node_prev_focus: TextInputField
@export var node_next_focus: TextInputField

enum FIELD_TYPE {
	LINE,
	MULTILINE
}

enum FIELD_CATEGORY {
	SCENE_NUM,
	SHOT_NUM,
	SHOT_TYPE,
	SHOT_SUBTYPE,
	LENS,
	GROUP,
	TAGS,
	SETUP_NUM,
}
@export var chosen_field_type: FIELD_TYPE

@onready var label: Label = $VBox/Label
@onready var line_edit: LineEdit = $VBox/LineEdit
@onready var vbox: VBoxContainer = $VBox

signal text_changed(text: String, field_category: FIELD_CATEGORY)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	line_edit.focus_entered.connect(_on_focus_entered)
	line_edit.focus_exited.connect(_on_focus_exited)
	focus_mode = Control.FOCUS_ALL
	label.focus_mode = Control.FOCUS_ALL
	label.text = field_label
	line_edit.text_changed.connect(_on_field_text_changed)
	await get_tree().process_frame
	if node_next_focus:
		line_edit.focus_next = node_next_focus.line_edit.get_path()
	if node_prev_focus:
		line_edit.focus_previous = node_prev_focus.line_edit.get_path()

	if chosen_field_type == FIELD_TYPE.MULTILINE:
		vbox.remove_child(line_edit)
		var textedit: TextEdit = TextEdit.new()
		textedit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)
		vbox.add_child(textedit)
		textedit.text = field_text
		textedit.custom_minimum_size = Vector2(0, 35)
		textedit.placeholder_text = field_placeholder
	else:
		line_edit.text = field_text
		line_edit.placeholder_text = field_placeholder

func grab_field_focus() -> void:
	if line_edit:
		line_edit.grab_focus()


func _on_line_edit_gui_input(_event: InputEvent) -> void:
	pass
	#if event is InputEventKey:
	#	if event.pressed:
	#		if event.keycode == KEY_PERIOD or event.keycode == KEY_KP_PERIOD:
	#			if (
	#				field_category == FIELD_CATEGORY.SCENE_NUM
	#				or field_category == FIELD_CATEGORY.SHOT_NUM
	#				or field_category == FIELD_CATEGORY.SHOT_TYPE
	#				or field_category == FIELD_CATEGORY.SHOT_SUBTYPE
	#				):
	#				await get_tree().process_frame
	#				if line_edit.text.length() > 1:
	#					line_edit.text = line_edit.text.substr(0, line_edit.text.length() - 1)
	#				else:
	#					line_edit.text = ""
	#				text_changed.emit(line_edit.text)
	#				node_next_focus.line_edit.grab_focus()

func _on_field_text_changed(new_text: String) -> void:
	text_changed.emit(new_text, field_category)

func set_text(text: String = "") -> void:
	line_edit.text = text

func get_text() -> String:
	return line_edit.text

func _on_focus_entered() -> void:
	if field_category == FIELD_CATEGORY.SHOT_NUM:
		if line_edit.text == "":
			line_edit.text = "0"
			text_changed.emit(line_edit.text, field_category)

func _on_focus_exited() -> void:
	if field_category == FIELD_CATEGORY.SHOT_NUM:
		if line_edit.text == "":
			line_edit.text = "0"
			text_changed.emit(line_edit.text, field_category)