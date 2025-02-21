extends Command

class_name BulkSegmentsChangedCommand

var prev_segments_state: Dictionary # shotline_uuid: {pageline_uuid: true/false} //// Nested Dictionary
var completed_cmds: Array[ToggleSegmentUnfilmedCommand] = []
var first_executed: bool = false

func _init(_params: Array) -> void:
    completed_cmds = _params.front()
    prev_segments_state = _params.back()

func execute() -> bool:
    if (not prev_segments_state) or prev_segments_state == {}:
        return false
    if not first_executed:
        first_executed = true
        return true
    if (not completed_cmds) or completed_cmds == []:
        return false
    for cmd: ToggleSegmentUnfilmedCommand in completed_cmds:
        cmd.execute()
    return true

func undo() -> bool:
    if not (prev_segments_state or completed_cmds):
        return false
    if (not completed_cmds) or completed_cmds == []:
        return false
    for cmd: ToggleSegmentUnfilmedCommand in completed_cmds:
        cmd.undo()
    return true