; 
; Window Spy for AHKv2
;

#Requires AutoHotkey v2.0

#NoTrayIcon
#SingleInstance Ignore
SetWorkingDir A_ScriptDir
CoordMode "Pixel", "Screen"

Global oGui, A_StandardDpi := 96

WinSpyGui()

WinSpyGui() {
    Global oGui
    
    try TraySetIcon "inc\spy.ico"
    DllCall("shell32\SetCurrentProcessExplicitAppUserModelID", "wstr", "AutoHotkey.WindowSpy")
    
    oGui := Gui("AlwaysOnTop Resize MinSize +DPIScale","Window Spy for AHKv2")
    oGui.OnEvent("Close",WinSpyClose)
    oGui.OnEvent("Size",WinSpySize)
    
    oGui.Add("Text",,"Window Title, Class and Process:")
    oGui.Add("Checkbox","yp xp+200 w120 Right vCtrl_FollowMouse","Follow Mouse").Value := 1
    oGui.Add("Edit","xm w320 r5 ReadOnly -Wrap vCtrl_Title")
    oGui.Add("Text",,"Mouse Position")
    oGui.Add("Checkbox","yp xp+115 w80 Right vCtrl_DPIAware","DPI Aware").Value := 1
    ToggleDPIAwarenessContext(oGui["Ctrl_DPIAware"])
    oGui["Ctrl_DPIAware"].OnEvent("Click", ToggleDPIAwarenessContext)
    oGui.Add("Checkbox","yp xp+85 w125 Right vCtrl_DPINormalized","DPI Normalized To " A_StandardDpi).Value := 1
    oGui.Add("Edit","xm w320 r4 ReadOnly vCtrl_MousePos")
    oGui.Add("Text","w200 vCtrl_CtrlLabel",(txtFocusCtrl := "Focused Control") ":")
    oGui.Add("Edit","w320 r4 ReadOnly vCtrl_Ctrl")
    oGui.Add("Text",,"Active Window Postition:")
    oGui.Add("Edit","w320 r2 ReadOnly vCtrl_Pos")
    oGui.Add("Text",,"Status Bar Text:")
    oGui.Add("Edit","w320 r2 ReadOnly vCtrl_SBText")
    oGui.Add("Checkbox","vCtrl_IsSlow","Slow TitleMatchMode")
    oGui.Add("Text",,"Visible Text:")
    oGui.Add("Edit","w320 r2 ReadOnly vCtrl_VisText")
    oGui.Add("Text",,"All Text:")
    oGui.Add("Edit","w320 r2 ReadOnly vCtrl_AllText")
    oGui.Add("Text","w320 r1 vCtrl_Freeze",(txtNotFrozen := "(Hold Ctrl or Shift to suspend updates)"))
    
    oGui.Show("NoActivate")
    WinGetClientPos(&x_temp, &y_temp2,,,"ahk_id " oGui.hwnd)
    
    ; oGui.horzMargin := x_temp*96//A_ScreenDPI - 320 ; now using oGui.MarginX
    
    oGui.txtNotFrozen := txtNotFrozen       ; create properties for futur use
    oGui.txtFrozen    := "(Updates suspended)"
    oGui.txtMouseCtrl := "Control Under Mouse Position"
    oGui.txtFocusCtrl := txtFocusCtrl
    
    SetTimer Update, 250
}

WinSpySize(GuiObj, MinMax, Width, Height) {
    Global oGui
    
    If !oGui.HasProp("txtNotFrozen") ; WinSpyGui() not done yet, return until it is
        return
    
    SetTimer Update, (MinMax=0)?250:0 ; suspend updates on minimize
    
    ctrlW := Width - (oGui.MarginX * 2) ; ctrlW := Width - horzMargin
    list := "Title,MousePos,Ctrl,Pos,SBText,VisText,AllText,Freeze"
    Loop Parse list, ","
        oGui["Ctrl_" A_LoopField].Move(,,ctrlW)
}

ToggleDPIAwarenessContext(CtrlObj, *) {
    static MaximumDPIAwarenessContext := VerCompare(A_OSVersion, ">=10.0.15063") ? -4 : -3, RestoreDPIAwareness
    RestoreDPIAwareness := DllCall("SetThreadDpiAwarenessContext", "ptr", CtrlObj.Value ? MaximumDPIAwarenessContext : RestoreDPIAwareness)
}

