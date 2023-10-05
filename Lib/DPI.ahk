#Requires AutoHotkey v2

/*
	Name: DPI.ahk
	Version 1.0 (07.09.23)
	Created: 01.09.23
	Author: Descolada

	Description:
	A library meant to standardize coordinates between computers/monitors with different DPIs, including multi-monitor setups. 

    How this works:
    This library, by default, normalizes all output coordinates to 96 DPI (100% scale) and all input coordinates to the DPI of the target window (if CoordMode is Client or Window).
    Accompanied is WindowSpyDpi.ahk which is WindowSpy modified to normalize all coordinates to DPI 96. This can be used to get coordinates for your script. 
    Then use the corresponding DPI.Win... (eg DPI.WinGetPos) variant of the function you wish to use, but using the normalized coordinates. 
    If screen coordinates are used (CoordMode Screen) then usually they don't need to be converted and native functions can be used.
    In addition, when DPI.ahk is used then the DPI awareness of the script is automatically set to monitor-aware. This might break compatibility with existing scripts. 

    For example, using the default CoordMode("Mouse", "Client"), DPI.MouseGetPos(&outX, &outY) will return coordinates scaled to DPI 96 taking account the monitor and window DPIs. 
    Then, DPI.MouseMove(outX, outY) will convert the coordinates back to the proper DPI. This means that the coordinates from DPI.MouseGetPos can be used the same in all computers, all
    monitors, and all multi-monitor setups. 


    DPI.ahk constants:
    DPI.Standard := 96 means than by default the conversion is to DPI 96, but this global variable can be changed to a higher value (eg 960 for 1000% scaling). 
        This may be desired if pixel-perfect accuracy is needed.
    DPI.MaximumPerMonitorDpiAwarenessContext contains either -3 or -4 depending on Windows version
    DPI.DefaultDpiAwarenessContext determines the default DPI awareness which will be set after each Dpi function call, by default it's DPI.MaximumPerMonitorDpiAwarenessContext
    

    DPI.ahk functions:
    DPI.SetThreadAwarenessContext(context)                           =>  Sets DPI awareness of the running script thread to a new context
    DPI.SetProcessAwarenessContext(context)                          =>  Sets DPI awareness of the running process to a new context
    DPI.GetForWindow(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?)  =>  Gets the DPI for the specified window
    DPI.ConvertCoord(&coord, from, to)                               =>  Converts a coordinate from DPI from to DPI to
    DPI.FromStandard(dpi, &x, &y)                                    =>  Converts a point (x,y) from DPI DPI.Standard to the new DPI
    DPI.ToStandard(dpi, &x, &y)                                      =>  Converts a point (x,y) from dpi to DPI.Standard
    DPI.GetMonitorHandles()                                          =>  Returns an array of monitor handles for all active monitors
    DPI.MonitorFromPoint(x, y, CoordMode, flags:=2)                  =>  Gets monitor from a point (if CoordMode is not "screen" then also adjusts for DPI)
    DPI.MonitorFromWindow(WinTitle?, WinText?, flags:=2, ...)        =>  Gets monitor from window
    DPI.GetForMonitor(hMonitor, monitorDpiType := 0)                 =>  Gets the DPI for a specific monitor
    DPI.CoordsToScreen(&X, &Y, CoordMode, WinTitle?, ...)            =>  Converts coordinates X and Y from CoordMode to screen coordinates
    DPI.CoordsToWindow(&X, &Y, CoordMode, WinTitle?, ...)            =>  Converts coordinates X and Y from CoordMode to window coordinates
    DPI.CoordsToClient(&X, &Y, CoordMode, WinTitle?, ...)            =>  Converts coordinates X and Y from CoordMode to client coordinates
    DPI.ScreenToWindow(&X, &Y, hWnd), ScreenToClient(&X, &Y, hWnd), WindowToClient(&X, &Y, hWnd), WindowToScreen(&X, &Y, hWnd), ClientToWindow(&X, &Y, hWnd), ClientToScreen(&X, &Y, hWnd)

    In addition, the following built-in functions are converted:
    DPI.MouseGetPos, MouseMove, MouseClick, MouseClickDrag, Click, WinGetPos, WinGetClientPos, PixelGetColor, PixelSearch, ImageSearch, 
    ControlGetPos, ControlClick

    Notes:
    If AHK has launched a new thread (eg MsgBox) then any new pseudo-thread executing during that (eg user presses hotkey) might revert DPI back to system-aware. 
        Setting DPI awareness for script process and monitoring WM_DPICHANGED message doesn't change that. Source: https://www.autohotkey.com/boards/viewtopic.php?p=310542#p310542
        For this reason, every Dpi function call that depends on coordinates automatically calls DPI.SetThreadDpiAwarenessContext(DPI.DefaultDpiAwarenessContext). This has a slight
        time cost equivalent to ~1 WinGetPos call. Overall, the Dpi functions are ~7-10x slower than the native ones, but still fast (<0.1ms per call in my setup).
*/

