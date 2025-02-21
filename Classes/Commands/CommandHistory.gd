extends Node

var history: Array[Command] = []
var command_index: int = 0
const max_size: int = 1000

func _ready() -> void:
	history.resize(max_size)

func add_command(command: Command) -> int:
	if not command:
		return - 1

	if not command.execute():
		return - 1

	history[command_index] = command

	if command_index == max_size - 1:
		history.pop_front()
		history.resize(max_size)
	elif command_index < max_size - 1:
		command_index += 1
		if get_command_at_index(command_index):
			print("Overwriting redos...")
			history.resize(command_index)
			history.resize(max_size)

	var first_ten: Array = []
	for n in range(10):
		first_ten.append(history[n])
	print("Current History after adding command: ", first_ten)

	return 0

func undo() -> int:
	if command_index - 1 < 0:
		print("Not undoing...")
		return - 1
	print("Undoing...")
	#print("command index before undo: ", command_index)
	#print(get_filtered_history())
	command_index -= 1
	#print("Command at index: ", history[command_index])
	history[command_index].undo()
	#print("Command index after undo: ", command_index)
	#print(history[command_index])

	return 0

func redo() -> int:
	if not history[command_index]:
		return - 1
	print("Redoing...")
	if command_index + 1 > max_size - 1:
		print("Not redoing...")
		return - 1
	#print("current command index: ", command_index)
	var command_to_redo: Command = history[command_index]
	command_to_redo.execute()
	command_index += 1
	return 0

func get_command_at_index(chosen_index: int) -> Command:
	if chosen_index < max_size:
		return history[command_index]
	return null

func get_filtered_history() -> Array:
	return history.filter(
		func(command: Command) -> bool:
			if not command:
				return false
			return true
	)

func clear_history() -> void:
	history.clear()
	history.resize(max_size)
	command_index = 0
