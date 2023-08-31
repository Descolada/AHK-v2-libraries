#Requires AutoHotkey v2.0

; PRE-RELEASE VERSION
; NOT MEANT FOR GENERAL USE

global A_StandardDpi := 96
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

; ImageSearch doesn't work with different screen scalings as the one the image was screenshot from
ImageSearchDpi(&OutputVarX, &OutputVarY, X1, Y1, X2, Y2, ImageFile) {
    if (out := ImageSearch(&OutputVarX, &OutputVarY, X1, Y1, X2, Y2, ImageFile))
        DpiToStandardExceptCoordModeScreen(A_CoordModePixel, &OutputVarX, &OutputVarY)
    return out
}

ControlGetPosDpi(&OutX?, &OutY?, &OutWidth?, &OutHeight?, Control?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    ControlGetPos(&OutX?, &OutY?, &OutWidth?, &OutHeight?, Control?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?)
    , DpiToStandard(dpi := WinGetDpi(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), &OutX, &OutY)
    , DpiToStandard(dpi, &OutWidth, &OutHeight)
}

ControlClickDpi(ControlOrPos?, WinTitle?, WinText?, WhichButton?, ClickCount?, Options?, ExcludeTitle?, ExcludeText?) {
    if IsSet(ControlOrPos) && ControlOrPos is String {
        if RegExMatch(ControlOrPos, "i)x\s*(\d+)\s+y\s*(\d+)", &regOut:="")
            DpiFromStandard(WinGetDpi(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), &x := Integer(regOut[1]), &y := Integer(regOut[2]))
            ControlOrPos := "X" x " Y" y
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
ConvertDpi(&coord, from, to) => (coord := DllCall("MulDiv", "int", coord, "int", to, "int", from, "int"))

; Convert a point from standard to desired DPI, or vice-versa
DpiFromStandard(dpi, &x, &y) => (x := DllCall("MulDiv", "int", x, "int", dpi, "int", A_StandardDpi, "int"), y := DllCall("MulDiv", "int", y, "int", dpi, "int", A_StandardDpi, "int"))
DpiToStandard(dpi, &x, &y) => (x := DllCall("MulDiv", "int", x, "int", A_StandardDpi, "int", dpi, "int"), y := DllCall("MulDiv", "int", y, "int", A_StandardDpi, "int", dpi, "int"))

; Sets script to per-monitor awareness instead of system-aware (which is the DPI of the primary monitor)
SetMaximumDPIAwareness() => SetScriptAwarenessContext(VerCompare(A_OSVersion, ">=10.0.15063") ? -4 : -3)
SetScriptAwarenessContext(context) => DllCall("SetThreadDpiAwarenessContext", "ptr", context, "ptr")

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