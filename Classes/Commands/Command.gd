extends Node

class_name Command

var params: Array = []

func _init(_params: Array) -> void:
	params = _params

func execute() -> bool:
	return true

func undo() -> bool:
	return true
