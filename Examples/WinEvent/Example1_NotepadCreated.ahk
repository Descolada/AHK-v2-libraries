#Requires AutoHotkey v2
#include ..\..\Lib\WinEvent.ahk

; Detects when a Notepad window is created. Press F1 to run Notepad and test.

; This could also be achieved using WinEvent.Create, but along with the Notepad main window there
; are some other hidden windows created as well that match "ahk_exe notepad.exe" which we don't want
; to capture. In the case of Notepad we could use "ahk_class Notepad ahk_exe notepad.exe" to filter
; for the main window, but that method isn't generalizable, so WinEvent.Show is a safer option.
WinEvent.Show(NotepadCreated, "ahk_exe notepad.exe")

NotepadCreated(hWnd, hook, dwmsEventTime) {
    ToolTip "Notepad was created at " dwmsEventTime ", hWnd " hWnd "`n"
    SetTimer ToolTip, -3000
}

F1::Run("notepad.exe")