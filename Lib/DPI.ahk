#Requires AutoHotkey v2

/*
	Name: DPI.ahk
	Version 0.1 (01.09.23)
	Created: 01.09.23
	Author: Descolada

	Description:
	A library meant to standardize coordinates between computers/monitors with different DPIs, including multi-monitor setups. 

    How this works:
    This library, by default, normalizes all output coordinates to 96 DPI (100% scale) and all input coordinates to the DPI of the target window (if CoordMode is Client or Window).
    Accompanied is WindowSpyDpi.ahk which is WindowSpy modified to normalize all coordinates to DPI 96. This can be used to get coordinates for your script. 
    Then use the corresponding Win...Dpi variant of the function you wish to use, but using the normalized coordinates. 
    If screen coordinates are used (CoordMode Screen) then usually they don't need to be converted and native functions can be used.
    In addition, when DPI.ahk is used then the DPI awareness of the script is automatically set to monitor-aware. This might break compatibility with existing scripts. 

    For example, using the default CoordMode("Mouse", "Client"), MouseGetPosDpi(&outX, &outY) will return coordinates scaled to DPI 96 taking account the monitor and window DPIs. 
    Then, MouseMoveDpi(outX, outY) will convert the coordinates back to the proper DPI. This means that the coordinates from MouseGetPosDpi can be used the same in all computers, all
    monitors, and all multi-monitor setups. 


    DPI.ahk constants:
    A_StandardDpi := 96 means than by default the conversion is to DPI 96, but this global variable can be changed to a higher value (eg 960 for 1000% scaling). 
        This may be desired if pixel-perfect accuracy is needed.

    DPI.ahk functions:
    WinGetDpi(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?)     =>  Gets the DPI for the specified window
    SetMaximumDPIAwareness()                                        =>  Sets script to per-monitor awareness instead of system-aware (which is the DPI of the primary monitor)
    SetScriptAwarenessContext(context)                              =>  Sets DPI awareness of the running script to a new context
    ConvertDpi(&coord, from, to)                                    =>  Converts a coordinate from DPI from to DPI to
    DpiFromStandard(dpi, &x, &y)                                    =>  Converts a point (x,y) from DPI A_StandardDpi to the new DPI
    DpiToStandard(dpi, &x, &y)                                      =>  Converts a point (x,y) from dpi to A_StandardDpi

    In addition, the following built-in functions are converted:
    MouseGetPosDpi, MouseMoveDpi, MouseClickDpi, MouseClickDragDpi, ClickDpi, WinGetPosDpi, WinGetClientPosDpi, PixelGetColorDpi, PixelSearchDpi, ImageSearchDpi, 
    ControlGetPosDpi, ControlClickDpi

    Notes:
    If AHK has launched a new thread (eg MsgBox) then any new pseudo-thread executing during that (eg user presses hotkey) might revert DPI back to system-aware. 
        Setting DPI awareness for script process and monitoring WM_DPICHANGED message doesn't change that. Source: https://www.autohotkey.com/boards/viewtopic.php?p=310542#p310542
*/

global A_StandardDpi := 96, WM_DPICHANGED := 0x02E0
;SetMaximumDPIAwareness(1) ; Also set the process DPI awareness?
SetMaximumDPIAwareness() ; Set DPI awareness of our script to maximum available by default

; Gets the DPI for the specified window
WinGetDpi(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    /*
    ; The following only adds added complexity. GetDpiForWindow returns the correct DPI for windows that are monitor-aware. 
    ; For system-aware or unaware programs it returns the FIRST DPI the window got initialized with, so if the window is dragged
    ; onto a second monitor then the DPI becomes invalid. Using MonitorFromWindow + GetDpiForMonitor returns the correct DPI for both aware and unaware windows.
    context := DllCall("GetWindowDpiAwarenessContext", "ptr", hWnd, "ptr")
    if DllCall("GetAwarenessFromDpiAwarenessContext", "ptr", context, "int") = 2 ; If window is not DPI_AWARENESS_SYSTEM_AWARE
        return DllCall("GetDpiForWindow", "ptr", hWnd, "uint")
    ; Otherwise report the monitor DPI the window is currently located in
    */
    hMonitor := DllCall("MonitorFromWindow", "ptr", WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), "int", 2, "ptr") ; MONITOR_DEFAULTTONEAREST
    DllCall("Shcore.dll\GetDpiForMonitor", "ptr", hMonitor, "int", 0, "uint*", &dpiX:=0, "uint*", &dpiY:=0)
    return dpiX
}

