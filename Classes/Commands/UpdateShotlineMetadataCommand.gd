extends Command
class_name UpdateShotlineMetadataCommand

var old_metadata: Dictionary = {}
var new_metadata: Dictionary = {}

# TODO: Only update shotline metadata when the user does one of the following:
    # tabs from one InputField to another
    # hits enter in an InputField
    # When focus is changed from an InputField to something else

func _init(_params: Array) -> void:
    pass