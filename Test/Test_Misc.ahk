#include "..\Lib\Misc.ahk"
;#Include "..\Lib\DUnit.ahk"
;DUnit("C", MiscTestSuite)

class MiscTestSuite {
    static Fail() {
        throw Error()
    }
    Begin() {
        DUnit.Print(,"", "")
    }

    Test_Print() {
        DUnit.Equal(DUnit.Print([]), "[]")
        DUnit.Equal(DUnit.Print(Map()), "Map()")
        DUnit.Equal(DUnit.Print({}), "{}")
        DUnit.Equal(DUnit.Print([1]), "[1]")
        DUnit.Equal(DUnit.Print(Map("key", "value")), "Map('key':'value')")
        DUnit.Equal(DUnit.Print({key:"value"}), "{key:'value'}")
        DUnit.Equal(DUnit.Print([1,[2,[3,4]]]), "[1, [2, [3, 4]]]")
        DUnit.Equal(DUnit.Print(Map(1, 2, "3", "4")), "Map(1:2, '3':'4')")
        DUnit.Equal(DUnit.Print({key:"value", 1:2, 3:"4"}), "{1:2, 3:'4', key:'value'}")
    }

    Test_Swap() {
        a := 1, b := 2
        Swap(&a, &b)
        DUnit.Equal(a, 2)
        DUnit.Equal(b, 1)
    }

    Test_Range() {
        DUnit.Equal(DUnit.Print(Range(5)), "Range(1:1, 2:2, 3:3, 4:4, 5:5)")
        DUnit.Equal(Range(5).ToArray(), [1,2,3,4,5])
        DUnit.Equal(DUnit.Print(Range(0)), "Range(1:1, 2:0)")
    }
    Test_Range2() { ; Split into two because of the ListLines limitation
        DUnit.Equal(DUnit.Print(Range(3, 5)), "Range(1:3, 2:4, 3:5)")
        DUnit.Equal(DUnit.Print(Range(5, 3)), "Range(1:5, 2:4, 3:3)")
        DUnit.Equal(DUnit.Print(Range(5,,2)), "Range(1:1, 2:3, 3:5)")
        DUnit.Equal(DUnit.Print(Range(5,-5,-2)), "Range(1:5, 2:3, 3:1, 4:-1, 5:-3, 6:-5)")
    }

    Test_RegExMatchAll() {
        DUnit.Equal(RegExMatchAll("", "\w+"), [])
        DUnit.Equal(DUnit.Print(RegExMatchAll("a,bb,ccc", "\w+")), "[RegExMatchInfo(0:'a'), RegExMatchInfo(0:'bb'), RegExMatchInfo(0:'ccc')]")
        DUnit.Equal(DUnit.Print(RegExMatchAll("a,bb,ccc", "\w+",4)), "[RegExMatchInfo(0:'b'), RegExMatchInfo(0:'ccc')]")
    }

    Test_ConvertWinPos() {
        ccm := A_CoordModeMouse
        WinExist("A")
        A_CoordModeMouse := "client"
        MouseMove(100, 200)
        MouseGetPos(&clientX, &clientY)
        A_CoordModeMouse := "screen"
        MouseGetPos(&screenX, &screenY)
        A_CoordModeMouse := "window"
        MouseGetPos(&windowX, &windowY)
        A_CoordModeMouse := ccm
        ConvertWinPos(screenX, screenY, &OutX, &OutY, "screen", "client", "A")
        DUnit.Equal(clientX " " clientY, OutX " " OutY)
        ConvertWinPos(clientX, clientY, &OutX, &OutY, "client", "screen", "A")
        DUnit.Equal(screenX " " screenY, OutX " " OutY)
        ConvertWinPos(windowX, windowY, &OutX, &OutY, "window", "screen", "A")
        DUnit.Equal(screenX " " screenY, OutX " " OutY)
        ConvertWinPos(screenX, screenY, &OutX, &OutY, "screen", "window", "A")
        DUnit.Equal(windowX " " windowY, OutX " " OutY)
        ConvertWinPos(clientX, clientY, &OutX, &OutY, "client", "window", "A")
        DUnit.Equal(windowX " " windowY, OutX " " OutY)
        ConvertWinPos(windowX, windowY, &OutX, &OutY, "window", "client", "A")
        DUnit.Equal(clientX " " clientY, OutX " " OutY)
    }
}