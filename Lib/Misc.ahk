/*
	Name: Misc.ahk
	Version 1.0.1 (11.11.24)
	Created: 26.08.22
	Author: Descolada (https://www.autohotkey.com/boards/viewtopic.php?f=83&t=107759)
    Credit: Coco

	Range(stop)						=> Returns an iterable to count from 1..stop
	Range(start, stop [, step])		=> Returns an iterable to count from start to stop with step
	Swap(&a, &b)					=> Swaps the values of a and b
	Printer(func?) 					=> Create a function that will print a string with the given function or to a string.
	RegExMatchAll(haystack, needleRegEx [, startingPosition := 1])
	    Returns all RegExMatch results (RegExMatchInfo objects) for needleRegEx in haystack 
		in an array: [RegExMatchInfo1, RegExMatchInfo2, ...]
	Highlight(x?, y?, w?, h?, showTime:=0, color:="Red", d:=2)
		Highlights an area with a colorful border.
	MouseTip(x?, y?, color1:="red", color2:="blue", d:=4)
		Flashes a colorful highlight at a point for 2 seconds.
	WindowFromPoint(X, Y) 			=> Returns the window ID at screen coordinates X and Y.
	ConvertCoords(X, Y, &outX, &outY, relativeFrom:=A_CoordModeMouse, relativeTo:="screen", winTitle?, winText?, excludeTitle?, excludeText?)
		Converts coordinates between screen, window and client.
	WinGetInfo(WinTitle:="", Verbose := 1, WinText:="", ExcludeTitle:="", ExcludeText:="", Separator := "`n")
		Gets info about a window (title, process name, location etc).
	WinWaitNew(WinTitle:="", WinText:="", TimeOut:="", ExcludeTitle:="", ExcludeText:="")
		Waits for a new instance of a window matching the criteria.
	GetCaretPos(&X?, &Y?, &W?, &H?)
		Gets the position of the caret with CaretGetPos, Acc, Java Access Bridge or UIA.
	IntersectRect(l1, t1, r1, b1, l2, t2, r2, b2)
		Checks whether two rectangles intersect and if they do, then returns an object containing the
		rectangle of the intersection: {l:left, t:top, r:right, b:bottom}
	WinGetPosEx(WinTitle:="", &X := "", &Y := "", &Width := "", &Height := "", &LeftBorder := 0, &TopBorder := 0, &RightBorder := 0, &BottomBorder := 0)
		Returns the window coordinates based on visible attributes of the window (Border arguments are set 
		to the corresponding thickness of the invisible DWM borders).
	WinMoveEx(X?, Y?, Width?, Height?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?)
		Moves the window based on the visual attributes of the window (adjusts for invisible DWM borders).
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
 * Create a function that will print a string with the given function or to a string.
 * OutputFunc and Newline can be changed later on by modifying the property with the same name.
 * @param OutputFunc The function to print the string. Default is no function (simply returns a string).
 * @param NewLine New line separator added to the end of the string. Default is `n
 * @returns {Func}
 * @example 
 * 	MB := Printer(MsgBox)
 * 	MB([1,2,3])
 */
class Printer {
	__New(OutputFunc:=0, Newline := "`n") => (this.Newline := Newline, this.OutputFunc := OutputFunc)
	Call(val?) => ((str := !IsSet(val) || IsObject(val) ? ToString(val?) this.Newline : val this.Newline), this.OutputFunc ? this.OutputFunc.Call(str) : str)
}

/**
 * Converts a value (number, array, object) to a string.
 * @param value Optional: the value to convert. 
 * @returns {String}
 */
