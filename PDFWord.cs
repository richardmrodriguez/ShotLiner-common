using Godot;
using System;
using Godot.Collections;
using UglyToad.PdfPig.Content;


[GlobalClass]
public partial class PDFWord : GodotObject
{
    public Array<PDFLetter> PDFLetters = new();

    public Vector2 WordPos = new();
    public Vector2 WordBBox = new();
    // TODO; Implement GetWordBBox which constructs the BBox from the size and pos of its letters

    public string GetWordString()
    {
        string newString = "";
        foreach (PDFLetter letter in PDFLetters)
        {
            newString += letter.Str;

        }
        return newString;
    }

    public Vector2 GetPosition()
    {
        if (PDFLetters.Count == 0)
        {
            GD.Print(" NO LETTERS");
            return new Vector2();
        }
        return PDFLetters[0].Location;
    }

    private Vector2 GetWordBBoxFromLetters()
    {
        // TODO: Implement
        return new Vector2();
    }

    public Dictionary GetWordAsDict()
    {
        Godot.Collections.Array<Dictionary> lettersArray = new();
        foreach (PDFLetter lt in PDFLetters)
        {
            lettersArray.Add(lt.GetLetterAsDict());
        }

        Dictionary WordDict = new()
        {
            {"pdfletters",lettersArray},
            {"wordpos", (string)GD.VarToStr(WordPos)},
            {"wordbbox", (string)GD.VarToStr(WordBBox)}
        };

        return WordDict;
    }



    public void SetWordFromDict(Dictionary WordDict)
    {
        PDFLetters = new();
        foreach (Dictionary NLDict in (Array<Dictionary>)WordDict["pdfletters"])
        {
            PDFLetter NewLetter = new();
            NewLetter.SetLetterFromDict(NLDict);
            PDFLetters.Add(NewLetter);
        }
        WordPos = (Vector2)GD.StrToVar((string)WordDict["wordpos"]);
        WordBBox = (Vector2)GD.StrToVar((string)WordDict["wordbbox"]);

    }



}