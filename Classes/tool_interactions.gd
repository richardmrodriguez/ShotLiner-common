## This should handle all the functionality that occurs when a tool needs to be used.
## I think the EditorView take signals and then calls Static Functions to this class
## Or maybe this isn't a class, but just an object, perhaps a child of the EditorView
## This way, this ToolHandler can store its own variables that probably shouldn't be stored in the EditorView anyway

## instead of just a bunch of nested if statements, when a tool is needed, we just emit a TOOL_USED signal, 
## with the relevant mouse index or even just an abstract TOOL_ACTION
## I.E. when drawing a line, we just emit a signal when the drawing starts, moves, and finally ends.
## This means that we can also use different tools while a "main tool" is currently selected
## i.e. if I am drawing with the draw tool, middle-clicking can activate the Move tool, or right-clicking can
## activate the eraser tool or squiggle tool
## or, clicking the toolbar buttons can assign a different tool to different button by clicking on that tool with the specified button
## left clicking the draw tool assigns draw to left click, right clicking move assigns move to right click, etc.

extends Node

class_name ToolHandler