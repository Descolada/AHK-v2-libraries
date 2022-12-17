/*
	Name: Misc.ahk
	Version 0.2 (15.10.22)
	Created: 26.08.22
	Author: Descolada (https://www.autohotkey.com/boards/viewtopic.php?f=83&t=107759)
    Credit: Coco

	Range(stop)						=> Returns an iterable to count from 1..stop
	Range(start, stop [, step])		=> Returns an iterable to count from start to stop with step
	Swap(&a, &b)					=> Swaps the values of a and b
	Print(value?, func?, newline?) 	=> Prints the formatted value of a variable (number, string, array, map, object)
	RegExMatchAll(Haystack, NeedleRegEx [, StartingPosition := 1])
	    Returns all RegExMatch results (RegExMatchInfo objects) for NeedleRegEx in Haystack 
		in an array: [RegExMatchInfo1, RegExMatchInfo2, ...]
	Highlight(x?, y?, w?, h?, showTime:=0, color:="Red", d:=2)
		Highlights an area with a colorful border.
	MouseTip(x?, y?, color1:="red", color2:="blue", d:=4)
		Flashes a colorful highlight at a point for 2 seconds.
	WindowFromPoint(X, Y) 			=> Returns the window ID at screen coordinates X and Y.
	ConvertWinPos(X, Y, &OutX, &OutY, RelativeFrom:=A_CoordModeMouse, RelativeTo:="screen", WinTitle?, WinText?, ExcludeTitle?, ExcludeText?)
		Converts coordinates between screen, window and client.
*/

/**
 * Returns a sequence of numbers, starting from 1 by default, 
 * and increments by step 1 (by default), 
 * and stops at a specified end number.
 * Can be converted to an array with the method ToArray()
 * @param start The number to start with, or if 'end' is omitted then the number to end with
 * @param end The number to end with
 * @param step Optional: a number specifying the incrementation. Default is 1.
 * @returns {Iterable}
 * @example 
 * for v in Range(5)
 *     Print(v) ; Outputs "1 2 3 4 5"
 */
class Range {
	__New(start, end?, step:=1) {
		if !step
			throw TypeError("Invalid 'step' parameter")
		if !IsSet(end)
			end := start, start := 1
		if (end < start) && (step > 0)
			step := -step
		this.start := start, this.end := end, this.step := step
	}
	__Enum(varCount) {
		start := this.start - this.step, end := this.end, step := this.step, counter := 0
		EnumElements(&element) {
			start := start + step
			if ((step > 0) && (start > end)) || ((step < 0) && (start < end))
				return false
			element := start
			return true
		}
		EnumIndexAndElements(&index, &element) {
			start := start + step
			if ((step > 0) && (start > end)) || ((step < 0) && (start < end))
				return false
			index := ++counter
			element := start
			return true
		}
		return (varCount = 1) ? EnumElements : EnumIndexAndElements
	}
	/**
	 * Converts the iterable into an array.
	 * @returns {Array}
	 * @example
	 * Range(3).ToArray() ; returns [1,2,3]
	 */
	ToArray() {
		r := []
		for v in this
			r.Push(v)
		return r
	}
}

/**
 * Swaps the values of two variables
 * @param a First variable
 * @param b Second variable
 */
Swap(&a, &b) {
	temp := a
	a := b
	b := temp
}

/**
 * Prints the formatted value of a variable (number, string, object).
 * Leaving all parameters empty will return the current function and newline in an Array: [func, newline]
 * @param value Optional: the variable to print. 
 *     If omitted then new settings (output function and newline) will be set.
 *     If value is an object/class that has a ToString() method, then the result of that will be printed.
 * @param func Optional: the print function to use. Default is OutputDebug.
 *     Not providing a function will cause the Print output to simply be returned as a string.
 * @param newline Optional: the newline character to use (applied to the end of the value). 
 *     Default is newline (`n).
 */
