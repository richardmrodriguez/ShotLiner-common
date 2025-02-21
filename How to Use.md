# Basic Usage 

This module is a simple wrapper for the UglyToad PDFPig library, with a specific focus on Screenplay PDFs.

`PDFIngester` provides access to the `'GetDocGD` function, which returns a `PDFDocGD` object. This is a Godot object, and can be used immediately in GDScript.

`PDFDocGD` is composed of `PDFPage`s.

`PDFPage`s are composed of `PDFLineFN`s.

Each `PDFLineFN` is composed of `PDFWord`s.

Finally, each `PDFWord` is composed of `PDFLetter`s.

Each `PDFLetter` has `Str` string which represents the unicode value, as well as `Location`, `FontSize`, `PointSize`, `Width` and `GlyphRect`.

The `Location` of each `PDFLetter`, and therefore any text element, is calculated  with 0, 0 being the *bottom left* of a PDF Page, whereas
in Godot (0, 0) starts at the top left of a Window. This y-axis conversion must be accounted for by the user of this wrapper (or most any
other PDF Parsing / creation library, for that matter.)