MouseGetPosDpi(&OutputVarX?, &OutputVarY?, &OutputVarWin?, &OutputVarControl?, Flag?) {
    MouseGetPos(&OutputVarX?, &OutputVarY?, &OutputVarWin?, &OutputVarControl?, Flag?)
    DpiToStandardExceptCoordModeScreen(A_CoordModeMouse, &OutputVarX, &OutputVarY)
}

MouseMoveDpi(X, Y, Speed?, Relative?) {
    DpiFromStandardExceptCoordModeScreen(A_CoordModeMouse, &X, &Y)
    , MouseMove(X, Y, Speed?, Relative?)
}

MouseClickDpi(WhichButton?, X?, Y?, ClickCount?, Speed?, DownOrUp?, Relative?) {
    DpiFromStandardExceptCoordModeScreen(A_CoordModeMouse, &X, &Y)
    , MouseClick(WhichButton?, X?, Y?, ClickCount?, Speed?, DownOrUp?, Relative?)
}

MouseClickDragDpi(WhichButton?, X1?, Y1?, X2?, Y2?, Speed?, Relative?) {
    DpiFromStandardExceptCoordModeScreen(A_CoordModeMouse, &X, &Y)
    , MouseClickDrag(WhichButton?, X1?, Y1?, X2?, Y2?, Speed?, Relative?)
}

ClickDpi(Options*) {
    if Options.Length > 1 && IsInteger(Options[2]) { ; Click(x, y)
        DpiFromStandardExceptCoordModeScreen(A_CoordModeMouse, &X:=Options[1], &Y:=Options[2])
        , Options[1]:=X, Options[2]:=Y
    } else { ; Click("x y")
        if RegExMatch(Options[1], "i)\s*(\d+)\s+(\d+)", &regOut:="") {
            DpiFromStandardExceptCoordModeScreen(A_CoordModeMouse, &X:=regOut[1], &Y:=regOut[2])
            Options[1] := RegExReplace(Options[1], "i)(\d+)\s+(\d+)", X " " Y)
        }
    }
    Click(Options*)
}

; Useful if window is moved to another screen after getting the position and size
WinGetPosDpi(&X?, &Y?, &Width?, &Height?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    WinGetPos(&X?, &Y?, &Width?, &Height?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?)
    , DpiToStandard(WinGetDpi(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), &Width, &Height)
}

; Useful if window is moved to another screen after getting the position and size
WinGetClientPosDpi(&X?, &Y?, &Width?, &Height?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    WinGetClientPos(&X?, &Y?, &Width?, &Height?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?)
    , DpiToStandard(WinGetDpi(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), &Width, &Height)
}

PixelGetColorDpi(X, Y, Mode := '') {
    DpiFromStandardExceptCoordModeScreen(A_CoordModePixel, &X, &Y)
    return PixelGetColor(X, Y, Mode)
}

PixelSearchDpi(&OutputVarX, &OutputVarY, X1, Y1, X2, Y2, ColorID, Variation?) {
    out := PixelSearch(&OutputVarX, &OutputVarY, X1, Y1, X2, Y2, ColorID, Variation?)
    if out
        DpiToStandardExceptCoordModeScreen(A_CoordModePixel, &OutputVarX, &OutputVarY)
    return out
}

/**
 * ImageSearch that may work with all DPIs. Higher resolution images usually work better than lower resolution (that is, screenshot with high scaling)
 * OutputVarX, OutputVarY, X1, Y1, X2, Y2, ImageFile are same as native ImageSearch
 * @param OutputVarX 
 * @param OutputVarY 
 * @param X1 
 * @param Y1 
 * @param X2 
 * @param Y2 
 * @param ImageFile 
 * @param dpi Allows specifying the "screen/window DPI". By default if CoordMode Pixel is Screen then A_ScreenDPI is used, otherwise the active windows' DPI
 * @param imgDpi Allows specifying the image DPI, since the DPI recorded in the image file is the one A_ScreenDPI was at the time of the taking. 
 *  In multi-monitor setups the main screen DPI is A_ScreenDPI, but if secondary screen DPI is different and image is captured there, then the wrong DPI is recorded (the primary monitors')
 *  If imgDpi is a VarRef then it's set to the image DPI contained in image info.
 * @param imgW Gets set to the *w option value (eg the width of the image the search is actually performed with)
 *  If screen/window DPI == image DPI then the actual size of the image is returned (since no scaling is necessary)
 * @param imgH Gets set to the *h option value (eg the height of the image the search is actually performed with)
 * @returns {number} 
 */