class DPI {

static Standard := 96, WM_DPICHANGED := 0x02E0, MaximumPerMonitorDpiAwarenessContext := VerCompare(A_OSVersion, ">=10.0.15063") ? -4 : -3, DefaultDpiAwarenessContext := this.MaximumPerMonitorDpiAwarenessContext

static __New() {
    ; Set DPI awareness of our script to maximum available per-monitor by default
    this.SetThreadAwarenessContext(this.DefaultDpiAwarenessContext)
    ; this.SetMaximumDPIAwareness(1) ; Also set the process DPI awareness?
}

/**
 * Gets the DPI for the specified window
 * @param WinTitle WinTitle, same as built-in
 * @param WinText 
 * @param ExcludeTitle 
 * @param ExcludeText 
 * @returns {Integer} 
 */
static GetForWindow(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    /*
    ; The following only adds added complexity. GetDpiForWindow returns the correct DPI for windows that are monitor-aware. 
    ; For system-aware or unaware programs it returns the FIRST DPI the window got initialized with, so if the window is dragged
    ; onto a second monitor then the DPI becomes invalid. Using MonitorFromWindow + GetForMonitor returns the correct DPI for both aware and unaware windows.
    context := DllCall("GetWindowDpiAwarenessContext", "ptr", hWnd, "ptr")
    if DllCall("GetAwarenessFromDpiAwarenessContext", "ptr", context, "int") = 2 ; If window is not DPI_AWARENESS_SYSTEM_AWARE
        return DllCall("GetDpiForWindow", "ptr", hWnd, "uint")
    ; Otherwise report the monitor DPI the window is currently located in
    */
    return (hMonitor := DllCall("MonitorFromWindow", "ptr", WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), "int", 2, "ptr") ; MONITOR_DEFAULTTONEAREST
    , DllCall("Shcore.dll\GetDpiForMonitor", "ptr", hMonitor, "int", 0, "uint*", &dpiX:=0, "uint*", &dpiY:=0), dpiX)
}

/**
 * Returns an array of handles to monitors in order of monitors
 * @returns {Array} 
 */
static GetMonitorHandles() {
	static EnumProc := CallbackCreate(MonitorEnumProc)
	Monitors := []
	return DllCall("User32\EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", EnumProc, "Ptr", ObjPtr(Monitors), "Int") ? Monitors : false

    MonitorEnumProc(hMonitor, hDC, pRECT, ObjectAddr) {
        Monitors := ObjFromPtrAddRef(ObjectAddr)
        Monitors.Push(hMonitor)
        return true
    }
}

/**
 * Gets a monitor from coordinates (follows CoordMode)
 * @param {Integer} x DPI-adjusted x-coordinate
 * @param {Integer} y DPI-adjusted y-coordinate
 * @param {String} CoordMode The CoordMode to use (provide A_CoordModeMouse, A_CoordModePixel etc)
 * @param {number} flags Determines the function's return value if the point is not contained within any display monitor.
 * Defaults to nearest monitor.
 * MONITOR_DEFAULTTONULL = 0    => Returns 0.
 * MONITOR_DEFAULTTOPRIMARY = 1 => Returns a handle to the primary display monitor. 
 * MONITOR_DEFAULTTONEAREST = 2 => Default. Returns a handle to the display monitor that is nearest to the point.
 * @returns {Integer} Handle to the monitor
 */
