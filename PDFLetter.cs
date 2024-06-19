using Godot;
using System;
using System.IO;
using System.Collections.Generic;


[GlobalClass]
public partial class PDFLetter : GodotObject
{
    public string Str = "";
    public Vector2 Location = new();
    public Vector2 GlyphRect = new();
    public float Width = (float)0.0;
    public float FontSize = (float)0.0;
    public float PointSize = (float)0.0;
}