/*
	Name: String.ahk
	Version 0.1 (27.08.22)
	Created: 27.08.22
	Author: Descolada
	Credit:
	tidbit		--- Author of "String Things - Common String & Array Functions", from which
					I copied/based a lot of methods
	Contributors to "String Things": AfterLemon, Bon, Lexikos, MasterFocus, Rseding91, Verdlin

	Description:
	A compilation of useful string methods. Also lets strings be treated as objects.

	These methods cannot be used as stand-alone. To do that, you must add another argument
	'string' to the function and replace all occurrences of 'this.string' with 'string'.
	.-==========================================================================-.
	| Methods                                                                    |
	|============================================================================|
	| Native functions as methods:                                               |
	| String.ToUpper()                                                           |
	|       .ToLower()                                                           |
	|       .ToTitle()                                                           |
	|       .Split([Delimiters, OmitChars, MaxParts])                            |
	|       .Replace(Needle [, ReplaceText, CaseSense, &OutputVarCount, Limit])  |
	|       .Trim([OmitChars])                                                   |
	|       .LTrim([OmitChars])                                                  |
	|       .RTrim([OmitChars])                                                  |
	|       .Compare(comparison [, CaseSense])                                   |
	|       .Sort([, Options, Function])                                         |
	|       .Find(Needle [, CaseSense, StartingPos, Occurrence])                 |
	|                                                                            |
	| String[n] => gets nth character                                            |
	| String[i,j] => substring from i to j                                       |
	| String.Length                                                              |
	| String.Count(searchFor)                                                    |
	| String.Insert(insert, into [, pos])                                        |
	| String.Delete(string [, start, length])                                    |
	| String.Overwrite(overwrite, into [, pos])                                  |
	| String.Repeat(count)                                                       |
	| Delimeter.Concat(words*)                                                   |
	|                                                                            |
	| String.LineWrap([column:=56, indentChar:=""])                              |
	| String.WordWrap([column:=56, indentChar:=""])                              |
	| String.ReadLine(line [, delim:="`n", exclude:="`r"])                       |
	| String.DeleteLine(line [, delim:="`n", exclude:="`r"])                     |
	| String.InsertLine(insert, into, line [, delim:="`n", exclude:="`r"])       |
	|                                                                            |
	| String.Reverse()                                                           |
	| String.Contains(needle1 [, needle2, needle3...])                           |
	| String.RemoveDuplicates([delim:="`n"])                                     |
	| String.LPad(count)                                                         |
	| String.RPad(count)                                                         |
	|                                                                            |
	| String.Center([fill:=" ", symFill:=0, delim:="`n", exclude:="`r", width])  |
	| String.Right([fill:=" ", delim:="`n", exclude:="`r"])                      |
	'-==========================================================================-'
*/

; Add String2 methods and properties into String object
ObjDefineProp := Object.Prototype.DefineProp
for f in String2.OwnProps() {
	if !(f ~= "__Init|__Item|Prototype|BindString|Length") {
		if HasMethod(String2, f)
			ObjDefineProp(String.Prototype, f, {call:String2.BindString.Bind(String2, f)})
	}
}
ObjDefineProp(String.Prototype, "__Item", {get:(args*)=>String2.__Item[args*]})
ObjDefineProp(String.Prototype, "Length", {get:(arg)=>String2.Length(arg)})