static MonitorFromPoint(x, y, CoordMode, flags:=2) {
    this.SetThreadAwarenessContext(this.DefaultDpiAwarenessContext)
    , this.FromStandardExceptCoordModeScreen(CoordMode, &X, &Y)
    , this.CoordsToScreen(&X, &Y, CoordMode, "A")
    return DllCall("MonitorFromPoint", "int64", y << 32 | (x & 0xFFFFFFFF), "int", flags, "ptr")
}
; Gets a monitor from screen coordinates, no conversions done
static MonitorFromPointRaw(x, y, flags:=2) {
    this.SetThreadAwarenessContext(this.DefaultDpiAwarenessContext)
    return DllCall("MonitorFromPoint", "int64", y << 32 | (x & 0xFFFFFFFF), "int", flags, "ptr")
}

/**
 * Gets a monitor from a window
 * @param WinTitle 
 * @param WinText 
 * @param {Integer} flags Determines the function's return value if the point is not contained within any display monitor.
 * Defaults to nearest monitor.
 * MONITOR_DEFAULTTONULL = 0    => Returns 0.
 * MONITOR_DEFAULTTOPRIMARY = 1 => Returns a handle to the primary display monitor. 
 * MONITOR_DEFAULTTONEAREST = 2 => Default. Returns a handle to the display monitor that is nearest to the point.
 * @param ExcludeTitle 
 * @param ExcludeText 
 * @returns {Integer} 
 */
static MonitorFromWindow(WinTitle?, WinText?, flags:=2, ExcludeTitle?, ExcludeText?) => DllCall("MonitorFromWindow", "int", WinExist(WinTitle?, WinText?, ExcludeText?, ExcludeText?), "int", flags, "ptr")

/**
 * Returns the DPI for a certain monitor
 * @param {Integer} hMonitor Handle to the monitor (can be gotten with GetMonitorHandles)
 * @param {Integer} Monitor_Dpi_Type The type of DPI being queried. Can be one of the following:
 *  MDT_EFFECTIVE_DPI = 0 => Default, the effective DPI. This value should be used when determining the correct scale factor for scaling UI elements.
 *  MDT_ANGULAR_DPI = 1 => The angular DPI. This DPI ensures rendering at a compliant angular resolution on the screen. This does not include the scale factor set by the user for this specific display.
 *  MDT_RAW_DPI = 2 => The raw DPI. This value is the linear DPI of the screen as measured on the screen itself.
 * @returns {Integer} 
 */
static GetForMonitor(hMonitor, monitorDpiType := 0) {
	if !DllCall("Shcore\GetDpiForMonitor", "Ptr", hMonitor, "UInt", monitorDpiType, "UInt*", &dpiX:=0, "UInt*", &dpiY:=0, "UInt")
		return dpiX
}

static MouseGetPos(&OutputVarX?, &OutputVarY?, &OutputVarWin?, &OutputVarControl?, Flag?) {
    this.SetThreadAwarenessContext(this.DefaultDpiAwarenessContext)
    , MouseGetPos(&OutputVarX, &OutputVarY, &OutputVarWin, &OutputVarControl, Flag?)
    , this.ToStandardExceptCoordModeScreen(A_CoordModeMouse, &OutputVarX, &OutputVarY)
}

static MouseMove(X, Y, Speed?, Relative?) {
    this.SetThreadAwarenessContext(this.MaximumPerMonitorDpiAwarenessContext)
    , this.FromStandardExceptCoordModeScreen(A_CoordModeMouse, &X, &Y)
    , MouseMove(X, Y, Speed?, Relative?)
}

static MouseClick(WhichButton?, X?, Y?, ClickCount?, Speed?, DownOrUp?, Relative?) {
    this.SetThreadAwarenessContext(this.MaximumPerMonitorDpiAwarenessContext)
    , this.FromStandardExceptCoordModeScreen(A_CoordModeMouse, &X, &Y)
    , MouseClick(WhichButton?, X?, Y?, ClickCount?, Speed?, DownOrUp?, Relative?)
}

static MouseClickDrag(WhichButton?, X1?, Y1?, X2?, Y2?, Speed?, Relative?) {
    this.SetThreadAwarenessContext(this.MaximumPerMonitorDpiAwarenessContext)
    , this.FromStandardExceptCoordModeScreen(A_CoordModeMouse, &X, &Y)
    , MouseClickDrag(WhichButton?, X1?, Y1?, X2?, Y2?, Speed?, Relative?)
}

