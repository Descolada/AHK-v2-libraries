#Requires AutoHotkey v2
#include ..\..\Lib\WinEvent.ahk

; Detects when any window is maximized
WinEvent.Maximize(WindowMaximizedEvent)
Persistent()

WindowMaximizedEvent(hWnd, hook, dwmsEventTime) {
    if MsgBox("A window was maximized at " dwmsEventTime ", hWnd " hWnd "`n`nStop hook?",, 0x4) = "Yes"
        hook.Stop()
}

F1::Run("notepad.exe")