WinSpyClose(GuiObj) {
    ExitApp
}

Update() { ; timer, no params
    Try TryUpdate() ; Try
}

TryUpdate() {
    Global oGui
    
    If !oGui.HasProp("txtNotFrozen") ; WinSpyGui() not done yet, return until it is
        return
    
    Ctrl_FollowMouse := oGui["Ctrl_FollowMouse"].Value
    CoordMode "Mouse", "Screen"
    MouseGetPos &msX, &msY, &msWin, &msCtrl, 2 ; get ClassNN and hWindow
    actWin := WinExist("A")
    
    if (Ctrl_FollowMouse) {
        curWin := msWin, curCtrl := msCtrl
        WinExist("ahk_id " curWin) ; updating LastWindowFound?
    } else {
        curWin := actWin
        curCtrl := ControlGetFocus() ; get focused control hwnd from active win
    }
    curCtrlClassNN := ""
    Try curCtrlClassNN := ControlGetClassNN(curCtrl)
    
    t1 := WinGetTitle(), t2 := WinGetClass()
    if (curWin = oGui.hwnd || t2 = "MultitaskingViewFrame") { ; Our Gui || Alt-tab
        UpdateText("Ctrl_Freeze", oGui.txtFrozen)
        return
    }
    
    UpdateText("Ctrl_Freeze", oGui.txtNotFrozen)
    t3 := WinGetProcessName(), t4 := WinGetPID()
    
    WinDataText := t1 "`n" ; ZZZ
                 . "ahk_class " t2 "`n"
                 . "ahk_exe " t3 "`n"
                 . "ahk_pid " t4 "`n"
                 . "ahk_id " curWin
    
    UpdateText("Ctrl_Title", WinDataText)
    CoordMode "Mouse", "Window"
    MouseGetPos &mrX, &mrY
    CoordMode "Mouse", "Client"
    MouseGetPos &mcX, &mcY
    mClr := PixelGetColor(msX,msY,"RGB")

    if oGui["Ctrl_DPIAware"].Value {
        wDpi := WinGetDpi("ahk_id " curWin)
        DpiToStandard(wDpi, &mrX, &mrY), DpiToStandard(wDpi, &mcX, &mcY)
    }
    
    mpText := "Screen:`t" msX ", " msY "`n"
            . "Window:`t" mrX ", " mrY "`n"
            . "Client:`t" mcX ", " mcY " (default)`n"
            . "Color:`t" mClr " (Red=" SubStr(mClr, 3, 2) " Green=" SubStr(mClr, 5, 2) " Blue=" SubStr(mClr, 7) ")"
    
    UpdateText("Ctrl_MousePos", mpText)
    
    UpdateText("Ctrl_CtrlLabel", (Ctrl_FollowMouse ? oGui.txtMouseCtrl : oGui.txtFocusCtrl) ":")
    
    if (curCtrl) {
        ctrlTxt := ControlGetText(curCtrl)
        WinGetClientPos(&sX, &sY, &sW, &sH, curCtrl)
        ControlGetPos &cX, &cY, &cW, &cH, curCtrl
        if oGui["Ctrl_DPIAware"].Value
            DpiToStandard(wDpi, &cX, &cY), DpiToStandard(wDpi, &cW, &cH), DpiToStandard(wDpi, &sW, &sH)
        
        cText := "ClassNN:`t" curCtrlClassNN "`n"
               . "Text:`t" textMangle(ctrlTxt) "`n"
               . "Screen:`tx: " sX "`ty: " sY "`tw: " sW "`th: " sH "`n"
               . "Client`tx: " cX "`ty: " cY "`tw: " cW "`th: " cH
    } else
        cText := ""
    
    UpdateText("Ctrl_Ctrl", cText)
    wX := "", wY := "", wW := "", wH := ""
    WinGetPos &wX, &wY, &wW, &wH, "ahk_id " curWin
    WinGetClientPos(&wcX, &wcY, &wcW, &wcH, "ahk_id " curWin)
    
    if oGui["Ctrl_DPIAware"].Value
        DpiToStandard(wDpi, &wW, &wH), DpiToStandard(wDpi, &wcW, &wcH)
        
    wText := "Screen:`tx: " wX "`ty: " wY "`tw: " wW "`th: " wH "`n"
           . "Client:`tx: " wcX "`ty: " wcY "`tw: " wcW "`th: " wcH
    
    UpdateText("Ctrl_Pos", wText)
    sbTxt := ""
    
    Loop {
        ovi := ""
        Try ovi := StatusBarGetText(A_Index)
        if (ovi = "")
            break
        sbTxt .= "(" A_Index "):`t" textMangle(ovi) "`n"
    }
    
    sbTxt := SubStr(sbTxt,1,-1) ; StringTrimRight, sbTxt, sbTxt, 1
    UpdateText("Ctrl_SBText", sbTxt)
    bSlow := oGui["Ctrl_IsSlow"].Value ; GuiControlGet, bSlow,, Ctrl_IsSlow
    
    if (bSlow) {
        DetectHiddenText False
        ovVisText := WinGetText() ; WinGetText, ovVisText
        DetectHiddenText True
        ovAllText := WinGetText() ; WinGetText, ovAllText
    } else {
        ovVisText := WinGetTextFast(false)
        ovAllText := WinGetTextFast(true)
    }
    
    UpdateText("Ctrl_VisText", ovVisText)
    UpdateText("Ctrl_AllText", ovAllText)
}