Class String2 {
	; Necessary for correct autosuggestions in IDE
	static BindString(f, str, args*) {
		this.string := str
		return this.%f%(args*)
	}

	static __Item[args*] {
		get {
			if args.length = 2
				return SubStr(args[1], args[2], 1)
			else {
				if args[3] < 0
					return SubStr(args[1], args[2], StrLen(args[1])-args[2]+args[3]+1)
				else if args[3] = 0
					return SubStr(args[1], args[2])
				else if args[3] < args[2]
					return SubStr(args[1], args[3], args[2]).Reverse()
				else
					return SubStr(args[1], args[2], args[3]-args[2]+1)
			}
		}
	}
	; Native functions implemented as methods for the String object
	static Length(str)    => StrLen(str)
	static ToUpper()      => StrUpper(this.string)
	static ToLower()      => StrLower(this.string)
	static ToTitle()      => StrTitle(this.string)
	static Split(args*)   => StrSplit(this.string, args*)
	static Replace(args*) => StrReplace(this.string, args*)
	static Trim(args*)    => Trim(this.string, args*)
	static LTrim(args*)   => LTrim(this.string, args*)
	static RTrim(args*)   => RTrim(this.string, args*)
	static Compare(args*) => StrCompare(this.string, args*)
	static Sort(args*)    => Sort(this.string, args*)
	static Find(args*)    => InStr(this.string, args*)

	/*
		LPad
		Add character(s) to left side of the input string.

		padding = Text you want to add
		count   = How many times do you want to repeat adding to the left side.

		example: "aaa".LPad("+", 5)
		output: +++++aaa
	*/
	static LPad(padding, count:=1) {
		str := this.string
		if (count>0) {
			Loop count
				str := padding str
		}
		return str
	}
	/*
		RPad
		Add character(s) to right side of the input string.

		padding = Text you want to add
		count   = How many times do you want to repeat adding to the left side.
	*/
	static RPad(padding, count:=1) {
		str := this.string
		if (count>0) {
			Loop count
				str := str padding
		}
		return str
	}
	/*
		Count
		Count the number of occurrences of needle in the string

		input: "12234".Count("2")
		output: 2
	*/
	static Count(needle, caseSensitive:=False) {
		StrReplace(this.string, needle,,caseSensitive, &count)
		return count+1
	}

	/*
		Repeat
		Duplicate the string 'count' times.

		input: "abc".Repeat(3)
		output: "abcabcabc"
	*/
	static Repeat(count) => StrReplace(Format("{:" count "}",""), " ", this.string)

	/*
		Reverse
		Reverse the string.
	*/
	static Reverse() {
		DllCall("msvcrt\_wcsrev", "str", str := this.string, "CDecl str")
		return str
	}

	/*
		Insert
		Insert the string inside 'insert' into position 'pos'

		input: "abc".Insert("d", 2)
		output: "adbc"
	*/
	static Insert(insert, pos:=1) {
		Length := StrLen(this.string)
		((pos > 0) ? (pos2 := pos - 1) : (((pos = 0) ? (pos2 := StrLen(this.string),Length := 0) : (pos2 := pos))))
		output := SubStr(this.string, 1, pos2) . insert . SubStr(this.string, pos, Length)
		if (StrLen(output) > StrLen(this.string) + StrLen(insert))
			((Abs(pos) <= StrLen(this.string)/2) ? (output := SubStr(output, 1, pos2 - 1) . SubStr(output, pos + 1, StrLen(this.string))) : (output := SubStr(output, 1, pos2 - StrLen(insert) - 2) . SubStr(output, pos - StrLen(insert), StrLen(this.string))))
		return output
	}

	/*
		Overwrite
		Replace part of the string with the string in 'overwrite' starting from position 'pos'

		overwrite = Text to insert.
		pos       = The position where to begin overwriting. 0 may be used to overwrite
					at the very end, -1 will offset 1 from the end, and so on.

		input: "aaabbbccc".Overwrite("zzz", 4)
		output: "aaazzzccc"
	*/
	static Overwrite(overwrite, pos:=1) {
	if (Abs(pos) > StrLen(this.string))
		return 0
	else if (pos>0)
		return SubStr(this.string, 1, pos-1) . overwrite . SubStr(this.string, pos+StrLen(overwrite))
	else if (pos<0)
		return SubStr(this.string, 1, pos) . overwrite . SubStr(this.string " ",(Abs(pos) > StrLen(overwrite) ? pos+StrLen(overwrite) : 0), Abs(pos+StrLen(overwrite)))
	else if (pos=0)
		return this.string . overwrite
	}


	/*
		Delete
		Delete a range of characters from the specified string.

		start  = The position where to start deleting.
		length = How many characters to delete.

		input: "aaabbbccc".Delete(4, 3)
		output: "aaaccc"
	*/
	static Delete(start:=1, length:=1) {
		if (Abs(start+length) > StrLen(this.string))
			return ""
		if (start>0)
			return SubStr(this.string, 1, start-1) . SubStr(this.string, start + length)
		else if (start<=0)
			return SubStr(this.string " ", 1, start-length-1) SubStr(this.string " ", ((start<0) ? start : 0), -1)
	}

	/*
		LineWrap
		Wrap the string so each line is never more than a specified length.

		input: "Apples are a round fruit, usually red.".LineWrap(20, "---")
		output: "Apples are a round f
				---ruit, usually red
				---."
	*/
	static LineWrap(column:=56, indentChar:="") {
		string := this.string
		, CharLength := StrLen(indentChar)
		, columnSpan := column - CharLength
		, Ptr := A_PtrSize ? "Ptr" : "UInt"
		, UnicodeModifier := 2
		, VarSetStrCapacity(&out, (StrLen(string) + (Ceil(StrLen(string) / columnSpan) * (column + CharLength + 1)))+2)
		, A := StrPtr(out)

		Loop parse, string, "`n", "`r" {
			if ((FieldLength := StrLen(ALoopField := A_LoopField)) > column) {
				DllCall("RtlMoveMemory", "Ptr", A, "ptr", StrPtr(ALoopField), "UInt", column * UnicodeModifier)
				, A += column * UnicodeModifier
				, NumPut("UShort", 10, A)
				, A += UnicodeModifier
				, Pos := column

				While (Pos < FieldLength) {
					if CharLength
						DllCall("RtlMoveMemory", "Ptr", A, "ptr", StrPtr(indentChar), "UInt", CharLength * UnicodeModifier)
						, A += CharLength * UnicodeModifier

					if (Pos + columnSpan > FieldLength)
						DllCall("RtlMoveMemory", "Ptr", A, "ptr", StrPtr(ALoopField) + (Pos * UnicodeModifier), "UInt", (FieldLength - Pos) * UnicodeModifier)
						, A += (FieldLength - Pos) * UnicodeModifier
						, Pos += FieldLength - Pos
					else
						DllCall("RtlMoveMemory", "Ptr", A, "ptr", StrPtr(ALoopField) + (Pos * UnicodeModifier), "UInt", columnSpan * UnicodeModifier)
						, A += columnSpan * UnicodeModifier
						, Pos += columnSpan

					NumPut("UShort", 10, A)
					, A += UnicodeModifier
				}
			} else
				DllCall("RtlMoveMemory", "Ptr", A, "ptr", StrPtr(ALoopField), "UInt", FieldLength * UnicodeModifier)
				, A += FieldLength * UnicodeModifier
				, NumPut("UShort", 10, A)
				, A += UnicodeModifier
		}
		VarSetStrCapacity(&out, -1)
		return SubStr(out,1, -1)
	}

	/*
		WordWrap
		Wrap the string so each line is never more than a specified length.
		Unlike LineWrap(), this method takes into account words separated by a space.

		input: "Apples are a round fruit, usually red.".WordWrap(20, "---")
		output: "Apples are a round
				---fruit, usually
				---red."
	*/
	static WordWrap(column:=56, indentChar:="") {
		if !IsInteger(column)
			throw TypeError("WordWrap: argument 'column' must be an integer", -2)
		out := ""
		indentLength := StrLen(indentChar)

		Loop parse, this.string, "`n", "`r" {
			if (StrLen(A_LoopField) > column) {
				pos := 1
				Loop parse, A_LoopField, " "
					if (pos + (LoopLength := StrLen(A_LoopField)) <= column)
						out .= (A_Index = 1 ? "" : " ") A_LoopField
						, pos += LoopLength + 1
					else
						pos := LoopLength + 1 + indentLength
						, out .= "`n" indentChar A_LoopField

				out .= "`n"
			} else
				out .= A_LoopField "`n"
		}
		return SubStr(out, 1, -1)
	}

	/*
		InsertLine
		Insert a line of text at the specified line number.
		The line you specify is pushed down 1 and your text is inserted at its
		position. A "line" can be determined by the delimiter parameter. Not
		necessarily just a `r or `n. But perhaps you want a | as your "line".

		insert  = Text you want to insert.
		line    = What line number to insert at. Use a 0 or negative to start
					inserting from the end.
		delim   = The string which defines a "line".
		exclude = The text you want to ignore when defining a line.

		input: "aaa|ccc|ddd".InsertLine("bbb", 2, "|")
		output: "aaa|bbb|ccc|ddd"
	*/
	static InsertLine(insert, line, delim:="`n", exclude:="`r") {
		into := this.string, new := ""
		count := into.Count(delim)

		; Create any lines that don't exist yet, if the Line is less than the total line count.
		if (line<0 && Abs(line)>count) {
			Loop Abs(line)-count
				into := delim into
			line:=1
		}
		if (line == 0)
			line:=Count+1
		if (line<0)
			line:=count+line+1
		; Create any lines that don't exist yet. Otherwise the Insert doesn't work.
		if (count<line)
			Loop line-count
				into.=delim

		Loop parse, into, delim, exclude
			new.=((a_index==line) ? insert . delim . A_LoopField . delim : A_LoopField . delim)

		return RTrim(new, delim)
	}


	/*
		DeleteLine
		Delete a line of text at the specified line number.
		The line you specify is deleted and all lines below it are shifted up.
		A "line" can be determined by the delimiter parameter. Not necessarily
		just a `r or `n. But perhaps you want a | as your "line".

		string  = Text you want to delete the line from.
		line    = What line to delete. You may use -1 for the last line and a negative
					an offset from the last. -2 would be the second to the last.
		delim   = The string which defines a "line".
		exclude = The text you want to ignore when defining a line.

		input: "aaa|bbb|777|ccc".DeleteLine(3, "|")
		output: "aaa|bbb|ccc"
	*/
	static DeleteLine(line, delim:="`n", exclude:="`r") {
		string := this.string, new := ""
		; checks to see if we are trying to delete a non-existing line.
		count:=string.Count(delim)
		if (abs(line)>Count)
			throw Error("DeleteLine: the line number cannot be greater than the number of lines", -2)
		if (line<0)
			line:=count+line+1
		else if (line=0)
			throw Error("DeleteLine: line number cannot be 0", -2)

		Loop parse, string, delim, exclude {
			if (a_index==line) {
				if A_Index == count
					new .= delim
				Continue
			} else
				(new .= A_LoopField . delim)
		}

		return SubStr(new,1,-StrLen(delim))
	}


	/*
		ReadLine
		Read the content of the specified line in a string. A "line" can be
		determined by the delimiter parameter. Not necessarily just a `r or `n.
		But perhaps you want a | as your "line".

		line    = What line to read*.
		delim   = The string which defines a "line".
		exclude = The text you want to ignore when defining a line.

		* For the Line parameter, you may specify the following:
			"L" = The last line.
			"R" = A random line.
			Otherwise specify a number to get that line.
			You may specify a negative number to get the line starting from
			the end. -1 is the same as "L", the last. -2 would be the second to
			the last, and so on.

		input: "aaa|bbb|ccc|ddd|eee|fff".ReadLine(4, "|")
		output: "ddd"
	*/
	static ReadLine(line, delim:="`n", exclude:="`r") {
		string := this.string, out := ""
		count:=String.Count(delim)

		if (line="R")
			line := Random(1, count)
		else if (line="L")
			line := count
		else if abs(line)>Count
			throw Error("ReadLine: the line number cannot be greater than the number of lines", -2)
		else if (line<0)
			line:=count+line+1
		else if (line=0)
			throw Error("ReadLine: line number cannot be 0", -2)

		Loop parse, String, delim, exclude {
			if A_Index = line
				return A_LoopField
		}
		throw Error("ReadLine: something went wrong, the line was not found", -2)
	}

	/*
		RemoveDuplicates
		Replace all consecutive occurrences of 'delim' with only one occurrence.

		input: "aaa|bbb|||ccc||ddd".RemoveDuplicates("|")
		output: "aaa|bbb|ccc|ddd"
	*/
	static RemoveDuplicates(delim:="`n") => RegExReplace(this.string, "(" RegExReplace(delim, "([\\.*?+\[\{|\()^$])", "\$1") ")+", "$1")

	/*
		Contains
		Checks whether the string contains any of the needles provided.

		input: "aaa|bbb|ccc|ddd".Contains("eee", "aaa")
		output: 1 (although the string doesn't contain "eee", it DOES contain "aaa")
	*/
	static Contains(needles*) {
		for needle in needles
			if InStr(this.string, needle)
				return 1
		return 0
	}

	/*
		Center
		Centers a block of text to the longest item in the string.

		text    = The text you would like to center.
		fill    = A single character to use as the padding to center text.
		symFill = 0: Just fill in the left half. 1: Fill in both sides.
		delim   = The string which defines a "line".
		exclude = The text you want to ignore when defining a line.
		width	= Can be specified to add extra padding to the sides


		example: "aaa`na`naaaaaaaa".Center()
		output:  "aaa
				   a
				aaaaaaaa"
	*/
	static Center(fill:=" ", symFill:=0, delim:="`n", exclude:="`r", width?) {
		fill:=SubStr(fill,1,1)
		Loop parse, this.string, delim, exclude
			if (StrLen(A_LoopField)>longest)
				longest:=StrLen(A_LoopField)
		if !IsSet(width)
			longest := Max(longest, width)
		Loop parse, this.string, %delim%, %exclude%
		{
			filled:=""
			Loop (longest-StrLen(A_LoopField))//2
				filled.=fill
			new.= filled A_LoopField ((symFill=1) ? filled : "") "`n"
		}
		return rtrim(new,"`r`n")
	}

	/*
		Right
		Align a block of text to the right side.

		fill    = A single character to use as to push the text to the right.
		delim   = The string which defines a "line".
		exclude = The text you want to ignore when defining a line.

		input: "aaa`na`naaaaaaaa".Right()
		output: "     aaa
		|               a
		|        aaaaaaaa"
	*/
	static Right(fill:=" ", delim:="`n", exclude:="`r") {
		fill:=SubStr(fill,1,1), longest := 0
		Loop parse, this.string, delim, exclude
			if (StrLen(A_LoopField)>longest)
				longest:=StrLen(A_LoopField)
		Loop parse, this.string, delim, exclude {
			filled:=""
			Loop Abs(longest-StrLen(A_LoopField))
				filled.=fill
			new.= filled A_LoopField "`n"
		}
		return RTrim(new,"`r`n")
	}

	/*
		Concat
		Join a list of strings together to form a string separated by delimiter this was called with.

		words*   = A list of strings separated by a comma.

		input: "|".Concat("111", "222", "333", "abc")
		output: "111|222|333|abc"
	*/
	static Concat(words*) {
		delim := this.string, s := ""
		for v in words
			s .= v . delim
		return SubStr(s,1,-StrLen(this.string))
	}
}