ToString(val?) {
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
            try self := ToString(val.ToString()) ; if the object has ToString available, print it
            if valType != "Array" { ; enumerate object with key and value pair, except for array
                try {
                    enum := val.__Enum(2) 
                    while (enum.Call(&val1, &val2))
                        iter .= ToString(val1) ":" ToString(val2?) ", "
                }
            }
            if !IsSet(enum) { ; if enumerating with key and value failed, try again with only value
                try {
                    enum := val.__Enum(1)
                    while (enum.Call(&enumVal))
                        iter .= ToString(enumVal?) ", "
                }
            }
            if !IsSet(enum) && (valType = "Object") && !self { ; if everything failed, enumerate Object props
                for k, v in val.OwnProps()
                    iter .= SubStr(ToString(k), 2, -1) ":" ToString(v?) ", "
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

/**
 * Returns all RegExMatch results in an array: [RegExMatchInfo1, RegExMatchInfo2, ...]
 * @param haystack The string whose content is searched.
 * @param needleRegEx The RegEx pattern to search for.
 * @param startingPosition If StartingPos is omitted, it defaults to 1 (the beginning of haystack).
 * @returns {Array}
 */
RegExMatchAll(haystack, needleRegEx, startingPosition := 1) {
	out := [], end := StrLen(haystack)+1
	While startingPosition < end && RegExMatch(haystack, needleRegEx, &outputVar, startingPosition)
		out.Push(outputVar), startingPosition := outputVar.Pos + (outputVar.Len || 1)
	return out
}

/**
 * Highlights an area with a colorful border. If called without arguments then all highlightings
 * are removed. This function also supports named parameters.
 * @param x Screen X-coordinate of the top left corner of the highlight
 * @param y Screen Y-coordinate of the top left corner of the highlight
 * @param w Width of the highlight
 * @param h Height of the highlight
 * @param showTime Can be one of the following:
 * * Unset - if highlighting exists then removes the highlighting, otherwise highlights for 2 seconds. This is the default value.
 * * 0 - Indefinite highlighting 
 * * Positive integer (eg 2000) - will highlight and pause for the specified amount of time in ms
 * * Negative integer - will highlight for the specified amount of time in ms, but script execution will continue
 * * "clear" - removes the highlighting unconditionally
 * @param color The color of the highlighting. Default is red.
 * @param d The border thickness of the highlighting in pixels. Default is 2.
 */
Highlight(x?, y?, w?, h?, showTime?, color:="Red", d:=2) {
	static guis := Map(), timers := Map()
	if IsSet(x) { ; if x is set then check whether a highlight already exists at those coords
		if IsObject(x) {
			d := x.HasOwnProp("d") ? x.d : d, color := x.HasOwnProp("color") ? x.color : color, showTime := x.HasOwnProp("showTime") ? x.showTime : showTime
			, h := x.HasOwnProp("h") ? x.h : h, w := x.HasOwnProp("w") ? x.w : h, y := x.HasOwnProp("y") ? x.y : y, x := x.HasOwnProp("x") ? x.x : unset
		}
		if !(IsSet(x) && IsSet(y) && IsSet(w) && IsSet(h))
			throw ValueError("x, y, w and h arguments must all be provided for a highlight", -1)
		for k, v in guis {
			if k.x = x && k.y = y && k.w = w && k.h = h { ; highlight exists, so either remove it, or update
				if !IsSet(showTime) || (IsSet(showTime) && showTime = "clear")
					TryRemoveTimer(k), TryDeleteGui(k)
				else if showTime = 0
					TryRemoveTimer(k)
				else if IsInteger(showTime) {
					if showTime < 0 {
						if !timers.Has(k)
							timers[k] := Highlight.Bind(x,y,w,h)
						SetTimer(timers[k], showTime)
					} else {
						TryRemoveTimer(k)
						Sleep showTime
						TryDeleteGui(k)
					}
				} else
					throw ValueError('Invalid showTime value "' (!IsSet(showTime) ? "unset" : IsObject(showTime) ? "{Object}" : showTime) '"', -1)
				return
			}
		}
	} else { ; if x is not set (eg Highlight()) then delete all highlights
		for k, v in timers
			SetTimer(v, 0)
		for k, v in guis
			v.Destroy()
		guis := Map(), timers := Map()
		return
	}
	
	if (showTime := showTime ?? 2000) = "clear"
		return
	else if !IsInteger(showTime)
		throw ValueError('Invalid showTime value "' (!IsSet(showTime) ? "unset" : IsObject(showTime) ? "{Object}" : showTime) '"', -1)

	; Otherwise this is a new highlight
	loc := {x:x, y:y, w:w, h:h}
	guis[loc] := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000")
	GuiObj := guis[loc]
	GuiObj.BackColor := color
	iw:= w+d, ih:= h+d, w:=w+d*2, h:=h+d*2, x:=x-d, y:=y-d
	WinSetRegion("0-0 " w "-0 " w "-" h " 0-" h " 0-0 " d "-" d " " iw "-" d " " iw "-" ih " " d "-" ih " " d "-" d, GuiObj.Hwnd)
	GuiObj.Show("NA x" . x . " y" . y . " w" . w . " h" . h)

	if showTime > 0 {
		Sleep(showTime)
		TryDeleteGui(loc)
	} else if showTime < 0
		SetTimer(timers[loc] := Highlight.Bind(loc.x,loc.y,loc.w,loc.h), showTime)

	TryRemoveTimer(key) {
		if timers.Has(key)
			SetTimer(timers[key], 0), timers.Delete(key)
	}
	TryDeleteGui(key) {
		if guis.Has(key)
			guis[key].Destroy(), guis.Delete(key)
	}
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
	return DllCall("GetAncestor", "ptr", DllCall("user32.dll\WindowFromPoint", "Int64", Y << 32 | X, "ptr"), "UInt", 2)
}

/**
 * Converts coordinates between screen, window and client.
 * @param X X-coordinate to convert
 * @param Y Y-coordinate to convert
 * @param outX Variable where to store the converted X-coordinate
 * @param outY Variable where to store the converted Y-coordinate
 * @param relativeFrom CoordMode where to convert from. Default is A_CoordModeMouse.
 * @param relativeTo CoordMode where to convert to. Default is Screen.
 * @param winTitle A window title or other criteria identifying the target window. 
 * @param winText If present, this parameter must be a substring from a single text element of the target window.
 * @param excludeTitle Windows whose titles include this value will not be considered.
 * @param excludeText Windows whose text include this value will not be considered.
 */
ConvertCoords(X, Y, &outX, &outY, relativeFrom:="", relativeTo:="screen", winTitle?, winText?, excludeTitle?, excludeText?) {
	relativeFrom := relativeFrom || A_CoordModeMouse
	if relativeFrom = relativeTo {
		outX := X, outY := Y
		return
	}
	hWnd := WinExist(winTitle?, winText?, excludeTitle?, excludeText?)

	switch relativeFrom, 0 {
		case "screen", "s":
			if relativeTo = "window" || relativeTo = "w" {
				DllCall("user32\GetWindowRect", "Int", hWnd, "Ptr", RECT := Buffer(16))
				outX := X-NumGet(RECT, 0, "Int"), outY := Y-NumGet(RECT, 4, "Int")
			} else { 
				; screen to client
				pt := Buffer(8), NumPut("int",X,pt), NumPut("int",Y,pt,4)
				DllCall("ScreenToClient", "Int", hWnd, "Ptr", pt)
				outX := NumGet(pt,0,"int"), outY := NumGet(pt,4,"int")
			}
		case "window", "w":
			; window to screen
			WinGetPos(&outX, &outY,,,hWnd)
			outX += X, outY += Y
			if relativeTo = "client" || relativeTo = "c" {
				; screen to client
				pt := Buffer(8), NumPut("int",outX,pt), NumPut("int",outY,pt,4)
				DllCall("ScreenToClient", "ptr", hWnd, "Ptr", pt)
				outX := NumGet(pt,0,"int"), outY := NumGet(pt,4,"int")
			}
		case "client", "c":
			; client to screen
			pt := Buffer(8), NumPut("int",X,pt), NumPut("int",Y,pt,4)
			DllCall("ClientToScreen", "ptr", hWnd, "Ptr", pt)
			outX := NumGet(pt,0,"int"), outY := NumGet(pt,4,"int")
			if relativeTo = "window" || relativeTo = "w" { ; screen to window
				DllCall("user32\GetWindowRect", "ptr", hWnd, "ptr", RECT := Buffer(16))
				outX -= NumGet(RECT, 0, "Int"), outY -= NumGet(RECT, 4, "Int")
			}
	}
}
ConvertWinPos(X, Y, &outX, &outY, relativeFrom:="", relativeTo:="screen", winTitle?, winText?, excludeTitle?, excludeText?) => ConvertCoords(X, Y, &outX, &outY, relativeFrom, relativeTo, winTitle?, winText?, excludeTitle?, excludeText?)

/**
 * Gets info about a window (title, process name, location etc)
 * @param WinTitle Same as AHK WinTitle
 * @param {number} Verbose How verbose the output should be (default is 1):
 *  0: Returns window title, hWnd, class, process name, PID, process path, screen position, min-max info, styles and ex-styles
 *  1: Additionally returns TransColor, transparency level, text (both hidden and not), statusbar text
 *  2: Additionally returns ClassNN names for all controls
 * @param WinText Same as AHK WinText
 * @param ExcludeTitle Same as AHK ExcludeTitle
 * @param ExcludeText Same as AHK ExcludeText
 * @param {string} Separator Linebreak character(s)
 * @returns {string} The info as a string. 
 * @example MsgBox(WinGetInfo("ahk_exe notepad.exe", 2))
 */
WinGetInfo(WinTitle:="", Verbose := 1, WinText:="", ExcludeTitle:="", ExcludeText:="", Separator := "`n") {
    if !(hWnd := WinExist(WinTitle, WinText, ExcludeTitle, ExcludeText))
        throw TargetError("Target window not found!", -1)
    out := 'Title: '
    try out .= '"' WinGetTitle(hWnd) '"' Separator
    catch
        out .= "#ERROR" Separator
    out .=  'ahk_id ' hWnd Separator
    out .= 'ahk_class '
    try out .= WinGetClass(hWnd) Separator
    catch
        out .= "#ERROR" Separator
    out .= 'ahk_exe '
    try out .= WinGetProcessName(hWnd) Separator
    catch
        out .= "#ERROR" Separator
    out .= 'ahk_pid '
    try out .= WinGetPID(hWnd) Separator
    catch
        out .= "#ERROR" Separator
    out .= 'ProcessPath: '
    try out .= '"' WinGetProcessPath(hWnd) '"' Separator
    catch
        out .= "#ERROR" Separator
    out .= 'Screen position: '
    try { 
        WinGetPos(&X, &Y, &W, &H, hWnd)
        out .= "x: " X " y: " Y " w: " W " h: " H Separator
    } catch
        out .= "#ERROR" Separator
    out .= 'MinMax: '
    try out .= ((minmax := WinGetMinMax(hWnd)) = 1 ? "maximized" : minmax = -1 ? "minimized" : "normal") Separator
    catch
        out .= "#ERROR" Separator

    static Styles := Map("WS_OVERLAPPED", 0x00000000, "WS_POPUP", 0x80000000, "WS_CHILD", 0x40000000, "WS_MINIMIZE", 0x20000000, "WS_VISIBLE", 0x10000000, "WS_DISABLED", 0x08000000, "WS_CLIPSIBLINGS", 0x04000000, "WS_CLIPCHILDREN", 0x02000000, "WS_MAXIMIZE", 0x01000000, "WS_CAPTION", 0x00C00000, "WS_BORDER", 0x00800000, "WS_DLGFRAME", 0x00400000, "WS_VSCROLL", 0x00200000, "WS_HSCROLL", 0x00100000, "WS_SYSMENU", 0x00080000, "WS_THICKFRAME", 0x00040000, "WS_GROUP", 0x00020000, "WS_TABSTOP", 0x00010000, "WS_MINIMIZEBOX", 0x00020000, "WS_MAXIMIZEBOX", 0x00010000, "WS_TILED", 0x00000000, "WS_ICONIC", 0x20000000, "WS_SIZEBOX", 0x00040000, "WS_OVERLAPPEDWINDOW", 0x00CF0000, "WS_POPUPWINDOW", 0x80880000, "WS_CHILDWINDOW", 0x40000000, "WS_TILEDWINDOW", 0x00CF0000, "WS_ACTIVECAPTION", 0x00000001, "WS_GT", 0x00030000)
    , ExStyles := Map("WS_EX_DLGMODALFRAME", 0x00000001, "WS_EX_NOPARENTNOTIFY", 0x00000004, "WS_EX_TOPMOST", 0x00000008, "WS_EX_ACCEPTFILES", 0x00000010, "WS_EX_TRANSPARENT", 0x00000020, "WS_EX_MDICHILD", 0x00000040, "WS_EX_TOOLWINDOW", 0x00000080, "WS_EX_WINDOWEDGE", 0x00000100, "WS_EX_CLIENTEDGE", 0x00000200, "WS_EX_CONTEXTHELP", 0x00000400, "WS_EX_RIGHT", 0x00001000, "WS_EX_LEFT", 0x00000000, "WS_EX_RTLREADING", 0x00002000, "WS_EX_LTRREADING", 0x00000000, "WS_EX_LEFTSCROLLBAR", 0x00004000, "WS_EX_CONTROLPARENT", 0x00010000, "WS_EX_STATICEDGE", 0x00020000, "WS_EX_APPWINDOW", 0x00040000, "WS_EX_OVERLAPPEDWINDOW", 0x00000300, "WS_EX_PALETTEWINDOW", 0x00000188, "WS_EX_LAYERED", 0x00080000, "WS_EX_NOINHERITLAYOUT", 0x00100000, "WS_EX_NOREDIRECTIONBITMAP", 0x00200000, "WS_EX_LAYOUTRTL", 0x00400000, "WS_EX_COMPOSITED", 0x02000000, "WS_EX_NOACTIVATE", 0x08000000)
    out .= 'Style: '
    try {
        out .= (style := WinGetStyle(hWnd)) " ("
        for k, v in Styles {
            if v && style & v {
                out .= k " | "
                style &= ~v
            }
        }
        out := RTrim(out, " |")
        if style
            out .= (SubStr(out, -1, 1) = "(" ? "" : ", ") "Unknown enum: " style
        out .= ")" Separator
    } catch
        out .= "#ERROR" Separator

        out .= 'ExStyle: '
        try {
            out .= (style := WinGetExStyle(hWnd)) " ("
            for k, v in ExStyles {
                if v && style & v {
                    out .= k " | "
                    style &= ~v
                }
            }
            out := RTrim(out, " |")
            if style
                out .= (SubStr(out, -1, 1) = "(" ? "" : ", ") "Unknown enum: " style
            out .= ")" Separator
        } catch
            out .= "#ERROR" Separator

    
    if Verbose {
        out .= 'TransColor: '
        try out .= WinGetTransColor(hWnd) Separator
        catch
            out .= "#ERROR" Separator
        out .= 'Transparent: '
        try out .= WinGetTransparent(hWnd) Separator
        catch
            out .= "#ERROR" Separator

        PrevDHW := DetectHiddenText(0)
        out .= 'Text (DetectHiddenText Off): '
        try out .= '"' WinGetText(hWnd) '"' Separator
        catch
            out .= "#ERROR" Separator
        DetectHiddenText(1)
        out .= 'Text (DetectHiddenText On): '
        try out .= '"' WinGetText(hWnd) '"' Separator
        catch
            out .= "#ERROR" Separator
        DetectHiddenText(PrevDHW)

        out .= 'StatusBar Text: '
        try out .= '"' StatusBarGetText(1, hWnd) '"' Separator
        catch
            out .= "#ERROR" Separator
    }
    if Verbose > 1 {
        out .= 'Controls (ClassNN): ' Separator
        try {
            for ctrl in WinGetControls(hWnd)
                out .= '`t' ctrl Separator
        } catch
            out .= "#ERROR" Separator
    }
    return SubStr(out, 1, -StrLen(Separator))
}

/**
 * Waits for a new instance of a window matching the criteria. 
 * Arguments match the format of WinWait.
 * @example
 * w := WinWaitNew("ahk_exe chrome.exe")
 * Run "chrome.exe"
 * w()
 * MsgBox "Chrome found"
 * @returns {Integer} 
 */
class WinWaitNew {
    Tick := 1
    __New(WinTitle:="", WinText:="", TimeOut:="", ExcludeTitle:="", ExcludeText:="") {
        local hWnd, hWnds
		this.hWnds := hWnds := Map(), this.TimeOut := TimeOut="" ? 0x7FFFFFFFFFFFFFFF : A_TickCount+1000*TimeOut
        this.WinTitle := WinTitle, this.WinText := WinText, this.ExcludeTitle := ExcludeTitle, this.ExcludeText := ExcludeText
		for hWnd in WinGetList(WinTitle, WinText, ExcludeTitle, ExcludeText)
			hWnds[hWnd] := 1
    }
    Call() {
        local hWnd
        while this.TimeOut > A_TickCount {
            for hWnd in WinGetList(this.WinTitle, this.WinText, this.ExcludeTitle, this.ExcludeText)
                if !this.hWnds.Has(hWnd)
                    return hWnd
            Sleep this.Tick
        }
        throw TimeoutError("Timeout exceeded", -1)
    }
}

/**
 * Gets the position of the caret with UIA, Acc, Java Access Bridge, or CaretGetPos.
 * Credit: plankoe (https://www.reddit.com/r/AutoHotkey/comments/ysuawq/get_the_caret_location_in_any_program/)
 * @param X Value is set to the screen X-coordinate of the caret
 * @param Y Value is set to the screen Y-coordinate of the caret
 * @param W Value is set to the width of the caret
 * @param H Value is set to the height of the caret
 */
GetCaretPos(&X?, &Y?, &W?, &H?) {
	/*
		This implementation prefers CaretGetPos > Acc > JAB > UIA. This is mostly due to speed differences
		between the methods and statistically it seems more likely that the UIA method is required the
		least (Chromium apps support Acc as well).
	*/
    ; Default caret
    savedCaret := A_CoordModeCaret
    CoordMode "Caret", "Screen"
    CaretGetPos(&X, &Y)
    CoordMode "Caret", savedCaret
	if IsInteger(X) && (X | Y) != 0 {
		W := 4, H := 20
		return
	}

    ; Acc caret
    static _ := DllCall("LoadLibrary", "Str","oleacc", "Ptr")
    try {
        idObject := 0xFFFFFFF8 ; OBJID_CARET
        if DllCall("oleacc\AccessibleObjectFromWindow", "ptr", WinExist("A"), "uint",idObject &= 0xFFFFFFFF
            , "ptr",-16 + NumPut("int64", idObject == 0xFFFFFFF0 ? 0x46000000000000C0 : 0x719B3800AA000C81, NumPut("int64", idObject == 0xFFFFFFF0 ? 0x0000000000020400 : 0x11CF3C3D618736E0, IID := Buffer(16)))
            , "ptr*", oAcc := ComValue(9,0)) = 0 {
            x:=Buffer(4), y:=Buffer(4), w:=Buffer(4), h:=Buffer(4)
            oAcc.accLocation(ComValue(0x4003, x.ptr, 1), ComValue(0x4003, y.ptr, 1), ComValue(0x4003, w.ptr, 1), ComValue(0x4003, h.ptr, 1), 0)
            X:=NumGet(x,0,"int"), Y:=NumGet(y,0,"int"), W:=NumGet(w,0,"int"), H:=NumGet(h,0,"int")
            if (X | Y) != 0
                return
        }
    }

	static JAB := InitJAB() ; Source: https://github.com/Elgin1/Java-Access-Bridge-for-AHK
	if JAB && (hWnd := WinExist("A")) && DllCall(JAB.module "\isJavaWindow", "ptr", hWnd, "CDecl Int") {
		if JAB.firstRun
			Sleep(200), JAB.firstRun := 0
		prevThreadDpiAwarenessContext := DllCall("SetThreadDpiAwarenessContext", "ptr", -2, "ptr")
		DllCall(JAB.module "\getAccessibleContextWithFocus", "ptr", hWnd, "Int*", &vmID:=0, JAB.acType "*", &ac:=0, "Cdecl Int") "`n"
		DllCall(JAB.module "\getCaretLocation", "Int", vmID, JAB.acType, ac, "Ptr", Info := Buffer(16,0), "Int", 0, "Cdecl Int")
		DllCall(JAB.module "\releaseJavaObject", "Int", vmId, JAB.acType, ac, "CDecl")
		DllCall("SetThreadDpiAwarenessContext", "ptr", prevThreadDpiAwarenessContext, "ptr")
		X := NumGet(Info, 0, "Int"), Y := NumGet(Info, 4, "Int"), W := NumGet(Info, 8, "Int"), H := NumGet(Info, 12, "Int")
		hMonitor := DllCall("MonitorFromWindow", "ptr", hWnd, "int", 2, "ptr") ; MONITOR_DEFAULTTONEAREST
    	DllCall("Shcore.dll\GetDpiForMonitor", "ptr", hMonitor, "int", 0, "uint*", &dpiX:=0, "uint*", &dpiY:=0)
		if dpiX
			X := DllCall("MulDiv", "int", X, "int", dpiX, "int", 96, "int"), Y := DllCall("MulDiv", "int", Y, "int", dpiX, "int", 96, "int")
		if X || Y || W || H
			return
	}

    ; UIA caret
    static IUIA := ComObject("{e22ad333-b25f-460c-83d0-0581107395c9}", "{34723aff-0c9d-49d0-9896-7ab52df8cd8a}")
    try {
        ComCall(8, IUIA, "ptr*", &FocusedEl:=0) ; GetFocusedElement
		/*
			The current implementation uses only TextPattern GetSelections and not TextPattern2 GetCaretRange.
			This is because TextPattern2 is less often supported, or sometimes reports being implemented
			but in reality is not. The only downside to using GetSelections is that when text
			is selected then caret position is ambiguous. Nevertheless, in those cases it most
			likely doesn't matter much whether the caret is in the beginning or end of the selection.

			If GetCaretRange is needed then the following code implements that:
			ComCall(16, FocusedEl, "int", 10024, "ptr*", &patternObject:=0), ObjRelease(FocusedEl) ; GetCurrentPattern. TextPattern2 = 10024
			if patternObject {
				ComCall(10, patternObject, "int*", &IsActive:=1, "ptr*", &caretRange:=0), ObjRelease(patternObject) ; GetCaretRange
				ComCall(10, caretRange, "ptr*", &boundingRects:=0), ObjRelease(caretRange) ; GetBoundingRectangles
				if (Rect := ComValue(0x2005, boundingRects)).MaxIndex() = 3 { ; VT_ARRAY | VT_R8
					X:=Round(Rect[0]), Y:=Round(Rect[1]), W:=Round(Rect[2]), H:=Round(Rect[3])
					return
				}
			}
		*/
        ComCall(16, FocusedEl, "int", 10014, "ptr*", &patternObject:=0), ObjRelease(FocusedEl) ; GetCurrentPattern. TextPattern = 10014
        if patternObject {
            ComCall(5, patternObject, "ptr*", &selectionRanges:=0), ObjRelease(patternObject) ; GetSelections
			ComCall(4, selectionRanges, "int", 0, "ptr*", &selectionRange:=0) ; GetElement
			ComCall(6, selectionRange, "int", 0) ; ExpandToEnclosingUnit = Character
            ComCall(10, selectionRange, "ptr*", &boundingRects:=0), ObjRelease(selectionRange), ObjRelease(selectionRanges) ; GetBoundingRectangles
            if (Rect := ComValue(0x2005, boundingRects)).MaxIndex() = 3 { ; VT_ARRAY | VT_R8
                X:=Round(Rect[0]), Y:=Round(Rect[1]), W:=Round(Rect[2]), H:=Round(Rect[3])
                return
            }
        }
    }

	InitJAB() {
		ret := {}, ret.firstRun := 1, ret.module := A_PtrSize = 8 ? "WindowsAccessBridge-64.dll" : "WindowsAccessBridge-32.dll", ret.acType := "Int64"
		ret.DefineProp("__Delete", {call: (this) => DllCall("FreeLibrary", "ptr", this)})
		if !(ret.ptr := DllCall("LoadLibrary", "Str", ret.module, "ptr")) && A_PtrSize = 4 {
			 ; try legacy, available only for 32-bit
			 ret.acType := "Int", ret.module := "WindowsAccessBridge.dll", ret.ptr := DllCall("LoadLibrary", "Str", ret.module, "ptr")
		}
		if !ret.ptr
			return ; Failed to load library. Make sure you are running the script in the correct bitness and/or Java for the architecture is installed.
		DllCall(ret.module "\Windows_run", "Cdecl Int")
		return ret
	}
}

/**
 * Checks whether two rectangles intersect and if they do, then returns an object containing the
 * rectangle of the intersection: {l:left, t:top, r:right, b:bottom}
 * Note 1: Overlapping area must be at least 1 unit. 
 * Note 2: Second rectangle starting at the edge of the first doesn't count as intersecting:
 *     {l:100, t:100, r:200, b:200} does not intersect {l:200, t:100, 400, 400}
 * @param l1 x-coordinate of the upper-left corner of the first rectangle
 * @param t1 y-coordinate of the upper-left corner of the first rectangle
 * @param r1 x-coordinate of the lower-right corner of the first rectangle
 * @param b1 y-coordinate of the lower-right corner of the first rectangle
 * @param l2 x-coordinate of the upper-left corner of the second rectangle
 * @param t2 y-coordinate of the upper-left corner of the second rectangle
 * @param r2 x-coordinate of the lower-right corner of the second rectangle
 * @param b2 y-coordinate of the lower-right corner of the second rectangle
 * @returns {Object}
 */
IntersectRect(l1, t1, r1, b1, l2, t2, r2, b2) {
	rect1 := Buffer(16), rect2 := Buffer(16), rectOut := Buffer(16)
	NumPut("int", l1, "int", t1, "int", r1, "int", b1, rect1)
	NumPut("int", l2, "int", t2, "int", r2, "int", b2, rect2)
	if DllCall("user32\IntersectRect", "Ptr", rectOut, "Ptr", rect1, "Ptr", rect2)
		return {l:NumGet(rectOut, 0, "Int"), t:NumGet(rectOut, 4, "Int"), r:NumGet(rectOut, 8, "Int"), b:NumGet(rectOut, 12, "Int")}
}

/**
 * Gets the position, size, and offset of a window. See the *Remarks* section for more information.
 * Source: https://www.autohotkey.com/boards/viewtopic.php?f=6&t=3392
 * Additional credits: original idea and some code from *KaFu* (AutoIt forum)
 * @param WinTitle Target window title or handle
 * @param X Optional: contains the screen x-coordinate of the window
 * @param Y Optional: contains the screen y-coordinate of the window
 * @param Width Optional: contains the width of the window
 * @param Height Optional: contains the height of the window
 * @param LeftBorder Optional: thickness of the invisible left border
 * @param TopBorder Optional: thickness of the invisible top border
 * @param RightBorder Optional: thickness of the invisible right border
 * @param BottomBorder Optional: thickness of the invisible bottom border
 * @returns {Integer} Returns 0 if failed, otherwise the window handle
 * 
 * Remarks:
 * 
 * Starting with Windows Vista, Microsoft includes the Desktop Window Manager
 * (DWM) along with Aero-based themes that use DWM.  Aero themes provide new
 * features like a translucent glass design with subtle window animations.
 * Unfortunately, the DWM doesn't always conform to the OS rules for size and
 * positioning of windows.  If using an Aero theme, many of the windows are
 * actually larger than reported by Windows when using standard commands (Ex:
 * WinGetPos, GetWindowRect, etc.) and because of that, are not positioned
 * correctly when using standard commands (Ex: Gui.Show, WinMove, etc.).  This
 * function was created to 1) identify the true position and size of all
 * windows regardless of the window attributes, desktop theme, or version of
 * Windows and to 2) identify the appropriate offset that is needed to position
 * the window if the window is a different size than reported.
 * 
 * The true size, position, and offset of a window cannot be determined until
 * the window has been rendered.  See the example script for an example of how
 * to use this function to position a new window.
 */
WinGetPosEx(WinTitle:="", &X := "", &Y := "", &Width := "", &Height := "", &LeftBorder := 0, &TopBorder := 0, &RightBorder := 0, &BottomBorder := 0) {
	static S_OK := 0x0, DWMWA_EXTENDED_FRAME_BOUNDS := 9
	local RECT := Buffer(16, 0), RECTPlus := Buffer(24,0), R, B
	if !(WinTitle is Integer)
		WinTitle := WinGetID(WinTitle)
	DllCall("GetWindowRect", "Ptr", WinTitle, "Ptr", RECT)
	try DWMRC := DllCall("dwmapi\DwmGetWindowAttribute", "Ptr",  WinTitle, "UInt", DWMWA_EXTENDED_FRAME_BOUNDS, "Ptr", RECTPlus, "UInt", 16, "UInt")
	catch
	   return 0
	X := NumGet(RECTPlus, 0, "Int"), LeftBorder := X - NumGet(RECT, 0, "Int")
	Y := NumGet(RECTPlus, 4, "Int"), TopBorder := Y - NumGet(RECT, 4, "Int")
	R := NumGet(RECTPlus, 8, "Int"), RightBorder := NumGet(RECT,  8, "Int") - R
	B := NumGet(RECTPlus, 12, "Int"), BottomBorder := NumGet(RECT,  12, "Int") - B
	Width := R - X
	Height := B - Y
	return WinTitle
}

/**
 * Moves the window based on the visual attributes of the window (adjusts for invisible borders).
 * @param X If omitted, the position in the X dimension will not be changed. Otherwise, specify 
 * the X coordinate (in pixels) of the upper left corner of the target window's new location. 
 * The upper-left pixel of the screen is at 0, 0.
 * @param Y If omitted, the position in the Y dimension will not be changed. Otherwise, specify 
 * the Y coordinate (in pixels) of the upper left corner of the target window's new location. 
 * The upper-left pixel of the screen is at 0, 0.
 * @param Width If omitted, the width will not be changed. Otherwise, specify the new width of the window (in pixels).
 * @param Height If omitted, the height will not be changed. Otherwise, specify the new height of the window (in pixels).
 * @param WinTitle WinTitle, same as normal WinMove
 * @param WinText Same as normal WinMove
 * @param ExcludeTitle Same as normal WinMove
 * @param ExcludeText Same as normal WinMove
 */
WinMoveEx(X?, Y?, Width?, Height?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
	WinGetPosEx(hWnd := WinGetID(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?),,,,, &LeftBorder := 0, &TopBorder := 0, &RightBorder := 0, &BottomBorder := 0)
	if IsSet(X)
		X -= LeftBorder
	if IsSet(Y)
		Y -= TopBorder
	if IsSet(Width)
		Width += LeftBorder + RightBorder
	if IsSet(Height)
		Height += TopBorder + BottomBorder
	return WinMove(X?, Y?, Width?, Height?, hWnd)
}