static Click(Options*) {
    this.SetThreadAwarenessContext(this.MaximumPerMonitorDpiAwarenessContext)
    if Options.Length > 1 && IsInteger(Options[2]) { ; Click(x, y)
        this.FromStandardExceptCoordModeScreen(A_CoordModeMouse, &X:=Options[1], &Y:=Options[2])
        , Options[1]:=X, Options[2]:=Y
    } else { ; Click("x y")
        if RegExMatch(Options[1], "i)\s*(\d+)\s+(\d+)", &regOut:="") {
            this.FromStandardExceptCoordModeScreen(A_CoordModeMouse, &X:=regOut[1], &Y:=regOut[2])
            Options[1] := RegExReplace(Options[1], "i)(\d+)\s+(\d+)", X " " Y)
        }
    }
    Click(Options*)
}

; Useful if window is moved to another screen after getting the position and size
static WinGetPos(&X?, &Y?, &Width?, &Height?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    this.SetThreadAwarenessContext(this.MaximumPerMonitorDpiAwarenessContext)
    , WinGetPos(&X, &Y, &Width, &Height, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?)
    , this.ToStandard(this.GetForWindow(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), &Width, &Height)
}

; Useful if window is moved to another screen after getting the position and size
static WinGetClientPos(&X?, &Y?, &Width?, &Height?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    this.SetThreadAwarenessContext(this.MaximumPerMonitorDpiAwarenessContext)
    , WinGetClientPos(&X, &Y, &Width, &Height, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?)
    , this.ToStandard(this.GetForWindow(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), &Width, &Height)
}

static PixelGetColor(X, Y, Mode := '') {
    return (this.SetThreadAwarenessContext(this.MaximumPerMonitorDpiAwarenessContext)
    , this.FromStandardExceptCoordModeScreen(A_CoordModePixel, &X, &Y), PixelGetColor(X, Y, Mode))
}

