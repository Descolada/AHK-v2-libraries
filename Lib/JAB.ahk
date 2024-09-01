#Requires AutoHotkey v2

if (!A_IsCompiled and A_LineFile=A_ScriptFullPath)
    JAB.Viewer()

class JAB {
    DLLVersion:=""
    , DLLHandle:=""
    , acType:="Int64"
    , acPType:="Int64*"
    , acSize:=8
    JavaVersion => (this.DefineProp("JavaVersion", {value:RegRead("HKLM\SOFTWARE" (A_PtrSize = 8 ? "\Wow6432Node" : "") "\JavaSoft\Java Runtime Environment", "CurrentVersion", "")}), this.JavaVersion)
    JavaHome => (this.DefineProp("JavaHome", {value:RegRead("HKLM\SOFTWARE" (A_PtrSize = 8 ? "\Wow6432Node" : "") "\JavaSoft\Java Runtime Environment\" this.JavaVersion, "JavaHome", "")}), this.JavaHome)

    static MAX_BUFFER_SIZE:=10240
    , MAX_STRING_SIZE:=1024
    , SHORT_STRING_SIZE:=256
    , MAX_HYPERLINKS := 64
    , MAX_ICON_INFO := 8
    , MAX_RELATIONS := 5
    , MAX_RELATION_TARGETS := 25
    , MAX_KEY_BINDINGS := 8
    , MAX_ACTION_INFO := 256
    , MAX_ACTIONS_TO_DO := 32
    , MAX_VISIBLE_CHILDREN := 256

    static ACCESSIBLE_ALERT:="alert"
    , ACCESSIBLE_COLUMN_HEADER:="column header"
    , ACCESSIBLE_CANVAS:="canvas"
    , ACCESSIBLE_COMBO_BOX:="combo box"
    , ACCESSIBLE_DESKTOP_ICON:="desktop icon"
    , ACCESSIBLE_INTERNAL_FRAME:="internal frame"
    , ACCESSIBLE_DESKTOP_PANE:="desktop pane"
    , ACCESSIBLE_OPTION_PANE:="option pane"
    , ACCESSIBLE_WINDOW:="window"
    , ACCESSIBLE_FRAME:="frame"
    , ACCESSIBLE_DIALOG:="dialog"
    , ACCESSIBLE_COLOR_CHOOSER:="color chooser"
    , ACCESSIBLE_DIRECTORY_PANE:="directory pane"
    , ACCESSIBLE_FILE_CHOOSER:="file chooser"
    , ACCESSIBLE_FILLER:="filler"
    , ACCESSIBLE_HYPERLINK:="hyperlink"
    , ACCESSIBLE_ICON:="icon"
    , ACCESSIBLE_LABEL:="label"
    , ACCESSIBLE_ROOT_PANE:="root pane"
    , ACCESSIBLE_GLASS_PANE:="glass pane"
    , ACCESSIBLE_LAYERED_PANE:="layered pane"
    , ACCESSIBLE_LIST:="list"
    , ACCESSIBLE_LIST_ITEM:="list item"
    , ACCESSIBLE_MENU_BAR:="menu bar"
    , ACCESSIBLE_POPUP_MENU:="popup menu"
    , ACCESSIBLE_MENU:="menu"
    , ACCESSIBLE_MENU_ITEM:="menu item"
    , ACCESSIBLE_SEPARATOR:="separator"
    , ACCESSIBLE_PAGE_TAB_LIST:="page tab list"
    , ACCESSIBLE_PAGE_TAB:="page tab"
    , ACCESSIBLE_PANEL:="panel"
    , ACCESSIBLE_PROGRESS_BAR:="progress bar"
    , ACCESSIBLE_PASSWORD_TEXT:="password text"
    , ACCESSIBLE_PUSH_BUTTON:="push button"
    , ACCESSIBLE_TOGGLE_BUTTON:="toggle button"
    , ACCESSIBLE_CHECK_BOX:="check box"
    , ACCESSIBLE_RADIO_BUTTON:="radio button"
    , ACCESSIBLE_ROW_HEADER:="row header"
    , ACCESSIBLE_SCROLL_PANE:="scroll pane"
    , ACCESSIBLE_SCROLL_BAR:="scroll bar"
    , ACCESSIBLE_VIEWPORT:="viewport"
    , ACCESSIBLE_SLIDER:="slider"
    , ACCESSIBLE_SPLIT_PANE:="split pane"
    , ACCESSIBLE_TABLE:="table"
    , ACCESSIBLE_TEXT:="text"
    , ACCESSIBLE_TREE:="tree"
    , ACCESSIBLE_TOOL_BAR:="tool bar"
    , ACCESSIBLE_TOOL_TIP:="tool tip"
    , ACCESSIBLE_AWT_COMPONENT:="awt component"
    , ACCESSIBLE_SWING_COMPONENT:="swing component"
    , ACCESSIBLE_UNKNOWN:="unknown"
    , ACCESSIBLE_STATUS_BAR:="status bar"
    , ACCESSIBLE_DATE_EDITOR:="date editor"
    , ACCESSIBLE_SPIN_BOX:="spin box"
    , ACCESSIBLE_FONT_CHOOSER:="font chooser"
    , ACCESSIBLE_GROUP_BOX:="group box"
    , ACCESSIBLE_HEADER:="header"
    , ACCESSIBLE_FOOTER:="footer"
    , ACCESSIBLE_PARAGRAPH:="paragraph"
    , ACCESSIBLE_RULER:="ruler"
    , ACCESSIBLE_EDITBAR:="editbar"
    , PROGRESS_MONITOR:="progress monitor"

    static PropertyFromValue(obj, value) {
        for k, v in obj.OwnProps()
            if value == v
                return k
        throw UnsetItemError("Property item `"" value "`" not found!", -1)
    }
    static PropertyValueGetter := {get: (obj, value) => JAB.PropertyFromValue(obj, value)}

    ; MatchMode constants used in condition objects
    static MatchMode := {
        StartsWith:1,
        Substring:2,
        Exact:3,
        RegEx:"Regex"
    }

    ; Used wherever the scope variable is needed (eg Dump, FindElement, FindElements)
    static TreeScope := {
        Element:1,
        Children:2,
        Family:3,
        Descendants:4,
        Subtree:7
    }

    Static TreeTraversalOptions := {
        Default:0,
        PostOrder:1,
        LastToFirst:2,
        PostOrderLastToFirst:3
    }

    class TypeValidation {
        static Element(arg) {
            if !arg || (arg is JAB.JavaAccessibleContext)
                return arg
            throw TypeError("Element argument requires parameter with type JAB.JavaAccessibleContext, but received " Type(arg), -2)
        }
        static Integer(arg, paramName) {
            if IsInteger(arg)
                return Integer(arg)
            throw TypeError(paramName " requires type Integer, but received type " Type(arg), -2)
        }
        static String(arg, paramName) {
            if arg is String
                return arg
            if !(arg is Object)
                return String(arg)
            throw TypeError(paramName " requires type String, but received type " Type(arg), -2)
        }
        static Object(arg, paramName) {
            if arg is Object
                return arg
            throw TypeError(paramName " requires type Object, but received type " Type(arg), -2)
        }
        static TreeScope(arg) {
            if IsInteger(arg) {
                if arg < 1 || arg > 31
                    throw ValueError("UIA.TreeScope does not contain constant `"" arg "`"", -2)
                return Integer(arg)
            } else if arg is String {
                try return JAB.TreeScope.%arg%
                throw ValueError("JAB.TreeScope does not contain value for `"" arg "`"", -2)
            }
            throw TypeError("JAB.TreeScope requires parameter with type Integer or String, but received " Type(arg), -2)
        }
        static TreeTraversalOptions(arg) {
            if IsInteger(arg) {
                return Integer(arg)
            } else if arg is String {
                try return JAB.TreeTraversalOptions.%arg%
                try return JAB.TreeTraversalOptions.%arg "Order"%
                throw ValueError("JAB.TreeTraversalOptions does not contain value for `"" arg "`"", -2)
            }
            throw TypeError("Invalid type provided for JAB.TreeTraversalOptions", -2, "Allowed types are Integer and String, but was provided type " Type(arg))
        }
    }

    static __New() => this.base := JAB()

    __New(AutoEnableJABSwitch:=1, dll?, ForceLegacy:=0) {
        if IsSet(dll) {
            this.DLLVersion:=StrReplace(dll, ".dll")
            this.DLLHandle:=DllCall("LoadLibrary", "Str", dll, "ptr")
        } else {
            if ForceLegacy
                this.__LoadLegacy()
            else if (A_PtrSize=8) {
                this.DLLVersion:="WindowsAccessBridge-64"
                this.DLLHandle:=DllCall("LoadLibrary", "Str", this.DLLVersion ".dll", "ptr")
                if !this.DLLHandle && this.JavaHome {
                    this.DLLVersion := this.JavaHome "\bin\" this.DLLVersion ".dll"
                    this.DLLHandle:=DllCall("LoadLibrary", "Str", this.DLLVersion, "ptr")
                }
            } else {
                this.DLLVersion:="WindowsAccessBridge-32"
                this.DLLHandle:=DllCall("LoadLibrary", "Str", this.DLLVersion ".dll", "ptr")
                if !this.DLLHandle && this.JavaHome {
                    this.DLLVersion := this.JavaHome "\bin\" this.DLLVersion ".dll"
                    this.DLLHandle:=DllCall("LoadLibrary", "Str", this.DLLVersion, "ptr")
                }
                if (!this.DLLHandle) 
                    this.__LoadLegacy()
            }
        }

        if !this.DLLHandle
            throw Error("Failed to load JAB")
        ; DLLHandle := {ptr:DLLHandle}.DefineProp("__Delete", {call:(this, *) => DllCall("FreeLibrary", "ptr", this)}) ; Probably no need to free the library

        if AutoEnableJABSwitch {
            try RunWait("jabswitch /enable",, "Hide")
            catch {
                try RunWait(this.JavaHome "\bin\jabswitch /enable",, "Hide")
            }
        }
        ; Start up the access bridge
        If (!DllCall(this.DLLVersion "\Windows_run", "Cdecl Int")) {
            throw Error("Initializing JAB failed")
        }
        _DLLVersion := this.DLLVersion
        this.DLLVersion := "Java Access Bridge requires 200ms to startup! No JAB methods may be used before that."
        SetTimer((*) => this.DLLVersion := _DLLVersion, -200)
    }

    __LoadLegacy() {
        this.DLLVersion:="WindowsAccessBridge"
        this.DLLHandle:=DllCall("LoadLibrary", "Str", this.DLLVersion ".dll", "ptr")
        this.acType:="Int"
        this.acPType:="Int*"
        this.acSize:=4
    }

    static ElementFromHandle(WinTitle:="") => this.base.ElementFromHandle(WinTitle)
    ; retrieves the root element from a window
    ElementFromHandle(WinTitle:="") {
        if !DllCall(this.DLLVersion "\isJavaWindow", "ptr", hWnd := WinGetID(WinTitle), "cdecl int")
            throw TargetError("The specified window is not a Java window")
        if (DllCall(this.DLLVersion "\getAccessibleContextFromHWND", "ptr", hWnd := WinExist(WinTitle), "Int*", &vmID:=0, this.acPType, &ac:=0, "Cdecl Int"))
            return JAB.JavaAccessibleContext(vmID, ac, this)
        throw Error("Failed to get accessible context for the specified window")
    }

    static GetFocusedElement() => this.base.GetFocusedElement()
    GetFocusedElement() {
        if !(hWnd := this.GetFocusedJavaWindow())
            return 0
        if (DllCall(this.DLLVersion "\getAccessibleContextWithFocus", "ptr", hwnd, "Int*", &vmID:=0, this.acPType, &ac:=0, "Cdecl Int"))
            return JAB.JavaAccessibleContext(vmID, ac, this)
        return 0
    }

    static IsJavaWindow(WinTitle:="", WinText:="", ExcludeTitle:="", ExcludeText:="") => this.base.IsJavaWindow(WinTitle, WinText, ExcludeTitle, ExcludeText)
    IsJavaWindow(WinTitle:="", WinText:="", ExcludeTitle:="", ExcludeText:="") => DllCall(this.DLLVersion "\isJavaWindow", "Ptr", WinGetID(WinTitle, WinText, ExcludeTitle, ExcludeText), "Cdecl Int")

    static GetFocusedJavaWindow() => this.base.GetFocusedJavaWindow()
    GetFocusedJavaWindow() {
        if this.IsJavaWindow(hWnd := WinExist("A"))
            return hWnd
        else {
            if (this.IsJavaWindow(hWnd := ControlGetFocus(hWnd)))
                return hWnd
        }
        return 0
    }

    static CompareElements(el1, el2) => this.base.CompareElements(el1, el2)
    CompareElements(el1, el2) => el1 is JAB.JavaAccessibleContext && el2 is JAB.JavaAccessibleContext && el1.__vmID == el2.__vmID && DllCall(this.DLLVersion "\isSameObject", "Int", el1.__vmID, this.acType, el1.__ac, this.acType, el2.__ac, "Cdecl Int")

    static ElementFromPoint(x?, y?) => this.base.ElementFromPoint(x?, y?)
    ElementFromPoint(x?, y?) {
        if !(IsSet(x) && IsSet(y))
            DllCall("GetCursorPos", "int64P", &pt64:=0), x := 0xFFFFFFFF & pt64, y := pt64 >> 32
        else
            pt64 := y << 32 | (x & 0xFFFFFFFF)
        hWnd := DllCall("GetAncestor", "Ptr", DllCall("user32.dll\WindowFromPoint", "int64",  pt64, "ptr"), "UInt", 2, "ptr")
        if !this.IsJavaWindow(hWnd)
            return 0

        baseEl := this.ElementFromHandle(hWnd)
        if DllCall(baseEl.JAB.DLLVersion "\getAccessibleContextAt", "Int", baseEl.__vmID, baseEl.JAB.acType, baseEl.__ac, "Int", x, "Int", y, baseEl.JAB.acPType, &ac:=0, "Cdecl Int") && ac
			baseEl := JAB.JavaAccessibleContext(baseEl.__vmID, ac, baseEl.JAB)
        
        local el, evaluate := baseEl.GetDescendants(5), smallest := baseEl, smallestSize := 100000000
        for el in evaluate {
            loc := el.Location
            if x >= loc.x && y >= loc.y && x <= (loc.x+loc.w) && y <= (loc.y+loc.h) {
                if (size := loc.w*loc.h) < smallestSize
                    smallest := el, smallestSize := size
            }
        }
        return smallest
    }

    static ClearAllHighlights() => this.JavaAccessibleContext.Prototype.Highlight("clearall")

    static __ExtractNamedParameters(obj, params*) {
        local i := 0
        if !IsObject(obj) || Type(obj) != "Object"
            return 0
        Loop params.Length // 2 {
            name := params[++i], value := params[++i]
            if obj.HasProp(name)
                %value% := obj.%name%
        }
        return 1
    }

    __EventHandlers := JAB.Mapi(
        "FocusGained", 0, 
        "FocusLost", 0, 
        "CaretUpdate", 0, 
        "MouseClicked", 0, 
        "MouseEntered", 0, 
        "MouseExited", 0, 
        "MousePressed", 0, 
        "MouseReleased", 0, 
        "MenuCanceled", 0, 
        "MenuDeselected", 0, 
        "MenuSelected", 0, 
        "PopupMenuCanceled", 0, 
        "PopupMenuWillBecomeInvisible", 0, 
        "PopupMenuWillBecomeVisible", 0, 
        "PropertyNameChange", 0, 
        "PropertyDescriptionChange", 0, 
        "PropertyStateChange", 0, 
        "PropertyValueChange", 0, 
        "PropertySelectionChange", 0, 
        "PropertyTextChange", 0, 
        "PropertyCaretChange", 0, 
        "PropertyVisibleDataChange", 0, 
        "PropertyChildChange", 0, 
        "PropertyActiveDescendentChange", 0, 
        "PropertyTableModelChange", 0,
        "JavaShutdown", 0)
    static RegisterEvent(eventName, handler:=0) => this.base.RegisterEvent(eventName, handler)
    RegisterEvent(eventName, handler:=0) {
        if !this.__EventHandlers.Has(eventName)
            throw ValueError("Non-existant event name", -1)
        if this.__EventHandlers[eventName]
            CallbackFree(this.__EventHandlers[eventName])
        DllCall(this.DLLVersion "\set" eventName "FP", "Ptr", this.__EventHandlers[eventName] := handler ? CallbackCreate(this.__HandleEvent.Bind(this, handler), "CDecl", 3) : 0, "Cdecl")
    }

    ; X can be pt64 as well, in which case Y should be omitted
    static WindowFromPoint(X, Y?) { ; by SKAN and Linear Spoon
        return DllCall("GetAncestor", "Ptr", DllCall("user32.dll\WindowFromPoint", "Int64", IsSet(Y) ? (Y << 32 | (X & 0xFFFFFFFF)) : X), "UInt", 2, "Ptr")
    }

    __HandleEvent(handler, vmID, event, source) => handler(JAB.JavaAccessibleContext(vmID, source, this), event)

    __Delete(*) {
        for k, v in this.__EventHandlers
            if v
                DllCall(this.DLLVersion "\set" k "FP", "Ptr", 0, "CDecl"), CallbackFree(v)
        DllCall("FreeLibrary", "ptr", this.DLLVersion)
    }

    class Mapi extends Map {
        CaseSense := 0
    }

    class JavaAccessibleObject {
        __vmID:=0, __ac:=0
        __New(vmID, ac, JAB, obj?) {
            If (vmID and ac)
                this.__vmID:=vmID, this.__ac:=ac, this.JAB := JAB, IsSet(obj) ? this.__obj := obj : ""
            else
                throw Error("Invalid ID or context")
        }
    }

    class JavaAccessibleContext extends JAB.JavaAccessibleObject {
        __LastElementInfo := 0, __LastElementInfoTickCount := 0
        __UpdateLastElementInfo() => (this.__LastElementInfoTickCount = A_TickCount ? "" : (this.__LastElementInfoTickCount := A_TickCount, this.__LastElementInfo := this.GetElementInfo()))

        Id => this.__vmID ":" this.__ac

        Name => (this.__UpdateLastElementInfo(), this.__LastElementInfo.Name)
        Description => (this.__UpdateLastElementInfo(), this.__LastElementInfo.Description)
        LocalizedRole => (this.__UpdateLastElementInfo(), this.__LastElementInfo.LocalizedRole)
        Role => (this.__UpdateLastElementInfo(), this.__LastElementInfo.Role)
        LocalizedStates => (this.__UpdateLastElementInfo(), this.__LastElementInfo.LocalizedStates)
        States => (this.__UpdateLastElementInfo(), this.__LastElementInfo.States)
        IndexInParent => (this.__UpdateLastElementInfo(), this.__LastElementInfo.IndexInParent)
        Length => (this.__UpdateLastElementInfo(), this.__LastElementInfo.Length)
        Depth => (this.DefineProp("Depth", {value:DllCall(this.JAB.DLLVersion "\getObjectDepth", "Int", this.__vmID, this.JAB.acType, this.__ac, "Cdecl Int")}), this.Depth)
        X => (this.__UpdateLastElementInfo(), this.__LastElementInfo.X)
        Y => (this.__UpdateLastElementInfo(), this.__LastElementInfo.Y)
        W => (this.__UpdateLastElementInfo(), this.__LastElementInfo.W)
        H => (this.__UpdateLastElementInfo(), this.__LastElementInfo.H)
        Location => (this.__UpdateLastElementInfo(), this.__LastElementInfo.Location)
        AccessibleComponent => (this.__UpdateLastElementInfo(), this.__LastElementInfo.AccessibleComponent)
        AccessibleAction => (this.__UpdateLastElementInfo(), this.__LastElementInfo.AccessibleAction)
        AccessibleSelection => (this.__UpdateLastElementInfo(), this.__LastElementInfo.AccessibleSelection)
        AccessibleText => (this.__UpdateLastElementInfo(), this.__LastElementInfo.AccessibleText)
        
        IsValueInterfaceAvailable => (this.__UpdateLastElementInfo(), this.__LastElementInfo.IsValueInterfaceAvailable)
        IsActionInterfaceAvailable => (this.__UpdateLastElementInfo(), this.__LastElementInfo.IsActionInterfaceAvailable)
        IsComponentInterfaceAvailable => (this.__UpdateLastElementInfo(), this.__LastElementInfo.IsComponentInterfaceAvailable)
        IsSelectionInterfaceAvailable => (this.__UpdateLastElementInfo(), this.__LastElementInfo.IsSelectionInterfaceAvailable)
        IsTableInterfaceAvailable => (this.__UpdateLastElementInfo(), this.__LastElementInfo.IsTableInterfaceAvailable)
        IsTextInterfaceAvailable => (this.__UpdateLastElementInfo(), this.__LastElementInfo.IsTextInterfaceAvailable)
        IsHypertextInterfaceAvailable => (this.__UpdateLastElementInfo(), this.__LastElementInfo.IsHypertextInterfaceAvailable)
        AvailableInterfaces => (this.__UpdateLastElementInfo(), this.__LastElementInfo.AvailableInterfaces)

        KeyBindings {
            get {
                static KeyMap := Map(8, "Backspace", 127, "Delete", 40, "Down", 35, "End", 36, "Home", 155, "Insert", 225, "KeypadDown", 226, "KeypadLeft", 227, "KeypadRight", 224, "KeypadUp", 37, "Left", 34, "PgDown", 33, "PgUp", 39, "Right", 38, "Up")
                if DllCall(this.JAB.DLLVersion "\getAccessibleKeyBindings", "Int", this.__vmID, this.JAB.acType, this.__ac, "Ptr", keyBindings := Buffer(4+10*JAB.MAX_KEY_BINDINGS, 0), "Cdecl int") {
                    str := "", offset := 4
                    Loop keyBindingsCount := Min(NumGet(keyBindings.Ptr, 0, "int"), JAB.MAX_KEY_BINDINGS)  {
                        modifiers := NumGet(keyBindings.Ptr, offset+4, "int"), key := NumGet(keyBindings.Ptr, offset, "ushort")
                        str .= (modifiers & 0x2 ? "Ctrl+" : "") (modifiers & 0x1 ? "Shift+" : "") (modifiers & 0x8 ? "Alt+" : "") (modifiers & 0x4 ? "Win+" : "") (KeyMap.Has(key) ? KeyMap[key] : Chr(key)) ", "
                        offset += 8
                    }
                    return (this.DefineProp("KeyBindings", {value:SubStr(str, 1, -2)}), this.KeyBindings)
                }
                return ""
            }
        }

        WinId => (this.DefineProp("WinId", {value:DllCall(this.JAB.DLLVersion "\getHWNDFromAccessibleContext", "Int", this.__vmID, this.JAB.acType, this.__ac, "Cdecl Ptr") || DllCall(this.JAB.DLLVersion "\getHWNDFromAccessibleContext", "Int", (winEl := this.RootElement).__vmID, this.JAB.acType, winEl.__ac, "Cdecl Ptr")}), this.WinId)
        Hwnd => this.WinId

        Exists { ; TODO : add additional criteria besides position?
            get {
                try {
                    if (((pos := this.Location).x==-1) && (pos.y==-1) && (pos.w==-1) && (pos.h==-1))
                        return 0
                } catch
                    return 0
                return 1
            }
        }

        __Item[params*] {
            get {
                oContext := this
                for param in params {
                    if IsInteger(param)
                        oContext := oContext.GetNthChild(param)
                    else if IsObject(param)
                        oContext := oContext.FindElement(param, 2)
                    else if param is String
                        oContext := oContext.ElementFromPath(param)
                    else
                        TypeError("Invalid item type!", -1)
                }
                return oContext
            }
        }

        __Enum(varCount) {
            maxLen := this.Length, i := 0, children := this.Children
            EnumElements(&element) {
                if ++i > maxLen
                    return false
                element := children[i]
                return true
            }
            EnumIndexAndElements(&index, &element) {
                if ++i > maxLen
                    return false
                index := i
                element := children[i]
                return true
            }
            return (varCount = 1) ? EnumElements : EnumIndexAndElements
        }

        Parent {
            get {
                if (ac:=DllCall(this.JAB.DLLVersion "\getAccessibleParentFromContext", "Int", this.__vmID, this.JAB.acType, this.__ac, "Cdecl " this.JAB.acType))
                    return (this.DefineProp("Parent", {value:JAB.JavaAccessibleContext(this.__vmID, ac, this.JAB)}), this.Parent)
                throw UnsetError("No parent found", -1)
            }
        }

        RootElement {
            get {
                if (ac:=DllCall(this.JAB.DLLVersion "\getTopLevelObject", "Int", this.__vmID, this.JAB.acType, this.__ac, "Cdecl " this.JAB.acType))
                    return (this.DefineProp("RootElement", {value:JAB.JavaAccessibleContext(this.__vmID, ac, this.JAB)}), this.RootElement)
                throw Error("Unable to get root element", -1)
            }
        }

        Children {
            get {
                children := []
                Loop this.Length
                    try children.Push(this[A_Index])
                return children
            }
        }

        VisibleChildren {
            get {
                children := [], len := this.VisibleLength, i := 0
                Loop {
                    TempChildren := Buffer(257*this.JAB.acSize, 0)
                    if (DllCall(this.JAB.DLLVersion "\getVisibleChildren", "Int", this.__vmID, this.JAB.acType, this.__ac, "Int", i, "Ptr", TempChildren, "Cdecl Int") && numret:=NumGet(TempChildren.Ptr, 0, "Int")) {
                        Loop numret
                            children.Push(JAB.JavaAccessibleContext(this.__vmID, NumGet(TempChildren.Ptr, this.JAB.acSize*A_Index, this.JAB.acType), this.JAB))
                        i+=numret
                    } else
                        break
                } Until i >= len
                return children
            }
        }

        VisibleLength => DllCall(this.JAB.DLLVersion "\getVisibleChildrenCount", "Int", this.__vmID, this.JAB.acType, this.__ac, "Cdecl Int")

        ;; Value Interface
        Value {
            get {
                if DllCall(this.JAB.DLLVersion "\getCurrentAccessibleValueFromContext", "int", this.__vmID, this.JAB.acType, this.__ac, "ptr", pStr := Buffer(JAB.MAX_STRING_SIZE*2, 0), "short", JAB.MAX_STRING_SIZE, "CDecl Int")
                    return StrGet(pStr.ptr, JAB.MAX_STRING_SIZE, "UTF-16")
                throw Error("Unable to get value", -1)
            }
        }
        Maximum {
            get {
                if DllCall(this.JAB.DLLVersion "\getMaximumAccessibleValueFromContext", "int", this.__vmID, this.JAB.acType, this.__ac, "ptr", pStr := Buffer(JAB.MAX_STRING_SIZE*2, 0), "short", JAB.MAX_STRING_SIZE, "CDecl Int")
                    return StrGet(pStr, JAB.MAX_STRING_SIZE, "UTF-16")
                throw Error("Unable to get value", -1)
            }
        }
        Minimum {
            get {
                if DllCall(this.JAB.DLLVersion "\getMinimumAccessibleValueFromContext", "int", this.__vmID, this.JAB.acType, this.__ac, "ptr", pStr := Buffer(JAB.MAX_STRING_SIZE*2, 0), "short", JAB.MAX_STRING_SIZE, "CDecl Int")
                    return StrGet(pStr, JAB.MAX_STRING_SIZE, "UTF-16")
                throw Error("Unable to get value", -1)
            }
        }

        ;; Text Interface

        Text {
            get => this.GetTextRange()
            set => this.SetTextContents(Value)
        }

        ; retrieves information about a certain text element as an object with the keys:
        ; CharCount, CaretIndex, IndexAtPoint
        GetTextInfo(x:=0, y:=0) {
            if (DllCall(this.JAB.DLLVersion "\getAccessibleTextInfo", "Int", this.__vmID, this.JAB.acType, this.__ac, "Ptr", Info := Buffer(12, 0), "Int", x, "Int", y, "Cdecl Int"))
                return {CharCount:NumGet(Info.Ptr, 0, "Int"), CaretIndex:NumGet(Info.Ptr, 4, "Int"), IndexAtPoint:NumGet(Info.Ptr, 8, "Int")}
            return 0
        }

        ; retrieves the text items as an object with the keys:
        ; letter, word, sentence
        GetTextItems(Index) {
            If (DllCall(this.JAB.DLLVersion "\getAccessibleTextItems", "Int", this.__vmID, this.JAB.acType, this.__ac, "Ptr", Info := Buffer(2562, 0), "Int", Index, "Cdecl Int"))
                return {letter:Chr(NumGet(Info.Ptr, 0, "UChar")), word:StrGet(Info.Ptr+2, JAB.SHORT_STRING_SIZE, "UTF-16"), sentence:StrGet(Info.Ptr+2+JAB.SHORT_STRING_SIZE*2, JAB.MAX_STRING_SIZE, "UTF-16")}
            return 0
        }

        ; retrieves the currently selected text and its start and end index as an object with the keys:
        ; SelectionStartIndex, SelectionEndIndex, SelectedText
        GetTextSelectionInfo() {
            if (DllCall(this.JAB.DLLVersion "\getAccessibleTextSelectionInfo", "Int", this.__vmID, this.JAB.acType, this.__ac, "Ptr", Info := Buffer(this.JAB.MAX_STRING_SIZE*2+8, 0), "Cdecl Int"))
                return {SelectionStartIndex:NumGet(Info.Ptr, 0, "Int"), SelectionEndIndex:NumGet(Info.Ptr, 4, "Int"), SelectedText:StrGet(Info.Ptr+8, this.JAB.MAX_STRING_SIZE, "UTF-16")}
            return 0
        }

        ; retrieves the text attributes as an object with the keys:
        ; bold, italic, underline, strikethrough, superscript, subscript,
        ; backgroundColor, foregroundColor, fontFamily, fontSize,
        ; alignment, bidiLevel, firstLineIndent, leftIndent, rightIndent,
        ; lineSpacing, spaceAbove, spaceBelow, fullAttributesString
        GetTextAttributes() {
            if (DllCall(this.JAB.DLLVersion "\getAccessibleTextAttributes", "Int", this.__vmID, this.JAB.acType, this.__ac, "Ptr", Info := Buffer(3644, 0), "Cdecl Int"))
                return {
                    bold:NumGet(Info.Ptr, 0, "Int"),
                    italic:NumGet(Info.Ptr, 4, "Int"),
                    underline:NumGet(Info.Ptr, 8, "Int"),
                    strikethrough:NumGet(Info.Ptr, 12, "Int"),
                    superscript:NumGet(Info.Ptr, 16, "Int"),
                    subscript:NumGet(Info.Ptr, 20, "Int"),
                    backgroundColor:StrGet(Info.Ptr+(Offset:=24), JAB.SHORT_STRING_SIZE, "UTF-16"),
                    foregroundColor:StrGet(Info.Ptr+(Offset+=JAB.SHORT_STRING_SIZE*2), JAB.SHORT_STRING_SIZE, "UTF-16"),
                    fontFamily:StrGet(Info.Ptr+(Offset+=JAB.SHORT_STRING_SIZE*2), JAB.SHORT_STRING_SIZE, "UTF-16"),
                    fontSize:NumGet(Info.Ptr, Offset+=JAB.SHORT_STRING_SIZE*2, "Int"),
                    alignment:NumGet(Info.Ptr, Offset+=4, "Int"),
                    bidiLevel:NumGet(Info.Ptr, Offset+=4, "Int"),
                    firstLineIndent:NumGet(Info.Ptr, Offset+=4, "Float"),
                    leftIndent:NumGet(Info.Ptr, Offset+=4, "Float"),
                    rightIndent:NumGet(Info.Ptr, Offset+=4, "Float"),
                    lineSpacing:NumGet(Info.Ptr, Offset+=4, "Float"),
                    spaceAbove:NumGet(Info.Ptr, Offset+=4, "Float"),
                    spaceBelow:NumGet(Info.Ptr, Offset+=4, "Float"),
                    fullAttributesString:StrGet(Info.Ptr+Offset+4, JAB.MAX_STRING_SIZE, "UTF-16")
                }
            return 0
        }

        ; retrieves the location of position Index as an object with the keys:
        ; X, Y, W, H
        GetTextRect(Index) {
            if (DllCall(this.JAB.DLLVersion "\getAccessibleTextRect", "Int", this.__vmID, this.JAB.acType, this.__ac, "Ptr", Info := Buffer(16, 0), "Int", Index, "Cdecl Int"))
                return {X:NumGet(Info.Ptr, 0, "Int"), Y:NumGet(Info.Ptr, 4, "Int"), W:NumGet(Info.Ptr, 8, "Int"), H:NumGet(Info.Ptr, 12, "Int")}
            return 0
        }

        ; retrieves text between start and end index
        GetTextRange(startc:=0, endc:=0) {
            TInfo := this.GetTextInfo(), startc := Max(0, startc), endc := Min(TInfo.CharCount-1, endc = 0 ? 0xFFFFFFFF : endc), len:=endc-startc
            if (DllCall(this.JAB.DLLVersion "\getAccessibleTextRange", "Int", this.__vmID, this.JAB.acType, this.__ac, "Int", startc, "Int", endc, "Ptr", Txt := Buffer(len*2, 0), "short", len, "Cdecl Int"))
                return StrGet(Txt, len, "UTF-16")
            return ""
        }

        ; retrieves the start and end index of the line containing Index as an object with the keys:
        ; StartPos, EndPos
        GetTextLineBounds(Index) {
            if (DllCall(this.JAB.DLLVersion "\getAccessibleTextLineBounds", "Int", this.__vmID, this.JAB.acType, this.__ac, "Int*", &StartPos:=0, "Int*", &EndPos:=0, "Cdecl Int"))
                return {StartPos:StartPos, EndPos:EndPos}
            return 0
        }

        SelectTextRange(startIndex, endIndex) => DllCall(this.JAB.DLLVersion "\selectTextRange", "Int", this.__vmID, this.JAB.acType, this.__ac, "Int", startIndex, "Int", endIndex, "Cdecl Int")

        GetTextAttributesInRange(startIndex, endIndex) {
            if (DllCall(this.JAB.DLLVersion "\getTextAttributesInRange", "Int", this.__vmID, this.JAB.acType, this.__ac, "Int", startIndex, "Int", endIndex, "Ptr", Info := Buffer(3644, 0), "short*", &len:=0, "Cdecl Int"))
                return {
                    length:len,
                    bold:NumGet(Info.Ptr, 0, "Int"),
                    italic:NumGet(Info.Ptr, 4, "Int"),
                    underline:NumGet(Info.Ptr, 8, "Int"),
                    strikethrough:NumGet(Info.Ptr, 12, "Int"),
                    superscript:NumGet(Info.Ptr, 16, "Int"),
                    subscript:NumGet(Info.Ptr, 20, "Int"),
                    backgroundColor:StrGet(Info.Ptr+(Offset:=24), JAB.SHORT_STRING_SIZE, "UTF-16"),
                    foregroundColor:StrGet(Info.Ptr+(Offset+=JAB.SHORT_STRING_SIZE*2), JAB.SHORT_STRING_SIZE, "UTF-16"),
                    fontFamily:StrGet(Info.Ptr+(Offset+=JAB.SHORT_STRING_SIZE*2), JAB.SHORT_STRING_SIZE, "UTF-16"),
                    fontSize:NumGet(Info.Ptr, Offset+=JAB.SHORT_STRING_SIZE*2, "Int"),
                    alignment:NumGet(Info.Ptr, Offset+=4, "Int"),
                    bidiLevel:NumGet(Info.Ptr, Offset+=4, "Int"),
                    firstLineIndent:NumGet(Info.Ptr, Offset+=4, "Float"),
                    leftIndent:NumGet(Info.Ptr, Offset+=4, "Float"),
                    rightIndent:NumGet(Info.Ptr, Offset+=4, "Float"),
                    lineSpacing:NumGet(Info.Ptr, Offset+=4, "Float"),
                    spaceAbove:NumGet(Info.Ptr, Offset+=4, "Float"),
                    spaceBelow:NumGet(Info.Ptr, Offset+=4, "Float"),
                    fullAttributesString:StrGet(Info.Ptr+Offset+4, JAB.MAX_STRING_SIZE, "UTF-16")
                }
            return 0
        }

        GetCaretLocation(Index:=1) {
            if (DllCall(this.JAB.DLLVersion "\getCaretLocation", "Int", this.__vmID, this.JAB.acType, this.__ac, "Ptr", Info := Buffer(16, 0), "Int", Index-1, "Cdecl Int"))
                return {X:NumGet(Info.Ptr, 0, "Int"), Y:NumGet(Info.Ptr, 4, "Int"), W:NumGet(Info.Ptr, 8, "Int"), H:NumGet(Info.Ptr, 12, "Int")}
            return 0
        }

        SetCaretPosition(Position) => DllCall(this.JAB.DLLVersion "\setCaretPosition", "Int", this.__vmID, this.JAB.acType, this.__ac, "Int", position, "Cdecl Int")

        SetTextContents(Text) {
            len := StrLen(Text), TempStr := Buffer(len*2 + 2, 0)
            StrPut(Text, TempStr.ptr, len, "UTF-16")
            return DllCall(this.JAB.DLLVersion "\setTextContents", "Int", this.__vmID, this.JAB.acType, this.__ac, "UInt", TempStr.Ptr, "Cdecl Int")
        }

        ;; Hypertext Interface : partially implemented
        Hyperlinks {
            get {
                static SizeofAccessibleHypertextInfo := JAB.SHORT_STRING_SIZE*2 + 4 + this.JAB.acSize
                if this.IsHypertextInterfaceAvailable && DllCall(this.JAB.DLLVersion "\getAccessibleHypertext", "int", this.__vmID, this.JAB.acType, this.__ac, "ptr", Info := Buffer(4+JAB.MAX_HYPERLINKS*SizeofAccessibleHypertextInfo+this.JAB.acSize, 0)) {
                    linkCount := NumGet(Info.ptr, "int"), offset := 4, links := []
                    Loop linkCount {
                        links.Push(link := JAB.JavaAccessibleHyperlink(this.__vmID, this.__ac, this.JAB, NumGet(Info.Ptr, offset+SizeofAccessibleHypertextInfo-this.JAB.acSize, this.JAB.acType)))
                        link.Text := StrGet(Info.Ptr+offset, JAB.SHORT_STRING_SIZE, "UTF-16")
                        link.startIndex := NumGet(Info.Ptr, offset+JAB.SHORT_STRING_SIZE*2, "int")
                        link.endIndex := NumGet(Info.Ptr, offset+JAB.SHORT_STRING_SIZE*2+4, "int")
                        offset += SizeofAccessibleHypertextInfo
                    }
                    return links
                }
                return 0
            }
        }

        ;; Relations Interface : UNTESTED

        GetRelations() {
            if DllCall(this.JAB.DLLVersion "\getAccessibleRelationSet", "int", this.__vmID, this.JAB.acType, this.__ac, "ptr", relationSetInfo := Buffer(4+JAB.MAX_RELATIONS*(this.JAB.acSize*JAB.MAX_RELATION_TARGETS+4+JAB.SHORT_STRING_SIZE*2), 0), "Cdecl Int") {
                offset := 4, relations := []
                Loop relationCount := NumGet(relationSetInfo.Ptr, "int") {
                    key := StrGet(relationSetInfo.Ptr+offset, JAB.SHORT_STRING_SIZE, "UTF-16")
                    offset += 2*JAB.SHORT_STRING_SIZE
                    targets := [], targetCount := NumGet(relationSetInfo.Ptr, offset, "int")
                    offset += 4
                    Loop targetCount {
                        if ac := NumGet(relationSetInfo.Ptr, offset, this.JAB.acType)
                            targets.Push(JAB.JavaAccessibleContext(this.__vmID, ac, this.JAB))
                        offset += this.JAB.acSize
                    }
                    relations.Push({key:key, targets:targets})
                }
                return relations
            }
            
            return 0
        }

        ;; Table Interface : NOT IMPLEMENTED

        GetTable() {
            if DllCall(this.JAB.DLLVersion "\getAccessibleTableInfo", "int", this.__vmID, this.JAB.acType, this.__ac, "ptr", tableInfo:=Buffer(40, 0), "Cdecl Int")
                return JAB.JavaAccessibleTable.__GetTable(this, tableInfo)
            throw Error("Unable to get table info", -1)
        }

        ;; Selection Interface

        AddSelection(i) => DllCall(this.JAB.DLLVersion "\addAccessibleSelectionFromContext", "int", this.__vmID, this.JAB.acType, this.__ac, "int", i-1, "Cdecl")
        RemoveSelection(i) => DllCall(this.JAB.DLLVersion "\removeAccessibleSelectionFromContext", "int", this.__vmID, this.JAB.acType, this.__ac, "int", i-1, "Cdecl")
        ClearSelections() => DllCall(this.JAB.DLLVersion "\clearAccessibleSelectionFromContext", "int", this.__vmID, this.JAB.acType, this.__ac, "Cdecl")
        GetSelection(i) {
            if (ac := DllCall(this.JAB.DLLVersion "\getAccessibleSelectionFromContext", "int", this.__vmID, this.JAB.acType, this.__ac, "int", i-1, "Cdecl " this.JAB.acType))
                return JAB.JavaAccessibleContext(this.__vmID, ac, this.JAB)
            return 0
        }
        SelectionCount => DllCall(this.JAB.DLLVersion "\getAccessibleSelectionCountFromContext", "int", this.__vmID, this.JAB.acType, this.__ac, "Cdecl int")
        IsChildSelected(i) => DllCall(this.JAB.DLLVersion "\isAccessibleChildSelectedFromContext", "int", this.__vmID, this.JAB.acType, this.__ac, "int", i-1, "Cdecl int")
        SelectAll() => DllCall(this.JAB.DLLVersion "\selectAllAccessibleSelectionFromContext", "int", this.__vmID, this.JAB.acType, this.__ac, "Cdecl")

        ;; Action Interface

        Actions {
            get {
                Actions := Buffer(256*256*2+A_PtrSize, 0)
                if DllCall(this.JAB.DLLVersion "\getAccessibleActions", "Int", this.__vmID, this.JAB.acType, this.__ac, "Ptr", Actions.Ptr, "Cdecl Int") {
                    arr := []
                    numActions:=NumGet(Actions.Ptr, 0, "Int")
                    Offset := 4
                    Loop numActions {
                        arr.Push(StrGet(Actions.ptr+Offset, JAB.SHORT_STRING_SIZE, "UTF-16"))
                        Offset += JAB.SHORT_STRING_SIZE*2
                    }
                    return arr
                }
                return []
            }
        }

        DoDefaultAction() => this.DoAccessibleActions([this.Actions[1]])

        DoAccessibleActions(actions) {
            pActions := Buffer(256*256*2+A_PtrSize, 0)
            NumPut("Int", actions.Length, pActions.Ptr, 0)
            offset := 4
            for action in actions {
                StrPut(action, pActions.ptr+offset, JAB.SHORT_STRING_SIZE, "UTF-16")
                offset += JAB.SHORT_STRING_SIZE
                NumPut("Int", A_Index, pActions.Ptr, 0)
            }
            DllCall(this.JAB.DLLVersion "\doAccessibleActions", "Int", this.__vmID, this.JAB.acType, this.__ac, "Ptr", pActions, "Int*", &failure:=0, "Cdecl Int")
            return failure
        }

        SetFocus() => DllCall(this.JAB.DLLVersion "\requestFocus", "Int", this.__vmID, this.JAB.acType, this.__ac, "Cdecl Int")

        ;; General functions

        GetDescendants(scope:=4) {
            scope := IsInteger(scope) ? scope : JAB.TreeScope.%scope%
            result := []
            if scope&1
                result.Push(this)
            if scope&4
                RecurseTree(this)
            else if scope&2
                Loop this.Length
                    result.Push(this[A_Index])
            return result
            
            RecurseTree(parent) {
                for child in parent.Children
                    result.Push(child), RecurseTree(child)
            }
        }

        GetElementInfo() {
            Info := Buffer(6188, 0)
            if (DllCall(this.JAB.DLLVersion "\getAccessibleContextInfo", "Int", this.__vmID, this.JAB.acType, this.__ac, "Ptr", Info, "Cdecl Int")) {
                ret := {}
                Offset:=0
                ret.Name := StrGet(info.ptr+Offset, JAB.MAX_STRING_SIZE, "UTF-16")
                Offset += 2*JAB.MAX_STRING_SIZE
                ret.Description := StrGet(info.ptr+Offset, JAB.MAX_STRING_SIZE, "UTF-16")
                Offset += 2*JAB.MAX_STRING_SIZE
                ret.LocalizedRole := StrGet(info.ptr+Offset, JAB.SHORT_STRING_SIZE, "UTF-16")
                Offset += 2*JAB.SHORT_STRING_SIZE
                ret.Role := StrGet(info.ptr+Offset, JAB.SHORT_STRING_SIZE, "UTF-16")
                Offset += 2*JAB.SHORT_STRING_SIZE
                ret.LocalizedStates := StrGet(info.ptr+Offset, JAB.SHORT_STRING_SIZE, "UTF-16")
                Offset += 2*JAB.SHORT_STRING_SIZE
                ret.States := StrGet(info.ptr+Offset, JAB.SHORT_STRING_SIZE, "UTF-16")
                Offset += 2*JAB.SHORT_STRING_SIZE
                ret.IndexInParent := NumGet(Info.Ptr, Offset, "Int")
                Offset+=4
                ret.Length := NumGet(Info.Ptr, Offset, "Int")
                Offset+=4
                ret.X := NumGet(Info.Ptr, Offset, "Int")
                Offset+=4
                ret.Y := NumGet(Info.Ptr, Offset, "Int")
                Offset+=4
                ret.W := NumGet(Info.Ptr, Offset, "Int")
                Offset+=4
                ret.H := NumGet(Info.Ptr, Offset, "Int")
                ret.Location := {X:ret.X, Y:ret.Y, W:ret.W, H:ret.H}
                Offset+=4
                ret.AccessibleComponent := NumGet(Info.Ptr, Offset, "Int")
                Offset+=4
                ret.AccessibleAction := NumGet(Info.Ptr, Offset, "Int")
                Offset+=4
                ret.AccessibleSelection := NumGet(Info.Ptr, Offset, "Int")
                Offset+=4
                ret.AccessibleText := NumGet(Info.Ptr, Offset, "Int")
                Offset+=4
                tmp:=NumGet(Info.Ptr, Offset, "Int")
                ret.IsValueInterfaceAvailable := !!(tmp & 1)
                ret.IsActionInterfaceAvailable := !!(tmp & 2)
                ret.IsComponentInterfaceAvailable := !!(tmp & 4)
                ret.IsSelectionInterfaceAvailable := !!(tmp & 8)
                ret.IsTableInterfaceAvailable := !!(tmp & 16)
                ret.IsTextInterfaceAvailable := !!(tmp & 32)
                ret.IsHypertextInterfaceAvailable := !!(tmp & 64)
                ret.AvailableInterfaces := SubStr((ret.IsValueInterfaceAvailable ? "value," : "") (ret.IsActionInterfaceAvailable ? "action," : "") (ret.IsComponentInterfaceAvailable ? "component," : "") (ret.IsSelectionInterfaceAvailable ? "selection," : "") (ret.IsTableInterfaceAvailable ? "table," : "") (ret.IsTextInterfaceAvailable ? "text," : "") (ret.IsHypertextInterfaceAvailable ? "hypertext," : ""), 1, -1)
                return ret
            }
            throw Error("Failed to get accessible info", -1)
        }

        BuildUpdatedCache(properties, scope:=1) {
            if scope&1 {
                for prop in properties {
                    this.Cached%prop% := this.%prop%
                }
            } else if scope > 1 {
                this.CachedChildren := this.Children
                this.CachedLength := this.CachedChildren.Length
                for child in this.CachedChildren
                    child.BuildUpdatedCache(properties, scope&4 ? 5 : 1)
            }
        }

        GetNthChild(index) {
            local ac
            If (ac:=DllCall(this.JAB.DLLVersion "\getAccessibleChildFromContext", "Int", this.__vmID, this.JAB.acType, this.__ac, "Int", index-1, "Cdecl " this.JAB.acType))
                return JAB.JavaAccessibleContext(this.__vmID, ac, this.JAB)
        }

        Dump(scope:=1, delimiter:=" ", depth:=-1) {
            out := "", scope := IsInteger(scope) ? scope : JAB.TreeScope.%scope%
            if scope&1 {
                Name := "N/A", Role := "N/A", Description := "N/A", Value := "N/A", States := "N/A", Location := {x:"N/A",y:"N/A",w:"N/A",h:"N/A"}, IsValueInterfaceAvailable := "N/A", AvailableInterfaces := ""
                for v in ["Name", "Role", "Description", "Value", "States", "Location", "IsValueInterfaceAvailable", "AvailableInterfaces"]
                    if v != "Value" || this.IsValueInterfaceAvailable
                        try %v% := this.%v%
                out := "Name: " Name delimiter "Role: " Role delimiter "[Location: {x:" Location.x ",y:" Location.y ",w:" Location.w ",h:" Location.h "}]" (Description ? delimiter "[Description: " Description "]" : "") (Value != "N/A" ? delimiter "[Value: " Value  "]" : "") (States ? delimiter "[States: " States "]" : "") (AvailableInterfaces ? delimiter "[AvailableInterfaces: " AvailableInterfaces "]" : "") "`n"
            }
            if scope&4
                return Trim(RecurseTree(this, out,, depth), "`n")
            if scope&2 {
                for n, oChild in this.Children
                    out .= n ":" delimiter oChild.Dump() "`n"
            }
            return Trim(out, "`n")

            RecurseTree(oEl, tree, path:="", depth:=-1) {
                if depth > 0 {
                    StrReplace(path, "," , , , &count)
                    if count >= (depth-1)
                        return tree
                }
                try {
                    if !oEl.Length
                        return tree
                } catch
                    return tree
                
                For i, oChild in oEl.Children {
                    tree .= path (path?",":"") i ":" delimiter oChild.Dump() "`n"
                    tree := RecurseTree(oChild, tree, path (path?",":"") i, depth)
                }
                return tree
            }
        }
        DumpAll(delimiter:=" ", maxDepth:=-1) => this.Dump(5, delimiter, maxDepth)

        /**
         * Returns an element from a path string (comma-separated integers and/or RoleText values)
         * @param ChildPath Comma-separated indexes for the tree traversal. 
         *     Instead of an index, RoleText is also permitted.
         * @returns {JAB.JavaAccessibleContext}
         */
        ElementFromPath(ChildPath) {
            oContext := this
            ChildPath := StrReplace(StrReplace(ChildPath, ".", ","), " ")
            Loop Parse ChildPath, ","
            {
                if IsInteger(A_LoopField)
                    oContext := oContext.GetNthChild(A_LoopField)
                else {
                    RegExMatch(A_LoopField, "(\D+)(\d*)", &m), i := m[2] || 1, c := 0
                    if m[1] = "p" {
                        Loop i
                            oContext := oContext.Parent
                        continue
                    }
                    for oChild in oContext {
                        try {
                            if (StrReplace(oChild.Role, " ") = m[1]) && (++c = i) {
                                oAcc := oChild
                                break
                            }
                        }
                    }
                }
            }
            Return oContext
        }

        /**
         * @param relativeTo CoordMode to be used: client, window or screen. Default is A_CoordModeMouse
         * @param WinTitle Optional: may be used to specifically define the window that the element belongs to
         * @returns {x:x coordinate, y:y coordinate, w:width, h:height}
         */
        GetPos(relativeTo:="", WinTitle?) {
            if IsSet(WinTitle) && !IsInteger(WinTitle)
                WinTitle := WinExist(WinTitle)
            local loc := this.Location, pt
            relativeTo := (relativeTo == "") ? A_CoordModeMouse : relativeTo
            if (relativeTo = "screen")
                return loc
            else if (relativeTo = "window") {
                DllCall("user32\GetWindowRect", "Int", WinTitle ?? this.WinId, "Ptr", RECT := Buffer(16))
                return {x:(loc.x-NumGet(RECT, 0, "Int")), y:(loc.y-NumGet(RECT, 4, "Int")), w:loc.w, h:loc.h}
            } else if (relativeTo = "client") {
                pt := Buffer(8), NumPut("int",loc.x,pt), NumPut("int", loc.y,pt,4)
                DllCall("ScreenToClient", "Int", WinTitle ?? this.WinId, "Ptr", pt)
                return {x:NumGet(pt,0,"int"), y:NumGet(pt,4,"int"), w:loc.w, h:loc.h}
            } else
                throw Error(relativeTo "is not a valid CoordMode",-1)
        }

        /**
         * Finds the first element matching a set of conditions.
         * The returned element also has a "Path" property with the found elements path
         * @param condition The condition to filter with, or a callback function.  
         * The condition object additionally supports named parameters.  
         * Default MatchMode is "Exact", and CaseSense "On".  
         * See a more detailed explanation under FindElement condition argument.
         * @param scope Optional TreeScope value: Element, Children, Family (Element+Children), Descendants, Subtree (=Element+Descendants). Default is Descendants.
         * @param index Looks for the n-th element matching the condition
         * @param order Optional: custom tree navigation order, one of UIA.TreeTraversalOptions values (LastToFirstOrder, PostOrder, LastToFirstPostOrder). Default is FirstToLast and PreOrder.
         * @param startingElement Optional: search will start from this element instead, which must be a child/descendant of the starting element
         *     If startingElement is supplied then part of the tree will not be searched (depending on TreeTraversalOrder, either everything before this element, or everything after it will be ignored)
         * @returns {JAB.JavaAccessibleContext}
         */
        FindElement(condition, scope:=4, index:=1, order:=0, startingElement:=0) {
            local callback := 0, found, child
            JAB.__ExtractNamedParameters(condition, "scope", &scope, "order", &order, "startingElement", &startingElement, "callback", &callback)
            if condition.HasProp("i")
                index := condition.i
            callback := callback || JAB.JavaAccessibleContext.Prototype.ValidateCondition.Bind(unset, condition), scope := JAB.TypeValidation.TreeScope(scope), index := JAB.TypeValidation.Integer(index, "Index"), order := JAB.TypeValidation.TreeTraversalOptions(order), startingElement := JAB.TypeValidation.Element(startingElement)
            if index < 0
                order |= 2, index := -index
            else if index = 0
                throw ValueError("Condition index cannot be 0", -1)
            if startingElement
                startingElement := startingElement.Id
            ; First handle PostOrder
            if order&1 {
                if scope > 1 {
                    if order&2 { ; LastToFirst
                        local children := this.Children, len := children.Length + 1
                        Loop len-1 {
                            child := children[i := len-A_index]
                            if scope&4 && found := PostOrderLastToFirstRecursiveFind(child, i "") ; Handles this child and its descendants
                                return found
                            else if (startingElement ? (startingElement = child.Id ? !(startingElement := "") : 0) : 1) && callback(child) && --index = 0
                                return (child.Path := i "", child)
                        }
                    } else { ; FirstToLast
                        for i, child in this.Children {
                            if scope&4 && found := PostOrderFirstToLastRecursiveFind(child, i "") ; Handles this child and its descendants
                                return found
                            else if (startingElement ? (startingElement = child.Id ? !(startingElement := "") : 0) : 1) && callback(child) && --index = 0
                                return (child.Path := i "", child)
                        }
                    }
                }
                if scope&1 && (startingElement ? (startingElement = this.Id ? !(startingElement := "") : 0) : 1) && callback(this) && --index = 0
                    return (this.Path := "", this)
                throw TargetError("An element matching the condition was not found", -1)
            }
            ; PreOrder
            if scope&1 && callback(this) && --index = 0
                return (this.Path := "", this)
            if scope > 1 {
                if found := order&2 ? PreOrderLastToFirstRecursiveFind(this) : PreOrderFirstToLastRecursiveFind(this)
                    return found
            }
            throw TargetError("An element matching the condition was not found", -1)
            PreOrderFirstToLastRecursiveFind(el, path:="") {
                local child, found
                for i, child in el.Children {
                    if (startingElement ? (startingElement = child.Id ? !(startingElement := "") : 0) : 1) && callback(child) && --index = 0
                        return (child.Path := Trim(path "," i, ","), child)
                    else if scope&4 && (found := PreOrderFirstToLastRecursiveFind(child, path "," i))
                        return found
                }
            }
            PreOrderLastToFirstRecursiveFind(el, path:="") {
                local children := el.Children, len := children.Length + 1, found, child
                Loop len-1 {
                    child := children[i := len-A_index]
                    if (startingElement ? (startingElement = child.Id ? !(startingElement := "") : 0) : 1) && callback(child) && --index = 0
                        return (child.Path := Trim(path "," i, ","), child)
                    else if scope&4 && found := PreOrderLastToFirstRecursiveFind(child, path "," i)
                        return found
                }
            }
            PostOrderFirstToLastRecursiveFind(el, path:="") {
                local child, found
                for i, child in el.Children {
                    if (found := PostOrderFirstToLastRecursiveFind(child, path "," i))
                        return found
                }
                if (startingElement ? (startingElement = el.Id ? !(startingElement := "") : 0) : 1) && callback(el) && --index = 0
                    return (el.Path := Trim(path "," i, ","), el)
            }
            PostOrderLastToFirstRecursiveFind(el, path:="") {
                local children := el.Children, len := children.Length + 1, found
                Loop len-1 {
                    if found := PostOrderLastToFirstRecursiveFind(children[i := len-A_index], path "," i)
                        return found
                }
                if (startingElement ? (startingElement = el.Id ? !(startingElement := "") : 0) : 1) && callback(el) && --index = 0
                    return (el.Path := Trim(path "," i, ","), el)
            }
        }

        /**
         * Returns all elements that satisfy the specified condition inside a tree.
         * @param condition The condition to filter with, or a callback function.  
         * The condition object additionally supports named parameters.  
         * Default MatchMode is "Exact", and CaseSense "On".  
         * See a more detailed explanation under FindElement condition argument.
         * @param scope Optional TreeScope value: Element, Children, Family (Element+Children), Descendants, Subtree (=Element+Descendants). Default is Descendants.
         * @param order Optional: custom tree navigation order, one of UIA.TreeTraversalOptions values (LastToFirstOrder, PostOrder, LastToFirstPostOrder). Default is FirstToLast and PreOrder.
         * @param startingElement Optional: element with which to begin the search
         *     Unlike FindElements, using this will not give a performance benefit.
         * @returns {[JAB.JavaAccessibleContext]}
         */
        FindElements(condition, scope:=4, order:=0, startingElement:=0) {
            local callback := 0, foundElements := [], child
            JAB.__ExtractNamedParameters(condition, "scope", &scope, "order", &order, "startingElement", &startingElement, "callback", &callback)
            callback := callback || JAB.JavaAccessibleContext.Prototype.ValidateCondition.Bind(unset, condition), scope := JAB.TypeValidation.TreeScope(scope), order := JAB.TypeValidation.TreeTraversalOptions(order), startingElement := JAB.TypeValidation.Element(startingElement)
            if startingElement
                startingElement := startingElement.Id
            ; First handle PostOrder
            if order&1 {
                if scope > 1 {
                    if order&2 { ; LastToFirst
                        local children := this.Children, len := children.Length + 1
                        Loop len-1 {
                            child := children[i := len-A_index]
                            if scope&4
                                PostOrderLastToFirstRecursiveFind(child, i "") ; Handles this child and its descendants
                            else if (startingElement ? (startingElement = child.Id ? !(startingElement := "") : 0) : 1) && callback(child)
                                child.Path := i "", foundElements.Push(child)
                        }
                    } else { ; FirstToLast
                        for i, child in this.Children {
                            if scope&4
                                PostOrderFirstToLastRecursiveFind(child, i "") ; Handles this child and its descendants
                            else if (startingElement ? (startingElement = child.Id ? !(startingElement := "") : 0) : 1) && callback(child)
                                child.Path := i "", foundElements.Push(child)
                        }
                    }
                }
                if scope&1 && (startingElement ? (startingElement = this.Id ? !(startingElement := "") : 0) : 1) && callback(this)
                    this.Path := "", foundElements.Push(this)
                return foundElements
            }
            ; PreOrder
            if scope&1 && callback(this)
                foundElements.Push(this)
            if scope > 1
                return (order&2 ? PreOrderLastToFirstRecursiveFind(this) : PreOrderFirstToLastRecursiveFind(this), foundElements)
            return foundElements
            PreOrderFirstToLastRecursiveFind(el, path:="") {
                local child
                for i, child in el.Children {
                    if (startingElement ? (startingElement = child.Id ? !(startingElement := "") : 0) : 1) && callback(child)
                        child.Path := Trim(path "," i, ","), foundElements.Push(child)
                    if scope&4
                        PreOrderFirstToLastRecursiveFind(child, path "," i)
                }
            }
            PreOrderLastToFirstRecursiveFind(el, path:="") {
                local children := el.Children, len := children.Length + 1, child
                Loop len-1 {
                    child := children[i := len-A_index]
                    if (startingElement ? (startingElement = child.Id ? !(startingElement := "") : 0) : 1) && callback(child)
                        child.Path := Trim(path "," i, ","), foundElements.Push(child)
                    if scope&4
                        PreOrderLastToFirstRecursiveFind(child, path "," i)
                }
            }
            PostOrderFirstToLastRecursiveFind(el, path:="") { ; called only if scope>=4
                local child
                for i, child in el.Children
                    PostOrderFirstToLastRecursiveFind(child, path "," i)
                if (startingElement ? (startingElement = el.Id ? !(startingElement := "") : 0) : 1) && callback(el)
                    el.Path := Trim(path, ","), foundElements.Push(el)
            }
            PostOrderLastToFirstRecursiveFind(el, path:="") { ; called only if scope>=4
                local children, len
                children := el.Children, len := children.Length + 1
                Loop len-1
                    PostOrderLastToFirstRecursiveFind(children[i := len-A_index], path "," i)
                if (startingElement ? (startingElement = el.Id ? !(startingElement := "") : 0) : 1) && callback(el)
                    el.Path := Trim(path, ","), foundElements.Push(el)
            }
        }

        /**
         * Wait element to exist.
         * @param condition The condition to filter with.
         * The condition object additionally supports named parameters.  
         * See a more detailed explanation under FindElement condition argument.
         * @param timeOut Waiting time for element to appear in ms. Default: indefinite wait
         * @param scope Optional TreeScope value: Element, Children, Family (Element+Children), Descendants, Subtree (=Element+Descendants). Default is Descendants.
         * @param index Looks for the n-th element matching the condition
         * @param order Optional: custom tree navigation order, one of JAB.TreeTraversalOptions values (LastToFirstOrder, PostOrder, LastToFirstPostOrder) [requires Windows 10 version 1703+]
         * @param startingElement Optional: element with which to begin the search
         * @returns {JAB.JavaAccessibleContext} Found element if successful, 0 if timeout happens
         */
        ElementExist(condition, scope:=4, index:=1, order:=0, startingElement:=0) {
            try return this.FindElement(condition, scope, index, order, startingElement)
            catch TargetError
                return 0
            return 0
        }

        /**
         * Wait element to exist.
         * @param condition The condition to filter with.
         * The condition object additionally supports named parameters.  
         * See a more detailed explanation under FindElement condition argument.
         * @param timeOut Waiting time for element to appear in ms. Default: indefinite wait
         * @param scope Optional TreeScope value: Element, Children, Family (Element+Children), Descendants, Subtree (=Element+Descendants). Default is Descendants.
         * @param index Looks for the n-th element matching the condition
         * @param order Optional: custom tree navigation order, one of JAB.TreeTraversalOptions values (LastToFirstOrder, PostOrder, LastToFirstPostOrder) [requires Windows 10 version 1703+]
         * @param startingElement Optional: element with which to begin the search
         * @param tick Optional: sleep duration between searches, default is 20ms
         * @returns {JAB.JavaAccessibleContext} Found element if successful, 0 if timeout happens
         */
        WaitElement(condition, timeOut := -1, scope := 4, index := 1, order := 0, startingElement := 0, tick := 20) {
            local endtime
            if IsObject(condition)
                timeOut := condition.HasOwnProp("timeOut") ? condition.timeOut : timeOut, tick := condition.HasOwnprop("tick") ? condition.tick : tick
            timeOut := JAB.TypeValidation.Integer(timeOut, "TimeOut"), tick := JAB.TypeValidation.Integer(tick, "tick")
            endtime := A_TickCount + timeOut
            While ((timeOut == -1) || (A_Tickcount < endtime)) {
                try return this.FindElement(condition, scope, index, order, startingElement)
                Sleep tick
            }
            return 0
        }

        /**
         * Wait element to not exist (disappear).
         * @param condition The condition to filter with.  
         * The condition object additionally supports named parameters.  
         * See a more detailed explanation under FindElement condition argument.
         * @param timeout Waiting time for element to disappear. Default: indefinite wait
         * @param scope Optional TreeScope value: Element, Children, Family (Element+Children), Descendants, Subtree (=Element+Descendants). Default is Descendants.
         * @param order Optional: custom tree navigation order, one of UIA.TreeTraversalOptions values (LastToFirstOrder, PostOrder, LastToFirstPostOrder) [requires Windows 10 version 1703+]
         * @param startingElement Optional: element with which to begin the search [requires Windows 10 version 1703+]
         * @param cacheRequest Optional: cache request object
         * @returns 1 if element disappeared, 0 otherwise
         */
        WaitElementNotExist(condition, timeout := -1, scope := 4, index := 1, order := 0, startingElement := 0, cacheRequest := 0) {
            local endtime
            timeOut := condition.HasOwnProp("timeOut") ? condition.timeOut : timeOut
            endtime := A_TickCount + timeout
            While (timeout == -1) || (A_Tickcount < endtime) {
                try this.FindElement(condition, scope, index, order, startingElement)
                catch
                    return 1
            }
            return 0
        }

        /**
         * Waits for this element to not exist. Returns True if the element disappears before the timeout.
         * @param timeOut Timeout in milliseconds. Default in indefinite waiting.
         */
        WaitNotExist(timeOut:=-1) {
            waitTime := A_TickCount + timeOut
            while ((timeOut < 1) ? 1 : (A_tickCount < waitTime)) {
                if !this.Exists
                    return 1
                Sleep 40
            }
        }
        /**
         * Checks whether the current element or any of its ancestors match the condition, 
         * and returns that element. If no element is found, an error is thrown.
         * @param condition Condition object (see ValidateCondition)
         * @returns {Acc.IAccessible}
         */
        Normalize(condition) {
            if this.ValidateCondition(condition)
                return this
            oEl := this
            Loop {
                try {
                    if Type(condition) = "Object" && condition.HasProp("Role") {
                        if !(ac := DllCall(this.JAB.DLLVersion "\getParentWithRole", "Int", this.__vmID, this.JAB.acType, this.__ac, "wstr", condition.Role, "Cdecl " this.JAB.acType))
                            return 0
                        oEl := JAB.JavaAccessibleContext(this.__vmID, ac, this.JAB)
                    } else
                        oEl := oEl.Parent
                    if oEl.ValidateCondition(condition)
                        return oEl
                } catch
                    break
            }
            return 0
        }

        /*
            Checks whether the element matches a provided condition.
            Everything inside {} is an "and" condition
            Everything inside [] is an "or" condition
            Object key "not" creates a not condition

            matchmode key defines the MatchMode: StartsWith, Substring, Exact, RegEx (Acc.MATCHMODE values)

            casesensitive key defines case sensitivity: True=case sensitive; False=case insensitive

            {Name:"Something"} => Name must match "Something" (case sensitive)
            {Name:"Something", RoleText:"something else"} => Name must match "Something" and RoleText must match "something else"
            [{Name:"Something", Role:42}, {Name:"Something2", RoleText:"something else"}] => Name=="Something" and Role==42 OR Name=="Something2" and RoleText=="something else"
            {Name:"Something", not:[RoleText:"something", RoleText:"something else"]} => Name must match "something" and RoleText cannot match "something" nor "something else"
        */
        ValidateCondition(oCond) {
            if !IsObject(oCond)
                return !!oCond ; if oCond is not an object, then it is treated as True or False condition
            if HasMethod(oCond) {
                return oCond(this)
            } else if oCond is Array { ; or condition
                for _, c in oCond
                    if this.ValidateCondition(c)
                        return 1
                return 0
            }
            matchmode := 3, casesensitive := 1, notCond := False
            for p in ["matchmode", "mm"]
                if oCond.HasOwnProp(p)
                    matchmode := oCond.%p%
            try matchmode := IsInteger(matchmode) ? matchmode : JAB.MatchMode.%matchmode%
            for p in ["casesensitive", "cs"]
                if oCond.HasOwnProp(p)
                    casesensitive := oCond.%p%
            for prop, cond in oCond.OwnProps() {
                switch Type(cond) { ; and condition
                    case "String", "Integer":
                        if prop ~= "i)^(index|i|matchmode|mm|casesensitive|cs|scope|timeout|tick)$"
                            continue
                        propValue := ""
                        try propValue := this.%prop%
                        switch matchmode, 0 {
                            case 2:
                                if !InStr(propValue, cond, casesensitive)
                                    return 0
                            case 1:
                                if !((casesensitive && (SubStr(propValue, 1, StrLen(cond)) == cond)) || (!casesensitive && (SubStr(propValue, 1, StrLen(cond)) = cond)))
                                    return 0
                            case "Regex":
                                if !(propValue ~= cond)
                                    return 0
                            default:
                                if !((casesensitive && (propValue == cond)) || (!casesensitive && (propValue = cond)))
                                    return 0
                        }
                    case "JAB.JavaAccessibleContext":
                        if (prop="IsEqual") ? !JAB.CompareElements(this, cond) : !this.ValidateCondition(cond)
                            return 0
                    default:
                        if (HasProp(cond, "Length") ? cond.Length = 0 : ObjOwnPropCount(cond) = 0) {
                            try return this.%prop% && 0
                            catch
                                return 1
                        } else if (prop = "Location") {
                            try loc := cond.HasOwnProp("relative") ? this.GetPos(cond.relative) 
                                : cond.HasOwnProp("r") ? this.GetPos(cond.r) 
                                : this.Location
                            catch
                                return 0
                            for lprop, lval in cond.OwnProps() {
                                if (!((lprop = "relative") || (lprop = "r")) && (loc.%lprop% != lval))
                                    return 0
                            }
                        } else if ((prop = "not") ? this.ValidateCondition(cond) : !this.ValidateCondition(cond))
                            return 0
                }
            }
            return 1
        }
    
        /**
         * Tries to click the element. The method depends on WhichButton variable: by default it tries DoDefaultAction
         * @param WhichButton 
         * * If WhichButton is left empty (default), then DoDefaultAction is used.
         * * If WhichButton is a number, then Sleep will be called afterwards with that number of milliseconds.  
         *     Eg. Element.Click(200) will sleep 200ms after "clicking".  
         * * If WhichButton is "left" or "right", then the native Click() will be used to move the cursor to
         * the center of the element and perform a click.  
         * @param ClickCount Is used if WhichButton isn't a number or left empty, that is if AHK Click()
         * will be used. In this case if ClickCount is a number <10, then that number of clicks will be performed.  
         * If ClickCount is >=10, then Sleep will be called with that number of ms. Both ClickCount and sleep time
         * can be combined by separating with a space.  
         * Eg. Element.Click("left", 1000) will sleep 1000ms after clicking.  
         *     Element.Click("left", 2) will double-click the element  
         *     Element.Click("left", "2 1000") will double-click the element and then sleep for 1000ms  
         * @param DownOrUp If AHK Click is used, then this will either press the mouse down, or release it.
         * @param Relative If Relative is "Rel" or "Relative" then X and Y coordinates are treated as offsets from the current mouse position.  
         * Otherwise it expects offset values for both X and Y (eg "-5 10" would offset X by -5 and Y by +10 from the center of the element).
         * @param NoActivate If AHK Click is used, then this will determine whether the window is activated
         * before clicking if the clickable point isn't visible on the screen. Default is no activating.
         * @param MoveBack If set then the cursor will be moved back to its original location after sleeping for
         * the specified amount of ms. Specify 0 for no sleep.
         */
        Click(WhichButton:="", ClickCount:=1, DownOrUp:="", Relative:="", NoActivate:=False, MoveBack?) {
            local SleepTime, rel, pos
            if WhichButton = "" or IsInteger(WhichButton) {
                this.DoDefaultAction()
                if WhichButton != ""
                    Sleep WhichButton
                return "DoDefaultAction"
            }
            rel := [0,0], pos := this.Location
            if (Relative && !InStr(Relative, "rel"))
                rel := StrSplit(Relative, " "), Relative := ""
            if IsInteger(WhichButton)
                SleepTime := WhichButton, WhichButton := "left"
            if !IsInteger(ClickCount) && InStr(ClickCount, " ") {
                sCount := StrSplit(ClickCount, " ")
                ClickCount := sCount[1], SleepTime := sCount[2]
            } else if ClickCount > 9 {
                SleepTime := ClickCount, ClickCount := 1
            }
            if (!NoActivate && (JAB.WindowFromPoint(pos.x+pos.w//2+rel[1], pos.y+pos.h//2+rel[2]) != (wId := this.WinId))) {
                WinActivate(wId)
                WinWaitActive(wId)
            }
            saveCoordMode := A_CoordModeMouse
            CoordMode("Mouse", "Screen")
            if IsSet(MoveBack)
                MouseGetPos(&prevX, &prevY)
            Click(pos.x+pos.w//2+rel[1] " " pos.y+pos.h//2+rel[2] " " WhichButton (ClickCount ? " " ClickCount : "") (DownOrUp ? " " DownOrUp : "") (Relative ? " " Relative : ""))
            if IsSet(MoveBack) {
                if MoveBack != 0
                    Sleep MoveBack
                MouseMove(prevX, prevY)
            }
            CoordMode("Mouse", saveCoordMode)
            if IsSet(SleepTime)
                Sleep(SleepTime)
        }

        /**
         * Uses ControlClick to click the element.
         * @param WhichButton determines which button to use to click (left, right, middle).  
         * If WhichButton is a number, then a Sleep will be called afterwards.  
         * Eg. ControlClick(200) will sleep 200ms after clicking.
         * @param ClickCount How many times to click. Default is 1.
         * @param Options Additional ControlClick Options (see AHK documentations).
         * @param WinTitle Optional: providing the WinTitle of the window the element belongs to might
         *  give speed improvements and sometimes be more reliable.
         */
        ControlClick(WhichButton:="left", ClickCount:=1, Options:="", WinTitle?) {
            local pos := this.GetPos("client", WinTitle?)
            ControlClick("X" pos.x+pos.w//2 " Y" pos.y+pos.h//2, WinTitle ?? this.WinId,, IsInteger(WhichButton) ? "left" : WhichButton, ClickCount, Options)
            if IsInteger(WhichButton)
                Sleep(WhichButton)
        }

        /**
         * Highlights the element for a chosen period of time.
         * @param showTime Can be one of the following:  
         * * Unset - if highlighting exists then removes the highlighting, otherwise highlights for 2 seconds. This is the default value.
         * * 0 - Indefinite highlighting
         * * Positive integer (eg 2000) - will highlight and pause for the specified amount of time in ms
         * * Negative integer - will highlight for the specified amount of time in ms, but script execution will continue
         * * "clear" - removes the highlighting unconditionally
         * @param color The color of the highlighting. Default is red.
         * @param d The border thickness of the highlighting in pixels. Default is 2.
         * @returns {UIA.IUIAutomationElement}
         */
        Highlight(showTime:=unset, color:="Red", d:=2) {
            local loc, x, y, w, h, key, prop
            static Guis := Map()
            if IsSet(showTime) && showTime = "clearall" {
                for key, prop in Guis {
                    SetTimer(prop.TimerObj, 0)
                    try prop.GuiObj.Destroy()
                }
                Guis := Map()
                return this
            }

            if (!IsSet(showTime) && Guis.Has(this.Id)) || (IsSet(showTime) && showTime = "clear") {
                    if Guis.Has(this.Id) {
                        SetTimer(Guis[this.Id].TimerObj, 0)
                        try Guis[this.Id].GuiObj.Destroy()
                        Guis.Delete(this.Id)
                    }
                    return this
            } else if !IsSet(showTime)
                showTime := 2000

            try loc := this.Location
            if !IsSet(loc) || !IsObject(loc) || (loc.w == -1 && loc.h == -1)
                try loc := this.CachedLocation
            if !IsSet(loc) || !IsObject(loc)
                return this
            
            if !Guis.Has(this.Id) {
                Guis[this.Id] := {}
                Guis[this.Id].GuiObj := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000")
                Guis[this.Id].TimerObj := ObjBindMethod(this, "Highlight", "clear")
            }
            GuiObj := Guis[this.Id].GuiObj
            GuiObj.BackColor := color
            x:=loc.x, y:=loc.y, w:=loc.w, h:=loc.h, iw:= w+d, ih:= h+d, w:=w+d*2, h:=h+d*2, x:=x-d, y:=y-d
            WinSetRegion("0-0 " w "-0 " w "-" h " 0-" h " 0-0 " d "-" d " " iw "-" d " " iw "-" ih " " d "-" ih " " d "-" d, GuiObj.Hwnd)
            GuiObj.Show("NA x" . x . " y" . y . " w" . w . " h" . h)

            if showTime > 0 {
                Sleep(showTime)
                this.Highlight()
            } else if showTime < 0
                SetTimer(Guis[this.Id].TimerObj, -Abs(showTime))
            return this
        }
        ClearHighlight() => this.Highlight("clear")

        IsEqual(el) => JAB.CompareElements(this, el)

        GetVersionInfo() {
            Info := Buffer(2048, 0)
            if (DllCall(this.JAB.DLLVersion "\getVersionInfo", "Int", this.__vmID, "Ptr", Info, "Cdecl Int"))
                return {VMVersion:StrGet(Info.Ptr, JAB.SHORT_STRING_SIZE, "UTF-16")
                    , bridgeJavaClassVersion:StrGet(Info.Ptr+JAB.SHORT_STRING_SIZE*2, JAB.SHORT_STRING_SIZE, "UTF-16")
                    , bridgeJavaDLLVersion:StrGet(Info.Ptr+JAB.SHORT_STRING_SIZE*4, JAB.SHORT_STRING_SIZE, "UTF-16")
                    , bridgeWinDLLVersion:StrGet(Info.Ptr+JAB.SHORT_STRING_SIZE*6, JAB.SHORT_STRING_SIZE, "UTF-16")}
            return 0
        }

        __Delete() => DllCall(this.JAB.DLLVersion "\releaseJavaObject", "Int", this.__vmID, this.JAB.acType, this.__ac, "Cdecl")
    }

    class JavaAccessibleHyperlink extends JAB.JavaAccessibleObject {
        ; Text, startIndex, endIndex
        Activate() => DllCall(this.JAB.DLLVersion "\activateAccessibleHyperlink", "Int", this.__vmID, this.JAB.acType, this.__ac, this.JAB.acType, this.__obj, "Cdecl")
    }
    ;; Not needed in this implementation
    class JavaAccessibleHypertext extends JAB.JavaAccessibleObject {
    }

    class JavaAccessibleTable extends JAB.JavaAccessibleObject {
        Owner := 0, Caption := 0, Summary := 0, rowCount := 0, columnCount := 0
        static __GetTable(caller, tableInfo) {
            local owner := (ac := NumGet(tableInfo, caller.JAB.acSize*2+8, caller.JAB.acType)) ? JAB.JavaAccessibleContext(caller.__vmID, ac, caller.JAB) : 0
            , table := ((t := NumGet(tableInfo, caller.JAB.acSize*3+8, caller.JAB.acType)) ? JAB.JavaAccessibleTable(caller.__vmID, ac, caller.JAB, t) : 0)
            if table && owner {
                table.Owner := owner
                table.Caption := ((ac := NumGet(tableInfo, caller.JAB.acType)) ? JAB.JavaAccessibleContext(caller.__vmID, ac, caller.JAB) : 0)
                table.Summary := ((ac := NumGet(tableInfo, caller.JAB.acSize, caller.JAB.acType)) ? JAB.JavaAccessibleContext(caller.__vmID, ac, caller.JAB) : 0)
                table.rowCount := NumGet(tableInfo, caller.JAB.acSize*2, "int")
                table.columnCount := NumGet(tableInfo, caller.JAB.acSize*2+4, "int")
                return table
            }
            return 0
        }
        static __GetCell(caller, tableCellInfo) => (offset := 0, cell := JAB.JavaAccessibleCell(caller.__vmID, NumGet(tableCellInfo.Ptr, caller.JAB.acType), caller.JAB),
            Cell.index:=NumGet(tableCellInfo.Ptr, offset+=caller.JAB.acSize, "int")+1,
            Cell.row:=NumGet(tableCellInfo.Ptr, offset+=4, "int")+1,
            Cell.column:=NumGet(tableCellInfo.Ptr, offset+=4, "int")+1,
            Cell.rowExtent:=NumGet(tableCellInfo.Ptr, offset+=4, "int"),
            Cell.columnExtent:=NumGet(tableCellInfo.Ptr, offset+=4, "int"),
            Cell.isSelected:=NumGet(tableCellInfo.Ptr, offset+=4, "int"), cell)
        
        GetCell(row, column) {
            if row < 1 || row > this.rowCount
                throw ValueError("Invalid row number", -1)
            if column < 1 || column > this.columnCount
                throw ValueError("Invalid column number", -1)
            if DllCall(this.JAB.DLLVersion "\getAccessibleTableCellInfo", "Int", this.__vmID, this.JAB.acType, this.__obj, "int", row-1, "int", column-1, "ptr", tableCellInfo:=Buffer(32,0), "Cdecl Int")
                return JAB.JavaAccessibleTable.__GetCell(this, tableCellInfo)
            throw Error("Unable to get cell", -1)
        }

        RowHeader {
            get {
                if DllCall(this.JAB.DLLVersion "\getAccessibleTableRowHeader", "int", this.__vmID, this.JAB.acType, this.__ac, "ptr", tableInfo:=Buffer(40, 0), "Cdecl Int")
                    return JAB.JavaAccessibleTable.__GetTable(this, tableInfo)
                throw Error("Unable to get table", -1)
            }
        }

        ColumnHeader {
            get {
                if DllCall(this.JAB.DLLVersion "\getAccessibleTableColumnHeader", "int", this.__vmID, this.JAB.acType, this.__ac, "ptr", tableInfo:=Buffer(40, 0), "Cdecl Int")
                    return JAB.JavaAccessibleTable.__GetTable(this, tableInfo)
                throw Error("Unable to get table", -1)
            }
        }

        GetRow(row) {
            if row < 1 || row > this.rowCount
                throw ValueError("Invalid row number", -1)
            if ac := DllCall(this.JAB.DLLVersion "\getAccessibleTableRowDescription", "int", this.__vmID, this.JAB.acType, this.__ac, "int", row-1, "Cdecl " this.JAB.acType)
                return JAB.JavaAccessibleContext(this.__vmID, ac, this.JAB)
            throw Error("Unable to get row", -1)
        }

        GetColumn(column) {
            if column < 1 || column > this.columnCount
                throw ValueError("Invalid column number", -1)
            if ac := DllCall(this.JAB.DLLVersion "\getAccessibleTableColumnDescription", "int", this.__vmID, this.JAB.acType, this.__ac, "int", column-1, "Cdecl " this.JAB.acType)
                return JAB.JavaAccessibleContext(this.__vmID, ac, this.JAB)
            throw Error("Unable to get column", -1)
        }

        RowSelectionCount => DllCall(this.JAB.DLLVersion "\getAccessibleTableRowSelectionCount", "int", this.__vmID, this.JAB.acType, this.__obj, "Cdecl Int")
        ColumnSelectionCount => DllCall(this.JAB.DLLVersion "\getAccessibleTableColumnSelectionCount", "int", this.__vmID, this.JAB.acType, this.__obj, "Cdecl Int")
        GetSelectedRows() {
            if DllCall(this.JAB.DLLVersion "\getAccessibleTableRowSelections", "int", this.__vmID, this.JAB.acType, this.__obj, "int", c := this.RowSelectionCount, "ptr", buf := Buffer(4*c) "Cdecl Int") {
                selections := []
                Loop c
                    selections.Push(NumGet(buf.ptr, (A_Index-1)*4, "int")+1)
                return selections
            }
            return 0
        }
        GetSelectedColumns() {
            if DllCall(this.JAB.DLLVersion "\getAccessibleTableColumnSelections", "int", this.__vmID, this.JAB.acType, this.__obj, "int", c := this.ColumnSelectionCount, "ptr", buf := Buffer(4*c) "Cdecl Int") {
                selections := []
                Loop c
                    selections.Push(NumGet(buf.ptr, (A_Index-1)*4, "int")+1)
                return selections
            }
            return 0
        }
        IsRowSelected(row) => DllCall(this.JAB.DLLVersion "\isAccessibleTableRowSelected", "int", this.__vmID, this.JAB.acType, this.__obj, "int", row-1, "Cdecl Int")
        IsColumnSelected(column) => DllCall(this.JAB.DLLVersion "\isAccessibleTableColumnSelected", "int", this.__vmID, this.JAB.acType, this.__obj, "int", column-1, "Cdecl Int")
        GetRowNumberByCellIndex(index) => DllCall(this.JAB.DLLVersion "\getAccessibleTableRow", "int", this.__vmID, this.JAB.acType, this.__obj, "int", index-1, "Cdecl Int")
        GetColumnNumberByCellIndex(index) => DllCall(this.JAB.DLLVersion "\getAccessibleTableColumn", "int", this.__vmID, this.JAB.acType, this.__obj, "int", index-1, "Cdecl Int")
        GetCellIndex(row, column) => DllCall(this.JAB.DLLVersion "\getAccessibleTableIndex", "int", this.__vmID, this.JAB.acType, this.__obj, "int", row-1, "int", column-1, "Cdecl Int")
    }

    class JavaAccessibleCell extends JAB.JavaAccessibleContext {
        index := 0, row := 0, column := 0, rowExtent := 0, columnExtent := 0, isSelected := 0
    }

    class Viewer {
        __New() {
            this.Stored := {mwId:0, FilteredTreeView:Map(), TreeView:Map()}
            this.Capturing := False
            this.gViewer := Gui("AlwaysOnTop Resize","JABViewer")
            this.gViewer.OnEvent("Close", (*) => ExitApp())
            this.gViewer.OnEvent("Size", this.GetMethod("gViewer_Size").Bind(this))
            this.gViewer.Add("Text", "w100", "Window Info").SetFont("bold")
            this.LVWin := this.gViewer.Add("ListView", "h140 w250", ["Property", "Value"])
            this.LVWin.OnEvent("ContextMenu", LV_CopyTextMethod := this.GetMethod("LV_CopyText").Bind(this))
            this.LVWin.ModifyCol(1,60)
            this.LVWin.ModifyCol(2,180)
            for _, v in this.DefaultLVWinItems := ["Title", "Text", "Id", "Location", "Class(NN)", "Process", "PID"]
                this.LVWin.Add(,v,"")
            this.gViewer.Add("Text", "w100", "JAB Info").SetFont("bold")
            this.LVProps := this.gViewer.Add("ListView", "h220 w250", ["Property", "Value"])
            this.LVProps.OnEvent("ContextMenu", LV_CopyTextMethod)
            this.LVProps.ModifyCol(1,100)
            this.LVProps.ModifyCol(2,140)
            for _, v in this.DefaultLVPropsItems := ["Role", "LocalizedRole", "Name", "Description", "States", "LocalizedStates", "Value", "Location", "AvailableInterfaces", "KeyBindings", "Id"]
                this.LVProps.Add(,v,"")
            this.ButCapture := this.gViewer.Add("Button", "xp+60 y+10 w130", "Start capturing (F1)")
            this.ButCapture.OnEvent("Click", this.CaptureHotkeyFunc := this.GetMethod("ButCapture_Click").Bind(this))
            HotKey("F1", this.CaptureHotkeyFunc)
            this.SBMain := this.gViewer.Add("StatusBar",, "  Start capturing, then hold cursor still to construct tree")
            this.SBMain.OnEvent("Click", this.GetMethod("SBMain_Click").Bind(this))
            this.SBMain.OnEvent("ContextMenu", this.GetMethod("SBMain_Click").Bind(this))
            this.gViewer.Add("Text", "x278 y10 w200", "Java Accessibility Bridge Tree").SetFont("bold")
            this.TVContext := this.gViewer.Add("TreeView", "x275 y25 w250 h390 -0x800")
            this.TVContext.OnEvent("Click", this.GetMethod("TVContext_Click").Bind(this))
            this.TVContext.OnEvent("ContextMenu", this.GetMethod("TVContext_ContextMenu").Bind(this))
            this.TVContext.Add("Start capturing to show tree")
            this.TextFilterTVContext := this.gViewer.Add("Text", "x275 y428", "Filter:")
            this.EditFilterTVContext := this.gViewer.Add("Edit", "x305 y425 w100")
            this.EditFilterTVContext.OnEvent("Change", this.GetMethod("EditFilterTV_Change").Bind(this))
            this.gViewer.Show()
        }
        ; Resizes window controls when window is resized
        gViewer_Size(GuiObj, MinMax, Width, Height) {
            this.TVContext.GetPos(&TVContextX, &TVContextY, &TVContextWidth, &TVContextHeight)
            this.TVContext.Move(,,Width-TVContextX-10,Height-TVContextY-50)
            this.TextFilterTVContext.Move(TVContextX, Height-42)
            this.EditFilterTVContext.Move(TVContextX+30, Height-45)
            this.TVContext.GetPos(&LVPropsX, &LVPropsY, &LVPropsWidth, &LVPropsHeight)
            this.LVProps.Move(,,,Height-LVPropsY-225)
            this.ButCapture.Move(,Height -55)
        }
        ; Starts showing the element under the cursor with 200ms intervals with CaptureCallback
        ButCapture_Click(GuiCtrlObj?, Info?) {
            if this.Capturing {
                this.StopCapture()
                return
            }
            this.Capturing := True
            HotKey("F1", this.CaptureHotkeyFunc, "Off")
            HotKey("Esc", this.CaptureHotkeyFunc, "On")
            this.TVContext.Delete()
            this.TVContext.Add("Hold cursor still to construct tree")
            this.ButCapture.Text := "Stop capturing (Esc)"
            this.CaptureCallback := this.GetMethod("CaptureCycle").Bind(this)
            SetTimer(this.CaptureCallback, 200)
        }
        ; Handles right-clicking a listview (copies to clipboard)
        LV_CopyText(GuiCtrlObj, Info, *) {
            local out := "", LVData := Info > GuiCtrlObj.GetCount()
                ? ListViewGetContent("", GuiCtrlObj)
                : ListViewGetContent("Selected", GuiCtrlObj)
                for LVData in StrSplit(LVData, "`n") {
                    LVData := StrSplit(LVData, "`t",,2)
                    if LVData.Length < 2
                        continue
                    switch LVData[1], 0 {
                        case "Location":
                            LVData[2] := "{" RegExReplace(LVData[2], "(\w:) (\d+)(?= )", "$1$2,") "}"
                    }
                    out .= ", " (GuiCtrlObj.Hwnd = this.LVWin.Hwnd ? "" : LVData[1] ":") (LVData[1] = "Location" || IsInteger(LVData[2]) ? LVData[2] : "`"" StrReplace(StrReplace(LVData[2], "``", "````"), "`"", "```"") "`"")
                }
                ToolTip("Copied: " (A_Clipboard := SubStr(out, 3)))
                SetTimer(ToolTip, -3000)
        }
        ; Copies the JAB path to clipboard when statusbar is clicked
        SBMain_Click(GuiCtrlObj, Info, *) {
            if InStr(this.SBMain.Text, "Path:") {
                ToolTip("Copied: " (A_Clipboard := SubStr(this.SBMain.Text, 9)))
                SetTimer((*) => ToolTip(), -3000)
            }
        }
        ; Stops capturing elements under mouse, unhooks CaptureCallback
        StopCapture(GuiCtrlObj:=0, Info:=0) {
            if this.Capturing {
                this.Capturing := False
                this.ButCapture.Text := "Start capturing (F1)"
                HotKey("Esc", this.CaptureHotkeyFunc, "Off")
                HotKey("F1", this.CaptureHotkeyFunc, "On")
                SetTimer(this.CaptureCallback, 0)
                if this.Stored.HasOwnProp("oContext")
                    this.Stored.oContext.Highlight()
                return
            }
        }
        ; Gets JAB element under mouse, updates the GUI. 
        ; If the mouse is not moved for 1 second then constructs the JAB tree.
        CaptureCycle() {
            Thread "NoTimers"
            MouseGetPos(&mX, &mY, &mwId)
            if !JAB.IsJavaWindow(mwID) {
                this.LVWin.Delete()
                for v in this.DefaultLVWinItems
                    this.LVWin.Add(,v,"")
                this.LVProps.Delete()
                for v in this.DefaultLVPropsItems
                    this.LVProps.Add(,v,"")
                this.TVContext.Delete()
                this.TVContext.Add("Not a Java window!")
                return
            }
            oContext := JAB.ElementFromPoint()
            if !IsObject(oContext)
                return
            oContext.BuildUpdatedCache(this.DefaultLVPropsItems)
            if this.Stored.HasOwnProp("oContext") && oContext.IsEqual(this.Stored.oContext) {
                if this.FoundTime != 0 && ((A_TickCount - this.FoundTime) > 1000) {
                    if (mX == this.Stored.mX) && (mY == this.Stored.mY) 
                        this.ConstructTreeView(), this.FoundTime := 0
                    else 
                        this.FoundTime := A_TickCount
                }
                this.Stored.mX := mX, this.Stored.mY := mY
                return
            }
            if !WinExist(mwId)
                return
            this.LVWin.Delete()
            WinGetPos(&mwX, &mwY, &mwW, &mwH, mwId)
            propsOrder := ["Title", "Text", "Id", "Location", "Class(NN)", "Process", "PID"]
            props := Map("Title", WinGetTitle(mwId), "Text", WinGetText(mwId), "Id", mwId, "Location", "x: " mwX " y: " mwY " w: " mwW " h: " mwH, "Class(NN)", WinGetClass(mwId), "Process", WinGetProcessName(mwId), "PID", WinGetPID(mwId))
            for propName in propsOrder
                this.LVWin.Add(,propName,props[propName])
            this.LVProps_Populate(oContext)
            this.Stored.mwId := mwId, this.Stored.oContext := oContext, this.Stored.mX := mX, this.Stored.mY := mY, this.FoundTime := A_TickCount
        }
        ; Populates the listview with JAB element properties
        LVProps_Populate(oContext) {
            JAB.ClearAllHighlights() ; Clear
            oContext.Highlight(0) ; Indefinite show
            this.LVProps.Delete()
            Location := {x:"N/A",y:"N/A",w:"N/A",h:"N/A"}, Role := "N/A", LocalizedRole := "N/A", Name := "N/A", Description := "N/A", States := "N/A", LocalizedStates := "N/A", Value := "N/A", Id := "N/A", AvailableInterfaces := "", KeyBindings := "N/A"
            for _, v in this.DefaultLVPropsItems {
                try %v% := oContext.Cached%v%
                this.LVProps.Add(,v, v = "Location" ? ("x: " %v%.x " y: " %v%.y " w: " %v%.w " h: " %v%.h) : %v%)
            }
        }
        ; Handles selecting elements in the JAB tree, highlights the selected element
        TVContext_Click(GuiCtrlObj, Info) {
            if this.Capturing
                return
            try oContext := this.EditFilterTVContext.Value ? this.Stored.FilteredTreeView[Info] : this.Stored.TreeView[Info]
            if IsSet(oContext) && oContext {
                try this.SBMain.SetText("  Path: " oContext.Path)
                this.LVProps_Populate(oContext)
            }
        }
        ; Permits copying the Dump of JAB element(s) to clipboard
        TVContext_ContextMenu(GuiCtrlObj, Item, IsRightClick, X, Y) {
            TVContext_Menu := Menu()
            try oContext := this.EditFilterTVContext.Value ? this.Stored.FilteredTreeView[Item] : this.Stored.TreeView[Item]
            if IsSet(oContext)
                TVContext_Menu.Add("Copy to Clipboard", (*) => A_Clipboard := oContext.Dump())
            TVContext_Menu.Add("Copy Tree to Clipboard", (*) => A_Clipboard := JAB.ElementFromHandle(this.Stored.mwId).DumpAll())
            TVContext_Menu.Show()
        }
        ; Handles filtering the JAB elements inside the TreeView when the text hasn't been changed in 500ms.
        ; Sorts the results by JAB properties.
        EditFilterTV_Change(GuiCtrlObj, Info, *) {
            static TimeoutFunc := "", ChangeActive := False
            if !this.Stored.TreeView.Count
                return
            if (Info != "DoAction") || ChangeActive {
                if !TimeoutFunc
                    TimeoutFunc := this.GetMethod("EditFilterTV_Change").Bind(this, GuiCtrlObj, "DoAction")
                SetTimer(TimeoutFunc, -500)
                return
            }
            ChangeActive := True
            this.Stored.FilteredTreeView := Map(), parents := Map()
            if !(searchPhrase := this.EditFilterTVContext.Value) {
                this.ConstructTreeView()
                ChangeActive := False
                return
            }
            this.TVContext.Delete()
            temp := this.TVContext.Add("Searching...")
            Sleep -1
            this.TVContext.Opt("-Redraw")
            this.TVContext.Delete()
            for index, oContext in this.Stored.TreeView {
                for _, prop in ["RoleText", "Role", "Value", "Name", "StateText", "State", "DefaultAction", "Description", "KeyboardShortcut", "Help", "ChildId", "Identity"] {
                    try {
                        if InStr(oContext.%Prop%, searchPhrase) {
                            if !parents.Has(prop)
                                parents[prop] := this.TVContext.Add(prop,, "Expand")
                            this.Stored.FilteredTreeView[this.TVContext.Add(this.GetShortDescription(oContext), parents[prop], "Expand")] := oContext
                        }
                    }
                }
            }
            if !this.Stored.FilteredTreeView.Count
                this.TVContext.Add("No results found matching `"" searchPhrase "`"")
            this.TVContext.Opt("+Redraw")
            TimeoutFunc := "", ChangeActive := False
        }
        ; Populates the TreeView with the JAB tree when capturing and the mouse is held still
        ConstructTreeView() {
            this.TVContext.Delete()
            this.TVContext.Add("Constructing Tree, please wait...")
            Sleep -1
            this.TVContext.Opt("-Redraw")
            this.TVContext.Delete()
            this.Stored.TreeView := Map()
            if !WinExist(this.Stored.mwId)
                return
            this.RecurseTreeView(JAB.ElementFromHandle(this.Stored.mwId))
            this.TVContext.Opt("+Redraw")
            for k, v in this.Stored.TreeView
                if this.Stored.oContext.IsEqual(v)
                    this.TVContext.Modify(k, "Vis Select"), this.SBMain.SetText("  Path: " v.Path)
        }
        ; Stores the JAB tree with corresponding path values for each element
        RecurseTreeView(oContext, parent:=0, path:="") {
            oContext.BuildUpdatedCache(this.DefaultLVPropsItems)
            this.Stored.TreeView[TWEl := this.TVContext.Add(this.GetShortDescription(oContext), parent, "Expand")] := oContext.DefineProp("Path", {value:path})
            for k, v in oContext
                this.RecurseTreeView(v, TWEl, path (path?",":"") k)
        }
        ; Creates a short description string for the JAB tree elements
        GetShortDescription(oContext) {
            elDesc := " `"`""
            try elDesc := " `"" oContext.CachedName "`""
            try elDesc := oContext.CachedRole elDesc
            catch
                elDesc := "`"`"" elDesc
            return elDesc
        }
    }
}