ImageSearchDpi(&OutputVarX, &OutputVarY, X1, Y1, X2, Y2, ImageFile, dpi?, imgDpi?, &imgW?, &imgH?) {
    static oGdip := InitGdip()

    if !IsSet(dpi)
        dpi := (A_CoordModePixel = "screen") ? A_ScreenDPI : WinGetDpi("A")

    ImgPath := RegExMatch(ImageFile, "i)(?: |^)(?!\*(?:icon|trans|w|h|)[-\d]+)(.+)", &regOut:="") ? regOut[1] : ImageFile
    if !InStr(ImgPath, "\")
        ImgPath := A_WorkingDir "\" ImgPath
    DllCall("gdiplus\GdipCreateBitmapFromFile", "uptr", StrPtr(ImgPath), "uptr*", &pBitmap:=0)
    if IsSet(imgDpi) && imgDpi is VarRef
        imgDpi := %imgDpi%, imgDpi := unset
    if !IsSet(imgDpi)
        DllCall("gdiplus\GdipGetImageHorizontalResolution", "uint", pBitmap, "float*", &imgDpi:=0), imgDpi := Round(imgDpi)

    if !RegExMatch(ImageFile, "i)\*w([-\d]+)\s+\*h([-\d]+)", &regOut:="") {
        DllCall("gdiplus\GdipGetImageWidth", "ptr", pBitmap, "uint*", &imgW:=0)
        DllCall("gdiplus\GdipGetImageHeight", "ptr", pBitmap, "uint*", &imgH:=0)
        if dpi != imgDpi
            ConvertDpi(&imgW, imgDpi, dpi), ConvertDpi(&imgH, imgDpi, dpi)
    } else
        imgW := Integer(regOut[1]), imgH := Integer(regOut[2])

    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
        
    if (out := ImageSearch(&OutputVarX, &OutputVarY, X1, Y1, X2, Y2, (dpi != imgDpi ? "*w" imgW " *h" imgH " " : "") ImageFile))
        DpiToStandardExceptCoordModeScreen(A_CoordModePixel, &OutputVarX, &OutputVarY)
    return out

    InitGdip() {
        if (!DllCall("LoadLibrary", "str", "gdiplus", "UPtr"))
            throw Error("Could not load GDI+ library")
    
        si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
        , NumPut("UInt", 1, si)
        , DllCall("gdiplus\GdiplusStartup", "UPtr*", &pToken:=0, "UPtr", si.Ptr, "UPtr", 0)
        if (!pToken)
            throw Error("Gdiplus failed to start. Please ensure you have gdiplus on your system")
        _oGdip := {}
        , _oGdip.DefineProp("ptr", {value:pToken})
        , _oGdip.DefineProp("__Delete", {call:(this)=> DllCall("gdiplus\GdiplusShutdown", "Ptr", this.Ptr)}) 
        return _oGdip
    }
}

ControlGetPosDpi(&OutX?, &OutY?, &OutWidth?, &OutHeight?, Control?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    ControlGetPos(&OutX?, &OutY?, &OutWidth?, &OutHeight?, Control?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?)
    , DpiToStandard(dpi := WinGetDpi(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), &OutX, &OutY)
    , DpiToStandard(dpi, &OutWidth, &OutHeight)
}

ControlClickDpi(ControlOrPos?, WinTitle?, WinText?, WhichButton?, ClickCount?, Options?, ExcludeTitle?, ExcludeText?) {
    if IsSet(ControlOrPos) && ControlOrPos is String {
        if RegExMatch(ControlOrPos, "i)x\s*(\d+)\s+y\s*(\d+)", &regOut:="") {
            DpiFromStandard(WinGetDpi(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), &x := Integer(regOut[1]), &y := Integer(regOut[2]))
            ControlOrPos := "X" x " Y" y
        }
    }
    ControlClick(ControlOrPos?, WinTitle?, WinText?, WhichButton?, ClickCount?, Options?, ExcludeTitle?, ExcludeText?)
}

DpiToStandardExceptCoordModeScreen(CoordMode, &OutputVarX, &OutputVarY) {
    if CoordMode = "screen"
        return
    DpiToStandard(WinGetDpi("A"), &OutputVarX, &OutputVarY)
}
DpiFromStandardExceptCoordModeScreen(CoordMode, &OutputVarX, &OutputVarY) {
    if CoordMode = "screen"
        return
    DpiFromStandard(WinGetDpi("A"), &OutputVarX, &OutputVarY)
}
ConvertDpi(&coord, from, to) => (coord := IsNumber(coord) ? DllCall("MulDiv", "int", coord, "int", to, "int", from, "int") : coord)

; Convert a point from standard to desired DPI, or vice-versa
DpiFromStandard(dpi, &x, &y) => (x := IsNumber(x) ? DllCall("MulDiv", "int", x, "int", dpi, "int", A_StandardDpi, "int") : x, y := IsNumber(y) ? DllCall("MulDiv", "int", y, "int", dpi, "int", A_StandardDpi, "int") : y)
DpiToStandard(dpi, &x, &y) => (x := IsNumber(x) ? DllCall("MulDiv", "int", x, "int", A_StandardDpi, "int", dpi, "int") : x, y := IsNumber(y) ? DllCall("MulDiv", "int", y, "int", A_StandardDpi, "int", dpi, "int") : y)

; Sets script to per-monitor awareness instead of system-aware (which is the DPI of the primary monitor)
SetMaximumDPIAwareness(process:=0) => SetScriptAwarenessContext(VerCompare(A_OSVersion, ">=10.0.15063") ? -4 : -3, process)

/**
 * Returns one of the following:
 * DPI_AWARENESS_INVALID = -1,
 * DPI_AWARENESS_UNAWARE = 0,
 * DPI_AWARENESS_SYSTEM_AWARE = 1,
 * DPI_AWARENESS_PER_MONITOR_AWARE = 2
 * @returns {Integer} 
 */
GetScriptDpiAwareness() {
    return DllCall("GetAwarenessFromDpiAwarenessContext", "ptr", DllCall("GetThreadDpiAwarenessContext", "ptr"), "int")
}

/**
 * Uses SetThreadDpiAwarenessContext to set the running scripts' DPI awareness. Returns the previous context, but not in the same format as the
 * following context argument.
 * @param context May be one of the following values:
 *  -1: DPI unaware. Automatically scaled by the system to system-dpi
 *  -2: System DPI aware. Script queries for the DPI once and uses that value for the lifetime of the script.
 *      If the DPI changes, the script will not adjust to the new DPI value.
 *  -3: Per monitor DPI aware. Adjusts the scale factor whenever the DPI changes.
 *  -4: Per Monitor v2. An advancement over the original per-monitor DPI awareness mode, which enables applications 
 *      to access new DPI-related scaling behaviors on a per top-level window basis. Dialogs, non-client areas and themes scale better.
 *  -5: DPI unaware with improved quality of GDI-based content. 
 * @param process May be either "thread" (default) or "process"
 * @returns {Integer}  
 */
SetScriptAwarenessContext(context, process:=0) => (process ? DllCall("SetProcessDpiAwarenessContext", "ptr", context, "ptr") : DllCall("SetThreadDpiAwarenessContext", "ptr", context, "ptr"))

ClientToScreen(&x, &y, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    pt := Buffer(8), NumPut("int", x, "int", y, pt)
    DllCall("ClientToScreen", "ptr", IsSet(WinTitle) && IsInteger(WinTitle) ? WinTitle : WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), "ptr", pt)
    x := NumGet(pt, 0, "int"), y := NumGet(pt, 4, "int")
}

