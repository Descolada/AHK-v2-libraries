#Requires AutoHotkey v2
#include ..\..\Lib\WinEvent.ahk

; Detects when any window is maximized, for a maximum of 1 successful callback
WinEvent.Maximize(WindowMaximizedEvent,, 1)

; Fail the callback if "Yes" is not clicked, so the hook is not stopped
WindowMaximizedEvent(hWnd, hook, dwmsEventTime) => MsgBox("A window was maximized at " dwmsEventTime ", hWnd " hWnd "`n`nStop hook?",, 0x4) != "Yes"

F1::Run("notepad.exe")