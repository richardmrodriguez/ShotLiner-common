using Godot;
using System;
using System.IO;

using System.Collections.Generic;


[GlobalClass]
public partial class PDFDocGD : GodotObject
{
    public Godot.Collections.Array<PDFPage> PDFPages = new();
    public Godot.Collections.Dictionary Scenes = new(); // Scenes[NominalSceneNum] = PagelineUUID
}