Print(value?, func?, newline?) {
	static p := OutputDebug, nl := "`n"
	if IsSet(func)
		p := func
	if IsSet(newline)
		nl := newline
	if IsSet(value) {
		val := IsObject(value) ? _Print(value) nl : value nl
		return HasMethod(p) ? p(val) : val
	}
	return [p, nl]

	_Print(val?) {
		if !IsSet(val)
			return "unset"
		valType := Type(val)
		switch valType, 0 {
			case "String":
				return "'" val "'"
			case "Integer", "Float":
				return val
			default:
				self := "", iter := "", out := ""
				try self := _Print(val.ToString()) ; if the object has ToString available, print it
				if valType != "Array" { ; enumerate object with key and value pair, except for array
					try {
						enum := val.__Enum(2) 
						while (enum.Call(&val1, &val2))
							iter .= _Print(val1) ":" _Print(val2?) ", "
					}
				}
				if !IsSet(enum) { ; if enumerating with key and value failed, try again with only value
					try {
						enum := val.__Enum(1)
						while (enum.Call(&enumVal))
							iter .= _Print(enumVal?) ", "
					}
				}
				if !IsSet(enum) && (valType = "Object") && !self { ; if everything failed, enumerate Object props
					for k, v in val.OwnProps()
						iter .= SubStr(_Print(k), 2, -1) ":" _Print(v?) ", "
				}
				iter := SubStr(iter, 1, StrLen(iter)-2)
				if !self && !iter && !((valType = "Array" && val.Length = 0) || (valType = "Map" && val.Count = 0) || (valType = "Object" && ObjOwnPropCount(val) = 0))
					return valType ; if no additional info is available, only print out the type
				else if self && iter
					out .= "value:" self ", iter:[" iter "]"
				else
					out .= self iter
				return (valType = "Object") ? "{" out "}" : (valType = "Array") ? "[" out "]" : valType "(" out ")"
		}
	}
}

/**
 * Returns all RegExMatch results in an array: [RegExMatchInfo1, RegExMatchInfo2, ...]
 * @param Haystack The string whose content is searched.
 * @param NeedleRegEx The RegEx pattern to search for.
 * @param StartingPosition If StartingPos is omitted, it defaults to 1 (the beginning of Haystack).
 * @returns {Array}
 */
RegExMatchAll(Haystack, NeedleRegEx, StartingPosition := 1) {
	out := []
	While StartingPosition := RegExMatch(Haystack, NeedleRegEx, &OutputVar, StartingPosition) {
		out.Push(OutputVar), StartingPosition += OutputVar[0] ? StrLen(OutputVar[0]) : 1
	}
	return out
}

/**
 * Highlights an area with a colorful border.
 * @param x Screen X-coordinate of the top left corner of the highlight
 * @param y Screen Y-coordinate of the top left corner of the highlight
 * @param w Width of the highlight
 * @param h Height of the highlight
 * @param showTime Can be one of the following:
 *     0 - removes the highlighting
 *     Positive integer (eg 2000) - will highlight and pause for the specified amount of time in ms
 *     Negative integer - will highlight for the specified amount of time in ms, but script execution will continue
 * @param color The color of the highlighting. Default is red.
 * @param d The border thickness of the highlighting in pixels. Default is 2.
 */
