#Requires AutoHotkey v2
#include ..\..\Lib\WinEvent.ahk
#include ..\..\Lib\Misc.ahk

WinEvent.Active(ActiveWindowChanged)

ActiveWindowChanged(hWnd, *) {
    ToolTip "Active window changed! New window info: `n" WinGetInfo(hWnd)
    SetTimer ToolTip, -5000
}