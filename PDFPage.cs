using Godot;
using System;
using System.IO;
using System.Collections.Generic;
using Godot.Collections;

[GlobalClass]
public partial class PDFPage : GodotObject
{
    public string NominalPageNum = ""; // page number could be 3A, for example
    public Vector2 PageSizeInPoints = new();
    public Godot.Collections.Array<PDFLineFN> PDFLines = new(); // horizontal lines of text, with fountain line type (?)


}