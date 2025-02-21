## This class is responsible for taking the PDFLineFN inputs from a PDFDocGD 
## and returning a list of `ScreenplayPageContent`s which have been properly modified and marked
## I.E. Each line belongs to a scene, each line has an FNlineType, etc.
class_name PDFScreenplayParser
extends Node

static var STANDARD_SCENE_HEADING_PREFIXES: Array[String] = [
    "INT.",
    "EXT.",
    "I./E.",
    "INT./EXT.",
]

static var STANDARD_ELEMENT_INDENTS: Dictionary = {
    "ACTION": 1.5,
    "CHARACTER_CUE": 3.5,
    "DIALOGUE_LEFT": 2.5,
    "DIALOGUE_RIGHT": 5.5,
    "PARENTHETICAL": 3.0,
    "TRANSITION": 6.0,


}

static var STANDARD_ELEMENT_VERTICAL_OFFSETS: Dictionary = {
    "NOMINAL_PAGE_NUM": 0.5
}

enum PDF_LINE_STATE {
    WITHIN_BODY_MARGINS,
    BEFORE_LEFT_MARGIN,
    AFTER_RIGHT_MARGIN,
    BEFORE_LEFT_AND_AFTER_RIGHT_MARGIN,
    ABOVE_TOP_MARGIN,
    BELOW_BOTTOM_MARGIN,
}

enum ELEMENT {
    ACTION,
    SCENE_HEADING,
    CHARACTER_CUE,
    PARENTHETICAL,
    DIALOGUE,
    NOMINAL_PAGE_NUM,
    TRANSITION,
    HEADER,
    FOOTER,
    DUAL_CHARACTERS,
    DUAL_DIALOGUES, # Could be Dual dialogues, dual wrylies, or one wrylie and one dialogue, ugh
    OMITTED,
    OTHER,

}

static var left_margin_in: float = 1.5
static var right_margin_in: float = 1
static var top_margin_in: float = 1
static var bottom_margin_in: float = 1


static func parse_pdfline(pdfline: PDFLineFN, pdf_page_size_points: Vector2, extra_scene_heading_prefixes: Array[String] = []) -> ELEMENT:
    var body_text: String = get_normalized_body_text(pdfline, pdf_page_size_points)
    var dpi: float = get_dpi_from_pagesize(pdf_page_size_points)
    var letter_point_size: float = dpi / 6.0
    var prefixes_to_check: Array[String] = STANDARD_SCENE_HEADING_PREFIXES.duplicate(true)
    prefixes_to_check.append_array(extra_scene_heading_prefixes.duplicate(true))

    for prefix: String in prefixes_to_check:
        if body_text.begins_with(prefix):
            return ELEMENT.SCENE_HEADING
    
    if get_PDFLine_body_state(pdfline, pdf_page_size_points) == PDF_LINE_STATE.BEFORE_LEFT_AND_AFTER_RIGHT_MARGIN:
        return ELEMENT.SCENE_HEADING
    
    # Parse by Vertical Position
    var linepos: Vector2 = pdfline.GetLinePosition()
    if (pdf_page_size_points.y - linepos.y) <= (STANDARD_ELEMENT_VERTICAL_OFFSETS["NOMINAL_PAGE_NUM"] * dpi): # if it is less than half an inch from top of page
        if linepos.x > 0.75 * pdf_page_size_points.x:
            return ELEMENT.NOMINAL_PAGE_NUM
        return ELEMENT.HEADER

    # Parse by Horizontal Position
    if linepos.x >= STANDARD_ELEMENT_INDENTS["TRANSITION"] * dpi:
        return ELEMENT.TRANSITION
    if linepos.x >= STANDARD_ELEMENT_INDENTS["CHARACTER_CUE"] * dpi:
        return ELEMENT.CHARACTER_CUE
    if linepos.x >= STANDARD_ELEMENT_INDENTS["PARENTHETICAL"] * dpi:
        return ELEMENT.PARENTHETICAL
    if linepos.x >= STANDARD_ELEMENT_INDENTS["DIALOGUE_LEFT"] * dpi:
        return ELEMENT.DIALOGUE
    #TODO: Dual Dialogue Support...
    
    # elements should only be footers as a last resort
    if linepos.y < 1 * dpi: # if it is less than 1 inch from bottom of page
        return ELEMENT.FOOTER # this might not be right... footers should
    return ELEMENT.ACTION

