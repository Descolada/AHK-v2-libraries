#Requires AutoHotkey v2.0

#include "..\Lib\DPI.ahk"
#Include "..\Lib\DUnit.ahk"
#include "..\Lib\FindTextDpi.ahk"

class DPITestSuite {
    static Fail() {
        throw Error()
    }

    __GetWindow(winTitle, exeName) {
        if !WinExist(winTitle) {
            Run exeName
            WinWaitActive winTitle
            Sleep 200
        } else
            WinActivate winTitle
        WinWaitActive winTitle
        return WinExist(winTitle)
    }

    __GetCalculator() {
        hwnd := this.__GetWindow("Calculator", "calc.exe")
        WinMove(A_ScreenWidth+100, 100, 300, 500, hwnd)
    }
    __GetNPP() => this.__GetWindow("ahk_exe notepad++.exe", "notepad++.exe")

    Test_MonitorFuncs() {
        DUnit.True(DPI.MonitorFromWindow("A"))
        DUnit.Equal(DPI.MonitorFromPoint(100, 100, "client"), DPI.MonitorFromWindow("A"))
        CoordMode "Mouse", "Screen"
        DUnit.Equal(DPI.GetForMonitor(DPI.MonitorFromPoint(100, 100, "screen")), 144)
        DUnit.Equal(DPI.GetForMonitor(DPI.MonitorFromPoint(A_ScreenWidth+100, 100, "screen")), 96)

        monitors := DPI.GetMonitorHandles()
        DUnit.Equal(DPI.GetForMonitor(monitors[1]), 144)
        DUnit.Equal(DPI.GetForMonitor(monitors[2]), 96)
    }

    Test_ClickDPI() {
        this.__GetCalculator()
        SetMouseDelay 0
        SetDefaultMouseSpeed 0
        DPI.Click(47, 329)
    }

    Test_ImageSearch() {
        WinGetPos(&wX, &wY, &wW, &wH, this.__GetCalculator())
        DUnit.True(DPI.ImageSearch(&outX, &outY, 0, 0, wW, wH, "*150 " A_WorkingDir "\..\Resources\DPI_Tutorial\Calculator_icon_225%.png",,216))
    }

    Test_FindText() {
        wTitle := "ahk_exe chrome.exe"
        WinActivate wTitle
        WinWaitActive wTitle

        WinGetPos(&wX, &wY, &wW, &wH, wTitle)

        Text:="|<144>*180$27.00000000000000Dzz01zzs0ADz01bzs0Bzz01zzs0Dzz01XAM0AEX01W4M0ANX01zzs0AEz01W7s0AEz01zzs0Dzz01W7s0AEz01W7s0Dzz01zzs0000000004"
        Text:="|<96>*180$13.00003zlDsjwTyDz4ZWGFzsYwGSDz4bWHlzs000000E"
        Text:="|<96>*185$21.00000000000000000000000003wE0zq0C7k30S0s7k61y0k006000k0U70C0M3U1ks07y00T0000000000000004"
        ;Text:="|<144>**50$29.0000000000000000000000000000001y000Dz300zzC07kDw0C04M0s08k1U0lU703z0C07w0Q0000s0001k0003U0603U0Q0700s0703U07US007zs007zU003w0000000000000000E"
        Text:="|<216>**50$41.0000000000000000000000000000000000000y00000DzU2001s3kA00Dzyss00zUDvE03w07wU07U03100S006201g00A403k00k80B0030E0S00A0U0w00zz01M000002U000005000000/000000S000000w000801c000s01s003k03M007U03k00S007k01s007s0Dk007w1z0007TzQ0007U3U0003zw00000T0000000000000000000000000000004"

        ;if (ok:=FindText(&X, &Y, wX, wY, wX+wW, wY+wH, 0.3, 0.2, Text, , 0, , , , , zoomW:=DPI.GetForWindow(wTitle)/216, zoomW))
        ;if (ok:=FindText(&X, &Y, wX, wY, wX+wW, wY+wH, 0.3, 0.3, "##10$Calculator_icon_225%.png", , 0, , , , , zoomW:=DPI.GetForWindow(wTitle)/216, zoomW))
        ok:=FindText(&X, &Y, wX, wY, wX+wW, wY+wH, 0.2, 0.1, "##10$" A_WorkingDir "\..\Resources\DPI_Tutorial\Chrome_Reload_100%.png", , 0, , , , , zoomW:=DPI.GetForWindow(wTitle)/96, zoomW)
        DUnit.True(ok)
    }

    Test_CoordConversion() {
        this.__GetCalculator()

        SetMouseDelay 0
        SetDefaultMouseSpeed 0
        DPI.MouseMove(47, 329)

        CoordMode "Mouse", "Client"
        MouseGetPos(&clientX, &clientY)
        CoordMode "Mouse", "Window"
        MouseGetPos(&windowX, &windowY)
        CoordMode "Mouse", "Screen"
        MouseGetPos(&screenX, &screenY)

        CoordMode "Mouse", "Client"
        MouseGetPos(&newX, &newY)
        DPI.CoordsToClient(&newX, &newY, A_CoordModeMouse)
        DUnit.Equal(newX, clientX), DUnit.Equal(newY, clientY)

        CoordMode "Mouse", "Window"
        MouseGetPos(&newX, &newY)
        DPI.CoordsToWindow(&newX, &newY, A_CoordModeMouse)
        DUnit.Equal(newX, windowX), DUnit.Equal(newY, windowY)

        CoordMode "Mouse", "Screen"
        MouseGetPos(&newX, &newY)
        DPI.CoordsToScreen(&newX, &newY, A_CoordModeMouse)
        DUnit.Equal(newX, screenX), DUnit.Equal(newY, screenY)
    }

    Test_GetForWindow() {
        DUnit.Equal(DPI.GetForWindow(this.__GetNPP()), A_ScreenDPI)
        DUnit.Equal(DPI.GetForWindow(hwnd := this.__GetCalculator()), DPI.GetForMonitor(DPI.MonitorFromWindow(hwnd)))
    }

    Test_GuiOptScale() {
        DUnit.Equal(DPI.GuiOptScale("w100 h-1", 144), "w150 h-1")
        DPI.Standard := 144
        DUnit.Equal(DPI.GuiOptScale("w100 h-1", 144), "w100 h-1")
        DPI.Standard := 96
    }
}