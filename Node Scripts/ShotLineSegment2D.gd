extends ColorRect

class_name ShotLineSegment2D

@onready var straight_line: Node
@onready var jagged_line: Node
@onready var segments_container: Node
@onready var shotline_container: Node

var pageline_uuid: String

var is_hovered_over: bool = false
var is_straight: bool = true

signal hovered_over_shotline_segment(segment: ShotLineSegment2D)

func _ready() -> void:

	segments_container = get_parent()
	shotline_container = segments_container.get_parent()

	hovered_over_shotline_segment.connect(segments_container._on_segment_hovered)
	mouse_filter = Control.MOUSE_FILTER_PASS
	straight_line = $StraightLine2D
	jagged_line = $JaggedLine2D
	set_straight_or_jagged(true)
	#color = Color.YELLOW

func set_straight_or_jagged(straight: bool) -> void:
	if straight:
		straight_line.visible = true
		jagged_line.visible = false
	else:
		straight_line.visible = false
		jagged_line.visible = true
	

func set_segment_height(height: float) -> void:
	custom_minimum_size = Vector2(size.x, height)
	straight_line.set_points(PackedVector2Array(
		[
			Vector2(0, 0),
			Vector2(0, height)
		]
		)
	)
	jagged_line.set_points(PackedVector2Array(
		[
			Vector2(0, 0),
			Vector2(8, (height / 3)),
			Vector2(-8, 2 * (height / 3)),
			Vector2(0, height)
		]
	))

func set_segment_line_width(width: float) -> void:
	straight_line.width = width
	jagged_line.width = 0.75 * width

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if get_global_rect().has_point(event.global_position):
			is_hovered_over = true
			hovered_over_shotline_segment.emit(self)
			set_segment_line_width(shotline_container.hover_line_width)
		else:
			is_hovered_over = false
			set_segment_line_width(shotline_container.line_width)
	if event.is_action("DrawInvert", true):
		if event.is_pressed():
			return
			# TODO: Add back single click segment inversion
			if EventStateManager.cur_tool == EventStateManager.TOOL.DRAW:
				if is_hovered_over:
					var toggle_straight_command := ToggleSegmentUnfilmedCommand.new([self])
					CommandHistory.add_command(toggle_straight_command)
