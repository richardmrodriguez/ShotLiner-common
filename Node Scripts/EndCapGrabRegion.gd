extends ColorRect

class_name EndcapGrabRegion

@onready var open_endcap: Node = %OpenEndCapLine2D
@onready var closed_endcap: Node = %ClosedEndCapLine2D
@onready var shotline_container: Node = get_parent()

var is_open: bool = false

@export var is_begin_cap: bool = false

var cap_region_is_hovered_over: bool = false

signal endcap_clicked(
	endcap_region: EndcapGrabRegion,
	shotline: ShotLine2DContainer,
	button_index: int)
signal endcap_released(
	endcap_region: EndcapGrabRegion,
	shotline: ShotLine2DContainer,
	button_index: int)
signal endcap_dragged(endcap_region: EndcapGrabRegion)

func _ready() -> void:
	endcap_clicked.connect(EventStateManager._on_shotline_endcap_clicked)
	endcap_released.connect(EventStateManager._on_shotline_endcap_released)

func toggle_open_endcap(open_state: bool = false) -> void:
	if open_state:
		is_open = true

		open_endcap.visible = true
		closed_endcap.visible = false
	else:
		is_open = false
		open_endcap.visible = false
		closed_endcap.visible = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if get_global_rect().has_point(get_global_mouse_position()):
			cap_region_is_hovered_over = true
			color = ShotLinerColors.content_color
		else:
			cap_region_is_hovered_over = false
			color = Color.TRANSPARENT
	if event.is_action("TouchDown", true):
		if event.is_pressed():
			if cap_region_is_hovered_over:
				endcap_clicked.emit(
					self,
					shotline_container,
					event.button_index
					)
		else:
			if cap_region_is_hovered_over:
				endcap_released.emit(
					self,
					shotline_container,
					event.button_index
					)