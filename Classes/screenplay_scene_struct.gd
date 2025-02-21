class_name ScreenplayScene

var scene_line_id: String
var scene_num_nominal: String
var page_num_start_nominal: String
#var section: PagelineSection
var scene_location: String
var scene_time_of_day: String
var characters_in_scene: Array

var associated_tags: Array
var associated_setups: Array

func get_shotlines_for_scene() -> Array[Shotline]:
    var shotlines: Array[Shotline] = []
    for shotline: Shotline in ScreenplayDocument.shotlines:
        
        if ScreenplayDocument.get_scene_num_from_global_line_idx(shotline.get_start_idx()) == scene_num_nominal:
            shotlines.append(shotline)
    
    return shotlines

func get_highest_shot_number_for_scene() -> String:
    var shotlines := get_shotlines_for_scene()
    var shot_numbers: Array[String] = []
    for sl: Shotline in shotlines:
        shot_numbers.append(sl.shot_number)
    shot_numbers.sort_custom(func(a: String, b: String) -> bool:
         # TODO: SHOT NUMBER SORTING: Implement a custom sort to account for alphabetical / alphanumeric shot numbers
        return int(a) < int(b)
    )
    if shot_numbers.is_empty():
        return ""
    return shot_numbers.back()
