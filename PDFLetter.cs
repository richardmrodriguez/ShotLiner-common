using Godot;
using System;
using System.IO;
using System.Collections.Generic;
using Godot.Collections;


[GlobalClass]
public partial class PDFLetter : GodotObject
{
    public string Str = "";
    public Vector2 Location = new();
    public Vector2 GlyphRect = new();
    public float Width = (float)0.0;
    public float FontSize = (float)0.0;
    public float PointSize = (float)0.0;

    public Dictionary GetLetterAsDict()
    {
        Dictionary newDict = new()
        {
            { "string", Str },
            { "location", (string)GD.VarToStr(Location) },
            { "glyphrect", (string)GD.VarToStr(GlyphRect) },
            { "width", Width },
            { "fontsize", FontSize },
            { "pointsize", PointSize }
        };

        return newDict;
    }

    public void SetLetterFromDict(Dictionary LDict)
    {
        Json json = new();
        Str = (string)LDict["string"];

        Location = (Vector2)GD.StrToVar((string)LDict["location"]); // FIXME: TODO - We can only save and load Vector2s by doing VarToStr on save, then StrToVar on load. This isn't necessary for other datatypes for some reason?
        GlyphRect = (Vector2)GD.StrToVar((string)LDict["glyphrect"]);
        Width = (float)LDict["width"];
        FontSize = (float)LDict["fontsize"];
        PointSize = (float)LDict["pointsize"];

    }
}