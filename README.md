# AHK-v2-libraries
# Useful libraries for AHK v2

## Misc.ahk
Implements useful miscellaneous functions

Range: allows looping from start to end with step.
```
Range(stop)
Range(start, stop [, step ])
```
Usage: `for v in Range(2,10)` -> loops from 2 to 10
`for v in Range(10,1,-1)` -> loops from 10 to 1 backwards


## String.ahk
Implements useful string functions and lets strings be treated as objects

Native AHK functions as methods:
```
String.ToUpper()
      .ToLower()
      .ToTitle()
      .Split([Delimiters, OmitChars, MaxParts])
      .Replace(Needle [, ReplaceText, CaseSense, &OutputVarCount, Limit])
      .Trim([OmitChars])
      .LTrim([OmitChars])
      .RTrim([OmitChars])
      .Compare(comparison [, CaseSense])
      .Sort([, Options, Function])
      .Find(Needle [, CaseSense, StartingPos, Occurrence])
```

```
String[n] => gets nth character
String[i,j] => substring from i to j
String.Length
String.Count(searchFor)
String.Insert(insert, into [, pos])
String.Delete(string [, start, length])
String.Overwrite(overwrite, into [, pos])
String.Repeat(count)
Delimeter.Concat(words*)

String.LineWrap([column:=56, indentChar:=""])
String.WordWrap([column:=56, indentChar:=""])
String.ReadLine(line [, delim:="`n", exclude:="`r"])
String.DeleteLine(line [, delim:="`n", exclude:="`r"])
String.InsertLine(insert, into, line [, delim:="`n", exclude:="`r"])

String.Reverse()
String.Contains(needle1 [, needle2, needle3...])
String.RemoveDuplicates([delim:="`n"])
String.LPad(count)
String.RPad(count)

String.Center([fill:=" ", symFill:=0, delim:="`n", exclude:="`r", width])
String.Right([fill:=" ", delim:="`n", exclude:="`r"])