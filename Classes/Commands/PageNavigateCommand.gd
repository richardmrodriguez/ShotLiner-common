extends Command

class_name PageNavigateCommand

var new_page_idx: int
var old_page_idx: int

func execute() -> bool:
    
    new_page_idx = params.front()
    old_page_idx = params.back()

    var pages: Array[PageContent] = ScreenplayDocument.pages
    if 0 <= new_page_idx&&new_page_idx < pages.size():
        EventStateManager.cur_page_idx = new_page_idx
        print(pages.size())
        EventStateManager.page_node.replace_current_page(
            pages[EventStateManager.cur_page_idx],
            EventStateManager.cur_page_idx
        )
        print("Current shotlines: ", ScreenplayDocument.shotlines)
        
        return true
    return false

func undo() -> bool:
    print("undoing page nav......")
    var pages: Array[PageContent] = ScreenplayDocument.pages
    EventStateManager.cur_page_idx = old_page_idx
    EventStateManager.page_node.replace_current_page(
            pages[old_page_idx],
            old_page_idx
    )
    return true