; ===========================================================================================
; WinGetText ALWAYS uses the "slow" mode - TitleMatchMode only affects
; WinText/ExcludeText parameters. In "fast" mode, GetWindowText() is used
; to retrieve the text of each control.
; ===========================================================================================
WinGetTextFast(detect_hidden) {    
    controls := WinGetControlsHwnd()
    
    static WINDOW_TEXT_SIZE := 32767 ; Defined in AutoHotkey source.
    
    buf := Buffer(WINDOW_TEXT_SIZE * 2,0)
    
    text := ""
    
    Loop controls.Length {
        hCtl := controls[A_Index]
        if !detect_hidden && !DllCall("IsWindowVisible", "ptr", hCtl)
            continue
        if !DllCall("GetWindowText", "ptr", hCtl, "Ptr", buf.ptr, "int", WINDOW_TEXT_SIZE)
            continue
        
        text .= StrGet(buf) "`r`n" ; text .= buf "`r`n"
    }
    return text
}

; ===========================================================================================
; Unlike using a pure GuiControl, this function causes the text of the
; controls to be updated only when the text has changed, preventing periodic
; flickering (especially on older systems).
; ===========================================================================================
UpdateText(vCtl, NewText) {
    Global oGui
    static OldText := {}
    ctl := oGui[vCtl], hCtl := Integer(ctl.hwnd)
    
    if (!oldText.HasProp(hCtl) Or OldText.%hCtl% != NewText) {
        ctl.Value := NewText
        OldText.%hCtl% := NewText
    }
}

WinGetDpi(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
    hMonitor := DllCall("MonitorFromWindow", "ptr", WinExist(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?), "int", 2, "ptr") ; MONITOR_DEFAULTTONEAREST
    DllCall("Shcore.dll\GetDpiForMonitor", "ptr", hMonitor, "int", 0, "uint*", &dpiX:=0, "uint*", &dpiY:=0)
    return dpiX
}
DpiToStandard(dpi, &x, &y) => (x := DllCall("MulDiv", "int", x, "int", A_StandardDpi, "int", dpi, "int"), y := DllCall("MulDiv", "int", y, "int", A_StandardDpi, "int", dpi, "int"))

textMangle(x) {
    elli := false
    if (pos := InStr(x, "`n"))
        x := SubStr(x, 1, pos-1), elli := true
    else if (StrLen(x) > 40)
        x := SubStr(x,1,40), elli := true
    if elli
        x .= " (...)"
    return x
}

suspend_timer() {
    Global oGui
    SetTimer Update, 0
    UpdateText("Ctrl_Freeze", oGui.txtFrozen)
}

~*Shift::
~*Ctrl::suspend_timer()

~*Ctrl up::
~*Shift up::SetTimer Update, 250