# TODO: Special Case Parsing for Production Script elements:

    # For each of these Elements, simply strip out any extraneous text, assign the appropriate
    # values to the FNLineGD, then send this FNlineGD off to be "really" parsed by the main parser.
        # Sluglines with Scene Numbers 
            # The scene numbers bookend at a fixed position before and after the body margins
        # Revised lines { * Text'content..... *}
            # The Revision asterisk `*` bookend at a fixed position before and after the body margins
        # Page Numbers
            # Fixed position above body margins, first page of a screenplay usually doesn't have a page number printed
        # Headers / Footers (likely revision dates)
            # Above / Below body margins
        # Omitted Scenes
            # This is just text that says "OMITTED", but is also marked as "omitted" in its FNlineGD
            # This is important for diffing between revisions of documents

#

## Returns the state of a PDFLine, if it is within the body margins,
## or if it is above or below the top and bottom, 
## or if it is before or after (or both before and after) the left and right-hand margins. 
static func get_PDFLine_body_state(
    line: PDFLineFN,
    pdf_page_size_points: Vector2,
    ) -> PDF_LINE_STATE:

    var is_before_left_margin: bool = false
    var is_after_right_margin: bool = false
    var is_above_top_margin: bool = false
    var is_below_bottom_margin: bool = false

    var dpi: float = get_dpi_from_pagesize(pdf_page_size_points)

   
    #----------Left Margin Check
    var first_word: PDFWord = line.PDFWords[0]
    var first_letter: PDFLetter = first_word.PDFLetters[0]
    if first_letter.Location.x < dpi * left_margin_in: # less than 1 inch from left hand side
        is_before_left_margin = true
    #---------Right Margin Check
    var last_word: PDFWord = line.PDFWords[-1]
    var last_letter: PDFLetter = last_word.PDFLetters[-1]
    if (pdf_page_size_points.x - last_letter.Location.x) < dpi * right_margin_in:
        is_after_right_margin = true
    #--------Top Margin Check
    if (pdf_page_size_points.y - first_letter.Location.y) < dpi * top_margin_in: # less than 1 inch rom top edge of page
        is_above_top_margin = true
    #--------Bottom Margin Check
    if first_letter.Location.y < dpi * bottom_margin_in:
        is_below_bottom_margin = true

    if not (
        is_above_top_margin or
        is_below_bottom_margin or
        is_before_left_margin or
        is_after_right_margin):
        return PDF_LINE_STATE.WITHIN_BODY_MARGINS

    if is_above_top_margin:
        return PDF_LINE_STATE.ABOVE_TOP_MARGIN
    elif is_below_bottom_margin:
        return PDF_LINE_STATE.BELOW_BOTTOM_MARGIN

    if is_before_left_margin and is_after_right_margin:
        return PDF_LINE_STATE.BEFORE_LEFT_AND_AFTER_RIGHT_MARGIN
    elif is_before_left_margin:
        return PDF_LINE_STATE.BEFORE_LEFT_MARGIN
    elif is_after_right_margin:
        return PDF_LINE_STATE.AFTER_RIGHT_MARGIN

    return PDF_LINE_STATE.WITHIN_BODY_MARGINS

static func get_dpi_from_pagesize(pagesize: Vector2) -> float:
    var dpi: float = 72.0
    var page_type: String = "A4"
    if (pagesize.x / pagesize.y) > 0.709:
        page_type = "USLETTER"

    if page_type == "USLETTER":
        dpi = pagesize.x / 8.5
    else:
        dpi = pagesize.x / 8.3
    
    return dpi

