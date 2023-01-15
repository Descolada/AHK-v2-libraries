#include "..\Lib\Misc.ahk"
#include "..\Lib\Acc.ahk"
#Include "..\Lib\DUnit.ahk"
DUnit("C", AccTestSuite)

class AccTestSuite {
    static Fail() {
        throw Error()
    }
    Begin() {
        Run "notepad.exe"
        WinWaitActive "ahk_exe notepad.exe"
        WinMove(0,0,1530,876)
        this.oAcc := Acc.ElementFromHandle("ahk_exe notepad.exe")
        A_Clipboard := this.oAcc.DumpAll()
    }
    End() {
        WinClose "ahk_exe notepad.exe"
    }
    Test_Item() {
        DUnit.Equal(this.oAcc.Dump(), "RoleText: window Role: 9 [Location: {x:0,y:0,w:1530,h:876}] [Name: Untitled - Notepad] [Value: ] [StateText: focusable] [State: 1441792] [Help: N/A]")
        DUnit.Equal(this.oAcc[4,2,4,3].Dump(), "RoleText: text Role: 41 [Location: {x:1086,y:831,w:73,h:34}] [Name:  100%] [Value: ] [StateText: normal] [KeyboardShortcut: N/A] ChildId: 3", "Item only by indexes")
        DUnit.Equal(this.oAcc[4,2,"menu bar"].Dump(), "RoleText: menu bar Role: 2 [Location: {x:0,y:0,w:0,h:0}] [Name: System] [Value: ] [StateText: invisible] [State: 32768] [DefaultAction: N/A] [Description: Contains commands to manipulate the window]", "Item by RoleText 1")
        DUnit.Equal(this.oAcc[4,2,"menu bar 2"].Dump(), "RoleText: menu bar Role: 2 [Location: {x:0,y:0,w:0,h:0}] [Name: Application] [Value: ] [StateText: invisible] [State: 32768] [DefaultAction: N/A] [Description: Contains commands to manipulate the current view or document]", "Item by RoleText and index")
        DUnit.Equal(this.oAcc[4,2,"status bar",3].Dump(), "RoleText: text Role: 41 [Location: {x:1086,y:831,w:73,h:34}] [Name:  100%] [Value: ] [StateText: normal] [KeyboardShortcut: N/A] ChildId: 3", "Item by RoleText 2")
        DUnit.Equal(this.oAcc["4.2.status bar.3"].Dump(), "RoleText: text Role: 41 [Location: {x:1086,y:831,w:73,h:34}] [Name:  100%] [Value: ] [StateText: normal] [KeyboardShortcut: N/A] ChildId: 3", "Item by string indexes and RoleText")
        DUnit.Equal(this.oAcc[4,-1].Dump(), this.oAcc[4,2].Dump())
        DUnit.Equal(this.oAcc[4,{Name:"Status Bar"}].Dump(), this.oAcc[4,2].Dump())
        DUnit.NotEqual(this.oAcc[4,{Name:"Text Editor"}].Dump(), this.oAcc[4,2].Dump())
        DUnit.Equal(this.oAcc[4,-1,-4,-3].Dump(), "RoleText: text Role: 41 [Location: {x:1086,y:831,w:73,h:34}] [Name:  100%] [Value: ] [StateText: normal] [KeyboardShortcut: N/A] ChildId: 3")
        oEdit := this.oAcc[4,1,4]
        DUnit.Equal(this.oAcc[4,1].Dump(), oEdit["p2,1"].Dump())
    }
    Test_ControlID_WinID() {
        oEdit := this.oAcc[4,1,4]
        DUnit.Equal(ControlGetHwnd("Edit1"), oEdit.ControlID)
        DUnit.Equal(WinExist(), oEdit.WinID)
    }
    Test_DoDefaultAction_WaitElementExist_WaitNotExist() {
        this.oAcc.FindElement({Name:"File"}).DoDefaultAction()
        oSave := this.oAcc.WaitElementExist({Name:"Save As...	Ctrl+Shift+S"},1000)
        DUnit.True(oSave)
        DUnit.Equal(oSave.Dump(), "RoleText: menu item Role: 12 [Location: {x:14,y:201,w:310,h:31}] [Name: Save As...	Ctrl+Shift+S] [Value: ] [StateText: normal] [DefaultAction: Execute] [Description: N/A] [KeyboardShortcut: a] ChildId: 5")
        Send "{Esc}"
        DUnit.True(oSave.WaitNotExist())
        DUnit.False(this.oAcc.WaitElementExist({Name:"Save As...	Ctrl+Shift+S"}, 100))
    }
    Test_Children() {
        oChildren := this.oAcc.Children
        DUnit.Equal(oChildren.length, 7)
        DUnit.Equal(oChildren[7].Dump(), "RoleText: grip Role: 4 [Location: {x:0,y:0,w:0,h:0}] [Name: ] [Value: ] [StateText: invisible] [State: 32769]")
    }
    Test_GetPath_ControlClick() {
        DUnit.Equal(this.oAcc.GetPath(this.oAcc[4,2,4,3]), "4,2,4,3")
        Run "chrome.exe --incognito autohotkey.com"
        WinWaitActive("ahk_exe chrome.exe")
        Sleep 500
        oChrome := Acc.ElementFromHandle("ahk_exe chrome.exe") 
        DUnit.Equal(oChrome.GetPath(oEl := oChrome.WaitElementExist("4,1,1,2,2,2,2,1,1,1,1,1")), "4,1,1,2,2,2,2,1,1,1,1,1")
        docEl := oEl.Normalize({RoleText:"document", not:{Value:""}})
        DUnit.Equal(docEl.Value, "https://www.autohotkey.com/")
        oEl.ControlClick()
        DUnit.True(oEl.WaitNotExist())
        WinClose("ahk_exe chrome.exe")
    }
    Test_GetLocation() {
        WinMove(10, 10)
        oEl := this.oAcc[4,2,4,3]
        DUnit.Equal(oEl.GetLocation("screen"), {h:34, w:73, x:1096, y:841})
        DUnit.Equal(oEl.GetLocation("client"), {h:34, w:73, x:1075, y:756})
        DUnit.Equal(oEl.GetLocation("window"), {h:34, w:73, x:1086, y:831})
        DUnit.Equal(oEl.GetLocation(""), {h:34, w:73, x:1075, y:756})
        DUnit.Equal(A_CoordmodeMouse, "Client")
    }
    Test_FindElement_FindElements_ValidateCondition() {
        oEdit := this.oAcc[4,1,4]
        DUnit.Equal(this.oAcc.FindElement({Name:"Maximize", Role:43}).Dump(), "RoleText: push button Role: 43 [Location: {x:1379,y:1,w:70,h:44}] [Name: Maximize] [Value: ] [StateText: normal] [DefaultAction: Press] [Description: Makes the window full screen] ChildId: 3")
        DUnit.Equal(DUnit.Print(this.oAcc.FindElements([{Name:"Minimize"}, {Name:"Maximize"}])), "[Acc.IAccessible('RoleText: menu item Role: 12 [Location: {x:0,y:0,w:0,h:0}] [Name: Minimize] [Value: ] [StateText: normal] [DefaultAction: Execute] [Description: N/A] [KeyboardShortcut: n] "
        . "ChildId: 4'), Acc.IAccessible('RoleText: menu item Role: 12 [Location: {x:0,y:0,w:0,h:0}] [Name: Maximize] [Value: ] [StateText: normal] [DefaultAction: Execute] [Description: N/A] [KeyboardShortcut: x] ChildId: 5'), Acc.IAccessible('RoleText: push button Role:"
        . " 43 [Location: {x:1308,y:1,w:71,h:44}] [Name: Minimize] [Value: ] [StateText: normal] [DefaultAction: Press] [Description: Moves the window out of the way] ChildId: 2'), Acc.IAccessible('RoleText: push button Role: 43 [Location: {x:1379,y:1,w:70,h:44}] [Name: "
        . "Maximize] [Value: ] [StateText: normal] [DefaultAction: Press] [Description: Makes the window full screen] ChildId: 3'), Acc.IAccessible('RoleText: push button Role: 43 [Location: {x:0,y:0,w:0,h:0}] [Name: Minimize] [Value: ] [StateText: invisible] [State: 32768]"
        . " [DefaultAction: Press] [Description: Moves the window out of the way] ChildId: 2'), Acc.IAccessible('RoleText: push button Role: 43 [Location: {x:0,y:0,w:0,h:0}] [Name: Maximize] [Value: ] [StateText: invisible] [State: 32768] [DefaultAction: Press] [Description: "
        . "Makes the window full screen] ChildId: 3'), Acc.IAccessible('RoleText: push button Role: 43 [Location: {x:0,y:0,w:0,h:0}] [Name: Minimize] [Value: ] [StateText: invisible] [State: 32768] [DefaultAction: Press] [Description: Moves the window out of the way] ChildId: 2'), "
        . "Acc.IAccessible('RoleText: push button Role: 43 [Location: {x:0,y:0,w:0,h:0}] [Name: Maximize] [Value: ] [StateText: invisible] [State: 32768] [DefaultAction: Press] [Description: Makes the window full screen] ChildId: 3')]")
        DUnit.Equal(DUnit.Print(this.oAcc.FindElements([{Name:"Minimize"}])), "[Acc.IAccessible('RoleText: menu item Role: 12 [Location: {x:0,y:0,w:0,h:0}] [Name: Minimize] [Value: ] [StateText: normal] [DefaultAction: Execute] [Description: N/A] [KeyboardShortcut: n] ChildId: 4'), "
        . "Acc.IAccessible('RoleText: push button Role: 43 [Location: {x:1308,y:1,w:71,h:44}] [Name: Minimize] [Value: ] [StateText: normal] [DefaultAction: Press] [Description: Moves the window out of the way] ChildId: 2'), "
        . "Acc.IAccessible('RoleText: push button Role: 43 [Location: {x:0,y:0,w:0,h:0}] [Name: Minimize] [Value: ] [StateText: invisible] [State: 32768] [DefaultAction: Press] [Description: Moves the window out of the way] ChildId: 2'), "
        . "Acc.IAccessible('RoleText: push button Role: 43 [Location: {x:0,y:0,w:0,h:0}] [Name: Minimize] [Value: ] [StateText: invisible] [State: 32768] [DefaultAction: Press] [Description: Moves the window out of the way] ChildId: 2')]")
        DUnit.Equal(DUnit.Print(this.oAcc.FindElements([{Name:"Minimize", not:{Role:43}}])), "[Acc.IAccessible('RoleText: menu item Role: 12 [Location: {x:0,y:0,w:0,h:0}] [Name: Minimize] [Value: ] [StateText: normal] [DefaultAction: Execute] [Description: N/A] [KeyboardShortcut: n] ChildId: 4')]")
        DUnit.Equal(DUnit.Print(this.oAcc.FindElements([{Name:"minim", cs:false, mm:2}])), "[Acc.IAccessible('RoleText: menu item Role: 12 [Location: {x:0,y:0,w:0,h:0}] [Name: Minimize] [Value: ] [StateText: normal] [DefaultAction: Execute] [Description: N/A] [KeyboardShortcut: n] ChildId: 4'), "
        . "Acc.IAccessible('RoleText: push button Role: 43 [Location: {x:1308,y:1,w:71,h:44}] [Name: Minimize] [Value: ] [StateText: normal] [DefaultAction: Press] [Description: Moves the window out of the way] ChildId: 2'), "
        . "Acc.IAccessible('RoleText: push button Role: 43 [Location: {x:0,y:0,w:0,h:0}] [Name: Minimize] [Value: ] [StateText: invisible] [State: 32768] [DefaultAction: Press] [Description: Moves the window out of the way] ChildId: 2'), "
        . "Acc.IAccessible('RoleText: push button Role: 43 [Location: {x:0,y:0,w:0,h:0}] [Name: Minimize] [Value: ] [StateText: invisible] [State: 32768] [DefaultAction: Press] [Description: Moves the window out of the way] ChildId: 2')]")
        DUnit.Equal(this.oAcc.FindElement({Role:9, index:-1}).Dump(), "RoleText: window Role: 9 [Location: {x:11,y:829,w:1508,h:36}] [Name: Status Bar] [Value: ] [StateText: focusable] [State: 1048576] [Help: N/A]")
        DUnit.Equal(this.oAcc.FindElement({Role:9, index:2}).Dump(), "RoleText: window Role: 9 [Location: {x:11,y:829,w:1508,h:36}] [Name: Status Bar] [Value: ] [StateText: focusable] [State: 1048576] [Help: N/A]")
        DUnit.Equal(this.oAcc.FindElement({or:[{Name:"Save	Ctrl+S"}, {Name:"Save As...	Ctrl+Shift+S"}], index:-1}).Dump(), "RoleText: menu item Role: 12 [Location: {x:0,y:0,w:0,h:0}] [Name: Save As...	Ctrl+Shift+S] [Value: ] [StateText: normal] [DefaultAction: Execute] [Description: N/A] [KeyboardShortcut: a] ChildId: 5")
        DUnit.Equal(this.oAcc.FindElement({IsEqual:oEdit}).Dump(), "RoleText: editable text Role: 42 [Location: {x:11,y:75,w:1482,h:754}] [Name: Text Editor] [Value: ] [StateText: focusable] [State: 1048580]")
        DUnit.Equal(this.oAcc.FindElement({Location:{w:1482,h:754}}).Dump(), "RoleText: editable text Role: 42 [Location: {x:11,y:75,w:1482,h:754}] [Name: Text Editor] [Value: ] [StateText: focusable] [State: 1048580]")
        DUnit.Equal(this.oAcc.FindElement([{Role:9}, {Role:10}], 3,,1).Dump(), "RoleText: client Role: 10 [Location: {x:11,y:75,w:1508,h:790}] [Name: Untitled - Notepad] [Value: ] [StateText: focusable] [State: 1048576]")
        DUnit.Equal(this.oAcc.FindElement({Role:9}, 2,,2), "")
        DUnit.Equal(this.oAcc.FindElements([{Role:11}, {Role:12}],, 2).Length, 12)
        DUnit.False(this.oAcc.FindElement([{Role:9}, {Role:12}],,,,1))
        DUnit.True(this.oAcc.FindElement([{Role:9}, {Role:12}],,,,2))
        DUnit.False(this.oAcc.FindElement([{Role:9}, {Role:12}],,,3,1))
        DUnit.True(this.oAcc.FindElement([{Role:9}, {Role:12}],,,3,2))
    }
    Test_Highlight() {
        (oEl := this.oAcc[4,1,4]).Highlight(0)
        res := MsgBox("Confirm the Highlight is visible",, 4)
        oEl := ""
        Acc.ClearHighlights()
        if res = "No"
            throw Error("Highlighting failed!")
    }
    Test_Click_ControlClick() {
        this.oAcc[3,2].Click()
        DUnit.True(oPaste := this.oAcc.WaitElementExist({Name:"Paste	Ctrl+V"},200))
        ;oPaste.ControlClick()
        Send "{Esc}"
        DUnit.True(oPaste.WaitNotExist())
    }
    Test_ObjectFromPoint() {
        oEdit := Acc.ObjectFromPoint(100, 200)
        DUnit.Equal(oEdit, this.oAcc[4,1,4])
        DUnit.Equal(oEdit.wId, WinExist())
    }
}