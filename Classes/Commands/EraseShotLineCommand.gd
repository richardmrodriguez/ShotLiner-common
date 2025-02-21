extends Command

class_name EraseShotLineCommand

var shotline_obj: Shotline
var shotline_uuid: String
var this_shotline_2D: ShotLine2DContainer
var page_panel: Node
var command_to_invert: CreateShotLineCommand

func _init(_params: Array) -> void:
    params = _params
    command_to_invert = CreateShotLineCommand.new(params)

func undo() -> bool:
    return command_to_invert.execute()
    
func execute() -> bool:
    print("erasing shotline...")
    return command_to_invert.undo()
    