## Get normalized body text, without line numbers or revision asterisks which lie outside the body margins
static func get_normalized_body_text(
    pdfline: PDFLineFN,
    pdf_page_size_points: Vector2) -> String:

    # TODO: Use some code from this func to get the un-normalized text as well...
    if pdfline.NormalizedLine != "":
        return pdfline.NormalizedLine

    var normalized_text: String = ""
    var dpi: float = get_dpi_from_pagesize(pdf_page_size_points)
   
    var last_pdf_word: PDFWord = null
    for cur_word: PDFWord in pdfline.PDFWords:
        var first_letter_pos: float = cur_word.PDFLetters[0].Location.x
        if (first_letter_pos < dpi * left_margin_in) or ((pdf_page_size_points.x - first_letter_pos) < dpi * right_margin_in
        ):
            continue
        else:
            normalized_text += " ".repeat(get_spaces_between_character_positions(
                cur_word,
                last_pdf_word,
                dpi))
            if not last_pdf_word:
                last_pdf_word = cur_word
                
                #assert(false, normalized_text)
                
            normalized_text += cur_word.GetWordString()
            last_pdf_word = cur_word
# TODO: When using this func, put this result in the pdfline's NormalizedLine string
    return normalized_text

static func get_nominal_scene_num(pageline: PDFLineFN, page_size: Vector2) -> String:
    var full_text := pageline.GetLineString()
    var normalized_text: String = get_normalized_body_text(pageline, page_size)
    var scene_num_only: String = full_text.erase(full_text.find(normalized_text), normalized_text.length())
    scene_num_only = scene_num_only.erase(scene_num_only.find(" "), scene_num_only.length())
    return scene_num_only
#PDFScreenplayParser.ELEMENT.

static func get_spaces_between_character_positions(new_word: PDFWord, old_word: PDFWord, dpi: float) -> int:
    if not old_word:
        return 0
    var new_x: float = new_word.PDFLetters[0].Location.x
    var old_x: float = old_word.PDFLetters[-1].Location.x
    var char_width: float = dpi * 0.1
    var spaces: int = roundi(abs(new_x - old_x) / char_width) - 1
        
    return spaces

# TODO: make use of the following funcs

## Iterates over the pages of a PDFDocGD, returns an Array of local modes of y-height differences between PDFLineFNs.
## In other words, each element of the Array is the most-occurring y-height difference for that particular page.
## This func may not return the exact number of elements as there are pages in the PDFDocGD.
static func get_modes_of_line_y_deltas_from_doc(pdfdoc: PDFDocGD, excluded_pages: Array[int] = []) -> Array[float]:
    
    var y_deltas: Array[float] = []

    var page_indices: Array = range(pdfdoc.PDFPages.size())

    for ex: int in excluded_pages:
        if excluded_pages == []:
            break
        if page_indices.has(ex):
            page_indices.remove_at(page_indices.find(ex))

    for pidx: int in page_indices:
        var page: PDFPage = pdfdoc.PDFPages[pidx]
        var local_deltas: Array[float] = []

        var last_line: PDFLineFN = null
        for line: PDFLineFN in page.PDFLines:
            if not last_line:
                last_line = line
                continue
            local_deltas.append(line.GetLinePosition().y)
        
        if local_deltas == []:
            continue

        y_deltas.append(_get_mode(local_deltas))
    
    return y_deltas

## Given the y-height delta between two PDFLineFNs, and the line_height (calculated from get_modes_of_line_y_deltas_from_doc()), 
## returns the amount of carriage returns between the PDFLines.
static func get_carriage_returns_from_y_delta(y_delta: float, line_height: float) -> int:
    if y_delta < line_height:
        return 0
    
    return roundi(y_delta / line_height)

static func _get_mode(arr: Array) -> float:
    var occurance_dict: Dictionary = {}
    for element: float in arr:
        occurance_dict[arr.count(element)] = element
    
    var sorted_keys: Array = occurance_dict.keys().duplicate(true)
    sorted_keys.sort()
    return occurance_dict[sorted_keys[-1]]