ScreenToClient(&x, &y, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    pt := Buffer(8), NumPut("int", x, "int", y, pt)
    DllCall("ScreenToClient", "ptr", IsSet(WinTitle) && IsInteger(WinTitle) ? WinTitle : WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), "ptr", pt)
    x := NumGet(pt, 0, "int"), y := NumGet(pt, 4, "int")
}

; The following functions apparently do nothing

PhysicalToLogicalPointForPerMonitorDPI(&x, &y, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    pt64 := y << 32 | (x & 0xFFFFFFFF)
    DllCall("PhysicalToLogicalPointForPerMonitorDPI", "ptr", IsSet(WinTitle) && IsInteger(WinTitle) ? WinTitle : WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), "int64P", &pt64)
    x := 0xFFFFFFFF & pt64, y := pt64 >> 32
}

LogicalToPhysicalPointForPerMonitorDPI(&x, &y, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    pt := Buffer(8), NumPut("int", x, "int", y, pt)
    DllCall("LogicalToPhysicalPointForPerMonitorDPI", "ptr", IsSet(WinTitle) && IsInteger(WinTitle) ? WinTitle : WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), "ptr", pt)
    x := NumGet(pt, 0, "int"), y := NumGet(pt, 4, "int")
}

AdjustWindowRectExForDpi(&x1, &y1, &x2, &y2, dpi) {
    rect := Buffer(16), NumPut("int", x1, "int", y1, "int", x2, "int", y2, rect)
    OutputDebug DllCall("AdjustWindowRectExForDpi", "ptr", rect, "int", 0, "int", 0, "int", 0, "int", dpi) "`n"
    x1 := NumGet(rect, 0, "int"), y1 := NumGet(rect, 4, "int"), x2 := NumGet(rect, 8, "int"), y2 := NumGet(rect, 12, "int")
}