static PixelSearch(&OutputVarX, &OutputVarY, X1, Y1, X2, Y2, ColorID, Variation?) {
    this.SetThreadAwarenessContext(this.MaximumPerMonitorDpiAwarenessContext)
    , (out := PixelSearch(&OutputVarX, &OutputVarY, X1, Y1, X2, Y2, ColorID, Variation?)) && this.ToStandardExceptCoordModeScreen(A_CoordModePixel, &OutputVarX, &OutputVarY)
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
static ImageSearch(&OutputVarX, &OutputVarY, X1, Y1, X2, Y2, ImageFile, dpi?, imgDpi?, &imgW?, &imgH?) {
    static oGdip := InitGdip()
    this.SetThreadAwarenessContext(this.MaximumPerMonitorDpiAwarenessContext)
    if !IsSet(dpi)
        dpi := (A_CoordModePixel = "screen") ? A_ScreenDPI : this.GetForWindow("A")

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
            this.ConvertCoord(&imgW, imgDpi, dpi), this.ConvertCoord(&imgH, imgDpi, dpi)
    } else
        imgW := Integer(regOut[1]), imgH := Integer(regOut[2])

    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
        
    if (out := ImageSearch(&OutputVarX, &OutputVarY, X1, Y1, X2, Y2, (dpi != imgDpi ? "*w" imgW " *h" imgH " " : "") ImageFile))
        this.ToStandardExceptCoordModeScreen(A_CoordModePixel, &OutputVarX, &OutputVarY)
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

static ControlGetPos(&OutX?, &OutY?, &OutWidth?, &OutHeight?, Control?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    this.SetThreadAwarenessContext(this.MaximumPerMonitorDpiAwarenessContext)
    , ControlGetPos(&OutX, &OutY, &OutWidth, &OutHeight, Control?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?)
    , this.ToStandard(dpi := this.GetForWindow(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), &OutX, &OutY)
    , this.ToStandard(dpi, &OutWidth, &OutHeight)
}

static ControlClick(ControlOrPos?, WinTitle?, WinText?, WhichButton?, ClickCount?, Options?, ExcludeTitle?, ExcludeText?) {
    this.SetThreadAwarenessContext(this.MaximumPerMonitorDpiAwarenessContext)
    if IsSet(ControlOrPos) && ControlOrPos is String {
        if RegExMatch(ControlOrPos, "i)x\s*(\d+)\s+y\s*(\d+)", &regOut:="") {
            this.FromStandard(this.GetForWindow(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), &x := Integer(regOut[1]), &y := Integer(regOut[2]))
            ControlOrPos := "X" x " Y" y
        }
    }
    ControlClick(ControlOrPos?, WinTitle?, WinText?, WhichButton?, ClickCount?, Options?, ExcludeTitle?, ExcludeText?)
}

; Takes a GUI options string and converts all coordinates from fromDpi (default: DPI.Standard) to targetDpi
; Original author: user hi5, https://autohotkey.com/boards/viewtopic.php?f=6&t=37913
static GuiOptScale(opt, targetDpi, fromDpi := this.Standard) {
    out := ""
    Loop Parse, opt, A_Space A_Tab {
        if RegExMatch(A_LoopField,"i)(w0|h0|h-1|xp|yp|xs|ys|xm|ym)$|(icon|hwnd)") ; these need to be bypassed
            out .= A_LoopField A_Space
        else if RegExMatch(A_LoopField,"i)^\*?(x|xp|y|yp|w|h|s)[-+]?\K(\d+)", &number:="") ; should be processed
            out .= StrReplace(A_LoopField, number[2], this.ConvertCoord(&_:=Integer(number[2]), fromDpi, targetDpi)) A_Space
        else ; the rest can be bypassed as well (variable names etc)
            out .= A_LoopField A_Space
    }
    Return Trim(out)
}

static ToStandardExceptCoordModeScreen(CoordMode, &OutputVarX, &OutputVarY) => (CoordMode = "screen" || this.ToStandard(this.GetForWindow("A"), &OutputVarX, &OutputVarY))
static FromStandardExceptCoordModeScreen(CoordMode, &OutputVarX, &OutputVarY) => (CoordMode = "screen" || this.FromStandard(this.GetForWindow("A"), &OutputVarX, &OutputVarY))
static ConvertCoord(&coord, from, to) => ((IsNumber(coord) && coord := DllCall("MulDiv", "int", coord, "int", to, "int", from, "int")) || coord)

; Convert a point from standard to desired DPI, or vice-versa
static FromStandard(dpi, &x, &y) => (IsInteger(x) && x := DllCall("MulDiv", "int", x, "int", dpi, "int", this.Standard, "int"), IsInteger(y) && y := DllCall("MulDiv", "int", y, "int", dpi, "int", this.Standard, "int"))
static ToStandard(dpi, &x, &y) => (IsInteger(x) && x := DllCall("MulDiv", "int", x, "int", this.Standard, "int", dpi, "int"), IsInteger(y) && y := DllCall("MulDiv", "int", y, "int", this.Standard, "int", dpi, "int"))
static GetScaleFactor(dpi) => Round(dpi / 96, 2)

/**
 * Returns one of the following:
 * DPI_AWARENESS_INVALID = -1,
 * DPI_AWARENESS_UNAWARE = 0,
 * DPI_AWARENESS_SYSTEM_AWARE = 1,
 * DPI_AWARENESS_PER_MONITOR_AWARE = 2
 * @returns {Integer} 
 */
static GetScriptAwareness() => DllCall("GetAwarenessFromDpiAwarenessContext", "ptr", DllCall("GetThreadDpiAwarenessContext", "ptr"), "int")

/**
 * Uses DPI.SetThreadDpiAwarenessContext to set the running scripts' DPI awareness. Returns the previous context, but not in the same format as the
 * following context argument.
 * @param context May be one of the following values:
 *  -1: DPI unaware. Automatically scaled by the system to system-dpi
 *  -2: System DPI aware. Script queries for the DPI once and uses that value for the lifetime of the script.
 *      If the DPI changes, the script will not adjust to the new DPI value.
 *  -3: Per monitor DPI aware. Adjusts the scale factor whenever the DPI changes.
 *  -4: Per Monitor v2. An advancement over the original per-monitor DPI awareness mode, which enables applications 
 *      to access new DPI-related scaling behaviors on a per top-level window basis. Dialogs, non-client areas and themes scale better.
 *  -5: DPI unaware with improved quality of GDI-based content. 
 * @returns {Integer}  
 */
static SetThreadAwarenessContext(context) => DllCall("SetThreadDpiAwarenessContext", "ptr", context, "ptr")
static SetProcessAwarenessContext(context) => DllCall("SetProcessDpiAwarenessContext", "ptr", context, "ptr")

; Converts coordinates to screen coordinates depending on provided CoordMode and window
static CoordsToScreen(&X, &Y, CoordMode, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    this.SetThreadAwarenessContext(this.DefaultDpiAwarenessContext)
    if CoordMode = "screen" {
        return
    } else if CoordMode = "client" {
        this.ClientToScreen(&X, &Y, WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?))
    } else {
        this.WindowToScreen(&X, &Y, WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?))
    }
}
; Converts coordinates to client coordinates depending on provided CoordMode and window
static CoordsToClient(&X, &Y, CoordMode, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    this.SetThreadAwarenessContext(this.DefaultDpiAwarenessContext)
    if CoordMode = "screen" {
        this.ScreenToClient(&X, &Y, WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?))
    } else if CoordMode = "client" {
        return
    } else {
        this.WindowToClient(&X, &Y, WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?))
    }
}
; Converts coordinates to window coordinates depending on provided CoordMode and window
static CoordsToWindow(&X, &Y, CoordMode, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    this.SetThreadAwarenessContext(this.DefaultDpiAwarenessContext)
    if CoordMode = "screen" {
        this.ScreenToWindow(&X, &Y, WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?))
    } else if CoordMode = "client" {
        this.ClientToWindow(&X, &Y, WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?))
    } else {
        return
    }
}