Highlight(x?, y?, w?, h?, showTime:=0, color:="Red", d:=2) {
	static guis := []
	for _, r in guis
		r.Destroy()
	guis := []
	if !IsSet(x)
		return
	Loop 4
		guis.Push(Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000"))
	Loop 4 {
		i:=A_Index
		, x1:=(i=2 ? x+w : x-d)
		, y1:=(i=3 ? y+h : y-d)
		, w1:=(i=1 or i=3 ? w+2*d : d)
		, h1:=(i=2 or i=4 ? h+2*d : d)
		guis[i].BackColor := color
		guis[i].Show("NA x" . x1 . " y" . y1 . " w" . w1 . " h" . h1)
	}
	if showTime > 0 {
		Sleep(showTime)
		Highlight()
	} else if showTime < 0
		SetTimer(Highlight, -Abs(showTime))
}

/**
 * Flashes a colorful highlight at a point for 2 seconds.
 * @param x Screen X-coordinate for the highlight
 *     Omit x or y to highlight the current cursor position.
 * @param y Screen Y-coordinate for the highlight
 * @param color1 First color for the highlight. Default is red.
 * @param color2 Second color for the highlight. Default is blue.
 * @param d The border thickness of the highlighting in pixels. Default is 2.
 */
MouseTip(x?, y?, color1:="red", color2:="blue", d:=4) {
	If !(IsSet(x) && IsSet(y))
		MouseGetPos(&x, &y)
	Loop 2 {
		Highlight(x-10, y-10, 20, 20, 500, color1, d)
		Highlight(x-10, y-10, 20, 20, 500, color2, d)
	}
	Highlight()
}

/**
 * Returns the window ID at screen coordinates X and Y. 
 * @param X Screen X-coordinate of the point
 * @param Y Screen Y-coordinate of the point
 */
WindowFromPoint(X, Y) { ; by SKAN and Linear Spoon
	return DllCall("GetAncestor", "UInt", DllCall("user32.dll\WindowFromPoint", "Int64", Y << 32 | X), "UInt", 2)
}

/**
 * Converts coordinates between screen, window and client.
 * @param X X-coordinate to convert
 * @param Y Y-coordinate to convert
 * @param OutX Variable where to store the converted X-coordinate
 * @param OutY Variable where to store the converted Y-coordinate
 * @param RelativeFrom CoordMode where to convert from. Default is A_CoordModeMouse.
 * @param RelativeTo CoordMode where to convert to. Default is Screen.
 * @param WinTitle A window title or other criteria identifying the target window. 
 * @param WinText If present, this parameter must be a substring from a single text element of the target window.
 * @param ExcludeTitle Windows whose titles include this value will not be considered.
 * @param ExcludeText Windows whose text include this value will not be considered.
 */
ConvertWinPos(X, Y, &OutX, &OutY, RelativeFrom:="", RelativeTo:="screen", WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
	RelativeFrom := (RelativeFrom == "") ? A_CoordModeMouse : RelativeFrom
	if RelativeFrom = RelativeTo {
		OutX := X, OutY := Y
		return
	}
	hWnd := WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?)

	switch RelativeFrom, 0 {
		case "screen", "s":
			if RelativeTo = "window" || RelativeTo = "w" {
				DllCall("user32\GetWindowRect", "Int", hWnd, "Ptr", RECT := Buffer(16))
				OutX := X-NumGet(RECT, 0, "Int"), OutY := Y-NumGet(RECT, 4, "Int")
			} else { 
				; screen to client
				pt := Buffer(8), NumPut("int",X,pt), NumPut("int",Y,pt,4)
				DllCall("ScreenToClient", "Int", hWnd, "Ptr", pt)
				OutX := NumGet(pt,0,"int"), OutY := NumGet(pt,4,"int")
			}
		case "window", "w":
			; window to screen
			WinGetPos(&OutX, &OutY,,,hWnd)
			OutX += X, OutY += Y
			if RelativeTo = "client" || RelativeTo = "c" {
				; screen to client
				pt := Buffer(8), NumPut("int",OutX,pt), NumPut("int",OutY,pt,4)
				DllCall("ScreenToClient", "Int", hWnd, "Ptr", pt)
				OutX := NumGet(pt,0,"int"), OutY := NumGet(pt,4,"int")
			}
		case "client", "c":
			; client to screen
			pt := Buffer(8), NumPut("int",X,pt), NumPut("int",Y,pt,4)
			DllCall("ClientToScreen", "Int", hWnd, "Ptr", pt)
			OutX := NumGet(pt,0,"int"), OutY := NumGet(pt,4,"int")
			if RelativeTo = "window" || RelativeTo = "w" { ; screen to window
				DllCall("user32\GetWindowRect", "Int", hWnd, "Ptr", RECT := Buffer(16))
				OutX -= NumGet(RECT, 0, "Int"), OutY -= NumGet(RECT, 4, "Int")
			}
	}
}