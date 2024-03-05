#Requires AutoHotkey v2
#include ..\..\Lib\WinEvent.ahk

; Detects when any window is maximized
hook := WinEvent.Maximize(WindowMaximizedEvent)
Persistent()

WindowMaximizedEvent(hWnd, dwmsEventTime) {
    ToolTip "A window was maximized at " dwmsEventTime ", hWnd " hWnd "`n"
    SetTimer ToolTip, -3000
}

F1::Run("notepad.exe")