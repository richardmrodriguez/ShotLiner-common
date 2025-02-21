extends Command

class_name ResizeShotlineCommand

var is_moved_from_topcap: bool

var old_shotline_start_uuid: String
var old_shotline_end_uuid: String

var new_shotline_end_uuid: String
var new_shotline_start_uuid: String

var last_uuid_resized_from: String
var was_inverted: bool = false

var shotline_uuid: String

var new_start_end_set: bool = false

var new_uuid_to_resize_to: String

var old_segments: Dictionary = {}

var old_begin_cap_state: bool
var old_end_cap_state: bool
var new_begin_cap_state: bool
var new_end_cap_state: bool

func _init(_params: Array) -> void:
	is_moved_from_topcap = _params[0]
	var shotline: Shotline = _params[1]
	new_uuid_to_resize_to = _params[2]

	old_shotline_start_uuid = shotline.start_uuid
	old_shotline_end_uuid = shotline.end_uuid

	shotline_uuid = shotline.shotline_uuid
	old_segments = shotline.segments_filmed_or_unfilmed.duplicate(true)


func execute() -> bool:
	var shotline: Shotline = ScreenplayDocument.get_shotline_from_uuid(shotline_uuid)
	assert(shotline, "Shotline not found.")
	var uuid_to_resize_to: String = new_uuid_to_resize_to
	if new_start_end_set:
		if not was_inverted:
			if is_moved_from_topcap:
				uuid_to_resize_to = new_shotline_start_uuid
			else:
				uuid_to_resize_to = new_shotline_end_uuid
		else:
			if is_moved_from_topcap:
				uuid_to_resize_to = new_shotline_end_uuid
			else:
				uuid_to_resize_to = new_shotline_start_uuid
	shotline.shotline_node.update_length_from_endcap_drag(
		is_moved_from_topcap,
		uuid_to_resize_to,
		
		)
	
	if not new_start_end_set:
		new_shotline_start_uuid = shotline.start_uuid
		new_shotline_end_uuid = shotline.end_uuid

		if new_shotline_start_uuid == old_shotline_start_uuid:
			last_uuid_resized_from = old_shotline_end_uuid
		elif new_shotline_end_uuid == old_shotline_start_uuid:
			was_inverted = true
			last_uuid_resized_from = old_shotline_end_uuid
			
		elif new_shotline_end_uuid == old_shotline_end_uuid:
			last_uuid_resized_from = old_shotline_start_uuid
		elif new_shotline_start_uuid == old_shotline_end_uuid:
			was_inverted = true
			last_uuid_resized_from = old_shotline_start_uuid

		new_start_end_set = true

	return true

func undo() -> bool:
	var shotline: Shotline = ScreenplayDocument.get_shotline_from_uuid(shotline_uuid)
	assert(shotline, "Shotline not found.")

	if not shotline.shotline_node:
		shotline.start_uuid = old_shotline_start_uuid
		shotline.end_uuid = old_shotline_end_uuid

		var create_shotline_cmd: CreateShotLineCommand = CreateShotLineCommand.new([shotline])
		create_shotline_cmd.execute()
	else:
		var resized_maybe_inverted: bool = is_moved_from_topcap
		if was_inverted:
			resized_maybe_inverted = not resized_maybe_inverted

		shotline.shotline_node.update_length_from_endcap_drag( # TODO: This is supposed to make undoing a resize preserve the previous state of the segments
			resized_maybe_inverted,
			last_uuid_resized_from,
			old_segments.duplicate(true))
		
	return true
