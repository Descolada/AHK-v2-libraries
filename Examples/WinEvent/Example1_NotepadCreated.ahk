#Requires AutoHotkey v2
#include ..\..\Lib\WinEvent.ahk

; Detects when a Notepad window is created. Press F1 to run Notepad and test.
hook := WinEvent.Show(NotepadCreated, "ahk_exe notepad.exe")
Persistent()

NotepadCreated(hWnd, dwmsEventTime) {
    ToolTip "Notepad was created at " dwmsEventTime ", hWnd " hWnd "`n"
    SetTimer ToolTip, -3000
}

F1::Run("notepad.exe")