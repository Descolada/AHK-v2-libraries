#Requires AutoHotkey v2
#include ..\..\Lib\WinEvent.ahk

SetWinDelay(-1)

target := WinExist("ahk_exe notepad.exe")
if !target {
   Run "notepad.exe"
   WinWait "ahk_exe notepad.exe"
   target := WinExist("ahk_exe notepad.exe")
}
WinActivate target
WinWaitActive target

docked := Gui("-DPIScale +ToolWindow +Owner" target, "Docked GUI")
docked.AddButton(, "Test").OnEvent("Click", (*) => MsgBox("Button was clicked"))
WinGetPosEx(target, &X, &Y, &W, , &offsetX)
WinGetPos(,,, &H, target)
docked.Show("x" (X+W+offsetX) " y" Y " w200 h" H)
docked.Move(X+W+offsetX, Y,, H)

WinEvent.Move(TargetMoved, target)
WinEvent.Close((*) => ExitApp(), target)

TargetMoved(hWnd, *) {
   local X, Y, W, H
   docked.Restore()
   WinGetPosEx(target, &X, &Y, &W)
   WinGetPos(,,, &H, target)
   docked.Move(X+W+offsetX, Y,, H)
}

;------------------------------
;
; Function: WinGetPosEx
;
; Description:
;
;   Gets the position, size, and offset of a window. See the *Remarks* section
;   for more information.
;
;   https://www.autohotkey.com/boards/viewtopic.php?f=6&t=3392
;
; Parameters:
;
;   hWindow - Handle to the window.
;
;   X, Y, Width, Height - Output variables. [Optional] If defined, these
;       variables contain the coordinates of the window relative to the
;       upper-left corner of the screen (X and Y), and the Width and Height of
;       the window.
;
;   Offset_X, Offset_Y - Output variables. [Optional] Offset, in pixels, of the
;       actual position of the window versus the position of the window as
;       reported by GetWindowRect.  If moving the window to specific
;       coordinates, add these offset values to the appropriate coordinate
;       (X and/or Y) to reflect the true size of the window.
;
; Returns:
;
;   If successful, a RECTPlus buffer object is returned.
;   The first 16 bytes contains a RECT structure that contains the dimensions of the
;   bounding rectangle of the specified window.
;   The dimensions are given in screen coordinates that are relative to the upper-left
;   corner of the screen.
;   The next 8 bytes contain the X and Y offsets (4-byte integer for X and
;   4-byte integer for Y).
;
;   Also if successful (and if defined), the output variables (X, Y, Width,
;   Height, Offset_X, and Offset_Y) are updated.  See the *Parameters* section
;   for more more information.
;
;   If not successful, FALSE is returned.
;
; Requirement:
;
;   Windows 2000+
;
; Remarks, Observations, and Changes:
;
; * Starting with Windows Vista, Microsoft includes the Desktop Window Manager
;   (DWM) along with Aero-based themes that use DWM.  Aero themes provide new
;   features like a translucent glass design with subtle window animations.
;   Unfortunately, the DWM doesn't always conform to the OS rules for size and
;   positioning of windows.  If using an Aero theme, many of the windows are
;   actually larger than reported by Windows when using standard commands (Ex:
;   WinGetPos, GetWindowRect, etc.) and because of that, are not positioned
;   correctly when using standard commands (Ex: gui Show, WinMove, etc.).  This
;   function was created to 1) identify the true position and size of all
;   windows regardless of the window attributes, desktop theme, or version of
;   Windows and to 2) identify the appropriate offset that is needed to position
;   the window if the window is a different size than reported.
;
; * The true size, position, and offset of a window cannot be determined until
;   the window has been rendered.  See the example script for an example of how
;   to use this function to position a new window.
;
; * 20150906: The "dwmapi\DwmGetWindowAttribute" function can return odd errors
;   if DWM is not enabled.  One error I've discovered is a return code of
;   0x80070006 with a last error code of 6, i.e. ERROR_INVALID_HANDLE or "The
;   handle is invalid."  To keep the function operational during this types of
;   conditions, the function has been modified to assume that all unexpected
;   return codes mean that DWM is not available and continue to process without
;   it.  When DWM is a possibility (i.e. Vista+), a developer-friendly messsage
;   will be dumped to the debugger when these errors occur.
;
; Credit:
;
;   Idea and some code from *KaFu* (AutoIt forum)
;
;-------------------------------------------------------------------------------
WinGetPosEx(hWindow, &X := "", &Y := "", &Width := "", &Height := "", &Offset_X := "", &Offset_Y := "") {
    Static S_OK := 0x0,
           DWMWA_EXTENDED_FRAME_BOUNDS := 9
    ;-- Get the window's dimensions
    ;   Note: Only the first 16 bytes of the RECTPlus structure are used by the
    ;   DwmGetWindowAttribute and GetWindowRect functions.
    RECTPlus := Buffer(24,0)
    Try {
       DWMRC := DllCall("dwmapi\DwmGetWindowAttribute",
                        "Ptr",  hWindow,                     ;-- hwnd
                        "UInt", DWMWA_EXTENDED_FRAME_BOUNDS, ;-- dwAttribute
                        "Ptr",  RECTPlus,                    ;-- pvAttribute
                        "UInt", 16,                          ;-- cbAttribute
                        "UInt")
    }
    Catch {
       Return False
    }
    ;-- Populate the output variables
    X := NumGet(RECTPlus,  0, "Int") ; left
    Y := NumGet(RECTPlus,  4, "Int") ; top
    R := NumGet(RECTPlus,  8, "Int") ; right
    B := NumGet(RECTPlus, 12, "Int") ; bottom
    Width    := R - X ; right - left
    Height   := B - Y ; bottom - top
    OffSet_X := 0
    OffSet_Y := 0
    ;-- Collect dimensions via GetWindowRect
    RECT := Buffer(16, 0)
    DllCall("GetWindowRect", "Ptr", hWindow,"Ptr", RECT)
    ;-- Right minus Left
    GWR_Width := NumGet(RECT,  8, "Int") - NumGet(RECT, 0, "Int")
    ;-- Bottom minus Top
    GWR_Height:= NumGet(RECT, 12, "Int") - NumGet(RECT, 4, "Int")
    ;-- Calculate offsets and update output variables
    NumPut("Int", Offset_X := (Width  - GWR_Width)  // 2, RECTPlus, 16)
    NumPut("Int", Offset_Y := (Height - GWR_Height) // 2, RECTPlus, 20)
    Return RECTPlus
 }