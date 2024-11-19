#Requires AutoHotkey v2
#include ..\..\Lib\WinEvent.ahk

Run "notepad.exe"
WinWaitActive "ahk_exe notepad.exe"
; Detect the closing of the newly created Notepad window. Note that using "A" instead of
; WinExist("A") would detect the closing of any active window, not Notepad.
WinEvent.Close(ActiveWindowClosed, WinExist("A"), 1)

ActiveWindowClosed(*) {
    MsgBox "Notepad window closed, press OK to exit"
    ExitApp
}