static ClientToScreen(&x, &y, hWnd?) {
    pt := Buffer(8), NumPut("int", x, "int", y, pt)
    DllCall("ClientToScreen", "ptr", hWnd, "ptr", pt)
    x := NumGet(pt, 0, "int"), y := NumGet(pt, 4, "int")
}

static ScreenToClient(&x, &y, hWnd?) {
    pt := Buffer(8), NumPut("int", x, "int", y, pt)
    , DllCall("ScreenToClient", "ptr", hWnd, "ptr", pt)
    , x := NumGet(pt, 0, "int"), y := NumGet(pt, 4, "int")
}

static ScreenToWindow(&x, &y, hWnd?) {
	DllCall("user32\GetWindowRect", "Ptr", hWnd, "Ptr", RECT := Buffer(16,0))
	x := x - NumGet(RECT, 0, "Int"), y := y - NumGet(RECT, 4, "Int")
}

static WindowToScreen(&x, &y, hWnd?) {
	DllCall("user32\GetWindowRect", "Ptr", hWnd, "Ptr", RECT := Buffer(16,0))
	x := x + NumGet(RECT, 0, "Int"), y := y + NumGet(RECT, 4, "Int")
}

static ClientToWindow(&x, &y, hWnd?) {
    this.ClientToScreen(&x, &y, hWnd?)
    this.ScreenToWindow(&x, &y, hWnd?)
}

static WindowToClient(&x, &y, hWnd?) {
    this.WindowToScreen(&x, &y, hWnd?)
    this.ScreenToClient(&x, &y, hWnd?)
}

; The following functions apparently do nothing

static PhysicalToLogicalPointForPerMonitorDPI(&x, &y, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    pt64 := y << 32 | (x & 0xFFFFFFFF)
    DllCall("PhysicalToLogicalPointForPerMonitorDPI", "ptr", IsSet(WinTitle) && IsInteger(WinTitle) ? WinTitle : WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), "int64P", &pt64)
    x := 0xFFFFFFFF & pt64, y := pt64 >> 32
}

static LogicalToPhysicalPointForPerMonitorDPI(&x, &y, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    pt := Buffer(8), NumPut("int", x, "int", y, pt)
    DllCall("LogicalToPhysicalPointForPerMonitorDPI", "ptr", IsSet(WinTitle) && IsInteger(WinTitle) ? WinTitle : WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), "ptr", pt)
    x := NumGet(pt, 0, "int"), y := NumGet(pt, 4, "int")
}

static AdjustWindowRectExForDpi(&x1, &y1, &x2, &y2, dpi) {
    rect := Buffer(16), NumPut("int", x1, "int", y1, "int", x2, "int", y2, rect)
    OutputDebug DllCall("AdjustWindowRectExForDpi", "ptr", rect, "int", 0, "int", 0, "int", 0, "int", dpi) "`n"
    x1 := NumGet(rect, 0, "int"), y1 := NumGet(rect, 4, "int"), x2 := NumGet(rect, 8, "int"), y2 := NumGet(rect, 12, "int")
}

}